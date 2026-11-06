/*
	MTTintedViewController.m
	AutumnBoard

	Created by MacThemes on 9/28/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import "MTTintedViewController.h"
#import "MTAutumnBoard.h"

@implementation MTTintedViewController

	#pragma mark -
	#pragma mark Lifecycle

		- (void)viewWillAppear: (BOOL)animated
		{
			[super viewWillAppear: animated];

			// Allocate and initialize Theming Engine …

			MTAutumnBoard *autumnBoard = [MTAutumnBoard sharedInstance];

			// Set the Tint Color …

			self.view.tintColor = [autumnBoard generalWindow];

			// Set the Navigation Bar's Tint Color using the assigned Color …

			self.navigationController.navigationController.navigationBar.tintColor = [autumnBoard generalNavigationBar];
		}

@end
