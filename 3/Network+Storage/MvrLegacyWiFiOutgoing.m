//
//  MvrLegacyWiFiOutgoing.m
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrLegacyWiFiOutgoing.h"

#import "MvrLegacyWiFi.h"

NSString* const kMvrLegacyWiFiOutgoingErrorDomain = @"MvrLegacyWiFiOutgoingErrorDomain";

@interface MvrLegacyWiFiOutgoing ()

- (void) endWithError:(NSError*) e;
@property(retain) NSError* error;

@property BOOL finished;

@end


@implementation MvrLegacyWiFiOutgoing

- (id) initWithItem:(MvrItem*) i toNetService:(NSNetService*) s;
{
	self = [super init];
	if (self != nil) {
		item = [i retain];
		service = [s retain];
	}
	return self;
}

@synthesize finished, error;

- (void) dealloc
{
	[self endWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
	[error release];
	[item release];
	[service release];
	[super dealloc];
}

#pragma mark -
#pragma mark Sending.

- (void) start;
{
	if (item.requiresStreamSupport) {
		[self endWithError:[NSError errorWithDomain:kMvrLegacyWiFiOutgoingErrorDomain code:kMvrLegacyWiFiOutgoingItemRequiresStreamError userInfo:nil]];
		return;
	}
	
	connection = [[BLIPConnection alloc] initToNetService:service];
	connection.delegate = self;
	[connection open];
}

- (void) endWithError:(NSError*) e;
{
	if (self.finished) return;
	
	self.error = e;
	
	[connection closeWithTimeout:5.0];
	connection.delegate = nil;
	[connection release]; connection = nil;
	
	[item release]; item = nil;
	[service release]; service = nil;
	
	self.finished = YES;
}

- (void) connectionDidOpen: (TCPConnection*)c;
{
	[connection sendRequest:[item contentsAsBLIPRequest]];
}

- (void) connection: (BLIPConnection*)connection receivedResponse: (BLIPResponse*)response;
{
	[self endWithError:nil];
}

- (BOOL) connectionReceivedCloseRequest: (BLIPConnection*)connection;
{
	[self endWithError:nil];
	return YES;
}

- (MvrItem *) item;
{
	return item;
}

@end
