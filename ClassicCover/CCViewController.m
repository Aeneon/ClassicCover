/*
	CCViewController.m
	ClassicCover

	Created by c0ldra1n on 3/5/17; Updated by MacThemes on 11/7/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#include <dlfcn.h>

#import <sys/sysctl.h>

#import "CCViewController.h"

#import "../MTCoreHaptic.h"
#import "../MTCoreLogic.h"

#import "CCBundle.h"

#import "CCArtworkCache.h"
#import "CCNowPlayingIndicatorView.h"
#import "CCPrefsManager.h"

#import "MediaRemote.h"

#import "UIColor+Hex.h"
#import "UIColor+Random.h"
#import "UIImage+Graphics.h"

@interface CCViewController()
{
	// The Size of the Cover …

	CGFloat _cardUnit;

	// The Album-Array …

	NSArray<MPMediaItemCollection *> *_albums;

	// Persistent IDs in Carousel-Order, which avoids MediaPlayer-Property-Lookups during Scrolling …

	NSArray<NSNumber *> *_albumIdentifiers;

	// The Libraries last Modification Date ( available on iOS 9.3 and later ) …

	NSDate *_albumsLibraryDate;

	/*
		One Entry per Album that has finished loading Artwork, keyed by `albumPersistentID` …

		- Populated once ( in `- (void)carousel: viewForItemAtIndex:` ) the first Time an Album's Artwork loads, then reused every Scroll Frame in `- (void)carouselDidScroll:` - recomputing the average Color from the full Image on every Scroll Delta would be wasteful and jittery.
	*/
	NSMutableDictionary<NSNumber *, UIColor *> *_averageColorCache;

	// Get Main Screen's Dimensions …

	CGFloat _screenWidth;
	CGFloat _screenHeight;

	// The Fallback Image for Albums without a Cover …

	UIImage *_fallbackArtwork;

	// The Images for our Play/pause-Button …

	UIImage *_playImage;
	UIImage *_pauseImage;

	// The Images for our Repeat-Button ( Repeat all Tracks and Repeat the current Track ) …

	UIImage *_repeatImage;
	UIImage *_repeatOneImage;

	// The Image for our Shuffle-Button …

	UIImage *_shuffleImage;

	// iCarousel's pending Index …

	NSInteger _pendingFlipIndex;

	// Pins the top Label to the Top of the Carousel, only active on notched Devices ( the Storyboard pins the bottom Label to the Bottom of the Carousel instead ) …

	NSLayoutConstraint *_topLabelTopConstraint;

	// Bumped every Time a Fade-Out happens …

	NSUInteger _albumInfoFadeGeneration;

	// Are our Labels for showing Album Informations, such as Album Name and Artist currently faded out ?

	BOOL _albumInfoFadedOut;

	// Is the Album Detail View currently shown ? The Buttons for skipping Tracks, Shuffle and Repeat are only visible then …

	BOOL _albumDetailVisible;

	// Is the Demo-Loop currently running ?

	BOOL _demoRunning;

	// Is the Interface visible ?

	BOOL _interfaceVisible;

	// Should we generate Playback-Notifications ?

	BOOL _playbackNotificationsActive;

	// An Object that coordinates the processing of specific low-level System Events, such as our Timer for Fading the Album Informations …

	dispatch_source_t _albumInfoFadeTimer;

	// Bumped every Time a Demo-Loop happens or the Idle-Countdown get's refreshed …

	NSUInteger _demoGeneration;
	NSUInteger _demoIdleGeneration;

	/*
		Our last Jump-Direction:

		-	-1 = Last Jump went back …
		-	 0 = No Jump yet …
		-	 1 = Last Jump went forward …
	*/

	CCJumpDirection _demoLastDirection;

	// Our Preferences …

	iCarouselType _coverStyle;

	CCArtworkSize _artworkSize;

	CCBackgroundStyle _backgroundStyle;

	CCSortMethod _sortMethod;

	BOOL _autoHideLabels;

	BOOL _demoEnabled;

	BOOL _preventSleep;

	BOOL _reflection;
	BOOL _reflectionBlur;
}
@end

@implementation CCViewController

	#pragma mark -
	#pragma mark Lifecycle

		- (void)viewDidLoad
		{
			[super viewDidLoad];

			self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];

			// Set iCarousel's pending Index to a Value indicating that the Index doesn’t exist …

			self -> _pendingFlipIndex = NSNotFound;

			// Check, if we're running on a pre-A9-Device ( iPhone 5S, iPhone 6(+), iPad Air ( 1st & 2n Gen ), iPad mini ( 2nd - 4th Gen. ) and iPod touch 6 ) …

			CCDeviceIsPreA9SoC = [self deviceIsPreA9SoC];

			// Create a new Dispatch Queue ( if not exists ) to which we can submit Blocks …

			if(!CCControlQueue)
			{
				CCControlQueue = dispatch_queue_create("com.macthemes.classiccover.media.control", nil);
			}

			// Get the default Notification Center …

			NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

			[notificationCenter addObserver: self selector: @selector(applicationWillResignActive) name: UIApplicationWillResignActiveNotification object: nil];
			[notificationCenter addObserver: self selector: @selector(applicationDidBecomeActive) name: UIApplicationDidBecomeActiveNotification object: nil];

			// We need to add our own Observer here …

			[notificationCenter addObserver: self selector: @selector(updatePlaybackControls) name: MPMusicPlayerControllerPlaybackStateDidChangeNotification object: nil];

			// Prepares the Media Player for Playback …

			[self.musicPlayer prepareToPlay];

			// Getting Fallback-Artwork for Albums, which don't have a Cover :( …

			self -> _fallbackArtwork = [CCBundle getImageNamed: @"MissingAlbumArtwork"];

			// Set Background Wallpaper View' Content Mode …

			self.backgroundWallpaper.contentMode = UIViewContentModeScaleAspectFill;

			// … and send them to the Back in the View Hierarchy.

			[self.view sendSubviewToBack: self.backgroundWallpaper];

			// Set the Image for our Play/Pause-Button …

			self -> _playImage = [CCBundle getControlImageNamed: @"Play"];
			self -> _pauseImage = [CCBundle getControlImageNamed: @"Pause"];

			// Get the Images for the Buttons, which are only visible while the Album Detail View is shown …

			UIImage *previousTrack = [CCBundle getControlImageNamed: @"Previous"];
			UIImage *nextTrack = [CCBundle getControlImageNamed: @"Next"];

			[self.previousTrackButton setImage: previousTrack forState: UIControlStateNormal];
			[self.nextTrackButton setImage: nextTrack forState: UIControlStateNormal];

			// … and there are a few more.

			self -> _repeatImage = [CCBundle getControlImageNamed: @"Repeat"];
			self -> _repeatOneImage = [CCBundle getControlImageNamed: @"RepeatOne"];

			self -> _shuffleImage = [CCBundle getControlImageNamed: @"Shuffle"];

			[self.repeatButton setImage: self -> _repeatImage forState: UIControlStateNormal];
			[self.shuffleButton setImage: self -> _shuffleImage forState: UIControlStateNormal];

			// Get Screen's Scale …

			CGFloat scale = [UIScreen mainScreen].scale;

			// Set the Trailing Buffer for our Labels showing Album Informations …

			self.topLabel.trailingBuffer = MIN(CCMarqueeLabelTrailingBufferMinimum, self.topLabel.bounds.size.width / 4.0);
			self.bottomLabel.trailingBuffer = MIN(CCMarqueeLabelTrailingBufferMinimum, self.bottomLabel.bounds.size.width / 4.0);

			// Add a Shadow to our Labels for showing Album Informations, such as Album Name and Artist …

			self.topLabel.layer.masksToBounds = NO;

			self.topLabel.layer.shadowColor = [UIColor blackColor].CGColor;
			self.topLabel.layer.shadowRadius = CCTextShadowRadius / scale;
			self.topLabel.layer.shadowOpacity = CCTextShadowOpacity;
			self.topLabel.layer.shadowOffset = CGSizeMake(0.0, CCTextShadowOffset / scale);

			self.bottomLabel.layer.masksToBounds = NO;

			self.bottomLabel.layer.shadowColor = [UIColor blackColor].CGColor;
			self.bottomLabel.layer.shadowRadius = CCTextShadowRadius / scale;
			self.bottomLabel.layer.shadowOpacity = CCTextShadowOpacity;
			self.bottomLabel.layer.shadowOffset = CGSizeMake(0.0, CCTextShadowOffset / scale);

			// Bring both Labels to Front …

			NSArray<UIView *> *subViews = @[self.previousTrackButton, self.nextTrackButton, self.topLabel, self.bottomLabel, self.shuffleButton, self.repeatButton, self.playPauseButton];

			for(UIView *subView in subViews)
			{
				[self.carouselView bringSubviewToFront: subView];
			}

			// If we're running on an iPad …

			if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
			{
				// … create a new Gesture Regognizer, which regognizes every Tap on the Screen, so we can exit our Demo-Loop.

				UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget: nil action: NULL];

				// Set the Delegate to our View …

				tapGesture.delegate = self;

				// Add the new Gesture Regognizer to our View …

				[self.view addGestureRecognizer: tapGesture];
			}

			// A small Easter Egg: Long pressing the Play/Pause-Button does some magically …

			UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(surpriseMe:)];

			// You have to press a little Bit longer …

			longPressGesture.minimumPressDuration = CCDurationNormal;

			// … and add the Gesture Regognizer to the Play/Pause-Button.

			[self.playPauseButton addGestureRecognizer: longPressGesture];
		}

		- (void)viewWillAppear:(BOOL)animated
		{
			[super viewWillAppear: animated];

			// On iOS 11 and later …

			if(@available(iOS 11, *))
			{
				// … apply the current Safe-Area-Insets, before the Interface becomes visible.

				[self updateSafeAreaLayout];
			}

			// Get Main Screen's Dimensions …

			self -> _screenWidth = [UIScreen mainScreen].bounds.size.width;
			self -> _screenHeight = [UIScreen mainScreen].bounds.size.height;

			// If we're running on an iPad …

			if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
			{
				// … we use nearly the same Formulae here, as on an iPhone / iPod touch, a little Bit shortened.

				self -> _cardUnit = ((self -> _screenWidth > self -> _screenHeight) ? self -> _screenHeight : self -> _screenWidth) / 2.0;
			}
		}

		- (void)viewDidAppear: (BOOL)animated
		{
			[super viewDidAppear: animated];

			// Yeah, the Interface is visible …

			self -> _interfaceVisible = YES;

			// Let's resume ClassicCover's Activity …

			[self resumeClassicCover];

			// Apply the ( newly made ) Preferences …

			[self applyPreferencesIfNeeded];

			// Show the Interface …

			[self setInterfaceAlpha: 1.0 delay: (CCPreferencesHaveChanged ? CCDurationDelay : 0.0)];

			// Indicate to the System that the View Controller Status Bar Attributes have changed …

			[self setNeedsStatusBarAppearanceUpdate];

			// On iOS 11 and later …

			if(@available(iOS 11, *))
			{
				// … we have to notify UIKit that your View Controller updated its Preference regarding the Home Indicator.

				[self setNeedsUpdateOfHomeIndicatorAutoHidden];
			}

			// Resume only the Marquee Labels that are actually visible …

			if(self.topLabel.alpha > 0.0)
			{
				[self.topLabel restartLabel];
			}

			if(self.bottomLabel.alpha > 0.0)
			{
				[self.bottomLabel restartLabel];
			}
		}

		- (void)viewWillDisappear: (BOOL)animated
		{
			// Ohh, the Interface will be hidden …

			self -> _interfaceVisible = NO;

			// Let's suspend ClassicCover's Activity …

			[self suspendClassicCover];

			// Stop the Demo-Loop …

			[self endPresentationMode];

			// … and stop the Idle-Countdown too.

			self -> _demoIdleGeneration++;

			// Cancels a pending Fade-Out …

			self -> _albumInfoFadeGeneration++;

			// … so the Un-Flip restarts the Marquee from Home.

			self -> _albumInfoFadedOut = YES;

			// The Marquee Animation of our Labels should not keep running while ClassicCover is hidden …

			[self.topLabel shutdownLabel];
			[self.bottomLabel shutdownLabel];

			// If we're running on an iPad and "Prevent Display Sleep" is turned on, allow Display going to Sleep, since ClassicCover's View is hidden …

			[self caffeinate: NO];

			// Hide the Interface …

			[self setInterfaceAlpha: 0.0 delay: CCDurationDelay];

			// Call `super` of this Method …

			[super viewWillDisappear: animated];
		}

		- (void)dealloc
		{
			// Stop the Generation of Playback Notifications, if necessary …

			if(self -> _playbackNotificationsActive)
			{
				[self.musicPlayer endGeneratingPlaybackNotifications];
			}

			// Cancel our Fade of Album Informations …

			if(self -> _albumInfoFadeTimer)
			{
				dispatch_source_cancel(self -> _albumInfoFadeTimer);
			}

			// Remove the Observers …

			[[NSNotificationCenter defaultCenter] removeObserver: self];
		}

	#pragma mark -
	#pragma mark Overrides

		- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
		{
			if(kCFCoreFoundationVersionNumber >= 1443.00 && kCFCoreFoundationVersionNumber < 1665.15 && [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
			{
				return UIInterfaceOrientationPortrait;
			}
			else
			{
				return UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
			}
		}

		- (UIStatusBarStyle)preferredStatusBarStyle
		{
			return UIStatusBarStyleLightContent;
		}

		- (BOOL)prefersHomeIndicatorAutoHidden
		{
			return YES;
		}

		- (BOOL)prefersStatusBarHidden
		{
			return [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad;
		}

		- (BOOL)shouldAutorotate
		{
			return YES;
		}

		- (UIInterfaceOrientationMask)supportedInterfaceOrientations
		{
			if(kCFCoreFoundationVersionNumber >= 1443.00 && kCFCoreFoundationVersionNumber < 1665.15 && [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
			{
				return UIInterfaceOrientationMaskAllButUpsideDown;
			}
			else
			{
				return UIInterfaceOrientationMaskLandscape;
			}
		}

	#pragma mark -
	#pragma mark Memory Management

		- (void)didReceiveMemoryWarning
		{
			// Dispose of any resources that can be recreated.

			[super didReceiveMemoryWarning];
		}

	#pragma mark -
	#pragma mark Safe Area

		- (void)viewSafeAreaInsetsDidChange
		{
			[super viewSafeAreaInsetsDidChange];

			// Gets called by UIKit on iOS 11 and above, whenever the Insets change …

			[self updateSafeAreaLayout];
		}

		- (void)updateSafeAreaLayout
		{
			// Do a Compatibility-Check at First: If we're running iOS 11 and above, we can use Safe-Area-Insets …

			if(@available(iOS 11, *))
			{
				// Get the Edge-Insets …

				UIEdgeInsets safeAreaInsets = self.view.safeAreaInsets;

				// Keep iCarousel's Labels and Buttons inside the Safe Area. Both Constraints are pinned to the View's Edges, so the trailing Constant has to be negative …

				self.carouselLeadingConstraint.constant = safeAreaInsets.left;
				self.carouselTrailingConstraint.constant = -safeAreaInsets.right;

				// Create the Constraint pinning the Top Album-Information-Label to the Top of iCarousel once …

				if(!self -> _topLabelTopConstraint)
				{
					self -> _topLabelTopConstraint = [self.topLabel.topAnchor constraintEqualToAnchor: self.carouselView.topAnchor constant: 11.0];
				}

				// Check, if we're running on a notched Device …

				if(safeAreaInsets.left > 0.0 || safeAreaInsets.right > 0.0)
				{
					// … if so, deactivate the bottom Pin at First. Both Labels are chained, so exactly one End of the Chain may be pinned, otherwise the Layout would be over-constrained …

					self.bottomLabelBottomConstraint.active = NO;

					// Now pin the top Label to the Top …

					self -> _topLabelTopConstraint.constant = 11.0 + safeAreaInsets.top;
					self -> _topLabelTopConstraint.active = YES;
				}
				else
				{
					// … otherwise, deactivate the top Pin at First. Both Labels are chained, so exactly one End of the Chain may be pinned, otherwise the Layout would be over-constrained …

					self -> _topLabelTopConstraint.active = NO;

					// Now pin the bottom Label to the Bottom …

					self.bottomLabelBottomConstraint.active = YES;
				}

				[self.view setNeedsLayout];
			}
		}

	#pragma mark -
	#pragma mark App Activity

		- (void)applicationWillResignActive
		{
			// Suspend any Animations and other Background Activity …

			[self suspendClassicCover];
		}

		- (void)applicationDidBecomeActive
		{
			// Let all synchronous Activation-Observers ( including Preferences ) finish …

			dispatch_async(dispatch_get_main_queue(), ^
			{
				if([self isInterfaceActive])
				{
					// Resume any Animations and other Background Activity …

					[self resumeClassicCover];

					// Apply the ( newly made ) Preferences …

					[self applyPreferencesIfNeeded];

					// Show and fade-in the Album Information …

					[self showAlbumInfoAndScheduleFadeOut];
				}
			});
		}

	#pragma mark -
	#pragma mark iCarousel

		- (NSInteger)numberOfItemsInCarousel: (iCarousel *)carousel
		{
			return self -> _albums.count;
		}

		- (void)carousel: (iCarousel *)carousel didSelectItemAtIndex: (NSInteger)index
		{
			if(carousel.isScrolling)
			{
				self -> _pendingFlipIndex = index;

				return;
			}

			[self flipItemAtIndex: index inCarousel: carousel];
		}

		- (CGFloat)carousel: (iCarousel *)carousel valueForOption: (iCarouselOption)option withDefault: (CGFloat)value
		{
			if(carousel.type == iCarouselTypeCoverFlow || carousel.type == iCarouselTypeCoverFlow2)
			{
				if(option == iCarouselOptionSpacing)
				{
					return 0.3;
				}

				if(option == iCarouselOptionShowBackfaces)
				{
					return 0.0;
				}
			}

			return value;
		}

		- (UIView *)carousel: (iCarousel *)carousel viewForItemAtIndex: (NSInteger)index reusingView: (nullable UIView *)view
		{
			CCAlbumArtView *albumArtView;

			// If no View exists, we have to create a new One …

			if(!view)
			{
				albumArtView = [[CCAlbumArtView alloc] initWithFrame: CGRectMake(0.0, 0.0, self -> _cardUnit, self -> _cardUnit)];
			}
			else
			{
				albumArtView = (CCAlbumArtView *)view;

				// But if still a View exists, we have to prepare it for a Re-Use …

				[albumArtView prepareForReuse];
			}

			// Get the current Album from our Collection …

			MPMediaItemCollection *collection = self -> _albums[index];

			albumArtView.album = collection;

			// If we have a valid Album Artwork as Cover …

			if([collection.representativeItem artwork])
			{
				// … get the `albumPersistentID`.

				MPMediaEntityPersistentID albumPersistentID = [self -> _albumIdentifiers[index] unsignedLongLongValue];

				// Now the Magic begins: Show whatever's already on Screen ( or nothing ) immediately. The Cache Callback below fills it in as soon as it's ready, sync if already warm …

				[[CCArtworkCache sharedCache] artworkForEntityIdentifier: albumPersistentID mediaItem: collection.representativeItem size: CGSizeMake(self -> _cardUnit, self -> _cardUnit) withAlpha: NO token: collection completion: ^(UIImage *artwork, id token)
				{
					// It's possible, that `albumArtView.album` may have been re-assigned to a different Album by the Time this runs ( Cell Re-Use ), so don't paint the wrong Cover …

					if(albumArtView.album == token)
					{
						MPMediaItem *representativeItem = collection.representativeItem;

						// Log the Entity Identifier with dedicated Informations, such as Title, Artist and Album Title …

						MTLog(@"Got Cover-Artwork for „%@ – %@“ in Album „%@“ with ID: %llu.", representativeItem.title, representativeItem.artist, representativeItem.albumTitle, albumPersistentID);

						// Set the Artwork …

						albumArtView.artworkView.image = artwork;

						// If the User requested Colorization from Artwork …

						if(self -> _backgroundStyle == CCBackgroundStyleColorAlbum)
						{
							// … cache the Color, but don't touch Background Wallpaper View here `- (void)carouselDidScroll:` is what actually drives the Background, continuously, based on Scroll Position …

							UIColor *color = self -> _averageColorCache[@(albumPersistentID)];

							if(!color && artwork)
							{
								color = [artwork averageColor];
							}

							if(color)
							{
								self -> _averageColorCache[@(albumPersistentID)] = color;

								if(carousel.currentItemIndex == index)
								{
									self.backgroundWallpaper.backgroundColor = color;
								}
							}
						}

						// If we want Reflections …

						if(self -> _reflection)
						{
							// Chaining this inside the Artwork Completion, rather than firing both Lookups independently, is what guarantees the Ordering.

							albumArtView.reflectionView.delegate = self;
							albumArtView.reflectionView.entityIdentifier = albumPersistentID;

							[[CCArtworkCache sharedCache] reflectionForEntityIdentifier: albumPersistentID token: collection completion: ^(UIImage *reflection, id token)
							{
								// Is still the same Album and the same Artwork on Screen and does it still have the same ID ?

								BOOL stillCurrent = (albumArtView.album == token) && (albumArtView.artworkView.image == artwork) && (albumArtView.reflectionView.entityIdentifier == albumPersistentID);

								// If not, leave here …

								if(!stillCurrent)
								{
									return;
								}

								// Otherwise, check, if we want Reflections or not …

								if(reflection)
								{
									// Log the Entity Identifier with dedicated Informations, such as Title, Artist and Album Title …

									MTLog(@"Got Cover-Reflection for „%@ – %@“ in Album „%@“ with ID: %llu.", representativeItem.title, representativeItem.artist, representativeItem.albumTitle, albumPersistentID);

									// Cache Hit - just display it, no re-render needed …

									albumArtView.reflectionView.image = reflection;
								}
								else
								{
									// Log the Entity Identifier with dedicated Informations, such as Title, Artist and Album Title …

									MTLog(@"Creating new Cover-Reflection for „%@ – %@“ in Album „%@“ with ID: %llu.", representativeItem.title, representativeItem.artist, representativeItem.albumTitle, albumPersistentID);

									// Cache Miss: Render the Reflection directly from the Artwork, which we got for exactly this Album. Artwork and Entity Identifier travel together, so the Reflection can't end up with a different Cover …

									[albumArtView.reflectionView renderReflectionFromArtwork: artwork entityIdentifier: albumPersistentID];
								}
							}];
						}
					}
				}];
			}
			else
			{
				// … otherwise, get the persistent Album ID, …

				MPMediaEntityPersistentID albumPersistentID = [collection.representativeItem albumPersistentID];

				// … if we want to get the Background Color from Album …

				if(self -> _backgroundStyle == CCBackgroundStyleColorAlbum)
				{
					// … set the Color to Black …

					UIColor *color = [UIColor blackColor];

					self -> _averageColorCache[@(albumPersistentID)] = color;

					// … and set the Background Color.

					if(carousel.currentItemIndex == index)
					{
						self.backgroundWallpaper.backgroundColor = color;
					}
				}

				// Now use the Fallback-Image as Artwork :( …

				albumArtView.artworkView.image = self -> _fallbackArtwork;

				// If we want Reflections …

				if(self -> _reflection)
				{
					albumArtView.reflectionView.delegate = self;

					// Render the Reflection directly from the Fallback Artwork …

					[albumArtView.reflectionView renderReflectionFromArtwork: self -> _fallbackArtwork entityIdentifier: albumPersistentID];
				}
			}

			return albumArtView;
		}

		- (void)carouselCurrentItemIndexDidChange: (iCarousel *)carousel
		{
			NSInteger index = carousel.currentItemIndex;

			if([self isInterfaceActive] && index >= 0 && index < (NSInteger)self -> _albums.count)
			{
				// Set Album Informations, depending on the Preference we set …

				[self setAlbumInformations: self -> _albums[index].representativeItem];

				// Show and fade-in the Album Information …

				[self showAlbumInfoAndScheduleFadeOut];
			}
		}

		- (void)carouselDidEndScrollingAnimation: (iCarousel *)carousel
		{
			NSInteger index = self -> _pendingFlipIndex;

			self -> _pendingFlipIndex = NSNotFound;

			if(index != NSNotFound && index == carousel.currentItemIndex)
			{
				[self flipItemAtIndex: index inCarousel: carousel];
			}
		}

		- (void)carouselDidScroll: (iCarousel *)carousel
		{
			// If we don't want to colorize the Background Color from Album, leave the Function …

			if(self -> _backgroundStyle == CCBackgroundStyleColorAlbum)
			{
				CGFloat offset = carousel.scrollOffset;

				NSInteger lowerIndex = (NSInteger)floor(offset);
				NSInteger upperIndex = lowerIndex + 1;

				CGFloat fraction = offset - lowerIndex;

				UIColor *fromColor = [self averageColorForAlbumAtIndex: lowerIndex];
				UIColor *toColor = [self averageColorForAlbumAtIndex: upperIndex];

				if(fromColor && toColor)
				{
					self.backgroundWallpaper.backgroundColor = [self blendedColorFrom: fromColor to: toColor fraction: fraction];
				}
				else if(fromColor)
				{
					// The Neighbour we're scrolling towards hasn't loaded a Color yet, so show the One we do have rather than nothing, and let the next Scroll Delta ( or the Artwork Completion Firing ) pick up the Blend once it's available …

					self.backgroundWallpaper.backgroundColor = fromColor;
				}
				else if(toColor)
				{
					self.backgroundWallpaper.backgroundColor = toColor;
				}
			}
		}

		- (void)carouselWillBeginDragging: (iCarousel *)carousel
		{
			// Show and fade-in the Album Information …

			[self showAlbumInfoAndScheduleFadeOut];
		}

	#pragma mark -
	#pragma mark Reflection View

		- (void)reflectionDidUpdate: (UIImage *_Nullable)image entityIdentifier: (uint64_t)entityPersistentID
		{
			// The Function `- (void)reflectionDidUpdate` fires on the Main Thread ( it's driven by CALayer-Rendering ), so keep this call cheap: It only touches the Memory Tier synchronously and pushes Pre-Decode + Disk Write to a Background Queue …

			NSString *key = [[CCArtworkCache sharedCache] reflectionCacheKeyForEntityIdentifier: entityPersistentID];
			NSString *diskPath = [[CCArtworkCache sharedCache] diskPathForEntityIdentifier: entityPersistentID suffix: @"_r"];

			[[CCArtworkCache sharedCache] storeImage: image forKey: key diskPath: diskPath withAlpha: YES];
		}

	#pragma mark -
	#pragma mark Album Art View

		- (void)albumArtView: (CCAlbumArtView *)view willFlip: (BOOL)flipVisible
		{
			if(flipVisible)
			{
				self.carouselView.scrollEnabled = NO;
				self.carouselView.tapShortCutEnabled = NO;

				// Cancels a pending Fade-Out …

				self -> _albumInfoFadeGeneration++;

				[self cancelAlbumInfoFade];

				// … so the Un-Flip restarts the Marquee from Home.

				self -> _albumInfoFadedOut = YES;

				// Fade-out and hide the Album Information …

				[UIView transitionWithView: self.view duration: (CCDurationHalf / 2) options: UIViewAnimationOptionCurveEaseIn animations: ^
				{
					self.topLabel.alpha = 0.0;
					self.bottomLabel.alpha = 0.0;
				}
				completion: ^(BOOL finished)
				{
					if(finished)
					{
						self.topLabel.hidden = YES;
						self.bottomLabel.hidden = YES;

						// The Marquee Animation of our Labels should not keep running while Detail View is hidden …

						[self.topLabel shutdownLabel];
						[self.bottomLabel shutdownLabel];
					}
				}];

				// Decrease the Opacity of all visible Covers, except the current One …

				for(CCAlbumArtView *card in self.carouselView.visibleItemViews)
				{
					if(card != view)
					{
						[card setActiveAnimated: NO];
					}
				}
			}

			self -> _albumDetailVisible = flipVisible;

			// Show ( or hide ) our Playback Controls and slide the Play/Pause-Button, while the Cover flips …

			[self updatePlaybackControlsAnimated: YES];
		}

		- (void)albumArtView: (CCAlbumArtView *)view didFlip: (BOOL)flipVisible
		{
			if(!flipVisible)
			{
				self.carouselView.scrollEnabled = YES;
				self.carouselView.tapShortCutEnabled = YES;

				// Show and fade-in the Album Information …

				[self showAlbumInfoAndScheduleFadeOut];

				// Increase the Opacity of all visible Covers, except the current One …

				for(CCAlbumArtView *card in self.carouselView.visibleItemViews)
				{
					if(card != view)
					{
						[card setActiveAnimated: YES];
					}
				}
			}
		}

	#pragma mark -
	#pragma mark Interface Builder

		- (IBAction)skipToPreviousTrack: (id)sender
		{
			// Depending on the current Playback Time, this restarts the current Track instead …

			MRMediaRemoteSendCommand(kMRPreviousTrack, nil);

			// Let's get back to the Main Thread and send haptic Feedback …

			dispatch_async(dispatch_get_main_queue(), ^
			{
				[MTCoreHaptic triggerFeedbackWithPreference: MTCoreHapticFeedbackStyleLight];
			});
		}

		- (IBAction)togglePlayPause: (id)sender
		{
			// Getting Playback-State can block on IPC with `mediaserverd`, so we always do it on our Control Queue, off the Main Thread …

			dispatch_async(CCControlQueue, ^
			{
				if([MPMusicPlayerController systemMusicPlayer].playbackState == MPMusicPlaybackStatePlaying)
				{
					[self.musicPlayer pause];
				}
				else
				{
					if(![MPMusicPlayerController systemMusicPlayer].nowPlayingItem)
					{
						// Get the Album from the iCarousel's current Index …

						MPMediaItemCollection *collection = self -> _albums[self.carouselView.currentItemIndex];

						// Set Queue if no Track is playing …

						[self.musicPlayer setQueueWithItemCollection: collection];
					}

					[self.musicPlayer play];
				}

				// Let's get back to the Main Thread and send haptic Feedback …

				dispatch_async(dispatch_get_main_queue(), ^
				{
					[MTCoreHaptic triggerFeedbackWithPreference: MTCoreHapticFeedbackStyleLight];
				});
			});
		}

		- (IBAction)skipToNextTrack: (id)sender
		{
			// Let's go the the next Item …

			MRMediaRemoteSendCommand(kMRNextTrack, nil);

			// Let's get back to the Main Thread and send haptic Feedback …

			dispatch_async(dispatch_get_main_queue(), ^
			{
				[MTCoreHaptic triggerFeedbackWithPreference: MTCoreHapticFeedbackStyleLight];
			});
		}

		- (IBAction)toggleShuffleMode: (id)sender
		{
			// Reading Shuffle-Mode can block on IPC with `mediaserverd`, so we always fetch it on our Control Queue, off the Main Thread …

			dispatch_async(CCControlQueue, ^
			{
				// Switch between Shuffle the Songs of the current Album / Playlist and Shuffle Off …

				if([MPMusicPlayerController systemMusicPlayer].shuffleMode == MPMusicShuffleModeOff)
				{
					MRMediaRemoteSetShuffleMode(kMRAShuffleTracks);
				}
				else
				{
					MRMediaRemoteSetShuffleMode(kMRAShuffleDisabled);
				}

				// We have to wait 250 Milliseconds here, before we update the Playback Controls, since it's possible Media Remote isn't as fast, as we want …

				dispatch_time_t safeDispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CCIntervalSafeDispatchTime * NSEC_PER_SEC));

				// Let's get back to the Main Thread: Send haptic Feedback …

				dispatch_async(dispatch_get_main_queue(), ^
				{
					[MTCoreHaptic triggerFeedbackWithPreference: MTCoreHapticFeedbackStyleLight];
				});

				// … and with a Delay, update our Playback Controls.

				dispatch_after(safeDispatchTime, dispatch_get_main_queue(), ^(void)
				{
					[self updatePlaybackControlsAnimated: NO];
				});
			});
		}

		- (IBAction)toggleRepeatMode: (id)sender
		{
			// Reading Repeat-Mode can block on IPC with `mediaserverd`, so we always fetch it on our Control Queue, off the Main Thread …

			dispatch_async(CCControlQueue, ^
			{
				// Cycle through Repeat off, Repeat all Tracks and Repeat the current Track …

				switch([MPMusicPlayerController systemMusicPlayer].repeatMode)
				{
					case MPMusicRepeatModeAll:	MRMediaRemoteSetRepeatMode(kMRARepeatTrack); break;
					case MPMusicRepeatModeOne:	MRMediaRemoteSetRepeatMode(kMRARepeatDisabled); break;
					default:					MRMediaRemoteSetRepeatMode(kMRARepeatPlaylist); break;
				}

				// We have to wait 250 Milliseconds here, before we update the Playback Controls, since it's possible Media Remote isn't as fast, as we want …

				dispatch_time_t safeDispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CCIntervalSafeDispatchTime * NSEC_PER_SEC));

				// Let's get back to the Main Thread: Send haptic Feedback …

				dispatch_async(dispatch_get_main_queue(), ^
				{
					[MTCoreHaptic triggerFeedbackWithPreference: MTCoreHapticFeedbackStyleLight];
				});

				// … and with a Delay, update our Playback Controls.

				dispatch_after(safeDispatchTime, dispatch_get_main_queue(), ^(void)
				{
					[self updatePlaybackControlsAnimated: NO];
				});
			});
		}

	#pragma mark -
	#pragma mark Now Playing

		- (void)resetAlbumDetailState
		{
			// `- (void)reloadData` throws all Cards away, including a flipped One - they never reach `- (void)prepareForReuse` and `- (void)albumArtView: didFlip:` is never sent. So undo everything here, what `- (void)albumArtView: willFlip:` has changed …

			if(self.carouselView.scrollEnabled && !self -> _albumDetailVisible)
			{
				return;
			}

			self.carouselView.scrollEnabled = YES;
			self.carouselView.tapShortCutEnabled = YES;

			// The Album Detail View will be hidden …

			self -> _albumDetailVisible = NO;

			// Show the Album Information again …

			[self showAlbumInfoAndScheduleFadeOut];

			// Hide our Playback Controls and slide the Play/Pause-Button, while the Cover flips …

			[self updatePlaybackControlsAnimated: YES];
		}

		- (void)setAlbumInformations: (MPMediaItem *)representativeItem
		{
			NSString *topLabelText;
			NSString *bottomLabelText;

			// Which Sort-Method do we use ?

			if(self -> _sortMethod == CCSortMethodGenre)
			{
				// The easiest Part: Set the Album Title and Album Artist …

				topLabelText = [representativeItem.albumTitle stringByAppendingString: [@" – " stringByAppendingString: representativeItem.albumArtist]];

				// The localized String for "Genre" …

				NSString *genre = [CCBundle getLocalizedStringForKey: @"CCGenre"];

				// Set the last remaining Album Information …

				bottomLabelText = [NSString stringWithFormat: @"%@ %@", genre, representativeItem.genre];
			}
			else if(self -> _sortMethod == CCSortMethodDateAddedAscending || self -> _sortMethod == CCSortMethodDateAddedDescending || self -> _sortMethod == CCSortMethodLastPlayedDateAscending || self -> _sortMethod == CCSortMethodLastPlayedDateDescending)
			{
				// The easiest Part: Set the Album Title and Album Artist …

				topLabelText = [representativeItem.albumTitle stringByAppendingString: [@" – " stringByAppendingString: representativeItem.albumArtist]];

				// Not we do some Magic: Instead of simply showing the last played / added Date, we categorize them with some nice looking localizable Strings …

				NSDate *now = [NSDate date];
				NSDate *date;

				// The localized String for "Last played Date" / "Date added" …

				NSString *localizedPrefix;

				// We can fetch the Date, where an Item was added to the Library, …

				if(self -> _sortMethod == CCSortMethodDateAddedAscending || self -> _sortMethod == CCSortMethodDateAddedDescending)
				{
					// … but only, if we're running iOS 10 and above.

					if(@available(iOS 10, *))
					{
						date = representativeItem.dateAdded;

						// Set our localized Prefix …

						localizedPrefix = [CCBundle getLocalizedStringForKey: @"CCDateAdded"];
					}
				}
				else
				{
					// … otherwise we can also use the last played Date.

					date = representativeItem.lastPlayedDate;

					// Set our localized Prefix …

					localizedPrefix = [CCBundle getLocalizedStringForKey: @"CCLastPlayed"];
				}

				// Where's my DeLorean ? I wan't to d(r)ive into the History …

				NSCalendar *calendar = [NSCalendar currentCalendar];

				// Ask the Calendar for the elapsed Time as a proper Year / Month / Day Breakdown right away ( the same well-established Pattern used for e.g. Age Calculations ) …

				NSDateComponents *elapsed = [calendar components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate: date toDate: now options: 0];

				// The localized String for the Timespan …

				NSString *localizedTimespan;

				// Let's travel through the Time … 1985 … 1955 … 2015 … 1885 … nahh maybe not so long …

				if(!date) // Never played …
				{
					localizedTimespan = [CCBundle getLocalizedStringForKey: @"CCLastPlayedNever"];
				}
				else if([calendar isDateInToday: date]) // Today …
				{
					localizedTimespan = [CCBundle getLocalizedStringForKey: @"CCLastPlayedToday"];
				}
				else if([calendar isDateInYesterday: date]) // Yesterday
				{
					localizedTimespan = [CCBundle getLocalizedStringForKey: @"CCLastPlayedYesterday"];
				}
				else if([calendar isDate: date equalToDate: now toUnitGranularity: NSCalendarUnitWeekOfYear]) // Date is in the current Calendar Week …
				{
					// Create a new Date Formatter with the current Locale …

					NSDateFormatter *weekdayFormatter = [[NSDateFormatter alloc] init];

					weekdayFormatter.locale = [NSLocale currentLocale];

					// We want to have a localized Weekday, the Date and the full Month …

					NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate: @"EEEE d MMMM" options: 0 locale: weekdayFormatter.locale];

					weekdayFormatter.dateFormat = dateFormat;

					// Set the localized Timespan …

					localizedTimespan = [weekdayFormatter stringFromDate: date];
				}
				else if([calendar isDate: date equalToDate: [calendar dateByAddingUnit: NSCalendarUnitWeekOfYear value: -1 toDate: now options: 0] toUnitGranularity: NSCalendarUnitWeekOfYear]) // Last Week …
				{
					localizedTimespan = [CCBundle getLocalizedStringForKey: @"CCLastPlayedLastWeek"];
				}
				else if([calendar isDate: date equalToDate: [calendar dateByAddingUnit: NSCalendarUnitWeekOfYear value: -2 toDate: now options: 0] toUnitGranularity: NSCalendarUnitWeekOfYear]) // Last two Weeks …
				{
					localizedTimespan = [CCBundle getLocalizedStringForKey: @"CCLastPlayedLastTwoWeeks"];
				}
				else if(elapsed.year >= 3) // A very long Time ago …
				{
					localizedTimespan = [CCBundle getLocalizedStringForKey: @"CCLastPlayedLongTime"];
				}
				else if(elapsed.year >= 2) // Two Years ago …
				{
					localizedTimespan = [CCBundle getLocalizedStringForKey: @"CCLastPlayedTwoYears"];
				}
				else if(elapsed.year >= 1) // One Year ago …
				{
					localizedTimespan = [CCBundle getLocalizedStringForKey: @"CCLastPlayedOneYear"];
				}
				else if(elapsed.month >= 6) // Six Months ago …
				{
					localizedTimespan = [CCBundle getLocalizedStringForKey: @"CCLastPlayedSixMonths"];
				}
				else if(elapsed.month >= 3) // Three Months ago …
				{
					localizedTimespan = [CCBundle getLocalizedStringForKey: @"CCLastPlayedThreeMonths"];
				}
				else if(elapsed.month >= 1) // One Month ago …
				{
					localizedTimespan = [CCBundle getLocalizedStringForKey: @"CCLastPlayedOneMonth"];
				}
				else
				{
					localizedTimespan = [CCBundle getLocalizedStringForKey: @"CCLastPlayedThreeWeeks"];
				}

				// Set the last remaining Album Information …

				bottomLabelText = [NSString stringWithFormat: @"%@ %@", localizedPrefix, localizedTimespan];
			}
			else // Default Fallback to Album and Artist …
			{
				topLabelText = representativeItem.albumTitle;
				bottomLabelText = representativeItem.albumArtist;
			}

			// If Debug Logging is active, …

			if([CC_PREFS_VALUE_FOR_KEY(CCPrefsDebugLoggingKey) boolValue])
			{
				// … get the `albumPersistentID` of the current Album, …

				MPMediaEntityPersistentID albumPersistentID = [representativeItem albumPersistentID];

				// … check if we don't use a special Sort Order ( Genre or by Date ), …

				BOOL requiresNoSpecialSortOrder = (self -> _sortMethod == CCSortMethodAlbum || self -> _sortMethod == CCSortMethodAlbumArtist || self -> _sortMethod == CCSortMethodArtist || self -> _sortMethod == CCSortMethodRandom);

				// … and add the `albumPersistentID` to the End of the Album Name.

				if(requiresNoSpecialSortOrder)
				{
					bottomLabelText = [NSString stringWithFormat: @"%@, ID: %llu", bottomLabelText, albumPersistentID];
				}
				else
				{
					topLabelText = [NSString stringWithFormat: @"%@, ID: %llu", topLabelText, albumPersistentID];
				}
			}

			// Set Label's Text Property …

			self.topLabel.text = topLabelText;
			self.bottomLabel.text = bottomLabelText;
		}

		- (void)surpriseMe: (UILongPressGestureRecognizer *)recognizer
		{
			// React only once per Press …

			if(recognizer.state != UIGestureRecognizerStateBegan)
			{
				return;
			}

			NSInteger count = self -> _albums.count;

			// Nothing to pick, or an Album Detail View is currently open ( the Carousel is locked then ) …

			if(count == 0 || self -> _albumDetailVisible)
			{
				return;
			}

			NSInteger currentIndex = MAX(self.carouselView.currentItemIndex, 0);
			NSInteger randomIndex = currentIndex;

			// Pick a random Album, but never the current One ( pick from `count - 1` and skip over the current Index ) …

			if(count > 1)
			{
				randomIndex = (NSInteger)arc4random_uniform((uint32_t)(count - 1));

				if(randomIndex >= currentIndex)
				{
					randomIndex++;
				}
			}

			MPMediaItemCollection *collection = self -> _albums[randomIndex];

			// Reading Shuffle-Mode can block on IPC with `mediaserverd`, so we always fetch it on our Control Queue, off the Main Thread …

			dispatch_async(CCControlQueue, ^
			{
				// Remember the User's Shuffle-Preference, so we can restore it once our Selection has "taken" …

				MPMusicShuffleMode previousShuffleMode = self.musicPlayer.shuffleMode;

				// Shuffle re-orders the Queue as soon as it's set, which makes `setNowPlayingItem:` unreliable, so we disable it just long enough to pin Playback to the tapped Item …

				[self.musicPlayer setShuffleMode: MPMusicShuffleModeOff];

				// Set the Item Collection for the Queue ( simply a new Playlist ), …

				[self.musicPlayer setQueueWithItemCollection: collection];

				// … let the Music Play, …

				[self.musicPlayer play];

				// … send haptic Feedback …

				[MTCoreHaptic triggerFeedbackWithPreference: MTCoreHapticFeedbackStyleMedium];

				// … and restore Shuffle shortly after Playback has started, once the correct Item is locked in. A short Delay avoids a Race with `play` re-picking an Item …

				dispatch_time_t safeDispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CCIntervalSafeDispatchTime * NSEC_PER_SEC));

				dispatch_after(safeDispatchTime, CCControlQueue, ^(void)
				{
					[self.musicPlayer setShuffleMode: previousShuffleMode];
				});
			});

			// Only one Album: There's nothing to scroll to, so flip the Card right away …

			if(randomIndex == currentIndex)
			{
				[self flipItemAtIndex: randomIndex inCarousel: self.carouselView];

				return;
			}

			// … otherwise let iCarousel spin there with a custom Duration. `carouselDidEndScrollingAnimation:` flips the Card as soon as it landed.

			self -> _pendingFlipIndex = randomIndex;

			CGFloat duration = ((MAX(currentIndex, randomIndex) - MIN(currentIndex, randomIndex)) * CCDurationOneEighth) + CCDurationShuffle;

			[self.carouselView scrollToItemAtIndex: randomIndex duration: duration];
		}

		- (void)updatePlaybackControls
		{
			[self updatePlaybackControlsAnimated: YES];
		}

		- (void)updatePlaybackControlsAnimated: (BOOL)animated
		{
			// Reading Playback-State, Repeat- and Shuffle-Mode can block on IPC with `mediaserverd`, so we always fetch them on our Control Queue, off the Main Thread …

			dispatch_async(CCControlQueue, ^
			{
				// Get the current State of the System Music Player …

				MPMusicPlayerController *musicPlayer = [MPMusicPlayerController systemMusicPlayer];

				// Get the current Playback-State, Repeat- and Shuffle-Mode …

				MPMusicPlaybackState playbackState = musicPlayer.playbackState;
				MPMusicRepeatMode repeatMode = musicPlayer.repeatMode;
				MPMusicShuffleMode shuffleMode = musicPlayer.shuffleMode;

				// Get the current now playing Item …

				MPMediaItem *nowPlayingItem = musicPlayer.nowPlayingItem;

				// Let's get back to the Main Thread …

				dispatch_async(dispatch_get_main_queue(), ^
				{
					// Based on the current Playback-State …

					UIImage *playbackImage = (playbackState == MPMusicPlaybackStatePlaying) ? self -> _pauseImage : self -> _playImage;

					// … set the Image.

					[self.playPauseButton setImage: playbackImage forState: UIControlStateNormal];

					// Check if we should Repeat All or only one Song …

					BOOL repeatAllActive = repeatMode == MPMusicRepeatModeAll;
					BOOL repeatOneActive = repeatMode == MPMusicRepeatModeOne;

					// And now let's to the same for the Shuffle-Button: Check if we should Shuffle Albums or Songs …

					BOOL shuffleActive = shuffleMode == MPMusicShuffleModeAlbums || shuffleMode == MPMusicShuffleModeSongs;

					// Repeat can be changed outside of ClassicCover, too, so sync the Icon with the Player, before the Button fades in …

					if(self -> _albumDetailVisible)
					{
						// … based on this Knowlegde, set the Image.

						UIImage *repeatImage = repeatOneActive ? self -> _repeatOneImage : self -> _repeatImage;

						[self.repeatButton setImage: repeatImage forState: UIControlStateNormal];
					}

					void (^setAlpha)(void) = ^
					{
						// The Values were already fetched off the Main Thread above, so this is a plain, synchronous Assignment …

						BOOL itemExistsAndFlipIsVisible = nowPlayingItem && self -> _albumDetailVisible;

						// The Buttons for the Album Detail View only fade with the Interface, while it is shown …

						self.previousTrackButton.alpha = itemExistsAndFlipIsVisible ? 1.0 : 0.0;
						self.nextTrackButton.alpha = itemExistsAndFlipIsVisible ? 1.0 : 0.0;

						// Set the Alpha-Value of the Buttons …

						self.repeatButton.alpha = itemExistsAndFlipIsVisible ? ((repeatAllActive || repeatOneActive) ? CCButtonBackgroundAlphaActive : CCButtonBackgroundAlphaInactive) : 0.0;
						self.shuffleButton.alpha = itemExistsAndFlipIsVisible ? (shuffleActive ? CCButtonBackgroundAlphaActive : CCButtonBackgroundAlphaInactive) : 0.0;
					};

					// Last - but not least - animate the View … or not.

					if(animated)
					{
						// If we have a now playing Item …

						if(nowPlayingItem)
						{
							// Be sure, that the Frames of our Buttons are up to date, before we read them …

							[self.view layoutIfNeeded];

							CGFloat previousButtonMinX = CGRectGetMinX(self.previousTrackButton.frame);
							CGFloat previousButtonMaxX = CGRectGetMaxX(self.previousTrackButton.frame);

							CGFloat playPauseWidth = CGRectGetWidth(self.playPauseButton.bounds);

							// The Play/Pause-Button slides to the Right and leaves it's Place to the Previous-Button - and slides back, as soon as the Album Detail View is hidden again …

							self.playPauseLeadingConstraint.constant = self -> _albumDetailVisible ? (previousButtonMaxX + CCButtonSpacing) : previousButtonMinX;
							self.nextTrackLeadingConstraint.constant = self -> _albumDetailVisible ? (previousButtonMaxX + playPauseWidth + (CCButtonSpacing * 2)) : previousButtonMinX;
						}

						// Set the Animation Curve …

						UIViewAnimationOptions animationCurve = self -> _albumDetailVisible ? UIViewAnimationOptionCurveEaseOut : UIViewAnimationOptionCurveEaseIn;

						// We use the same Duration and Curve as the Flip itself, so both Animations run in Sync …

						[UIView animateWithDuration: CCDurationHalf delay: 0.0 options: (animationCurve | UIViewAnimationOptionBeginFromCurrentState) animations: ^
						{
							setAlpha();

							// Lay out the Sub-Views immediately, if Layout Updates are pending …

							[self.view layoutIfNeeded];
						} completion: nil];
					}
					else
					{
						setAlpha();
					}
				});
			});
		}

	#pragma mark -
	#pragma mark Demo-Loop

		- (void)beginPresentationMode
		{
			// If Demo-Loop isn't enabled, or we don't have any Album in the Music Library, leave here …

			if(self -> _demoRunning || ![self isInterfaceActive] || !self -> _demoEnabled || self -> _albums.count == 0)
			{
				return;
			}

			// … otherwise indicate, that our Demo-Loop is running, …

			self -> _demoRunning = YES;

			// … reset the last Direction we jumped to …

			self -> _demoLastDirection = CCJumpDirectionNone;

			// … and a new Generation kills every older Chain.

			[self scheduleNextPresentationStep: ++self -> _demoGeneration];
		}

		- (void)endPresentationMode
		{
			// If Demo-Loop isn't running, leave here …

			if(!self -> _demoRunning)
			{
				return;
			}

			// … otherwise stop the Demo-Loop …

			self -> _demoRunning = NO;
			self -> _demoGeneration++;

			// … and flip the Card only after the User's own Scroll …

			self -> _pendingFlipIndex = NSNotFound;
		}

		- (BOOL)gestureRecognizer: (UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch: (UITouch *)touch
		{
			// Stop the Demo-Loop …

			[self endPresentationMode];

			// … and start a new Idle-Countdown.

			[self schedulePresentationRestartAfterIdle];

			// Return `NO` …

			return NO;
		}

		- (void)schedulePresentationRestartAfterIdle
		{
			// If Demo-Loop isn't enabled anymore, leave here …

			if(![self isInterfaceActive] || !self -> _demoEnabled)
			{
				return;
			}

			// Every Call invalidates the previous Countdown …

			NSUInteger idleGeneration = ++self -> _demoIdleGeneration;

			// Let's start the Demo-Loop again, after 60 Seconds …

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CCDurationDemoInactivity * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
			{
				// … but only, if we're still Idle …

				BOOL stillIdle = (idleGeneration == self -> _demoIdleGeneration);

				// … and Demo-Loop is enabled, not running and no Detail View is flipped, because of someone is reading a Track List …

				if(stillIdle && self -> _demoEnabled && !self -> _demoRunning && !self -> _albumDetailVisible)
				{
					[self beginPresentationMode];
				}
			});
		}

		- (void)scheduleNextPresentationStep: (NSUInteger)generation
		{
			// Let's get a random Delay, …

			CGFloat delay = CCDurationDemoDelayMinimum + (((double)arc4random() / UINT32_MAX) * (CCDurationDemoDelayMaximum - CCDurationDemoDelayMinimum));

			// … after which the Presentation-Step will start …

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
			{
				// If the Demo-Loop isn't running or we don't have a new Presentation-Step, leave here …

				if(![self isInterfaceActive] || !self -> _demoRunning || generation != self -> _demoGeneration)
				{
					return;
				}

				NSInteger count = self -> _albums.count;

				// Nothing to pick, so leave here …

				if(count == 0)
				{
					return;
				}

				NSInteger currentIndex = MAX(self.carouselView.currentItemIndex, 0);

				// If the current Cover is flipped, …

				if(self -> _albumDetailVisible)
				{
					CCAlbumArtView *card = (CCAlbumArtView *)[self.carouselView itemViewAtIndex: currentIndex];

					// … flip it back, …

					[card flip: NO];

					// … schedule the next Presentation-Step …

					[self scheduleNextPresentationStep: generation];

					// … and leave here.

					return;
				}

				// Pick a random Album within a Range of max. 14 Covers around the current ( but never that ) One ( pick from `count - 1` and skip over the current Index ) …

				NSInteger randomIndex = currentIndex;

				if(count > 1)
				{
					NSInteger backReach = CCDemoJumpValueMinimum;
					NSInteger forwardReach = CCDemoJumpValueMinimum;

					// If we went back before, the Way forward gets the longer Reach, and the other Way round …

					if(self -> _demoLastDirection == CCJumpDirectionBack)
					{
						forwardReach = CCDemoJumpValueMaximum;
					}
					else if(self -> _demoLastDirection == CCJumpDirectionForward)
					{
						backReach = CCDemoJumpValueMaximum;
					}

					NSInteger lowerBound = MAX(currentIndex - backReach, 0);
					NSInteger upperBound = MIN(currentIndex + forwardReach, count - 1);

					// Number of Candidates, without the current Cover …

					uint32_t candidates = (uint32_t)(upperBound - lowerBound);

					randomIndex = lowerBound + (NSInteger)arc4random_uniform(candidates);

					// … and skip over the current Index.

					if(randomIndex >= currentIndex)
					{
						randomIndex++;
					}

					// Remember the Direction for the next Step …

					self -> _demoLastDirection = (randomIndex > currentIndex) ? CCJumpDirectionForward : CCJumpDirectionBack;
				}

				// In 14% it's possible, that the Cover will be flipped …

				if(arc4random_uniform(100) < CCDemoFlipViewChance)
				{
					self -> _pendingFlipIndex = randomIndex;
				}

				// Let iCarousel spin there with a custom Duration …

				CGFloat duration = ((MAX(currentIndex, randomIndex) - MIN(currentIndex, randomIndex)) * CCDurationOneQuarter) + CCDurationShuffle;

				[self.carouselView scrollToItemAtIndex: randomIndex duration: duration];

				// … but let's wait, until iCarousel reached the final Index, …

				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
				{
					// … if the Demo-Loop is still running and we don't have a new Presentation-Step …

					if(self -> _demoRunning && generation == self -> _demoGeneration)
					{
						// … do the next One.

						[self scheduleNextPresentationStep: generation];
					}
				});
			});
		}

	#pragma mark -
	#pragma mark Private Methods

		- (void)applyPreferencesIfNeeded
		{
			// Get the preferred Style for our Background …

			self -> _backgroundStyle = [CC_PREFS_VALUE_FOR_KEY(CCPrefsBackgroundStyleKey) integerValue];

			// If the Preferences have changed …

			if(CCPreferencesHaveChanged)
			{
				// Previous Settings for Artwork Size, Reflection and it's Blur …

				CCArtworkSize previousArtworkSize = self -> _artworkSize;

				BOOL previousReflection = self -> _reflection;
				BOOL previousReflectionBlur = self -> _reflectionBlur;

				// Get the Size of the Artwork …

				self -> _artworkSize = [CC_PREFS_VALUE_FOR_KEY(CCPrefsArtworkSizeKey) integerValue];

				// Should we use Reflections and are they blurred ?

				self -> _reflection = [CC_PREFS_VALUE_FOR_KEY(CCPrefsReflectionKey) boolValue];
				self -> _reflectionBlur = [CC_PREFS_VALUE_FOR_KEY(CCPrefsReflectionBlurKey) boolValue];

				// Should we fade-out the Album Informations automatically ?

				self -> _autoHideLabels = [CC_PREFS_VALUE_FOR_KEY(CCPrefsAutoHideAlbumMetaKey) boolValue];

				// Cached Artworks / Reflections may have been rendered with the old Values, so start with a clean Memory Tier, if necessary …

				if(previousArtworkSize != self -> _artworkSize || previousReflection != self -> _reflection || previousReflectionBlur != self -> _reflectionBlur)
				{
					[[CCArtworkCache sharedCache] clearMemoryCache];
				}

				// Determine, if we're running on an iPad …

				BOOL isiPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;

				// If we're running on an iPad …

				if(isiPad)
				{
					// Determine, if we should we use the Demo-Loop ?

					self -> _demoEnabled = [CC_PREFS_VALUE_FOR_KEY(CCPrefsDemoEnabledKey) boolValue];

					// And prevent the Display from going to Sleep ?

					self -> _preventSleep = [CC_PREFS_VALUE_FOR_KEY(CCPrefsPreventSleepKey) boolValue];

					// Set the Idle-Timer's new Preference, while ClassicCover's View is visible …

					[self caffeinate: self -> _preventSleep];
				}
				else
				{
					// … otherwise we use a slightly different Size for our Album Artworks here.

					self -> _cardUnit = (((self -> _screenWidth > self -> _screenHeight) ? self -> _screenHeight : self -> _screenWidth) / 10.0) * (7 - self -> _artworkSize);
				}

				// Set the Background, by respecting the chosen Preference …

				switch(self -> _backgroundStyle)
				{
					case CCBackgroundStyleColorPlain:
					{
						self.backgroundWallpaper.backgroundColor = [UIColor colorWithCSS: CC_PREFS_VALUE_FOR_KEY(CCPrefsBackgroundColorKey)]; break;
					}
					case CCBackgroundStyleColorRandom: break;
					case CCBackgroundStyleColorAlbum:
					{
						self -> _averageColorCache = [NSMutableDictionary dictionary];

						self.backgroundWallpaper.backgroundColor = [UIColor blackColor];

						break;
					}
					case CCBackgroundStylePhoto:
					case CCBackgroundStylePhotoBlur:
					case CCBackgroundStyleWallpaperBlur:
					{
						// Show a neutral Placeholder immediately …

						self.backgroundWallpaper.backgroundColor = [UIColor blackColor];

						// Get the Background Style …

						CCBackgroundStyle backgroundStyle = self -> _backgroundStyle;

						// Get the Radius for the Blur, which will be applied on the Image …

						CGFloat backgroundBlurRadius = MAX((self -> _screenHeight / CCBackgroundBlurMultiplier), CCBackgroundBlurMinimum);

						// Sourcing this Background. Raw Disk I/O, plus an undocumented, private Decode Call for the SpringBoard Wallpaper Case and, worse, running a Gaussian Blur over a full-Screen Image, are both far too slow to do synchronously here, before the View has even appeared. Do it on a Background Queue instead, and hand the Result back once it's ready …

						dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^
						{
							UIImage *backgroundImage = (backgroundStyle == CCBackgroundStyleWallpaperBlur) ? [self getSpringBoardBackground] : [UIImage imageWithContentsOfFile: CCFileManagerCacheBackground];

							UIImage *processedImage;
							UIColor *processedColor;

							if(backgroundImage)
							{
								if(backgroundStyle == CCBackgroundStylePhoto)
								{
									processedImage = [backgroundImage colorizeWithColor: [UIColor colorWithWhite: 0.0 alpha: CCBackgroundDarkeningAlphaHalf]];
								}
								else
								{
									processedImage = [[backgroundImage blurredImageWithRadius: backgroundBlurRadius] colorizeWithColor: [UIColor colorWithWhite: 0.0 alpha: CCBackgroundDarkeningAlphaHalf]];
								}

								processedColor = [processedImage averageColor];
							}

							// Let's get back to the Main Thread …

							dispatch_async(dispatch_get_main_queue(), ^
							{
								if(processedImage)
								{
									self.backgroundWallpaper.image = processedImage;
									self.backgroundWallpaper.backgroundColor = processedColor;

									self.view.backgroundColor = processedColor;
								}
							});
						});

						break;
					}
					default:
					{
						self.backgroundWallpaper.backgroundColor = [UIColor blackColor]; break;
					}
				}

				// Nothing has changed …

				CCPreferencesHaveChanged = NO;

				// The Labels may be faded out right now, or the Countdown may be obsolete, …

				if(self.isViewLoaded && self.view.window)
				{
					// … so re-evaluate, if we're on Screen.

					[self showAlbumInfoAndScheduleFadeOut];
				}
			}
			else
			{
				// Let's start with the Demo-Loop, if the User wants it …

				if(self -> _demoEnabled)
				{
					[self schedulePresentationRestartAfterIdle];
				}
			}

			// Reload our Albums, if needed …

			[self reloadAlbumsIfNeeded];

			// If we're using a random Color for the Background, apply them …

			if(self -> _backgroundStyle == CCBackgroundStyleColorRandom)
			{
				self.backgroundWallpaper.backgroundColor = [UIColor randomColor];
			}
		}

		- (UIColor *)averageColorForAlbumAtIndex: (NSInteger)index
		{
			if(self -> _albums.count == 0)
			{
				// Return `nil`, if Album's Artwork hasn't finished loading yet …

				return nil;
			}

			// Looks up the cached Average Color for the Album, clamped to valid Bounds …

			NSInteger clampedIndex = MAX(0, MIN(index, (NSInteger)self -> _albums.count - 1));

			MPMediaEntityPersistentID albumPersistentID = [self -> _albumIdentifiers[clampedIndex] unsignedLongLongValue];

			return self -> _averageColorCache[@(albumPersistentID)];
		}

		- (UIColor *)blendedColorFrom: (UIColor *)fromColor to: (UIColor *)toColor fraction: (CGFloat)fraction
		{
			CGFloat fromRed, fromGreen, fromBlue, fromAlpha;
			CGFloat toRed, toGreen, toBlue, toAlpha;

			[fromColor getRed: &fromRed green: &fromGreen blue: &fromBlue alpha: &fromAlpha];
			[toColor getRed: &toRed green: &toGreen blue: &toBlue alpha: &toAlpha];

			return [UIColor colorWithRed: (fromRed + (toRed - fromRed) * fraction) green: (fromGreen + (toGreen - fromGreen) * fraction) blue: (fromBlue + (toBlue - fromBlue) * fraction) alpha: (fromAlpha + (toAlpha - fromAlpha) * fraction)];
		}

		- (void)caffeinate: (BOOL)preventSleep
		{
			// Check, if we're running on an iPad and Low Power Mode is enabled or not, …

			BOOL isiPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
			BOOL isLowPowerModeEnabled = ([[NSProcessInfo processInfo] isLowPowerModeEnabled]);

			// … and based on this Knowledge, prevent the Display from going to Sleep …

			[UIApplication sharedApplication].idleTimerDisabled = [self isInterfaceActive] && isiPad && !isLowPowerModeEnabled && self -> _demoEnabled && preventSleep;
		}

		- (void)cancelAlbumInfoFade
		{
			if(self -> _albumInfoFadeTimer)
			{
				// Cancel our Fade of Album Informations …

				dispatch_source_cancel(self -> _albumInfoFadeTimer);

				// … and reset the Album-Fade-Timer.

				self -> _albumInfoFadeTimer = nil;
			}
		}

		- (BOOL)deviceIsPreA9SoC
		{
			// Check, if we're running on a pre-A9-Device ( iPhone 5S, iPhone 6(+), iPad Air ( 1st & 2n Gen ), iPad mini ( 2nd - 4th Gen. ) and iPod touch 6 ) …

			uint32_t family = 0;
			size_t size = sizeof(family);

			if(sysctlbyname("hw.cpufamily", &family, &size, NULL, 0) != 0)
			{
				return NO; // Unknown CPU-Family -> Assume A9 and above …
			}

			// Return, if we're running on an A7- or A8-Family …

			return (family == CCCPUFamilyAppleA7 || family == CCCPUFamilyAppleA8);
		}

		- (void)flipItemAtIndex: (NSInteger)index inCarousel: (iCarousel *)carousel
		{
			if(index == carousel.currentItemIndex)
			{
				CCAlbumArtView *card = (CCAlbumArtView *)[carousel itemViewAtIndex: index];

				card.delegate = self;

				[card flip: YES];
			}
		}

		- (UIImage *)getSpringBoardBackground
		{
			UIImage *wallpaper;

			// The SpringBoard-Wallpaper is special, so we need a Reference to an immutable Array Object …

			CFArrayRef (*CPBitmapCreateImagesFromData)(CFDataRef, void*, int, void*) = (CFArrayRef (*)(CFDataRef, void*, int, void*)) (dlsym(RTLD_DEFAULT, "CPBitmapCreateImagesFromData"));

			// Let's check, which Wallpaper exists: If you seth the Wallpaper for Home- and Lockscreen, there's only "LockBackground.cpbitmap" available …

			NSFileManager *fileManager = [NSFileManager defaultManager];

			NSString *homescreenFilePath = @"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap";
			NSString *lockscreenFilePath = @"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap";

			if([fileManager fileExistsAtPath: homescreenFilePath])
			{
				// We got the Homescreen-Wallpaper, so now let's get an UIImage from that …

				CFArrayRef someArrayRef = CPBitmapCreateImagesFromData((__bridge CFDataRef)([NSData dataWithContentsOfFile: homescreenFilePath]), NULL, 1, NULL);

				NSArray *array = (__bridge NSArray*)someArrayRef;

				wallpaper = [UIImage imageWithCGImage: (__bridge CGImageRef)(array[0])];
			}
			else if([fileManager fileExistsAtPath: lockscreenFilePath])
			{
				// We got the Lockscreen-Wallpaper, so now let's get an UIImage from that …

				CFArrayRef someArrayRef = CPBitmapCreateImagesFromData((__bridge CFDataRef)([NSData dataWithContentsOfFile: lockscreenFilePath]), NULL, 1, NULL);

				NSArray *array = (__bridge NSArray*)someArrayRef;

				wallpaper = [UIImage imageWithCGImage: (__bridge CGImageRef)(array[0])];
			}

			CFRelease(CPBitmapCreateImagesFromData);

			return wallpaper;
		}

		- (BOOL)isInterfaceActive
		{
			return self -> _interfaceVisible && [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
		}

		- (void)reloadAlbumsIfNeeded
		{
			// Get the previous Media Collection that matches Music Items and that groups and sorts Collections by Album Name, …

			NSArray<MPMediaItemCollection *> *previousAlbums = self -> _albums;

			// … the previous Persistent IDs, …

			NSArray<NSNumber *> *previousIdentifiers = self -> _albumIdentifiers;

			// … the previous Sort Method …

			NSInteger previousSortMethod = self -> _sortMethod;

			// … and the previous Library Date.

			NSDate *previousLibraryDate = self -> _albumsLibraryDate;

			// Load the Album-Collection asynchronously …

			dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^
			{
				// Get the Sort-Method for Albums …

				NSInteger sortMethod = [CC_PREFS_VALUE_FOR_KEY(CCPrefsSortMethodKey) intValue];

				// Do a Compatibility-Check at First: If we're running iOS 10 and above, we can use the Sort Method "Date Added" …

				if(@available(iOS 10, *))
				{
					// … and there's nothing to Change here …
				}
				else
				{
					// … but if we're running iOS 9, we can't use the new Sort Method …

					if(sortMethod == CCSortMethodDateAddedAscending || sortMethod == CCSortMethodDateAddedDescending)
					{
						// … and fall back to Album Artist ( Default Value ).

						sortMethod = CCSortMethodAlbumArtist;
					}
				}

				// Set the Libraries last Modification Date ( available on iOS 9.3 and later; older Versions simply never reuse ) …

				NSDate *libraryDate = nil;

				if([[MPMediaLibrary defaultMediaLibrary] respondsToSelector: @selector(lastModifiedDate)])
				{
					libraryDate = [MPMediaLibrary defaultMediaLibrary].lastModifiedDate;
				}

				// Neither the Sort Method nor the Library changed: The previous Result is still valid …

				BOOL canAlbumsReused = (previousAlbums.count > 0 && sortMethod != CCSortMethodRandom && sortMethod == previousSortMethod && libraryDate && [libraryDate isEqualToDate: previousLibraryDate]);

				// The Album-Array …

				NSArray<MPMediaItemCollection *> *albums;

				// The Array of Persistent IDs …

				NSArray<NSNumber *> *albumIdentifiers = previousIdentifiers;

				// If we can re-use the Album Collection, …

				if(canAlbumsReused)
				{
					// … use the previous Album Collection.

					albums = previousAlbums;
				}
				else
				{
					// The Media Collection that matches Music Items and that groups and sorts Collections by Album Name …

					NSArray<MPMediaItemCollection *> *mediaAlbumCollections = [[MPMediaQuery albumsQuery] collections];

					// That's an interesting Part: We do the Query for our iCarousel, by respecting the Sort-Order-Preference …

					if(sortMethod == CCSortMethodRandom)
					{
						// Let's sort the Albums random, …

						NSMutableArray<MPMediaItemCollection *> *shuffledAlbums = [mediaAlbumCollections mutableCopy];

						// … by using Fisher-Yates-Algorithm …

						for(NSUInteger index = shuffledAlbums.count; index > 1; index--)
						{
							NSUInteger randomIndex = arc4random_uniform((uint32_t)index);

							[shuffledAlbums exchangeObjectAtIndex: index - 1 withObjectAtIndex: randomIndex];
						}

						// … and return the shuffled Array.

						albums = [shuffledAlbums copy];
					}
					else
					{
						// Should we sort by Date ?

						BOOL isDateSort = (sortMethod == CCSortMethodDateAddedAscending || sortMethod == CCSortMethodDateAddedDescending || sortMethod == CCSortMethodLastPlayedDateAscending || sortMethod == CCSortMethodLastPlayedDateDescending);

						// The "Ascending" Variants put the newest Date first and never-played / unknown Dates at the Bottom …

						BOOL newestFirst = (sortMethod == CCSortMethodDateAddedAscending || sortMethod == CCSortMethodLastPlayedDateAscending);

						// We want to sort the Albums by Metadata …

						albums = [mediaAlbumCollections sortedArrayUsingComparator: ^NSComparisonResult(MPMediaItemCollection* collectionOne, MPMediaItemCollection* collectionTwo)
						{
							// On a big Library, `representativeItem` and the Property Getters create many autoreleased Objects, and they all stay alive until the Background Block ends. That causes a Memory Spike, and Music is under Jetsam Pressure …

							@autoreleasepool
							{
								MPMediaItem *itemOne = [collectionOne representativeItem];
								MPMediaItem *itemTwo = [collectionTwo representativeItem];

								if(sortMethod == CCSortMethodAlbum)
								{
									return [itemOne.albumTitle localizedStandardCompare: itemTwo.albumTitle];
								}
								else if(sortMethod == CCSortMethodArtist)
								{
									return [itemOne.artist localizedStandardCompare: itemTwo.artist];
								}
								else if(sortMethod == CCSortMethodGenre)
								{
									return [itemOne.genre localizedStandardCompare: itemTwo.genre];
								}
								else if(isDateSort)
								{
									NSDate *dateOne;
									NSDate *dateTwo;

									// We can fetch the Date, where an Item was added to the Library, …

									if(sortMethod == CCSortMethodDateAddedAscending || sortMethod == CCSortMethodDateAddedDescending)
									{
										// … but only if we're running iOS 10 and above.

										if(@available(iOS 10, *))
										{
											dateOne = itemOne.dateAdded;
											dateTwo = itemTwo.dateAdded;
										}
									}
									else
									{
										// … but if we're using the last played Date, get these Dates instead.

										dateOne = itemOne.lastPlayedDate;
										dateTwo = itemTwo.lastPlayedDate;
									}

									// Let's do the Order-Magic …

									if(!dateOne && !dateTwo) { return NSOrderedSame; }

									if(newestFirst)
									{
										if(!dateOne) { return NSOrderedDescending; } // Never-played sinks to Bottom …
										if(!dateTwo) { return NSOrderedAscending; }

										return [dateTwo compare: dateOne];
									}
									else
									{
										if(!dateOne) { return NSOrderedAscending; } // Never-played raises to Top …
										if(!dateTwo) { return NSOrderedDescending; }

										return [dateOne compare: dateTwo];
									}
								}
								else // Default Fallback to Album Artist …
								{
									return [itemOne.albumArtist localizedStandardCompare: itemTwo.albumArtist];
								}
							}
						}];

						// Let's get the Persistent ID for each Album …

						NSMutableArray<NSNumber *> *identifiers = [NSMutableArray arrayWithCapacity: albums.count];

						for(MPMediaItemCollection *album in albums)
						{
							[identifiers addObject: @([album.representativeItem albumPersistentID])];
						}

						albumIdentifiers = [identifiers copy];
					}
				}

				// Let's get back to the Main Thread …

				dispatch_async(dispatch_get_main_queue(), ^
				{
					self -> _sortMethod = sortMethod;

					self -> _albums = albums;
					self -> _albumIdentifiers = [albumIdentifiers copy];
					self -> _albumsLibraryDate = libraryDate;

					// Initialize the iCarousel-View …

					[self.carouselView setType: [CC_PREFS_VALUE_FOR_KEY(CCPrefsCoverStyleKey) integerValue]];

					// If we can't re-use the Album Collection, …

					if(!canAlbumsReused)
					{
						// … a flipped Card doesn't survive the Reload, so reset the Interface first …

						[self resetAlbumDetailState];

						// … and reload iCarousel View's Data.

						[self.carouselView reloadData];
					}

					// If we have at least one Album …

					if(self -> _albums.count > 0)
					{
						// Get the current Index …

						NSInteger currentIndex = (self.carouselView.currentItemIndex >= 0) ? self.carouselView.currentItemIndex : 0;

						// … and set the Album Information.

						[self setAlbumInformations: self -> _albums[currentIndex].representativeItem];
					}

					// Let's start with the Demo-Loop, if the User wants it …

					if([self isInterfaceActive] && self -> _demoEnabled && !canAlbumsReused)
					{
						[self beginPresentationMode];
					}
				});
			});
		}

		- (void)resumeClassicCover
		{
			// Check, if our Interface is active …

			if([self isInterfaceActive])
			{
				// … and if we don't generate Playback Notifications …

				if(!self -> _playbackNotificationsActive)
				{
					// … we have to change this.

					self -> _playbackNotificationsActive = YES;

					// Get the default Notification Center, …

					NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

					// … so we can react on Playback-State- and Now-Playing-Item-Changes …

					[center addObserver: self selector: @selector(updatePlaybackControls) name: MPMusicPlayerControllerPlaybackStateDidChangeNotification object: nil];
					[center addObserver: self selector: @selector(updatePlaybackControls) name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification object: nil];

					// … and start the Generation of Playback Notifications too.

					[self.musicPlayer beginGeneratingPlaybackNotifications];
				}

				// If our Detail View is visible …

				if(self -> _albumDetailVisible)
				{
					CCAlbumArtView *card = (CCAlbumArtView *)self.carouselView.currentItemView;

					// Observe the Changes here too …

					[card.flipViewController beginObservingNowPlayingChanges];
					[card.flipViewController updateNowPlayingIndicator];
				}

				// Should we prevent Display Sleep ?

				[self caffeinate: self -> _preventSleep];

				// Update our Playback Controls without Animation  …

				[self updatePlaybackControlsAnimated: NO];

				// The Host sets it's visible Alpha after forwarding Appearance-Callbacks …

				dispatch_async(dispatch_get_main_queue(), ^
				{
					if([self isInterfaceActive])
					{
						[self setAnimationStateInView: self.view suspended: NO];
					}
				});
			}
		}

		- (void)setAnimationStateInView: (UIView *)view suspended: (BOOL)suspended
		{
			// Set the new State for our Now-Playing-Indicator …

			if([view isKindOfClass: [CCNowPlayingIndicatorView class]])
			{
				[(CCNowPlayingIndicatorView *)view setAnimationSuspended: suspended];
			}

			// Iterate through the Sub-Views and suspend or resume them too …

			for(UIView *subview in view.subviews)
			{
				[self setAnimationStateInView: subview suspended: suspended];
			}
		}

		- (void)setInterfaceAlpha: (CGFloat)alpha delay: (NSTimeInterval)delay
		{
			void (^setAlpha)(void) = ^
			{
				self.backgroundWallpaper.alpha = alpha;
				self.overlayView.alpha = alpha;
				self.carouselView.alpha = alpha;

				self.playPauseButton.alpha = alpha;

				CGFloat detailViewAlpha = self -> _albumDetailVisible ? alpha : 0.0;

				// The Buttons for the Album Detail View only fade with the Interface, while it is shown …

				self.previousTrackButton.alpha = detailViewAlpha;
				self.nextTrackButton.alpha = detailViewAlpha;

				// Keep the Information Labels hidden while the preserved Album Detail View is shown …

				CGFloat albumInfoAlpha = self -> _albumDetailVisible ? 0.0 : alpha;

				// Set the Alpha for the Information Labels …

				self.topLabel.alpha = albumInfoAlpha;
				self.bottomLabel.alpha = albumInfoAlpha;

				// Update our Playback Controls without being Part of this Animation …

				[UIView performWithoutAnimation: ^
				{
					[self updatePlaybackControlsAnimated: NO];
				}];
			};

			[UIView animateWithDuration: CCDurationHalf delay: delay options: UIViewAnimationOptionCurveLinear animations: setAlpha completion: nil];
		}

		- (void)showAlbumInfoAndScheduleFadeOut
		{
			// Invalidates every pending Fade-Out …

			NSUInteger generation = ++(self -> _albumInfoFadeGeneration);

			// Cancels a pending Fade-Out …

			[self cancelAlbumInfoFade];

			// If the Interface is active …

			if([self isInterfaceActive])
			{
				// The Album Detail View covers the Labels, so they stay hidden until the Un-Flip …

				if(self -> _albumDetailVisible)
				{
					return;
				}

				// Back from a Flip or a Fade-Out: Un-Hide the Labels …

				self.topLabel.hidden = NO;
				self.bottomLabel.hidden = NO;

				// … and let the Text start at its Home Position again, instead of somewhere in the Middle of a Scroll …

				BOOL restartLabels = self -> _albumInfoFadedOut;

				self -> _albumInfoFadedOut = NO;

				[UIView animateWithDuration: CCDurationHalf delay: 0.0 options: UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut animations: ^
				{
					self.topLabel.alpha = 1.0;
					self.bottomLabel.alpha = 1.0;
				} completion: nil];

				// Alpha now reflects the visible State: A Restart before this would correctly be rejected by the Marquee Label's Visibility-Check …

				if(restartLabels)
				{
					[self.topLabel restartLabel];
					[self.bottomLabel restartLabel];
				}

				// The User want the Labels to fade-out …

				if(self -> _autoHideLabels)
				{
					// … after 5 Seconds without Activity …

					__weak CCViewController *weakSelf = self;

					// Create a new Dispatch Source to monitor low-level System Events …

					self -> _albumInfoFadeTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());

					// Set a Start Time, Interval, and leeway Value for our Album Informations Fade …

					dispatch_source_set_timer(self -> _albumInfoFadeTimer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CCIntervalAlbumInfoInactivity * NSEC_PER_SEC)), DISPATCH_TIME_FOREVER, (uint64_t)(0.1 * NSEC_PER_SEC));

					// Set the Event-Handler-Block for the given Dispatch Source …

					dispatch_source_set_event_handler(self -> _albumInfoFadeTimer, ^
					{
						CCViewController *strongSelf = weakSelf;

						if(strongSelf && strongSelf -> _albumInfoFadeGeneration == generation)
						{
							// Cancels a pending Fade-Out …

							[strongSelf cancelAlbumInfoFade];
						}

						if([strongSelf isInterfaceActive] && strongSelf -> _albumInfoFadeGeneration == generation && !strongSelf -> _albumDetailVisible)
						{
							[UIView animateWithDuration: CCDurationNormal delay: 0.0 options: UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn animations: ^
							{
								strongSelf.topLabel.alpha = 0.0;
								strongSelf.bottomLabel.alpha = 0.0;
							}
							completion: ^(BOOL finished)
							{
								// Only if the Fade-Out ran through and nothing interrupted it ( Touch, new Album, Flip ) …

								if(finished && strongSelf -> _albumInfoFadeGeneration == generation)
								{
									strongSelf -> _albumInfoFadedOut = YES;

									// … stop the invisible Scrolling, which only costs CPU / Battery.

									[strongSelf.topLabel shutdownLabel];
									[strongSelf.bottomLabel shutdownLabel];
								}
							}];
						}
					});

					// Resumes the Invocation of Block-Objects on a Dispatch-Object …

					dispatch_resume(self -> _albumInfoFadeTimer);
				}
			}
		}

		- (void)suspendClassicCover
		{
			// Stop the Demo-Loop …

			[self endPresentationMode];

			// Set iCarousel's pending Index to a Value indicating that the Index doesn’t exist …

			self -> _pendingFlipIndex = NSNotFound;

			// Stop the Idle-Countdown …

			self -> _demoIdleGeneration++;

			// … and cancel a pending Fade-Out.

			self -> _albumInfoFadeGeneration++;

			[self cancelAlbumInfoFade];

			// Suspend Animations …

			[self setAnimationStateInView: self.view suspended: YES];

			// Allow Display going into Sleep …

			[self caffeinate: NO];

			// Stop observing Playback Changes …

			for(CCAlbumArtView *card in self.carouselView.visibleItemViews)
			{
				[card.flipViewController endObservingNowPlayingChanges];
			}

			if(self -> _playbackNotificationsActive)
			{
				self -> _playbackNotificationsActive = NO;

				NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

				[center removeObserver: self name: MPMusicPlayerControllerPlaybackStateDidChangeNotification object: nil];
				[center removeObserver: self name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification object: nil];

				[self.musicPlayer endGeneratingPlaybackNotifications];
			}
		}

	#pragma mark -
	#pragma mark Navigation

/*
		// In a storyboard-based Application, you will often want to do a little Preparation before Navigation …

		- (void)prepareForSegue: (UIStoryboardSegue *)segue sender: (id)sender
		{
			// Get the new View Controller using `[segue destinationViewController]` and pass the selected Object to the new View Controller.
		}
*/

@end
