TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e
THEOS_PACKAGE_SCHEME := rootless
INSTALL_TARGET_PROCESSES := SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := PullOverProDiagnostic
PullOverProDiagnostic_FILES := Tweak.xm
PullOverProDiagnostic_CFLAGS := -fobjc-arc
PullOverProDiagnostic_FRAMEWORKS := Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
