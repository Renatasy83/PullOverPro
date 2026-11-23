include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PullOverPro
PullOverPro_FILES = Tweak.xm ContextHostManager.mm $(wildcard *.m)
PullOverPro_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-objc-property-no-attribute -Wno-incomplete-implementation
PullOverPro_FRAMEWORKS = UIKit QuartzCore
PullOverPro_PRIVATE_FRAMEWORKS = FrontBoard

include $(THEOS_MAKE_PATH)/tweak.mk
