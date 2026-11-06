BUNDLE_NAME = ClassicCover

include $(THEOS)/makefiles/common.mk

$(BUNDLE_NAME)_CFLAGS += -fobjc-arc -ffast-math -flto=thin -fomit-frame-pointer -ftree-vectorize -O3 -Wformat
$(BUNDLE_NAME)_FILES = $(filter-out CCPrefsManager.m,$(wildcard *.m)) $(wildcard ./*/*.m) $(wildcard ../MT*.m)
$(BUNDLE_NAME)_IDENTIFIER = com.macthemes.classiccover
$(BUNDLE_NAME)_INSTALL_PATH = /Library/Application Support/MacThemes
$(BUNDLE_NAME)_LDFLAGS += -flto=thin -Wl,-S,-x,-dead_strip,-undefined,dynamic_lookup

THEOS_STAGING_DIR = ../Packages/$($(BUNDLE_NAME)_IDENTIFIER)/

DEBUG = 0
FINALPACKAGE = 1

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)rm -r ./Resources/ClassicCover.storyboardc$(ECHO_END)
	$(ECHO_NOTHING)ibtool --minimum-deployment-target 9.0 --warnings --notices --errors --compile ./Resources/ClassicCover.storyboardc ./ClassicCover.storyboard$(ECHO_END)
