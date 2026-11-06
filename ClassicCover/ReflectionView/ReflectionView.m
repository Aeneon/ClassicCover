/*
	ReflectionView.m | Version 1.3.1

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

#import <Availability.h>
#import "ReflectionView.h"

#import "../UIImage+Graphics.h"

#import "../../MTCoreLogic.h"

#if !__has_feature(objc_arc)
	#error This class requires automatic reference counting
#endif

// #pragma clang diagnostic ignored "-Wreceiver-is-weak"
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma clang diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
#pragma clang diagnostic ignored "-Wunused-macros"
#pragma clang diagnostic ignored "-Wconversion"
#pragma clang diagnostic ignored "-Wformat-nonliteral"
#pragma clang diagnostic ignored "-Wgnu"

@interface ReflectionView()
{
	// Bumped every Time the current Content is invalidated …

	NSUInteger _renderGeneration;
}

	@property (strong, nonatomic) UIImageView *reflectionView;

@end

@implementation ReflectionView

	#pragma mark -
	#pragma mark Layer Class

		+ (Class)layerClass
		{
			return [CAReplicatorLayer class];
		}

	#pragma mark -
	#pragma mark Lifecycle

		- (id)initWithCoder: (NSCoder *)aDecoder
		{
			if((self = [super initWithCoder: aDecoder]))
			{
				[self setUp];
			}

			return self;
		}

		- (id)initWithFrame: (CGRect)frame
		{
			if((self = [super initWithFrame: frame]))
			{
				[self setUp];
			}

			return self;
		}

		- (void)setUp
		{
			// Set ( new ) Default Properties …

			self.reflectionAlpha = CCReflectionViewAlpha; // Default: 0.5
			self.reflectionBlur = 0.0; // Default: 0.0
			self.reflectionGap = 0.0; // Default: 4.0
			self.reflectionScale = 0.5;

			// Update the Reflection …

			[self setNeedsLayout];
		}

	#pragma mark -
	#pragma mark Custom Accessors

		- (void)setEntityIdentifier: (uint64_t)entityIdentifier
		{
			if(_entityIdentifier != entityIdentifier)
			{
				_entityIdentifier = entityIdentifier;

				// A different Album: anything still in flight is stale …

				self -> _renderGeneration++;
			}
		}

		- (void)setImage: (UIImage *)image
		{
			if(_image != image)
			{
				// Invalidate any in-flight Render and push the Change to the visible Reflection Image View right now, synchronously - not deferred to the next `layoutSubviews` Pass …

				self -> _renderGeneration++;

				[self showReflection: image];

				[self setNeedsLayout];
			}
		}

		- (void)setReflectionAlpha: (CGFloat)reflectionAlpha
		{
			if(_reflectionAlpha != reflectionAlpha)
			{
				// The Alpha is applied to the Image View and never baked into the Image, so the Reflection Image stays valid …

				_reflectionAlpha = reflectionAlpha;

				[self setNeedsLayout];
			}
		}

		- (void)setReflectionAlphaAnimated: (CGFloat)alpha duration: (NSTimeInterval)duration
		{
			self.reflectionAlpha = alpha;

			[UIView animateWithDuration: duration delay: 0.0 options: UIViewAnimationOptionCurveEaseOut animations: ^
			{
				self.reflectionView.alpha = alpha;
			} completion: nil];
		}

		- (void)setReflectionBlur: (CGFloat)reflectionBlur
		{
			if(_reflectionBlur != reflectionBlur)
			{
				_reflectionBlur = reflectionBlur;

				// Anything in flight was rendered with the old Value, so drop it. A new Reflection has to be requested via `- (void)renderReflectionFromArtwork: entityIdentifier:` …

				self -> _renderGeneration++;
			}
		}

		- (void)setReflectionGap: (CGFloat)reflectionGap
		{
			if(_reflectionGap != reflectionGap)
			{
				// The Gap is only a Matter of Layout …

				_reflectionGap = reflectionGap;

				[self setNeedsLayout];
			}
		}

		- (void)setReflectionScale: (CGFloat)reflectionScale
		{
			if(_reflectionScale != reflectionScale)
			{
				_reflectionScale = reflectionScale;

				// Same as for the Blur: Anything in flight was rendered with the old Value …

				self -> _renderGeneration++;

				[self setNeedsLayout];
			}
		}

	#pragma mark -
	#pragma mark Private Methods

		// Sets the Image, which is shown by the Reflection Image View, without touching the Render Generation …

		- (void)showReflection: (UIImage *)image
		{
			_image = image;

			self.reflectionView.image = image;
		}

		// Cache an immutable Gradient-Mask for each Reflection-Size. The Mask doesn't depend on Artwork, so reusing it avoids an extra Bitmap-Draw per Album …

		- (CGImageRef)gradientMaskForSize: (CGSize)size
		{
			static NSCache<NSString *, UIImage *> *maskCache;
			static dispatch_once_t onceToken;

			dispatch_once(&onceToken, ^
			{
				maskCache = [NSCache new];
				maskCache.totalCostLimit = 4 * 1024 * 1024;
			});

			NSString *key = NSStringFromCGSize(size);

			@synchronized(maskCache)
			{
				UIImage *cached = [maskCache objectForKey: key];

				if(cached.CGImage)
				{
					return CGImageRetain(cached.CGImage);
				}

				// Create the Gradient Mask …

				UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);

				CGContextRef gradientContext = UIGraphicsGetCurrentContext();

				CGFloat colors[] = {1.0, 1.0, 0.0, 1.0};

				CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
				CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);

				CGPoint gradientStartPoint = CGPointMake(0.0, 0.0);
				CGPoint gradientEndPoint = CGPointMake(0.0, size.height);

				CGContextDrawLinearGradient(gradientContext, gradient, gradientStartPoint, gradientEndPoint, kCGGradientDrawsAfterEndLocation);

				CGGradientRelease(gradient);

				CGImageRef gradientMask = CGBitmapContextCreateImage(gradientContext);

				CGColorSpaceRelease(colorSpace);

				UIGraphicsEndImageContext();

				if(gradientMask)
				{
					[maskCache setObject: [UIImage imageWithCGImage: gradientMask] forKey: key cost: CGImageGetBytesPerRow(gradientMask) * CGImageGetHeight(gradientMask)];
				}

				return gradientMask; // Retained. The Caller must `CGImageRelease` it …
			}
		}

		/*
			Renders the Reflection of an Artwork directly from the Artwork's `UIImage` - never from whatever the Layer Tree happens to show at that Moment …

			- Only plain Core Graphics, so it's safe to call on any Thread ( `UIGraphicsBeginImageContextWithOptions` is thread-safe since iOS 4.0 ).
			- `viewSize` is the Size of the ( sharp ) Artwork View, `size` the Size of the Reflection ( `viewSize.height * reflectionScale` ).
			- The Artwork View uses `UIViewContentModeScaleAspectFill`, so we draw the Artwork the same Way.
		*/
		- (UIImage *)reflectionFromArtwork: (UIImage *)artwork viewSize: (CGSize)viewSize size: (CGSize)size
		{
			if(!artwork || artwork.size.width <= 0.0 || artwork.size.height <= 0.0 || size.width <= 0.0 || size.height <= 0.0)
			{
				return nil;
			}

			// Create the Gradient Mask …

			CGImageRef gradientMask = [self gradientMaskForSize: size];

			// Create a Drawing Context and flip it vertically, so we draw the mirrored Artwork …

			UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

			CGContextRef context = UIGraphicsGetCurrentContext();

			if(!context)
			{
				UIGraphicsEndImageContext();

				CGImageRelease(gradientMask);

				return nil;
			}

			CGContextScaleCTM(context, 1.0, -1.0);
			CGContextTranslateCTM(context, 0.0, -viewSize.height);

			// Clip to the Gradient …

			CGContextClipToMask(context, CGRectMake(0.0, viewSize.height - size.height, size.width, size.height), gradientMask);
			CGImageRelease(gradientMask);

			// Calculate the Rect for an Aspect-Fill Drawing …

			CGFloat factor = MAX(viewSize.width / artwork.size.width, viewSize.height / artwork.size.height);
			CGSize drawSize = CGSizeMake(artwork.size.width * factor, artwork.size.height * factor);
			CGRect drawRect = CGRectMake((viewSize.width - drawSize.width) / 2.0, (viewSize.height - drawSize.height) / 2.0, drawSize.width, drawSize.height);

			// … and draw the Artwork ( cropped to the View's Bounds, just like `clipsToBounds` on the Artwork View ) …

			CGContextClipToRect(context, CGRectMake(0.0, 0.0, viewSize.width, viewSize.height));

			[artwork drawInRect: drawRect];

			// Capture the resultant Image …

			UIImage *result = UIGraphicsGetImageFromCurrentImageContext();

			// … and remove the current bitmap-based Graphics Context.

			UIGraphicsEndImageContext();

			return result;
		}

	#pragma mark -
	#pragma mark Public Methods

		- (void)layoutSubviews
		{
			[self update];

			[super layoutSubviews];
		}

		- (void)reset
		{
			// Everything in flight is stale from now on, and the Reflection of the previous Album has to disappear synchronously, or the new Album's sharp Cover ( which UIImageView paints immediately ) briefly sits above the old Album's Reflection …

			self -> _renderGeneration++;
			self -> _entityIdentifier = 0;

			[self showReflection: nil];
		}

		- (void)renderReflectionFromArtwork: (UIImage *)artwork entityIdentifier: (uint64_t)entityIdentifier
		{
			// Everything we need is captured right now, on the Main Thread, as one Unit: The Artwork and the Entity Identifier it belongs to. Nothing in the Background depends on View or Layer State anymore, so there's no Way, that a Reflection ends up with a different Album's Artwork …

			self -> _entityIdentifier = entityIdentifier;

			// This Render Attempt's own Token, so anything started before is stale from now on …

			NSUInteger generation = ++(self -> _renderGeneration);

			CGSize viewSize = self.bounds.size;
			CGSize size = CGSizeMake(viewSize.width, viewSize.height * self.reflectionScale);

			CGFloat radius = self.reflectionBlur;

			if(!artwork || size.width <= 0.0 || size.height <= 0.0)
			{
				return;
			}

			__weak ReflectionView *weakSelf = self;

			/*
				The Core-Image-Pipeline has a Bug on iOS 9, which causes wrong Blurs for some Covers.

				Getting this Bug fixed wasn't possible without ChatGPT Plus with GPT-6 and a High Thinking Effort during the whole Process - 7 Hours.
				13 Test-Builds until we got final One - the 13th. 97 Minutes of Thinking Time for only 15 Messages, which is an Average of 6 Minutes and 28 Seconds per Message ( Hi: 12m 23s, Lo: 2m 29s ).
			*/
			BOOL blurWithVImage = ([[[UIDevice currentDevice] systemVersion] integerValue] == 9);

			// Drawing ( and Blurring ) is the slow Part and plain Core Graphics, so hop to a Background Queue, so it never blocks Scrolling …

			dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^
			{
				UIImage *reflection = [self reflectionFromArtwork: artwork viewSize: viewSize size: size];

				// Blur the Image with the given Radius …

				if(reflection && radius > 0.0)
				{
					// If we're running iOS 9, we use VImage instead of Core Image …

					if(blurWithVImage)
					{
						reflection = [reflection blurredImageWithRadiusUsingVImage: radius];
					}
					else
					{
						reflection = [reflection blurredImageWithRadius: radius];
					}
				}

				// Never touch the View in the Background ( not even to read it ), so it can't be released on a wrong Thread - get back to the Main Thread first …

				dispatch_async(dispatch_get_main_queue(), ^
				{
					ReflectionView *strongSelf = weakSelf;

					// If this View has since been re-used for a different Album ( or a newer Render was started ), this Result is stale - drop it silently instead of showing or caching the wrong Cover's Reflection …

					if(!reflection || !strongSelf || strongSelf -> _renderGeneration != generation || strongSelf -> _entityIdentifier != entityIdentifier)
					{
						return;
					}

					[strongSelf showReflection: reflection];

					// … notify our Delegate.

					if(strongSelf.delegate)
					{
						[strongSelf.delegate reflectionDidUpdate: reflection entityIdentifier: entityIdentifier];
					}
				});
			});
		}

		- (void)update
		{
			// Remove the Layer Mask …

			self.layer.mask = nil;

			// Create a ( new ) Reflection View …

			if(!self.reflectionView)
			{
				self.reflectionView = [[UIImageView alloc] initWithFrame: self.bounds];

				self.reflectionView.contentMode = UIViewContentModeScaleToFill;
				self.reflectionView.userInteractionEnabled = NO;

				[self addSubview: self.reflectionView];
			}

			// Get Reflection Bounds …

			CGSize size = CGSizeMake(self.bounds.size.width, self.bounds.size.height * self.reflectionScale);

			if(size.height > 0.0 && size.width > 0.0)
			{
				// If there's an Image ( e.g. set before the first Layout Pass ) …

				if(self.image && self.reflectionView.image != self.image)
				{
					// … show it. We never generate a Reflection here anymore.

					self.reflectionView.image = self.image;
				}
			}

			// Update the Reflection …

			self.reflectionView.alpha = self.reflectionAlpha;
			self.reflectionView.frame = CGRectMake(0.0, self.bounds.size.height + self.reflectionGap, size.width, size.height);
		}

@end
