/*
	UIColor+Random.m
	ClassicCover

	Created by MacThemes on 10/6/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import "UIColor+Random.h"

#pragma mark -
#pragma mark UIColor (Random)

	@implementation UIColor(Random)

		+ (UIColor *) randomColor
		{
			return [UIColor randomColor: 1.0];
		}

		+ (UIColor *) randomColor: (double)alpha
		{
			CGFloat hue = (arc4random() % 256 / 256.0); // 0 to 1 …
			CGFloat saturation = (arc4random() % 128 / 256.0) + 0.5; // 0.5 to 1, away from White …
			CGFloat brightness = (arc4random() % 128 / 256.0) + 0.5; // 0.5 to 1, away from Black …

			UIColor *randomColor = [UIColor colorWithHue: hue saturation: saturation brightness: brightness alpha: alpha];

			return randomColor;
		}

	@end
