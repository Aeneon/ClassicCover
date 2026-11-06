/*
	MTAutumnBoard.m
	AutumnBoard

	Created by MacThemes on 10/28/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import "MTAutumnBoard.h"

#import "../../MTCoreLogic.h"

/*
	Theme …
*/
@implementation MTAutumnBoard
{
	// The ClassicCover Preference-Bundle …

	NSBundle *_preferenceBundle;
}

	#pragma mark -
	#pragma mark Shared Instance

		+ (instancetype)sharedInstance
		{
			// "Theme.plist" is bundled with the Preference-Bundle and does not change while it is loaded. Re-Use the parsed Colors instead of reading the File for every Switch and Button Cell …

			static MTAutumnBoard *sharedInstance = nil;

			static dispatch_once_t onceToken;

			dispatch_once(&onceToken, ^
			{
				sharedInstance = [[self alloc] init];
			});

			return sharedInstance;
		}

	#pragma mark -
	#pragma mark Lifecycle

		- (id)init
		{
			self = [super init];

			if(self)
			{
				// Set the ClassicCover Preference-Bundle …

				_preferenceBundle = [NSBundle bundleForClass: self.class];

				// Get the "Theme.plist" from our Preference Bundle …

				NSString *bundledTheme = [_preferenceBundle pathForResource: @"Theme" ofType: @"plist"];

				NSDictionary *theme = [NSDictionary dictionaryWithContentsOfFile: bundledTheme];

				// Our Dictionaries of Colors …

				NSDictionary *tintColorsCC;
				NSDictionary *tintColorsMT;

				// If "Theme.plist" contains a Dictionary named "CCTintColors" …

				if(theme[@"CCTintColors"])
				{
					// … get them.

					tintColorsCC = theme[@"CCTintColors"];
				}

				// If "Theme.plist" contains a Dictionary named "MTTintColors" …

				if(theme[@"MTTintColors"])
				{
					// … get them.

					tintColorsMT = theme[@"MTTintColors"];
				}

				// Now check, if every Color exists and - if so - convert it's Hex-Color-String to an UI Color, otherwise use the Default Color …

				_socialTwitter			= tintColorsMT[@"MTSocialTwitter"]			? [self colorWithHexString: tintColorsMT[@"MTSocialTwitter"]]			: CCColorSocialTwitter;
				_socialWebsite			= tintColorsMT[@"MTSocialWebsite"]			? [self colorWithHexString: tintColorsMT[@"MTSocialWebsite"]]			: CCColorSocialWebseite;

				_generalNavigationBar	= tintColorsMT[@"MTNavigationBar"]			? [self colorWithHexString: tintColorsMT[@"MTNavigationBar"]]			: CCColorGeneralNavigationBar;
				_generalWindow 			= tintColorsMT[@"MTWindow"]					? [self colorWithHexString: tintColorsMT[@"MTWindow"]]					: CCColorGeneralWindow;

				_buttonArtworkCache		= tintColorsCC[@"CCButtonArtworkCache"]		? [self colorWithHexString: tintColorsCC[@"CCButtonArtworkCache"]]		: CCColorGeneralButtonDestructive;
				_buttonBackgroundImage 	= tintColorsCC[@"CCButtonBackgroundImage"]	? [self colorWithHexString: tintColorsCC[@"CCButtonBackgroundImage"]]	: CCColorGeneralButton;
				_buttonOpenSource		= tintColorsCC[@"CCButtonOpenSource"]		? [self colorWithHexString: tintColorsCC[@"CCButtonOpenSource"]]		: CCColorGeneralButton;
				_buttonOrphanedArtworks	= tintColorsCC[@"CCButtonOrphanedArtworks"]	? [self colorWithHexString: tintColorsCC[@"CCButtonOrphanedArtworks"]]	: CCColorGeneralButton;

				_switchAutoHideLabels	= tintColorsCC[@"CCSwitchAutoHideLabels"]	? [self colorWithHexString: tintColorsCC[@"CCSwitchAutoHideLabels"]]	: CCColorGeneralSwitch;
				_switchDebugLogging		= tintColorsCC[@"CCSwitchDebugLogging"]		? [self colorWithHexString: tintColorsCC[@"CCSwitchDebugLogging"]]		: CCColorGeneralSwitch;
				_switchDemoEnable		= tintColorsCC[@"CCSwitchDemoEnable"]		? [self colorWithHexString: tintColorsCC[@"CCSwitchDemoEnable"]]		: CCColorGeneralSwitch;
				_switchEnable			= tintColorsCC[@"CCSwitchEnable"]			? [self colorWithHexString: tintColorsCC[@"CCSwitchEnable"]]			: CCColorGeneralSwitch;
				_switchFlipShadow		= tintColorsCC[@"CCSwitchFlipShadow"]		? [self colorWithHexString: tintColorsCC[@"CCSwitchFlipShadow"]]		: CCColorGeneralSwitch;
				_switchHapticFeedback	= tintColorsCC[@"CCSwitchHapticFeedback"]	? [self colorWithHexString: tintColorsCC[@"CCSwitchHapticFeedback"]]	: CCColorGeneralSwitch;
				_switchPreventSleep		= tintColorsCC[@"CCSwitchPreventSleep"]		? [self colorWithHexString: tintColorsCC[@"CCSwitchPreventSleep"]]		: CCColorGeneralSwitchDestructive;
				_switchReflection		= tintColorsCC[@"CCSwitchReflection"]		? [self colorWithHexString: tintColorsCC[@"CCSwitchReflection"]]		: CCColorGeneralSwitch;
				_switchReflectionBlur	= tintColorsCC[@"CCSwitchReflectionBlur"]	? [self colorWithHexString: tintColorsCC[@"CCSwitchReflectionBlur"]]	: CCColorGeneralSwitchBright;
			}

			return self;
		}

	#pragma mark -
	#pragma mark Private Methods

		// Convert Hex-Color-String to UI Color …

		- (UIColor *)colorWithHexString: (NSString *)stringToConvert
		{
			// Split the String into an Array using the Colon …

			NSArray *components = [stringToConvert componentsSeparatedByString: @":"];

			// The first Component is our Color …

			NSString *hashString = ([components count] > 0) ? components[0] : components;

			// … and the second our Alpha Value.

			float alphaValue = ([components count] > 1) ? [components[1] floatValue] : 1.0;

			// Now let's remove the Hashtag ( "#" ) from our Hex-String, …

			NSString *noHashString = [hashString stringByReplacingOccurrencesOfString: @"#" withString: @""];

			// … remove Symbol Characters, like "+" and "$" …

			NSScanner *scanner = [NSScanner scannerWithString: noHashString];

			[scanner setCharactersToBeSkipped: [NSCharacterSet symbolCharacterSet]];

			// … convert the String, by getting it'S Components for Red, Green and Blue …

			unsigned hex;

			if(![scanner scanHexInt: &hex])
			{
				return nil;
			}

			int red = (hex >> 16) & 0xFF;
			int green = (hex >> 8) & 0xFF;
			int blue = (hex) & 0xFF;

			// … and return the Components, plus the Alpha Value as new UI Color.

			return [UIColor colorWithRed: red / 255.0 green: green / 255.0 blue: blue / 255.0 alpha: alphaValue];
		}

@end
