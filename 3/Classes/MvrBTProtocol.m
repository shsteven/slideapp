//
//  MvrBTProtocol.m
//  Mover3
//
//  Created by ∞ on 20/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrBTProtocol.h"
#import "MvrBTDebugTracker.h"

@implementation MvrBTProtocolOutgoing

@synthesize delegate;

- (void) start;
{
	if (started)
		return;
	started = YES;
	
	MvrBTTrack(@"Starting an outgoing session -- sending the starter...");
	
	latestSequenceNumber = kMvrBTProtocolStarterSequenceNumber;
	[delegate sendStarter];
}

- (void) didAcknowledgeWithSequenceNumber:(NSUInteger) sequenceNumber;
{
	if (sequenceNumber != latestSequenceNumber) {
		MvrBTTrack(@"We've got an ack for a packet other than the last one. ouch!");
		[delegate endConnectionWithReason:kMvrBTProtocolOutOfOrderReception];
		return;
	}
	
	if (![delegate isPayloadAllSent]) {
		MvrBTTrack(@"Post-ack, sending the next packet");
		latestSequenceNumber++;
		[delegate sendPacketWithSequenceNumber:latestSequenceNumber];
	} else {
		MvrBTTrack(@"We've finished! Yay!");
		[delegate endConnectionWithReason:kMvrBTProtocolFinishedWithoutErrors];
	}
}

- (void) didSignalErrorWithSequenceNumber:(NSUInteger) sequenceNumber;
{
	MvrBTTrack(@"We've got a nack for packet %lu.", sequenceNumber);

	if ([delegate isPastPacketAvailableWithSequenceNumber:sequenceNumber]) {
		MvrBTTrack(@"We've got a nack for packet %lu. Resending because we have it.", sequenceNumber);
		latestSequenceNumber = sequenceNumber;
		[delegate sendPacketWithSequenceNumber:sequenceNumber];
	} else {
		MvrBTTrack(@"We have lost that packet. Closing it.");
		[delegate endConnectionWithReason:kMvrBTProtocolCannotBacktrackSoMuch];
	}
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
		MvrBTTrack(@"Received a starter out of order!");
		[delegate endConnectionWithReason:kMvrBTProtocolOutOfOrderReception];
		return;
	}
	
	MvrBTTrack(@"Received a starter -- setting up show and sending ack!");
	lastReceivedSequenceNumber = kMvrBTProtocolStarterSequenceNumber;
	state = kMvrStateWaitingForPacketStart;
	[delegate sendAcknowledgementForSequenceNumber:lastReceivedSequenceNumber];
}

- (void) didReceivePacketStartWithSequenceNumber:(NSUInteger) number length:(size_t) length;
{
	if (state != kMvrStateWaitingForPacketStart) {
		MvrBTTrack(@"Received an initial packet out of order! Asking for a resend of %lu.", (unsigned long) lastReceivedSequenceNumber);
		[delegate signalErrorForSequenceNumber:lastReceivedSequenceNumber reason:kMvrBTProtocolOutOfOrderReception];
		return;
	}
	
	if (number != lastReceivedSequenceNumber + 1) {
		MvrBTTrack(@"Received an initial packet for an unwanted packet (%lu, we were expecting %lu)! Asking for a resend!", (unsigned long) number, (unsigned long) lastReceivedSequenceNumber + 1, (unsigned long) lastReceivedSequenceNumber);
		[delegate signalErrorForSequenceNumber:lastReceivedSequenceNumber + 1 reason:kMvrBTProtocolOutOfOrderReception];
		return;
	}
	
	MvrBTTrack(@"Received a packet start with number %lu. Now expecting %zu bytes.", number, length);
	lastReceivedSequenceNumber = number;
	state = kMvrStateWaitingForPacketPart;
	remainingLength = length;	
}

- (void) didReceivePacketPart:(NSData*) part;
{
	if (state != kMvrStateWaitingForPacketPart) {
		MvrBTTrack(@"Received actual data packet out of order!");
		
		if (lastReceivedSequenceNumber == 0) {
			MvrBTTrack(@"We haven't received a packet yet, so, um, there's nothing to ask back. Dropping.");
			[delegate endConnectionWithReason:kMvrBTProtocolOutOfOrderReception];
		} else {
			MvrBTTrack(@"Asking for a resend of %lu.", (unsigned long) lastReceivedSequenceNumber);
			[delegate signalErrorForSequenceNumber:lastReceivedSequenceNumber reason:kMvrBTProtocolOutOfOrderReception];
		}
		
		return;
	}
	
	if ([part length] > remainingLength) {
		MvrBTTrack(@"I was expecting %lu more bytes, but I got %lu. Ouch. We're seriously messed up. Closing.", (unsigned long) remainingLength, (unsigned long) [part length]);
		[delegate endConnectionWithReason:kMvrBTProtocolTooMuchDataReceived];
		return;
	}
	
	MvrBTTrack(@"Got %lu bytes off %lu I was expecting.", (unsigned long) [part length], (unsigned long) remainingLength);
	remainingLength -= [part length];
	
	if (remainingLength == 0) {
		MvrBTTrack(@"We've got all bytes; now sending ack for this packet (%lu)", lastReceivedSequenceNumber);
		[delegate sendAcknowledgementForSequenceNumber:lastReceivedSequenceNumber];
		
		if ([delegate isPayloadAllReceived]) {
			MvrBTTrack(@"We've got all the payload! Yay!");
			[delegate endConnectionWithReason:kMvrBTProtocolFinishedWithoutErrors];
		} else
			state = kMvrStateWaitingForPacketStart;
	}
}

@end
