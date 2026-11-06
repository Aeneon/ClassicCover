/*
	MTEditTextCell.m
	ClassicCover

	Created by MacThemes on 10/28/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import "MTEditTextCell.h"

@implementation MTEditTextCell

	#pragma mark -
	#pragma mark Lifecycle

		- (instancetype)initWithStyle: (UITableViewCellStyle)style reuseIdentifier: (NSString *)identifier specifier: (PSSpecifier *)specifier
		{
			self = [super initWithStyle: style reuseIdentifier: identifier specifier: specifier];

			if(self)
			{
				// Right-align the TextField's Content …

				[self textField].textAlignment = NSTextAlignmentRight;
			}

			return self;
		}

@end
