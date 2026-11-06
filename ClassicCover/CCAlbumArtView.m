/*
	CCAlbumArtView.m
	ClassicCover

	Created by c0ldra1n on 8/26/17; Updated by MacThemes on 10/27/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import "CCAlbumArtView.h"
#import "CCPrefsManager.h"

#import "../MTCoreLogic.h"

// The Margin between Flip View Container's Edge and Flip View's Edge on every Side ( gives the Shadow Room to breathe ) …

@interface CCAlbumArtView()
{
	BOOL _flipViewVisible;

	CGRect _flipViewFrame;
	CGFloat _flipViewHeight;

	CGRect _originalFrame;
	CGPoint _originalCenter;

	BOOL _originalCenterSet;

	// Our Preferences …

	BOOL _reflection;
}
@end

@implementation CCAlbumArtView

	#pragma mark -
	#pragma mark Lifecycle

		- (instancetype)initWithFrame: (CGRect)frame
		{
			self = [super initWithFrame: frame];

			if(self)
			{
				self -> _originalFrame = frame;

				self.clipsToBounds = NO;

				// Should we use Reflections ?

				self -> _reflection = [CC_PREFS_VALUE_FOR_KEY(CCPrefsReflectionKey) boolValue];

				// If we want Reflections …

				if(self -> _reflection)
				{
					// … create the Reflection View.

					self.reflectionView = [[ReflectionView alloc] initWithFrame: self.bounds];

					self.reflectionView.clipsToBounds = NO;

					// If we're running on a Device with at least an Appla A9-CPU ( iPhone 6S(+), iPhone SE and iPad Pro ( 9.7" & 12.9" 1st Gen. ) ), we can use blurred Reflections too …

					if(!CCDeviceIsPreA9SoC && [CC_PREFS_VALUE_FOR_KEY(CCPrefsReflectionBlurKey) boolValue])
					{
						self.reflectionView.reflectionBlur = MAX((frame.size.width / CCReflectionViewBlurMultiplier), CCReflectionViewBlurMinimum);
					}

					// Let's create the Artwork View, which is a Part of the Reflection View …

					self.artworkView = [[UIImageView alloc] initWithFrame: CGRectMake(0.0, 0.0, frame.size.width, frame.size.width)];

					self.artworkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
					self.artworkView.contentMode = UIViewContentModeScaleAspectFill;
					self.artworkView.clipsToBounds = YES;

					// Add the Artwork View to our Reflection View …

					[self.reflectionView addSubview: self.artworkView];

					// Add the ( newly created ) Reflection View to our View Hierarchy …

					[self addSubview: self.reflectionView];
				}
				else
				{
					// … otherwise create only the Artwork View …

					self.artworkView = [[UIImageView alloc] initWithFrame: CGRectMake(0.0, 0.0, frame.size.width, frame.size.width)];

					self.artworkView.center = self.center;

					// … and add it to our View Hierarchy.

					[self addSubview: self.artworkView];
				}

				// Check, if we're running on an iPad …

				BOOL isiPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;

				// Calculate the Height of our Flip View ( Originally we used the Formulae: (x / 7) * 9 ), but if we're running on an iPad, set the Columns to 7 …

				self -> _flipViewHeight = ((isiPad ? 7 : [self columnsThatFitScreen]) * 50.0) + (isiPad ? 120.0 : 60.0);

				// … and set it's Size.

				self -> _flipViewFrame = CGRectMake(0.0, 0.0, self -> _flipViewHeight, self -> _flipViewHeight); // Original: (origFrame.size.width / 7) * 9 …
			}

			return self;
		}

		- (void)prepareForReuse
		{
			self.frame = _originalFrame;

			// If we want Reflections …

			if(self -> _reflection)
			{
				// Set the Reflection and Artwork View's original Frame …

				self.reflectionView.frame = self.bounds;
				self.artworkView.frame = self.reflectionView.bounds;

				// … and add the Reflection View, if not in our View Hierarchy.

				if(![self.subviews containsObject: self.reflectionView])
				{
					[self addSubview: self.reflectionView];
				}

				// Reset synchronously, right now - not deferred. Any `layoutSubviews` that fires between this Re-Use and the new Artwork actually loading must not re-display the previous Album's Reflection, and everything still in flight for the previous Album is dropped. `CCViewController` re-queries the Reflection Cache and requests a new Reflection once the correct Artwork has been applied …

				[self.reflectionView reset];
			}
			else
			{
				// … otherwise, if the Artwork View is not in our View Hierarchy …

				if(self.artworkView && ![self.subviews containsObject: self.artworkView])
				{
					// … set it's View to the original Frame …

					self.artworkView.frame = self.bounds;

					// … and add it back to our View Hierarchy.

					[self addSubview: self.artworkView];
				}
			}

			// The View may now represent another Album. Do not show the previous Cover while its asynchronous Lookup is still pending …

			self.artworkView.image = nil;

			// Check, if the Album Detail View is visible …

			if(self -> _flipViewVisible)
			{
				// We don't need to observe Now Playing Changes here …

				[self.flipViewController endObservingNowPlayingChanges];

				// Remove the Flip View Container from our View Hierarchy …

				[self.flipViewContainer removeFromSuperview];

				// The Artwork ( or Reflection ) View is back in our View Hierarchy, so this Card is not flipped anymore - otherwise it could never be flipped again …

				self -> _flipViewVisible = NO;
			}

			self.flipViewController = nil;
			self.flipView = nil;
			self.flipViewContainer = nil;
		}

	#pragma mark -
	#pragma mark Custom Accessors

		- (void)setActiveAnimated: (BOOL)active
		{
			// Check, if the Flip is shown …

			if(active)
			{
				// Alter the View's Opacity, …

				[UIView animateWithDuration: CCDurationThreeQuarter animations: ^
				{
					// … depending if we want Reflections or not …

					UIView *visibleView = self -> _reflection ? self.reflectionView : self.artworkView;

					visibleView.alpha = 1.0;
				}
				completion: ^(BOOL finished)
				{
					// … and if the Animation is finished, prevent User Interactions.

					[self setUserInteractionEnabled: YES];
				}];
			}
			else
			{
				// Set Background Color …

				self.backgroundColor = [UIColor blackColor];

				// Alter the View's Opacity, …

				[UIView animateWithDuration: CCDurationThreeQuarter animations: ^
				{
					// … depending if we want Reflections or not …

					UIView *visibleView = self -> _reflection ? self.reflectionView : self.artworkView;

					visibleView.alpha = CCBackgroundDarkeningAlphaNormal;
				}
				completion: ^(BOOL finished)
				{
					// … and if the Animation is finished, enable User Interactions ( again ).

					[self setUserInteractionEnabled: NO];
				}];
			}
		}

	#pragma mark -
	#pragma mark Private Methods

		- (NSInteger)columnsThatFitScreen
		{
			// Get Main Screen's Dimensions …

			CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
			CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;

			// … calculate them by using Screen's shortest Side ( 100 Pixels = 60 Pixels Artwork Sitze + 20 Pixels Spacing on Top and Bottom ) …

			NSInteger columns = (NSInteger)floor((((screenWidth > screenHeight) ? screenHeight : screenWidth) - 100.0) / 50.0);

			// … and return the Columns.

			return MAX(columns, 1);
		}

	#pragma mark -
	#pragma mark Public Methods

		- (void)flip: (BOOL)flag
		{
			if(self -> _flipViewVisible != flag)
			{
				[self.window setUserInteractionEnabled: NO];

				self.backgroundColor = [UIColor clearColor];

				// Call the associated Delegate …

				if(self.delegate)
				{
					[self.delegate albumArtView: self willFlip: !self -> _flipViewVisible];
				}

				// Initialize a ( new ) Instance of our Flip View …

				if(!self.flipViewController)
				{
					self.flipViewController = [[UIStoryboard storyboardWithName: @"ClassicCover" bundle: [NSBundle bundleForClass: self.class]] instantiateViewControllerWithIdentifier: @"albumTracksViewController"];

					self.flipViewController.album = self.album;

					self.flipViewContainer = [[UIView alloc] initWithFrame: self -> _flipViewFrame];

					self.flipView = self.flipViewController.view;

					self.flipView.albumArtView = self;
					self.flipView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

					[self.flipViewContainer addSubview: self.flipView];

					// If we should use a Shadow, draw them …

					if([CC_PREFS_VALUE_FOR_KEY(CCPrefsFlipShadowKey) boolValue])
					{
						CGSize size = self -> _flipViewFrame.size;

						self.flipViewContainer.layer.shadowColor = [UIColor blackColor].CGColor;
						self.flipViewContainer.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CCFlipContainerMargin, CCFlipContainerMargin, size.width, size.height) cornerRadius: CCDropShadowCorner].CGPath;
						self.flipViewContainer.layer.shadowOffset = CGSizeMake(0.0, CCDropShadowOffset);
						self.flipViewContainer.layer.shadowOpacity = CCDropShadowOpacity;
						self.flipViewContainer.layer.shadowRadius = CCDropShadowRadius;
					}
				}

				// Save our Center-Position …

				if(!self -> _originalCenterSet)
				{
					self -> _originalCenter = self.center;
					self -> _originalCenterSet = YES;
				}

				// Let's get back to the Main Thread …

				dispatch_async(dispatch_get_main_queue(), ^
				{
					if(flag)
					{
						// Set the Frames to their new Sizes and Coordinates …

						CGFloat flipWidth = self -> _flipViewHeight + (CCFlipContainerMargin * 2.0);
						CGFloat flipHeight = self -> _flipViewHeight + (CCFlipContainerMargin * 2.0);

						CGRect targetFrame = CGRectMake(0.0, 0.0, flipWidth, flipHeight);

						self.flipViewContainer.frame = CGRectMake(0.0, 0.0, flipWidth, flipHeight);
						self.flipView.frame = CGRectMake(CCFlipContainerMargin, CCFlipContainerMargin, self -> _flipViewHeight, self -> _flipViewHeight);

						// Let's set the Bounds of our UIView …

						self.bounds = CGRectMake(0.0, 0.0, targetFrame.size.width, targetFrame.size.height);

						// Set the Center-Position from our saved Value …

						self.center = self -> _originalCenter;

						// At first: Should we show Reflections ?

						if(self -> _reflection)
						{
							// If so, fade-out the Reflection, which prevents a small Bug, during un-flip when the Reflection is not painted until fully flipped …

							[self.reflectionView setReflectionAlphaAnimated: 0.0 duration: CCDurationHalf];
						}

						// Start tracking Now-Playing Changes while the Flip View is visible. We're using an Observer here, because it's plain `NSNotificationCenter` Bookkeeping and no `MediaPlayer` Call involved …

						[self.flipViewController beginObservingNowPlayingChanges];

						// The Screen may be appearing while a Track from this Album is already playing ( or was left paused ). Let's sync the Indicator now, don't wait for the next Notification …

						[self.flipViewController updateNowPlayingIndicator];

						// The Flip View will be shown …

						[UIView transitionWithView: self duration: CCDurationNormal options: (UIViewAnimationOptionTransitionFlipFromRight | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowAnimatedContent) animations: ^
						{
							[self addSubview: self.flipViewContainer];

							// If we should use a Reflection and remove one of both Views …

							[((self -> _reflection) ? self.reflectionView : self.artworkView) removeFromSuperview];
						}
						completion: ^(BOOL finished)
						{
							// Enable User Interactions ( again ) …

							[self.window setUserInteractionEnabled: YES];

							// If the Animation is finished, …

							if(finished)
							{
								// … determine if the Reflection View or Artwork View a Part of our View Hierarchy ?

								self -> _flipViewVisible = !((self -> _reflection ? self.reflectionView.superview : self.artworkView.superview) != nil);

								// Call the Delegate …

								if(self.delegate)
								{
									[self.delegate albumArtView: self didFlip: self -> _flipViewVisible];
								}
							}
						}];
					}
					else
					{
						// Get the original Frame Size …

						CGSize originalSize = self -> _originalFrame.size;

						// Get the Center of the Coordinates …

						CGPoint currentBoundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

						// Get the Center of the original Frame Size …

						CGPoint originalBoundsCenter = CGPointMake(originalSize.width / 2.0, originalSize.height / 2.0);

						// Determine, if we should use a Reflection and set the View …

						UIView *visibleView = self -> _reflection ? self.reflectionView : self.artworkView;

						// Let's set the Bounds and Center-Position of our View …

						visibleView.bounds = CGRectMake(0.0, 0.0, originalSize.width, originalSize.height);
						visibleView.center = currentBoundsCenter;

						// If we use Reflections, be sure, that Artwork's Frame is the same Size as Reflection View's Bounds …

						if(self -> _reflection)
						{
							self.artworkView.frame = self.reflectionView.bounds;
						}

						// Now add the View to the View Hierarchy …

						[self addSubview: visibleView];

						// Now the Flip View will be hidden …

						[UIView transitionWithView: self duration: CCDurationNormal options: (UIViewAnimationOptionTransitionFlipFromRight | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowAnimatedContent) animations: ^
						{
							// Let's set the Bounds of our UIView …

							self.bounds = CGRectMake(0.0, 0.0, originalSize.width, originalSize.height);

							// Set the Center of our View …

							visibleView.center = originalBoundsCenter;

							if(self -> _reflection)
							{
								self.artworkView.frame = self.reflectionView.bounds;
							}

							// Remove the Flip View from our View Hierarchy …

							[self.flipViewContainer removeFromSuperview];
						}
						completion: ^(BOOL finished)
						{
							// Let's set the Bounds of our UIView …

							self.bounds = CGRectMake(0.0, 0.0, originalSize.width, originalSize.height);

							// Set the Center-Position from our saved Value …

							self.center = self -> _originalCenter;

							// Enable User Interactions ( again ) …

							[self.window setUserInteractionEnabled: YES];

							// Let's set the Bounds and Center-Position of our View …

							visibleView.bounds = CGRectMake(0.0, 0.0, originalSize.width, originalSize.height);
							visibleView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

							// If we use Reflections, be sure, that Artwork's Frame is the same Size as Reflection View's Bounds …

							if(self -> _reflection)
							{
								self.artworkView.frame = self.reflectionView.bounds;
							}

							// The Flip View is going awaym, so stop tracking Now-Playing Changes for it …

							[self.flipViewController endObservingNowPlayingChanges];

							// If the Animation is finished …

							if(finished)
							{
								// … determine, if we should use a Reflection and fade them back in.

								if(self -> _reflection)
								{
									[self.reflectionView setReflectionAlphaAnimated: CCReflectionViewAlpha duration: CCDurationHalf];
								}

								// Is the Reflection View or Artwork View a Part of our View Hierarchy ?

								self -> _flipViewVisible = !((self -> _reflection ? self.reflectionView.superview : self.artworkView.superview) != nil);

								// Call the Delegate …

								if(self.delegate)
								{
									[self.delegate albumArtView: self didFlip: self -> _flipViewVisible];
								}
							}
						}];
					}
				});

				MTLog(@"Album Detail View is now %@.", _flipViewVisible ? @"visible" : @"hidden");
			}
		}

@end
