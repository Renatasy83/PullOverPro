#include "PPOBridgeIO.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>

namespace {
bool Allowed(const char *name) {
    return name && (!strcmp(name, "request.json") || !strcmp(name, "response.json") ||
                    !strcmp(name, "heartbeat.json") || !strcmp(name, "consumed.json"));
}

int CheckDirectory(int descriptor) {
    struct stat status = {};
    if (fstat(descriptor, &status)) return errno;
    if (!S_ISDIR(status.st_mode) || status.st_uid != getuid() ||
        (status.st_mode & 07777) != 0700) return EPERM;
    return 0;
}

int CheckFile(const struct stat &status, bool allowUnlinkedSnapshot = false) {
    if (!S_ISREG(status.st_mode) || status.st_uid != getuid() ||
        (status.st_mode & 07777) != 0600 || status.st_nlink > 1 ||
        (!allowUnlinkedSnapshot && status.st_nlink != 1)) return EPERM;
    if (status.st_size < 0 || status.st_size > PPOBridgeMaximumBytes) return EMSGSIZE;
    return 0;
}

int CheckTarget(int directory, const char *name) {
    struct stat status = {};
    if (fstatat(directory, name, &status, AT_SYMLINK_NOFOLLOW))
        return errno == ENOENT ? 0 : errno;
    return CheckFile(status);
}

int RandomName(char (&name)[37]) {
    unsigned char random[16];
    int descriptor = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
    if (descriptor < 0) return errno;
    size_t offset = 0;
    int failure = 0;
    while (offset < sizeof(random)) {
        ssize_t count = read(descriptor, random + offset, sizeof(random) - offset);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) { failure = count < 0 ? errno : EIO; break; }
        offset += static_cast<size_t>(count);
    }
    close(descriptor);
    if (failure) return failure;
    memcpy(name, "tmp-", 4);
    const char hex[] = "0123456789abcdef";
    for (size_t i = 0; i < sizeof(random); ++i) {
        name[4 + 2 * i] = hex[random[i] >> 4];
        name[5 + 2 * i] = hex[random[i] & 15];
    }
    name[36] = '\0';
    return 0;
}
}

int PPOBridgeOpenDirectory(const char *path) {
    if (!path || path[0] != '/' || path[1] == '\0' || path[strlen(path) - 1] == '/') {
        errno = EINVAL; return -1;
    }
    if (mkdir(path, 0700) && errno != EEXIST) return -1;
    int descriptor = open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (descriptor < 0) return -1;
    int failure = CheckDirectory(descriptor);
    if (failure) { close(descriptor); errno = failure; return -1; }
    return descriptor;
}

int PPOBridgeWrite(int directory, const char *name, const void *bytes, size_t length) {
    if (!Allowed(name) || !bytes || length == 0) return EINVAL;
    if (length > PPOBridgeMaximumBytes) return EMSGSIZE;
    int failure = CheckDirectory(directory);
    if (failure) return failure;
    failure = CheckTarget(directory, name);
    if (failure) return failure;
    char temporary[37];
    failure = RandomName(temporary);
    if (failure) return failure;
    int descriptor = openat(directory, temporary,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
    if (descriptor < 0) return errno;
    // The process umask may remove owner permissions. Refuse instead of changing it.
    struct stat status = {};
    if (fstat(descriptor, &status)) failure = errno;
    else failure = CheckFile(status);
    size_t offset = 0;
    while (!failure && offset < length) {
        ssize_t count = write(descriptor, static_cast<const char *>(bytes) + offset, length - offset);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) { failure = count < 0 ? errno : EIO; break; }
        offset += static_cast<size_t>(count);
    }
    if (!failure && fsync(descriptor)) failure = errno;
    if (close(descriptor) && !failure) failure = errno;
    // Recheck before rename; rename never follows a concurrently replaced symlink.
    if (!failure) failure = CheckTarget(directory, name);
    if (!failure && renameat(directory, temporary, directory, name)) failure = errno;
    if (failure) unlinkat(directory, temporary, 0); // Only our own random temporary.
    return failure;
}

int PPOBridgeRead(int directory, const char *name, void *bytes, size_t capacity, size_t *length) {
    if (!Allowed(name) || !bytes || !length || capacity == 0 ||
        capacity > PPOBridgeMaximumBytes) return EINVAL;
    int failure = CheckDirectory(directory);
    if (failure) return failure;
    // O_NONBLOCK prevents a malicious FIFO from blocking before the fstat check.
    int descriptor = openat(directory, name, O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK);
    if (descriptor < 0) return errno;
    struct stat status = {};
    if (fstat(descriptor, &status)) failure = errno;
    // An atomic replacement may unlink this already-open, valid old snapshot.
    else failure = CheckFile(status, true);
    if (!failure && static_cast<uint64_t>(status.st_size) > capacity) failure = EMSGSIZE;
    size_t offset = 0;
    while (!failure && offset < capacity) {
        ssize_t count = read(descriptor, static_cast<char *>(bytes) + offset, capacity - offset);
        if (count < 0 && errno == EINTR) continue;
        if (count < 0) { failure = errno; break; }
        if (!count) break;
        offset += static_cast<size_t>(count);
    }
    // Detect growth during the read, even when the initial fstat was in bounds.
    char extra;
    if (!failure && offset == capacity) {
        ssize_t count;
        do { count = read(descriptor, &extra, 1); } while (count < 0 && errno == EINTR);
        if (count != 0) failure = count < 0 ? errno : EMSGSIZE;
    }
    if (close(descriptor) && !failure) failure = errno;
    if (!failure) *length = offset;
    return failure;
}
