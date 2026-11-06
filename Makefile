TWEAK_NAME = ClassicCover

export TARGET = iphone:clang:latest:9.0
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

$(TWEAK_NAME)_IDENTIFIER = com.macthemes.classiccover

THEOS_STAGING_DIR = Packages/$($(TWEAK_NAME)_IDENTIFIER)/

DEBUG = 0
FINALPACKAGE = 1

SUBPROJECTS += ClassicCover Preferences Tweaks/Loader Tweaks/CoreMotion Tweaks/UIKit

include $(THEOS_MAKE_PATH)/aggregate.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)DEBIAN$(ECHO_END)
	$(ECHO_NOTHING)cp -r Debian/$($(TWEAK_NAME)_IDENTIFIER)/* $(THEOS_STAGING_DIR)$(ECHO_END)
	$(ECHO_NOTHING)$(THEOS_BIN_PATH)/convert_xml_plist.sh -D $(THEOS_STAGING_DIR)$(ECHO_END)
	$(ECHO_NOTHING)$(THEOS_PROJECT_DIR)/SetFileChangeDate $(THEOS_STAGING_DIR)$(ECHO_END)
