#include "../PPOBridgeIO.h"
#include <sys/stat.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <vector>

static int checks = 0;
#define CHECK(value) do { ++checks; if (!(value)) { \
    fprintf(stderr, "FAIL line %d: %s (errno=%d)\n", __LINE__, #value, errno); exit(1); \
} } while (0)

static void RawFile(const std::string &path, const std::string &value, mode_t mode = 0600) {
    int fd = open(path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, mode);
    CHECK(fd >= 0);
    CHECK(fchmod(fd, mode) == 0);
    CHECK(write(fd, value.data(), value.size()) == static_cast<ssize_t>(value.size()));
    CHECK(close(fd) == 0);
}

static std::string Read(int directory, const char *name) {
    char bytes[PPOBridgeMaximumBytes];
    size_t length = static_cast<size_t>(-1);
    CHECK(PPOBridgeRead(directory, name, bytes, sizeof(bytes), &length) == 0);
    CHECK(length <= sizeof(bytes));
    return std::string(bytes, length);
}

int main() {
    // Only test-owned paths are removed at the end; never touch a device mailbox.
    char pattern[] = "/tmp/ppo-bridge-tests-XXXXXX";
    char *rootValue = mkdtemp(pattern);
    CHECK(rootValue != nullptr);
    std::string root(rootValue);
    std::string box = root + "/box";
    int directory = PPOBridgeOpenDirectory(box.c_str());
    CHECK(directory >= 0);
    struct stat status = {};
    CHECK(fstat(directory, &status) == 0 && (status.st_mode & 07777) == 0700);
    char bytes[PPOBridgeMaximumBytes];
    size_t length = 71;
    CHECK(PPOBridgeRead(directory, "request.json", bytes, sizeof(bytes), &length) == ENOENT);
    CHECK(length == 71);
    const char first[] = "{\"id\":1}";
    CHECK(PPOBridgeWrite(directory, "request.json", first, sizeof(first) - 1) == 0);
    CHECK(Read(directory, "request.json") == first);
    CHECK(fstatat(directory, "request.json", &status, 0) == 0);
    CHECK((status.st_mode & 07777) == 0600 && status.st_nlink == 1);
    ino_t initialInode = status.st_ino;
    const char second[] = "{\"id\":2}";
    CHECK(PPOBridgeWrite(directory, "request.json", second, sizeof(second) - 1) == 0);
    CHECK(Read(directory, "request.json") == second);
    CHECK(fstatat(directory, "request.json", &status, 0) == 0 && status.st_ino != initialInode);
    CHECK(PPOBridgeRead(directory, "request.json", bytes, 2, &length) == EMSGSIZE);
    CHECK(PPOBridgeRead(directory, "request.json", bytes, sizeof(bytes) + 1, &length) == EINVAL);
    CHECK(PPOBridgeRead(directory, "request.json", nullptr, sizeof(bytes), &length) == EINVAL);
    CHECK(PPOBridgeRead(directory, "request.json", bytes, sizeof(bytes), nullptr) == EINVAL);
    CHECK(PPOBridgeWrite(directory, "request.json", first, 0) == EINVAL);
    CHECK(PPOBridgeWrite(directory, "request.json", nullptr, 5) == EINVAL);
    CHECK(PPOBridgeWrite(directory, "request.json", first, PPOBridgeMaximumBytes + 1) == EMSGSIZE);
    for (const char *invalid : {"../external", "/tmp/external", "other.json", "tmp-1234", "./request.json", ""}) {
        CHECK(PPOBridgeWrite(directory, invalid, first, sizeof(first) - 1) == EINVAL);
        CHECK(PPOBridgeRead(directory, invalid, bytes, sizeof(bytes), &length) == EINVAL);
    }
    CHECK(PPOBridgeWrite(directory, nullptr, first, sizeof(first) - 1) == EINVAL);
    for (const char *valid : {"heartbeat.json", "consumed.json", "response.json"}) {
        CHECK(PPOBridgeWrite(directory, valid, first, sizeof(first) - 1) == 0);
        CHECK(Read(directory, valid) == first);
    }

    std::string external = root + "/external";
    RawFile(external, "private outside data");
    CHECK(unlinkat(directory, "response.json", 0) == 0);
    CHECK(symlink(external.c_str(), (box + "/response.json").c_str()) == 0);
    CHECK(PPOBridgeWrite(directory, "response.json", first, sizeof(first) - 1) == EPERM);
    CHECK(PPOBridgeRead(directory, "response.json", bytes, sizeof(bytes), &length) != 0);
    int externalFD = open(external.c_str(), O_RDONLY);
    CHECK(externalFD >= 0);
    CHECK(read(externalFD, bytes, sizeof(bytes)) == 20);
    CHECK(memcmp(bytes, "private outside data", 20) == 0);
    CHECK(close(externalFD) == 0);
    CHECK(unlinkat(directory, "response.json", 0) == 0);

    CHECK(mkfifo((box + "/response.json").c_str(), 0600) == 0);
    CHECK(PPOBridgeRead(directory, "response.json", bytes, sizeof(bytes), &length) == EPERM);
    CHECK(PPOBridgeWrite(directory, "response.json", first, sizeof(first) - 1) == EPERM);
    CHECK(unlinkat(directory, "response.json", 0) == 0);
    CHECK(mkdir((box + "/response.json").c_str(), 0700) == 0);
    CHECK(PPOBridgeRead(directory, "response.json", bytes, sizeof(bytes), &length) == EPERM);
    CHECK(PPOBridgeWrite(directory, "response.json", first, sizeof(first) - 1) == EPERM);
    CHECK(unlinkat(directory, "response.json", AT_REMOVEDIR) == 0);

    RawFile(box + "/response.json", std::string(PPOBridgeMaximumBytes + 1, 'x'));
    CHECK(PPOBridgeRead(directory, "response.json", bytes, sizeof(bytes), &length) == EMSGSIZE);
    CHECK(PPOBridgeWrite(directory, "response.json", first, sizeof(first) - 1) == EMSGSIZE);
    CHECK(unlinkat(directory, "response.json", 0) == 0);
    RawFile(box + "/response.json", first, 0644);
    CHECK(PPOBridgeRead(directory, "response.json", bytes, sizeof(bytes), &length) == EPERM);
    CHECK(PPOBridgeWrite(directory, "response.json", first, sizeof(first) - 1) == EPERM);
    CHECK(unlinkat(directory, "response.json", 0) == 0);
    CHECK(link(external.c_str(), (box + "/response.json").c_str()) == 0);
    CHECK(PPOBridgeRead(directory, "response.json", bytes, sizeof(bytes), &length) == EPERM);
    CHECK(PPOBridgeWrite(directory, "response.json", first, sizeof(first) - 1) == EPERM);
    CHECK(unlinkat(directory, "response.json", 0) == 0);

    std::string linkPath = root + "/link";
    CHECK(symlink(box.c_str(), linkPath.c_str()) == 0);
    CHECK(PPOBridgeOpenDirectory(linkPath.c_str()) == -1);
    CHECK(PPOBridgeOpenDirectory((linkPath + "/").c_str()) == -1);
    CHECK(PPOBridgeOpenDirectory("relative") == -1 && errno == EINVAL);
    CHECK(PPOBridgeOpenDirectory(nullptr) == -1 && errno == EINVAL);
    CHECK(PPOBridgeOpenDirectory((root + "/missing/box").c_str()) == -1);
    CHECK(chmod(box.c_str(), 0755) == 0);
    CHECK(PPOBridgeOpenDirectory(box.c_str()) == -1 && errno == EPERM);
    CHECK(PPOBridgeWrite(directory, "request.json", first, sizeof(first) - 1) == EPERM);
    CHECK(PPOBridgeRead(directory, "request.json", bytes, sizeof(bytes), &length) == EPERM);
    CHECK(stat(box.c_str(), &status) == 0 && (status.st_mode & 07777) == 0755);
    CHECK(chmod(box.c_str(), 0700) == 0);
    CHECK(PPOBridgeWrite(-1, "request.json", first, sizeof(first) - 1) == EBADF);

    std::string maximum(PPOBridgeMaximumBytes, 'z');
    CHECK(PPOBridgeWrite(directory, "request.json", maximum.data(), maximum.size()) == 0);
    CHECK(Read(directory, "request.json") == maximum);
    // A process reader sees whole old/new payloads across 250 atomic replacements.
    pid_t child = fork();
    CHECK(child >= 0);
    if (child == 0) {
        for (int i = 0; i < 1000; ++i) {
            size_t got = 0;
            char buffer[PPOBridgeMaximumBytes];
            if (PPOBridgeRead(directory, "request.json", buffer, sizeof(buffer), &got) ||
                got != maximum.size()) _exit(20);
            for (size_t j = 1; j < got; ++j) if (buffer[j] != buffer[0]) _exit(21);
        }
        _exit(0);
    }
    for (int i = 0; i < 250; ++i) {
        std::string payload(PPOBridgeMaximumBytes, static_cast<char>('a' + i % 26));
        CHECK(PPOBridgeWrite(directory, "request.json", payload.data(), payload.size()) == 0);
    }
    int childStatus = 0;
    CHECK(waitpid(child, &childStatus, 0) == child);
    CHECK(WIFEXITED(childStatus) && WEXITSTATUS(childStatus) == 0);

    for (const char *name : {"request.json", "heartbeat.json", "consumed.json"})
        CHECK(unlinkat(directory, name, 0) == 0);
    CHECK(close(directory) == 0);
    CHECK(unlink(linkPath.c_str()) == 0);
    CHECK(unlink(external.c_str()) == 0);
    CHECK(rmdir(box.c_str()) == 0); // Also verifies no leaked temporary files.
    CHECK(rmdir(root.c_str()) == 0);
    printf("Bridge IO: %d checks passed; bounded files, private ownership/modes, symlink/FIFO/hardlink rejection, atomic concurrent replacement.\n", checks);
    return 0;
}
