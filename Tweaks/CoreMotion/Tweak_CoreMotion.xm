/*
	Tweak_CoreMotion.xm
	ClassicCover

	Created by MacThemes on 11/3/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import "Tweak_CoreMotion.h"

#import "../../MTCoreLogic.h"

// The ClassicCover Bundle …

static NSBundle *CCBundle;

// Should we disable ClassicCover on Now Playing View Controller ?

static BOOL CCForceDisable = NO;

// Our Object for starting and managing Motion Services …

static CMMotionManager *CCMotionManager = nil;

// Private serial Queue: Samples are evaluated off the Main Thread …

static NSOperationQueue *CCMotionQueue = nil;

// Main-Thread-Generation rejects Callbacks queued before a Stop / Restart …

static NSUInteger CCMotionGeneration = 0;

// Does ClassicCover want Updates at all ?

static BOOL CCMonitoringWanted = NO;

// Was ClassicCover's View presented for the first Time ?

static BOOL CCPresented = NO;

// The short Side of the Screen ( in Portrait-Mode, this is the Width of the Screen ) …

static CGFloat CCScreenWidth = 0.0;

// The long Side of the Screen ( in Portrait-Mode, this is the Height of the Screen ) …

static CGFloat CCScreenHeight = 0.0;

#pragma mark -
#pragma mark Helpers

	// Derive the physical Orientation from the Gravity Vector. This works regardless of what the App supports and regardless of the Rotation Lock …

	static void CCStartAccelerometerMonitoring(void)
	{
		if(!CCMonitoringWanted || CCForceDisable || [UIApplication sharedApplication].applicationState != UIApplicationStateActive)
		{
			return;
		}

		// If no Motion Manager exists …

		if(!CCMotionManager)
		{
			// … allocate a new Instance and …

			CCMotionManager = [CMMotionManager new];

			// … set the Interval to 500 Milliseconds, where the Accelerometer sends updates to the Block Handler.

			CCMotionManager.accelerometerUpdateInterval = 0.5;
		}

		// If no Motion Queue exists …

		if(!CCMotionQueue)
		{
			// … create a new Operation Queue to which we can submit Blocks.

			CCMotionQueue = [NSOperationQueue new];

			// Set the Name of the Operation Queue …

			CCMotionQueue.name = @"com.macthemes.classiccover.sensors.accelerometer";

			// … and the Maximum Number of queued Operations that can execute at the same Time.

			CCMotionQueue.maxConcurrentOperationCount = 1;
			CCMotionQueue.qualityOfService = NSQualityOfServiceUtility;
		}

		// If we don't have an Accelerometer or it isn't active, leave here …

		if(!CCMotionManager.accelerometerAvailable || CCMotionManager.accelerometerActive)
		{
			return;
		}

		// Forget the last Orientation, so the first Sample after a Restart is applied …

		CCMotionManager.accelerometerUpdateInterval = [NSProcessInfo processInfo].lowPowerModeEnabled ? 1.0 : 0.5;

		NSUInteger generation = ++CCMotionGeneration;

		// Last reported Orientation ( only touched on `CCMotionQueue` or while the Updates are stopped ) …
		
		__block UIDeviceOrientation lastOrientation = UIDeviceOrientationUnknown;

		// Starts Accelerometer-Updates on our existing private, serial Queue …

		[CCMotionManager startAccelerometerUpdatesToQueue: CCMotionQueue withHandler: ^(CMAccelerometerData *data, NSError *error)
		{
			if(!data)
			{
				return;
			}

			double x = data.acceleration.x;
			double y = data.acceleration.y;
			double z = data.acceleration.z;

			// Lying flat: Keep the current Orientation …

			if(fabs(z) > 0.8)
			{
				return;
			}

			UIDeviceOrientation orientation;

			// Get the Floating-Point absolute Value of `y` and `x`. If `y` is larger than `x` …

			if(fabs(y) >= fabs(x))
			{
				// … we can assume, that we're in Portrait-Mode. Since we don't want `UIDeviceOrientationPortraitUpsideDown`, we add another Check for Landscape-Mode.

				orientation = (y < 0) ? UIDeviceOrientationPortrait : ((x < 0) ? UIDeviceOrientationLandscapeLeft : UIDeviceOrientationLandscapeRight);
			}
			else
			{
				// … otherwise we're in Landscape-Mode.

				orientation = (x < 0) ? UIDeviceOrientationLandscapeLeft : UIDeviceOrientationLandscapeRight;
			}

			// Keep the previous orientation near a diagonal instead of repeatedly
			// rotating the whole interface when the sensor fluctuates around 45°.
			if(lastOrientation != UIDeviceOrientationUnknown && fabs(fabs(x) - fabs(y)) < 0.15) { return; }

			// Nothing changed ? Then don't wake the Main Thread at all …

			if(orientation == lastOrientation)
			{
				return;
			}

			lastOrientation = orientation;

			// Let's apply the new Orientation …

			dispatch_async(dispatch_get_main_queue(), ^
			{
				if(generation != CCMotionGeneration || !CCMonitoringWanted || CCForceDisable || [UIApplication sharedApplication].applicationState != UIApplicationStateActive) { return; }
				[[ClassicCover sharedInstance] applyOrientation: orientation];
			});
		}];

		MTLog(@"Accelerometer Monitoring started …");
	}

	static void CCStopAccelerometerMonitoring(void)
	{
		CCMotionGeneration++;
		if(CCMotionManager.accelerometerActive)
		{
			[CCMotionManager stopAccelerometerUpdates];
			[CCMotionQueue cancelAllOperations];

			MTLog(@"Accelerometer Monitoring stopped …");
		}
	}

#pragma mark -
#pragma mark Hooks - ClassicCover

	%group ClassicCover

		@implementation ClassicCover

			@synthesize hostView, orientationOld, viewController;

			__strong static id _sharedObject;

			+ (id)sharedInstance
			{
				if(!_sharedObject)
				{
					_sharedObject = [[self alloc] init];
				}

				return _sharedObject;
			}

			- (id)init
			{
				self = [super init];

				if(self != nil)
				{
					// Load our Bundle, if it's not already loaded …

					if(!CCBundle.loaded)
					{
						[CCBundle load];
					}

					// Set the previous Orientation to unknown …

					self -> orientationOld = UIDeviceOrientationUnknown;

					// Let's calculate the Hypotenuse of a Right Triangle formed by Screen's Width and Height, then round the Result up toward positive Infinity …

					CGFloat hypotenuse = ceilf(hypotf(CCScreenWidth, CCScreenHeight));

					// We need a Container, which serves as Host View for ClassicCover's View. It starts hidden and is only shown ( and rotated into Place ) in Landscape …

					self -> hostView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, hypotenuse, hypotenuse)];

					self -> hostView.alpha = 0.0;
					self -> hostView.hidden = YES;
					self -> hostView.userInteractionEnabled = NO;
					self -> hostView.backgroundColor = [UIColor blackColor];

					self -> hostView.layer.cornerRadius = 0.0;
					self -> hostView.layer.masksToBounds = YES;
					self -> hostView.layer.shouldRasterize = NO;

					// Try to load the Storyboard, …

					@try
					{
						self -> viewController = [[UIStoryboard storyboardWithName: @"ClassicCover" bundle: CCBundle] instantiateInitialViewController];
					}
					@catch(NSException *exception)
					{
						MTLog(@"Loading Storyboard failed with Error „%@“. Details: %@.", exception.name, exception.reason);
					}

					// Get the centered Points …

					CGFloat centerX = (hypotenuse - CCScreenHeight) / 2.0;
					CGFloat centerY = (hypotenuse - CCScreenWidth) / 2.0;

					// … set the Frame, …

					self -> viewController.view.frame = CGRectMake(centerX, centerY, CCScreenHeight, CCScreenWidth);

					// … and add ClassicCover's View to the Host View.

					[self -> hostView addSubview: self -> viewController.view];
				}

				return self;
			}

			- (void)centerInSuperview
			{
				UIView *superview = self -> hostView.superview;

				if(!superview)
				{
					return;
				}

				// To center the View, we have to use Bounds, instead of Frame, because the Frame is undefined while a Transform is applied …

				self -> hostView.center = CGPointMake(CGRectGetMidX(superview.bounds), CGRectGetMidY(superview.bounds));
			}

			- (void)applyOrientation: (UIDeviceOrientation)orientation
			{
				// FaceUp / FaceDown / Unknown say nothing about the Interface: Keep the current State …

				if(CCForceDisable)
				{
					orientation = UIDeviceOrientationPortrait;
				}

				MTLog(@"View will Transition to Size …");

				// Determine, if the given Orientation isn't one of the Portrait or Landscape Orientations …

				if(!UIDeviceOrientationIsValidInterfaceOrientation(orientation))
				{
					// … and if the previous Orientation isn't unknown …

					if(self -> orientationOld != UIDeviceOrientationUnknown)
					{
						// … leave here …

						return;
					}

					// … "otherwise" we're in Portrait-Mode.

					orientation = UIDeviceOrientationPortrait;
				}

				// If the previous Orientation and the current One are the same, leave here …

				if(orientation == self -> orientationOld)
				{
					return;
				}

				// Let's set the new Orientation as the previous One …

				self -> orientationOld = orientation;

				// … and check, if we're in Landscape-Mode …

				BOOL isLandscape = UIDeviceOrientationIsLandscape(orientation);

				if(isLandscape)
				{
					// The Host View has to be visible and laid out, before the View Controller "appears" …

					self -> hostView.hidden = NO;
					self -> hostView.userInteractionEnabled = YES;

					// Center ClassicCover's View inside Host View …

					[self centerInSuperview];
				}

				// Forward the Appearance Callbacks, but only if the State really changed ( Landscape Left <-> Right must not trigger them ) …

				if(isLandscape != CCPresented)
				{
					CCPresented = isLandscape;

					// Calls `viewWillAppear:` / `viewDidAppear:` ( or `viewWillDisappear:` / `viewDidDisappear:` ) …

					[self -> viewController beginAppearanceTransition: isLandscape animated: YES];
					[self -> viewController endAppearanceTransition];
				}

				// Check again, if we're in Landscape-Mode …

				if(isLandscape)
				{
					// … and animate the Transform.

					[UIView animateWithDuration: CCDurationNormal animations: ^
					{
						self -> hostView.transform = CGAffineTransformMakeRotation((orientation == UIDeviceOrientationLandscapeLeft) ? M_PI_2 : -M_PI_2);
					} completion: nil];
				}

				// Determine, if we're running on an iPad …

				BOOL isiPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;

				// Let's hide the Status Bar ( iOS 13 and earlier, iOS 14 hides them using another Technique, on iPads the Status Bar will be always visible ) …

				UIApplication *application = [UIApplication sharedApplication];

				if([application respondsToSelector: @selector(statusBarWindow)])
				{
					[[application statusBarWindow] setHidden: (isiPad ? NO : isLandscape)];
				}

				// Fade-in the Host View …

				[UIView animateWithDuration: CCDurationNormal animations: ^
				{
					self -> hostView.alpha = isLandscape ? 1.0 : 0.0;
				}
				completion: ^(BOOL finished)
				{
					if(finished)
					{
						// Only hide if we're still in Portrait ( the User may have rotated back in the Meantime ) …

						if(!UIDeviceOrientationIsLandscape(self.orientationOld))
						{
							self -> hostView.hidden = YES;
							self -> hostView.userInteractionEnabled = NO;
						}
					}
				}];
			}

		@end

		%hook MusicApplication

			- (void)applicationDidResume
			{
				%orig();

				if(CCMonitoringWanted && !CCForceDisable)
				{
					CCStartAccelerometerMonitoring();
				}
			}

			- (void)applicationWillSuspend
			{
				CCStopAccelerometerMonitoring();

				%orig();
			}

		%end

		%hook MusicTabBarController

			- (void)loadView
			{
				%orig();
			}

			-(void)viewDidLoad
			{
				%orig();

				// Wait a Moment …

				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CCIntervalSafeDispatchTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
				{
					UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [UIApplication sharedApplication].windows.firstObject;

					// The Host View, containing ClassicCover's View …

					UIView *hostView = [[ClassicCover sharedInstance] hostView];

					// If everything exists …

					if(window && hostView && hostView.superview != window)
					{
						// … add the Host View to Music's Window …

						[window addSubview: hostView];

						// … and center ClassicCover's View inside Host View.

						[[ClassicCover sharedInstance] centerInSuperview];
					}
				});
			}

			- (void)viewDidAppear: (BOOL)animated
			{
				%orig();

				CCMonitoringWanted = YES;

				if(CCForceDisable)
				{
					return;
				}

				// Start monitoring the Accelerometer only while ClassicCover's Screen is visible …

				CCStartAccelerometerMonitoring();

				// Apply the current Orientation …

				[[ClassicCover sharedInstance] applyOrientation: [[UIDevice currentDevice] orientation]];
			}

			- (void)viewWillDisappear: (BOOL)animated
			{
				%orig();

				// Stop monitoring the Accelerometer …

				CCMonitoringWanted = NO;

				CCStopAccelerometerMonitoring();
			}

			- (BOOL)prefersStatusBarHidden
			{
				return ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad);
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

				CCForceDisable = YES;

				CCStopAccelerometerMonitoring();
			}

			- (void)viewDidDisappear: (BOOL)animated
			{
				%orig();

				CCForceDisable = NO;

				if(CCMonitoringWanted)
				{
					CCStartAccelerometerMonitoring();
				}
			}

		%end

	%end

#pragma mark -
#pragma mark Hooks - Constructor

	%ctor
	{
		// Let's get back to the Initialization of ClassicCover …

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

		if(kCFCoreFoundationVersionNumber >= 1556.00) // iOS 12 …
		{
			MusicTabBarController_Class = NSClassFromString(@"Music.TabBarController");
		}
		else // iOS 11 …
		{
			MusicTabBarController_Class = NSClassFromString(@"Music.RootViewController");
		}

		// Use Short / Long Side so a Launch while the Device is already in Landscape can't swap them …

		CGRect bounds = [[UIScreen mainScreen] bounds];

		CCScreenWidth = MIN(bounds.size.width, bounds.size.height);
		CCScreenHeight = MAX(bounds.size.width, bounds.size.height);

		CCBundle = [NSBundle bundleWithPath: CCFileManagerBundle];

		[CCBundle load];

		// Some Additions for iOS 11 and later …

		if(kCFCoreFoundationVersionNumber >= 1443.00)
		{
			Class MusicNowPlayingViewController_Class = NSClassFromString(@"Music.NowPlayingViewController");

			%init(ClassicCover_NowPlaying, MusicNowPlayingViewController = MusicNowPlayingViewController_Class);
		}

		// Public Lifecycle-Notifications also cover Lock-Screen and Interruptions while Music remains alive for Audio-Playback. Tokens live with the Tweak …

		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

		[center addObserverForName: UIApplicationWillResignActiveNotification object: nil queue: [NSOperationQueue mainQueue] usingBlock: ^(NSNotification *notification)
		{
			CCStopAccelerometerMonitoring();
		}];

		[center addObserverForName: UIApplicationDidBecomeActiveNotification object: nil queue: [NSOperationQueue mainQueue] usingBlock: ^(NSNotification *notification)
		{
			CCStartAccelerometerMonitoring();
		}];

		// Initialize ClassicCover …

		%init(ClassicCover, MusicTabBarController = MusicTabBarController_Class);
	}
