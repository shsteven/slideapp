//
//  MvrWiFiChannel.m
//  Mover
//
//  Created by ∞ on 26/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFiChannel.h"
#import "MvrWiFiOutgoingTransfer.h"

static NSString* MvrStringFromDataOrString(id x) {
	if (!x) return nil;
	
	if ([x isKindOfClass:[NSString class]])
		return x;
	
	if ([x isKindOfClass:[NSData class]])
		return [[[NSString alloc] initWithData:x encoding:NSUTF8StringEncoding] autorelease];
	
	NSCAssert(NO, @"Neither a NSString nor a NSData instance: %@");
	return nil;
}

@interface MvrWiFiChannel ()

@property(setter=private_setName:, copy) NSString* name;
@property(setter=private_setUniquePeerIdentifier:, copy) NSString* uniquePeerIdentifier;
@property(setter=private_setApplicationVersion:, assign) double applicationVersion;
@property(setter=private_setUserVisibleApplicationVersion:, copy) NSString* userVisibleApplicationVersion;

@end


@implementation MvrWiFiChannel

@synthesize name, uniquePeerIdentifier, userVisibleApplicationVersion, applicationVersion;
@synthesize service;

- (id) initWithNetService:(NSNetService*) s;
{
	if (self = [super init]) {
		if ([s TXTRecordData]) {
			NSDictionary* d = [NSNetService dictionaryFromTXTRecordData:[s TXTRecordData]];
			
			self.name = s.name;
			self.uniquePeerIdentifier = MvrStringFromDataOrString([d objectForKey:kMvrWiFiChannelUniqueIdentifierKey]);
			self.userVisibleApplicationVersion = MvrStringFromDataOrString([d objectForKey:kMvrWiFiChannelUserVisibleApplicationVersionKey]);
			
			NSString* appVersion = MvrStringFromDataOrString([d objectForKey:kMvrWiFiChannelApplicationVersionKey]);
			self.applicationVersion = appVersion? [appVersion doubleValue] : 0;
		}
		
		service = [s retain];
		outgoingTransfers = [NSMutableSet new];
		dispatch = [[L0KVODispatcher alloc] initWithTarget:self];
	}
	
	return self;
}

- (void) dealloc;
{
	[name release];
	[uniquePeerIdentifier release];
	[userVisibleApplicationVersion release];
	[outgoingTransfers release];
	[dispatch release];
	
	[service release];
	
	[super dealloc];
}

- (BOOL) sendItemToOtherEndpoint:(L0MoverItem*) i;
{
	MvrWiFiOutgoingTransfer* transfer = [[MvrWiFiOutgoingTransfer alloc] initWithItem:i toChannel:self];

	[dispatch observe:@"finished" ofObject:transfer usingSelector:@selector(transferDidChangeFinished:change:) options:0];
	[outgoingTransfers addObject:transfer];
	
	[transfer start];
	return YES;
}

- (void) transferDidChangeFinished:(MvrWiFiOutgoingTransfer*) transfer change:(NSDictionary*) change;
{
	if (!transfer.finished) return;
	
	[dispatch endObserving:@"finished" ofObject:transfer];
	[outgoingTransfers removeObject:transfer];
}

@end
