/*
	MTCoreHaptic.m
	ClassicCover

	Created by MacThemes with Claude.AI on 10/6/26.
	Copyright © 2026 MacThemes. All rights reserved.

	Small Wrapper around Taptic Engine Feedback that works all the Way back to iOS 9:

	- Uses undocumented System Sound IDs Apple itself used internally for 3D Touch "Peek & Pop" Haptics on iOS 9's Taptic-Engine-equipped Devices.
	- On Devices without a Taptic Engine, this silently does nothing - it's always safe to call.
*/

#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>

#import "MTCoreHaptic.h"

#import "ClassicCover/CCPrefsManager.h"

@implementation MTCoreHaptic

	#pragma mark -
	#pragma mark Private Methods

		+ (void)triggerFeedback: (MTCoreHapticFeedbackStyle)style
		{
			/*
				Pre-iOS 10 Fallback: Apple itself drove 3D Touch's "Peek & Pop" Haptics on iOS 9's Taptic-Engine-equipped Devices through this exact, fully public `AudioServicesPlaySystemSound` API - only the specific System Sound ID is undocumented …

				The commonly-documented IDs:

					- 1519: "Peek", a light Tap, roughly matches `UIImpactFeedbackStyleLight`
					- 1520: "Pop", a firmer Tap, roughly matches `UIImpactFeedbackStyleMedium`
					- 1521: "Nope", a sharp Double-Pulse, roughly matches `UINotificationFeedbackTypeError`

				On Devices without a Taptic Engine, this System Sound ID silently does nothing.
			*/

			SystemSoundID soundID;

			switch(style)
			{
				case MTCoreHapticFeedbackStyleMedium: // "Pop" - A firmer Tap …
				{
					soundID = 1520; break;
				}
				case MTCoreHapticFeedbackStyleError: // "Nope" - A sharp Double-Pulse …
				{
					soundID = 1521; break;
				}
				default: // "Peek" - A light Tap …
				{
					soundID = 1519; break;
				}
			}

			AudioServicesPlaySystemSound(soundID);
		}

	#pragma mark -
	#pragma mark Public Methods

		+ (void)triggerFeedbackWithPreference: (MTCoreHapticFeedbackStyle)style
		{
			// Check if Haptic Feedback is enabled in Preferences …

			if([CC_PREFS_VALUE_FOR_KEY(CCPrefsHapticFeedbackKey) boolValue])
			{
				[self triggerFeedback: style];
			}
		}

		+ (void)triggerFeedbackWithValue: (MTCoreHapticFeedbackStyle)style value: (BOOL)value
		{
			// Check if Haptic Feedback is requested …

			if(value)
			{
				[self triggerFeedback: style];
			}
		}

@end
