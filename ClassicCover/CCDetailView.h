/*
	CCDetailView.h
	ClassicCover

	Created by c0ldra1n on 9/2/17; Updated by MacThemes on 9/28/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import <UIKit/UIKit.h>

#import "MarqueeLabel/MarqueeLabel.h"

@class CCAlbumArtView;

@interface CCDetailView: UIView

	// The whole Album Art View …

	@property (strong, nonatomic) CCAlbumArtView *albumArtView;

	// The Background …

	@property (strong, nonatomic) IBOutlet UIImageView *backgroundArtwork;

	// The Container holding the Artwork-Image and Album-Detail-Labels …

	@property (strong, nonatomic) IBOutlet UIView *barView;

	// The Height Constraint of our Container holding the Artwork-Image and Album-Detail-Labels …

	@property (strong, nonatomic) IBOutlet NSLayoutConstraint *barViewHeightConstraint;

	// Our Artwork-Image, Artist-, Album-, Genre- and Duration-Labels …

	@property (strong, nonatomic) IBOutlet UIImageView *artwork;

	@property (strong, nonatomic) IBOutlet MarqueeLabel *artistLabel;
	@property (strong, nonatomic) IBOutlet MarqueeLabel *albumLabel;
	@property (strong, nonatomic) IBOutlet MarqueeLabel *genreLabel;
	@property (strong, nonatomic) IBOutlet MarqueeLabel *durationLabel;

	// The Table View, where our Tracks are listed …

	@property (strong, nonatomic) IBOutlet UITableView *trackTable;

@end
