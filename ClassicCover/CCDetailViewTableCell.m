/*
	CCDetailViewTableCell.m
	ClassicCover

	Created by c0ldra1n on 9/2/17; Updated by MacThemes on 11/3/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import "CCDetailViewTableCell.h"

#import "../MTCoreLogic.h"

@interface CCDetailViewTableCell()
{
	// Our `CALayers` for Highlight and Shadow …

	CALayer *_highlight;
	CALayer *_shadow;
}
@end

@implementation CCDetailViewTableCell

	#pragma mark -
	#pragma mark Lifecycle

		- (void)awakeFromNib
		{
			[super awakeFromNib];

			self.opaque = NO;
			self.backgroundColor = [UIColor clearColor];

			self.selectedBackgroundView = [[UIView alloc] initWithFrame: self.bounds];
			self.selectedBackgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent: 0.3];

			// Draw the Highlight on Top and the Shadow at the Bottom …

			[self drawHighlightAndShadow];
		}

	#pragma mark -
	#pragma mark Custom Accessors

		- (void)setHighlighted: (BOOL)highlighted animated: (BOOL)animated
		{
			if(highlighted)
			{
				if(animated)
				{
					[UIView animateWithDuration: CCDurationHalf animations: ^
					{
						self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent: 0.3];
					}];
				}
				else
				{
					self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent: 0.3];
				}
			}
			else
			{
				if(animated)
				{
					[UIView animateWithDuration: (CCDurationHalf / 2.0) animations: ^
					{
						self.backgroundColor = [UIColor clearColor];
					}];
				}
				else
				{
					self.backgroundColor = [UIColor clearColor];
				}
			}
		}

		- (void)setIsFirstRow: (BOOL)isFirstRow
		{
			if(_isFirstRow != isFirstRow)
			{
				_isFirstRow = isFirstRow;

				[self -> _highlight setHidden: isFirstRow];
			}
		}

		- (void)setIsLastRow: (BOOL)isLastRow
		{
			if(_isLastRow != isLastRow)
			{
				_isLastRow = isLastRow;

				[self -> _shadow setHidden: isLastRow];
			}
		}

		- (void)setIsNowPlayingItem: (BOOL)isNowPlayingItem
		{
			_isNowPlayingItem = isNowPlayingItem;

			self.trackNumberLabel.hidden = isNowPlayingItem;
			self.nowPlayingIndicatorView.hidden = !isNowPlayingItem;

			self.trackTitleLabel.holdScrolling = !isNowPlayingItem;
			self.trackTitleLabel.trailingBuffer = MIN(CCMarqueeLabelTrailingBufferMinimum, self.trackTitleLabel.bounds.size.width / 4.0);

			if(isNowPlayingItem)
			{
				self.nowPlayingIndicatorView.playing = self.isPlaybackActive;
			}
			else
			{
				[self.trackTitleLabel shutdownLabel];
			}
		}

		- (void)setIsPlaybackActive: (BOOL)isPlaybackActive
		{
			_isPlaybackActive = isPlaybackActive;

			if(self.isNowPlayingItem)
			{
				self.nowPlayingIndicatorView.playing = isPlaybackActive;
			}
		}

		- (void)setSelected: (BOOL)selected animated: (BOOL)animated
		{
			[self setHighlighted: selected animated: animated];
		}

	#pragma mark -
	#pragma mark Private Methods

		- (void)layoutSubviews
		{
			[super layoutSubviews];

			// Set new Size for Highlight and Shadow …

			if(self -> _highlight)
			{
				CGSize size = self -> _highlight.frame.size;

				self -> _highlight.frame = CGRectMake(0.0, 0.0, self.bounds.size.width, size.height);
			}

			if(self -> _shadow)
			{
				CGPoint origin = self -> _shadow.frame.origin;
				CGSize size = self -> _shadow.frame.size;

				self -> _shadow.frame = CGRectMake(0.0, origin.y, self.bounds.size.width, size.height);
			}
		}

		- (void)drawHighlightAndShadow
		{
			// Get some basic Properties …

			CGFloat scale = [UIScreen mainScreen].scale;
			CGFloat pixel = 1.0 / scale;

			CGFloat width = CGRectGetWidth(self.bounds);

			// If we're not on the first Row of the Table …

			if(!self.isFirstRow)
			{
				// … draw the top Highlight …

				self -> _highlight = [CALayer layer];

				self -> _highlight.frame = CGRectMake(0.0, 0.0, width, pixel);
				self -> _highlight.backgroundColor = [UIColor whiteColor].CGColor;
				self -> _highlight.opacity = CCLayerHighlightOpacity;

				// … by using anti-aliased Edges.

				self -> _highlight.edgeAntialiasingMask = kCALayerLeftEdge | kCALayerRightEdge | kCALayerBottomEdge | kCALayerTopEdge;
				self -> _highlight.allowsEdgeAntialiasing = YES;
				self -> _highlight.shouldRasterize = YES;

				// Note: This is intened Behaviour, as we wan't a soft Highlight on Top …

				self -> _highlight.rasterizationScale = CCLayerRasterizationScale;

				[self.layer addSublayer: self -> _highlight];
			}

			// If we're not on the last Row of the Table …

			if(!self.isLastRow)
			{
				CGFloat height = CGRectGetHeight(self.bounds);

				CGFloat bottomY = height - (pixel * 2.0);

				// … draw the bottom Shadow …

				self -> _shadow = [CALayer layer];

				self -> _shadow.frame = CGRectMake(0.0, bottomY, width, pixel);
				self -> _shadow.backgroundColor = [UIColor blackColor].CGColor;
				self -> _shadow.opacity = CCLayerShadowOpacity;

				// … by using anti-aliased Edges.

				self -> _shadow.edgeAntialiasingMask = kCALayerLeftEdge | kCALayerRightEdge | kCALayerBottomEdge | kCALayerTopEdge;
				self -> _shadow.allowsEdgeAntialiasing = YES;
				self -> _shadow.shouldRasterize = YES;

				// Note: This is intened Behaviour, as we wan't a soft Shadow at Bottom …

				self -> _shadow.rasterizationScale = CCLayerRasterizationScale;

				[self.layer addSublayer: self -> _shadow];
			}
		}

@end
