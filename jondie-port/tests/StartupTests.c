#include "../Shared/POHostStartupState.h"
#include <assert.h>
#include <stdio.h>

int main(void) {
    POHostStartupState s = {0};
    uint64_t first = POStartupBegin(&s, 10);
    assert(POStartupMatches(&s, first));
    assert(POStartupTakeLaunch(&s));
    for (int i = 0; i < 1000; i++) assert(!POStartupTakeLaunch(&s));
    double now = 10;
    unsigned callbacks = 0;
    while (!POStartupTimedOut(&s, now)) { now += POStartupNextDelay(&s, now); callbacks++; }
    assert(callbacks <= 24 && now <= 30 && now >= 29);
    assert(POStartupTimedOut(&s, NAN));
    POStartupCancel(&s);
    assert(!POStartupMatches(&s, first));
    uint64_t second = POStartupBegin(&s, 50);
    assert(second != first && !POStartupMatches(&s, first));
    assert(POStartupTakeLaunch(&s));
    s.phase = POStartupHosted;
    assert(!POStartupMatches(&s, second)); // Late error cannot close a working host.
    assert(!POStartupTakeLaunch(&s));
    assert(s.phase == POStartupHosted); // No lifetime timer is part of this policy.
    uint64_t third = POStartupBegin(&s, 100);
    s.phase = POStartupFailed;
    assert(!POStartupMatches(&s, third));
    assert(!POStartupTakeLaunch(&s)); // Retry requires an explicit new request.
    POStartupCancel(&s);
    assert(s.phase == POStartupIdle && !s.launchRequested);
    puts("startup state tests passed");
}
