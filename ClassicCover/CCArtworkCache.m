/*
	CCArtworkCache.m
	ClassicCover

	Created by MacThemes with Claude.AI on 11/3/26.
	Copyright © 2026 MacThemes. All rights reserved.

	Fast 3-Tier Cache for Album Artwork: Memory ( NSCache ) -> Disk -> MPMediaItemArtwork-Generation …
*/

#import "CCArtworkCache.h"

#import "../MTCoreLogic.h"

@interface CCArtworkCache()

	@property (strong, nonatomic) NSCache<NSString *, UIImage *> *memoryCache;
	@property (strong, nonatomic) dispatch_queue_t diskQueue;

	@property (assign, nonatomic) CGFloat imageScale;

@end

@implementation CCArtworkCache

	+ (instancetype)sharedCache
	{
		static CCArtworkCache *instance;
		static dispatch_once_t onceToken;

		dispatch_once(&onceToken, ^
		{
			instance = [[CCArtworkCache alloc] init];
		});

		return instance;
	}

	#pragma mark -
	#pragma mark Lifecycle

		- (instancetype)init
		{
			self = [super init];

			if(self)
			{
				self.memoryCache = [[NSCache alloc] init];
				self.memoryCache.name = @"com.macthemes.classiccover.memory.cache";

				// Cost is tracked in Bytes ( roughly Width * Height * 4 for a decoded Bitmap). ~64 MB of decoded Artwork before Eviction kicks in - tune to Taste …

				self.memoryCache.totalCostLimit = 64 * 1024 * 1024;

				self.imageScale = [UIScreen mainScreen].scale;

				self.diskQueue = dispatch_queue_create("com.macthemes.classiccover.disk.cache", DISPATCH_QUEUE_CONCURRENT);

				[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(clearMemoryCache) name: UIApplicationDidReceiveMemoryWarningNotification object: nil];
			}

			return self;
		}

		- (void)dealloc
		{
			[[NSNotificationCenter defaultCenter] removeObserver: self];
		}

	#pragma mark -
	#pragma mark Memory Management

		- (void)clearMemoryCache
		{
			[self.memoryCache removeAllObjects];
		}

	#pragma mark -
	#pragma mark Private Methods

		/*
			Redraws the Image into a fresh Bitmap Context, forcing PNG / JPEG Decode to happen NOW ( whatever Thread calls this ) instead of lazily on first Draw ( which would otherwise happen on the Main Rhread the moment UIKit renders it ) …

			- Uses `UIGraphicsBeginImageContextWithOptions` available and thread-safe since iOS 4.0.
		*/
		- (UIImage *)predecodedImage: (UIImage *)image withAlpha: (BOOL)withAlpha
		{
			return [self predecodedImage: image withSize: CGSizeMake(0.0, 0.0) withAlpha: withAlpha];
		}

		- (UIImage *)predecodedImage: (UIImage *)image withSize: (CGSize)imageSize withAlpha: (BOOL)withAlpha
		{
			if(!image)
			{
				return nil;
			}

			CGSize size = ((imageSize.width > 0.0) && (imageSize.height > 0.0)) ? imageSize : image.size;

			if(size.width <= 0.0 || size.height <= 0.0)
			{
				return image;
			}
			// Cached Images don't have an "@2x" or "@3x" Filename. Their Point-Size is restored on Read. Preserve the Input Scale when Decoding, so never multiply its Pixels again …

			CGFloat scale = (imageSize.width > 0.0 && imageSize.height > 0.0) ? self.imageScale : image.scale;

			// `opaque` is the inverse of `withAlpha`, since no Alpha Channel is needed for Album Covers, but we need them for Reflections; Skipping the Channel saves Memory + Blending Cost …

			UIGraphicsBeginImageContextWithOptions(size, !withAlpha, scale);

			[image drawInRect: CGRectMake(0.0, 0.0, size.width, size.height)];

			UIImage *decoded = UIGraphicsGetImageFromCurrentImageContext();

			UIGraphicsEndImageContext();

			return decoded ?: image;
		}

		- (NSUInteger)costForImage: (UIImage *)image
		{
			CGImageRef cgImage = image.CGImage;

			if(!cgImage)
			{
				return 0;
			}

			return CGImageGetBytesPerRow(cgImage) * CGImageGetHeight(cgImage);
		}

		- (BOOL)ensureCacheDirectoryExists
		{
			NSFileManager *fileManager = [NSFileManager defaultManager];

			BOOL isDirectory = NO;

			if([fileManager fileExistsAtPath: CCFileManagerCacheArtwork isDirectory: &isDirectory] && isDirectory)
			{
				return YES;
			}

			NSError *dirError = nil;

			if([fileManager createDirectoryAtPath: CCFileManagerCacheArtwork withIntermediateDirectories: YES attributes: nil error: &dirError])
			{
				MTLog(@"Creation of Artwork-Cache at „%@“ was successful.", CCFileManagerCacheArtwork);

				return YES;
			}

			MTLog(@"Creation of Artwork-Cache at „%@“ failed with Error: %@", CCFileManagerCacheArtwork, dirError);

			return NO;
		}

		// Writes a PNG to Disk. Runs on whatever Thread it's called from - Callers are responsible for dispatching to `self.diskQueue` first …

		- (void)writeImageToDisk: (UIImage *)image path: (NSString *)path
		{
			if(![self ensureCacheDirectoryExists])
			{
				return; // Skipping Disk-Cache …
			}

			NSData *pngData = UIImagePNGRepresentation(image);

			NSError *writeError = nil;

			if([pngData writeToFile: path options: NSDataWritingAtomic error: &writeError])
			{
				MTLog(@"Creation of Cache-Entry „%@“ was successful.", path);
			}
			else
			{
				MTLog(@"Creation of Cache-Entry „%@“ failed with Error: %@", path, writeError);
			}
		}

	#pragma mark -
	#pragma mark Public Methods

		- (void)artworkForEntityIdentifier: (uint64_t)entityIdentifier mediaItem: (MPMediaItem *)representativeItem size: (CGSize)size withAlpha: (BOOL)withAlpha token: (id)token completion: (void (^)(UIImage *image, id token))completion
		{
			if(completion)
			{
				NSString *cacheKey = [@"art_" stringByAppendingString: [@(entityIdentifier) stringValue]];
				NSString *path = [self diskPathForEntityIdentifier: entityIdentifier];

				[self cachedImageForKey: cacheKey diskPath: path withAlpha: withAlpha token: token completion: ^(UIImage *image, id resolvedToken)
				{
					if(image || !representativeItem)
					{
						completion(image, resolvedToken);

						return;
					}

					// Tier 3: Nothing cached anywhere - generate from `MPMediaItemArtwork`. Still off the Main Thread; `imageWithSize:` does it's own CoreGraphics Work …

					dispatch_async(self.diskQueue, ^
					{
						// Log the Entity Identifier with dedicated Informations, such as Title, Artist and Album Title …

						MTLog(@"Creating Cache-Entry for „%@ – %@“ in Album „%@“ with ID: %llu.", representativeItem.title, representativeItem.artist, representativeItem.albumTitle, representativeItem.albumPersistentID);

						@autoreleasepool
						{
							// Create the Artwork and write to Disk …

							UIImage *generated = [[representativeItem artwork] imageWithSize: size];
							UIImage *decoded = [self predecodedImage: generated withSize: size withAlpha: withAlpha];

							if(decoded)
							{
								[self.memoryCache setObject: decoded forKey: cacheKey cost: [self costForImage: decoded]];

								[self writeImageToDisk: decoded path: path];
							}

							// Let's get back to the Main Thread …

							dispatch_async(dispatch_get_main_queue(), ^
							{
								completion(decoded, resolvedToken);
							});
						}
					});
				}];
			}
		}

		- (void)cachedImageForKey: (NSString *)cacheKey diskPath: (NSString *)diskPath withAlpha: (BOOL)withAlpha token: (id)token completion: (void (^)(UIImage *image, id token))completion
		{
			if(completion)
			{
				@autoreleasepool
				{
					// Tier 1: Memory - Synchronous, no Thread hop, no Flicker …

					UIImage *cached = [self.memoryCache objectForKey: cacheKey];

					if(cached)
					{
						MTLog(@"Using Cache-Entry with Key „%@“ from Memory Cache.", cacheKey);

						completion(cached, token);

						return;
					}

					// Tier 2: Disk - Always off the Main Thread ( I/O + Decode ) …

					dispatch_async(self.diskQueue, ^
					{
						NSFileManager *fileManager = [NSFileManager defaultManager];

						UIImage *image;

						if([fileManager fileExistsAtPath: diskPath])
						{
							UIImage *diskImage = [UIImage imageWithContentsOfFile: diskPath];

							image = [self predecodedImage: diskImage withAlpha: withAlpha];

							if(image)
							{
								MTLog(@"Adding Cache-Entry with Key „%@“ to Memory Cache from File „%@“.", cacheKey, diskPath);

								[self.memoryCache setObject: image forKey: cacheKey cost: [self costForImage: image]];
							}
						}

						// Let's get back to the Main Thread …

						dispatch_async(dispatch_get_main_queue(), ^
						{
							completion(image, token);
						});
					});
				}
			}
		}

		- (void)reflectionForEntityIdentifier: (uint64_t)entityIdentifier token: (id)token completion: (void (^)(UIImage *image, id token))completion
		{
			NSString *cacheKey = [self reflectionCacheKeyForEntityIdentifier: entityIdentifier];
			NSString *path = [self diskPathForEntityIdentifier: entityIdentifier suffix: @"_r"];

			/*
				Deliberately no Tier-3 Generation here: Reflections are produced by rendering a CALayer, which must happen on the Main Thread inside `ReflectionView` / `CCViewController` …

				- This just gives that Path the same fast memory-hit + async-disk-hit Behavior as Artwork; on a full Miss the Caller generates and calls `- (void)storeImage: forKey: diskPath:` itself.
			*/
			[self cachedImageForKey: cacheKey diskPath: path withAlpha: YES token: token completion: completion];
		}

		- (NSString *)reflectionCacheKeyForEntityIdentifier: (uint64_t)entityIdentifier
		{
			return [@"ref_" stringByAppendingString: [@(entityIdentifier) stringValue]];
		}

		- (NSString *)diskPathForEntityIdentifier: (uint64_t)entityIdentifier
		{
			return [self diskPathForEntityIdentifier: entityIdentifier suffix: nil];
		}

		- (NSString *)diskPathForEntityIdentifier: (uint64_t)entityIdentifier suffix: (NSString *)suffix
		{
			NSString *fileName = [[@(entityIdentifier) stringValue] stringByAppendingString: (suffix ?: @"")];

			return [CCFileManagerCacheArtwork stringByAppendingPathComponent: [fileName stringByAppendingPathExtension: @"png"]];
		}

		- (void)storeImage: (UIImage *)image forKey: (NSString *)cacheKey diskPath: (NSString *)diskPath withAlpha: (BOOL)withAlpha
		{
			if(image && cacheKey)
			{
				// Memory Tier: Cheap, do it immediately on the Caller's Thread so a lookup that follows right after ( e.g. next Carousel Item reusing the same Album ) hits warm …

				[self.memoryCache setObject: image forKey: cacheKey cost: [self costForImage: image]];

				if(diskPath)
				{
					dispatch_async(self.diskQueue, ^
					{
						UIImage *decoded = [self predecodedImage: image withAlpha: withAlpha];

						[self writeImageToDisk: (decoded ?: image) path: diskPath];
					});
				}
			}
		}

@end
