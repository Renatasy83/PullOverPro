TARGET := iphone:clang:16.5:15.0
ARCHS := arm64 arm64e
THEOS_PACKAGE_SCHEME := rootless
include $(THEOS)/makefiles/common.mk

TOOL_NAME := ppo-bridge
ppo-bridge_FILES := main.mm PPOWorkspace.mm PPOBridgeService.mm PPOBundleSceneReader.mm $(abspath ../../PPOSceneCapability.mm) $(abspath ../../PPOAppData.mm) $(abspath ../../PPOBridgeProtocol.mm) $(abspath ../../PPOBridgeIO.cpp)
ppo-bridge_CFLAGS := -Wall -Wextra -Werror
ppo-bridge_CCFLAGS := -std=c++17
ppo-bridge_OBJCFLAGS := -fobjc-arc
ppo-bridge_FRAMEWORKS := Foundation CoreFoundation
ppo-bridge_INSTALL_PATH := /usr/bin

include $(THEOS_MAKE_PATH)/tool.mk
