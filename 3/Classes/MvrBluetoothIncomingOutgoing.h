#import <Foundation/Foundation.h>

#import "Network+Storage/MvrIncoming.h"
#import "Network+Storage/MvrOutgoing.h"
#import "Network+Storage/MvrPacketParser.h"
#import "Network+Storage/MvrPacketBuilder.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrProtocol.h"
#import "Network+Storage/MvrBuffer.h"
#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrStreamedIncoming.h"

@class MvrBluetoothScanner;

// Implementations are in MvrBluetoothScanner.m

@interface MvrBluetoothIncoming : MvrStreamedIncoming {}
@end

@interface MvrBluetoothOutgoing : NSObject <MvrOutgoing, MvrPacketBuilderDelegate>
{
	MvrItem* item;
	MvrBluetoothScanner* scanner;
	MvrPacketBuilder* builder;
	MvrBuffer* buffer;
	
	BOOL finished;
	NSError* error;
}

- (id) initWithItem:(MvrItem*) i scanner:(MvrBluetoothScanner*) s;
@property(retain) NSError* error;
@property BOOL finished;

- (void) start;
- (void) sendPacketPart;
- (void) acknowledge;

- (void) endWithError:(NSError*) e;

@end
