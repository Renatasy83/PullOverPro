# Select an existing bash before Theos evaluates shell expressions (including on rootless iOS).
ifeq ($(origin SHELL),default)
SHELL := $(firstword $(wildcard /var/jb/bin/bash /var/jb/usr/bin/bash /bin/bash))
endif
export SHELL

export ARCHS = arm64 arm64e
export TARGET = iphone:clang:16.5:15.0
export THEOS_PACKAGE_SCHEME = rootless

# Only an explicit make install uses this; package creation does not reload SpringBoard.
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += Tweak
SUBPROJECTS += Prefs

include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	install -d "$(THEOS_STAGING_DIR)/usr/share/doc/com.johndie.pulloverpro-rootless"
	install -m 644 LICENSE PROVENANCE.md "$(THEOS_STAGING_DIR)/usr/share/doc/com.johndie.pulloverpro-rootless/"
