/*
	Tweak_CoreMotion.h
	ClassicCover

	Created by MacThemes on 11/3/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import <CoreMotion/CoreMotion.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIApplication()

	- (UIWindow *)statusBarWindow;

@end

@interface ClassicCover: NSObject
{
	// The Host View and ClassicCover's View Controller …

	UIView *hostView;
	UIViewController *viewController;

	// Our previous Device Orientation …

	UIDeviceOrientation orientationOld;
}

	// The Host View and ClassicCover's View Controller …

	@property (nonatomic, strong) UIView *hostView;
	@property (nonatomic, strong) UIViewController *viewController;

	// Our previous Device Orientation …

	@property (nonatomic, assign) UIDeviceOrientation orientationOld;

	// Methods …

	+ (id)sharedInstance;

	- (void)applyOrientation: (UIDeviceOrientation)orientation;
	- (void)centerInSuperview;

@end
