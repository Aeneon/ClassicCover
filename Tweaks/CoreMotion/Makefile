LIBRARY_NAME = ClassicCover_CoreMotion

include $(THEOS)/makefiles/common.mk

$(LIBRARY_NAME)_CFLAGS = -fobjc-arc -flto=thin -fomit-frame-pointer -O3 -Wformat
$(LIBRARY_NAME)_FILES = Tweak_CoreMotion.xm ../../MTCoreLogic.m
$(LIBRARY_NAME)_IDENTIFIER = com.macthemes.classiccover
$(LIBRARY_NAME)_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/ClassicCover
$(LIBRARY_NAME)_LDFLAGS = -flto=thin -Wl,-S,-x,-dead_strip,-undefined,dynamic_lookup

THEOS_STAGING_DIR = ../../Packages/$($(LIBRARY_NAME)_IDENTIFIER)/

DEBUG = 0
FINALPACKAGE = 1

include $(THEOS_MAKE_PATH)/library.mk
