//
//  L0WiFiBeamingPeer.m
//  Shard
//
//  Created by ∞ on 24/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0BonjourPeer.h"

#import <sys/socket.h>
#import <netinet/in.h>

#import "L0MoverAppDelegate+MvrAppleAd.h"

static inline CFMutableDictionaryRef L0CFDictionaryCreateMutableForObjects() {
	return CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
}

@interface L0BonjourPeer ()

@property(assign, setter=privateSetApplicationVersion:) double applicationVersion;
@property(copy, setter=privateSetUserVisibleApplicationVersion:) NSString* userVisibleApplicationVersion;

@end


@implementation L0BonjourPeer

@synthesize service = _service;
@synthesize applicationVersion, userVisibleApplicationVersion;

- (id) initWithNetService:(NSNetService*) service;
{
	if (self = [super init]) {
		_service = [service retain];
		_itemsBeingSentByConnection = L0CFDictionaryCreateMutableForObjects();
		
		NSData* txtData = [service TXTRecordData];
		if (txtData) {
			NSDictionary* info = [NSNetService dictionaryFromTXTRecordData:txtData];
			L0Log(@"Parsing info dictionary %@ for peer %@", info, self);
			
			NSData* appVersionData;
			if (appVersionData = [info objectForKey:kL0BonjourPeerApplicationVersionKey])
				self.applicationVersion = [[[[NSString alloc] initWithData:appVersionData encoding:NSUTF8StringEncoding] autorelease] doubleValue];
			
			NSData* userVisibleAppVersionData;
			if (userVisibleAppVersionData = [info objectForKey:kL0BonjourPeerUserVisibleApplicationVersionKey])
				self.userVisibleApplicationVersion = [[[NSString alloc] initWithData:userVisibleAppVersionData encoding:NSUTF8StringEncoding] autorelease];
			
			L0Log(@"App version found: %f.", self.applicationVersion);
			L0Log(@"User visible app version found: %@", self.userVisibleApplicationVersion);
			
			them = [[AsyncSocket alloc] initWithDelegate:self];
			[them connectToAddress:[[service addresses] objectAtIndex:0] error:NULL];
		}
	}
	
	return self;
}

- (void) dealloc;
{
	[_service release];
	
	[keepAliveTimer invalidate];
	[keepAliveTimer release];
	
	CFRelease(_itemsBeingSentByConnection);
	
	them.delegate = nil;
	[them disconnect];
	[them release];
	
	[super dealloc];
}

- (NSString*) name;
{
	return [_service name];
}

- (BOOL) receiveItem:(L0MoverItem*) item;
{
	const char byteToSend = 'K';
	[them writeData:[NSData dataWithBytes:&byteToSend length:sizeof(char)] withTimeout:60 tag:0];
	[Mover beginSendingForAppleAdWithItem:item];
	return YES;
}

- (void) sendKeepAlive:(NSTimer*) t;
{
	const char byteToSend = 'W';
	[them writeData:[NSData dataWithBytes:&byteToSend length:sizeof(char)] withTimeout:60 tag:0];
}

- (void) onSocketDidDisconnect:(AsyncSocket*) sock;
{
	[sock connectToAddress:[[_service addresses] objectAtIndex:0] error:NULL];
}

@end
