//
//  MvrModernWiFiChannel.m
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrModernWiFiChannel.h"

#import <MuiKit/MuiKit.h>
#import "MvrModernWiFiOutgoing.h"
#import "MvrModernWiFiIncoming.h"

@implementation MvrModernWiFiChannel

- (id) initWithNetService:(NSNetService *)ns identifier:(NSString *)ident;
{
	if (self = [super initWithNetService:ns identifier:ident]) {
		if ([ns TXTRecordData]) {
			NSDictionary* metadata = [NSNetService dictionaryFromTXTRecordData:[ns TXTRecordData]];
			id d = [metadata objectForKey:kMvrModernWiFiBonjourCapabilitiesKey];
			
			if ([d isKindOfClass:[NSData class]])
				d = [[[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding] autorelease];
			
			if (d) {
				long long capabilities = [d longLongValue];
				if (capabilities >= 0 && capabilities < kMvrCapabilityMaximum)
					supportsExtendedMetadata = (capabilities & kMvrCapabilityExtendedMetadata) != 0;
			}
		}
	}
	
	return self;
}

@synthesize supportsExtendedMetadata;

#pragma mark Outgoing transfers

- (void) beginSendingItem:(MvrItem*) item;
{
	MvrModernWiFiOutgoing* outgoing = [[MvrModernWiFiOutgoing alloc] initWithItem:item toAddresses:self.netService.addresses options:self.supportsExtendedMetadata? kMvrModernWiFiOutgoingAllowExtendedMetadata : 0];

	[self.dispatcher observe:@"finished" ofObject:outgoing usingSelector:@selector(outgoingTransfer:finishedDidChange:) options:0];
	
	[outgoing start];
	[self.mutableOutgoingTransfers addObject:outgoing];
	[outgoing release];
}

- (void) outgoingTransfer:(MvrModernWiFiOutgoing*) transfer finishedDidChange:(NSDictionary*) change;
{
	if (!transfer.finished)
		return;
	
	[self.dispatcher endObserving:@"finished" ofObject:transfer];
	[self.mutableOutgoingTransfers removeObject:transfer];
}

- (BOOL) supportsStreams;
{
	return YES;
}

#pragma mark Incoming transfers

- (void) addIncomingTransfersObject:(MvrModernWiFiIncoming*) incoming;
{
	SEL iOC = @selector(incomingTransfer:itemOrCancelledChanged:);
	[incoming observeUsingDispatcher:self.dispatcher invokeAtItemChange:iOC atCancelledChange:iOC atKeyChange:NULL];
	[super addIncomingTransfersObject:incoming];
}
	 
- (void) incomingTransfer:(MvrModernWiFiIncoming*) transfer itemOrCancelledChanged:(NSDictionary*) changed;
{
	[transfer endObservingUsingDispatcher:self.dispatcher];
	[self.mutableIncomingTransfers removeObject:transfer];
}

@end
