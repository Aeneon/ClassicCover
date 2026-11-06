/*
	MarqueelLabel-ObjC | Version 3.2.1

	Created by Charles Powell on 01/31/11; Updated by MacThemes on 11/3/26.
	Copyright © 2011-2017 Charles Powell

	Get the latest Version from here: https://github.com/cbpowell/MarqueeLabel-ObjC

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

	--------------
	Source Changes

	- NSLog() redirected to MTLog()
	- Remove deprecated Code
	- Rewrote existing and added new Comments
*/

#import <UIKit/UIKit.h>

// An Enum that defines the Types of `MarqueeLabel` Scrolling …

typedef NS_ENUM(NSUInteger, MarqueeType)
{
	MLLeftRight = 0, // Scrolls left first, then back right to the original Position.
	MLRightLeft = 1, // Scrolls right first, then back left to the original Position.
	MLContinuous = 2, // Continuously scrolls left ( with a Pause at the original Position if `animationDelay` is set ). See the `trailingBuffer` Property to define a Spacing between the repeating Strings.
	MLContinuousReverse = 3, // Continuously scrolls right ( with a Pause at the original Position if `animationDelay` is set ). See the `trailingBuffer` Property to define a Spacing between the repeating Strings.
	MLLeft = 4, // Scrolls left first, then does not return to the original Position.
	MLRight = 5 // Scrolls right first, then does not return to the original Position.
};


#ifndef IBInspectable
	#define IBInspectable
#endif

/**
	MarqueeLabel is a UILabel Subclass adds a scrolling Marquee Effect when the Text of a Label instance outgrows the available Width. Instances of `MarqueeLabel` can be configured for Label scrolling Direction / Looping, Speed / Rate, and other Options.
*/
IB_DESIGNABLE @interface MarqueeLabel: UILabel <CAAnimationDelegate>

	#pragma mark -
	#pragma mark Creating MarqueeLabels

		/**
			Returns a newly initialized `MarqueeLabel` Instance.

			The default Scroll Duration of 7.0 Seconds and Fade Length of 0.0 are used.

			@param frame A Rectangle specifying the initial Location and Size of the View in its Superview's Coordinates. Text ( for the given Font, Font Size, etc. ) that does not fit in this Frame will automatically scroll.

			@return An initialized `MarqueeLabel` Object or nil if the Object couldn't be created.
		*/
		- (instancetype)initWithFrame: (CGRect)frame;


		/**
			Returns a newly initialized `MarqueeLabel` Instance with the specified Scroll Rate and Edge Transparency Fade Length.

			You must specify a non-zero Rate, and you cannot thereafter modify the Rate.

			@param frame A Rectangle specifying the initial Location and Size of the View in its Superview's Coordinates. Text ( for the given Font, Font Size, etc. ) that does not fit in this Frame will automatically scroll.
			@param pixelsPerSec A Rate of scroll for the Label Scroll Animation. Must be non-zero. Note that this will be the Maximum Rate for ease-type Animation.
			@param fadeLength A Length of Transparency Fade at the left and right Edges of the `MarqueeLabel` Instance's Frame.

			@see `fadeLength`

			@return An initialized `MarqueeLabel` Object or nil if the Object couldn't be created.
		*/
		- (instancetype)initWithFrame: (CGRect)frame rate: (CGFloat)pixelsPerSec andFadeLength: (CGFloat)fadeLength;


		/**
			Returns a newly initialized `MarqueeLabel` instance with the specified scroll duration and edge transparency fade length.

			You must specify a non-zero duration, and you cannot thereafter modify the duration.

			@param frame A Rectangle specifying the initial Location and Size of the View in its Superview's Coordinates. Text ( for the given Font, Font Size, etc. ) that does not fit in this Frame will automatically scroll.
			@param scrollDuration A Scroll Duration the Label Scroll Animation. Must be non-zero. This will be the Duration that the Animation takes for one-half of the Scroll Cycle in the Case of left-right and right-left Marquee Types, and for one Loop of a continuous Marquee Type.
			@param fadeLength A Length of Transparency Fade at the left and right Edges of the `MarqueeLabel` Instance's Frame.

			@see `fadeLength`

			@return An initialized `MarqueeLabel` Object or nil if the Object couldn't be created.
		*/
		- (instancetype)initWithFrame: (CGRect)frame duration: (NSTimeInterval)scrollDuration andFadeLength: (CGFloat)fadeLength;


		/**
			Resizes the View to the Minimum Size necessary to fully enclose the current Text ( i.e. without Scrolling ), up to the Maximum Size specified.

			The current Origin of the Frame is retained.

			@param maxSize The Maximum Size up to which the View should be resized. Passing `CGSizeZero` will Result in no Maximum Size Limit.
			@param adjustHeight A Boolean that can be used to indicate if the View's Height should also be adjusted. Note that this has no Impact on Scrolling.
		*/
		- (void)minimizeLabelFrameWithMaximumSize: (CGSize)maxSize adjustHeight: (BOOL)adjustHeight;

	#pragma mark -
	#pragma mark Configuration Options

		/**
			Specifies the Animation Curve used in the Scrolling Motion of the Labels.

			Allowable Options:

			- `UIViewAnimationOptionCurveEaseInOut`
			- `UIViewAnimationOptionCurveEaseIn`
			- `UIViewAnimationOptionCurveEaseOut`
			- `UIViewAnimationOptionCurveLinear`

			Defaults to `UIViewAnimationOptionCurveEaseInOut`.
		*/
		@property (nonatomic, assign) UIViewAnimationOptions animationCurve;

		/**
			A Boolean Property that sets whether the `MarqueeLabel` should behave like a normal UILabel.

			When set to `YES` the `MarqueeLabel` will behave like a normal UILabel, and will not begin Scrolling when the Text is larger than the specified Frame. The Change takes effect immediately, removing any in-flight Animation as well as any current Edge Fade. Note that the `MarqueeLabel` will respect the current Values of the `lineBreakMode` and `textAlignment` Properties while labelized.

			To simply prevent Automatic Scrolling, use the `holdScrolling` Property.

			Defaults to `NO`.

			@see `holdScrolling`
			@see `lineBreakMode`

			@warning The Label will not automatically scroll when this Property is set to `YES`.
			@warning The UILabel Default Setting for the `lineBreakMode` Property is `NSLineBreakByTruncatingTail`, which truncates the Text adds an Ellipsis Glyph (...). Set the `lineBreakMode` Property to `NSLineBreakByClipping` in order to avoid the Ellipsis, especially if using an Edge Transparency Fade.
		*/
		@property (nonatomic, assign) IBInspectable BOOL labelize;

		/**
			A Boolean Property that sets whether the `MarqueeLabel` should hold ( prevent ) Label Scrolling.

			When set to `YES`, the `MarqueeLabel` will not automatically scroll even its Text is larger than the specified Frame, although the specified Edge Fades will remain.

			To set the `MarqueeLabel` to act like a normal UILabel, use the `labelize` Property.

			Defaults to `NO`.

			@see `labelize`

			@warning The Label will not automatically Scroll when this Property is set to `YES`.
		*/
		@property (nonatomic, assign) IBInspectable BOOL holdScrolling;

		/**
			A Boolean Property that sets whether the `MarqueeLabel` should only begin a Scroll when tapped.

			If this Property is set to `YES`, the `MarqueeLabel` will begin a Scroll Animation Cycle only when tapped. The Label will not automatically being a Scroll. This Setting overrides the Setting of the `holdScrolling` Property.

			Defaults to `NO` .

			@see `holdScrolling`

			@warning The Label will not automatically Scroll when this Property is set to `YES`.
		*/
		@property (nonatomic, assign) IBInspectable BOOL tapToScroll;

		/**
			Defines the Direction and Method in which the `MarqueeLabel` Instance scrolls.

			`MarqueeLabel` supports four Types of Scrolling: `MLLeftRight`, `MLRightLeft`, `MLContinuous`, and `MLContinuousReverse`.

			Given the nature of how Text Direction works, the Options for the `marqueeType` Property require specific Text Alignments and will set the `textAlignment` Property accordingly.

			- `MLLeftRight` type is ONLY compatible with a Label Text Alignment of `NSTextAlignmentLeft`.
			- `MLRightLeft` type is ONLY compatible with a Label Text Alignment of `NSTextAlignmentRight`.
			- `MLContinuous` does not require a Text Alignment ( it is effectively centered ).
			- `MLContinuousReverse` does not require a Text Alignment ( it is effectively centered ).

			Defaults to `MLLeftRight`.

			@see `MarqueeType`
			@see `textAlignment`
		*/
		#if TARGET_INTERFACE_BUILDER
			@property (nonatomic, assign) IBInspectable NSInteger marqueeType;
		#else
			@property (nonatomic, assign) MarqueeType marqueeType;
		#endif

		/**
			Defines the Duration of the Scrolling Animation.

			This Property sets the Amount of Time it will take for the Scrolling Animation to complete a Scrolling Cycle. Note that for `MLLeftRight` and `MLRightLeft`, a Cycle consists of the Animation away, a Pause ( if a Delay is specified ), and the Animation back to the original Position.

			Setting this Property will automatically override any Value previously set to the `rate` Property, and the `rate` Property will be set to `0.0`.

			@see `rate`
		*/
		@property (nonatomic, assign) IBInspectable CGFloat scrollDuration;

		/**
			Defines the Rate at which the Label will scroll, in Pixels per Second.

			Setting this Property will automatically override any Value previousy set to the `scrollDuration` Property, and the `scrollDuration` Property will be set to `0.0`. Note that this is the Rate at which the Label would scroll if it moved at a constant Speed - with other Animation Curves the Rate will be slightly different.

			@see `scrollDuration`
		*/
		@property (nonatomic, assign) IBInspectable CGFloat rate;

		/**
			A Buffer ( Offset ) between the leading Edge of the Label Text and the Label Frame.

			This Property adds additional Space between the leading Edge of the Label Text and the Label Frame. The leading Edge is the Edge of the Label Text facing the Direction of Scroll ( i.e. the Edge that animates offscreen first during Scrolling ).

			Defaults to `0`.

			@note The Value set to this Property affects Label Positioning at all Times ( including when `labelize` is set to `YES` ), including when the Text String Length is short enough that the Label does not need to scroll.
			@note For `MLContinuous`-type Labels, the smallest Value of `leadingBuffer`, 'trailingBuffer`, and `fadeLength` is used as Spacing between the two Label Instances. Zero is an allowable Value for all three Properties.

			@see `trailingBuffer`

			@since Available in 2.1.0 and later.
		*/
		@property (nonatomic, assign) IBInspectable CGFloat leadingBuffer;

		/**
			A Buffer ( Offset ) between the trailing Edge of the Label Text and the Label Frame.

			This Property adds additional Space ( Buffer ) between the trailing Edge of the Label Text and the Label Frame. The trailing Edge is the Edge of the Label Text facing away from the Direction of Scroll ( i.e. the Edge that animates offscreen last during Scrolling).

			Defaults to `0`.

			@note For `MLContinuous`-type Labels, the smallest Value of `leadingBuffer`, 'trailingBuffer`, and `fadeLength` is used as Spacing between the two Label Instances. Zero is an allowable Value for all three Properties.
			@note The Value set to this Property has no Effect when the `labelize` Property is set to `YES`.

			@see `leadingBuffer`

			@since Available in 2.1.0 and later.
		*/
		@property (nonatomic, assign) IBInspectable CGFloat trailingBuffer;

		/**
			The Length of Transparency Fade at the left and right Edges of the `MarqueeLabel` Instance's Frame.

			This Propery sets the Size ( in Points ) of the View Edge Transparency Fades on the left and right Edges of a `MarqueeLabel`. The Transparency fades from an Alpha of 1.0 ( fully visible ) to 0.0 ( fully transparent ) over this Distance. Values set to this Property will be sanitized to prevent a Fade Length greater than 1 / 2 of the Frame Width.

			Defaults to `0`.
		*/
		@property (nonatomic, assign) IBInspectable CGFloat fadeLength;


		/**
			The Length of Delay in Seconds that the Label pauses at the Completion of a Scroll.
		*/
		@property (nonatomic, assign) IBInspectable CGFloat animationDelay;


		/**
			The read-only Duration of the Scroll Animation ( not including Delay ).

			The Value of this Property is calculated when using the `scrollRate` Property to set Label Animation Speed. The Value of this Property is equal to the Value of `scrollDuration` Property when using the `scrollDuration` Property to set Label Animation Speed.

			@see `scrollDuration`
			@see `scrollRate`
		*/
		@property (nonatomic, readonly) NSTimeInterval animationDuration;

	#pragma mark -
	#pragma mark Animation control

		/**
			Immediately resets the Label to the Home Position, cancelling any in-flight Scroll Animation, and restarts the Scroll Animation if the appropriate Conditions are met.

			@see `triggerScrollStart`
		*/
		- (void)restartLabel;

		/**
			Immediately resets the Label to the Home Position, cancelling any in-flight Scroll Animation.

			The Text is immediately returned to the Home Position. Scrolling will not resume automatically after a Call to this Method.
			To re-initiate Scrolling use a Call to `restartLabel` or `triggerScrollStart`, or make a Change to a UILabel Property such as Text, Bounds / Frame, Font, Font Size, etc.

			@see `restartLabel`
			@see `triggerScrollStart`

			@since Available in 2.4.0 and later.
		*/
		- (void)shutdownLabel;

		/**
			Pauses the Text Scrolling Animation, at any Point during an in-progress Animation.

			@note This Method has no Effect if a Scroll Animation is NOT already in Progress. To prevent automatic Scrolling on a newly-initialized Label prior to its Presentation onscreen, see the `holdScrolling` Property.

			@see `holdScrolling`
			@see `unpauseLabel`
		*/
		- (void)pauseLabel;

		/**
			Un-pauses a previously paused Text Scrolling Animation. This Method has no Effect if the Label was not previously paused using `pauseLabel`.

			@see `pauseLabel`
		*/
		- (void)unpauseLabel;

		/**
			Overrides any non-size Condition which is preventing the Receiver from automatically Scrolling, and begins a Scroll Animation.

			Currently the only non-size Conditions which can prevent a Label from Scrolling are the `tapToScroll` and `holdScrolling` Properties. This Method will not force a Label with a String that fits inside the Label Bounds ( i.e. that would not automatically scroll ) to begin a Scroll Animation.

			Upon the Completion of the first forced Scroll Animation, the Receiver will not automatically continue to scroll unless the Conditions preventing Scrolling have been removed.

			@note This Method has no Effect if called during an already in-flight Scroll Animation.

			@see `restartLabel`

			@since Available in 2.2.0 and later.
		*/
		- (void)triggerScrollStart;

	#pragma mark -
	#pragma mark Animation Status

		/**
			Called when the Label Animation is about to begin.

			The Default Implementation of this Method does nothing. Subclasses may override this Method in order to perform any custom Actions just as the Label Animation begins. This is only called in the Event that the Conditions for Scrolling to begin are met.

			@since Available in 1.5.0 and later.
		*/
		- (void)labelWillBeginScroll;

		/**
			Called when the Label Animation has finished, and the Label is at the Home Position.

			The Default Implementation of this Method does nothing. Subclasses may override this Method in order to perform any custom Actions just as the Label Animation completes, and before the next Animation would begin ( assuming the Scroll Conditions are met ).

			@param finished A Boolean that indicates whether or not the Scroll Animation actually finished before the Completion Handler was called.

			@since Available in 1.5.0 and later.

			@warning This Method will be called, and the `finished` Parameter will be `NO`, when any Property Changes are made that would cause the Label Scrolling to be automatically reset. This includes Changes to Label Text and Font / Font Size changes.
		*/
		- (void)labelReturnedToHome: (BOOL)finished;

		/**
			A Boolean Property that indicates if the Label's Scroll Animation has been paused.

			@see `pauseLabel`
			@see `unpauseLabel`
		*/

		@property (nonatomic, assign, readonly) BOOL isPaused;

		/**
			A Boolean Property that indicates if the Label is currently away from the Home Location.

			The "Home" Location is the traditional Location of `UILabel` Text. This Property essentially reflects if a Scroll Animation is underway.
		*/
		@property (nonatomic, assign, readonly) BOOL awayFromHome;

	#pragma mark -
	#pragma mark Bulk-manipulation Methods

		/**
			Convenience Method to restart all `MarqueeLabel` Instances that have the specified View Controller in their next Responder Chain.

			This Method sends a `NSNotification` to all `MarqueeLabel` Instances with the specified View Controller in their next Responder Chain.
			The Scrolling Animation of these Instances will be automatically restarted. This is Equivalent to calling `restartLabel` on all affected Instances.

			There is currently no functional Difference between this Method and `controllerViewDidAppear:` or `controllerViewWillAppear:`. The Methods may be used interchangeably.

			@param controller The View Controller that has appeared.

			@see `restartLabel`
			@see `controllerViewDidAppear:`
			@see `controllerViewWillAppear:`

			@warning View Controllers that appear with Animation ( such as from underneath a Modal-Style Controller ) can cause some `MarqueeLabel` Text Position "jumping" when this Method is used in `viewDidAppear` if Scroll Animations are already underway. Use this Method inside `viewWillAppear:` instead to avoid this Problem.
			@warning This Method may not function properly if passed the Parent View Controller when using View Controller Containment.

			@since Available in 1.3.1 and later.
		*/
		+ (void)restartLabelsOfController: (UIViewController *)controller;

		/**
			Convenience Method to restart all `MarqueeLabel` Instances that have the specified View Controller in their next Responder Chain.

			Alternative to `restartLabelsOfController:`. This Method is retained for Backwards Compatibility and future Enhancements.

			@param controller The View Controller that has appeared.

			@see `restartLabel`
			@see `controllerViewWillAppear:`

			@since Available in 1.2.7 and later.
		*/
		+ (void)controllerViewDidAppear: (UIViewController *)controller;

		/**
			Convenience Method to restart all `MarqueeLabel` Instances that have the specified View Controller in their next Responder Chain.

			Alternative to `restartLabelsOfController:`. This Method is retained for Backwards Compatibility and future Enhancements.

			@param controller The View Controller that has appeared.

			@see `restartLabel`
			@see `controllerViewDidAppear:`

			@since Available in 1.2.8 and later.
		*/
		+ (void)controllerViewWillAppear: (UIViewController *)controller;

		/**
			Labelizes all `MarqueeLabel` Instances that have the specified View Controller in their next Responder Chain.

			This Method sends an `NSNotification` to all `MarqueeLabel` Instances with the specified View Controller in their next Responder Chain. The `labelize` Property of these `MarqueeLabel` Instances will be set to `YES`.

			@param controller The View Controller for which all `MarqueeLabel` Instances should be labelized.

			@see `labelize`
		*/
		+ (void)controllerLabelsShouldLabelize: (UIViewController *)controller;

		/**
			De-Labelizes all `MarqueeLabel` Instances that have the specified View Controller in their next Responder Chain.

			This Method sends an `NSNotification` to all `MarqueeLabel` Instances with the specified View Controller in their next Responder Chain. The `labelize` Property of these `MarqueeLabel` Instances will be set to `NO`.

			@param controller The View Controller for which all `MarqueeLabel` Instances should be de-labelized.

			@see `labelize`
		*/
		+ (void)controllerLabelsShouldAnimate: (UIViewController *)controller;

@end
