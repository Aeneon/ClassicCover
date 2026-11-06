TWEAK_NAME = ClassicCover

include $(THEOS)/makefiles/common.mk

$(TWEAK_NAME)_CFLAGS += -fobjc-arc -flto=thin -fomit-frame-pointer -O3 -Wformat
$(TWEAK_NAME)_FILES = ClassicCover.xm ../../MTCoreLogic.m ../../ClassicCover/CCPrefsManager.m
$(TWEAK_NAME)_IDENTIFIER = com.macthemes.classiccover
$(TWEAK_NAME)_LDFLAGS += -flto=thin -Wl,-S,-x,-dead_strip,-exported_symbols_list,$(THEOS_PROJECT_DIR)/ClassicCover.exp

THEOS_STAGING_DIR = ../../Packages/$($(TWEAK_NAME)_IDENTIFIER)/

DEBUG = 0
FINALPACKAGE = 1

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Music"
	install.exec "open com.apple.Music"
