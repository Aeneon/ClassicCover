/*
	CCPrefsManager.h
	ClassicCover

	Created by c0ldra1n on 1/1/18; Updated by MacThemes on 11/3/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define CC_PREFS_VALUE_FOR_KEY(key) [[CCPrefsManager sharedInstance] valueForPreferenceKey: key]

// Preferences …

extern NSString * const CCPrefsEnabledKey;

extern NSString * const CCPrefsCoverStyleKey;
extern NSString * const CCPrefsArtworkSizeKey;

extern NSString * const CCPrefsSortMethodKey;

extern NSString * const CCPrefsBackgroundStyleKey;
extern NSString * const CCPrefsBackgroundColorKey;

extern NSString * const CCPrefsAutoHideAlbumMetaKey;
extern NSString * const CCPrefsReflectionKey;
extern NSString * const CCPrefsReflectionBlurKey;
extern NSString * const CCPrefsFlipShadowKey;

extern NSString * const CCPrefsHapticFeedbackKey;

extern NSString * const CCPrefsDemoEnabledKey;
extern NSString * const CCPrefsPreventSleepKey;

extern NSString * const CCPrefsDebugLoggingKey;

typedef NS_ENUM(NSUInteger, CCBackgroundStyle)
{
	CCBackgroundStyleColorPlain = 0,
	CCBackgroundStyleColorRandom = 1,
	CCBackgroundStyleColorAlbum = 2,
	CCBackgroundStylePhoto = 3,
	CCBackgroundStylePhotoBlur = 4,
	CCBackgroundStyleWallpaperBlur = 5
};

typedef NS_ENUM(NSUInteger, CCArtworkSize)
{
	CCArtworkSizeBig = 0,
	CCArtworkSizeMedium = 1,
	CCArtworkSizeSmall = 2
};

typedef NS_ENUM(NSUInteger, CCSortMethod)
{
	CCSortMethodAlbum = 0,
	CCSortMethodAlbumArtist = 1,
	CCSortMethodArtist = 2,
	CCSortMethodGenre = 3,
	CCSortMethodDateAddedAscending = 4,
	CCSortMethodDateAddedDescending = 5,
	CCSortMethodLastPlayedDateAscending = 6,
	CCSortMethodLastPlayedDateDescending = 7,
	CCSortMethodRandom = 8
};

// Indicate, if the Preferences were changed …

extern BOOL CCPreferencesHaveChanged;

// The Interface of our Preferences Manager …

@interface CCPrefsManager: NSObject
{
	NSDictionary *_defaults;
	NSDictionary *_preferences;

	NSArray *_backgroundFingerprint;
}

	@property (assign, atomic, readwrite) BOOL debugLogging;

	+ (CCPrefsManager *)sharedInstance;

	- (void)reload;

	- (id)valueForPreferenceKey: (NSString *)key;

@end
