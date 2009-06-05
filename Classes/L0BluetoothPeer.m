//
//  L0BluetoothPeer.m
//  Mover
//
//  Created by ∞ on 05/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0BluetoothPeer.h"


@implementation L0BluetoothPeer

- (id) initWithPeerID:(NSString*) i displayName:(NSString*) n;
{
	if (self = [super init]) {
		peerID = [i copy];
		displayName = [n copy];
	}
	
	return self;
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
	// TODO send the item
	NSAssert(NO, @"Implement me");
	return NO;
}

@end
