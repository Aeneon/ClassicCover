/*
	MTCoreHaptic.h
	ClassicCover

	Created by MacThemes with Claude.AI on 10/6/26.
	Copyright © 2026 MacThemes. All rights reserved.

	Small Wrapper around Taptic Engine Feedback that works all the Way back to iOS 9:

	- Uses undocumented System Sound IDs Apple itself used internally for 3D Touch "Peek & Pop" Haptics on iOS 9's Taptic-Engine-equipped Devices.
	- On Devices without a Taptic Engine, this silently does nothing - it's always safe to call.
*/

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MTCoreHapticFeedbackStyle)
{
	MTCoreHapticFeedbackStyleLight,	// Roughly matches iOS 10's `UIImpactFeedbackStyleLight` …
	MTCoreHapticFeedbackStyleMedium, // Roughly matches iOS 10's `UIImpactFeedbackStyleMedium` …
	MTCoreHapticFeedbackStyleError	// Roughly matches iOS 10's `UINotificationFeedbackTypeError` …
};

@interface MTCoreHaptic: NSObject

	+ (void)triggerFeedbackWithPreference: (MTCoreHapticFeedbackStyle)style;
	+ (void)triggerFeedbackWithValue: (MTCoreHapticFeedbackStyle)style value: (BOOL)value;

@end
