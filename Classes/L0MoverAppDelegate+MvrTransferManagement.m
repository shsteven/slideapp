//
//  L0MoverAppDelegate+MvrTransferManagement.m
//  Mover
//
//  Created by ∞ on 06/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverAppDelegate+MvrTransferManagement.h"
#import "L0MoverAppDelegate+L0ItemPersistance.h"
#import "L0MoverAppDelegate+L0HelpAlerts.h"

#import "L0ImageItem.h"
#import "L0AddressBookPersonItem.h"

@implementation L0MoverAppDelegate (MvrTransferManagement)

- (void) moverPeer:(L0MoverPeer*) peer willBeSentItem:(L0MoverItem*) item;
{
	L0Log(@"About to send item %@", item);
	[UIApp beginNetworkUse];
}

- (void) moverPeer:(L0MoverPeer*) peer wasSentItem:(L0MoverItem*) item;
{
	L0Log(@"Sent %@", item);
	[self.tableController returnItemToTableAfterSend:item toPeer:peer];
	[UIApp endNetworkUse];
}

- (void) moverPeer:(L0MoverPeer*) peer didStartReceiving:(id <MvrIncoming>) incomingTransfer;
{
	L0Log(@"%@, %@", peer, incomingTransfer);
	
	[self.tableController trackIncomingTransfer:incomingTransfer fromPeer:peer];
	
	[UIApp beginNetworkUse];
	
	[observedTransfers addObject:incomingTransfer];
	[dispatcher observe:@"item" ofObject:incomingTransfer usingSelector:@selector(itemOfTransfer:changed:) options:0];
	[dispatcher observe:@"cancelled" ofObject:incomingTransfer usingSelector:@selector(cancelledOfTransfer:changed:) options:0];
}

- (void) itemOfTransfer:(id <MvrIncoming>) transfer changed:(NSDictionary*) change;
{
	if (!transfer.item)
		return;
	
	L0MoverItem* item = transfer.item;
	L0Log(@"Did receive an item: %@", item);
	
	[item storeToAppropriateApplication];
	[self persistItemToMassStorage:item];
	
	if ([item isKindOfClass:[L0ImageItem class]])
		[self showAlertIfNotShownBeforeNamedForiPhone:@"L0ImageReceived_iPhone" foriPodTouch:@"L0ImageReceived_iPod"];
	else if ([item isKindOfClass:[L0AddressBookPersonItem class]])
		[self showAlertIfNotShownBeforeNamed:@"L0ContactReceived"];
	
	[self stopTrackingIncomingTransfer:transfer];
}

- (void) cancelledOfTransfer:(id <MvrIncoming>) transfer changed:(NSDictionary*) change;
{
	if (!transfer.cancelled)
		return;
	
	[self stopTrackingIncomingTransfer:transfer];	
}

- (void) stopTrackingIncomingTransfer:(id <MvrIncoming>) transfer;
{
	[dispatcher endObserving:@"item" ofObject:transfer];
	[dispatcher endObserving:@"cancelled" ofObject:transfer];
	[observedTransfers removeObject:transfer];
	
	[UIApp endNetworkUse];
}

@end
