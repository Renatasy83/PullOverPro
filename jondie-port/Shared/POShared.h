// Shared between the tweak (SpringBoard) and the settings bundle.
#define PODomain @"com.johndie.pulloverpro-rootless"
#define POStateDomain @"com.johndie.pulloverpro-rootless.state"   // handle position, last pinned app
#define POPrefsChangedNotification "com.johndie.pulloverpro-rootless/changed"
// Commands other tweaks can post (Darwin notifications):
// pull the pinned app over, close it, or switch between the two.
#define POOpenNotification "com.johndie.pulloverpro-rootless/open"
#define POCloseNotification "com.johndie.pulloverpro-rootless/close"
#define POToggleNotification "com.johndie.pulloverpro-rootless/toggle"

// "Hide Handle" only exists with the PullOver Pro for Triggr add-on installed,
// since its Triggr actions are then the only way to pull an app over.
#include <rootless.h>
#include <unistd.h>
static inline BOOL POTriggrAddonInstalled(void) {
    return access(ROOT_PATH("/Library/MobileSubstrate/DynamicLibraries/PullOverTriggr.dylib"), F_OK) == 0;
}
