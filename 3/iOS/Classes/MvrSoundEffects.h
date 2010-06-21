//
//  MvrSoundEffects.h
//  Mover3
//
//  Created by ∞ on 20/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface MvrSoundEffects : NSObject <AVAudioSessionDelegate, AVAudioPlayerDelegate> {
	BOOL available;
	
	AVAudioPlayer* nowAvailablePlayer, * disconnectedPlayer,
		* transferBeepPlayer, * transferDonePlayer, * transferFailedPlayer;
	
	float volume;
	NSTimeInterval intervalBetweenBeeps;
	
	int requests;
}

- (void) playChannelNowAvailable;
- (void) playChannelDisconnected;

- (void) beginPlayingTransferSound;
- (void) endPlayingTransferSoundSucceding:(BOOL) succeed;

@end
