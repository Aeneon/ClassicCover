/*
	CCAlbumArtView.h
	ClassicCover

	Created by c0ldra1n on 8/26/17; Updated by MacThemes on 10/27/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

#import "ReflectionView/ReflectionView.h"

#import "CCDetailViewController.h"

@class CCAlbumArtView;

	@protocol CCAlbumArtViewDelegate <NSObject>

		@required

		- (void)albumArtView: (CCAlbumArtView *)view didFlip: (BOOL)flipVisible;
		- (void)albumArtView: (CCAlbumArtView *)view willFlip: (BOOL)flipVisible;

	@end

	@interface CCAlbumArtView: UIView <CAAnimationDelegate>
	{
		UIView *_contentView;
	}

	// Our Delegate …

	@property id<CCAlbumArtViewDelegate> delegate;

	// Our Media Collection for the current Album …

	@property MPMediaItemCollection *album;

	// Our Artwork-Image and it's Reflection …

	@property UIImageView *artworkView;
	@property ReflectionView *reflectionView;

	// The Container View, which holds the Flip View and creates a nice and beautiful Shadow around it …

	@property UIView *flipViewContainer;

	// The Flip View, where our Tracks are listed …

	@property CCDetailView *flipView;
	@property CCDetailViewController *flipViewController;

	// Flip between Cover ( and Reflection ) and the Album Detail View …

	- (void)flip: (BOOL)flag;

	// Reset the View, so we can use them for another Time …

	- (void)prepareForReuse;

	// Set the View's Alpha, depending if it's active or not …

	- (void)setActiveAnimated: (BOOL)active;

@end
