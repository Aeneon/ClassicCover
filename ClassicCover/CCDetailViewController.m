/*
	CCDetailViewController.m
	ClassicCover

	Created by c0ldra1n on 9/2/17; Updated by MacThemes on 11/3/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import "CCDetailViewController.h"

#import "../MTCoreHaptic.h"
#import "../MTCoreLogic.h"

#import "CCBundle.h"

#import "CCDetailViewTableCell.h"

#import "MediaRemote.h"

#import "UIImage+Graphics.h"

@interface CCDetailViewController()
{
	UIImage *_artwork;

	// One Entry per Disc, in ascending Disc-Number Order. Each Entry is the ordered Array of `MPMediaItems` on that Disc …

	NSArray<NSArray<MPMediaItem *> *> *_discSections;
	NSArray<NSNumber *> *_discNumbers;

	// The Count of Discs in the current Album …

	NSUInteger _discCount;

	// The `indexPath` of the Row currently representing `MPMusicPlayerController`'s `nowPlayingItem`, if that Item belongs to this Album - nil otherwise …

	NSIndexPath *_nowPlayingIndexPath;

	// Guard against double-registering / -removing Observers …

	BOOL _isObservingNowPlayingChanges;

	// Is currently Music playing ?

	BOOL _isPlaybackActive;

	// Should we update the Now-Playing-Indicator ?

	BOOL _nowPlayingUpdatePending;
	BOOL _nowPlayingRefreshAgain;

	NSUInteger _nowPlayingGeneration;

	// The Track Index Paths of our Album …

	NSDictionary<NSNumber *, NSIndexPath *> *_trackIndexPaths;
}
@end

@implementation CCDetailViewController

	// `view` is redeclared in the Header with a more specific Type ( `CCDetailView *` instead of `UIViewController`'s own `UIView *` ), purely so Call Sites don't need to cast `self.view` everywhere …

	@dynamic view;

	#pragma mark -
	#pragma mark Lifecycle

		- (void)viewDidLoad
		{
			[super viewDidLoad];

			self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];

			// Create a new Dispatch Queue ( if not exists ) to which we can submit Blocks …

			if(!CCControlQueue)
			{
				CCControlQueue = dispatch_queue_create("com.macthemes.classiccover.media.control", nil);
			}

			// Check, if we're running on an iPad …

			BOOL isiPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;

			// Increase the Album Label's Font Size a bit, if we're running on an iPad …

			self.view.albumLabel.font = [UIFont systemFontOfSize: (isiPad ? 20.0 : 18.0)];

			// Set Trailing Buffer for Album- and Artist-Labels …

			self.view.albumLabel.trailingBuffer = MIN(CCMarqueeLabelTrailingBufferMinimum, self.view.albumLabel.bounds.size.width / 4.0);
			self.view.artistLabel.trailingBuffer = MIN(CCMarqueeLabelTrailingBufferMinimum, self.view.artistLabel.bounds.size.width / 4.0);

			// Set Album Name and Artist …

			self.view.albumLabel.text = [self.album representativeItem].albumTitle;
			self.view.artistLabel.text = [self.album representativeItem].albumArtist;

			// If we're running on iPad, set the Artwork Size, we want to use, …

			CGSize artworkSize = isiPad ? CGSizeMake(120.0, 120.0) : CGSizeMake(60.0, 60.0);

			// … set Bar View's Height by the half of the Artwork Size, …

			self.view.barViewHeightConstraint.constant = artworkSize.height;

			// … so it fits two new Labels: One for the Genre, the other One for the Track Cound and Album Duration, otherwise hide the Labels.

			self.view.genreLabel.hidden = !isiPad;
			self.view.durationLabel.hidden = !isiPad;

			// Now we know, if we're running on an iPad …

			if(isiPad)
			{
				// … get Genre and Year of the representative Media-Item, …

				NSString *genre = [self.album representativeItem].genre;
				NSNumber *year = [[self.album representativeItem] valueForProperty: @"year"] ;

				// … by collecting only the Parts that are actually available, …

				NSMutableArray<NSString *> *parts = [NSMutableArray array];

				if(genre.length > 0)
				{
					[parts addObject: genre];
				}

				if(year.integerValue > 0)
				{
					[parts addObject: [NSString stringWithFormat: @"%ld", (long)year.integerValue]];
				}

				// … join them ( one Part → no Separator, two Parts → "Genre • Year" ) …

				NSString *formattedGenreAndReleaseYear = [parts componentsJoinedByString: @" • "];

				// … and set the Label. The String will be empty, if neither is available.

				self.view.genreLabel.text = formattedGenreAndReleaseYear;

				// Now let's get the Track Count and the full Playtime Duration of the Album …

				NSString *localizedTrackCountPlural = [CCBundle getLocalizedStringForKey: @"CCTrackCountPlural"];
				NSString *localizedTrackCountSingular = [CCBundle getLocalizedStringForKey: @"CCTrackCountSingular"];

				// With a `NSNumberFormatter` we're also getting correct looking Commas and Thousand Separators …

				NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];

				numberFormatter.formatterBehavior = NSNumberFormatterBehavior10_4;
				numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;

				NSString *formattedTrackCount = [NSString stringWithFormat: (self.album.items.count == 1 ? localizedTrackCountSingular : localizedTrackCountPlural), [numberFormatter stringFromNumber: @(self.album.items.count)]];

				// That was the easy Part. Let's get the Playtime Duration, …

				NSTimeInterval fullPlaytimeDuration = [[self.album.items valueForKeyPath: @"@sum.playbackDuration"] doubleValue];;

				// … format it nicely to Hours and Minutes, …

				NSDateComponentsFormatter *dateFormatter = [[NSDateComponentsFormatter alloc] init];

				dateFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
				dateFormatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute;
				dateFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropAll;

				NSString *formattedDuration = [NSString stringWithFormat: @"%@ %@", [CCBundle getLocalizedStringForKey: @"CCDuration"], [dateFormatter stringFromTimeInterval: fullPlaytimeDuration]];

				// … and add the Track Count, we got above.

				self.view.durationLabel.text = [NSString stringWithFormat: @"%@, %@", formattedTrackCount, formattedDuration];
			}

			// Get the Album Artwork …

			self -> _artwork = [self.album.representativeItem.artwork imageWithSize: artworkSize];

			if(!self -> _artwork)
			{
				MPMediaItem *representativeItem = self.album.representativeItem;

				// Log the Entity Identifier with dedicated Informations, such as Title, Artist and Album Title …

				MTLog(@"No Artwork assigned to „%@ – %@“ in Album „%@“ with ID: %llu.", representativeItem.title, representativeItem.artist, representativeItem.albumTitle, representativeItem.persistentID);

				// … if we don't have one, use our Fallback-Image.

				self -> _artwork = [CCBundle getImageNamed: @"MissingAlbumArtworkSmall"];
			}

			self.view.artwork.image = self -> _artwork;

			// Get the Radius for the Blur, which will be applied on the Image …

			CGFloat backgroundBlurRadius = MAX((self.view.frame.size.width / CCBackgroundBlurMultiplier), CCBackgroundBlurMinimum);

			// Let's blur and get the average Color of the Album Artwork, so we can use it as Background …

			self.view.backgroundArtwork.image = [self -> _artwork blurredImageWithRadius: backgroundBlurRadius];
			self.view.backgroundArtwork.backgroundColor = [self -> _artwork averageColor];

			// Build the Sections in our Table View containing the Disc Number …

			[self buildDiscSections];

			// Reload Table View's Data …

			[self.view.trackTable reloadData];

			// Hide the Separators in the Table View, since we're drawing our own …

			self.view.trackTable.separatorStyle = UITableViewCellSeparatorStyleNone;
		}

		- (void)dealloc
		{
			[self endObservingNowPlayingChanges];
		}


	#pragma mark -
	#pragma mark Memory Management

		- (void)didReceiveMemoryWarning
		{
			// Dispose of any Resources that can be recreated …

			[super didReceiveMemoryWarning];
		}

	#pragma mark -
	#pragma mark Table View

		- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
		{
			return self -> _discSections.count;
		}

		- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection: (NSInteger)section
		{
			// A Section Height of `0.0` gets silently promoted to UIKit's Default Header Height on some Versions; `0.01`` reliably collapses it for Single-Disc Albums …

			return (self -> _discSections.count > 1) ? 32.0 : 0.01;
		}

		- (NSInteger)tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section
		{
			return self -> _discSections[section].count;
		}

		- (NSString *)tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section
		{
			if(self -> _discSections.count <= 1)
			{
				return nil;
			}

			return [NSString stringWithFormat: @"Disc %1$lu of %2$lu", [self -> _discNumbers[section] unsignedLongValue], (unsigned long)self -> _discCount];
		}

		- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
		{
			CCDetailViewTableCell *cell = [tableView dequeueReusableCellWithIdentifier: @"CCDetailViewTableCell" forIndexPath: indexPath];

			// Get Disc Sections …

			NSArray<MPMediaItem *> *section = self -> _discSections[indexPath.section];

			// … and the Item in the given Section …

			MPMediaItem *item = section[indexPath.row];

			// Let's set the Title, Track Number and the Length …

			cell.trackTitleLabel.text = item.title;

			if(item.albumTrackNumber != 0)
			{
				cell.trackNumberLabel.text = [@(item.albumTrackNumber) stringValue];
			}
			else
			{
				cell.trackNumberLabel.text = @"";

				// Log the Entity Identifier with dedicated Informations, such as Title, Artist and Album Title …

				MTLog(@"No Track Number assigned to „%@ – %@“ in Album „%@“ with ID: %llu.", item.title, item.artist, item.albumTitle, item.persistentID);
			}

			cell.trackLengthLabel.text = [self formatTime: item.playbackDuration];

			// Determine, if we're on the first or last Row, so we can set our Highlight / Shadow …

			cell.isFirstRow = ([indexPath row] == 0);
			cell.isLastRow = ([indexPath row] == ([self -> _discSections[indexPath.section] count] - 1));

			// Set the Now-Playing Indicator's State - always explicitly, for every Row, so a freshly dequeued / re-used Cell never shows stale State left over from whichever Row it previously represented …

			BOOL isNowPlayingItem = [self -> _nowPlayingIndexPath isEqual: indexPath];

			cell.isNowPlayingItem = isNowPlayingItem;
			cell.isPlaybackActive = isNowPlayingItem && self -> _isPlaybackActive;

			// Return the Cell …

			return cell;
		}

		- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
		{
			// Get the Item in the given Section …

			MPMediaItem *item = self -> _discSections[indexPath.section][indexPath.row];

			// Reading Shuffle-Mode can block on IPC with `mediaserverd`, so we always fetch it on our Control Queue, off the Main Thread …

			dispatch_async(CCControlQueue, ^
			{
				// Remember the User's Shuffle-Preference, so we can restore it once our Selection has "taken" …

				MPMusicShuffleMode previousShuffleMode = self.musicPlayer.shuffleMode;

				// Shuffle re-orders the Queue as soon as it's set, which makes `setNowPlayingItem:` unreliable, so we disable it just long enough to pin Playback to the tapped Item …

				[self.musicPlayer setShuffleMode: MPMusicShuffleModeOff];

				// Set the Item Collection for the Queue ( simply a new Playlist ) …

				[self.musicPlayer setQueueWithItemCollection: self.album];

				// … and the now playing Item.

				[self.musicPlayer setNowPlayingItem: item];

				// Let the Music Play, …

				[self.musicPlayer play];

				// … send haptic Feedback …

				[MTCoreHaptic triggerFeedbackWithPreference: MTCoreHapticFeedbackStyleLight];

				// … and restore Shuffle shortly after Playback has started, once the correct Item is locked in. A short Delay avoids a Race with `play` re-picking an Item …

				dispatch_time_t safeDispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CCIntervalSafeDispatchTime * NSEC_PER_SEC));

				dispatch_after(safeDispatchTime, CCControlQueue, ^(void)
				{
					[self.musicPlayer setShuffleMode: previousShuffleMode];
				});

				// De-select the current Row after 350 Milliseconds …

				dispatch_time_t transitionDurationHalf = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CCDurationHalf * NSEC_PER_SEC));

				// Let's get back to the Main Thread with a Delay …

				dispatch_after(transitionDurationHalf, dispatch_get_main_queue(), ^(void)
				{
					[tableView deselectRowAtIndexPath: indexPath animated: YES];
				});
			});
		}

		- (UIView *)tableView: (UITableView *)tableView viewForHeaderInSection: (NSInteger)section
		{
			if(self -> _discSections.count <= 1)
			{
				return nil;
			}

			// Create a Visual Effect View, which contains a Label for our Disc Number …

			UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle: UIBlurEffectStyleDark];
			UIVisualEffectView *headerView = [[UIVisualEffectView alloc] initWithFrame: CGRectMake(0.0, 0.0, tableView.bounds.size.width, 32.0)];

			headerView.effect = blurEffect;

			// Create the Label …

			UILabel *label = [[UILabel alloc] initWithFrame: CGRectMake(16.0, 0.0, tableView.bounds.size.width - 32.0, 32.0)];

			label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			label.backgroundColor = [UIColor clearColor];
			label.textColor = [[UIColor whiteColor] colorWithAlphaComponent: 0.7];
			label.font = [UIFont boldSystemFontOfSize: 13.0];

			// … with localized Strings …

			NSString *localizedDiscNumber = [CCBundle getLocalizedStringForKey: @"CCDiscNumber"];

			label.text = [NSString stringWithFormat: localizedDiscNumber, [self -> _discNumbers[section] unsignedLongValue], (unsigned long)self -> _discCount];

			// … and add them to our Header View.

			[headerView.contentView addSubview: label];

			return headerView;
		}

	#pragma mark -
	#pragma mark Table View - Overrides

		- (void)tableView: (UITableView *)tableView didEndDisplayingCell: (UITableViewCell *)cell forRowAtIndexPath: (NSIndexPath *)indexPath
		{
			CCDetailViewTableCell *trackCell = (CCDetailViewTableCell *)cell;

			// Let's suspend the Animation of our Now-Playing-Indicator …

			trackCell.nowPlayingIndicatorView.animationSuspended = YES;
		}

		- (CGFloat)tableView: (UITableView *)tableView estimatedHeightForRowAtIndexPath: (NSIndexPath *)indexPath
		{
			return 50.0;
		}

		- (CGFloat)tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath
		{
			return 50.0;
		}

		- (BOOL)tableView: (UITableView *)tableView shouldHighlightRowAtIndexPath: (NSIndexPath *)indexPath
		{
			return YES;
		}

		- (void)tableView: (UITableView *)tableView willDisplayCell: (UITableViewCell *)cell forRowAtIndexPath: (NSIndexPath *)indexPath
		{
			CCDetailViewTableCell *trackCell = (CCDetailViewTableCell *)cell;

			// Start the Fade of our Marquee Label, if necessary …

			[trackCell.trackTitleLabel restartLabel];

			// Let's resume the Animation of our Now-Playing-Indicator …

			trackCell.nowPlayingIndicatorView.animationSuspended = !self -> _isObservingNowPlayingChanges;
		}

	#pragma mark -
	#pragma mark Now Playing

		- (NSIndexPath *)indexPathForPersistentID: (MPMediaEntityPersistentID)persistentID
		{
			return persistentID ? self -> _trackIndexPaths[@(persistentID)] : nil;
		}

		- (void)updateNowPlayingIndicator
		{
			// If we're not running in the Main Thread, …

			if(![NSThread isMainThread])
			{
				// … let's get back to them …

				dispatch_async(dispatch_get_main_queue(), ^{ [self updateNowPlayingIndicator]; });

				// … and leave here.

				return;
			}

			// If we don't observe Now Playing Changes or the Application isn't active, leave here …

			if(!self -> _isObservingNowPlayingChanges || [UIApplication sharedApplication].applicationState != UIApplicationStateActive)
			{
				return;
			}

			// If an Update for our Now-Playing-Indicator ais pendinggain, …

			if(self -> _nowPlayingUpdatePending)
			{
				// … let's refresh them at first …

				self -> _nowPlayingRefreshAgain = YES;

				// … and leave here.

				return;
			}

			self -> _nowPlayingUpdatePending = YES;
			self -> _nowPlayingRefreshAgain = NO;

			NSUInteger generation = self -> _nowPlayingGeneration;

			// Getting Playback-State can block on IPC with `mediaserverd`, so we always do it on our Control Queue, off the Main Thread …

			dispatch_async(CCControlQueue, ^
			{
				// Get the current State of the System Music Player, …

				MPMusicPlayerController *musicPlayer = [MPMusicPlayerController systemMusicPlayer];

				// … the `persistentID` of the Now Playing Item.

				MPMediaEntityPersistentID persistentID = musicPlayer.nowPlayingItem.persistentID;

				// … and the current Playback-State.

				BOOL isPlaying = musicPlayer.playbackState == MPMusicPlaybackStatePlaying;

				// Let's get back to the Main Thread …

				dispatch_async(dispatch_get_main_queue(), ^
				{
					self -> _nowPlayingUpdatePending = NO;

					// If we don't observe Now Playing Changes or the Application isn't active, leave here …

					if(!self -> _isObservingNowPlayingChanges || [UIApplication sharedApplication].applicationState != UIApplicationStateActive)
					{
						return;
					}

					// If we should refresh the Now-Playing-Indicator again, …

					if(self -> _nowPlayingRefreshAgain || generation != self -> _nowPlayingGeneration)
					{
						// … update them …

						[self updateNowPlayingIndicator];

						// … and leave here.

						return;
					}

					// Get the new Index Path for the Item …

					NSIndexPath *newIndexPath = [self indexPathForPersistentID: persistentID];
					NSIndexPath *oldIndexPath = self -> _nowPlayingIndexPath;

					// Check, if the Index Path was changed and Music isn't playing a Song …

					BOOL changed = (!(oldIndexPath == newIndexPath || [oldIndexPath isEqual: newIndexPath]) || self -> _isPlaybackActive != isPlaying);

					self -> _nowPlayingIndexPath = newIndexPath;
					self -> _isPlaybackActive = isPlaying;

					// If nothing has changed, return here …

					if(!changed)
					{
						return;
					}

					self -> _nowPlayingIndexPath = newIndexPath;

					// Only update the two visible Indicators, so Rebuilding a Row restarts it's Marquee and allocates Cells on every Play/Pause-Notification …

					if(oldIndexPath && ![oldIndexPath isEqual: newIndexPath])
					{
						CCDetailViewTableCell *oldCell = (CCDetailViewTableCell *)[self.view.trackTable cellForRowAtIndexPath: oldIndexPath];

						oldCell.isNowPlayingItem = NO;
					}

					if(newIndexPath)
					{
						CCDetailViewTableCell *newCell = (CCDetailViewTableCell *)[self.view.trackTable cellForRowAtIndexPath: newIndexPath];

						newCell.isPlaybackActive = isPlaying;
						newCell.isNowPlayingItem = YES;
					}
				});
			});
		}

	#pragma mark -
	#pragma mark Now Playing - Observation

		- (void)beginObservingNowPlayingChanges
		{
			if(!self -> _isObservingNowPlayingChanges)
			{
				self -> _isObservingNowPlayingChanges = YES;
				self -> _nowPlayingGeneration++;

				for(CCDetailViewTableCell *cell in self.view.trackTable.visibleCells)
				{
					cell.nowPlayingIndicatorView.animationSuspended = NO;
				}

				// Get the Default Notification Center …

				NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

				// We need to add our own Observers here. `beginGeneratingPlaybackNotifications` is already active for the Session's Lifetime ( started once in `CCViewController` ) …

				[notificationCenter addObserver: self selector: @selector(updateNowPlayingIndicator) name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification object: nil];
				[notificationCenter addObserver: self selector: @selector(updateNowPlayingIndicator) name: MPMusicPlayerControllerPlaybackStateDidChangeNotification object: nil];
			}
		}

		- (void)endObservingNowPlayingChanges
		{
			if(self -> _isObservingNowPlayingChanges)
			{
				self -> _isObservingNowPlayingChanges = NO;
				self -> _nowPlayingGeneration++;

				// Remove the Observers …

				[[NSNotificationCenter defaultCenter] removeObserver: self];
			}
		}

	#pragma mark -
	#pragma mark Private Methods

		- (void)buildDiscSections
		{
			NSMutableArray<NSNumber *> *discNumbers = [NSMutableArray array];
			NSMutableDictionary<NSNumber *, NSMutableArray<MPMediaItem *> *> *itemsByDisc = [NSMutableDictionary dictionary];

			NSUInteger discCount = 0;

			for(MPMediaItem *item in self.album.items)
			{
				NSNumber *discNumber = @(item.discNumber);

				discCount = MAX(discCount, item.discCount);

				NSMutableArray<MPMediaItem *> *items = itemsByDisc[discNumber];

				if(!items)
				{
					items = [NSMutableArray array];

					itemsByDisc[discNumber] = items;

					[discNumbers addObject: discNumber];
				}

				[items addObject: item];
			}

			// Sort Sections by Disc Number itself, not by first-appearance Order …

			[discNumbers sortUsingSelector: @selector(compare:)];

			NSMutableArray<NSArray<MPMediaItem *> *> *sections = [NSMutableArray array];

			for(NSNumber *discNumber in discNumbers)
			{
				[sections addObject: itemsByDisc[discNumber]];
			}

			// Fallback for Tracks with missing or wrong `discCount` Metadata: Never show a Total lower than the highest Disc Number we actually have …

			discCount = MAX(discCount, [discNumbers.lastObject unsignedIntegerValue]);

			// Set the Variables for further Use …

			self -> _discNumbers = discNumbers;
			self -> _discCount = discCount;
			self -> _discSections = sections;

			// Finds the Index Path of the given Entity Persistent ID within `_discSections` …

			NSMutableDictionary<NSNumber *, NSIndexPath *> *indexPaths = [NSMutableDictionary dictionary];

			for(NSUInteger section = 0; section < sections.count; section++)
			{
				NSArray<MPMediaItem *> *items = sections[section];

				for(NSUInteger row = 0; row < items.count; row++)
				{
					MPMediaEntityPersistentID identifier = items[row].persistentID;

					if(identifier)
					{
						indexPaths[@(identifier)] = [NSIndexPath indexPathForRow: row inSection: section];
					}
				}
			}

			self -> _trackIndexPaths = [indexPaths copy];
		}

		- (NSString *)formatTime: (NSTimeInterval) time
		{
			int minutes = floor(time / 60.0);
			int seconds = floor(time) - minutes * 60;

			return [NSString stringWithFormat: ((seconds < 10) ? @"%d:0%d" : @"%d:%d"), minutes, seconds];
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
