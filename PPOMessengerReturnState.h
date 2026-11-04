#pragma once
#include <cstdint>
#include <cmath>
enum class PPOReturnPhase : unsigned { Waiting=0, Captured=1, Migrated=2, Restored=3, Refused=4 };
struct PPOReturnState {
    PPOReturnPhase phase=PPOReturnPhase::Waiting;
    unsigned flags=0;
    bool capture(bool ordinaryPrimary, bool rootPresent) {
        if (phase!=PPOReturnPhase::Waiting || !ordinaryPrimary || !rootPresent) return false;
        phase=PPOReturnPhase::Captured; flags|=1; return true;
    }
    bool migration(bool ownedSession, bool sameWindow, bool currentRootOwned,
                   bool differentScene, bool rootReplaced) {
        if (!ownedSession) return false;
        flags|=2;
        if (phase!=PPOReturnPhase::Captured || !differentScene) return false;
        if (!sameWindow) { phase=PPOReturnPhase::Refused; flags|=128; return false; }
        if (!currentRootOwned) return false; // Wait for public hierarchy attachment; do not install an old root.
        if (rootReplaced) flags|=16;
        phase=PPOReturnPhase::Migrated; flags|=4; return true;
    }
    bool canRestore(bool ownedDisconnect, bool windowStillSame, bool currentRootOwned,
                    bool targetConnected, bool targetOrdinary, bool sameScreen,
                    bool windowOwnedOrDetached) const {
        return phase==PPOReturnPhase::Migrated && ownedDisconnect && windowStillSame && currentRootOwned &&
            targetConnected && targetOrdinary && sameScreen && windowOwnedOrDetached;
    }
    void finish(bool verified) { if (phase==PPOReturnPhase::Migrated) {
        phase=verified?PPOReturnPhase::Restored:PPOReturnPhase::Refused; if (verified) flags|=8;
    } }
    uint64_t packed(double now) const {
        if (!std::isfinite(now) || now<0 || now>4294967295.0) return 0;
        return (uint64_t(0x5050)<<48)|(uint64_t(2)<<44)|(uint64_t(phase)<<40)|
            (uint64_t(flags&255)<<32)|uint64_t(now);
    }
};
static inline bool PPOReturnReady(uint64_t value,double now) {
    return (value>>48)==0x5050 && ((value>>44)&15)==2 &&
        ((value>>40)&15)==unsigned(PPOReturnPhase::Captured) && ((value>>32)&1) && !((value>>32)&2) &&
        std::isfinite(now) && now>=double(uint32_t(value)) && now-double(uint32_t(value))<=30;
}
