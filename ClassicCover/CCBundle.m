/*
	CCBundle.m
	ClassicCover

	Created by MacThemes on 10/7/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import "CCBundle.h"

@implementation CCBundle

	#pragma mark -
	#pragma mark Class Properties

		+ (NSBundle *)bundle
		{
			static NSBundle *bundle = nil;
			static dispatch_once_t onceToken;

			// Set the ClassicCover Bundle, once, no matter who asks first …

			dispatch_once(&onceToken, ^
			{
				bundle = [NSBundle bundleForClass: self.class];
			});

			return bundle;
		}

	#pragma mark -
	#pragma mark Public Methods

		// Get the localized String for the given Key …

		+ (NSString *)getLocalizedStringForKey: (NSString *)key
		{
			return [self.bundle localizedStringForKey: key value: @"" table: nil];
		}

		// Get the Image for the given Filename ( without it's Scale and Extension ) for Use in a Media-Control-Button …

		+ (UIImage *)getControlImageNamed: (NSString *)name
		{
			NSString *controlName = [NSString stringWithFormat: @"SystemMediaControl-%@", name];

			return [[UIImage imageNamed: controlName inBundle: self.bundle compatibleWithTraitCollection: nil] imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
		}

		// Get the Image for the given Filename ( without it's Scale and Extension ) …

		+ (UIImage *)getImageNamed: (NSString *)name
		{
			return [UIImage imageNamed: name inBundle: self.bundle compatibleWithTraitCollection: nil];
		}

		// Get the Image for the given Filename ( without it's Scale and Extension ) for Use as an Template …

		+ (UIImage *)getImageTemplateNamed: (NSString *)name
		{
			return [[UIImage imageNamed: name inBundle: self.bundle compatibleWithTraitCollection: nil] imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
		}

@end
