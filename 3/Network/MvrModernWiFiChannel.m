//
//  MvrModernWiFiChannel.m
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrModernWiFiChannel.h"


@implementation MvrModernWiFiChannel

- (id) initWithNetService:(NSNetService*) ns;
{
	self = [super init];
	if (self != nil) {
		netService = [ns retain];
	}
	return self;
}

- (void) dealloc
{
	[netService release];
	[super dealloc];
}

- (NSString*) displayName;
{
	return [netService name];
}

- (void) beginSendingItem:(MvrItem*) item;
{
	// TODO
}

// Can be KVO'd. Contains id <MvrIncoming>s.
- (NSSet*) incomingTransfers;
{
	return [NSSet set]; // TODO
}

- (BOOL) hasSameServiceAs:(NSNetService*) n;
{
	return n == netService || ([n.name isEqual:netService.name] && [n.type isEqual:netService.type]);
}

- (BOOL) hasOutgoingTransfers;
{
	return NO; // TODO!
}

@end
