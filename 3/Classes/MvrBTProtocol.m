//
//  MvrBTProtocol.m
//  Mover3
//
//  Created by ∞ on 20/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrBTProtocol.h"


@implementation MvrBTProtocolOutgoing

@synthesize delegate;

- (void) start;
{
	if (started)
		return;
	started = YES;
	
	latestSequenceNumber = kMvrBTProtocolStarterSequenceNumber;
	[delegate sendStarter];
}

- (void) didAcknowledgeWithSequenceNumber:(NSUInteger) sequenceNumber;
{
	if (sequenceNumber != latestSequenceNumber) {
		[delegate endConnectionWithReason:kMvrBTProtocolOutOfOrderReception];
		return;
	}
	
	if (![delegate isPayloadAllSent]) {
		latestSequenceNumber++;
		[delegate sendPacketWithSequenceNumber:latestSequenceNumber];
	} else
		[delegate endConnectionWithReason:kMvrBTProtocolFinishedWithoutErrors];
}

- (void) didSignalErrorWithSequenceNumber:(NSUInteger) sequenceNumber;
{
	if ([delegate isPastPacketAvailableWithSequenceNumber:sequenceNumber]) {
		latestSequenceNumber = sequenceNumber;
		[delegate sendPacketWithSequenceNumber:sequenceNumber];
	} else
		[delegate endConnectionWithReason:kMvrBTProtocolCannotBacktrackSoMuch];
}

@end

enum {
	kMvrStateAtRest = 0,
	kMvrStateWaitingForPacketStart,
	kMvrStateWaitingForPacketPart,
};

@implementation MvrBTProtocolIncoming

@synthesize delegate;

- (void) didReceiveStarter;
{
	if (state != kMvrStateAtRest) {
		[delegate endConnectionWithReason:kMvrBTProtocolOutOfOrderReception];
		return;
	}
	
	lastReceivedSequenceNumber = kMvrBTProtocolStarterSequenceNumber;
	state = kMvrStateWaitingForPacketStart;
	[delegate sendAcknowledgementForSequenceNumber:lastReceivedSequenceNumber];
	[delegate startMonitoringTimeout];
}

- (void) didReceivePacketStartWithSequenceNumber:(NSUInteger) number length:(size_t) length;
{
	if (state != kMvrStateWaitingForPacketStart) {
		[delegate signalErrorForSequenceNumber:lastReceivedSequenceNumber reason:kMvrBTProtocolOutOfOrderReception];
		return;
	}
	
	if (number != lastReceivedSequenceNumber + 1) {
		[delegate signalErrorForSequenceNumber:lastReceivedSequenceNumber + 1 reason:kMvrBTProtocolOutOfOrderReception];
		return;
	}
	
	[delegate stopMonitoringTimeout];
	
	lastReceivedSequenceNumber = number;
	state = kMvrStateWaitingForPacketPart;
	remainingLength = length;
	
	[delegate startMonitoringTimeout];
}

- (void) didReceivePacketPart:(NSData*) part;
{
	if ([part length] > remainingLength) {
		[delegate endConnectionWithReason:kMvrBTProtocolTooMuchDataReceived];
		return;
	}
	
	remainingLength -= [part length];
	[delegate stopMonitoringTimeout];
	
	if (remainingLength == 0) {
		[delegate sendAcknowledgementForSequenceNumber:lastReceivedSequenceNumber];
		
		if ([delegate isPayloadAllReceived])
			[delegate endConnectionWithReason:kMvrBTProtocolFinishedWithoutErrors];
		else {
			state = kMvrStateWaitingForPacketStart;
			[delegate startMonitoringTimeout];
		}
	}
}

@end
