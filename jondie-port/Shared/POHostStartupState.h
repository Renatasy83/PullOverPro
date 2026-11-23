#ifndef PO_HOST_STARTUP_STATE_H
#define PO_HOST_STARTUP_STATE_H

#include <stdbool.h>
#include <stdint.h>
#include <math.h>

typedef enum { POStartupIdle, POStartupWaiting, POStartupHosted, POStartupFailed } POStartupPhase;
typedef struct {
    uint64_t generation;
    POStartupPhase phase;
    bool launchRequested;
    unsigned polls;
    double deadline;
} POHostStartupState;

static inline void POStartupCancel(POHostStartupState *state) {
    uint64_t next = state->generation + 1;
    *state = (POHostStartupState){ .generation = next, .phase = POStartupIdle };
}

static inline uint64_t POStartupBegin(POHostStartupState *state, double now) {
    POStartupCancel(state);
    state->phase = POStartupWaiting;
    state->deadline = now + 20.0; // Startup only: never expires a working window.
    return state->generation;
}

static inline bool POStartupMatches(const POHostStartupState *state, uint64_t generation) {
    return state->generation == generation && state->phase == POStartupWaiting;
}

static inline bool POStartupTimedOut(const POHostStartupState *state, double now) {
    return !isfinite(now) || now >= state->deadline || state->polls >= 24;
}

static inline bool POStartupTakeLaunch(POHostStartupState *state) {
    if (state->phase != POStartupWaiting || state->launchRequested) return false;
    state->launchRequested = true;
    return true;
}

static inline double POStartupNextDelay(POHostStartupState *state, double now) {
    state->polls++;
    double delay = state->polls == 1 ? 0.25 : (state->polls == 2 ? 0.5 : 1.0);
    return fmax(0.0, fmin(delay, state->deadline - now));
}

#endif
