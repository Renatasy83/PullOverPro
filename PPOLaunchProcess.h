#pragma once
#include <sys/types.h>

struct PPOLaunchResult {
    pid_t pid;
    const char *stage;
    uid_t realUID;
    uid_t effectiveUID;
    int statError;
    int accessError;
    mode_t executableMode;
    uid_t executableOwner;
    int spawnError;
    int waitError;
    int exitCode;
    int signalNumber;
    bool timedOut;
};
// Refuses to run on the main thread. No shell, privilege changes or signal handlers.
PPOLaunchResult PPORunHelper(const char *path, const char *argument, double timeoutSeconds);
