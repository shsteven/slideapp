//
//  MvrSoundEffects.m
//  Mover3
//
//  Created by ∞ on 20/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrSoundEffects.h"

@interface MvrSoundEffects ()

- (void) initializePlayer:(AVAudioPlayer**) player usingResource:(NSString*) res ofType:(NSString*) type;

- (void) playTransferBeepAndReschedule;

@end


@implementation MvrSoundEffects

- (id) init
{
	self = [super init];
	if (self != nil) {
		
		AVAudioSession* session = [AVAudioSession sharedInstance];
		session.delegate = self;
		
		available = [session setCategory:AVAudioSessionCategoryAmbient error:NULL];
		
		if (available)
			available = [session setActive:YES error:NULL];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	}
	
	return self;
}

- (void) dealloc
{
	AVAudioSession* session = [AVAudioSession sharedInstance];
	if (session.delegate == self)
		session.delegate = nil;
	
	[nowAvailablePlayer release];
	[disconnectedPlayer release];
	
	[super dealloc];
}


- (void) didReceiveMemoryWarning:(NSNotification*) n;
{
	[nowAvailablePlayer release]; nowAvailablePlayer = nil;
	[disconnectedPlayer release]; disconnectedPlayer = nil;
	[transferBeepPlayer release]; transferBeepPlayer = nil;
	[transferDonePlayer release]; transferDonePlayer = nil;
	[transferFailedPlayer release]; transferFailedPlayer = nil;
}

- (void) beginInterruption;
{
	available = NO;
}

- (void) endInterruption;
{
	available = [[AVAudioSession sharedInstance] setActive:YES error:NULL];
}

- (void) playChannelNowAvailable;
{
	if (!available)
		return;
	
	if (!nowAvailablePlayer) {
		[self initializePlayer:&nowAvailablePlayer usingResource:@"ChannelAppeared" ofType:@"caf"];
		nowAvailablePlayer.volume = 0.2;
	}
	
	if (self.enabled)
		[nowAvailablePlayer play];
}

- (void) playChannelDisconnected;
{
	if (!available)
		return;
	
	if (!disconnectedPlayer) {
		[self initializePlayer:&disconnectedPlayer usingResource:@"ChannelDisappeared" ofType:@"caf"];
		disconnectedPlayer.volume = 0.2;
	}
	
	if (self.enabled)
		[disconnectedPlayer play];
}

- (void) initializePlayer:(AVAudioPlayer**) player usingResource:(NSString*) res ofType:(NSString*) type;
{
	if (!available)
		return;
	
	NSString* s = [[NSBundle mainBundle] pathForResource:res ofType:type];
	if (!s)
		return;
	
	*player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:s] error:NULL];
	if (self.enabled)
		[*player prepareToPlay];
}

- (void) beginPlayingTransferSound;
{
	requests++;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	volume = 0.5;
	intervalBetweenBeeps = 1;
	
	[self playTransferBeepAndReschedule];
}

- (void) playTransferBeepAndReschedule;
{
	// step one, reschedule
	[self performSelector:@selector(playTransferBeepAndReschedule) withObject:nil afterDelay:intervalBetweenBeeps];
	intervalBetweenBeeps = MIN(intervalBetweenBeeps * 1.15, 5);
	
	if (!transferBeepPlayer)
		[self initializePlayer:&transferBeepPlayer usingResource:@"ProgressPing" ofType:@"caf"];
	
	transferBeepPlayer.volume = volume;
	volume = MAX(volume - 0.1, 0.02);
	
	if (self.enabled)
		[transferBeepPlayer play];
}

- (void) endPlayingTransferSoundSucceding:(BOOL) succeed;
{
	requests--;
	
	if (requests == 0)
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	if (succeed) {
		if (!transferDonePlayer)
			[self initializePlayer:&transferDonePlayer usingResource:@"ProgressOver" ofType:@"caf"];
		if (self.enabled)
			[transferDonePlayer play];
	} else {
		if (!transferFailedPlayer)
			[self initializePlayer:&transferFailedPlayer usingResource:@"ProgressOverFailure" ofType:@"caf"];
		
		transferFailedPlayer.volume = 0.5;
		if (self.enabled)
			[transferFailedPlayer play];
	}
}

@synthesize enabled;

@end
