//
//  MvrBTProtocol.h
//  Mover3
//
//  Created by ∞ on 20/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMvrBTProtocolStarterSequenceNumber (0)

enum {
	kMvrBTProtocolFinishedWithoutErrors = 0,
	kMvrBTProtocolOutOfOrderReception,
	kMvrBTProtocolTooMuchDataReceived,
	kMvrBTProtocolCannotBacktrackSoMuch,
	// kMvrBTProtocolCRC32DidNotMatch,
};
typedef NSInteger MvrBTProtocolErrorReason;

@protocol MvrBTProtocolIncomingDelegate, MvrBTProtocolOutgoingDelegate;


@interface MvrBTProtocolOutgoing : NSObject {
	id <MvrBTProtocolOutgoingDelegate> delegate;
	BOOL started;
	NSUInteger latestSequenceNumber;
}

@property(assign) id <MvrBTProtocolOutgoingDelegate> delegate;

- (void) start;
- (void) didAcknowledgeWithSequenceNumber:(NSUInteger) sequenceNumber;
- (void) didSignalErrorWithSequenceNumber:(NSUInteger) sequenceNumber;

@end

@protocol MvrBTProtocolOutgoingDelegate <NSObject>

- (void) sendStarter;

- (void) preparePacketWithSequenceNumber:(NSUInteger) sequenceNumber;
- (BOOL) isPacketAvailableWithSequenceNumber:(NSUInteger) sequenceNumber;
- (void) sendPacketWithSequenceNumber:(NSUInteger) sequenceNumber;

- (BOOL) isPayloadAllSent;

- (void) startMonitoringTimeout;
- (void) stopMonitoringTimeout;

- (void) endConnectionWithReason:(MvrBTProtocolErrorReason) reason;

@end


@interface MvrBTProtocolIncoming : NSObject {
	id <MvrBTProtocolIncomingDelegate> delegate;
	NSInteger state;
	NSUInteger lastReceivedSequenceNumber;
	size_t remainingLength;
}

@property(assign) id <MvrBTProtocolIncomingDelegate> delegate;

- (void) didReceiveStarter;
- (void) didReceivePacketStartWithSequenceNumber:(NSUInteger) number length:(size_t) length;
- (void) didReceivePacketPart:(NSData*) part;

@end

@protocol MvrBTProtocolIncomingDelegate <NSObject>

- (void) sendAcknowledgementForSequenceNumber:(NSUInteger) seq;
- (void) signalErrorForSequenceNumber:(NSUInteger) seq reason:(MvrBTProtocolErrorReason) reason;

- (void) startMonitoringTimeout;
- (void) stopMonitoringTimeout;

- (BOOL) isPayloadAllReceived;

- (void) endConnectionWithReason:(MvrBTProtocolErrorReason) reason;

@end
