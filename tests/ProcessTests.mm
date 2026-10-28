#import "../PPOLaunchProcess.h"
#include <pthread.h>
#include <sys/wait.h>
#include <time.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

static void Check(bool condition, const char *name) {
    if (!condition) { fprintf(stderr, "FAIL: %s\n", name); exit(1); }
}
static void *RunTests(void *value) {
    const char *path = static_cast<const char *>(value);
    setenv("PPO_TEST_PARENT_MARKER", "must-not-be-inherited", 1);
    PPOLaunchResult ok = PPORunHelper(path, "--ok", 2);
    Check(!ok.spawnError && !ok.waitError && !ok.timedOut && ok.exitCode == 0, "successful clean-environment child");
    PPOLaunchResult failed = PPORunHelper(path, "--fail", 2);
    Check(failed.exitCode == 7 && !failed.waitError, "nonzero child exit");
    PPOLaunchResult missing = PPORunHelper("/nonexistent/ppo-helper-fixture", "--ok", 2);
    Check(missing.spawnError == ENOENT, "missing executable");
    PPOLaunchResult invalid = PPORunHelper(path, "--ok", 0);
    Check(invalid.spawnError == EINVAL, "invalid timeout");
    PPOLaunchResult slow = PPORunHelper(path, "--delay", 0.05);
    Check(slow.timedOut && slow.pid > 0, "bounded wait");
    int status = 0;
    Check(waitpid(slow.pid, &status, 0) == slow.pid &&
          WIFEXITED(status) && WEXITSTATUS(status) == 0, "timed-out fixture exits naturally");
    printf("Process tests passed; no private API called\n");
    return nullptr;
}
int main(int argc, char *argv[]) {
    if (argc == 2) {
        if (strcmp(argv[1], "--ok") == 0) return getenv("PPO_TEST_PARENT_MARKER") ? 8 : 0;
        if (strcmp(argv[1], "--fail") == 0) return 7;
        if (strcmp(argv[1], "--delay") == 0) {
            timespec delay = {0, 300000000};
            while (nanosleep(&delay, &delay) != 0 && errno == EINTR) {}
            return 0;
        }
        return 9;
    }
    Check(argc == 1, "test arguments");
    Check(PPORunHelper(argv[0], "--ok", 2).spawnError == EDEADLK, "main-thread guard");
    pthread_t thread;
    Check(pthread_create(&thread, nullptr, RunTests, argv[0]) == 0, "worker starts");
    Check(pthread_join(thread, nullptr) == 0, "worker finishes");
    return 0;
}
