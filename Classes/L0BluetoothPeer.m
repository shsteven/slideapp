//
//  L0BluetoothPeer.m
//  Mover
//
//  Created by ∞ on 05/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0BluetoothPeer.h"
#import "L0BluetoothPeeringService.h"

@implementation L0BluetoothPeer

- (id) initWithPeerID:(NSString*) i displayName:(NSString*) n;
{
	if (self = [super init]) {
		peerID = [i copy];
		displayName = [n copy];
	}
	
	return self;
}

- (void) dealloc;
{
	[peerID release];
	[displayName release];
	[super dealloc];
}

@synthesize name = displayName, peerID;

- (double) applicationVersion;
{
	return kL0UnknownApplicationVersion;
}

- (NSString*) userVisibleApplicationVersion;
{
	return nil;
}

- (BOOL) receiveItem:(L0MoverItem*) i;
{
	[[L0BluetoothPeeringService sharedService] sendItem:i toBluetoothPeer:self];
	return YES;
}

@end
