/*
	Preferences.h
	ClassicCoverPrefs

	Created by MacThemes on 11/4/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import <Foundation/Foundation.h>

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

#import <UIKit/UIKit.h>

#import <rootless.h>
#import <spawn.h>

#import "AutumnBoard/MTAutumnBoard.h"

NS_ASSUME_NONNULL_BEGIN

@interface ClassicCoverPreferencesListController: PSListController <UIPopoverPresentationControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

	@property (retain, nonatomic) UIBarButtonItem *twitterButtonItem;
	@property (retain, nonatomic) UIBarButtonItem *websiteButtonItem;

	@property (retain, nonatomic) UIViewController *popController;

	@property (retain, nonatomic) UIView *headerView;
	@property (retain, nonatomic) UIImageView *headerImageView;
	@property (retain, nonatomic) UIImageView *iconView;

	- (void)cleanUpArtworks: (PSSpecifier *)sender;
	- (void)cleanUpOrphanedArtworks: (PSSpecifier *)sender;

	- (void)open: (PSSpecifier *)sender;

	- (void)setBackgroundImage: (PSSpecifier *)sender;

	- (void)showOpenSourceNotices: (PSSpecifier *)sender;

	- (void)visitTwitter: (UIButton *)sender;
	- (void)visitWebsite: (UIButton *)sender;

@end

@interface PSSpecifier(ClassicCoverListItems)

	- (NSArray *)values;

	- (void)setValues: (NSArray *)values titles: (NSArray *)titles;

@end

NS_ASSUME_NONNULL_END
