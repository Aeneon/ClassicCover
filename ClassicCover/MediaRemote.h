/*
	MediaRemote.h
	ClassicCover

	Created by David Murray on 12/9/24; Updated by MacThemes on 9/24/26.
	Copyright © 2013-2024 David Murray & © 2026 MacThemes. All rights reserved.
*/

#ifndef MEDIAREMOTE

	#define MEDIAREMOTE

	#include <Foundation/Foundation.h>

	#pragma mark - API

		typedef NS_ENUM(NSUInteger, MRCommand)
		{
			// Use `nil` for `userInfo` …

		/*
			kMRPlay = 0,
			kMRPause = 1,
			kMRTogglePlayPause = 2,
			kMRStop = 3,
			kMRToggleShuffle = 6,
			kMRToggleRepeat = 7,
			kMRStartForwardSeek = 8,
			kMREndForwardSeek = 9,
			kMRStartBackwardSeek = 10,
			kMREndBackwardSeek = 11,
			kMRGoBackFifteenSeconds = 12,
			kMRSkipFifteenSeconds = 13,
			kMRLikeTrack = 0x6A,
			kMRBanTrack = 0x6B
		*/
			kMRNextTrack = 4,
			kMRPreviousTrack = 5
		};

		typedef NS_ENUM(NSUInteger, MRAShuffleMode)
		{
			kMRAShuffleDisabled = 1,
			kMRAShuffleAlbums = 2,
			kMRAShuffleTracks = 3,
		};

		typedef NS_ENUM(NSUInteger, MRARepeatMode)
		{
			kMRARepeatDisabled = 1,
			kMRARepeatTrack = 2,
			kMRARepeatPlaylist = 3,
		};

		Boolean MRMediaRemoteSendCommand(MRCommand command, id userInfo);

		void MRMediaRemoteSetShuffleMode(int mode);
		void MRMediaRemoteSetRepeatMode(int mode);

#endif
