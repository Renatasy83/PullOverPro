#include "../PPOInteractionIntent.h"
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <random>
#include <vector>

static unsigned checks;
static void Check(bool condition, const char *message) {
    checks++;
    if (!condition) { std::fprintf(stderr, "FAIL: %s\n", message); std::exit(1); }
}
static void Inactive(const PPOInteractionIntent &intent, std::uint64_t ticket) {
    Check(!intent.current(ticket) && !intent.ready(ticket) && !intent.held(ticket),
        "inactive or stale callback cannot observe a current, ready or held intent");
}

// A deliberately small callback fixture: metadata arrival may allocate only
// after the actual coordinator grants its one-shot ready consumption. The
// production caller must also perform its independent admission/owner checks.
struct PendingReply {
    std::uint64_t ticket;
    unsigned allocations = 0;
    bool arrive(PPOInteractionIntent &intent) {
        if (!intent.current(ticket) || !intent.ready(ticket) || !intent.consume(ticket)) return false;
        allocations++;
        return true;
    }
};

int main() {
    PPOInteractionIntent intent;
    Inactive(intent,0); Inactive(intent,1);
    Check(!intent.commit(0) && !intent.consume(0), "zero cannot commit or consume an intent");
    const auto first=intent.begin(false);
    Check(first==1 && intent.current(first) && intent.ready(first) && !intent.held(first),
        "ordinary explicit selection starts a ready nonzero ticket");
    Check(!intent.commit(first) && intent.ready(first), "committing an already-ready ticket is not another grant");
    Check(intent.consume(first), "a ready ticket can be consumed once");
    Check(!intent.consume(first) && !intent.commit(first), "duplicate callbacks cannot consume or reactivate it");
    Inactive(intent,first);

    const auto gesture=intent.begin(true);
    Check(gesture>first && intent.current(gesture) && intent.held(gesture) && !intent.ready(gesture),
        "gesture preparation cannot authorize app creation before inward release");
    Check(!intent.consume(gesture) && intent.held(gesture), "held reply cannot allocate even when metadata arrived");
    Check(!intent.commit(first) && intent.held(gesture), "a stale gesture release cannot commit a newer gesture");
    Check(intent.commit(gesture) && intent.ready(gesture) && !intent.held(gesture),
        "a completed inward release converts its exact held ticket to ready");
    Check(!intent.commit(gesture), "a release is committed only once");
    Check(intent.consume(gesture) && !intent.consume(gesture), "completed gesture grants at most one creation");

    PendingReply cancelled{intent.begin(false)};
    intent.cancel();
    Check(!cancelled.arrive(intent) && cancelled.allocations==0,
        "close chooser before helper reply prevents creation");
    Inactive(intent,cancelled.ticket);
    PendingReply heldCancelled{intent.begin(true)};
    Check(!heldCancelled.arrive(intent), "reply while finger is held cannot create");
    intent.cancel();
    Check(!intent.commit(heldCancelled.ticket) && !heldCancelled.arrive(intent) && heldCancelled.allocations==0,
        "cancelled pan cannot create a hidden retained host after helper reply");
    PendingReply heldCommit{intent.begin(true)};
    Check(!heldCommit.arrive(intent), "metadata may arrive before a gesture is decided");
    Check(intent.commit(heldCommit.ticket) && heldCommit.arrive(intent) && heldCommit.allocations==1,
        "buffered metadata may allocate after a matching explicit inward release");
    Check(!heldCommit.arrive(intent) && heldCommit.allocations==1, "replayed metadata cannot create a second host");

    PendingReply selectedA{intent.begin(false)};
    PendingReply selectedB{intent.begin(false)};
    Check(selectedB.ticket>selectedA.ticket && !selectedA.arrive(intent) && selectedB.arrive(intent),
        "selecting another row invalidates all callbacks from the previous selection");
    Check(selectedA.allocations==0 && selectedB.allocations==1, "only the current selection may allocate");
    PendingReply firstUseLoad{intent.begin(false)};
    intent.cancel();
    Check(!firstUseLoad.arrive(intent), "closing the first-use auto-open chooser invalidates its load callback");
    for(unsigned reason=0;reason<5;reason++) {
        PendingReply pending{intent.begin((reason%2)==0)};
        // The caller uses cancel for lock, disable, edge change, outward release
        // and chooser dismissal; no event name receives a special exception.
        intent.cancel(); intent.cancel();
        Check(!pending.arrive(intent) && !intent.commit(pending.ticket) && pending.allocations==0,
            "repeated invalidation is idempotent for every UI cancellation source");
    }
    const auto beforeCancel=intent.begin(false);
    intent.cancel();
    const auto afterCancel=intent.begin(false);
    Check(afterCancel>beforeCancel && !intent.current(beforeCancel), "cancellation never reuses an opaque ticket");
    Check(!intent.consume(afterCancel+1) && intent.ready(afterCancel), "a fabricated future ticket cannot revoke current state");
    Check(!intent.commit(0) && !intent.consume(0) && intent.ready(afterCancel), "zero operations do not mutate a valid intent");
    intent.cancel();

    constexpr auto maximum=std::numeric_limits<std::uint64_t>::max();
    PPOInteractionIntent nearEnd(maximum-2);
    const auto last=nearEnd.begin(true);
    Check(last==maximum-1 && nearEnd.held(last), "last usable generation remains a genuine held ticket");
    Check(nearEnd.commit(last) && nearEnd.consume(last), "last usable generation is one-shot normally");
    Check(nearEnd.begin(false)==0, "generation maximum becomes a fail-closed sentinel without overflow");
    Inactive(nearEnd,last); Inactive(nearEnd,maximum); Inactive(nearEnd,0);
    for(unsigned i=0;i<128;i++) {
        nearEnd.cancel();
        Check(nearEnd.begin((i%2)==0)==0 && !nearEnd.commit(last) && !nearEnd.consume(last),
            "exhaustion remains permanent through cancellation and repeated requests");
    }
    PPOInteractionIntent exhausted(maximum),almostExhausted(maximum-1);
    Check(exhausted.begin(false)==0 && almostExhausted.begin(true)==0,
        "constructed exhausted counters cannot wrap or publish sentinel tickets");
    PPOInteractionIntent exhaustingActive(maximum-2);
    const auto outstanding=exhaustingActive.begin(true);
    Check(exhaustingActive.begin(false)==0 && !exhaustingActive.current(outstanding) &&
        !exhaustingActive.commit(outstanding), "an exhausted replacement invalidates outstanding callbacks immediately");

    // Simulate asynchronous completions arriving in arbitrary order while the
    // UI starts, commits, replaces, cancels and consumes requests. Properties
    // are checked against the externally observable one-shot contract.
    std::mt19937_64 random(0x50504f494e54454eULL);
    PPOInteractionIntent mixed;
    std::vector<std::uint64_t> history{0};
    std::uint64_t current=0,lastIssued=0;
    bool active=false,held=false;
    unsigned consumed=0,allocations=0;
    for(unsigned i=0;i<100000;i++) {
        const auto action=random()%6;
        if(action==0 || action==1) {
            held=(action==1); current=mixed.begin(held); active=true;
            Check(current>lastIssued && current!=0, "new UI request advances monotonically in mixed sequence");
            lastIssued=current; history.push_back(current);
        } else if(action==2) {
            mixed.cancel(); active=false; held=false;
        } else {
            const auto ticket=history[static_cast<std::size_t>(random()%history.size())];
            const bool matching=active && ticket==current && ticket!=0;
            if(action==3) {
                const bool expected=matching && held;
                Check(mixed.commit(ticket)==expected, "only the current held gesture accepts a commit");
                if(expected)held=false;
            } else {
                const bool expected=matching && !held;
                Check(mixed.consume(ticket)==expected, "only the current ready callback accepts one-shot creation");
                if(expected) { consumed++; allocations++; active=false; held=false; }
                Check(!mixed.consume(ticket), "immediate replay is always denied after any callback result");
            }
        }
        Check(mixed.current(current)==active && mixed.ready(current)==(active&&!held) &&
            mixed.held(current)==(active&&held), "all observable flags track mixed UI intent state");
        Check(!mixed.current(0) && !mixed.ready(0) && !mixed.held(0), "zero never becomes current during mixed callbacks");
        if(history.size()>1) {
            const auto old=history[static_cast<std::size_t>(random()%(history.size()-1))];
            Inactive(mixed,old);
        }
    }
    Check(allocations==consumed, "simulated creations are accounted for by successful one-shot consumption");
    std::printf("Interaction intent tests passed: %u checks; public UI cancellation/one-shot coordination, not iOS hosting\n",checks);
    return 0;
}
