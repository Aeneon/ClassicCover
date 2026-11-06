BUNDLE_NAME = ClassicCoverPrefs

include $(THEOS)/makefiles/common.mk

$(BUNDLE_NAME)_CFLAGS += -fobjc-arc -ffast-math -flto=thin -fomit-frame-pointer -ftree-vectorize -O3 -Wformat
$(BUNDLE_NAME)_FILES = $(wildcard *.m) $(wildcard ./*/*.m) $(wildcard ../MT*.m) ../ClassicCover/CCPrefsManager.m
$(BUNDLE_NAME)_IDENTIFIER = com.macthemes.classiccover
$(BUNDLE_NAME)_INSTALL_PATH = /Library/PreferenceBundles
$(BUNDLE_NAME)_LDFLAGS += -flto=thin -Wl,-S,-x,-dead_strip,-undefined,dynamic_lookup
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = Preferences

THEOS_STAGING_DIR = ../Packages/$($(BUNDLE_NAME)_IDENTIFIER)/

DEBUG = 0
FINALPACKAGE = 1

include $(THEOS_MAKE_PATH)/bundle.mk
