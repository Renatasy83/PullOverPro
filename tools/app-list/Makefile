TARGET := iphone:clang:16.5:15.0
ARCHS := arm64 arm64e
THEOS_PACKAGE_SCHEME := rootless
include $(THEOS)/makefiles/common.mk

TOOL_NAME := ppo-apps
ppo-apps_FILES := main.m
ppo-apps_CFLAGS := -fobjc-arc -Wall -Wextra -Werror
ppo-apps_FRAMEWORKS := Foundation
ppo-apps_INSTALL_PATH := /usr/bin

include $(THEOS_MAKE_PATH)/tool.mk
