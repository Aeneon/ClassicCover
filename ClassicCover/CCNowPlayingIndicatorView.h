/*
	CCNowPlayingIndicatorView.h
	ClassicCover

	Created by MacThemes with Claude.AI on 11/3/26.
	Copyright © 2026 MacThemes. All rights reserved.

	Small "Now Playing" Equalizer Glyph: Three Bars, animated while playing, static while paused …
*/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCNowPlayingIndicatorView: UIView

	// Should we suspend the Now-Playing-Animation ?

	@property (assign, nonatomic) BOOL animationSuspended;

	// Bars animate ( looping ) when true; when false they sit at fixed, uneven Heights. This matches the classic "paused" Glyph rather than just freezing Mid-Animation …

	@property (assign, nonatomic, getter = isPlaying) BOOL playing;

	// Tint for the Bars. Defaults to White …

	@property (strong, nonatomic) UIColor *barColor;

@end

NS_ASSUME_NONNULL_END
