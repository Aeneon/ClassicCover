/*
	Preferences.m
	ClassicCoverPrefs

	Created by MacThemes on 11/4/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import <sys/sysctl.h>
#import <sys/utsname.h>

#import <MediaPlayer/MediaPlayer.h>

#import "Preferences.h"

#import "../MTCoreHaptic.h"
#import "../MTCoreLogic.h"

#import "../ClassicCover/iCarousel/iCarousel.h"
#import "../ClassicCover/CCPrefsManager.h"

#import "AutumnBoard/MTTintedListItemsController.h"
#import "AutumnBoard/MTTintedViewController.h"

#import "MTContactCell.h"

// Our Tweak Version …

/*
	Philip David Charles "Phil" Collins ( * 30th January 1951 ), an English Singer, Drummer, Songwriter, Record Producer, and Actor. Known as the Drummer and later Lead Vocalist of Genesis and for his highly successful Career as a Solo Artist. Ohh, and on this Day, 37 Years ago, on 7th November 1989, he released his fourth Studio Album "… But Seriously" featuring Hits like "Another Day in Paradise", "Do You Remember ?", "I Wish It Would Rain Down" and many more. It sold more than 14,800,000 Copies worldwide and was certified with three Gold, 73 Platinum, and one Diamond Record 😲. The Album also brings together the instrumental Track "Saturday Night and Sunday Morning" and "Colors" - the shortest and longest Tracks, respectively, from Collins’ Solo Career - on a single Album …
*/
static NSString * const MTTweakVersion = @"2611 „Collins“";

/*
	Archived Tweak Versions:

	- 2610: Unnamed. Sorry :(.
*/

// Should we give haptic Feedback ( Default: YES ) ?

static BOOL CCPrefsHapticFeedbackValue = YES;

/*
	Preferences …
*/
@implementation ClassicCoverPreferencesListController
{
	// The ClassicCover Preference-Bundle …

	NSBundle *_preferenceBundle;

	// Tracking the Parent View Controller's Visibility …

	BOOL _isParentViewControllerOnScreen;

	// Tracking the State of Icon View's Visibility …

	BOOL _isIconViewVisible;

	// Define our Handlers for the Icon View …

	void (^_iconViewFadeIn)(void);
	void (^_iconViewFadeOut)(void);
	void (^_iconViewFadeOutComplete)(BOOL);

	// The Scroll-Offset ( relative to the Header's Height ) past which the Icon View should show …

	CGFloat _cachedHeaderHeight;

	// Cached References to the Background-Style-dependent Specifiers, kept around even while hidden ( i.e. removed from `_specifiers` ) so we can re-insert them later without reloading "Root.plist" …

	PSSpecifier *_backgroundColorSpecifier;
	PSSpecifier *_backgroundImageSpecifier;

	// Cached References to the Reflection-dependent Specifier, kept around even while hidden ( i.e. removed from `_specifiers` ) so we can re-insert them later without reloading "Root.plist" …

	PSSpecifier *_reflectionBlurSpecifier;

	// Cached References to the "Prevent Display Sleep"-dependent Specifiers, kept around even while hidden ( i.e. removed from `_specifiers` ) so we can re-insert them later without reloading "Root.plist" …

	PSSpecifier *_preventSleepSpecifier;
	PSSpecifier *_preventSleepGroupSpecifier;
}
	// Theming Enginge: AutumnBoard …

	MTAutumnBoard *autumnBoard;

	// The Preference-Specifiers from "Root.plist" …

	- (NSArray *)specifiers
	{
		if(!_specifiers)
		{
			_specifiers = [self loadSpecifiersFromPlistName: @"Root" target: self];

			// Remove unsupported Specifiers …

			[self removeSpecifiersUnsupportedByDevice];

			// Get the "Clean-Up Artworks"-Cell …

			PSSpecifier* cleanUpArtworksSpecifier = [self specifierForID: @"CCCleanUpArtworks"];

			if(cleanUpArtworksSpecifier)
			{
				// … and apply it's current File Count / Size synchronously.

				[self applyArtworkCacheInfoToSpecifier: cleanUpArtworksSpecifier onlyOrphaned: NO];
			}

			// Get the "Clean-Up orphaned Artworks"-Cell …

			PSSpecifier* cleanUpOrphanedArtworksSpecifier = [self specifierForID: @"CCCleanUpOrphanedArtworks"];

			if(cleanUpOrphanedArtworksSpecifier)
			{
				// … and apply it's current File Count / Size synchronously.

				[self applyArtworkCacheInfoToSpecifier: cleanUpOrphanedArtworksSpecifier onlyOrphaned: YES];
			}

			// Get Copyright-Cell, …

			PSSpecifier* copyrightSpecifier = [self specifierForID: @"CCCopyright"];

			if(copyrightSpecifier)
			{
				// … it's Footer Text, …

				NSString* footerText = [copyrightSpecifier propertyForKey: @"footerText"];

				// … replace the Dollar Sign by our Tweak Version …

				footerText = [footerText stringByReplacingOccurrencesOfString: @"$" withString: MTTweakVersion];

				// … and set the new Footer Text.

				[copyrightSpecifier setProperty: footerText forKey: @"footerText"];
			}

			// Get Creators-Cell, …

			PSSpecifier* creatorsSpecifier = [self specifierForID: @"CCCreators"];

			if(creatorsSpecifier)
			{
				// … it's Footer Text, …

				NSString* footerText = [creatorsSpecifier propertyForKey: @"footerText"];

				// … and dedicate the Tweak to Steve Jobs …

				NSDateComponents *today = [[NSCalendar currentCalendar] components: (NSCalendarUnitMonth | NSCalendarUnitDay) fromDate: [NSDate date]];

				/*
					… for the following Dates:

					- ( 1955 ) February 24	: It's Steve's Birthday …
					- ( 2011 ) October 5	: Steve died :'( …
					- ( 2001 ) October 23	: The original iPod Launch …
				*/

				if((today.month == 2 && today.day == 24) || (today.month == 10 && today.day == 5) || (today.month == 10 && today.day == 23))
				{
					footerText = [NSString stringWithFormat: @"%@\n%@", @"Dedicated to Steve Jobs", footerText];
				}

				// … and set the new Footer Text.

				[creatorsSpecifier setProperty: footerText forKey: @"footerText"];
			}

			// Cache the "Background Style"-dependent Specifiers, so once removed from `_specifiers` for Hiding, `specifierForID:` would no longer find them, so we keep our own References …

			self -> _backgroundColorSpecifier = [self specifierForID: @"CCBackgroundColor"];
			self -> _backgroundImageSpecifier = [self specifierForID: @"CCBackgroundImage"];

			// Cache the "Reflection"-dependent Specifier, so once removed from `_specifiers` for Hiding, `specifierForID:` would no longer find them, so we keep our own References …

			self -> _reflectionBlurSpecifier = [self specifierForID: @"CCReflectionBlur"];

			// Cache the "Prevent Display Sleep"-dependent Specifiers, so once removed from `_specifiers` for Hiding, `specifierForID:` would no longer find them, so we keep our own References …

			self -> _preventSleepSpecifier = [self specifierForID: @"CCPreventSleep"];
			self -> _preventSleepGroupSpecifier = [self specifierForID: @"CCPreventSleepGroup"];

			// … and apply the initial Visibility based on the currently saved Preferences. This must mutate `_specifiers` directly rather than going through `- (void)updateBackgroundDependentSpecifiers:` and `- (void)updateReflectionDependentSpecifiers:` …

			[self applyInitialSpecifierVisibility];
		}

		return _specifiers;
	}

	#pragma mark -
	#pragma mark Lifecycle

		- (instancetype)init
		{
			self = [super init];

			if(self)
			{
				// Set the ClassicCover Preference-Bundle …

				self -> _preferenceBundle = [NSBundle bundleForClass: self.class];

				// Header Height isn't known yet …

				self -> _cachedHeaderHeight = -1.0;

				// Allocate and initialize Theming Engine …

				autumnBoard = [MTAutumnBoard sharedInstance];

				// The "Visit Twitter"-Button …

				UIButton *twitterButton = [UIButton buttonWithType: UIButtonTypeCustom];

				twitterButton.frame = CGRectMake(0.0, 0.0, 30.0, 30.0);
				twitterButton.layer.masksToBounds = YES;

				UIImage *imageTwitter = [[UIImage imageNamed: @"twitter.png" inBundle: self -> _preferenceBundle compatibleWithTraitCollection: nil] imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];

				[twitterButton setImage: [imageTwitter imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate] forState: UIControlStateNormal];
				[twitterButton addTarget: self action: @selector(visitTwitter:) forControlEvents: UIControlEventTouchUpInside];

				twitterButton.tintColor = [autumnBoard socialTwitter];

				self.twitterButtonItem = [[UIBarButtonItem alloc] initWithCustomView: twitterButton];

				// The "Visit Website"-Button …

				UIButton *websiteButton = [UIButton buttonWithType: UIButtonTypeCustom];

				websiteButton.frame = CGRectMake(0.0, 0.0, 30.0, 30.0);
				websiteButton.layer.masksToBounds = YES;

				UIImage *imageWebsite = [[UIImage imageNamed: @"website.png" inBundle: self -> _preferenceBundle compatibleWithTraitCollection: nil] imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];

				[websiteButton setImage: [imageWebsite imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate] forState: UIControlStateNormal];
				[websiteButton addTarget: self action: @selector(visitWebsite:) forControlEvents: UIControlEventTouchUpInside];

				websiteButton.tintColor = [autumnBoard socialWebsite];

				self.websiteButtonItem = [[UIBarButtonItem alloc] initWithCustomView: websiteButton];

				// Add the Buttons to the right Side of the Navigation Bar …

				NSArray *rightButtons = @[self.twitterButtonItem, self.websiteButtonItem];

				self.navigationItem.rightBarButtonItems = rightButtons;

				// Create an Image to Display in the Navigation Bar …

				self.iconView = [[UIImageView alloc] initWithFrame: CGRectMake(0.0, 0.0, 29.0, 29.0)];

				self.iconView.alpha = 0.0;
				self.iconView.contentMode = UIViewContentModeScaleAspectFit;
				self.iconView.hidden = YES;
				self.iconView.image = [UIImage imageNamed: @"icon.png" inBundle: self -> _preferenceBundle compatibleWithTraitCollection: nil];

				self.navigationItem.titleView = self.iconView;

				// Create a weak Reference of `self` so we're not ending in a retain Cycle …

				__weak typeof(self) weakSelf = self;

				// Define our Animation Handlers for fading the Icon View in and out …

				self -> _iconViewFadeIn = ^
				{
					weakSelf.iconView.alpha = 1.0;
				};

				self -> _iconViewFadeOut = ^
				{
					weakSelf.iconView.alpha = 0.0;
				};

				// Additionally we need a Completion Handler, which is necessary for hiding the Icon View …

				self -> _iconViewFadeOutComplete = ^(BOOL finished)
				{
					if(finished)
					{
						// Since ARC checks against `nil`, we have to temporarily promote our weak Reference to a strong One …

						typeof(self) strongSelf = weakSelf;

						// … and check if it exists.

						if(strongSelf)
						{
							// Now we can set the Icon View hidden …

							strongSelf.iconView.hidden = YES;

							// … and reset the tracked State.

							strongSelf -> _isIconViewVisible = NO;
						}
					}
				};
			}

			return self;
		}

		- (void)viewDidLoad
		{
			[super viewDidLoad];

			// Create a new Tap Gesture Recognizer, so we can easily hide the Keyboard, if the User taps on a Table Element …

			UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(dismissKeyboard)];

			[self.view addGestureRecognizer: tapGestureRecognizer];

			tapGestureRecognizer.cancelsTouchesInView = NO;

			// Let's get the Preference for haptic Feedback …

			CCPrefsHapticFeedbackValue = [CC_PREFS_VALUE_FOR_KEY(CCPrefsHapticFeedbackKey) boolValue];

			// Define the Size of the Cover …

			CGSize coverSize = CGSizeMake(60.0, 60.0);

			// Create the Placeholder for the Banner Image, …

			NSInteger visibleColumns = [self columnsThatFitScreenWidthWithCoverSize: coverSize];
			NSUInteger extraBleedColumns = [self extraBleedColumnsForMinimumBleed: (coverSize.width / 2.0) coverSize: coverSize];

			NSUInteger columns = visibleColumns + extraBleedColumns;

			CGSize canvasSize = CGSizeMake(columns * coverSize.width, (coverSize.height * 3.0));

			// … and a new Header View with the Size of our Placeholder.

			self.headerView = [[UIImageView alloc] initWithFrame: CGRectMake(0.0, 0.0, canvasSize.width, canvasSize.height)];

			// Add a new Image View to our Header View …

			self.headerImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0.0, 0.0, 0.0, 0.0)];

			self.headerImageView.alpha = 0.0;
			self.headerImageView.contentMode = UIViewContentModeScaleAspectFill;
			self.headerImageView.translatesAutoresizingMaskIntoConstraints = NO;

			// Now add the newly created Sub View to the Header View …

			[self.headerView addSubview: self.headerImageView];

			// We need to gain Authorization to get the Recent Albums starting with iOS 9.3 and above …

			if([MPMediaLibrary respondsToSelector: @selector(authorizationStatus)] && [MPMediaLibrary authorizationStatus] == MPMediaLibraryAuthorizationStatusNotDetermined)
			{
				// Authorization is async; the Collage will simply be empty until granted …

				[MPMediaLibrary requestAuthorization: ^(MPMediaLibraryAuthorizationStatus status) {}];
			}

			// Fetch and render the Album-Collage off the Main Thread. Only the finished `UIImage` is assigned on the Main Thread, so opening Preferences does not block Scrolling or Switch-Interactions while the Banner is prepared …

			__weak typeof(self) weakSelf = self;

			dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^
			{
				@autoreleasepool
				{
					__strong typeof(weakSelf) strongSelf = weakSelf;

					if(!strongSelf)
					{
						return;
					}

					/*
						Returns a single UIImage made up of the Covers of the most recently played Albums, arranged in a `rows` x `columns` Grid ( fetches rows * columns Covers ).

						`overlayAlpha` ( 0.0 – 1.0 ) draws a Black Layer on Top of the whole Collage — 0 for None.
					*/
					UIImage *headerImage = [strongSelf collageOfRecentAlbumsWithRows: 3 coverSize: coverSize darkOverlayAlpha: CCBackgroundDarkeningAlphaNormal columns: columns];

					dispatch_async(dispatch_get_main_queue(), ^
					{
						__strong typeof(weakSelf) currentSelf = weakSelf;

						if(!currentSelf)
						{
							return;
						}

						currentSelf.headerImageView.image = headerImage;

						// Preserve the existing Fade-In Animation …

						[UIView animateWithDuration: CCDurationNormal animations: ^
						{
							currentSelf.headerImageView.alpha = 1.0;
						}];
					});
				}
			});

			// Activate the Layout Constraints …

			[NSLayoutConstraint activateConstraints:
			@[
				[self.headerImageView.widthAnchor constraintEqualToConstant: canvasSize.width],
				[self.headerImageView.heightAnchor constraintEqualToConstant: canvasSize.height],
				[self.headerImageView.centerXAnchor constraintEqualToAnchor: self.headerView.centerXAnchor],
				[self.headerImageView.topAnchor constraintEqualToAnchor: self.headerView.topAnchor constant: 0.0]
			]];

			// Set the Table's Header View - exactly once, here …

			self.table.tableHeaderView = self.headerView;
			self.table.userInteractionEnabled = YES;
		}

		- (void)viewWillAppear: (BOOL)animated
		{
			[super viewWillAppear: animated];

			CGRect frame = self.table.bounds;

			frame.origin.y = -frame.size.height;

			[self.navigationController.navigationController.navigationBar setShadowImage: [UIImage new]];

			// Set the Navigation Bar's Tint Color using the assigned Color …

			self.navigationController.navigationController.navigationBar.tintColor = [autumnBoard generalNavigationBar];

			// Indepent of we're moving from a Sub-Page, the Parent View Controller is on Screen ( seriously I don't know why this works ) …

			self -> _isParentViewControllerOnScreen = YES;

			// Reconcile the Icon's Visibility with the Table's actual current Scroll Position …

			[self updateIconVisibilityForScrollView: self.table animated: NO];

			// Get the "Clean-Up Artworks"-Cell …

			PSSpecifier *cleanUpArtworksSpecifier = [self specifierForID: @"CCCleanUpArtworks"];

			if(cleanUpArtworksSpecifier)
			{
				// … and re-compute the Artwork Cache's File Count / Size every Time this Screen appears via a Navigation Transition - in case Files changed while this Screen was pushed.

				[self refreshArtworkCacheInfoForSpecifier: cleanUpArtworksSpecifier onlyOrphaned: NO];
			}

			// Get the "Clean-Up orphaned Artworks"-Cell …

			PSSpecifier* cleanUpOrphanedArtworksSpecifier = [self specifierForID: @"CCCleanUpOrphanedArtworks"];

			if(cleanUpOrphanedArtworksSpecifier)
			{
				// … and apply it's current File Count / Size synchronously.

				[self refreshArtworkCacheInfoForSpecifier: cleanUpOrphanedArtworksSpecifier onlyOrphaned: YES];
			}
		}

		- (void)viewWillDisappear: (BOOL)animated
		{
			[super viewWillDisappear: animated];

			// A List-Items Sub-Page is being pushed on Top …

			self -> _isParentViewControllerOnScreen = self.isMovingFromParentViewController;

			// Reset the Navigation Bar's Tint Color …

			self.navigationController.navigationController.navigationBar.tintColor = nil;
		}

		- (void)viewDidLayoutSubviews
		{
			[super viewDidLayoutSubviews];

			// The Header's Geometry could have changed ( e.g. on Rotation ), so invalidate the cached Header Height …

			self -> _cachedHeaderHeight = -1.0;
		}

	#pragma mark -
	#pragma mark Overrides

		- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController: (UIPresentationController *)controller
		{
			return UIModalPresentationNone;
		}

	#pragma mark -
	#pragma mark Image Picker

		- (void)imagePickerController: (UIImagePickerController *)picker didFinishPickingMediaWithInfo: (NSDictionary<NSString *,id> *)info
		{
			// Get the picked Image, …

			UIImage *image = [info objectForKey: UIImagePickerControllerOriginalImage];

			// … save it to our Cache-File …

			NSData *pngData = UIImagePNGRepresentation(image);

			NSError *writeError = nil;

			if([pngData writeToFile: CCFileManagerCacheBackground options: NSDataWritingAtomic error: &writeError])
			{
				MTLog(@"Creation of cached Background „%@“ was successful.", CCFileManagerCacheBackground);
			}
			else
			{
				MTLog(@"Creation of cached Background „%@“ failed with Error: %@", CCFileManagerCacheBackground, writeError);
			}

			// … and dismiss the Image Picker.

			[picker dismissViewControllerAnimated: YES completion: nil];
		}

		- (void)imagePickerControllerDidCancel: (UIImagePickerController *)picker
		{
			// Send haptic Feedback …

			[MTCoreHaptic triggerFeedbackWithValue: MTCoreHapticFeedbackStyleError value: CCPrefsHapticFeedbackValue];

			// … and dismiss the Image Picker.

			[picker dismissViewControllerAnimated: YES completion: nil];
		}

	#pragma mark -
	#pragma mark Table View

		- (void)scrollViewDidScroll: (UIScrollView *)scrollView
		{
			// Show or hide the Icon View, depending on the Scroll-Offset …

			[self updateIconVisibilityForScrollView: scrollView animated: YES];
		}

	#pragma mark -
	#pragma mark Private Methods - Banner

		- (UIImage *)collageOfRecentAlbumsWithRows: (NSUInteger)rows coverSize: (CGSize)coverSize darkOverlayAlpha: (CGFloat)overlayAlpha columns: (NSUInteger)columns
		{
			rows = MAX(rows, 1);

			if(columns > 0)
			{
				NSArray<MPMediaItemCollection *> *collections = [self recentlyPlayedAlbumCollections];

				NSUInteger collectionCount = collections.count;

				NSUInteger maxCount = rows * columns;
				NSUInteger count = MIN(maxCount, collectionCount);

				CGSize canvasSize;

				// Fill the complete grid by repeating albums if necessary …

				if(collections.count > 0)
				{
					count = maxCount;
				}

				// If we have at least one Cover …

				if(count > 0)
				{
					CGFloat colStep = coverSize.width;
					CGFloat rowStep = coverSize.height;

					canvasSize = CGSizeMake(columns * coverSize.width, rows * coverSize.height);

					UIGraphicsBeginImageContextWithOptions(canvasSize, NO, 0.0);

					CGContextRef ctx = UIGraphicsGetCurrentContext();

					// Repeated Tiles should not request the same Artwork several Times …

					NSMutableDictionary<NSNumber *, UIImage *> *coversByIndex = [NSMutableDictionary dictionaryWithCapacity: MIN(count, collectionCount)];

					UIImage *fallbackArtwork = [UIImage imageNamed: @"MissingAlbumArtwork.png" inBundle: self -> _preferenceBundle compatibleWithTraitCollection: nil];

					// Draw back-to-front so the most recent Album ( Index 0 ) ends up on Top …

					for(NSUInteger i = 0; i < count; i++)
					{
						NSUInteger row = i / columns;
						NSUInteger col = i % columns;

						NSUInteger albumIndex = i % collectionCount;

						NSNumber *albumIndexKey = @(albumIndex);

						UIImage *cover = coversByIndex[albumIndexKey];

						if(!cover)
						{
							MPMediaItem *item = collections[albumIndex].representativeItem;
							MPMediaItemArtwork *artwork = [item valueForProperty: MPMediaItemPropertyArtwork];

							cover = [artwork imageWithSize: coverSize] ?: fallbackArtwork;

							if(cover)
							{
								coversByIndex[albumIndexKey] = cover;
							}
						}

						CGRect rect = CGRectMake(col * colStep, row * rowStep, coverSize.width, coverSize.height);

						[cover drawInRect: rect];
					}

					// Darkening Overlay on Top of the whole Grid. UIRectFill defaults to kCGBlendModeCopy, which discards the Covers underneath regardless of Alpha — set the Blend Mode to Normal so this actually composites.

					if(overlayAlpha > 0.0)
					{
						CGContextSetBlendMode(ctx, kCGBlendModeNormal);
						CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite: 0.0 alpha: overlayAlpha].CGColor);

						CGContextFillRect(ctx, CGRectMake(0, 0, canvasSize.width, canvasSize.height));
					}
				}
				else
				{
					// … otherwise create an empty Canvas, so we can draw our Banner on Top of it.

					canvasSize = CGSizeMake(columns * coverSize.width, rows * coverSize.height);

					UIGraphicsBeginImageContextWithOptions(canvasSize, NO, 0.0);
				}

				// Draw our Banner on Top …

				UIImage *banner = [UIImage imageNamed: @"banner.png" inBundle: self -> _preferenceBundle compatibleWithTraitCollection: nil];

				[banner drawInRect: CGRectMake((canvasSize.width - banner.size.width) / 2.0, (canvasSize.height - banner.size.height) / 2.0, banner.size.width, banner.size.height)];

				UIImage *result = UIGraphicsGetImageFromCurrentImageContext();

				UIGraphicsEndImageContext();

				// Return the Result …

				return result;
			}
			else
			{
				return nil;
			}
		}

		// How many Columns fit the Screen Width when: `n * coverWidth <= screenWidth` which re-arranges to: `n <= screenWidth / coverWidth` ?

		- (NSInteger)columnsThatFitScreenWidthWithCoverSize: (CGSize)coverSize
		{
			CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
			CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;

			CGFloat step = coverSize.width;

			if(step <= 0.0)
			{
				return 0.0;
			}

			NSInteger columns = (NSInteger)floor(((screenWidth > screenHeight) ? screenHeight : screenWidth) / step);

			return MAX(columns, 1);
		}

		// Calculate how much Columns we need to fill the Screen-Width …

		- (NSUInteger)extraBleedColumnsForMinimumBleed: (CGFloat)minimumBleedPoints coverSize: (CGSize)coverSize
		{
			if(minimumBleedPoints <= 0.0)
			{
				return 0.0;
			}

			CGFloat step = coverSize.width;

			if(step <= 0.0)
			{
				return 0.0;
			}

			// When the resulting ( wider than Screen ) Image is centered in a same-width Container, only Half of each extra Column's Width bleeds past each Edge - the other Half is absorbed into the Container …

			CGFloat bleedPerExtraColumn = step / 2.0;

			// To guarantee at least `minimumBleedPoints` visible on each Side, we need enough extra Columns that half their combined Width reaches that Target …

			NSUInteger columns = (NSUInteger)ceil(minimumBleedPoints / bleedPerExtraColumn);

			return MAX(columns, 1);
		}

		- (NSArray<MPMediaItemCollection *> *)recentlyPlayedAlbumCollections
		{
			// Get the Recently played Albums …

			MPMediaQuery *albumsQuery = [MPMediaQuery albumsQuery];
			NSArray<MPMediaItemCollection *> *collections = albumsQuery.collections ?: @[];

			// The Album-Array …

			NSArray<MPMediaItemCollection *> *albums = [collections sortedArrayUsingComparator: ^NSComparisonResult(MPMediaItemCollection* collectionOne, MPMediaItemCollection* collectionTwo)
			{
				@autoreleasepool
				{
					NSDate *dateOne = [collectionOne representativeItem].lastPlayedDate;
					NSDate *dateTwo = [collectionTwo representativeItem].lastPlayedDate;

					// Let's do the Order-Magic …

					if(!dateOne && !dateTwo) { return NSOrderedSame; }

					if(!dateOne) { return NSOrderedDescending; } // Never-played sinks to Bottom …
					if(!dateTwo) { return NSOrderedAscending; }

					return [dateTwo compare: dateOne];
				}
			}];

			return albums;
		}

	#pragma mark -
	#pragma mark Private Methods - Cache

		// Synchronous - only sets the Specifier's own Properties directly, never touches the Table …

		- (void)applyArtworkCacheInfoToSpecifier: (PSSpecifier *)specifier onlyOrphaned: (BOOL)onlyOrphaned
		{
			NSString *subTitle;

			BOOL enabled;

			// Calculates the Artwork Cache Size …

			[self calculateArtworkCacheSize: &subTitle enabled: &enabled onlyOrphaned: onlyOrphaned];

			// … and then applies the Result.

			[specifier setProperty: subTitle forKey: @"subTitle"];
			[specifier setProperty: @(enabled) forKey: @"enabled"];
		}

		// Check, if the Cache contains Files …

		- (BOOL)artworkCacheContainsFiles: (BOOL)onlyOrphaned
		{
			NSFileManager *fileManager = [NSFileManager defaultManager];

			// Check, if the Directory for our Artwork Cache exists …

			BOOL isDirectory = NO;

			if(![fileManager fileExistsAtPath: CCFileManagerCacheArtwork isDirectory: &isDirectory] || !isDirectory)
			{
				return NO;
			}

			// The current Library's Album IDs - anything cached that isn't in here is orphaned …

			NSSet<NSString *> *currentAlbumIDs = (onlyOrphaned ? [self currentLibraryAlbumPersistentIDs] : nil);

			// Build an Enumerator, which let's us remove every single File …

			NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath: CCFileManagerCacheArtwork];

			// Go through the enumerated Files …

			NSString *relativePath = nil;

			while((relativePath = [enumerator nextObject]))
			{
				NSString *fullPath = [CCFileManagerCacheArtwork stringByAppendingPathComponent: relativePath];

				// Be sure, that the current Item isn't a Directory …

				BOOL itemIsDirectory = NO;

				// If the File doesn't exist or is a Directory, continue …

				if(![fileManager fileExistsAtPath: fullPath isDirectory: &itemIsDirectory] || itemIsDirectory)
				{
					continue;
				}

				// If we should check for simply having an empty Cache, return here …

				if(!onlyOrphaned)
				{
					return YES;
				}

				// Otherwise, if we should check for orphaned Artworks, get the Filename without it's Extension: It's the Album's Persistent ID, …

				NSString *albumPersistentID = [[fullPath lastPathComponent] stringByDeletingPathExtension];

				// … but for the Reflection Counterpart it carries a "_r" Suffix, so strip that too …

				if([albumPersistentID hasSuffix: @"_r"])
				{
					albumPersistentID = [albumPersistentID substringToIndex: (albumPersistentID.length - 2)];
				}

				// … and if the Album it refers to is no longer in the Library, it's orphaned …

				if(![currentAlbumIDs containsObject: albumPersistentID])
				{
					return YES;
				}
			}

			return NO;
		}

		// Calculate the Size of our Artwork Cache: This is pure Computation, so no Specifier or Table Interaction, which makes it safe to call from any Thread …

		- (void)calculateArtworkCacheSize: (NSString **)outSubTitle enabled: (BOOL *)outEnabled onlyOrphaned: (BOOL)onlyOrphaned
		{
			NSFileManager *fileManager = [NSFileManager defaultManager];

			// Check, if the Directory for our Artwork Cache exists …

			BOOL isDirectory = NO;

			if(![fileManager fileExistsAtPath: CCFileManagerCacheArtwork isDirectory: &isDirectory] || !isDirectory)
			{
				// … and if not, we don't have anything to clean-up here, so inform the User about it and disable the Button.

				*outSubTitle = [self -> _preferenceBundle localizedStringForKey: (onlyOrphaned ? @"CCCacheSubTitleNoOrphanedArtworks" : @"CCCacheSubTitleNoArtworks") value: @"" table: nil];
				*outEnabled = NO;

				return;
			}

			// We can go further, so at first we need a Variable for the File-Count …

			NSUInteger fileCount = 0;

			// … but we also want to know the Size of the Cache.

			unsigned long long totalSize = 0;

			// The current Library's Album IDs - anything cached that isn't in here is orphaned. Only orphaned Artwork-Scans need the Media Library …

			NSSet<NSString *> *currentAlbumIDs = (onlyOrphaned ? [self currentLibraryAlbumPersistentIDs] : nil);

			// Build an Enumerator, which let's us retrieve the File Size …

			NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath: CCFileManagerCacheArtwork];

			// Go through the enumerated Files …

			NSString *relativePath = nil;

			while((relativePath = [enumerator nextObject]))
			{
				NSString *fullPath = [CCFileManagerCacheArtwork stringByAppendingPathComponent: relativePath];

				// The Enumerator already provides File Attributes. Avoid a separate Existence Check and another File-System Metadata-Lookup for each Item …

				NSDictionary *attributes = [enumerator fileAttributes];

				// If the File exists and isn't a Directory …

				if(attributes && ![attributes[NSFileType] isEqual: NSFileTypeDirectory])
				{
					// Should we only check for orphaned Artworks ?

					if(onlyOrphaned)
					{
						// If so, get the Filename without it's Extension: It's the Album's Persistent ID, …

						NSString *albumPersistentID = [[fullPath lastPathComponent] stringByDeletingPathExtension];

						// … but for the Reflection Counterpart it carries a "_r" Suffix, so strip that too …

						if([albumPersistentID hasSuffix: @"_r"])
						{
							albumPersistentID = [albumPersistentID substringToIndex: (albumPersistentID.length - 2)];
						}

						// … and if the Album it refers to is no longer in the Library, it's orphaned, …

						if(![currentAlbumIDs containsObject: albumPersistentID])
						{
							// … so get it's File Size …

							totalSize += [attributes fileSize];

							// … and since we have an Artwork plus it's Reflection ( which is simply one Artwork, separated in two Files ), …

							if(![fullPath containsString: @"_r"])
							{
								// … we have to count only the real Artwork.

								fileCount++;
							}
						}
					}
					else
					{
						// Get it's File Size …

						totalSize += [attributes fileSize];

						// … and since we have an Artwork plus it's Reflection ( which is simply one Artwork, separated in two Files ), …

						if(![fullPath containsString: @"_r"])
						{
							// … we have to count only the real Artwork.

							fileCount++;
						}
					}
				}
			}

			// If we have at least one File …

			if(fileCount > 0)
			{
				// Put the Cache Size and the Unit together …

				NSString *formattedSize = [self getFormattedFileSize: totalSize];

				// Special Treatment for a single Cover or multiple Covers ( yeah, some People have a very small Media Library ) …

				*outSubTitle = [NSString stringWithFormat: [self -> _preferenceBundle localizedStringForKey: ((fileCount == 1) ? @"CCCacheSubTitleSingular" : @"CCCacheSubTitlePlural") value: @"" table: nil], fileCount, formattedSize];
			}
			else
			{
				*outSubTitle = [self -> _preferenceBundle localizedStringForKey: (onlyOrphaned ? @"CCCacheSubTitleNoOrphanedArtworks" : @"CCCacheSubTitleNoArtworks") value: @"" table: nil];
			}

			// If we have at least one File, the Button will be enabled, otherwise not …

			*outEnabled = (fileCount > 0);
		}

		- (void)cleanUpCacheWithSpecifier: (PSSpecifier *)specifier alertMessageID: (NSString *)alertMessageID onlyOrphaned: (BOOL)onlyOrphaned cancelHandler: (void (^ _Nullable)(UIAlertAction * _Nonnull __strong))cancelHandler
		{
			// Check, if the Cache doesn't contain any File …

			if(![self artworkCacheContainsFiles: onlyOrphaned])
			{
				// … if so, we have nothing to clean up: Keep the Rows in Sync, but show no Alert.

				return;
			}

			NSFileManager *fileManager = [NSFileManager defaultManager];

			// Check, if the Directory for our Artwork Cache exists …

			BOOL isDirectory = NO;

			if(![fileManager fileExistsAtPath: CCFileManagerCacheArtwork isDirectory: &isDirectory] || !isDirectory)
			{
				// Get the "Clean-Up Artworks"- and "Clean-Up orphaned Artworks"-Cells, …

				PSSpecifier* cleanUpArtworksSpecifier = [self specifierForID: @"CCCleanUpArtworks"];
				PSSpecifier* cleanUpOrphanedArtworksSpecifier = [self specifierForID: @"CCCleanUpOrphanedArtworks"];

				// … apply it's current File Count / Size synchronously …

				if(cleanUpArtworksSpecifier)
				{
					[self applyArtworkCacheInfoToSpecifier: cleanUpArtworksSpecifier onlyOrphaned: NO];
				}

				if(cleanUpOrphanedArtworksSpecifier)
				{
					[self applyArtworkCacheInfoToSpecifier: cleanUpOrphanedArtworksSpecifier onlyOrphaned: YES];
				}

				// … and reload the Rows.

				[self updateSubTitleForSpecifier: cleanUpArtworksSpecifier];
				[self updateSubTitleForSpecifier: cleanUpOrphanedArtworksSpecifier];

				return;
			}

			// Send haptic Feedback …

			[MTCoreHaptic triggerFeedbackWithValue: MTCoreHapticFeedbackStyleLight value: CCPrefsHapticFeedbackValue];

			// Get the Identifier for Alert's Title …

			NSString *alertTitleID = (onlyOrphaned ? @"CCCacheOrphanedArtworksTitle" : @"CCCacheArtworksTitle");

			// We can go further, so at first we need a Alert …

			NSString *localizedAlertCancel = [self -> _preferenceBundle localizedStringForKey: @"CCCacheAlertCancel" value: @"" table: nil];
			NSString *localizedAlertCleanUp = [self -> _preferenceBundle localizedStringForKey: @"CCCacheAlertCleanUp" value: @"" table: nil];
			NSString *localizedAlertMessage = [self -> _preferenceBundle localizedStringForKey: alertMessageID value: @"" table: nil];
			NSString *localizedAlertTitle = [self -> _preferenceBundle localizedStringForKey: alertTitleID value: @"" table: nil];

			UIAlertController *alert = [UIAlertController alertControllerWithTitle: localizedAlertTitle message: localizedAlertMessage preferredStyle: UIAlertControllerStyleAlert];

			// … with a Cancel-Button and a destructive Clean-Up-Button.

			[alert addAction: [UIAlertAction actionWithTitle: localizedAlertCancel style: UIAlertActionStyleCancel handler: cancelHandler]];
			[alert addAction: [UIAlertAction actionWithTitle: localizedAlertCleanUp style: UIAlertActionStyleDestructive handler: ^(UIAlertAction *action)
			{
				// The current Library's Album IDs - anything cached that isn't in here is orphaned. Deleting the entire Cache does not require a Media Library Query …

				NSSet<NSString *> *currentAlbumIDs = (onlyOrphaned ? [self currentLibraryAlbumPersistentIDs] : nil);

				// Build an Enumerator, which let's us remove every single File …

				NSDirectoryEnumerator *deleteEnumerator = [fileManager enumeratorAtPath: CCFileManagerCacheArtwork];

				// Go through the enumerated Files …

				NSString *relativePath = nil;

				while((relativePath = [deleteEnumerator nextObject]))
				{
					NSString *fullPath = [CCFileManagerCacheArtwork stringByAppendingPathComponent: relativePath];

					// If an Error occurs, we can provide more Details in `MTLog` about it …

					NSError *error = nil;

					// Should we only remove orphaned Artworks ?

					if(onlyOrphaned)
					{
						// If so, get the Filename without it's Extension: It's the Album's Persistent ID, …

						NSString *albumPersistentID = [[fullPath lastPathComponent] stringByDeletingPathExtension];

						// … but for the Reflection Counterpart it carries a "_r" Suffix, so strip that too …

						if([albumPersistentID hasSuffix: @"_r"])
						{
							albumPersistentID = [albumPersistentID substringToIndex: (albumPersistentID.length - 2)];
						}

						// … and if the Album it refers to is no longer in the Library, it's orphaned, …

						if(![currentAlbumIDs containsObject: albumPersistentID])
						{
							// Try to remove the cached File at the given Path …

							if(![fileManager removeItemAtPath: fullPath error: &error])
							{
								MTLog(@"Removing orphaned Cache-Entry „%@“ failed with Error: %@", fullPath, error);
							}
						}
					}
					else
					{
						// Try to remove the cached File at the given Path …

						if(![fileManager removeItemAtPath: fullPath error: &error])
						{
							MTLog(@"Removing Cache-Entry „%@“ failed with Error: %@", fullPath, error);
						}
					}
				}

				// Get the "Clean-Up Artworks"- and "Clean-Up orphaned Artworks"-Cells, …

				PSSpecifier* cleanUpArtworksSpecifier = [self specifierForID: @"CCCleanUpArtworks"];
				PSSpecifier* cleanUpOrphanedArtworksSpecifier = [self specifierForID: @"CCCleanUpOrphanedArtworks"];

				// … the Rows were showing the pre-deletion Count / Size until now - refresh them, so they reflect the new Cache instead of staying Stale.

				if(cleanUpArtworksSpecifier)
				{
					[self refreshArtworkCacheInfoForSpecifier: cleanUpArtworksSpecifier onlyOrphaned: NO];
				}

				if(cleanUpOrphanedArtworksSpecifier)
				{
					[self refreshArtworkCacheInfoForSpecifier: cleanUpOrphanedArtworksSpecifier onlyOrphaned: YES];
				}
			}]];

			// Show the Alert …

			[self presentViewController: alert animated: YES completion: nil];
		}

		- (NSSet<NSString *> *)currentLibraryAlbumPersistentIDs
		{
			// Build a Set of every Album's Persistent ID currently in the Media Library …

			NSArray<MPMediaItemCollection *> *collections = [[MPMediaQuery albumsQuery] collections] ?: @[];

			NSMutableSet<NSString *> *albumIDs = [NSMutableSet setWithCapacity: collections.count];

			for(MPMediaItemCollection *collection in collections)
			{
				MPMediaEntityPersistentID albumPersistentID = [collection.representativeItem albumPersistentID];

				[albumIDs addObject: [@(albumPersistentID) stringValue]];
			}

			return albumIDs;
		}

		- (NSString *)getFormattedFileSize: (unsigned long long)totalSize
		{
			// We want to have a nice looking File Size, but at First define two Variables containing the Cache Size …

			double size;

			// … and the Unit.

			NSString *unit;

			// Now we can format them …

			if(totalSize < 1024)
			{
				size = totalSize;
				unit = [self -> _preferenceBundle localizedStringForKey: @"MTBinarySizeBytes" value: @"" table: nil];
			}
			else if(totalSize < (1024 * 1024))
			{
				size = (double)totalSize / 1024.0;
				unit = [self -> _preferenceBundle localizedStringForKey: @"MTBinarySizeKB" value: @"" table: nil];
			}
			else if(totalSize < (1024 * 1024 * 1024))
			{
				size = (double)totalSize / (1024.0 * 1024.0);
				unit = [self -> _preferenceBundle localizedStringForKey: @"MTBinarySizeMB" value: @"" table: nil];
			}
			else
			{
				size = (double)totalSize / (1024.0 * 1024.0 * 1024.0);
				unit = [self -> _preferenceBundle localizedStringForKey: @"MTBinarySizeGB" value: @"" table: nil];
			}

			// … with a `NSNumberFormatter` we're also getting correct looking Commas and Thousand Separators …

			NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];

			formatter.formatterBehavior = NSNumberFormatterBehavior10_4;
			formatter.numberStyle = NSNumberFormatterDecimalStyle;

			formatter.minimumFractionDigits = 0;
			formatter.maximumFractionDigits = 2;

			return [NSString stringWithFormat: @"%@ %@", [formatter stringFromNumber: @(size)], unit];
		}

		// Asynchronous - safe ONLY when the Table is already loaded and stable, NOT from within `-specifiers` itself …

		- (void)refreshArtworkCacheInfoForSpecifier: (PSSpecifier *)specifier onlyOrphaned: (BOOL)onlyOrphaned
		{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
			{
				NSString *subTitle;

				BOOL enabled;

				// Computes on the next Turn of the Main Run Loop, …

				[self calculateArtworkCacheSize: &subTitle enabled: &enabled onlyOrphaned: onlyOrphaned];

				dispatch_async(dispatch_get_main_queue(), ^
				{
					// … then applies the Result …

					[specifier setProperty: subTitle forKey: @"subTitle"];
					[specifier setProperty: @(enabled) forKey: @"enabled"];

					// … and reloads the Row on the Main Queue.

					[self updateSubTitleForSpecifier: specifier];
				});
			});
		}

	#pragma mark -
	#pragma mark Private Methods - Preferences

		// Applies the initial Preference-dependent Visibility while `-specifiers` is still building `_specifiers` - called both the first Time this Screen loads AND every Time `_specifiers` gets rebuilt after returning from a pushed View …

		- (void)applyInitialSpecifierVisibility
		{
			// Background Style …

			PSSpecifier *backgroundStyleSpecifier = [self specifierForID: @"CCBackgroundStyle"];

			CCBackgroundStyle style = (CCBackgroundStyle)[[self readPreferenceValue: backgroundStyleSpecifier] integerValue];

			BOOL shouldShowColor = (style == CCBackgroundStyleColorPlain);
			BOOL shouldShowImageButton = (style == CCBackgroundStylePhoto || style == CCBackgroundStylePhotoBlur);

			// Reflections …

			PSSpecifier *reflectionSpecifier = [self specifierForID: @"CCReflection"];

			BOOL reflections = [[self readPreferenceValue: reflectionSpecifier] boolValue];

			// Demo-Loop …

			PSSpecifier *demoEnabledSpecifier = [self specifierForID: @"CCDemoEnabled"];

			BOOL demoEnabled = [[self readPreferenceValue: demoEnabledSpecifier] boolValue];

			// The Table hasn't necessarily loaded these Rows yet or it's current Row Count doesn't match `_specifiers` anymore, so this mutates the plain Array directly instead of going through `- (void)removeSpecifier: animated:` / `- (void)insertSpecifier: afterSpecifier: animated:`, which both drive an actual UITableView Row Update and require the Table's current Row Count to already match `_specifiers` before being called …

			NSMutableArray *mutableSpecifiers = [self -> _specifiers mutableCopy];

			// If the given Specifier exists and "Plain Color" isn't selected, remove the Specifier …

			if(self -> _backgroundColorSpecifier && !shouldShowColor)
			{
				[mutableSpecifiers removeObject: self -> _backgroundColorSpecifier];
			}

			// If the given Specifier exists and "Photo" or / "Photo with Blur" isn't selected, remove the Specifier …

			if(self -> _backgroundImageSpecifier && !shouldShowImageButton)
			{
				[mutableSpecifiers removeObject: self -> _backgroundImageSpecifier];
			}

			// If the given Specifier exists and we're running on an Apple A8-Device or earlier or Reflections are disabled, remove the Specifier …

			if(self -> _reflectionBlurSpecifier && (CCDeviceIsPreA9SoC || !reflections))
			{
				[mutableSpecifiers removeObject: self -> _reflectionBlurSpecifier];
			}

			// If the given Specifiers exist and "Demo-Loop" isn't turned on, remove the Specifiers …

			if(self -> _preventSleepSpecifier && !demoEnabled)
			{
				[mutableSpecifiers removeObject: self -> _preventSleepSpecifier];
			}

			if(self -> _preventSleepGroupSpecifier && !demoEnabled)
			{
				[mutableSpecifiers removeObject: self -> _preventSleepGroupSpecifier];
			}

			// Return the new Specifiers …

			self -> _specifiers = mutableSpecifiers;
		}

		// Remove unsupported Specifiers, which don't met the required Core Foundation Version / Hardware Capabilities …

		- (void)removeSpecifiersUnsupportedByDevice
		{
			// Check, if we're running on a pre-A9-Device ( iPhone 5S, iPhone 6(+), iPad Air ( 1st & 2n Gen ), iPad mini ( 2nd - 4th Gen. ) and iPod touch 6 ) …

			CCDeviceIsPreA9SoC = [self deviceIsPreA9SoC];

			// Check, if we're running on a Device with Taptic Engine ( iPhone 6S(+) and above ) …

			CCDeviceHasTapticEngine = [self deviceHasTapticEngine];

			// Create a new Dictionary for our unsupported Specifiers …

			NSMutableArray *unsupportedSpecifiers = [NSMutableArray array];

			// Let's iterate through the Preference-Specifiers from "Root.plist"

			for(PSSpecifier *specifier in _specifiers)
			{
				// The Key `minCoreFoundationVersion` can be Part of a whole Specifier, so we're able to remove it completely …

				NSNumber *minCoreFoundationVersion = [specifier propertyForKey: @"minCoreFoundationVersion"];

				// Let‘s check, if the Value exists and if Core Foundation's Version Number is lower than our minimum specified Version, …

				if(minCoreFoundationVersion && kCFCoreFoundationVersionNumber < [minCoreFoundationVersion doubleValue])
				{
					// … if so, we can mark this Specifier for Removal …

					[unsupportedSpecifiers addObject: specifier];

					// … and continue with the next Item.

					continue;
				}

				// We can also remove single Items of a List …

				NSDictionary *minCoreFoundationVersions = [specifier propertyForKey: @"minCoreFoundationVersions"];

				// If the Dictionary with the Keys exist, …

				if(minCoreFoundationVersions)
				{
					// … create two new Arrays for the Titles and the Values.

					NSMutableArray *titles = [NSMutableArray array];
					NSMutableArray *values = [NSMutableArray array];

					// Now we want to iterate through the Dictionary-Keys …

					for(id value in [specifier values])
					{
						// We can specify minimum Version for a specific Key, so get it …

						NSNumber *minCoreFoundationVersionForKey = minCoreFoundationVersions[[NSString stringWithFormat: @"%@", value]];

						// Let‘s check, if the Value exists and if Core Foundation's Version Number is lower than our minimum specified Version …

						if(minCoreFoundationVersionForKey && kCFCoreFoundationVersionNumber < [minCoreFoundationVersionForKey doubleValue])
						{
							// … and continue with the next Item.

							continue;
						}

						// It's completely different here, because we populate the Arrays with Values of Keys which are supported on our System Version …

						[values addObject: value];
						[titles addObject: [specifier titleDictionary][value] ?: [value description]];
					}

					// Set the new Values …

					[specifier setValues: values titles: titles];
				}

				// Let's check the Hardware of the current Device and remove Specifiers, which don't support the required Capabilities …

				NSArray<NSString *> *requiredDeviceCapabilities = [specifier propertyForKey: @"requiredDeviceCapabilities"];

				// If the Array with the Values exist, …

				if(requiredDeviceCapabilities)
				{
					// … be sure, that every listed Capability has to be available on this Device.

					BOOL allCapabilitiesAvailable = YES;

					// Now we want to iterate through the Values …

					for(NSString *capability in requiredDeviceCapabilities)
					{
						// Let‘s check, if the current Device hasn't the given Capability …

						if([capability isEqualToString: @"DeviceSupportsTapticEngine"] && !CCDeviceHasTapticEngine) // Taptic Engine …
						{
							allCapabilitiesAvailable = NO;

							break;
						}
					}

					// If there's a Capability missing, …

					if(!allCapabilitiesAvailable)
					{
						// … mark the Specifier for Removal …

						[unsupportedSpecifiers addObject: specifier];

						// … and continue with the next Item.

						continue;
					}
				}
			}

			// Remove the unsupported Specifiers …

			[_specifiers removeObjectsInArray: unsupportedSpecifiers];
		}

		// Called by `PSListController` whenever the User changes a Preference's Value from this Screen …

		- (void)setPreferenceValue: (id)value specifier: (PSSpecifier *)specifier
		{
			[super setPreferenceValue: value specifier: specifier];

			// Get the Key of the ( changed ) Preference …

			NSString *key = [specifier propertyForKey: @"key"];

			// We hook it, to react live when the Artwork Size changes, …

			if([key isEqualToString: @"artworkSize"])
			{
				// … but at First we have to get the "Clean-Up Artworks"-Cell, …

				PSSpecifier* cleanUpArtworksSpecifier = [self specifierForID: @"CCCleanUpArtworks"];

				// … get the old Value for our Preference …

				NSInteger artworkSize = [CC_PREFS_VALUE_FOR_KEY(CCPrefsArtworkSizeKey) integerValue];

				// … and if it's not empty, …

				if(cleanUpArtworksSpecifier)
				{
					// … capture the pushed View Controller immediately, …

					UIViewController *pushedController = self.navigationController.topViewController;

					// … remove the Cache, …

					[self cleanUpCacheWithSpecifier: cleanUpArtworksSpecifier alertMessageID: @"CCCacheAlertSizeMessage" onlyOrphaned: NO cancelHandler: ^(UIAlertAction *action)
					{
						// … but if the User decides to Cancel the Clean-Up of the Cache, revert the Preference back.

						[super setPreferenceValue: @(artworkSize) specifier: [self specifierForID: @"CCArtworkSize"]];

						// Refresh the List-Items-Controller's Specifiers …

						if([pushedController isKindOfClass: [MTTintedListItemsController class]])
						{
							[(MTTintedListItemsController *)pushedController reloadSpecifiers];
						}
					}];
				}
			}

			// We hook it, to react live when the Background Style changes, so "Set Background Color" / "Set Background Image" show or hide immediately without needing to leave and re-enter the Screen …

			if([key isEqualToString: @"backgroundStyle"])
			{
				[self updateBackgroundDependentSpecifiers];
			}

			// React immediately on a Change for haptic Feedback …

			if([key isEqualToString: @"hapticFeedback"])
			{
				CCPrefsHapticFeedbackValue = [value boolValue];
			}

			// We hook it, to react live when the Reflection changes, so show or hide "Reflection Blur" immediately without needing to leave and re-enter the Screen …

			if([key isEqualToString: @"reflection"])
			{
				[self updateReflectionDependentSpecifiers];
			}

			// We hook it, to react live when the Reflection-Blur changes, …

			if([key isEqualToString: @"reflectionBlur"])
			{
				// … but at First we have to get the "Clean-Up Artworks"-Cell …

				PSSpecifier* cleanUpArtworksSpecifier = [self specifierForID: @"CCCleanUpArtworks"];

				// … and if it's not empty, …

				if(cleanUpArtworksSpecifier)
				{
					// … remove the Cache …

					[self cleanUpCacheWithSpecifier: cleanUpArtworksSpecifier alertMessageID: ([value boolValue] ? @"CCCacheAlertBlurMessage" : @"CCCacheAlertNoBlurMessage") onlyOrphaned: NO cancelHandler: ^(UIAlertAction *action)
					{
						// … but if the User decides to Cancel the Clean-Up of the Cache, revert the Preference back.

						[super setPreferenceValue: @((BOOL)![value boolValue]) specifier: [self specifierForID: @"CCReflectionBlur"]];

						// Reload the Row …

						[self reloadSpecifier: self -> _reflectionBlurSpecifier];
					}];
				}
			}

			// We hook it, to react live when the Demo-Loop changes …

			if([key isEqualToString: @"demoEnabled"])
			{
				[self updatePresentationModeDependentSpecifiers];
			}

			// Get the Cell of the ( changed ) Preference …

			NSString *cell = [specifier propertyForKey: @"cell"];

			// If the Cell wasn't a …

			if(![cell isEqualToString: @"PSButtonCell"] && ![cell isEqualToString: @"PSEditTextCell"])
			{
				// … then trigger haptic Feedback with a light Tap.

				[MTCoreHaptic triggerFeedbackWithValue: MTCoreHapticFeedbackStyleLight value: CCPrefsHapticFeedbackValue];
			}

			// Post the Notification …

			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)MTNotificationPreferenceChange, NULL, NULL, YES);
		}

		- (void)setSpecifier: (PSSpecifier *)specifier hidden: (BOOL)hidden afterSpecifier: (PSSpecifier *)precedingSpecifier
		{
			if(specifier)
			{
				BOOL isCurrentlyVisible = ([_specifiers indexOfObject: specifier] != NSNotFound);

				if(hidden && isCurrentlyVisible)
				{
					[self removeSpecifier: specifier animated: YES];
				}
				else if(!hidden && !isCurrentlyVisible)
				{
					[self insertSpecifier: specifier afterSpecifier: precedingSpecifier animated: YES];
				}
			}
		}

		// Shows "Set Background Color" only for the plain Color Style, and "Set Background Image" only for the two Photo-based Styles - called ONLY in response to a live Change from `- (void)setPreferenceValue: specifier:`, while the Table is already fully loaded and its Row Count is stable / consistent with `_specifiers` …

		- (void)updateBackgroundDependentSpecifiers
		{
			PSSpecifier *backgroundStyleSpecifier = [self specifierForID: @"CCBackgroundStyle"];

			CCBackgroundStyle style = (CCBackgroundStyle)[[self readPreferenceValue: backgroundStyleSpecifier] integerValue];

			// Show "Set Background Color" only for the plain Color Style and "Set Background Image" only for the two Photo-based Styles …

			BOOL shouldShowColor = (style == CCBackgroundStyleColorPlain);
			BOOL shouldShowImageButton = (style == CCBackgroundStylePhoto || style == CCBackgroundStylePhotoBlur);

			// If we're not chosen a Photo-based Style, remove the cached Background …

			if(!shouldShowImageButton)
			{
				NSFileManager *fileManager = [NSFileManager defaultManager];

				NSError *error = nil;

				if([fileManager fileExistsAtPath: CCFileManagerCacheBackground] && ![fileManager removeItemAtPath: CCFileManagerCacheBackground error: &error])
				{
					MTLog(@"Removing cached Background „%@“ failed with Error: %@", CCFileManagerCacheBackground, error);
				}
			}

			// Show or hide the Specifiers, based on the chosen Background Style …

			[self setSpecifier: _backgroundColorSpecifier hidden: !shouldShowColor afterSpecifier: backgroundStyleSpecifier];
			[self setSpecifier: _backgroundImageSpecifier hidden: !shouldShowImageButton afterSpecifier: backgroundStyleSpecifier];
		}

		- (void)updateSubTitleForSpecifier: (PSSpecifier *)specifier
		{
			// A Cell only exists, if the Row was already displayed. Otherwise the updated Properties get picked up when it's created …

			PSTableCell *cell = [self cachedCellForSpecifier: specifier];

			if([cell isKindOfClass: [MTContactCell class]])
			{
				[(MTContactCell *)cell refreshSubTitleWithSpecifier: specifier];
			}
		}

		// Shows "Reflection Blur" only if Reflection is enabled - called ONLY in response to a live Change from `- (void)setPreferenceValue: specifier:`, while the Table is already fully loaded and its Row Count is stable / consistent with `_specifiers` …

		- (void)updateReflectionDependentSpecifiers
		{
			PSSpecifier *reflectionSpecifier = [self specifierForID: @"CCReflection"];

			BOOL reflections = !CCDeviceIsPreA9SoC && [[self readPreferenceValue: reflectionSpecifier] boolValue];

			// Show or hide the Specifiers, based on the chosen Reflection-State …

			[self setSpecifier: _reflectionBlurSpecifier hidden: !reflections afterSpecifier: reflectionSpecifier];
		}

		// Shows "Prevent Display Sleep" only if Demo-Loop is enabled - called ONLY in response to a live Change from `- (void)setPreferenceValue: specifier:`, while the Table is already fully loaded and its Row Count is stable / consistent with `_specifiers` …

		- (void)updatePresentationModeDependentSpecifiers
		{
			PSSpecifier *demoEnabledSpecifier = [self specifierForID: @"CCDemoEnabled"];

			BOOL demoEnabled = [[self readPreferenceValue: demoEnabledSpecifier] boolValue];

			// Show or hide the Specifiers, based on the chosen Demo-Loop-State …

			[self setSpecifier: _preventSleepGroupSpecifier hidden: !demoEnabled afterSpecifier: demoEnabledSpecifier];

			PSSpecifier *preventSleepGroupSpecifier = [self specifierForID: @"CCPreventSleepGroup"];

			[self setSpecifier: _preventSleepSpecifier hidden: !demoEnabled afterSpecifier: preventSleepGroupSpecifier];
		}

	#pragma mark -
	#pragma mark Private Methods - Table

		- (void)updateIconVisibilityForScrollView: (UIScrollView *)scrollView animated: (BOOL)animated
		{
			// If the Parent View Controller is on Screen …

			if(self -> _isParentViewControllerOnScreen)
			{
				// This Geometry only ever changes when the Header's Layout does, so we don't want to fire on every single Scroll Delta. Compute it once and reuse the cached Value …

				if(self -> _cachedHeaderHeight < 0.0)
				{
					// … get the Height of our Header Image.

					CGFloat headerImageHeight = self.headerImageView.bounds.size.height;

					// The Header hasn't been laid out yet, so there's nothing to compare against yet, and we're at the Top of the Table at this Point anyway, …

					if(headerImageHeight <= 0.0)
					{
						// … so the Icon should stay hidden - but only actually touch it if it wasn't already, instead of redoing the Fade-Out Animation on every single Scroll Delta while we wait for Layout …

						if(self -> _isIconViewVisible)
						{
							self -> _isIconViewVisible = NO;

							self -> _iconViewFadeOut();
							self -> _iconViewFadeOutComplete(YES);
						}

						// Leave the Cache empty ( still `< 0` ) so we try again the next Time this is called, once Layout has actually happened …

						return;
					}

					// We want to show the Icon View not on Top: The User scrolls the Banner outside of the View, now let's show the Icon …

					self -> _cachedHeaderHeight = headerImageHeight - (self.navigationItem.titleView.bounds.size.height + 9.0);
				}

				// Get the Y-Offset in our Scroll View ( the Position ) …

				CGFloat offsetY = scrollView.contentOffset.y;

				// If the Y-Offset is larger than the cached Height of our Header, …

				BOOL shouldBeVisible = (offsetY > self -> _cachedHeaderHeight);

				// If the Value has changed since last Time - re-trigger the Animation …

				if(shouldBeVisible != self -> _isIconViewVisible)
				{
					// Set the tracked State to it's new Value …

					self -> _isIconViewVisible = shouldBeVisible;

					// If the Icon View should be visible …

					if(shouldBeVisible)
					{
						// … show the them, …

						self.iconView.hidden = NO;

						// … and last - but not least - animate the View … or not.

						animated ? [UIView animateWithDuration: CCDurationHalf animations: self -> _iconViewFadeIn] : self -> _iconViewFadeIn();
					}
					else
					{
						// … and last - but not least - animate the View … or not.

						if(animated)
						{
							[UIView animateWithDuration: CCDurationHalf animations: self -> _iconViewFadeOut completion: self -> _iconViewFadeOutComplete];
						}
						else
						{
							self -> _iconViewFadeOut();
							self -> _iconViewFadeOutComplete(YES);
						}
					}
				}
			}
		}

	#pragma mark -
	#pragma mark Private Methods

		- (BOOL)deviceHasTapticEngine
		{
			// Check, if we're running on a Device with Taptic Engine ( iPhone 6S(+) and above ) …

			struct utsname info;

			uname(&info);

			NSString *machine = [NSString stringWithUTF8String: info.machine];

			// iPhone SE ( 1st Gen. ), iPads and iPod touches don't have a Taptic Engine …

			if([machine isEqualToString: @"iPhone8,4"] || ![machine hasPrefix: @"iPhone"])
			{
				return NO;
			}

			// Get the major Device Version …

			NSInteger majorDeviceVersion = [[[machine substringFromIndex: 6] componentsSeparatedByString: @","].firstObject integerValue];

			// … and if this is above 8 ( iPhone 6S ), we have a Taptic Engine.

			return majorDeviceVersion >= 8;
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

		- (void)openScheme: (NSString *)scheme
		{
			// Get the current running Application ( Preferences ) …

			UIApplication *application = [UIApplication sharedApplication];

			// Transform the given Scheme into an URL …

			NSURL *URL = [NSURL URLWithString: scheme];

			if(@available(iOS 10, *))
			{
				[application openURL: URL options: @{} completionHandler: nil];
			}
			else
			{
				[application openURL: URL];
			}
		}

		- (void)showAlertWithTitle: (NSString *)title message: (NSString *)message
		{
			NSString *localizedAlertOK = [self -> _preferenceBundle localizedStringForKey: @"MTGeneralOK" value: @"" table: nil];

			// Show the Alert …

			UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title message: message preferredStyle: UIAlertControllerStyleAlert];

			[alertController addAction: [UIAlertAction actionWithTitle: localizedAlertOK style: UIAlertActionStyleDefault handler: nil]];

			[self presentViewController: alertController animated: YES completion: nil];
		}

	#pragma mark -
	#pragma mark Public Methods - Table

		- (void)dismissKeyboard
		{
			[self.view endEditing: YES];
		}

	#pragma mark -
	#pragma mark Public Methods

		- (void)cleanUpArtworks: (PSSpecifier *)sender
		{
			[self cleanUpCacheWithSpecifier: sender alertMessageID: @"CCCacheAlertMessage" onlyOrphaned: NO cancelHandler: nil];
		}

		- (void)cleanUpOrphanedArtworks: (PSSpecifier *)sender
		{
			[self cleanUpCacheWithSpecifier: sender alertMessageID: @"CCCacheAlertOrphanedArtworksMessage" onlyOrphaned: YES cancelHandler: nil];
		}

		// Open Links associated to Preference-Cells with the Custom Class `MTContactCell` …

		- (void)open: (PSSpecifier *)sender
		{
			// Send haptic Feedback …

			[MTCoreHaptic triggerFeedbackWithValue: MTCoreHapticFeedbackStyleLight value: CCPrefsHapticFeedbackValue];

			// Determine, if we can open GitHub-Links in an App …

			if([[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString: @"ioc:"]])
			{
				// … if so, change the Protocol-Part …

				NSString *urlString = [[sender propertyForKey: @"url"] stringByReplacingOccurrencesOfString: @"https" withString: @"ioc"];

				// … and open the Link in GitHub.

				[self openScheme: urlString];
			}
			else
			{
				// … otherwise open Safari.

				[self openScheme: [sender propertyForKey: @"url"]];
			}
		}

		- (void)setBackgroundImage: (PSSpecifier *)sender
		{
			// Pick a Photo from Photo Library …

			if([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary])
			{
				// Send haptic Feedback …

				[MTCoreHaptic triggerFeedbackWithValue: MTCoreHapticFeedbackStyleLight value: CCPrefsHapticFeedbackValue];

				// Create a new Image Picker …

				UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];

				imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
				imagePicker.delegate = self;

				// Show the Image Picker …

				[self presentViewController: imagePicker animated: YES completion: nil];
			}
			else
			{
				NSString *localizedAlertTitle = [self -> _preferenceBundle localizedStringForKey: @"CCBackgroundStylePhotoAlertTitle" value: @"" table: nil];
				NSString *localizedAlertMessage = [self -> _preferenceBundle localizedStringForKey: @"CCBackgroundStylePhotoAlertMessage" value: @"" table: nil];

				// Send haptic Feedback …

				[MTCoreHaptic triggerFeedbackWithValue: MTCoreHapticFeedbackStyleError value: CCPrefsHapticFeedbackValue];

				// Show an Alert, that we can't access the Photo Library …

				[self showAlertWithTitle: localizedAlertTitle message: localizedAlertMessage];
			}
		}

		- (void)showOpenSourceNotices: (PSSpecifier *)sender
		{
			NSString *openSourceNotices = [self -> _preferenceBundle.bundlePath stringByAppendingPathComponent: @"OpenSource.txt"];

			// If an Error occurs, we can provide more Details in `MTLog` about it …

			NSError *error = nil;

			// Get the Open Source Notices from our Preference Bundle …

			NSString *contents = [NSString stringWithContentsOfFile: openSourceNotices encoding: NSUTF8StringEncoding error: &error];

			if(!contents)
			{
				NSString *localizedAlertTitle = [self -> _preferenceBundle localizedStringForKey: @"CCOpenSourceAlertTitle" value: @"" table: nil];
				NSString *localizedAlertMessage = [NSString stringWithFormat: [self -> _preferenceBundle localizedStringForKey: @"CCOpenSourceAlertMessage" value: @"" table: nil], @"OpenSource.txt"];

				MTLog(@"An Error occured while getting the File „%@“, please see the full Details: %@", openSourceNotices, error);

				// Send haptic Feedback …

				[MTCoreHaptic triggerFeedbackWithValue: MTCoreHapticFeedbackStyleError value: CCPrefsHapticFeedbackValue];

				// Show an Alert, that "OpenSource.txt" wasn't found …

				[self showAlertWithTitle: localizedAlertTitle message: localizedAlertMessage];

				return;
			}

			// Create a Text View with monospaced Font, justified and no editable Text …

			UITextView *textView = [[UITextView alloc] init];

			textView.textAlignment = NSTextAlignmentJustified;
			textView.textContainerInset = UIEdgeInsetsMake(10.0, 4.0, 10.0, 4.0);

			textView.font = [UIFont fontWithName: @"Menlo-Regular" size: 10.0];
			textView.text = contents;

			textView.alwaysBounceVertical = YES;
			textView.editable = NO;

			// Create a new View Controller for the Text View …

			UIViewController *controller = [[MTTintedViewController alloc] init];

			// … and set it's Title.

			NSString *localizedOpenSourceLabel = [self -> _preferenceBundle localizedStringForKey: @"CCOpenSourceLabel" value: @"" table: nil];

			controller.title = localizedOpenSourceLabel;
			controller.view = textView;

			// Don't lay the View out underneath the Navigation Bar - this makes the Navigation Controller Size / Position the pushed View to start right below it, instead of relying on automatic Inset Math.

			controller.edgesForExtendedLayout = UIRectEdgeNone;

			// Now open up the niew View Controller …

			[self.navigationController pushViewController: controller animated: YES];
		}

		- (void)visitWebsite: (id)sender
		{
			// Send haptic Feedback …

			[MTCoreHaptic triggerFeedbackWithValue: MTCoreHapticFeedbackStyleLight value: CCPrefsHapticFeedbackValue];

			// Open Safari …

			[self openScheme: @"https://macthemes.me/"];
		}

		- (void)visitTwitter: (id)sender
		{
			// Send haptic Feedback …

			[MTCoreHaptic triggerFeedbackWithValue: MTCoreHapticFeedbackStyleLight value: CCPrefsHapticFeedbackValue];

			// Determine, if we can open Twitter-Links in an App …

			if ([[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString:@"twitter:"]])
			{
				// … if so, change the Protocol-Part and open the Link in Twitter.

				[self openScheme: @"twitter://user?screen_name=iMacThemes"];
			}
			else
			{
				// … otherwise open Safari.

				[self openScheme: @"https://mobile.twitter.com/iMacThemes"];
			}
		}

@end
