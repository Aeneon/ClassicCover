/*
	CCDetailViewController.h
	ClassicCover

	Created by c0ldra1n on 9/2/17; Updated by MacThemes on 11/3/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>

#import "CCDetailView.h"

@interface CCDetailViewController: UIViewController <UITableViewDataSource, UITableViewDelegate>

	// Our Media Collection for the current Album …

	@property (strong, nonatomic) MPMediaItemCollection *album;

	// The whole Album Detail View …

	@property (strong, nonatomic) CCDetailView *view;

	// Our System Music Player …

	@property (strong, nonatomic) MPMusicPlayerController *musicPlayer;

	// Registers and removes the Notification Observers that keep the Now-Playing Indicator in Sync while this Screen is visible …

	- (void)beginObservingNowPlayingChanges;
	- (void)endObservingNowPlayingChanges;

	// Update our Now Playing Indicator …

	- (void)updateNowPlayingIndicator;

@end
