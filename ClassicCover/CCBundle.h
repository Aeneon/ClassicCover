/*
	CCBundle.h
	ClassicCover

	Created by MacThemes on 10/7/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CCBundle: NSObject

	// The ClassicCover Bundle, cached after the first Access …

	@property (class, nonatomic, readonly) NSBundle *bundle;

	// Get the localized String for the given Key …

	+ (NSString *)getLocalizedStringForKey: (NSString *)key;

	// Get the Control Image for the given Filename ( without it's Scale and Extension ) for Use as an Template …

	+ (UIImage *)getControlImageNamed: (NSString *)name;

	// Get the Image for the given Filename ( without it's Scale and Extension ) …

	+ (UIImage *)getImageNamed: (NSString *)name;

	// Get the Image for the given Filename ( without it's Scale and Extension ) for Use as an Template …

	+ (UIImage *)getImageTemplateNamed: (NSString *)name;
@end
