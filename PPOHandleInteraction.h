#pragma once

#include "PPOEdgeDrawerGeometry.h"
#include <cstdint>
#include <limits>

// Public handle commands only. Opening a selected/chosen app still requires
// the caller's frozen identity, freshness, intent and owned-scene admission.
// A reveal command never authorizes metadata inspection, launch or hosting.
enum class PPOHandleAction {
    None,
    RevealChooser,
    HideChooser,
    OpenSelected,
    OpenChosen,
    ToggleOwned,
    FinishOwnedGesture
};

class PPOHandleInteraction {
public:
    explicit PPOHandleInteraction(std::uint64_t panSeed = 0) noexcept
        : panGeneration_(panSeed) {}

    bool revealed() const noexcept { return revealed_; }
    bool panActive() const noexcept { return panActive_; }

    // Genuine dismissal, lock/disable or edge change clears the second-step
    // readiness. Merely rebuilding/presenting a chooser must not call reset.
    void reset() noexcept {
        revealed_ = false;
        cancelPan();
    }

    // Invoke once per distinct UIControl tap action, not on pan completion or
    // an asynchronous callback. A nubbed tap only reveals, even if an owned
    // scene is retained behind it. A retracted owned scene also needs reveal
    // before a separate tap can open it; an already open one may be retracted.
    // Existing-window toggling never creates a new scene.
    PPOHandleAction tap(bool allowed, bool selectedAvailable,
        bool ownedWindowPresent, bool ownedWindowOpen, bool nubbed) noexcept {
        cancelPan();
        if (!allowed || (ownedWindowOpen && !ownedWindowPresent)) {
            reset(); return PPOHandleAction::None;
        }
        if (nubbed) { revealed_ = true; return PPOHandleAction::RevealChooser; }
        if (ownedWindowPresent && ownedWindowOpen) {
            revealed_ = false;
            return PPOHandleAction::ToggleOwned;
        }
        if (!revealed_ || (!selectedAvailable && !ownedWindowPresent)) {
            revealed_ = true;
            return PPOHandleAction::RevealChooser;
        }
        revealed_ = false;
        return ownedWindowPresent ? PPOHandleAction::ToggleOwned : PPOHandleAction::OpenSelected;
    }

    PPOHandleAction longPress(bool allowed) noexcept {
        cancelPan();
        if (!allowed) { reset(); return PPOHandleAction::None; }
        revealed_ = true;
        return PPOHandleAction::RevealChooser;
    }

    // The caller must already have validated that this immutable row belongs
    // to the currently visible generation. An unavailable/hidden row cannot
    // create a scene request through this policy.
    PPOHandleAction rowSelection(bool allowed, bool available) noexcept {
        cancelPan();
        if (!allowed) { reset(); return PPOHandleAction::None; }
        if (!revealed_ || !available) return PPOHandleAction::None;
        revealed_ = false;
        return PPOHandleAction::OpenChosen;
    }

    // Route only ordinary drawer pans here after PPOHandleNubState has locked
    // their direction. Outward nub and vertical positioning stay separate.
    // Pass true only for an owned window that is already OPEN, not merely
    // retained/retracted. A first inward pull on a retained closed window is
    // still chooser reveal. Beginning/moving never arms a tap or starts work.
    std::uint64_t beginPan(PPOEdgeDrawerSide side, bool allowed,
        bool ownedWindowOpen) noexcept {
        cancelPan();
        if (!allowed || !PPOEdgeDrawerDetail::Side(side)) {
            reset(); return 0;
        }
        constexpr auto maximum = std::numeric_limits<std::uint64_t>::max();
        if (panGeneration_ >= maximum - 1) {
            panGeneration_ = maximum;
            reset(); return 0;
        }
        ++panGeneration_;
        beganRevealed_ = revealed_;
        panOwned_ = ownedWindowOpen;
        panActive_ = true;
        return panGeneration_;
    }

    // Consume one matching terminal event. A stale/duplicate terminal cannot
    // reveal, toggle or arm anything. Even a committed inward pan can only
    // reveal the chooser (or finish an already owned window's public slide),
    // never open the selected app. Cancellation preserves prior readiness.
    PPOHandleAction finishPan(std::uint64_t ticket, bool opened,
        bool cancelled) noexcept {
        if (!panActive_ || ticket == 0 || ticket != panGeneration_)
            return PPOHandleAction::None;
        const bool wasRevealed = beganRevealed_;
        const bool owned = panOwned_;
        cancelPan();
        if (cancelled) {
            revealed_ = wasRevealed;
            if (owned) return PPOHandleAction::FinishOwnedGesture;
            return wasRevealed ? PPOHandleAction::RevealChooser : PPOHandleAction::HideChooser;
        }
        revealed_ = owned ? false : opened;
        if (owned) return PPOHandleAction::FinishOwnedGesture;
        return opened ? PPOHandleAction::RevealChooser : PPOHandleAction::HideChooser;
    }

private:
    void cancelPan() noexcept {
        panActive_ = false;
        beganRevealed_ = false;
        panOwned_ = false;
    }

    bool revealed_ = false;
    bool panActive_ = false;
    bool beganRevealed_ = false;
    bool panOwned_ = false;
    std::uint64_t panGeneration_ = 0;
};
