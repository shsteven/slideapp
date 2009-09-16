//
//  MvrScannerObserver.m
//  Network+Storage
//
//  Created by ∞ on 16/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrScannerObserver.h"

@interface MvrScannerObserver ()

- (void) beginObservingScanner;
- (void) endObservingScanner;

- (void) beginObservingChannel:(id <MvrChannel>) chan;
- (void) endObservingChannel:(id <MvrChannel>) chan;

- (void) beginObservingIncomingTransfer:(id <MvrIncoming>) incoming ofChannel:(id <MvrChannel>) chan;
- (void) endObservingIncomingTransfer:(id <MvrIncoming>) incoming;

- (void) beginObservingOutgoingTransfer:(id <MvrOutgoing>) outgoing ofChannel:(id <MvrChannel>) chan;
- (void) endObservingOutgoingTransfer:(id <MvrOutgoing>) outgoing;

@end


#import <MuiKit/MuiKit.h>

@implementation MvrScannerObserver

- (id) initWithScanner:(id <MvrScanner>) s delegate:(id <MvrScannerObserverDelegate>) d;
{
	if (self = [super init]) {
		kvo = [[L0KVODispatcher alloc] initWithTarget:self];

		delegate = d; // it owns us
		scanner = [s retain];
		
		[self beginObservingScanner];
	}
	
	return self;
}

- (void) dealloc;
{
	[self endObservingScanner];
	[kvo release];
	[super dealloc];
}

- (NSString*) description;
{
	return [NSString stringWithFormat:@"%@ { delegate = %@; }", [super description], delegate];
}

#pragma mark -
#pragma mark Observing scanners.

- (void) scanner:(id <MvrScanner>) s didChangeJammedKey:(NSDictionary*) d;
{
	[delegate scanner:s didChangeJammedKey:s.jammed];
}

- (void) scanner:(id <MvrScanner>) s didChangeEnabledKey:(NSDictionary*) d;
{
	[delegate scanner:s didChangeEnabledKey:s.enabled];
}

- (void) scanner:(id <MvrScanner>)s didChangeChannelsKey:(NSDictionary *)d;
{
	[kvo forEachSetChange:d forObject:s invokeSelectorForInsertion:@selector(scanner:didAddChannel:) removal:@selector(scanner:didRemoveChannel:)];
}

- (void) scanner:(id <MvrScanner>)s didAddChannel:(id <MvrChannel>) chan;
{
	L0Log(@"%@.channels += %@", s, chan);
	[self beginObservingChannel:chan];
}

- (void) scanner:(id <MvrScanner>)s didRemoveChannel:(id <MvrChannel>) chan;
{
	L0Log(@"%@.channels -= %@", s, chan);
	[self endObservingChannel:chan];
}

- (void) beginObservingScanner;
{
	L0Log(@"%@", scanner);
	
	[delegate scanner:scanner didChangeJammedKey:scanner.jammed];
	[delegate scanner:scanner didChangeEnabledKey:scanner.enabled];
	
	[kvo observe:@"enabled" ofObject:scanner usingSelector:@selector(scanner:didChangeJammedKey:) options:0];
	[kvo observe:@"jammed" ofObject:scanner usingSelector:@selector(scanner:didChangeEnabledKey:) options:0];
	
	for (id <MvrChannel> chan in scanner.channels)
		[self beginObservingChannel:chan];
	
	[kvo observe:@"channels" ofObject:scanner usingSelector:@selector(scanner:didChangeChannelsKey:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
}

- (void) endObservingScanner;
{
	L0Log(@"%@", scanner);
	
	for (id <MvrChannel> chan in scanner.channels)
		[self endObservingChannel:chan];
	
	[kvo endObserving:@"channels" ofObject:scanner];
	[kvo endObserving:@"jammed" ofObject:scanner];
	[kvo endObserving:@"enabled" ofObject:scanner];
}

#pragma mark -
#pragma mark Observing channels.

- (void) channel:(id <MvrChannel>) chan didChangeIncomingTransfersKey:(NSDictionary*) change;
{
	[kvo forEachSetChange:change forObject:chan invokeSelectorForInsertion:@selector(channel:didAddIncomingTransfer:) removal:@selector(channel:didRemoveIncomingTransfer:)];
}

- (void) channel:(id <MvrChannel>) chan didAddIncomingTransfer:(id <MvrIncoming>) incoming;
{
	L0Log(@"%@.incomingTransfers += %@", chan, incoming);
	[self beginObservingIncomingTransfer:incoming ofChannel:chan];
}

- (void) channel:(id <MvrChannel>) chan didRemoveIncomingTransfer:(id <MvrIncoming>) incoming;
{
	L0Log(@"%@.incomingTransfers -= %@", chan, incoming);
	[self endObservingIncomingTransfer:incoming];
}


- (void) channel:(id <MvrChannel>) chan didChangeOutgoingTransfersKey:(NSDictionary*) change;
{
	[kvo forEachSetChange:change forObject:chan invokeSelectorForInsertion:@selector(channel:didAddOutgoingTransfer:) removal:@selector(channel:didRemoveOutgoingTransfer:)];
}

- (void) channel:(id <MvrChannel>) chan didAddOutgoingTransfer:(id <MvrOutgoing>) outgoing;
{
	L0Log(@"%@.outgoingTransfers += %@", chan, outgoing);
	[self beginObservingOutgoingTransfer:outgoing ofChannel:chan];
}

- (void) channel:(id <MvrChannel>) chan didRemoveOutgoingTransfer:(id <MvrOutgoing>) outgoing;
{
	L0Log(@"%@.outgoingTransfers -= %@", chan, outgoing);
	[self endObservingOutgoingTransfer:outgoing];
}


- (void) beginObservingChannel:(id <MvrChannel>) chan;
{
	L0Log(@"%@", chan);
	[delegate scanner:scanner didAddChannel:chan];
	
	for (id <MvrIncoming> incoming in chan.incomingTransfers)
		[self beginObservingIncomingTransfer:incoming ofChannel:chan];
	
	[kvo observe:@"incomingTransfers" ofObject:chan usingSelector:@selector(channel:didChangeIncomingTransfersKey:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
	
	for (id <MvrOutgoing> outgoing in chan.outgoingTransfers)
		[self beginObservingOutgoingTransfer:outgoing ofChannel:chan];
	
	[kvo observe:@"outgoingTransfers" ofObject:chan usingSelector:@selector(channel:didChangeOutgoingTransfersKey:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
}

- (void) endObservingChannel:(id <MvrChannel>) chan;
{
	L0Log(@"%@", chan);
	
	for (id <MvrIncoming> incoming in chan.incomingTransfers)
		[self endObservingIncomingTransfer:incoming];
	for (id <MvrOutgoing> outgoing in chan.incomingTransfers)
		[self endObservingOutgoingTransfer:outgoing];

	[kvo endObserving:@"incomingTransfers" ofObject:chan];
	[kvo endObserving:@"outgoingTransfers" ofObject:chan];
}

#pragma mark -
#pragma mark Observing incoming transfers.

- (void) incomingTransfer:(id <MvrIncoming>) incoming didChangeItemOrCancelledKey:(NSDictionary*) change;
{
	if (incoming.cancelled || incoming.item) {
		L0Log(@"%@.cancelled == %d, %@.item == %@", incoming, incoming.cancelled, incoming, incoming.item);

		[delegate incomingTransfer:incoming didEndReceivingItem:(incoming.cancelled? nil : incoming.item)];
		
		[self endObservingIncomingTransfer:incoming];
	}
}

- (void) endObservingIncomingTransfer:(id <MvrIncoming>) incoming;
{
	[kvo endObserving:@"item" ofObject:incoming];
	[kvo endObserving:@"cancelled" ofObject:incoming];
}

- (void) beginObservingIncomingTransfer:(id <MvrIncoming>) incoming ofChannel:(id <MvrChannel>) chan;
{
	L0Log(@"%@ (from %@.incomingTransfers)", incoming, chan);
	[delegate channel:chan didBeginReceivingWithIncomingTransfer:incoming];
	
	if (incoming.cancelled || incoming.item)
		[delegate incomingTransfer:incoming didEndReceivingItem:(incoming.cancelled? nil : incoming.item)];
	else {
		[kvo observe:@"item" ofObject:incoming usingSelector:@selector(incomingTransfer:didChangeItemOrCancelledKey:) options:0];
		[kvo observe:@"cancelled" ofObject:incoming usingSelector:@selector(incomingTransfer:didChangeItemOrCancelledKey:) options:0];
	}
}

#pragma mark -
#pragma mark Observing incoming transfers.

- (void) outgoingTransfer:(id <MvrOutgoing>) outgoing didChangeFinishedKey:(NSDictionary*) d;
{
	L0Log(@"%@.finished == %d", outgoing, outgoing.finished);
	if (outgoing.finished) {
		[delegate outgoingTransferDidEndSending:outgoing];
		[self endObservingOutgoingTransfer:outgoing];
	}
}

- (void) endObservingOutgoingTransfer:(id <MvrOutgoing>) outgoing;
{
	L0Log(@"%@", outgoing);
	[kvo endObserving:@"finished" ofObject:outgoing];
}

- (void) beginObservingOutgoingTransfer:(id <MvrOutgoing>) outgoing ofChannel:(id <MvrChannel>) chan;
{
	L0Log(@"%@ (from %@.outgoingTransfers", outgoing, chan);
	[delegate channel:chan didBeginSendingWithOutgoingTransfer:outgoing];
	
	if (outgoing.finished)
		[delegate outgoingTransferDidEndSending:outgoing];
	else
		[kvo observe:@"finished" ofObject:outgoing usingSelector:@selector(outgoingTransfer:didChangeFinishedKey:) options:0];
}

@end
