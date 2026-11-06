/*
	UIImage+Graphics.m
	ClassicCover

	Created by c0ldra1n on 10/26/17; Updated by MacThemes on 10/28/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import "UIImage+Graphics.h"

#pragma mark -
#pragma mark Private Methods

	UIColor * colorWithMinimumSaturation(UIColor *self, double saturation)
	{
		if(!self)
		{
			return nil;
		}

		CGFloat h, s, b, a;

		[self getHue: &h saturation: &s brightness: &b alpha: &a];

		if(s < saturation)
		{
			return [UIColor colorWithHue: h saturation: saturation brightness: b alpha: a];
		}

		return self;
	}

	UIColor * averageColor(UIImage *image, double alpha)
	{
		// Work within the RGB-Colorspace …

		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

		unsigned char rgba[4];

		CGContextRef context = CGBitmapContextCreate(rgba, 1.0, 1.0, 8.0, 4.0, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

		// Draw our Image down to 1x1 Pixels …

		CGContextDrawImage(context, CGRectMake(0.0, 0.0, 1.0, 1.0), image.CGImage);
		CGColorSpaceRelease(colorSpace);
		CGContextRelease(context);

		// Check if Image Alpha is 0 …

		if(rgba[3] == 0.0)
		{
			CGFloat imageAlpha = ((CGFloat)rgba[3]) / 255.0;
			CGFloat multiplier = imageAlpha / 255.0;

			UIColor *averageColor = [UIColor colorWithRed: ((CGFloat)rgba[0]) * multiplier green: ((CGFloat)rgba[1]) * multiplier blue: ((CGFloat)rgba[2]) * multiplier alpha: imageAlpha];

			// Improve Color …

			averageColor = colorWithMinimumSaturation(averageColor, 0.15);

			// Return Average Color …

			return averageColor;
		}
		else
		{
			// Get Average …

			UIColor *averageColor = [UIColor colorWithRed: ((CGFloat)rgba[0]) / 255.0 green: ((CGFloat)rgba[1]) / 255.0 blue: ((CGFloat)rgba[2]) / 255.0 alpha: alpha];

			// Improve Color …

			averageColor = colorWithMinimumSaturation(averageColor, 0.15);

			// Return Average Color …

			return averageColor;
		}
	}

	/*
		Creating a `CIContext` isn't cheap - it stands up a whole Rendering Pipeline ( Shader Compilation, Format Negotiation, etc. ), which is one-time Work, not per-Image Work. A single, shared, GPU-backed Context is created once and reused for the Lifetime of the Tweak; `CIContext` is documented as thread-safe, so this is also safe to call from a Background Queue …
	*/
	CIContext * sharedBlurContext(void)
	{
		static CIContext *context;
		static dispatch_once_t onceToken;

		dispatch_once(&onceToken, ^
		{
			context = [CIContext contextWithOptions: @{ kCIContextUseSoftwareRenderer: @(NO) }];
		});

		return context;
	}

	UIImage * blurImage(UIImage *sourceImage, float radius)
	{
		// Create our blurred Image …

		CIContext *context = sharedBlurContext();
		CIImage *inputImage = [CIImage imageWithCGImage: sourceImage.CGImage];

		// Remember the original Bounds, before we extend the Image …

		CGRect originalExtent = [inputImage extent];

		// Clamp to Extent: repeats the outermost Pixels infinitely in all Directions, so the Blur never samples transparent Pixels at the Edges …

		CIImage *clampedImage = [inputImage imageByClampingToExtent];

		// Setting up Gaussian Blur …

		CIFilter *filter = [CIFilter filterWithName: @"CIGaussianBlur"];

		[filter setValue: clampedImage forKey: kCIInputImageKey];
		[filter setValue: [NSNumber numberWithFloat: radius] forKey: @"inputRadius"];

		CIImage *result = [filter valueForKey: kCIOutputImageKey];

		// `CIGaussianBlur` has a Tendency to shrink the Image a little, this ensures it matches up exactly to the Bounds of our original Image …

		CGImageRef cgImage = [context createCGImage: result fromRect: originalExtent];

		if(!cgImage)
		{
			return nil;
		}

		UIImage *retVal = [UIImage imageWithCGImage: cgImage scale: sourceImage.scale orientation: sourceImage.imageOrientation];

		CGImageRelease(cgImage);

		return retVal;
	}

	/*
		Blur Reflections with Accelerate / vImage instead of Core Image. Three Box-Filter Passes approximate the original Gaussian blur, while each Call uses its own Pixel Buffers to avoid sharing Image Data between concurrent Reflection Requests …
	*/
	UIImage * blurImageWithVImage(UIImage *sourceImage, float radius)
	{
		CGImageRef sourceCGImage = sourceImage.CGImage;

		// Keep the original Image if there is nothing valid to Blur …

		if(!sourceCGImage || !isfinite(radius) || radius <= 0.0f)
		{
			return sourceImage;
		}

		size_t width = CGImageGetWidth(sourceCGImage);
		size_t height = CGImageGetHeight(sourceCGImage);

		// The Minimum Convolution Kernel is 3x3: Smaller Images are left untouched …

		if(width < 3 || height < 3)
		{
			return sourceImage;
		}

		// Prevent `size_t` Òverflow when calculating the 4-Byte-per-Pixel Buffer Size …

		if(width > SIZE_MAX / 4 || height > SIZE_MAX / (width * 4))
		{
			return nil;
		}

		size_t rowBytes = width * 4;
		size_t byteCount = rowBytes * height;

		// Per-call ownership is important: no shared Core Image state or pixel data.

		// Allocate a private Input Buffer …

		void *pixelsA = calloc(1, byteCount);

		// … and two alternating Output Buffers. Separate Allocations keep concurrent Renders from sharing Pixel Data …

		void *pixelsB = malloc(byteCount);
		void *pixelsC = malloc(byteCount);

		UIImage *blurredImage = nil;

		CGColorSpaceRef colorSpace = NULL;
		CGContextRef context = NULL;

		CGImageRef outputCGImage = NULL;

		if(!pixelsA || !pixelsB || !pixelsC)
		{
			goto cleanup;
		}

		// Decode the Source into a predictable 32-Bit premultiplied RGB-Bitmap …

		colorSpace = CGColorSpaceCreateDeviceRGB();

		if(!colorSpace)
		{
			goto cleanup;
		}

		// Four 8-Bit Channels: Little-Endian ARGB is stored in BGRA Byte Order. The Convolution applies the same Kernel to all four Channels …

		CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little;

		context = CGBitmapContextCreate(pixelsA, width, height, 8, rowBytes, colorSpace, bitmapInfo);

		if(!context)
		{
			goto cleanup;
		}

		// Copy the Source Pixels into Input Buffer before running the vImage-Filters …

		CGContextDrawImage(context, CGRectMake(0.0, 0.0, width, height), sourceCGImage);
		CGContextRelease(context);

		context = NULL;

		// Describe the existing Allocations to vImage without copying their Contents …

		vImage_Buffer bufferA = { pixelsA, height, width, rowBytes };
		vImage_Buffer bufferB = { pixelsB, height, width, rowBytes };
		vImage_Buffer bufferC = { pixelsC, height, width, rowBytes };

		// Map the requested Blur-Radius to an odd-sized Box Kernel ( at least 3x3 ). Limit it to the Image-Dimensions and three Passes give a Gaussian-like Blur, though the Result is not pixel-identical to `CIGaussianBlur` …

		double halfWidth = (sqrt(1.0 + 4.0 * (double)radius * (double)radius) - 1.0) / 2.0;
		double maxHalfWidth = (double)((MIN(width, height) - 1) / 2);

		uint32_t halfKernel = (uint32_t)MAX(1.0, MIN(round(halfWidth), maxHalfWidth));
		uint32_t kernel = halfKernel * 2 + 1;

		// Ping-Pong A -> B -> C -> B: The last Pass leaves its Result in Buffer B. Edge Extension repeats Border Pixels instead of sampling Transparent Ones …

		vImage_Error error = vImageBoxConvolve_ARGB8888(&bufferA, &bufferB, NULL, 0, 0, kernel, kernel, NULL, kvImageEdgeExtend);

		if(error == kvImageNoError)
		{
			error = vImageBoxConvolve_ARGB8888(&bufferB, &bufferC, NULL, 0, 0, kernel, kernel, NULL, kvImageEdgeExtend);
		}
		if(error == kvImageNoError)
		{
			error = vImageBoxConvolve_ARGB8888(&bufferC, &bufferB, NULL, 0, 0, kernel, kernel, NULL, kvImageEdgeExtend);
		}

		// Abort on any failed Pass rather than returning a partial Reflection …

		if(error != kvImageNoError)
		{
			goto cleanup;
		}

		// Snapshot the finished Buffer B as a `CGImage` before releasing its Storage. This also avoids carrying a deferred Core-Image-Render into `UIImage` …

		context = CGBitmapContextCreate(pixelsB, width, height, 8, rowBytes, colorSpace, bitmapInfo);

		if(!context)
		{
			goto cleanup;
		}

		outputCGImage = CGBitmapContextCreateImage(context);

		if(outputCGImage)
		{
			blurredImage = [UIImage imageWithCGImage: outputCGImage scale: sourceImage.scale orientation: sourceImage.imageOrientation];
		}

		// Release every Resource on both Success and Failure: The `CGImage` Snapshot remains valid even after the temporary Bitmap Buffers have been freed …

	cleanup:
		if(outputCGImage)
		{
			CGImageRelease(outputCGImage);
		}

		if(context)
		{
			CGContextRelease(context);
		}

		if(colorSpace)
		{
			CGColorSpaceRelease(colorSpace);
		}

		free(pixelsA);
		free(pixelsB);
		free(pixelsC);

		// Return our blurred Image …

		return blurredImage;
	}

#pragma mark -
#pragma mark UIImage (Graphics)

	@implementation UIImage(Graphics)

		- (UIColor *)averageColor
		{
			return averageColor(self, 1.0);
		}

		- (UIImage *)blurredImageWithRadius: (float)radius
		{
			return blurImage(self, radius);
		}

		- (UIImage *)blurredImageWithRadiusUsingVImage: (float)radius
		{
			return blurImageWithVImage(self, radius);
		}

		- (UIImage *)colorizeWithColor: (UIColor *)color
		{
			UIGraphicsBeginImageContext(self.size);

			CGContextRef context = UIGraphicsGetCurrentContext();
			CGRect area = CGRectMake(0.0, 0.0, self.size.width, self.size.height);

			CGContextScaleCTM(context, 1.0, -1.0);
			CGContextTranslateCTM(context, 0.0, -area.size.height);

			CGContextSaveGState(context);
			CGContextClipToMask(context, area, self.CGImage);

			[color set];

			CGContextFillRect(context, area);
			CGContextRestoreGState(context);
			CGContextSetBlendMode(context, kCGBlendModeMultiply);
			CGContextDrawImage(context, area, self.CGImage);

			UIImage *colorizedImage = UIGraphicsGetImageFromCurrentImageContext();

			UIGraphicsEndImageContext();

			return colorizedImage;
		}

	@end
