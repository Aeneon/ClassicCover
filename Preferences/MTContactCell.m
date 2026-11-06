/*
	MTContactCell.h
	ClassicCover

	Created by MacThemes on 10/28/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import "MTContactCell.h"

#import "AutumnBoard/MTAutumnBoard.h"

@implementation MTContactCell
{
	// The ClassicCover Preference-Bundle …

	NSBundle *_preferenceBundle;

	// The Image View, Title and Sub-Title …

	UIImageView *_imageView;

	UILabel *_title;
	UILabel *_subTitle;
}

	#pragma mark -
	#pragma mark Lifecycle

		- (instancetype)initWithStyle: (UITableViewCellStyle)style reuseIdentifier: (NSString *)identifier specifier: (PSSpecifier *)specifier
		{
			self = [super initWithStyle: style reuseIdentifier: identifier specifier: specifier];

			if(self)
			{
				// Set the ClassicCover Preference-Bundle …

				_preferenceBundle = [NSBundle bundleForClass: self.class];

				// Get the Identifier from the given Preference-Specifier …

				NSString *title = [specifier propertyForKey: @"title"];

				// Localization-specific Stuff …

				NSString *localizedTitle = [self -> _preferenceBundle localizedStringForKey: [specifier propertyForKey: @"title"] value: @"" table: nil];
				NSString *localizedSubTitle = [self -> _preferenceBundle localizedStringForKey: [specifier propertyForKey: @"subTitle"] value: @"" table: nil];

				// Get the assigned Image …

				UIImage *image = [UIImage imageNamed: [specifier propertyForKey: @"image"] inBundle: self -> _preferenceBundle compatibleWithTraitCollection: nil];

				// … create a new Image View and assign the Image to it …

				self -> _imageView = [[UIImageView alloc] initWithImage: image];

				self -> _imageView.layer.masksToBounds = YES;
				self -> _imageView.translatesAutoresizingMaskIntoConstraints = NO;

				// … then add the newly created Sub View to the Content View.

				[self.contentView addSubview: self -> _imageView];

				// We can disable the User Interactions, but we need the Properties `id` and `enabled` …

				NSString *identifier = [specifier propertyForKey: @"id"];
				NSNumber *enabledValue = [specifier propertyForKey: @"enabled"];

				// Special initial State for our "Clean-Up Artworks"- and "Clean-Up orphaned Artworks"-Cells …

				BOOL isCacheButton = [identifier isEqualToString: @"CCCleanUpArtworks"] || [identifier isEqualToString: @"CCCleanUpOrphanedArtworks"];

				BOOL enabled = enabledValue ? [enabledValue boolValue] : !isCacheButton;

				self.userInteractionEnabled = enabled;

				// Let's create a Title-Label, …

				self -> _title = [UILabel new];

				self -> _title.alpha = enabled ? 1.0 : 0.5;
				self -> _title.font = [UIFont systemFontOfSize: 15.0];
				self -> _title.text = localizedTitle;
				self -> _title.translatesAutoresizingMaskIntoConstraints = NO;

				// … initialize the Theming Engine for Buttons that require a custom Tint Color, …

				if([title isEqualToString: @"CCCacheArtworksTitle"] || [title isEqualToString: @"CCCacheOrphanedArtworksTitle"])
				{
					MTAutumnBoard *autumnBoard = [MTAutumnBoard sharedInstance];

					// … and if the Title-Property equals the given Label, set the Tint Color we want to use.

					if([title isEqualToString: @"CCCacheArtworksTitle"])
					{
						self -> _title.textColor = [autumnBoard buttonArtworkCache];
					}
					else
					{
						self -> _title.textColor = [autumnBoard buttonOrphanedArtworks];
					}
				}

				// … add them to the Content View, …

				[self.contentView addSubview: self -> _title];

				// … create - the last Step - a Sub-Title-Label …

				self -> _subTitle = [UILabel new];

				self -> _subTitle.alpha = enabled ? 1.0 : 0.5;
				self -> _subTitle.font = [UIFont systemFontOfSize: 11.0];
				self -> _subTitle.text = localizedSubTitle;
				self -> _subTitle.textColor = UIColor.systemGrayColor;
				self -> _subTitle.translatesAutoresizingMaskIntoConstraints = NO;

				// … and add them to our Content View too.

				[self.contentView addSubview: self -> _subTitle];

				// Activate the Constraints for the created Controls …

				[NSLayoutConstraint activateConstraints:
				@[
					[self -> _imageView.centerYAnchor constraintEqualToAnchor: self.centerYAnchor],
					[self -> _imageView.leadingAnchor constraintEqualToAnchor: self.leadingAnchor constant: 15.0],
					[self -> _imageView.heightAnchor constraintEqualToConstant: 40.0],
					[self -> _imageView.widthAnchor constraintEqualToConstant: 40.0],

					[self -> _title.topAnchor constraintEqualToAnchor: self.centerYAnchor constant: -19.5],
					[self -> _title.leadingAnchor constraintEqualToAnchor: self -> _imageView.trailingAnchor constant: 10.0],
					[self -> _title.heightAnchor constraintEqualToConstant: 20.0],

					[self -> _subTitle.bottomAnchor constraintEqualToAnchor: self.centerYAnchor constant: 19.5],
					[self -> _subTitle.leadingAnchor constraintEqualToAnchor: self -> _imageView.trailingAnchor constant: 10.0],
					[self -> _subTitle.heightAnchor constraintEqualToConstant: 20.0],
				]];
			}

			return self;
		}

	#pragma mark -
	#pragma mark Private Methods

		- (void)updateEnabledStateWithSpecifier: (PSSpecifier *)specifier
		{
			// If there's the Key `enabled` set, use this One, otherwise set the Default Value …

			NSNumber *enabledValue = [specifier propertyForKey: @"enabled"];

			BOOL enabled = enabledValue ? [enabledValue boolValue] : YES;

			// Alter the Opacity of our Labels, if necessary, the Image will be left as it is …

			CGFloat alpha = enabled ? 1.0 : 0.5;

			if(self -> _title.alpha != alpha)
			{
				self -> _title.alpha = alpha;
			}

			if(self -> _subTitle.alpha != alpha)
			{
				self -> _subTitle.alpha = alpha;
			}

			// … and change the User Interactions Property, if necessary too.

			if(self.userInteractionEnabled != enabled)
			{
				self.userInteractionEnabled = enabled;
			}
		}

		- (void)refreshSubTitleWithSpecifier: (PSSpecifier *)specifier
		{
			// Refresh the Subtitle without forcing a Layout Pass …

			NSString *localizedSubTitle = [self -> _preferenceBundle localizedStringForKey: [specifier propertyForKey: @"subTitle"] value: @"" table: nil];

			if(![self -> _subTitle.text isEqualToString: localizedSubTitle])
			{
				self -> _subTitle.text = localizedSubTitle;
			}

			// The Cache Update may also have changed the Cell's Enabled-State …

			[self updateEnabledStateWithSpecifier: specifier];
		}

@end
