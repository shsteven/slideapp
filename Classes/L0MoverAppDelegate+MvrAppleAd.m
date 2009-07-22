//
//  L0MoverAppDelegate+MvrAppleAd.m
//  Mover
//
//  Created by ∞ on 20/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverAppDelegate+MvrAppleAd.h"
#import "MvrAppleAdItem.h"

#define kMvrDelayBetweenSendAndReceive 2.0

@implementation L0MoverAppDelegate (MvrAppleAd)

- (void) beginReceivingForAppleAd;
{
	if (!self.tableController.westPeer)
		return;
	
	[self.tableController beginWaitingForItemComingFromPeer:self.tableController.westPeer];
	[self performSelector:@selector(receiveItemForAppleAd) withObject:nil afterDelay:kMvrDelayBetweenSendAndReceive];
}

- (void) receiveItemForAppleAd;
{
	if (!self.tableController.westPeer)
		return;
	
	MvrAppleAdItem* item = [MvrAppleAdItem adItemForReceiving]; // the fifth
	[self.tableController addItem:item animation:kL0SlideItemsTableAddFromWest];
	[self.tableController stopWaitingForItemFromPeer:self.tableController.westPeer];
}

- (void) beginSendingForAppleAdWithItem:(L0MoverItem*) i;
{
	[self performSelector:@selector(returnItemAfterSendForAppleAd:) withObject:i afterDelay:kMvrDelayBetweenSendAndReceive];
}

- (void) returnItemAfterSendForAppleAd:(L0MoverItem*) i;
{
	if (!self.tableController.eastPeer)
		return;
	
	[self.tableController returnItemToTableAfterSend:i toPeer:self.tableController.eastPeer];
}

@end
