/*
	MTCoreLogic.m
	ClassicCover

	Created by MacThemes on 11/3/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import <Foundation/Foundation.h>

#import "MTCoreLogic.h"

#import "ClassicCover/CCPrefsManager.h"

#undef MTLog

BOOL MTDebugLoggingEnabled(void)
{
	return [CCPrefsManager sharedInstance].debugLogging;
}

#pragma mark -
#pragma mark Static Methods

	void MTLog(NSString * _Nonnull format, ...)
	{
		// Check if Debug Logging is enabled in Preferences …

		if(MTDebugLoggingEnabled())
		{
			// Declare a Pointer to hold the Variable Argument List …

			va_list args;

			// Initialize `args` to point to the first Argument after `format` …

			va_start(args, format);

			// Format the custom String with Variable Arguments …

			NSString *customFormat = [@"[ClassicCover] " stringByAppendingString: format];
			NSString *message = [[NSString alloc] initWithFormat: customFormat arguments: args];

			// Clean up the Memory / State associated with the Argument List …

			va_end(args);

			// `NSLog` handles the Timestamp, Process Name, and Thread ID automatically ( using %@ to safely avoid Format Specifier Bugs ) …

			NSLog(@"%@", message);
		}
	}
