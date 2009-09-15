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
	
	NSMutableSet* incomingTransfers;
	NSMutableSet* outgoingTransfers;

	L0KVODispatcher* dispatcher;
}

@property(retain) MvrModernWiFiChannel* modernChannel;
@property(retain) MvrLegacyWiFiChannel* legacyChannel;

- (void) addChannel:(id) chan;
- (BOOL) removeChannelAndReturnIfEmpty:(id) chan;

- (void) changeKey:(NSString*) key withKVOChange:(NSDictionary*) change;

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

@synthesize modernChannel, legacyChannel;

- (void) dealloc;
{
	[dispatcher release]; dispatcher = nil;
	
	self.modernChannel = nil;
	self.legacyChannel = nil;
	
	[super dealloc];
}

- (void) setModernChannel:(MvrModernWiFiChannel *) chan;
{
	if (chan != modernChannel) {
		if (modernChannel) {
			[dispatcher endObserving:@"incomingTransfers" ofObject:modernChannel];
			[dispatcher endObserving:@"outgoingTransfers" ofObject:modernChannel];
		}
		
		[modernChannel release];
		modernChannel = [chan retain];
		
		if (modernChannel) {
			[dispatcher observe:@"incomingTransfers" ofObject:modernChannel usingSelector:@selector(channel:didChangeIncomingTransfers:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
			[dispatcher observe:@"outgoingTransfers" ofObject:modernChannel usingSelector:@selector(channel:didChangeOutgoingTransfers:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
		}
	}
}

- (void) setLegacyChannel:(MvrLegacyWiFiChannel *) chan;
{
	if (chan != legacyChannel) {
		if (legacyChannel) {
			[dispatcher endObserving:@"incomingTransfers" ofObject:legacyChannel];
			[dispatcher endObserving:@"outgoingTransfers" ofObject:legacyChannel];
		}
		
		[legacyChannel release];
		legacyChannel = [chan retain];
		
		if (legacyChannel) {
			[dispatcher observe:@"incomingTransfers" ofObject:legacyChannel usingSelector:@selector(channel:didChangeIncomingTransfers:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
			[dispatcher observe:@"outgoingTransfers" ofObject:legacyChannel usingSelector:@selector(channel:didChangeOutgoingTransfers:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
		}
	}
}

- (void) addChannel:(id) chan;
{
	if ([chan isKindOfClass:[MvrModernWiFiChannel class]])
		self.modernChannel = chan;
	else if ([chan isKindOfClass:[MvrLegacyWiFiChannel class]])
		self.legacyChannel = chan;
	else
		return;
}

- (BOOL) removeChannelAndReturnIfEmpty:(id) chan;
{
	if ([chan isEqual:self.modernChannel])
		self.modernChannel = nil;
	else if ([chan isEqual:self.legacyChannel])
		self.legacyChannel = chan;

	return !self.modernChannel && !self.legacyChannel;
}

- (void) channel:(id) chan didChangeIncomingTransfers:(NSDictionary*) change;
{
	[self changeKey:@"incomingTransfers" withKVOChange:change];
}

- (void) channel:(id) chan didChangeOutgoingTransfers:(NSDictionary*) change;
{
	[self changeKey:@"outgoingTransfers" withKVOChange:change];
}

- (void) changeKey:(NSString*) key withKVOChange:(NSDictionary*) change;
{
	NSMutableSet* set = [self mutableSetValueForKey:@"incomingTransfers"];
	
	NSSet* objects;
	
	if ((objects = L0KVOPreviousValue(change)))
		[set minusSet:objects];
	
	if ((objects = L0KVOChangedValue(change)))
		[set unionSet:objects];
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
	else 
		return [self.legacyChannel valueForKey:key];

}

- (NSString*) displayName;
{
	return [self askChannelsForKey:@"displayName"];
}

- (void) beginSendingItem:(MvrItem *)item;
{
	if (self.modernChannel)
		[self.modernChannel beginSendingItem:item];
	else
		[self.legacyChannel beginSendingItem:item];
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
		dispatcher = [[L0KVODispatcher alloc] initWithTarget:self];
		
		[dispatcher observe:@"channels" ofObject:self.modernWiFi usingSelector:@selector(scanner:didChangeChannels:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
		[dispatcher observe:@"channels" ofObject:self.legacyWiFi usingSelector:@selector(scanner:didChangeChannels:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
		
		[dispatcher observe:@"enabled" ofObject:self.modernWiFi usingSelector:@selector(scanner:didChangeEnabledKey:) options:NSKeyValueObservingOptionPrior];
		[dispatcher observe:@"jammed" ofObject:self.modernWiFi usingSelector:@selector(scanner:didChangeEnabledKey:) options:NSKeyValueObservingOptionPrior];
		[dispatcher observe:@"enabled" ofObject:self.legacyWiFi usingSelector:@selector(scanner:didChangeJammedKey:) options:NSKeyValueObservingOptionPrior];
		[dispatcher observe:@"jammed" ofObject:self.legacyWiFi usingSelector:@selector(scanner:didChangeJammedKey:) options:NSKeyValueObservingOptionPrior];
	}
	
	return self;
}

@synthesize modernWiFi, legacyWiFi;

- (void) dealloc;
{
	[dispatcher release];
	
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

- (void) setEnabled:(BOOL) e;
{
	self.modernWiFi.enabled = e;
	self.legacyWiFi.enabled = e;
}

- (BOOL) jammed;
{
	return self.modernWiFi.jammed && self.legacyWiFi.jammed;
}

- (void) scanner:(id)mwf didChangeEnabledKey:(NSDictionary *)change;
{
	if (L0KVOIsPrior(change))
		[self willChangeValueForKey:@"enabled"];
	else
		[self didChangeValueForKey:@"enabled"];
}

- (void) scanner:(id)mwf didChangeJammedKey:(NSDictionary *)change;
{
	if (L0KVOIsPrior(change))
		[self willChangeValueForKey:@"jammed"];
	else
		[self didChangeValueForKey:@"jammed"];
}

#pragma mark Channel synthesis.

- (NSSet*) channels;
{
	return [NSSet setWithArray:[channelsByIdentifier allValues]];
}

- (void) scanner:(id) mwf didChangeChannels:(NSDictionary*) change;
{
	[dispatcher forEachSetChange:change forObject:mwf invokeSelectorForInsertion:@selector(scanner:didAddChannel:) removal:@selector(scanner:didRemoveChannel:)];
}

- (void) scanner:(id) mwf didAddChannel:(id) chan;
{
	MvrSyntheticWiFiChannel* syn = [channelsByIdentifier objectForKey:[chan identifier]];
	if (syn)
		[syn addChannel:chan];
	else {
		syn = [[MvrSyntheticWiFiChannel new] autorelease];
		
		[self willChangeValueForKey:@"channels" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:syn]];
		[channelsByIdentifier setObject:syn forKey:[chan identifier]];
		[self didChangeValueForKey:@"channels" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:syn]];
	}
}

- (void) scanner:(id) mwf didRemoveChannel:(id) chan;
{
	MvrSyntheticWiFiChannel* syn = [channelsByIdentifier objectForKey:[chan identifier]];
	if (syn) {
		
		BOOL shouldRemove = [syn removeChannelAndReturnIfEmpty:chan];
		
		if (shouldRemove) {
		
			[self willChangeValueForKey:@"channels" withSetMutation:NSKeyValueMinusSetMutation usingObjects:[NSSet setWithObject:syn]];
			[channelsByIdentifier removeObjectForKey:[chan identifier]];
			[self didChangeValueForKey:@"channels" withSetMutation:NSKeyValueMinusSetMutation usingObjects:[NSSet setWithObject:syn]];
			
		}
	}
}

@end
