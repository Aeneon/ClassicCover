/*
	ReflectionView.h | Version 1.3.1

	Created by Nick Lockwood on 7/19/2011; Updated by MacThemes on 11/3/26.
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
	- Removed dynamic Part, as it's not necessary
	- Rendered directly from the given Image
	- Rewrote existing and added new Comments
	- Support for blurring Reflections ( with VImage )
	- Support for using pre-cached Images
*/

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-property-synthesis"

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@protocol ReflectionViewDelegate <NSObject>

	@required

	- (void)reflectionDidUpdate: (UIImage *_Nullable)image entityIdentifier: (uint64_t)entityPersistentID;

@end

@interface ReflectionView: UIView

	// Our Delegate …

	@property id<ReflectionViewDelegate> _Nonnull delegate;

	// The current Media Item's Entity Identifier …

	@property (nonatomic, assign) uint64_t entityIdentifier;

	// The pre-cached Image …

	@property (nonatomic, copy) UIImage* _Nullable image;

	// Reflection Properties for Alpha, Blur, Gap and Scale …

	@property (nonatomic, assign) CGFloat reflectionAlpha;
	@property (nonatomic, assign) CGFloat reflectionBlur;
	@property (nonatomic, assign) CGFloat reflectionGap;
	@property (nonatomic, assign) CGFloat reflectionScale;

	// Cache an immutable Gradient-Mask for each Reflection-Size. The Mask doesn't depend on Artwork, so reusing it avoids an extra Bitmap-Draw per Album …

	- (CGImageRef _Nullable)gradientMaskForSize: (CGSize)size;

	// Renders the Reflection of an Artwork directly from the Artwork's `UIImage` - never from whatever the Layer Tree happens to show at that Moment …

	- (UIImage *_Nullable)reflectionFromArtwork: (UIImage *_Nullable)artwork viewSize: (CGSize)viewSize size: (CGSize)size;

	// Renders the Reflection directly from the given Artwork ( not from the Layer Content ), on a Background Queue. The Artwork and the Entity Identifier travel together, so a Reflection can never be based on a different Album's Artwork. The Delegate is informed on the Main Thread, if the Result is still current …

	- (void)renderReflectionFromArtwork: (UIImage *_Nullable)artwork entityIdentifier: (uint64_t)entityPersistentID;

	// We want to animate the Reflection Alpha …

	- (void)setReflectionAlphaAnimated: (CGFloat)alpha duration: (NSTimeInterval)duration;

	// Invalidates everything in flight and removes the shown Reflection synchronously. Call this when the View is prepared for Re-Use …

	- (void)reset;

	// The Update-Method ( Layout only ) …

	- (void)update;

@end

#pragma GCC diagnostic pop
