/*
	ClassicCover.xm
	ClassicCover

	Created by MacThemes on 10/27/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import <Foundation/Foundation.h>

#include <dlfcn.h>
#include <libSandy.h>

#import "../../MTCoreLogic.h"

#import "../../ClassicCover/CCPrefsManager.h"

#pragma mark -
#pragma mark Helpers

	// Get Read- / Write-Access to "/var/mobile/Library/Caches/com.macthemes.classiccover/" using libSandy on iOS 10 and later …

	static void CCApplySandboxProfile(void)
	{
		// Call libSandy …

		void *handle = dlopen("/usr/lib/libsandy.dylib", RTLD_LAZY);

		if(!handle)
		{
			MTLog(@"libSandy could not be loaded: %s", dlerror());

			return;
		}

		// … and apply the Profile.

		int (*applyProfile)(const char *) = (int (*)(const char *))dlsym(handle, "libSandy_applyProfile");

		if(applyProfile)
		{
			MTLog(@"Applying libSandy's Profile returned: %d.", applyProfile("ClassicCover"));
		}
	}

#pragma mark -
#pragma mark Hooks - Constructor

	%ctor
	{
		if([CC_PREFS_VALUE_FOR_KEY(CCPrefsEnabledKey) boolValue])
		{
			// Get Read- / Write-Access to "/var/mobile/Library/Caches/com.macthemes.classiccover/" using libSandy on iOS 10 and later …

			if(kCFCoreFoundationVersionNumber >= 1348.00)
			{
				CCApplySandboxProfile();
			}

			/*
				┌───────┬────────────────┐
				│  iOS	│ CoreFoundation │
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

			// If we're running on iOS 11 or iOS 12 and this Device isn't an iPad …

			if(kCFCoreFoundationVersionNumber >= 1443.00 && kCFCoreFoundationVersionNumber < 1665.15 && [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
			{
				// … load ClassicCover using CoreMotion, to get Music.app on iPhones and iPod touches working.

				dlopen("/Library/MobileSubstrate/DynamicLibraries/ClassicCover/ClassicCover_CoreMotion.dylib", RTLD_NOW);
			}
			else
			{
				// … otherwise load ClassicCover using UIKit.

				dlopen("/Library/MobileSubstrate/DynamicLibraries/ClassicCover/ClassicCover_UIKit.dylib", RTLD_NOW);
			}
		}
	}
