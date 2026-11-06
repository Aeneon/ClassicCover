/*
	Tweak_UIKit.xm
	ClassicCover

	Created by c0ldra1n on 3/5/17; Updated by MacThemes on 10/27/26.
	Copyright © 2017 c0ldra1n & © 2026 MacThemes. All rights reserved.
*/

#import "Tweak_UIKit.h"

#import "CydiaSubstrate/CydiaSubstrate.h"

#import "../../MTCoreLogic.h"

// The ClassicCover Bundle …

static NSBundle *CCBundle;

// Our View Controller …

static UIViewController *CCViewController;

// Should we disable ClassicCover on Now Playing View Controller ?

static BOOL CCForceDisable = NO;

// Was ClassicCover's View presented for the first Time ?

static BOOL CCPresented = NO;

#pragma mark -
#pragma mark Helpers

	// Is this an iPhone or an iPod touch ?

	static BOOL CCIsPhone(void)
	{
		return [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad;
	}

	// Is the Interface currently in Landscape ? The Status Bar Orientation is reliable right at Launch, whereas `[UIDevice currentDevice].orientation` may still be `Unknown` / `FaceUp` or `FaceDown` …

	static BOOL CCInterfaceIsLandscape(void)
	{
		return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
	}

	// Present ClassicCover on Top of the given Host, if it's not already visible …

	static void CCPresentIfNeeded(UIViewController *host)
	{
		if(CCPresented || !CCViewController || host.presentedViewController || CCViewController.presentingViewController)
		{
			return;
		}

		host.view.alpha = 0.0;

		UIStatusBar *statusBar = MSHookIvar<UIStatusBar *>([UIApplication sharedApplication], "_statusBar");

		statusBar.foregroundColor = [UIColor whiteColor];

		[host presentViewController: CCViewController animated: YES completion: ^
		{
			CCPresented = YES;
		}];
	}

#pragma mark -
#pragma mark Hooks - ClassicCover

	%group ClassicCover

		%hook UIApplication

			- (UIInterfaceOrientationMask)supportedInterfaceOrientationsForWindow: (UIWindow *)window
			{
				return CCIsPhone() ? UIInterfaceOrientationMaskAllButUpsideDown : %orig();
			}

		%end

		%hook MusicTabBarController

			- (void)loadView
			{
				%orig();
			}

			- (void)viewDidLoad
			{
				%orig();

				// Load our Bundle, if it's not already loaded …

				if(!CCBundle.loaded)
				{
					[CCBundle load];
				}

				// Load the Storyboard …

				@try
				{
					CCViewController = [[UIStoryboard storyboardWithName: @"ClassicCover" bundle: CCBundle] instantiateInitialViewController];
				}
				@catch(NSException *exception)
				{
					MTLog(@"Loading Storyboard failed with Error „%@“. Details: %@.", exception.name, exception.reason);
				}

				// Now let's set the Presentation-Style for our View Controller …

				CCViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
				CCViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
			}

			// If the App is launched ( or returns ) while the Device is already in Landscape, there's no Rotation. Catch this Case here, where the View is guaranteed to be in the Window …

			- (void)viewDidAppear: (BOOL)animated
			{
				%orig();

				if(CCForceDisable || !CCInterfaceIsLandscape())
				{
					return;
				}

				CCPresentIfNeeded(self);
			}

			- (void)viewWillTransitionToSize: (CGSize)size withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator
			{
				%orig();

				if(CCForceDisable)
				{
					return;
				}

				MTLog(@"View will Transition to Size …");

				[coordinator animateAlongsideTransition: ^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context)
				{
					if(UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
					{
						if(!CCPresented)
						{
							[self view].alpha = 0.0;

							UIStatusBar *statusBar = MSHookIvar<UIStatusBar *>([UIApplication sharedApplication], "_statusBar");

							statusBar.foregroundColor = [UIColor whiteColor];

							[self presentViewController: CCViewController animated: true completion: ^
							{
								CCPresented = YES;
							}];
						}
					}
					else
					{
						if(CCPresented)
						{
							[self view].alpha = 1.0;

							UIStatusBar *statusBar = MSHookIvar<UIStatusBar *>([UIApplication sharedApplication], "_statusBar");

							statusBar.foregroundColor = nil;

							[CCViewController dismissViewControllerAnimated: true completion: ^
							{
								CCPresented = NO;
							}];
						}
					}
				} completion: ^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {}];
			}

			- (UIStatusBarStyle)preferredStatusBarStyle
			{
				if(CCPresented)
				{
					return UIStatusBarStyleLightContent;
				}
				else
				{
					return %orig();
				}
			}

			- (BOOL)prefersStatusBarHidden
			{
				return CCIsPhone();
			}

			- (BOOL)shouldAutorotate
			{
				return true;
			}

			- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
			{
				return true;
			}

			- (UIInterfaceOrientationMask)supportedInterfaceOrientations
			{
				return UIInterfaceOrientationMaskAllButUpsideDown;
			}

		%end

	%end

#pragma mark -
#pragma mark Hooks - Now Playing View

	%group ClassicCover_NowPlaying

		%hook MusicNowPlayingViewController

			- (void)viewDidAppear: (BOOL)animated
			{
				%orig();

				CCForceDisable = true;
			}

			- (void)viewDidDisappear: (BOOL)animated
			{
				%orig();

				CCForceDisable = false;
			}

			- (BOOL)shouldAutorotate
			{
				return CCIsPhone() ? false : %orig();
			}

			- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
			{
				return CCIsPhone() ? false : %orig();
			}

			- (UIInterfaceOrientationMask)supportedInterfaceOrientations
			{
				return CCIsPhone() ? UIInterfaceOrientationPortrait : %orig();
			}

		%end

	%end

#pragma mark -
#pragma mark Hooks - Constructor

	%ctor
	{
		Class MusicTabBarController_Class;

		/*
			┌───────┬────────────────┐
			│  iOS  │ CoreFoundation │
			├───────┼────────────────┤
			│ 9.0	│ 1240.1		 │
			│ 9.1	│ 1241.11		 │
			│ 9.2	│ 1242.13		 │
			│ 9.3	│ 1280.30		 │
			│ 10.0	│ 1348.00		 │
			│ 10.1	│ 1348.00		 │
			│ 10.2	│ 1348.22		 │
			│ 10.3	│ 1349.56		 │
			│ 11.0	│ 1443.00		 │
			│ 11.1	│ 1445.32		 │
			│ 11.2	│ 1450.14		 │
			│ 11.3	│ 1452.23		 │
			│ 11.4	│ 1452.23		 │
			│ 12.0	│ 1556.00		 │
			│ 12.1	│ 1560.10		 │
			│ 12.2	│ 1570.15		 │
			│ 12.3	│ 1575.13		 │
			│ 12.4	│ 1575.17		 │
			│ 12.5	│ 1575.23		 │
			│ 13.0	│ 1665.15		 │
			│ 13.1	│ 1671.101		 │
			│ 13.2	│ 1673.126		 │
			│ 13.3	│ 1674.102		 │
			│ 13.4	│ 1675.129		 │
			│ 13.5	│ 1676.104		 │
			│ 14.0	│ 1751.108		 │
			│ 14.1	│ 1751.108		 │
			│ 14.2	│ 1770.106		 │
			│ 14.3	│ 1770.300		 │
			│ 14.4	│ 1774.101		 │
			│ 14.5	│ 1775.118		 │
			│ 14.6	│ 1776.103		 │
			│ 14.7	│ 1777.103		 │
			│ 14.8	│ 1778.101		 │
			└───────┴────────────────┘
		*/

		if(kCFCoreFoundationVersionNumber >= 1665.15) // iOS 13 and later …
		{
			MusicTabBarController_Class = NSClassFromString(@"MusicApplication.TabBarController");
		}
		else if(kCFCoreFoundationVersionNumber >= 1556.00) // iOS 12 and later …
		{
			MusicTabBarController_Class = NSClassFromString(@"Music.TabBarController");
		}
		else if(kCFCoreFoundationVersionNumber >= 1348.00) // iOS 10 and later …
		{
			MusicTabBarController_Class = NSClassFromString(@"Music.RootViewController");
		}
		else // iOS 9 and below …
		{
			MusicTabBarController_Class = %c(MusicTabBarController);
		}

		// Load ClassicCover's Bundle …

		CCBundle = [NSBundle bundleWithPath: CCFileManagerBundle];

		[CCBundle load];

		// If we're not running on iOS 11 or iOS 12 or if this is an iPad …

		if(kCFCoreFoundationVersionNumber < 1443.00 || kCFCoreFoundationVersionNumber >= 1665.15 || [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
		{
			// … add some Additions for iOS 10 and later …

			if(kCFCoreFoundationVersionNumber >= 1348.00)
			{
				Class MusicNowPlayingViewController_Class = (kCFCoreFoundationVersionNumber >= 1665.15) ? NSClassFromString(@"MusicApplication.NowPlayingViewController") : NSClassFromString(@"Music.NowPlayingViewController");

				%init(ClassicCover_NowPlaying, MusicNowPlayingViewController = MusicNowPlayingViewController_Class);
			}

			// … and initialize ClassicCover.

			%init(ClassicCover, MusicTabBarController = MusicTabBarController_Class);
		}
	}
