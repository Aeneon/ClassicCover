/*
	UIImage+Graphics.h
	ClassicCover

	Created by c0ldra1n on 10/26/17; Updated by MacThemes on 10/28/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import <math.h>
#import <stdint.h>

#import <Accelerate/Accelerate.h>
#import <UIKit/UIKit.h>

@interface UIImage(Graphics)

	- (UIColor *)averageColor;

	- (UIImage *)blurredImageWithRadius: (float)radius;

	- (UIImage *)blurredImageWithRadiusUsingVImage: (float)radius;

	- (UIImage *)colorizeWithColor: (UIColor *)color;

@end
