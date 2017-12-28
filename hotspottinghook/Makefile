include theos/makefiles/common.mk

TWEAK_NAME = Hotspotting

Hotspotting_FILES = /mnt/d/codes/hotspotting/hotspottinghook/Hotspotting.xm
Hotspotting_FRAMEWORKS = CydiaSubstrate UIKit IOKit
Hotspotting_LDFLAGS = -Wl,-segalign,4000

export ARCHS = armv7 arm64
Hotspotting_ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
	
all::
	