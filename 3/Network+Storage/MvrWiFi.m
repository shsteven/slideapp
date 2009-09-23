//
//  MvrWiFi.m
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFi.h"

#import "MvrChannel.h"

#import "MvrModernWiFi.h"
#import "MvrLegacyWiFi.h"
#import "MvrModernWiFiChannel.h"
#import "MvrLegacyWiFiChannel.h"


@interface MvrSyntheticWiFiChannel : NSObject <MvrChannel> {
	MvrModernWiFiChannel* modernChannel;
	MvrLegacyWiFiChannel* legacyChannel;
	MvrLegacyWiFiChannel* legacyLegacyChannel;
	
	NSMutableSet* incomingTransfers;
	NSMutableSet* outgoingTransfers;

	L0KVODispatcher* dispatcher;
}

@property(retain) MvrModernWiFiChannel* modernChannel;
@property(retain) MvrLegacyWiFiChannel* legacyChannel;
@property(retain) MvrLegacyWiFiChannel* legacyLegacyChannel; // ridiculous, yet.

- (void) addChannel:(id) chan;
- (BOOL) removeChannelAndReturnIfEmpty:(id) chan;

- askChannelsForKey:(NSString*) key;

@end

@implementation MvrSyntheticWiFiChannel

- (id) init
{
	self = [super init];
	if (self != nil) {
		dispatcher = [[L0KVODispatcher alloc] initWithTarget:self];
	}
	return self;
}

@synthesize modernChannel, legacyChannel, legacyLegacyChannel;

- (void) dealloc;
{
	[dispatcher release];
	
	self.modernChannel = nil;
	self.legacyChannel = nil;
	self.legacyLegacyChannel = nil;
	
	[super dealloc];
}

- (void) addChannel:(id) chan;
{
	if ([chan isKindOfClass:[MvrModernWiFiChannel class]])
		self.modernChannel = chan;
	else if ([chan isKindOfClass:[MvrLegacyWiFiChannel class]]) {
		if ([chan isLegacyLegacy])
			self.legacyChannel = chan;
		else
			self.legacyLegacyChannel = chan;
	} else
		return;
}

- (BOOL) removeChannelAndReturnIfEmpty:(id) chan;
{
	if ([chan isEqual:self.modernChannel])
		self.modernChannel = nil;
	else if ([chan isEqual:self.legacyChannel])
		self.legacyChannel = nil;
	else if ([chan isEqual:self.legacyLegacyChannel])
		self.legacyLegacyChannel = nil;

	return !self.modernChannel && !self.legacyChannel && !self.legacyLegacyChannel;
}

- (NSSet*) incomingTransfers;
{
	return incomingTransfers;
}

- (NSSet*) outgoingTransfers;
{
	return outgoingTransfers;
}

- askChannelsForKey:(NSString*) key;
{
	if (self.modernChannel)
		return [self.modernChannel valueForKey:key];
	else if (self.legacyChannel)
		return [self.legacyChannel valueForKey:key];
	else
		return [self.legacyLegacyChannel valueForKey:key];
}

- (NSString*) displayName;
{
	return [self askChannelsForKey:@"displayName"];
}

- (void) beginSendingItem:(MvrItem *)item;
{
	if (self.modernChannel)
		[self.modernChannel beginSendingItem:item];
	else if (self.legacyChannel)
		[self.legacyChannel beginSendingItem:item];
	else
		[self.legacyLegacyChannel beginSendingItem:item];
}

@end



@implementation MvrWiFi

- (id) initWithPlatformInfo:(id <MvrPlatformInfo>) info modernPort:(int) modernPort legacyPort:(int) legacyPort;
{
	self = [super init];
	if (self != nil) {
		self.modernWiFi = [[[MvrModernWiFi alloc] initWithPlatformInfo:info serverPort:modernPort] autorelease];
		self.legacyWiFi = [[[MvrLegacyWiFi alloc] initWithPlatformInfo:info serverPort:legacyPort] autorelease];
		
		channelsByIdentifier = [NSMutableDictionary new];
		modernObserver = [[MvrScannerObserver alloc] initWithScanner:self.modernWiFi delegate:self];
		legacyObserver = [[MvrScannerObserver alloc] initWithScanner:self.legacyWiFi delegate:self];
	}
	
	return self;
}

@synthesize modernWiFi, legacyWiFi;

- (void) dealloc;
{
	[modernObserver release];
	[legacyObserver release];
	
	self.modernWiFi = nil;
	self.legacyWiFi = nil;
	[channelsByIdentifier release];
	[super dealloc];
}

#pragma mark KVO notifications

- (BOOL) enabled;
{
	return self.modernWiFi.enabled || self.legacyWiFi.enabled;
}

+ (NSSet *) keyPathsForValuesAffectingEnabled;
{
	return [NSSet setWithObjects:@"modernWiFi.enabled", @"legacyWiFi.enabled", nil];
}

- (void) setEnabled:(BOOL) e;
{
	self.modernWiFi.enabled = e;
	self.legacyWiFi.enabled = e;
}

- (BOOL) jammed;
{
	return self.modernWiFi.jammed && self.legacyWiFi.jammed;
}

+ (NSSet *) keyPathsForValuesAffectingJammed;
{
	return [NSSet setWithObjects:@"modernWiFi.jammed", @"legacyWiFi.jammed", nil];
}

- (NSSet*) channels;
{
	return [NSSet setWithArray:[channelsByIdentifier allValues]];
}

#pragma mark Observer methods

- (void) scanner:(id <MvrScanner>) s didChangeJammedKey:(BOOL) jammed {}
- (void) scanner:(id <MvrScanner>) s didChangeEnabledKey:(BOOL) enabled {}

- (void) scanner:(id <MvrScanner>) s didAddChannel:(id <MvrChannel>) channel;
{
	NSString* ident = [(id)channel identifier];
	MvrSyntheticWiFiChannel* syn = [channelsByIdentifier objectForKey:ident];
	
	if (!syn) {		
		syn = [[MvrSyntheticWiFiChannel new] autorelease];
		
		[self willChangeValueForKey:@"channels" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:syn]];
		
		[syn addChannel:channel];
		[channelsByIdentifier setObject:syn forKey:ident];
		
		[self didChangeValueForKey:@"channels" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:syn]];
	} else
		[syn addChannel:channel];
}

- (void) scanner:(id <MvrScanner>) s didRemoveChannel:(id <MvrChannel>) channel;			
{
	NSString* ident = [(id)channel identifier];
	MvrSyntheticWiFiChannel* syn = [channelsByIdentifier objectForKey:ident];
	
	if (syn) {
		
		BOOL deleteMe = [syn removeChannelAndReturnIfEmpty:channel];
		if (deleteMe) {
			[self willChangeValueForKey:@"channels" withSetMutation:NSKeyValueMinusSetMutation usingObjects:[NSSet setWithObject:syn]];
			
			[channelsByIdentifier removeObjectForKey:ident];

			[self didChangeValueForKey:@"channels" withSetMutation:NSKeyValueMinusSetMutation usingObjects:[NSSet setWithObject:syn]];
		}
		
	}
}

- (void) channel:(id <MvrChannel>) channel didBeginReceivingWithIncomingTransfer:(id <MvrIncoming>) incoming;
{
	NSString* ident = [(id)channel identifier];
	MvrSyntheticWiFiChannel* syn = [channelsByIdentifier objectForKey:ident];
	[[syn mutableSetValueForKey:@"incomingTransfers"] addObject:incoming];
}

- (void) channel:(id <MvrChannel>) channel didBeginSendingWithOutgoingTransfer:(id <MvrOutgoing>) outgoing;
{
	NSString* ident = [(id)channel identifier];
	MvrSyntheticWiFiChannel* syn = [channelsByIdentifier objectForKey:ident];
	[[syn mutableSetValueForKey:@"outgoingTransfers"] addObject:outgoing];
}

- (void) outgoingTransferDidEndSending:(id <MvrOutgoing>) outgoing;
{
	for (NSString* ident in channelsByIdentifier) {
		MvrSyntheticWiFiChannel* syn = [channelsByIdentifier objectForKey:ident];
		[[syn mutableSetValueForKey:@"outgoingTransfers"] removeObject:outgoing];
	}
}

// i == nil if cancelled.
- (void) incomingTransfer:(id <MvrIncoming>) incoming didEndReceivingItem:(MvrItem*) i;
{
	for (NSString* ident in channelsByIdentifier) {
		MvrSyntheticWiFiChannel* syn = [channelsByIdentifier objectForKey:ident];
		[[syn mutableSetValueForKey:@"incomingTransfers"] removeObject:incoming];
	}
}

@end
