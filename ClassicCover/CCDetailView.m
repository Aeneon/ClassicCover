/*
	CCDetailView.m
	ClassicCover

	Created by c0ldra1n on 9/2/17; Updated by MacThemes on 9/28/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import "CCDetailView.h"

#import "../MTCoreLogic.h"

#import "CCAlbumArtView.h"

@interface CCDetailView()
{
	CALayer *_separator;
}
@end

@implementation CCDetailView

	#pragma mark -
	#pragma mark Lifecycle

		- (void)awakeFromNib
		{
			[super awakeFromNib];

			// Draw the Highlight at the Bottom …

			[self drawHighlight];

			// Flip the Album Art View by a Tap …

			UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(flipSuperView)];

			[self.barView addGestureRecognizer: tapGesture];
		}

		- (void)didMoveToSuperview
		{
			[super didMoveToSuperview];

			for(UIView *subview in self.trackTable.subviews)
			{
				if([NSStringFromClass([subview class]) isEqualToString: @"UITableViewWrapperView"])
				{
					subview.frame = CGRectMake(0.0, 0.0, self.trackTable.bounds.size.width, self.trackTable.bounds.size.height);
				}
			}
		}

	#pragma mark -
	#pragma mark Private Methods

		- (void)layoutSubviews
		{
			[super layoutSubviews];

			// If our CALayer for the bottom Highlight exists …

			if(self -> _separator)
			{
				CGFloat scale = [UIScreen mainScreen].scale;
				CGFloat pixel = 1.0 / scale;

				CGFloat width = CGRectGetWidth(self.barView.bounds);
				CGFloat height = CGRectGetHeight(self.barView.bounds);

				CGFloat bottomY = height - pixel;

				// … alter it's Size to reflect Parent's new Bounds.

				self -> _separator.frame = CGRectMake(0.0, bottomY, width, pixel);
			}
		}

		- (void)drawHighlight
		{
			// Draw the bottom Highlight …

			CGFloat scale = [UIScreen mainScreen].scale;
			CGFloat pixel = 1.0 / scale;

			CGFloat width = CGRectGetWidth(self.barView.bounds);
			CGFloat height = CGRectGetHeight(self.barView.bounds);

			CGFloat bottomY = height - pixel;

			self -> _separator = [CALayer layer];

			self -> _separator.frame = CGRectMake(0.0, bottomY, width, pixel);
			self -> _separator.backgroundColor = [UIColor whiteColor].CGColor;
			self -> _separator.opacity = CCLayerSeparatorOpacity;

			// … by using anti-aliased Edges …

			self -> _separator.edgeAntialiasingMask = kCALayerLeftEdge | kCALayerRightEdge | kCALayerBottomEdge | kCALayerTopEdge;
			self -> _separator.allowsEdgeAntialiasing = YES;
			self -> _separator.shouldRasterize = YES;
			self -> _separator.rasterizationScale = scale;

			[self.layer addSublayer: self -> _separator];
		}

		- (void)flipSuperView
		{
			[self.albumArtView flip: NO];
		}

@end
