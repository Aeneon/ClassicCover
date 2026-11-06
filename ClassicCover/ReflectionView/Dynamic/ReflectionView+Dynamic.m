/*
	ReflectionView.m | Version 1.3

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

#import <Availability.h>
#import "ReflectionView+Dynamic.h"

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

	@property (strong, nonatomic) CAGradientLayer *gradientLayer;
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

			self.reflectionGap = 0.0; // Default: 4.0
			self.reflectionScale = 0.5;
			self.reflectionAlpha = 0.42; // Default: 0.5

			// Update the Reflection …

			[self setNeedsLayout];
		}

	#pragma mark -
	#pragma mark Custom Accessors

		- (void)setDynamic: (BOOL)dynamic
		{
			if(_dynamic != dynamic)
			{
				_dynamic = dynamic;

				[self setNeedsLayout];
			}
		}

		- (void)setEntityIdentifier: (uint64_t)entityIdentifier
		{
			if(_entityIdentifier != entityIdentifier)
			{
				_entityIdentifier = entityIdentifier;
			}
		}

		- (void)setImage: (UIImage *)image
		{
			if(_image != image)
			{
				_image = image;

				[self setNeedsLayout];
			}
		}

		- (void)setReadyToRender: (BOOL)readyToRender
		{
			if(_readyToRender != readyToRender)
			{
				_readyToRender = readyToRender;
			}
		}

		- (void)setReflectionAlpha: (CGFloat)reflectionAlpha
		{
			if(_reflectionAlpha != reflectionAlpha)
			{
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

		- (void)setReflectionGap: (CGFloat)reflectionGap
		{
			if(_reflectionGap != reflectionGap)
			{
				_reflectionGap = reflectionGap;

				[self setNeedsLayout];
			}
		}

		- (void)setReflectionScale: (CGFloat)reflectionScale
		{
			if(_reflectionScale != reflectionScale)
			{
				_reflectionScale = reflectionScale;

				[self setNeedsLayout];
			}
		}

	#pragma mark -
	#pragma mark Public Methods

		- (void)layoutSubviews
		{
			[self update];

			[super layoutSubviews];
		}

		- (void)update
		{
			if(self.dynamic)
			{
				// Remove the Gradient View …

				[self.reflectionView removeFromSuperview];

				self.reflectionView = nil;

				// Update the Instances …

				CAReplicatorLayer *layer = (CAReplicatorLayer *)self.layer;

				layer.shouldRasterize = YES;
				layer.rasterizationScale = [UIScreen mainScreen].scale;
				layer.instanceCount = 2;

				CATransform3D transform = CATransform3DIdentity;

				transform = CATransform3DTranslate(transform, 0.0, layer.bounds.size.height + self.reflectionGap, 0.0);
				transform = CATransform3DScale(transform, 1.0, -1.0, 0.0);

				layer.instanceTransform = transform;
				layer.instanceAlphaOffset = self.reflectionAlpha - 1.0;

				// Create a ( new ) Gradient Layer …

				if(! self.gradientLayer)
				{
					self.gradientLayer = [[CAGradientLayer alloc] init];

					self.layer.mask = self.gradientLayer;

					self.gradientLayer.colors = @[(__bridge id)[UIColor blackColor].CGColor, (__bridge id)[UIColor blackColor].CGColor, (__bridge id)[UIColor clearColor].CGColor];
				}

				// Update Mask …

				[CATransaction begin];
				[CATransaction setDisableActions: YES]; // Don't animate …

				CGFloat total = layer.bounds.size.height * 2.0 + self.reflectionGap;
				CGFloat halfWay = (layer.bounds.size.height + self.reflectionGap) / total - 0.01;

				self.gradientLayer.frame = CGRectMake(0, 0, self.bounds.size.width, total);
				self.gradientLayer.locations = @[@0.0, @(halfWay), @(halfWay + (1.0 - halfWay) * self.reflectionScale)];

				[CATransaction commit];
			}
			else
			{
				// Remove the Gradient Layer …

				self.layer.mask = nil;
				self.gradientLayer = nil;

				// Create a ( new ) Reflection View …

				if(! self.reflectionView)
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
					// If there's already a pre-cached Image available …

					if(self.image)
					{
						// … use it.

						self.reflectionView.image = self.image;
					}
					else
					{
						// … otherwise, if we're ready to render a new Reflection …

						if(self.readyToRender)
						{
							// … update the Instances.

							CAReplicatorLayer *layer = (CAReplicatorLayer *)self.layer;

							layer.shouldRasterize = NO;
							layer.instanceCount = 1;

							// Create the Gradient Mask …

							UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);

							CGContextRef gradientContext = UIGraphicsGetCurrentContext();

							CGFloat colors[] = {1.0, 1.0, 0.0, 1.0};

							CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
							CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);

							CGPoint gradientStartPoint = CGPointMake(0.0, 0.0);
							CGPoint gradientEndPoint = CGPointMake(0.0, size.height);

							CGContextDrawLinearGradient(gradientContext, gradient, gradientStartPoint, gradientEndPoint, kCGGradientDrawsAfterEndLocation);

							CGImageRef gradientMask = CGBitmapContextCreateImage(gradientContext);

							CGGradientRelease(gradient);
							CGColorSpaceRelease(colorSpace);

							UIGraphicsEndImageContext();

							// Create a Drawing Context …

							UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

							CGContextRef context = UIGraphicsGetCurrentContext();
							CGContextScaleCTM(context, 1.0, -1.0);
							CGContextTranslateCTM(context, 0.0, -self.bounds.size.height);

							// Clip to the Gradient …

							CGContextClipToMask(context, CGRectMake(0.0, self.bounds.size.height - size.height, size.width, size.height), gradientMask);
							CGImageRelease(gradientMask);

							// Draw the reflected Layer Content …

							[self.layer renderInContext: context];

							// Capture the resultant Image …

							UIImage *result = UIGraphicsGetImageFromCurrentImageContext();

							self.reflectionView.image = result;

							UIGraphicsEndImageContext();

							// … and notify our Delegate.

							if(self.delegate)
							{
								[self.delegate reflectionDidUpdate: result entityIdentifier: self.entityIdentifier];
							}
						}
					}
				}

				// Update the Reflection …

				self.reflectionView.alpha = self.reflectionAlpha;
				self.reflectionView.frame = CGRectMake(0, self.bounds.size.height + self.reflectionGap, size.width, size.height);
			}
		}

@end
