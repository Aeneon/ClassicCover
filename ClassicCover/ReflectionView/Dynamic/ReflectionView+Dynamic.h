/*
	ReflectionView.h | Version 1.3

	Created by Nick Lockwood on 7/19/2011
	Updated by MacThemes on 9/9/26.
	Copyright © 2011 Charcoal Design & © 2026 MacThemes

	Distributed under the permissive zlib license

	Get the latest Version from here: https://github.com/nicklockwood/ReflectionView

	This Software is provided 'as-is', without any Express or implied Warranty. In no Event will the Authors be held liable for any Damages arising from the Use of this Software.

	Permission is granted to anyone to use this Software for any Purpose, including Commercial Applications, and to alter it and redistribute it freely, Subject to the following Restrictions:

	1. The Origin of this Software must not be misrepresented; you must not claim that you wrote the Original Software. If you use this Software in a Product, an Acknowledgment in the Product Documentation would be appreciated but is not required.

	2. Altered Source Versions must be plainly marked as such, and must not be misrepresented as being the Original Software.

	3. This Notice may not be removed or altered from any Source Distribution.

	--------------
	Source Changes

	- Animatable Reflection Alpha
	- Changed Reflection Alpha from 0.5 to 0.42
	- Changed Reflection Gap from 4.0 to 0.0
	- Reflections are only generated, if necessary
	- Rewrote existing and added new Comments
	- Support for using pre-cached Images to improve Performance
*/

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@protocol ReflectionViewDelegate <NSObject>

	@required

	- (void)reflectionDidUpdate: (UIImage *_Nullable)image entityIdentifier: (uint64_t)entityPersistentID;

@end

@interface ReflectionView: UIView

	// Our Delegate …

	@property id<ReflectionViewDelegate> _Nonnull delegate;

	// Indicate, if we should use a `CAReplicatorLayer` or not …

	@property (nonatomic, assign) BOOL dynamic;

	// The current Media Item's Entity Identifier …

	@property (nonatomic, assign) uint64_t entityIdentifier;

	// The pre-cached Image …

	@property (nonatomic, copy) UIImage* _Nullable image;

	// Reflection Properties for Alpha, Gap and Scale …

	@property (nonatomic, assign) CGFloat reflectionAlpha;
	@property (nonatomic, assign) CGFloat reflectionGap;
	@property (nonatomic, assign) CGFloat reflectionScale;

	// Gates the "generate a fresh Reflection by rendering my own Layer" Path in `- (void)update`. Defaults to `NO`. `layoutSubviews` can fire for many Reasons completely independent of whether the real Content to reflect has been painted yet - rendering before that happens captures blank / stale Content. Set this to `YES` only once the Artwork this Reflection is based on has actually been applied.

	@property (nonatomic, assign) BOOL readyToRender;

	// We want to animate the Reflection Alpha …

	- (void)setReflectionAlphaAnimated: (CGFloat)alpha duration: (NSTimeInterval)duration;

	// The Update-Method …

	- (void)update;

@end

#pragma GCC diagnostic pop
