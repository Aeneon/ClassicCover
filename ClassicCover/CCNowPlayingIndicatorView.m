/*
	CCNowPlayingIndicatorView.m
	ClassicCover

	Created by MacThemes with Claude.AI on 11/3/26.
	Copyright © 2026 MacThemes. All rights reserved.

	Small "Now Playing" Equalizer Glyph: Three Bars, animated while playing, static while paused …
*/

#import "CCNowPlayingIndicatorView.h"

#import "../MTCoreLogic.h"

@interface CCNowPlayingIndicatorView()
{
	NSArray<CALayer *> *_bars;

	BOOL _isAnimating;
	BOOL _isStateApplied;
}
@end

@implementation CCNowPlayingIndicatorView

	#pragma mark -
	#pragma mark Lifecycle

		- (instancetype)initWithCoder: (NSCoder *)coder
		{
			self = [super initWithCoder: coder];

			if(self)
			{
				[self setup];
			}

			return self;
		}

		- (instancetype)initWithFrame: (CGRect)frame
		{
			self = [super initWithFrame: frame];

			if(self)
			{
				[self setup];
			}

			return self;
		}

		- (void)setup
		{
			self.backgroundColor = [UIColor clearColor];
			self.userInteractionEnabled = NO;

			self.barColor = [UIColor whiteColor];

			NSMutableArray<CALayer *> *bars = [NSMutableArray array];

			// Let's create the Bars upon the Maximum defined by `CCNowPlayingBarCount` ( usually 3 ) …

			for(NSUInteger index = 0; index < CCNowPlayingBarCount; index++)
			{
				CALayer *bar = [CALayer layer];

				// Very important: The Background Color …

				bar.backgroundColor = self.barColor.CGColor;

				// Apply a softer Touch …

				bar.cornerRadius = CCNowPlayingCornerRadius;

				// Add the Bar to our `CALayer` …

				[self.layer addSublayer: bar];

				[bars addObject: bar];
			}

			self -> _bars = bars;
		}

		- (void)didMoveToWindow
		{
			[super didMoveToWindow];

			// Get the Default Notification Center …

			NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

			// Remove the Observers …

			[notificationCenter removeObserver: self name: UIApplicationWillResignActiveNotification object: nil];
			[notificationCenter removeObserver: self name: UIApplicationDidBecomeActiveNotification object: nil];

			// Add the Observers for getting and loosing Focus …

			if(self.window)
			{
				[notificationCenter addObserver: self selector: @selector(applicationWillResignActive) name: UIApplicationWillResignActiveNotification object: nil];
				[notificationCenter addObserver: self selector: @selector(applicationDidBecomeActive) name: UIApplicationDidBecomeActiveNotification object: nil];
			}

			// Cells get re-used: Start cleanly when on Screen, and drop the Animation as soon as the View leaves the Window …

			[self applyIndicatorState];
		}

		- (void)dealloc
		{
			// Remove the Observers …

			[[NSNotificationCenter defaultCenter] removeObserver: self];
		}

		- (void)applicationWillResignActive
		{
			[self endIndicatorAnimation];
		}

		- (void)applicationDidBecomeActive
		{
			[self applyIndicatorState];
		}

	#pragma mark -
	#pragma mark Custom Accessors

		- (void)setAnimationSuspended: (BOOL)animationSuspended
		{
			if(_animationSuspended != animationSuspended)
			{
				_animationSuspended = animationSuspended;

				[self applyIndicatorState];
			}
		}

		- (void)setBarColor: (UIColor *)barColor
		{
			_barColor = barColor;

			for(CALayer *bar in self -> _bars)
			{
				bar.backgroundColor = barColor.CGColor;
			}
		}

		- (void)setHidden: (BOOL)hidden
		{
			if(self.hidden != hidden)
			{
				[super setHidden: hidden];

				[self applyIndicatorState];
			}
		}

		- (void)setPlaying: (BOOL)playing
		{
			if(_playing != playing)
			{
				_playing = playing;

				[self applyIndicatorState];
			}
		}

	#pragma mark -
	#pragma mark Private Methods

		- (void)applyIndicatorState
		{
			if(_playing && !self.animationSuspended && !self.hidden && self.window && [UIApplication sharedApplication].applicationState == UIApplicationStateActive)
			{
				[self beginIndicatorAnimation];
			}
			else
			{
				[self endIndicatorAnimation];
			}
		}

		- (void)layoutSubviews
		{
			[super layoutSubviews];

			// Lay the Bars out bottom-aligned, evenly spaced, each anchored at its own Bottom Edge so height-changing Animations grow upward - matching the Classic Equalizer Look - rather than from the Center …

			CGFloat barCount = (CGFloat)self -> _bars.count;
			CGFloat gap = 2.0;
			CGFloat totalGaps = gap * (barCount - 1.0);
			CGFloat barWidth = (self.bounds.size.width - totalGaps) / barCount;

			[CATransaction begin];

			// This is pure Layout, not an animated Property Change …

			[CATransaction setDisableActions: YES];

			// Let's initialize our Bars …

			for(NSUInteger index = 0; index < self -> _bars.count; index++)
			{
				CALayer *bar = self -> _bars[index];

				CGFloat x = index * (barWidth + gap);

				// Set the Anchor Point to Bottom-Center, so `scale.y` grows upwards …

				bar.anchorPoint = CGPointMake(0.5, 1.0);

				// Define the Position and Size …

				bar.position = CGPointMake(x + barWidth / 2.0, self.bounds.size.height);
				bar.bounds = CGRectMake(0.0, 0.0, barWidth, self.bounds.size.height);
			}

			[CATransaction commit];

			[self applyIndicatorState];
		}

	#pragma mark -
	#pragma mark Private Methods - Animation

		- (void)beginIndicatorAnimation
		{
			// If the Animation is ( still ) running, leave here …

			if(self -> _isAnimating)
			{
				return;
			}

			// … otherwise, start the Animation.

			self -> _isAnimating = YES;
			self -> _isStateApplied = YES;

			// Staggered Durations plus Start Offsets keep the Bars visibly out of Sync with each other - a uniform Pulse reads as a single blinking Box rather than an Equalizer …

			NSArray<NSNumber *> *durations = @[@0.45, @0.6, @0.5];
			NSArray<NSNumber *> *delays = @[@0.0, @0.12, @0.24];

			for(NSUInteger index = 0; index < self -> _bars.count; index++)
			{
				CALayer *bar = self -> _bars[index];

				if([bar animationForKey: CCNowPlayingAnimationKey])
				{
					// This is already animating, so don't Restart and lose Phase …

					continue;
				}

				// Create the Animation: This is the Core Part …

				CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath: @"transform.scale.y"];

				animation.fromValue = @0.25;
				animation.toValue = @1.0;

				animation.beginTime = CACurrentMediaTime() + [delays[index % delays.count] doubleValue];
				animation.duration = [durations[index % durations.count] doubleValue];

				animation.autoreverses = YES;
				animation.repeatCount = HUGE_VALF;
				animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
				animation.removedOnCompletion = NO;

				[bar addAnimation: animation forKey: CCNowPlayingAnimationKey];
			}
		}

		- (void)endIndicatorAnimation
		{
			// If the Animation is ( still ) running and the new State applied, leave here …

			if(self -> _isStateApplied && !self -> _isAnimating)
			{
				return;
			}

			// … otherwise, stop the Animation.

			self -> _isAnimating = NO;
			self -> _isStateApplied = YES;

			// Fixed, uneven Heights for the paused State - matches the Classic static Equalizer Glyph rather than freezing Mid-Pulse …

			NSArray<NSNumber *> *staticScales = @[@0.4, @1.0, @0.65];

			[CATransaction begin];
			[CATransaction setDisableActions: YES];

			for(NSUInteger index = 0; index < self -> _bars.count; index++)
			{
				CALayer *bar = self -> _bars[index];

				// Remove the Animation-Key, so the Animation basically stops here …

				[bar removeAnimationForKey: CCNowPlayingAnimationKey];

				// Let's Apply the static Heights …

				bar.transform = CATransform3DMakeScale(1.0, [staticScales[index % staticScales.count] doubleValue], 1.0);
			}

			[CATransaction commit];
		}

@end
