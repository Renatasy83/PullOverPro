# Theos requires bash; select an existing path before any shell expressions.
ifeq ($(origin SHELL),default)
SHELL := $(firstword $(wildcard /var/jb/bin/bash /var/jb/usr/bin/bash /bin/bash))
endif
export SHELL

TARGET := iphone:clang:16.5:15.0
ARCHS := arm64 arm64e
THEOS_PACKAGE_SCHEME := rootless
INSTALL_TARGET_PROCESSES := SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := PullOverProDiagnostic
PullOverProDiagnostic_FILES := Tweak.xm
PullOverProDiagnostic_CFLAGS := -fobjc-arc
PullOverProDiagnostic_FRAMEWORKS := Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

