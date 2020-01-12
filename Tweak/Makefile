ARCHS = arm64 arm64e
TARGET = iphone:12.2:12.2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Axon
$(TWEAK_NAME)_FILES = Tweak.xm $(wildcard AXN*.m)
$(TWEAK_NAME)_FRAMEWORKS += QuartzCore WebKit MediaPlayer
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
