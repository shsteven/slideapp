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

enum {
	kMvrNoTimingTag,
	kMvrTimingTagFirstImpulse,
	
	kMvrTimingTagReturnOfFirstImpulse,
};

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
	
	self.itemSendingDate = nil;
	
	[super dealloc];
}

- (NSString*) name;
{
	return [_service name];
}

- (BOOL) receiveItem:(L0MoverItem*) item;
{
	[keepAliveTimer invalidate];
	[keepAliveTimer release];
	
	const char byteToSend = 'K';
	[them writeData:[NSData dataWithBytes:&byteToSend length:sizeof(char)] withTimeout:60 tag:kMvrTimingTagFirstImpulse];
	[Mover beginSendingForAppleAdWithItem:item];
	
	self.itemSendingDate = [NSDate date];
	
	return YES;
}

- (void) sendKeepAlive:(NSTimer*) t;
{
	const char byteToSend = 'W';
	[them writeData:[NSData dataWithBytes:&byteToSend length:sizeof(char)] withTimeout:60 tag:kMvrNoTimingTag];
}

- (void) onSocket:(AsyncSocket*) sock didWriteDataWithTag:(long) tag;
{
	if (tag == kMvrTimingTagFirstImpulse)
		[them readDataToLength:1 withTimeout:60 tag:kMvrTimingTagReturnOfFirstImpulse];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;
{
	if (tag == kMvrTimingTagReturnOfFirstImpulse) {
		NSDate* now = [NSDate date];
		NSTimeInterval elapsed = [now timeIntervalSinceDate:self.itemSendingDate];
		
		NSTimeInterval finalImpulseSendMoment = (kMvrDelayBetweenSendAndReceive - elapsed / 2);
		
		L0Log(@"Will send final impulse in %f (or now if negative).", finalImpulseSendMoment);
		// we need to warn in duration - elapsed/2 seconds.
		if (finalImpulseSendMoment > 0)
			[self performSelector:@selector(sendEndingImpulse) withObject:nil afterDelay:finalImpulseSendMoment];
		else {
			// sumimasen, director! I failed you!
			[self sendEndingImpulse];
		}
	}
}

- (void) sendEndingImpulse;
{
	const char byteToSend = 'Z';
	[them writeData:[NSData dataWithBytes:&byteToSend length:sizeof(char)] withTimeout:60 tag:kMvrNoTimingTag];
	self.itemSendingDate = nil;
	[Mover returnItemAfterSendForAppleAd];
}

- (void) onSocketDidDisconnect:(AsyncSocket*) sock;
{
	[sock connectToAddress:[[_service addresses] objectAtIndex:0] error:NULL];
}

@synthesize itemSendingDate;

@end
