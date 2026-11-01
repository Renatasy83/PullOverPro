#import "PPOFavoritesStore.h"
#import "PPOFavoriteApps.h"
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>

namespace {
constexpr size_t MaximumBytes = 16384;
const char FavoritesName[] = "favorites.plist";

class Descriptor {
public:
    explicit Descriptor(int value = -1) : value_(value) {}
    ~Descriptor() { if (value_ >= 0) close(value_); }
    Descriptor(const Descriptor &) = delete;
    Descriptor &operator=(const Descriptor &) = delete;
    int get() const { return value_; }
    int closeNow() {
        int value = value_;
        value_ = -1;
        return value >= 0 && close(value) ? errno : 0;
    }
private:
    int value_;
};

void Fail(NSError **error, int code, NSString *directory) {
    if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:code
        userInfo:directory ? @{NSFilePathErrorKey: directory} : nil];
}

bool Path(NSString *directory, std::string &path) {
    if (![directory isKindOfClass:NSString.class] || directory.length > 4096) return false;
    NSData *bytes = [directory dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    if (!bytes || bytes.length < 2 || bytes.length > 4096 ||
        memchr(bytes.bytes, '\0', bytes.length)) return false;
    path.assign(static_cast<const char *>(bytes.bytes), bytes.length);
    if (path.front() != '/' || path.back() == '/') return false;
    // Do not let path normalization turn an untrusted final component into a
    // parent traversal, or hide an empty component.
    size_t start = 1;
    while (start < path.size()) {
        size_t end = path.find('/', start);
        if (end == std::string::npos) end = path.size();
        size_t length = end - start;
        if (!length || (length == 1 && path[start] == '.') ||
            (length == 2 && path[start] == '.' && path[start + 1] == '.')) return false;
        start = end + 1;
    }
    return true;
}

int DirectoryStatus(const struct stat &status) {
    return S_ISDIR(status.st_mode) && status.st_uid == getuid() &&
        (status.st_mode & 07777) == 0700 ? 0 : EPERM;
}

bool SameIdentity(const struct stat &first, const struct stat &second) {
    return first.st_dev == second.st_dev && first.st_ino == second.st_ino;
}

bool SameVersion(const struct stat &first, const struct stat &second) {
    if (!SameIdentity(first, second) || first.st_size != second.st_size) return false;
#if defined(__APPLE__)
    return first.st_mtimespec.tv_sec == second.st_mtimespec.tv_sec &&
        first.st_mtimespec.tv_nsec == second.st_mtimespec.tv_nsec &&
        first.st_ctimespec.tv_sec == second.st_ctimespec.tv_sec &&
        first.st_ctimespec.tv_nsec == second.st_ctimespec.tv_nsec;
#else
    return first.st_mtim.tv_sec == second.st_mtim.tv_sec &&
        first.st_mtim.tv_nsec == second.st_mtim.tv_nsec &&
        first.st_ctim.tv_sec == second.st_ctim.tv_sec &&
        first.st_ctim.tv_nsec == second.st_ctim.tv_nsec;
#endif
}

int DirectoryIdentity(int descriptor, const char *path) {
    struct stat opened = {}, named = {};
    if (fstat(descriptor, &opened)) return errno;
    int failure = DirectoryStatus(opened);
    if (failure) return failure;
    if (lstat(path, &named)) return errno;
    failure = DirectoryStatus(named);
    if (failure) return failure;
    return SameIdentity(opened, named) ? 0 : ESTALE;
}

int OpenDirectory(const char *path, int *failure) {
    if (mkdir(path, 0700) && errno != EEXIST) { *failure = errno; return -1; }
    int descriptor = open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK);
    if (descriptor < 0) { *failure = errno; return -1; }
    *failure = DirectoryIdentity(descriptor, path);
    if (*failure) { close(descriptor); return -1; }
    return descriptor;
}

int FileStatus(const struct stat &status) {
    if (!S_ISREG(status.st_mode) || status.st_uid != getuid() ||
        (status.st_mode & 07777) != 0600 || status.st_nlink != 1) return EPERM;
    return status.st_size < 0 || static_cast<uint64_t>(status.st_size) > MaximumBytes
        ? EMSGSIZE : 0;
}

NSArray<NSString *> *Read(int directory, NSString *path, NSError **error) {
    Descriptor file(openat(directory, FavoritesName,
        O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK));
    if (file.get() < 0) {
        int failure = errno;
        if (failure == ENOENT) return @[];
        Fail(error, failure, path);
        return nil;
    }
    struct stat before = {}, after = {}, named = {};
    int failure = fstat(file.get(), &before) ? errno : FileStatus(before);
    unsigned char buffer[MaximumBytes + 1];
    size_t used = 0;
    while (!failure && used < sizeof(buffer)) {
        ssize_t count = read(file.get(), buffer + used, sizeof(buffer) - used);
        if (count < 0 && errno == EINTR) continue;
        if (count < 0) { failure = errno; break; }
        if (!count) break;
        used += static_cast<size_t>(count);
        if (used > MaximumBytes) failure = EMSGSIZE;
    }
    if (!failure && fstat(file.get(), &after)) failure = errno;
    if (!failure) failure = FileStatus(after);
    if (!failure && (!SameVersion(before, after) ||
        static_cast<uint64_t>(after.st_size) != used)) failure = ESTALE;
    if (!failure && fstatat(directory, FavoritesName, &named, AT_SYMLINK_NOFOLLOW)) failure = errno;
    if (!failure) failure = FileStatus(named);
    if (!failure && !SameVersion(after, named)) failure = ESTALE;
    int closeFailure = file.closeNow();
    if (!failure) failure = closeFailure;
    if (failure) { Fail(error, failure, path); return nil; }
    NSArray<NSString *> *result = PPOFavoriteIdentifiersFromData(
        [NSData dataWithBytes:buffer length:used], error);
    if (!result && error && !*error) Fail(error, EINVAL, path);
    return result;
}

void RandomName(char (&name)[48]) {
    unsigned char random[16];
    arc4random_buf(random, sizeof(random));
    memcpy(name, ".favorites-", 11);
    const char hex[] = "0123456789abcdef";
    for (size_t i = 0; i < sizeof(random); ++i) {
        name[11 + 2 * i] = hex[random[i] >> 4];
        name[12 + 2 * i] = hex[random[i] & 15];
    }
    memcpy(name + 43, ".tmp", 5);
}

int NamedTemporary(int directory, const char *name, const struct stat &completed, size_t length) {
    struct stat named = {};
    if (fstatat(directory, name, &named, AT_SYMLINK_NOFOLLOW)) return errno;
    int failure = FileStatus(named);
    if (failure) return failure;
    return SameVersion(completed, named) && static_cast<uint64_t>(named.st_size) == length
        ? 0 : ESTALE;
}

// A random-name collision, or a name replaced by another writer, is not ours.
void RemoveTemporary(int directory, const char *name, const struct stat &created) {
    struct stat named = {};
    if (!fstatat(directory, name, &named, AT_SYMLINK_NOFOLLOW) && SameIdentity(created, named))
        unlinkat(directory, name, 0);
}
} // namespace

NSArray<NSString *> *PPOFavoritesLoad(NSString *directory, NSError **error) {
    if (error) *error = nil;
    if (NSThread.isMainThread) { Fail(error, EDEADLK, nil); return nil; }
    std::string path;
    if (!Path(directory, path)) { Fail(error, EINVAL, nil); return nil; }
    NSString *savedDirectory = [directory copy];
    int failure = 0;
    Descriptor descriptor(OpenDirectory(path.c_str(), &failure));
    if (!failure && flock(descriptor.get(), LOCK_SH | LOCK_NB)) failure = errno;
    if (!failure) failure = DirectoryIdentity(descriptor.get(), path.c_str());
    if (failure) { Fail(error, failure, savedDirectory); return nil; }
    NSArray<NSString *> *result = Read(descriptor.get(), savedDirectory, error);
    if (!result) return nil;
    failure = DirectoryIdentity(descriptor.get(), path.c_str());
    if (failure) { Fail(error, failure, savedDirectory); return nil; }
    return result;
}

BOOL PPOFavoritesCommit(NSString *directory, NSArray<NSString *> *expected,
                        NSArray<NSString *> *replacement, NSError **error) {
    if (error) *error = nil;
    if (NSThread.isMainThread) { Fail(error, EDEADLK, nil); return NO; }
    std::string path;
    if (!Path(directory, path)) { Fail(error, EINVAL, nil); return NO; }
    NSString *savedDirectory = [directory copy];
    NSArray<NSString *> *normalizedExpected = PPOFavoriteIdentifiersNormalize(expected);
    NSArray<NSString *> *normalizedReplacement = PPOFavoriteIdentifiersNormalize(replacement);
    if (!normalizedExpected || !normalizedReplacement) {
        Fail(error, EINVAL, savedDirectory); return NO;
    }
    NSData *data = PPOFavoriteIdentifiersData(normalizedReplacement, error);
    if (!data || !data.length || data.length > MaximumBytes) {
        if (data || (error && !*error)) Fail(error, EMSGSIZE, savedDirectory);
        return NO;
    }
    int failure = 0;
    Descriptor descriptor(OpenDirectory(path.c_str(), &failure));
    if (!failure && flock(descriptor.get(), LOCK_EX | LOCK_NB)) failure = errno;
    if (!failure) failure = DirectoryIdentity(descriptor.get(), path.c_str());
    if (failure) { Fail(error, failure, savedDirectory); return NO; }
    NSArray<NSString *> *current = Read(descriptor.get(), savedDirectory, error);
    if (!current) return NO;
    if (![current isEqual:normalizedExpected]) { Fail(error, ESTALE, savedDirectory); return NO; }
    failure = DirectoryIdentity(descriptor.get(), path.c_str());
    if (failure) { Fail(error, failure, savedDirectory); return NO; }

    char temporary[48] = {};
    int opened = -1;
    for (unsigned attempt = 0; attempt < 8; ++attempt) {
        RandomName(temporary);
        opened = openat(descriptor.get(), temporary,
            O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK, 0600);
        if (opened >= 0 || errno != EEXIST) break;
    }
    if (opened < 0) { Fail(error, errno, savedDirectory); return NO; }
    Descriptor file(opened);
    struct stat created = {};
    bool haveIdentity = fstat(file.get(), &created) == 0;
    failure = haveIdentity ? FileStatus(created) : errno;
    size_t written = 0;
    while (!failure && written < data.length) {
        ssize_t count = write(file.get(), static_cast<const unsigned char *>(data.bytes) + written,
            data.length - written);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) { failure = count < 0 ? errno : EIO; break; }
        written += static_cast<size_t>(count);
    }
    if (!failure) {
        int synced;
        do { synced = fsync(file.get()); } while (synced && errno == EINTR);
        if (synced) failure = errno;
    }
    struct stat completed = {};
    if (!failure && fstat(file.get(), &completed)) failure = errno;
    if (!failure) failure = FileStatus(completed);
    if (!failure && (!SameIdentity(created, completed) ||
        static_cast<uint64_t>(completed.st_size) != data.length)) failure = ESTALE;
    int closeFailure = file.closeNow();
    if (!failure) failure = closeFailure;
    if (!failure) failure = NamedTemporary(descriptor.get(), temporary, completed, data.length);
    if (!failure) {
        current = Read(descriptor.get(), savedDirectory, error);
        if (!current) failure = EINVAL; // Preserve the more specific read error below.
        else if (![current isEqual:normalizedExpected]) failure = ESTALE;
    }
    if (!failure) failure = DirectoryIdentity(descriptor.get(), path.c_str());
    if (!failure) failure = NamedTemporary(descriptor.get(), temporary, completed, data.length);
    if (!failure && renameat(descriptor.get(), temporary, descriptor.get(), FavoritesName)) failure = errno;
    if (failure) {
        if (haveIdentity) RemoveTemporary(descriptor.get(), temporary, created);
        if (error && !*error) Fail(error, failure, savedDirectory);
        return NO;
    }
    return YES;
}
