TARGET := iphone:clang:16.5:15.0
ARCHS := arm64 arm64e
THEOS_PACKAGE_SCHEME := rootless
include $(THEOS)/makefiles/common.mk

TOOL_NAME := ppo-open
ppo-open_FILES := main.mm $(abspath ../../PPOAppData.mm)
ppo-open_CFLAGS := -fobjc-arc -Wall -Wextra -Werror
ppo-open_FRAMEWORKS := Foundation
ppo-open_INSTALL_PATH := /usr/bin

include $(THEOS_MAKE_PATH)/tool.mk
