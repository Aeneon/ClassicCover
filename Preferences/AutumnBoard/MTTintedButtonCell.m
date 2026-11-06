/*
	MTTintedButtonCell.m
	AutumnBoard

	Created by MacThemes on 10/28/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import "MTTintedButtonCell.h"
#import "MTAutumnBoard.h"

@implementation MTTintedButtonCell
{
	UIColor *_buttonTextColor;
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

			if([label isEqualToString: @"CCBackgroundImageButton"])
			{
				self -> _buttonTextColor = [autumnBoard buttonBackgroundImage];
			}
			else if([label isEqualToString: @"CCOpenSourceButton"])
			{
				self -> _buttonTextColor = [autumnBoard buttonOpenSource];
			}

			return self;
		}

	#pragma mark -
	#pragma mark Private Methods

		- (void)layoutSubviews
		{
			[super layoutSubviews];

			// Only restore the Button's Colors when necessary …

			if(!_buttonTextColor)
			{
				return;
			}

			// Get the Label of our Button …

			UILabel *buttonLabel = [self textLabel];

			// Set the Label's Tint Color …

			if(![buttonLabel.textColor isEqual: _buttonTextColor])
			{
				[buttonLabel setTextColor: _buttonTextColor];
			}

			if(![buttonLabel.highlightedTextColor isEqual: _buttonTextColor])
			{
				[buttonLabel setHighlightedTextColor: _buttonTextColor];
			}
		}

@end
