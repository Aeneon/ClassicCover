/*
	MTTintedSwitchCell.m
	AutumnBoard

	Created by MacThemes on 10/28/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import "MTTintedSwitchCell.h"
#import "MTAutumnBoard.h"

@implementation MTTintedSwitchCell
{
	UIColor *_switchOnTintColor;
}

	#pragma mark -
	#pragma mark Lifecycle

		- (instancetype)initWithStyle: (UITableViewCellStyle)style reuseIdentifier: (NSString *)identifier specifier: (PSSpecifier *)specifier
		{
			self = [super initWithStyle: style reuseIdentifier: identifier specifier: specifier];

			// Allocate and initialize Theming Engine …

			MTAutumnBoard *autumnBoard = [MTAutumnBoard sharedInstance];

			// Get the Label-Property from the given Preference-Specifier …

			NSString *label = [specifier propertyForKey: @"label"];

			// If the Label-Property equals the given Label, set the Tint Color we want to use …

			if([label isEqualToString: @"CCDebugSwitch"])
			{
				self -> _switchOnTintColor = [autumnBoard switchDebugLogging];
			}
			else if([label isEqualToString: @"CCEnableSwitch"])
			{
				self -> _switchOnTintColor = [autumnBoard switchEnable];
			}
			else if([label isEqualToString: @"CCAlbumMetaAutoHideSwitch"])
			{
				self -> _switchOnTintColor = [autumnBoard switchAutoHideLabels];
			}
			else if([label isEqualToString: @"CCDemoEnableSwitch"])
			{
				self -> _switchOnTintColor = [autumnBoard switchDemoEnable];
			}
			else if([label isEqualToString: @"CCHapticFeedbackSwitch"])
			{
				self -> _switchOnTintColor = [autumnBoard switchHapticFeedback];
			}
			else if([label isEqualToString: @"CCPreventSleepSwitch"])
			{
				self -> _switchOnTintColor = [autumnBoard switchPreventSleep];
			}
			else if([label isEqualToString: @"CCVisualEffectsFlipShadowSwitch"])
			{
				self -> _switchOnTintColor = [autumnBoard switchFlipShadow];
			}
			else if([label isEqualToString: @"CCVisualEffectsReflectionSwitch"])
			{
				self -> _switchOnTintColor = [autumnBoard switchReflection];
			}
			else if([label isEqualToString: @"CCVisualEffectsReflectionBlurSwitch"])
			{
				self -> _switchOnTintColor = [autumnBoard switchReflectionBlur];
			}

			// Set the Switch's Tint Color …

			[((UISwitch *)self.control) setOnTintColor: self -> _switchOnTintColor];

			return self;
		}

@end
