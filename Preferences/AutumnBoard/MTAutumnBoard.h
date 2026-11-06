/*
	MTAutumnBoard.h
	AutumnBoard

	Created by MacThemes on 10/28/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MTAutumnBoard: NSObject

	+ (instancetype)sharedInstance;

	@property (strong, nonatomic) UIColor *buttonArtworkCache;
	@property (strong, nonatomic) UIColor *buttonBackgroundImage;
	@property (strong, nonatomic) UIColor *buttonOpenSource;
	@property (strong, nonatomic) UIColor *buttonOrphanedArtworks;

	@property (strong, nonatomic) UIColor *generalNavigationBar;
	@property (strong, nonatomic) UIColor *generalWindow;

	@property (strong, nonatomic) UIColor *socialTwitter;
	@property (strong, nonatomic) UIColor *socialWebsite;

	@property (strong, nonatomic) UIColor *switchAutoHideLabels;
	@property (strong, nonatomic) UIColor *switchDebugLogging;
	@property (strong, nonatomic) UIColor *switchDemoEnable;
	@property (strong, nonatomic) UIColor *switchEnable;
	@property (strong, nonatomic) UIColor *switchFlipShadow;
	@property (strong, nonatomic) UIColor *switchHapticFeedback;
	@property (strong, nonatomic) UIColor *switchPreventSleep;
	@property (strong, nonatomic) UIColor *switchReflection;
	@property (strong, nonatomic) UIColor *switchReflectionBlur;

@end
