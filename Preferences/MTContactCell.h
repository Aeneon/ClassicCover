/*
	MTContactCell.h
	ClassicCover

	Created by MacThemes on 10/28/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import <Foundation/Foundation.h>

#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>

#import <UIKit/UIKit.h>

@interface MTContactCell: PSTableCell

	- (void)refreshSubTitleWithSpecifier: (PSSpecifier *)specifier;

@end
