#import "PPOLaunchProcess.h"
#include <spawn.h>
#include <pthread.h>
#include <sys/wait.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <cmath>

PPOLaunchResult PPORunHelper(const char *path, const char *argument, double timeoutSeconds) {
    PPOLaunchResult result = {};
    result.pid = -1;
    result.exitCode = -1;
    if (pthread_main_np()) { result.spawnError = EDEADLK; return result; }
    if (!path || path[0] != '/' || !argument || !std::isfinite(timeoutSeconds) ||
        timeoutSeconds <= 0 || timeoutSeconds > 30) {
        result.spawnError = EINVAL; return result;
    }
    timespec start = {};
    if (clock_gettime(CLOCK_MONOTONIC, &start) != 0) { result.waitError = errno; return result; }
    double deadline = start.tv_sec + start.tv_nsec / 1e9 + timeoutSeconds;
    posix_spawn_file_actions_t actions;
    int code = posix_spawn_file_actions_init(&actions);
    if (code) { result.spawnError = code; return result; }
    posix_spawnattr_t attributes;
    code = posix_spawnattr_init(&attributes);
    if (code) {
        posix_spawn_file_actions_destroy(&actions);
        result.spawnError = code; return result;
    }
    code = posix_spawnattr_setflags(&attributes, POSIX_SPAWN_CLOEXEC_DEFAULT);
    if (!code) code = posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0);
    if (!code) code = posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0);
    if (!code) code = posix_spawn_file_actions_adddup2(&actions, STDOUT_FILENO, STDERR_FILENO);
    char pathEnv[] = "PATH=/var/jb/usr/bin:/var/jb/bin:/usr/bin:/bin";
    char localeEnv[] = "LC_ALL=C";
    char languageEnv[] = "LANG=C";
    char *environment[] = {pathEnv, localeEnv, languageEnv, nullptr};
    char *arguments[] = {const_cast<char *>(path), const_cast<char *>(argument), nullptr};
    if (!code) code = posix_spawn(&result.pid, path, &actions, &attributes, arguments, environment);
    posix_spawnattr_destroy(&attributes);
    posix_spawn_file_actions_destroy(&actions);
    if (code) { result.spawnError = code; return result; }
    for (;;) {
        int status = 0;
        pid_t waited = waitpid(result.pid, &status, WNOHANG);
        if (waited == result.pid) {
            if (WIFEXITED(status)) result.exitCode = WEXITSTATUS(status);
            else if (WIFSIGNALED(status)) result.signalNumber = WTERMSIG(status);
            return result;
        }
        if (waited < 0 && errno != EINTR) { result.waitError = errno; return result; }
        timespec now = {};
        if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) { result.waitError = errno; return result; }
        if (now.tv_sec + now.tv_nsec / 1e9 >= deadline) {
            // The helper owns its 20s alarm. Stop observing; never signal a potentially reaped PID.
            result.timedOut = true;
            return result;
        }
        const timespec pause = {0, 100000000};
        nanosleep(&pause, nullptr);
    }
}
