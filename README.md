# ClassicCover

**Hello Friends,**

ClassicCover brings back what is arguably the most beautiful Way to experience Music on iPhones, iPads and iPod touches: CoverFlow&nbsp;- originally developed by Steel Skies, and later integrated by Apple into iTunes and the Finder. In 2026, iPods are also enjoying a minor Renaissance, and so CoverFlow is making a Comeback in the World of digital Music.

<p align="center" style="margin-top: 1.75em; margin-bottom: 3.5em;"><img src="https://macthemes.me/developer/ClassicCover_Header.png" /></p>

## Table of Contents

1. [Introduction](#1-introduction)

2. [Running on Device](#2-running-on-device)

3. [Building your own Version](#3-building-your-own-version)

4. [Made for your iDevice](#4-made-for-your-idevice)

5. [Last Words](#5-last-words)

6. [Greetings](#6-greetings)

7. [Updates](#7-updates)

## 1. Introduction

Almost 10 Years ago&nbsp;- in 2017&nbsp;- two Tweaks based on Nick Lockwood’s [iCarousel](https://github.com/nicklockwood/icarousel) were released that would breathe new Life into CoverFlow: On the one Hand, there was [CoverFlowM](https://github.com/julioverne/CoverflowM) by Julio Verne, which required iOS 10, and [ClassicCover](https://github.com/c0ldra1n/ClassicCover) by Mitsuha-Developer c0ldra1n, which was offered for $2,99. At the Time, a Comparison was made within the Jailbreak Community: [ClassicCover vs. CoverFlowM](https://www.reddit.com/r/jailbreak/comments/7okoww/release_classiccover_bring_back_the_good_old/). The Winner&nbsp;- in my Eyes&nbsp;- was the inferior Option, as CoverFlowM not only offered a simplified Interface but also didn't run on iOS 9. Fortunately, c0ldra1n released the Source Code for ClassicCover, so there was nothing to stop further Development, as, looking back, ClassicCover also had its weaknesses&nbsp;…

Reason enough, almost nine Years after its Release, to take a closer Look at the Project once again and make some significant Improvements to it&nbsp;…

- **Designed with Music in Mind**: Sort your Albums by Artist, Genre, Name, Date added to Library, last played Date or in a totally random Order&nbsp;…
- **Made for the Taptic Engine**: Get subtle haptic Feedback when you tap Buttons or toggle Switches&nbsp;…
- **Preferences made with Love**: Change any Setting without closing the Music-App&nbsp;…
- **Smooth User Experience**: Every Album Artwork and their Reflection will be cached in Memory and on Disk, so you'll never experience Lags while browsing your Library&nbsp;…
- **Vibrant with Colour**: Use different Styles for the Background, e.g. a solid or random Colour, Photos or even the average Colour of the Album Artwork&nbsp;…
- **Well-thought-out Design**: Reflections with an optional Blur Effect and a soft Shadow for Album’s Detail View will enhance any presentation of your Music Collection&nbsp;…
- **クラシックカバー&nbsp;?**&nbsp;: Fully localized in Deutsch, English, Español, Français, Italiano, Nederlands and Português&nbsp;…

If you're using ClassicCover on iPad, enjoy these **additional Features**:

- **Demo-Loop**: Show off your Music Collection in Style&nbsp;- ClassicCover automatically scrolls through Albums and displays the Detail View from Time to Time. Pause it by Scrolling through your Library or playing a Track. After one Minute of Inactivity, ClassicCover returns to Demo-Loop&nbsp;…
- **Prevent Display Sleep**: You can prevent the Display’s Sleep, while using Demo-Loop&nbsp;…

If you’d like to find out a bit more about&nbsp;- one or two hidden Features&nbsp;- or the Development Process behind ClassicCover, take a look at the [Developer’s Diary](https://macthemes.me/?p=0005-diaries-classiccover).

<p align="center" style="margin-top: 3.5em; margin-bottom: 3.5em;"><img src="https://macthemes.me/developer/ClassicCover_CoverView.png" /></p>

## 2. Running on Device

Originally, ClassicCover only ran on iOS 9 and iOS 10. At the Start of Development, the Focus was on these Versions, until I eventually decided to include an iPad 6&nbsp;- running iOS 12.4.1&nbsp;- in the Development Process. The Step up to the iPhone 12 Pro running iOS 14.4 was not far off, meaning that ClassicCover now supports all iPhones, iPads and iPod touches with a 64-bit Processor, from the first Version of iOS 9 right through to the latest Version of iOS 14.

To **get ClassicCover**, just add my Repo to your Package Manager: https://macthemes.me/ …

## 3. Building your own Version

All you need is [theos](https://github.com/theos/theos). You can easily build your own Version of ClassicCover by running `make` or `gmake`&nbsp;(&nbsp;requires GNU Make to be installed&nbsp;) in the Folder where you put ClassicCover's Code. Why I can't explain all of theos, please refer to the [Manual](https://theos.dev/docs/installation) for additional Help.

The most important Thing you need is **Patience**.

## 4. Made for your iDevice

As a Member of the&nbsp;- former&nbsp;- Forum of &quot;MacThemes&quot; I would like to offer Theme Designers a Possibility to customize the Settings of ClassicCover according to your Wishes. Have a Look at `Theme.plist` in the following Bundle:

- **Rootful:** `/Library/PreferenceBundles/ClassicCoverPrefs.bundle`

If you want to use custom Colors, simply copy the `Theme.plist` into a new Folder named `com.macthemes.classiccoverprefs` inside `Bundles` of your Theme.

Open the `Theme.plist`, expand the Dictionary-Keys `CCTintColors` and `MTTintColors`&nbsp;(&nbsp;if you're using something like [PlistEdit Pro](https://www.fatcatsoftware.com/plisteditpro/) or Xcode's Property List Editor&nbsp;) and have a Look at the Key-Value-Pairs&nbsp;…

| Key | Description | Default-Value |
| :-: | :---------: | :-----------: |
| CCButtonArtworkCache | The &quot;Clear Artwork Cache&quot; Button | #ff3945:1.0 |
| CCButtonBackgroundImage | The &quot;Custom Image&quot; Button | #c46eff:1.0 |
| CCButtonOpenSource | The &quot;Open-Source Notices&quot; Button | #c46eff:1.0 |
| CCButtonOrphanedArtworks | The &quot;Remove orphaned Artworks&quot; Button | #c46eff:1.0 |
| CCSwitchAutoHideLabels | The &quot;Fade-Out Album Informations&quot; Switch | #8a72ff:1.0 |
| CCSwitchDebugLogging | The &quot;Debug Logging&quot; Switch | #7a797f:1.0 |
| CCSwitchDemoEnable | The &quot;Enable Demo-Loop&quot; Switch | #8a72ff:1.0 |
| CCSwitchEnable | The &quot;Enable ClassicCover&quot; Switch | #8a72ff:1.0 |
| CCSwitchFlipShadow | The &quot;Shadow around Flip View&quot; Switch | #8a72ff:1.0 |
| CCSwitchHapticFeedback | The &quot;Haptic Feedback&quot; Switch | #8a72ff:1.0 |
| CCSwitchPreventSleep | The &quot;Prevent Display Sleep&quot; Switch | #ff3945:1.0 |
| CCSwitchReflection | The &quot;Reflections&quot; Switch | #8a72ff:1.0 |
| CCSwitchReflectionBlur | The &quot;Reflections with Blur&quot; Switch | #a08cff:1.0 |
| MTNavigationBar | Navigation Bar: Color of &quot;Preferences&quot; | #4f75ff:1.0 |
| MTSocialTwitter | Navigation Bar: Twitter-Button | #0098c0:1.0 |
| MTSocialWebsite | Navigation Bar: MacThemes-Button | #727373:1.0 |
| MTWindow | Window's Tint Color | #c46eff:1.0 |

Every Key is using a Hex-String as Color and a Float-Value ranging from Zero to One indicating the Alpha-Component of the Color. To convert your Color from RGB to a Hex-String, use [Google Color Chooser](https://g.co/kgs/aBRkTpR) or any Image Editor, such as [Adobe Photoshop](https://www.adobe.com/de/products/photoshop.html) or [Pixelmator](https://itunes.apple.com/de/app/pixelmator/id407963104?mt=12) from the Mac App Store. You can change the Colors, to match your Theme, like Suave7 does&nbsp;…

<p align="center"><img src="https://macthemes.me/developer/ClassicCover_Theming.png" /></p>

Save the File and apply the new Colorization with your Theming Engine&nbsp;- Anemone&nbsp;(&nbsp;iOS 9&nbsp;), iThemer&nbsp;(&nbsp;iOS 12&nbsp;) and NeonBoard&nbsp;(&nbsp;iOS 14&nbsp;) are known to work.

## 5. Last Words

This Project comes with no Warranty, neither express nor implied. If it blows up your Device, an angy Musician eats your Children, or causes you bodily Harm, all you'll get is a little Pity and maybe an Apology.

If you respect my Work&nbsp;(&nbsp;nearly two Months of Coding with hundreds of Builds and countless Hours of on-Device-Testing&nbsp;), you can help me with a small Donation via [PayPal.me](https://www.paypal.com/donate/?hosted_button_id=F5EPEFSLDBHPQ) and please don't publish the Tweak on an other Repo&nbsp;😃&nbsp;…

## 6. Greetings

I would like to extend my Special Thanks to *c0ldra1n* for deciding, many Years ago, to release the Source Code for ClassicCover. We need more People like him in our Community.

Thank you.

## 7. Updates

Starting with Version 2611, released on 7th November 2026, I've decided to dedicate each Release to an Artist from my Music Collection, whether they are still alive or have already passed away. The &quot;Release Highlights&quot; Section contains some interesting Facts about the Artist. To ensure this Information is not forgotten, you will find below a List of all previous Updates and their Dedications:

<ul>
	<li><strong>Version 2611, released 7th November 2026, 2:20 PM</strong><br/>Philip David Charles &quot;Phil&quot; Collins&nbsp;(&nbsp;* 30th January 1951&nbsp;), an English Singer, Drummer, Songwriter, Record Producer, and Actor. Known as the Drummer and later Lead Vocalist of Genesis and for his highly successful Career as a Solo Artist. Ohh, and on this Day, 37 Years ago, on 7th November 1989, he released his fourth Studio Album &quot;…&nbsp;But Seriously&quot; featuring Hits like &quot;Another Day in Paradise&quot;, &quot;Do You Remember&nbsp;?&quot;, &quot;I Wish It Would Rain Down&quot; and many more. It sold more than 14,800,000 Copies worldwide and was certified with three Gold, 73 Platinum, and one Diamond Record&nbsp;😲. The Album also brings together the instrumental Track &quot;Saturday Night and Sunday Morning&quot; and &quot;Colors&quot;&nbsp;- the shortest and longest Tracks, respectively, from Collins’ Solo Career&nbsp;- on a single Album&nbsp;…</li>
</ul>