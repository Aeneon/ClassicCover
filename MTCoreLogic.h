/*
	MTCoreLogic.h
	ClassicCover

	Created by MacThemes on 11/3/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import <UIKit/UIKit.h>

#pragma mark -
#pragma mark Preprocessor Macros

	// `MTLog` provides a Check against Debug Logging in Preferences and also features the ... variadic Arguments ( Variable Argument List ) …

	FOUNDATION_EXPORT void MTLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2) NS_NO_TAIL_CALL;

	// Check, if Debug Logging is enabled …

	FOUNDATION_EXPORT BOOL MTDebugLoggingEnabled(void);

#pragma mark -
#pragma mark Constants - Background

	static CGFloat const CCBackgroundBlurMultiplier = 16.0;
	static CGFloat const CCBackgroundBlurMinimum = 35.0;

	static CGFloat const CCBackgroundDarkeningAlphaHalf = 0.35;
	static CGFloat const CCBackgroundDarkeningAlphaNormal = 0.7;

#pragma mark -
#pragma mark Constants - Buttons

	static CGFloat const CCButtonBackgroundAlphaInactive = 0.5;
	static CGFloat const CCButtonBackgroundAlphaActive = 1.0;

	// The Space between two Buttons at the Bottom of the Screen - must match the Constraints in `ClassicCover.storyboard` …

	static CGFloat const CCButtonSpacing = 14.0;

#pragma mark -
#pragma mark Constants - CPU Families

	static uint32_t const CCCPUFamilyAppleA7 = 0x37a09642;
	static uint32_t const CCCPUFamilyAppleA8 = 0x2c91a47e;

#pragma mark -
#pragma mark Constants - Demo-Loop

	static NSInteger const CCDemoFlipViewChance = 14;

	static NSInteger const CCDemoJumpValueMaximum = 35;
	static NSInteger const CCDemoJumpValueMinimum = 14;

#pragma mark -
#pragma mark Constants - File Manager

	static NSString * const CCFileManagerBundle = @"/Library/Application Support/MacThemes/ClassicCover.bundle";

	static NSString * const CCFileManagerCacheArtwork = @"/var/mobile/Library/Caches/MacThemes/ClassicCover.artworks/";
	static NSString * const CCFileManagerCacheBackground = @"/var/mobile/Library/Caches/MacThemes/ClassicCover.background";

	static NSString * const CCFileManagerPreferences = @"/var/mobile/Library/Preferences/com.macthemes.classiccover.plist";

#pragma mark -
#pragma mark Constants - Flip Container

	static CGFloat const CCFlipContainerMargin = 40.0;

#pragma mark -
#pragma mark Constants - Layers

	static CGFloat const CCLayerRasterizationScale = 1.0;

	static CGFloat const CCLayerHighlightOpacity = 0.35;
	static CGFloat const CCLayerSeparatorOpacity = 0.525;
	static CGFloat const CCLayerShadowOpacity = 0.7;

#pragma mark -
#pragma mark Constants - MarqueeLabel

	static CGFloat const CCMarqueeLabelTrailingBufferMinimum = 70.0;

#pragma mark -
#pragma mark Constants - Notifications

	static NSString * const MTNotificationPreferenceChange = @"com.macthemes.classiccover/Preference.change";

#pragma mark -
#pragma mark Constants - Now Playing

	static NSString * const CCNowPlayingAnimationKey = @"CCNowPlayingBarAnimation";
	static NSString * const CCNowPlayingStopAnimationKey = @"CCNowPlayingBarStopAnimation";
	static NSUInteger const CCNowPlayingBarCount = 3;

	static CGFloat const CCNowPlayingCornerRadius = 1.0;

#pragma mark -
#pragma mark Constants - File Manager

	static NSString * const CCPreferencesDomain = @"com.macthemes.classiccover";

#pragma mark -
#pragma mark Constants - Reflection View

	static CGFloat const CCReflectionViewAlpha = 0.42;
	static CGFloat const CCReflectionViewBlurMultiplier = 61.25;
	static CGFloat const CCReflectionViewBlurMinimum = 3.5;

#pragma mark -
#pragma mark Constants - Shadows

	static CGFloat const CCDropShadowCorner = 2.0;
	static CGFloat const CCDropShadowOffset = 4.0;
	static CGFloat const CCDropShadowOpacity = 0.6;
	static CGFloat const CCDropShadowRadius = 14.0;

	static CGFloat const CCTextShadowRadius = 3.0;
	static CGFloat const CCTextShadowOffset = 2.0;
	static CGFloat const CCTextShadowOpacity = 0.35;

#pragma mark -
#pragma mark Constants - Time Intervals

	static CGFloat const CCIntervalSafeDispatchTime = 0.175;
	static CGFloat const CCIntervalAlbumInfoInactivity = 5.0;

#pragma mark -
#pragma mark Constants - Durations

	static CGFloat const CCDurationDelay = 0.175;

	static CGFloat const CCDurationDemoDelayMaximum = 14.0;
	static CGFloat const CCDurationDemoDelayMinimum = 3.5;

	static CGFloat const CCDurationDemoInactivity = 60.0;

	static CGFloat const CCDurationOneEighth = 0.0875;
	static CGFloat const CCDurationOneQuarter = 0.175;
	static CGFloat const CCDurationHalf = 0.35;
	static CGFloat const CCDurationThreeQuarter = 0.525;
	static CGFloat const CCDurationNormal = 0.7;
	static CGFloat const CCDurationShuffle = 3.5;

#pragma mark -
#pragma mark Defines - Colors

	#define CCColorGeneralButton			[UIColor colorWithRed: (196.0 / 255.0) green: (110.0 / 255.0) blue: 1.0 alpha: 1.0]
	#define CCColorGeneralButtonDestructive	[UIColor colorWithRed: 1.0 green: (57.0 / 255.0) blue: (69.0 / 255.0) alpha: 1.0]
	#define CCColorGeneralNavigationBar		[UIColor colorWithRed: (79.0 / 255.0) green: (117.0 / 255.0) blue: 1.0 alpha: 1.0]
	#define CCColorGeneralSwitch			[UIColor colorWithRed: (138.0 / 255.0) green: (114.0 / 255.0) blue: 1.0 alpha: 1.0]
	#define CCColorGeneralSwitchBright		[UIColor colorWithRed: (160.0 / 255.0) green: (140.0 / 255.0) blue: 1.0 alpha: 1.0]
	#define CCColorGeneralSwitchDestructive	[UIColor colorWithRed: 1.0 green: (57.0 / 255.0) blue: (69.0 / 255.0) alpha: 1.0]
	#define CCColorGeneralWindow			[UIColor colorWithRed: (196.0 / 255.0) green: (110.0 / 255.0) blue: 1.0 alpha: 1.0]

	#define CCColorSocialTwitter			[UIColor colorWithRed: 0.0 green: (152.0 / 255.0) blue: (192.0 / 255.0) alpha: 1.0]
	#define CCColorSocialWebseite			[UIColor colorWithRed: (114.0 / 255.0) green: (115.0 / 255.0) blue: (115.0 / 255.0) alpha: 1.0]

#pragma mark -
#pragma mark Variables - Device Info

	static BOOL CCDeviceIsPreA9SoC;
	static BOOL CCDeviceHasTapticEngine;

#pragma mark -
#pragma mark Variables - Control Queue

	static dispatch_queue_t CCControlQueue;
