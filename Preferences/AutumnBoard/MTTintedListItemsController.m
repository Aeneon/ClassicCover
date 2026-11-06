/*
	MTTintedListItemsController.m
	AutumnBoard

	Created by MacThemes on 9/28/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import "MTTintedListItemsController.h"
#import "MTAutumnBoard.h"

@implementation MTTintedListItemsController

	#pragma mark -
	#pragma mark Lifecycle

		- (void)viewDidLoad
		{
			[super viewDidLoad];

			// Allocate and initialize Theming Engine …

			MTAutumnBoard *autumnBoard = [MTAutumnBoard sharedInstance];

			// Set the Tint Color …

			self.view.tintColor = [autumnBoard generalWindow];

			// Set the Navigation Bar's Tint Color using the assigned Color …

			self.navigationController.navigationController.navigationBar.tintColor = [autumnBoard generalNavigationBar];
		}

		- (void)viewWillDisappear: (BOOL)animated
		{
			[super viewWillDisappear: animated];

			// Reset the Navigation Bar's Tint Color …

			self.navigationController.navigationController.navigationBar.tintColor = nil;
		}

@end
