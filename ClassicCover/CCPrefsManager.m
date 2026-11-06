/*
	CCPrefsManager.m
	ClassicCover

	Created by c0ldra1n on 1/1/18; Updated by MacThemes on 11/3/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import "CCPrefsManager.h"

#import "../MTCoreLogic.h"

#import "iCarousel/iCarousel.h"

// Preferences …

NSString * const CCPrefsEnabledKey = @"enabled";

NSString * const CCPrefsCoverStyleKey = @"coverStyle";
NSString * const CCPrefsArtworkSizeKey = @"artworkSize";

NSString * const CCPrefsSortMethodKey = @"sortMethod";

NSString * const CCPrefsBackgroundStyleKey = @"backgroundStyle";
NSString * const CCPrefsBackgroundColorKey = @"backgroundColor";

NSString * const CCPrefsAutoHideAlbumMetaKey = @"autoHideAlbumMeta";
NSString * const CCPrefsReflectionKey = @"reflection";
NSString * const CCPrefsReflectionBlurKey = @"reflectionBlur";
NSString * const CCPrefsFlipShadowKey = @"flipShadow";

NSString * const CCPrefsHapticFeedbackKey = @"hapticFeedback";

NSString * const CCPrefsDemoEnabledKey = @"demoEnabled";
NSString * const CCPrefsPreventSleepKey = @"preventSleep";

NSString * const CCPrefsDebugLoggingKey = @"debugLogging";

// Our Shared Instance …

static CCPrefsManager *sharedInstance;

// Indicate, if the Preferences were changed …

BOOL CCPreferencesHaveChanged = YES;

// Called whenever `MTNotificationPreferenceChange` fires - i.e. right after "Preferences.framework" commits a changed Switch Value to Disk. Keeps `_preferences` fresh without needing a Relaunch …

static void CCPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	// Let's get back to the Main Thread …

	dispatch_async(dispatch_get_main_queue(), ^
	{
		[[CCPrefsManager sharedInstance] reload];
	});
}

@implementation CCPrefsManager

	#pragma mark -
	#pragma mark Shared Instance

		+ (CCPrefsManager *)sharedInstance
		{
			return sharedInstance;
		}

	#pragma mark -
	#pragma mark Lifecycle

		- (instancetype)init
		{
			self = [super init];

			if(self)
			{
				[self reload];

				// Stay in Sync across Processes: Preferences.app writes the Property List and posts this Notification the Moment a Switch changes - reload our Cache right away instead of waiting for the next Launch …

				CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)self, CCPreferencesChanged, (CFStringRef)MTNotificationPreferenceChange, NULL, CFNotificationSuspensionBehaviorCoalesce);

				/*
					Safety Net: While Music.app is suspended in the Background, the Darwin Notification above is only coalesced and delivered with a Delay once the Process resumes …

					`UIApplicationDidBecomeActiveNotification` fires synchronously as soon as the App is active again, so we force a fresh Reload from Disk right here …
				*/
				[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reload) name: UIApplicationDidBecomeActiveNotification object: nil];
			}

			return self;
		}

		- (void)dealloc
		{
			// Remove the Observers …

			CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)self);

			[[NSNotificationCenter defaultCenter] removeObserver: self];
		}

	#pragma mark -
	#pragma mark Private Methods

		+ (void)setup
		{
			static BOOL prefs_init;

			if(!prefs_init)
			{
				sharedInstance = [[CCPrefsManager alloc] init];

				prefs_init = YES;
			}
		}

		+ (void)load
		{
			[CCPrefsManager setup];
		}

	#pragma mark -
	#pragma mark Public Methods

		- (void)reload
		{
			// Writes to permanent Storage all pending Changes to the Preference Data for the Application, and reads the latest Preference Data from permanent Storage …

			CFPreferencesAppSynchronize((CFStringRef)CCPreferencesDomain);

			// Load Preferences from Disk or initialize a new Dictionary …

			NSDictionary *preferences = ([[NSDictionary alloc] initWithContentsOfFile: CCFileManagerPreferences] ?: @{});

			// Replacing a Photo or the System Wallpaper changes no Preference-Key. Inspect only Metadata so unchanged Backgrounds avoid a new Decoding / Blur …

			NSInteger backgroundStyle = [self -> _preferences[CCPrefsBackgroundStyleKey] integerValue];

			NSArray<NSString *> *paths = @[];

			if(backgroundStyle == CCBackgroundStylePhoto || backgroundStyle == CCBackgroundStylePhotoBlur)
			{
				paths = @[CCFileManagerCacheBackground];
			}
			else if(backgroundStyle == CCBackgroundStyleWallpaperBlur)
			{
				paths = @[@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap", @"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap"];
			}

			NSMutableArray *backgroundFingerprint = [NSMutableArray array];

			for(NSString *path in paths)
			{
				NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path error: nil];

				[backgroundFingerprint addObject: @[path, attributes[NSFileModificationDate] ?: [NSNull null], attributes[NSFileSize] ?: @0, attributes[NSFileSystemFileNumber] ?: @0]];
			}

			@synchronized(self)
			{
				if(self -> _preferences && [self -> _preferences isEqualToDictionary: preferences] && [self -> _backgroundFingerprint isEqualToArray: backgroundFingerprint])
				{
					return;
				}

				self -> _preferences = preferences;
				self -> _backgroundFingerprint = backgroundFingerprint;

				// Get our Default Values, if they're not exist …

				if(!self -> _defaults)
				{
					self -> _defaults =	@{
											CCPrefsEnabledKey: @(YES),

											CCPrefsCoverStyleKey: @(iCarouselTypeCoverFlow),
											CCPrefsArtworkSizeKey: @(CCArtworkSizeBig),

											CCPrefsSortMethodKey: @(CCSortMethodAlbumArtist),

											CCPrefsBackgroundStyleKey: @(CCBackgroundStyleColorPlain),
											CCPrefsBackgroundColorKey: @"#010101",

											CCPrefsAutoHideAlbumMetaKey: @(NO),
											CCPrefsReflectionKey: @(YES),
											CCPrefsReflectionBlurKey: @(NO),
											CCPrefsFlipShadowKey: @(YES),

											CCPrefsHapticFeedbackKey: @(YES),

											CCPrefsDemoEnabledKey: @(NO),
											CCPrefsPreventSleepKey: @(NO),

											CCPrefsDebugLoggingKey: @(NO)
										};
				}

				// Check if Debug Logging is ( still ) enabled …

				self.debugLogging = [preferences[CCPrefsDebugLoggingKey] boolValue];

				// Indicate, that the Preferences have changed …

				CCPreferencesHaveChanged = YES;
			}
		}

		- (id)valueForPreferenceKey: (NSString *)key
		{
			// Check, if Preferences already contain a Key, if now use the Default One. A Reader sees one immutable Snapshot even if a Notification reloads Preferences …

			@synchronized(self)
			{
				return self -> _preferences[key] ?: self -> _defaults[key];
			}
		}

@end
