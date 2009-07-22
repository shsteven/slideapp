//
//  L0MoverAppDelegate+MvrAppleAd.m
//  Mover
//
//  Created by ∞ on 20/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverAppDelegate+MvrAppleAd.h"
#import "MvrAppleAdItem.h"

@implementation L0MoverAppDelegate (MvrAppleAd)

- (void) beginReceivingForAppleAd;
{
	if (!self.tableController.westPeer)
		return;
	
	[self.tableController beginWaitingForItemComingFromPeer:self.tableController.westPeer];
}

- (void) receiveItemForAppleAd;
{
	if (!self.tableController.westPeer)
		return;
	
	MvrAppleAdItem* item = [MvrAppleAdItem adItemForReceiving]; // the fifth
	[self.tableController addItem:item animation:kL0SlideItemsTableAddFromWest duration:[self durationOfArrivalAnimation]];
	[self.tableController stopWaitingForItemFromPeer:self.tableController.westPeer];
}

static L0MoverItem* adItemBeingSent = nil;

- (void) beginSendingForAppleAdWithItem:(L0MoverItem*) i;
{
	//[self performSelector:@selector(returnItemAfterSendForAppleAd:) withObject:i afterDelay:kMvrDelayBetweenSendAndReceive];
	adItemBeingSent = [i retain];
}

- (void) returnItemAfterSendForAppleAd;
{
	if (!self.tableController.eastPeer)
		return;
	
	[self.tableController returnItemToTableAfterSend:adItemBeingSent toPeer:self.tableController.eastPeer duration:[self durationOfArrivalAnimation]];
	[adItemBeingSent release]; adItemBeingSent = nil;
}

static NSTimeInterval MvrDelayBeforeArrival = 0.0;
BOOL foundOutDelayBeforeArrival = NO;
- (NSTimeInterval) delayBeforeArrivalAnimation;
{
	if (!foundOutDelayBeforeArrival) {
		
		id timeObject = [[NSUserDefaults standardUserDefaults] objectForKey:@"kMvrAppleAdAnimationDuration"];
		NSTimeInterval time = timeObject? [timeObject doubleValue] : 1.0;
		MvrDelayBeforeArrival = time >= 2.0? time - 1.0 : time - 0.5;
		
		foundOutDelayBeforeArrival = YES;
	}
	
	return MvrDelayBeforeArrival;
}

static NSTimeInterval MvrDurationOfArrivalAnimation = 0.0;
BOOL foundOutDurationOfArrival = NO;
- (NSTimeInterval) durationOfArrivalAnimation;
{

	if (!foundOutDurationOfArrival) {
		
		id timeObject = [[NSUserDefaults standardUserDefaults] objectForKey:@"kMvrAppleAdAnimationDuration"];
		NSTimeInterval time = timeObject? [timeObject doubleValue] : 1.0;
		MvrDurationOfArrivalAnimation = time >= 2.0? 1.0 : 0.5;
		
		foundOutDurationOfArrival = YES;
		
	}

	return MvrDurationOfArrivalAnimation;
}

@end
