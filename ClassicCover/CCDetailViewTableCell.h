/*
	CCDetailViewTableCell.h
	ClassicCover

	Created by c0ldra1n on 9/2/17; Updated by MacThemes on 11/3/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import <UIKit/UIKit.h>

#import "MarqueeLabel/MarqueeLabel.h"

#import "CCNowPlayingIndicatorView.h"

@interface CCDetailViewTableCell: UITableViewCell

	// Our Track-Number-, Title- and Length-Labels …

	@property (weak, nonatomic) IBOutlet CCNowPlayingIndicatorView *nowPlayingIndicatorView;

	@property (weak, nonatomic) IBOutlet UILabel *trackNumberLabel;
	@property (weak, nonatomic) IBOutlet MarqueeLabel *trackTitleLabel;
	@property (weak, nonatomic) IBOutlet UILabel *trackLengthLabel;

	// Indicate if this is the first or last Row; used for Highlight and Shadow …

	@property (nonatomic) BOOL isFirstRow;
	@property (nonatomic) BOOL isLastRow;

	// Whether this Row represents Music Player's current Now-Playing Item. If true, the Track Number is replaced by an Equalizer Indicator …

	@property (assign, nonatomic) BOOL isNowPlayingItem;

	// Whether Playback is currently active - only visually relevant while `isNowPlayingItem` is true. Toggles the Indicator between animated and static Bars …

	@property (assign, nonatomic) BOOL isPlaybackActive;

@end
