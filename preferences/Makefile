TARGET := iphone:clang:16.5:15.0
ARCHS := arm64 arm64e
THEOS_PACKAGE_SCHEME := rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME := PullOverProPortPreferences
PullOverProPortPreferences_FILES := PPOSettingsController.mm ../PPOUserPreferences.mm ../PPOAppData.mm ../PPOFavoriteApps.mm ../PPOFavoritesStore.mm ../PPOSceneCapability.mm
PullOverProPortPreferences_OBJCFLAGS := -fobjc-arc
PullOverProPortPreferences_CCFLAGS := -std=c++17
PullOverProPortPreferences_FRAMEWORKS := Foundation UIKit CoreFoundation
PullOverProPortPreferences_PRIVATE_FRAMEWORKS := Preferences
PullOverProPortPreferences_INSTALL_PATH := /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
