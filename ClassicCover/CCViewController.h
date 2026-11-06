/*
	CCViewController.h
	ClassicCover

	Created by c0ldra1n on 3/5/17; Updated by MacThemes on 11/4/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>

#import "iCarousel/iCarousel.h"
#import "MarqueeLabel/MarqueeLabel.h"
#import "ReflectionView/ReflectionView.h"

#import "CCAlbumArtView.h"

typedef NS_ENUM(NSUInteger, CCJumpDirection)
{
	CCJumpDirectionBack = -1,
	CCJumpDirectionNone = 0,
	CCJumpDirectionForward = 1
};

@interface CCViewController: UIViewController <iCarouselDelegate, ReflectionViewDelegate, CCAlbumArtViewDelegate, UIGestureRecognizerDelegate>

	// Our System Music Player …

	@property (strong, nonatomic) MPMusicPlayerController *musicPlayer;

	// Our View for the Background Wallpaper …

	@property (retain, nonatomic) IBOutlet UIImageView *backgroundWallpaper;

	// The Dark Overlay above the Background Wallpaper …

	@property (retain, nonatomic) IBOutlet UIView *overlayView;

	// The Heart of ClassicCover: iCarousel …

	@property (retain, nonatomic) IBOutlet iCarousel *carouselView;

	// Our Play/Pause-Button …

	@property (retain, nonatomic) IBOutlet UIButton *playPauseButton;

	// Our Buttons for skipping Tracks, they are only visible, while the Album Detail View is shown …

	@property (retain, nonatomic) IBOutlet UIButton *previousTrackButton;
	@property (retain, nonatomic) IBOutlet UIButton *nextTrackButton;

	// The Labels for showing Album Informations, such as Album Name and Artist …

	@property (retain, nonatomic) IBOutlet MarqueeLabel *topLabel;
	@property (retain, nonatomic) IBOutlet MarqueeLabel *bottomLabel;

	// Our Buttons for Shuffle and Repeat, they are only visible, while the Album Detail View is shown, too …

	@property (retain, nonatomic) IBOutlet UIButton *shuffleButton;
	@property (retain, nonatomic) IBOutlet UIButton *repeatButton;

	// The leading and trailing Constraints of our iCarousel-View …

	@property (retain, nonatomic) IBOutlet NSLayoutConstraint *carouselLeadingConstraint;
	@property (retain, nonatomic) IBOutlet NSLayoutConstraint *carouselTrailingConstraint;

	// The leading Constraint of our Play/Pause-Button …

	@property (retain, nonatomic) IBOutlet NSLayoutConstraint *playPauseLeadingConstraint;

	// The leading Constraint of our Next-Track-Button …

	@property (retain, nonatomic) IBOutlet NSLayoutConstraint *nextTrackLeadingConstraint;

	// The bottom Constraint of our bottom Album-Information-Label …

	@property (retain, nonatomic) IBOutlet NSLayoutConstraint *bottomLabelBottomConstraint;

@end
