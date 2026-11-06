/*
	CCArtworkCache.h
	ClassicCover

	Created by MacThemes with Claude.AI on 11/3/26.
	Copyright © 2026 MacThemes. All rights reserved.

	Fast 3-Tier Cache for Album Artwork: Memory ( NSCache ) -> Disk -> MPMediaItemArtwork-Generation …
*/

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCArtworkCache: NSObject

	+ (instancetype)sharedCache;

	/*
		Looks up Artwork for `entityIdentifier`.

		- If it's already in the In-Memory Cache, `completion` is called SYNCHRONOUSLY, on the calling Thread, before this Method returns. Call this from the Main Thread and you can set `view.image` directly inside the Completion Block with no Flicker.
		- Otherwise, Disk I/O / Decode / Generation happens on a Background Queue and `completion` is called ASYNCHRONOUSLY on the Main Queue.

		`token` identifies the Requester ( e.g. the re-used Cell ). Compare it against your View's current Album / Token inside the Completion Block before applying the Image, in Case the View was recycled for a different Album in the Meantime.
	*/
	- (void)artworkForEntityIdentifier: (uint64_t)entityIdentifier mediaItem: (nullable MPMediaItem *)representativeItem size: (CGSize)size withAlpha: (BOOL)withAlpha token: (nullable id)token completion: (void (^)(UIImage * _Nullable image, id _Nullable token))completion;

	/*
		Generic Lookup for Images this Class did not itself generate ( e.g. a Reflection captured from a CALayer, which must be rendered on the Main Thread by the Caller ). Checks the Memory Tier synchronously, then the Disk Tier asynchronously.

		- Does NOT fall back to generating anything - if neither Tier has it, `completion` is called with a nil Image so the Caller can generate one and hand it back via `- (void)storeImage: forKey: diskPath:`.
	*/
	- (void)cachedImageForKey: (NSString *)cacheKey diskPath: (NSString *)diskPath withAlpha: (BOOL)withAlpha token: (nullable id)token completion: (void (^)(UIImage * _Nullable image, id _Nullable token))completion;

	/*
		Convenience Wrapper over `- (void) cachedImageForKey:`diskPath: token: completion:` for Reflection PNGs, using the same "refl_<albumID>" / "<albumID>_r.png" Naming as the Rest of this Class.

		- Same nil-on-miss Contract - Caller generates and hands the Result to `- (void)storeImage: forKey: diskPath:` using `- (NSString *)reflectionCacheKeyForEntityIdentifier:` and `- (NSString *)diskPathForEntityIdentifier: suffix: @"_r"`.
	*/
	- (void)reflectionForEntityIdentifier: (uint64_t)entityIdentifier token: (nullable id)token completion: (void (^)(UIImage * _Nullable image, id _Nullable token))completion;

	- (NSString *)reflectionCacheKeyForEntityIdentifier: (uint64_t)entityIdentifier;

	/*
		Stores an already-generated Image into the Memory Tier immediately ( cheap, synchronous ), then predecodes it and writes it to `diskPath` on a Background Queue.

		- Use this after generating an Image through some Route this Class doesn't handle itself ( e.g. rendering a CALayer for a Reflection Snapshot ).
		- Pass a nil `diskPath` to only populate the Memory Tier.
	*/
	- (void)storeImage: (UIImage *)image forKey: (NSString *)cacheKey diskPath: (nullable NSString *)diskPath withAlpha: (BOOL)withAlpha;

	// Disk Path Helper, exposed so Callers can build Reflection / etc. Paths consistently.

	- (NSString *)diskPathForEntityIdentifier: (uint64_t)entityIdentifier suffix: (nullable NSString *)suffix;

	// Clears the In-Memory Tier only. Disk Cache is untouched.

	- (void)clearMemoryCache;

@end

NS_ASSUME_NONNULL_END
