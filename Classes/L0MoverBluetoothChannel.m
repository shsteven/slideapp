//
//  L0MoverBluetoothChannel.m
//  Mover
//
//  Created by ∞ on 11/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverBluetoothChannel.h"
#import <MuiKit/MuiKit.h>

#import "MvrProtocol.h"

static const size_t kL0MoverBluetoothMessageHeaderLength = sizeof(char) * 5;

static const char kL0MoverBluetoothMessageHeader_ItemTransfer[] = { 'M', 'O', 'V', 'E', 'R' };
static const char kL0MoverBluetoothMessageHeader_Acknowledgment[] = { 'M', 'V', 'a', 'c', 'k' };


static BOOL L0MoverBluetoothStartsWithHeader(const char* packet, const char* with) {
	int i; for (i = 0; i < kL0MoverBluetoothMessageHeaderLength; i++) {
		if (packet[i] != with[i])
			return NO;
	}
	
	return YES;
}

#define kL0MoverBluetoothTitleKey @"Title"
#define kL0MoverBluetoothTypeKey @"Type"
#define kL0MoverBluetoothExternalRepresentationKey @"Data"

@interface L0MoverBluetoothChannel ()

- (void) endSendingItem;
- (void) sendBlockOfData;

- (void) endReceivingItem:(L0MoverItem*) i;
- (void) receiveItemFromData:(NSData*) d;

@end

#pragma mark -
#pragma mark Transfer marker.

@interface MvrLegacyBluetoothIncomingTransfer : NSObject <MvrIncoming>
{
	L0MoverItem* item;
}

- (void) setItem:(L0MoverItem*) i;

@end

@implementation MvrLegacyBluetoothIncomingTransfer

@synthesize item;
- (void) setItem:(L0MoverItem*) i;
{
	if (i != item) {
		[item release];
		item = [i retain];
	}
}

- (CGFloat) progress { return kMvrPacketIndeterminateProgress; }


- (void) dealloc;
{
	[item release];
	[super dealloc];
}

@end


@implementation L0MoverBluetoothChannel

@synthesize uniquePeerIdentifier;

- (id) initWithScanner:(L0MoverBluetoothScanner*) s peerID:(NSString*) p;
{
	if (self = [super init]) {
		scanner = s;
		peerID = [p copy];
		
		NSString* nameAndID = [s.bluetoothSession displayNameForPeer:p];
		NSRange barRange = [nameAndID rangeOfString:@"|" options:NSBackwardsSearch];
		NSInteger indexPastBar = barRange.location == NSNotFound? 0 : barRange.location + barRange.length;
		
		if (barRange.location == NSNotFound || indexPastBar >= [nameAndID length]) {
			L0LogAlways(@"Owch! This Bluetooth peer (%@) has no pipe character in its name or no UUID past the bar -- suspiciously unusual. We're making a new UUID for it anyway, so that the machinery won't be confused by it.", nameAndID);
			uniquePeerIdentifier = [[[L0UUID UUID] stringValue] copy];
			name = [nameAndID copy];
		} else {
			uniquePeerIdentifier = [[nameAndID substringFromIndex:indexPastBar] copy];
			name = [[nameAndID substringToIndex:barRange.location] copy];
		}
		
		currentTransfer = [MvrLegacyBluetoothIncomingTransfer new];
	}
	
	return self;
}

- (void) dealloc;
{
	[self endCommunicationWithOtherEndpoint];
	[peerID release];
	[name release];
	[uniquePeerIdentifier release];
	[currentTransfer release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Communication

- (void) communicateWithOtherEndpoint;
{
	L0Log(@"Communication ping");
	
	if (itemToBeSent && !dataToBeSent) {
		L0Log(@"Preparing to send item");
		dataToBeSent = [NSMutableData new];
		[dataToBeSent appendBytes:kL0MoverBluetoothMessageHeader_ItemTransfer length:kL0MoverBluetoothMessageHeaderLength];
		
		NSData* externalRep = [itemToBeSent externalRepresentation];
		NSString* title = itemToBeSent.title;
		NSString* type = itemToBeSent.type;
		
		NSMutableDictionary* payloadPlist = [NSMutableDictionary dictionary];
		[payloadPlist setObject:title forKey:kL0MoverBluetoothTitleKey];
		[payloadPlist setObject:type forKey:kL0MoverBluetoothTypeKey];
		[payloadPlist setObject:externalRep forKey:kL0MoverBluetoothExternalRepresentationKey];
		
		NSString* err = nil;
		NSData* d = [NSPropertyListSerialization dataFromPropertyList:payloadPlist format:NSPropertyListBinaryFormat_v1_0 errorDescription:&err];
		if (err) {
			L0LogAlways(@"An error occurred while plistifying item %@: %@", itemToBeSent, err);
			[self endSendingItem];
			return;
		}
		
		NSInteger len = [d length];
		if (len > INT32_MAX) {
			L0LogAlways(@"Too big to send: %@", itemToBeSent);
			[self endSendingItem];
			return;
		}
		
		uint32_t lenNetwork = htonl(len);
		[dataToBeSent appendBytes:&lenNetwork length:sizeof(uint32_t)];
		[dataToBeSent appendData:d];		
		[self sendBlockOfData];
	}	
}

#define kL0MoverBluetoothSingleSendLimit (30 * 1024)

- (void) sendBlockOfData;
{
	if (!dataToBeSent) return;
	// sanity check
	if (![[scanner.bluetoothSession peersWithConnectionState:GKPeerStateConnected] containsObject:peerID]) {
		[self endCommunicationWithOtherEndpoint];
		return;
	}
	L0Log(@"Sending block of data...");
	
	BOOL done = NO;
	
	NSData* toSend = nil;
	NSRange sentRange = NSMakeRange(0, kL0MoverBluetoothSingleSendLimit);
	if ([dataToBeSent length] > kL0MoverBluetoothSingleSendLimit) {
		toSend = [dataToBeSent subdataWithRange:sentRange];
	} else {
		toSend = dataToBeSent; done = YES;
	}
	
	NSError* e = nil;
	if (![scanner.bluetoothSession sendData:toSend toPeers:[NSArray arrayWithObject:peerID] withDataMode:GKSendDataReliable error:&e]) {
		L0LogAlways(@"An error occurred while sending the item: %@", e);
		if ([e code] != GKSessionTransportError)
			done = YES;
	}
	
	if (!done) {
		[dataToBeSent replaceBytesInRange:sentRange withBytes:NULL length:0];
	} else
		[self endSendingItem];
}

- (BOOL) sendItemToOtherEndpoint:(L0MoverItem*) i;
{
	if (itemToBeSent)
		return NO;

	[scanner.service channel:self willSendItemToOtherEndpoint:i];

	itemToBeSent = [i retain];
	if ([[scanner.bluetoothSession peersWithConnectionState:GKPeerStateConnected] containsObject:peerID])
		[self communicateWithOtherEndpoint];
	else
		[scanner.bluetoothSession connectToPeer:peerID withTimeout:5.0];
	
	return YES;
}

- (void) endSendingItem;
{	
	L0Log(@"Ending send");
	
	if (itemToBeSent) {
		[scanner.service channel:self didSendItemToOtherEndpoint:itemToBeSent];
		[itemToBeSent release]; itemToBeSent = nil;
	}
	
	if (dataToBeSent) {
		[dataToBeSent release]; dataToBeSent = nil;
	}
	
	return;
}

- (void) receiveDataFromOtherEndpoint:(NSData*) data;
{
	L0Log(@"Received data.");
	
	if (dataToBeSent) {
		L0Log(@"Will check for acknowledgment...");
		// see if it's an acknowledgment
		if ([data length] >= kL0MoverBluetoothMessageHeaderLength &&
			L0MoverBluetoothStartsWithHeader([data bytes], kL0MoverBluetoothMessageHeader_Acknowledgment)) {
			L0Log(@"Did acknowledge! Sending new block.");
			[self sendBlockOfData];
		}
		
		return;
	}
	
	if (!dataReceived) {
		L0Log(@"First data of new item.");
		dataReceived = [NSMutableData new];
		[scanner.service channel:self didStartReceiving:currentTransfer];
	}
	
	if ([data length] >= kL0MoverBluetoothMessageHeaderLength) {
		[dataReceived appendData:data];

		const char* packetAtHeader = (const char*) [dataReceived bytes];
		if (!L0MoverBluetoothStartsWithHeader(packetAtHeader, kL0MoverBluetoothMessageHeader_ItemTransfer)) {
			[self endReceivingItem:nil];
			return;
		}
	}
	
	if ([dataReceived length] >= kL0MoverBluetoothMessageHeaderLength + sizeof(uint32_t)) {
		uint32_t* packetAtNetworkLength = (uint32_t*) ([dataReceived bytes] + kL0MoverBluetoothMessageHeaderLength);
		uint32_t networkLength = *packetAtNetworkLength;
		uint32_t length = ntohl(networkLength);
		
		NSInteger restOfLength = [dataReceived length] - kL0MoverBluetoothMessageHeaderLength - sizeof(uint32_t);
		
		if (restOfLength >= length) {
			NSData* payload = [dataReceived subdataWithRange:NSMakeRange(kL0MoverBluetoothMessageHeaderLength + sizeof(uint32_t), restOfLength)];
			[self receiveItemFromData:payload];
		}
	}
	
	NSData* d = [NSData dataWithBytes:kL0MoverBluetoothMessageHeader_Acknowledgment length:kL0MoverBluetoothMessageHeaderLength];
	[scanner.bluetoothSession sendData:d toPeers:[NSArray arrayWithObject:self.peerID] withDataMode:GKSendDataReliable error:NULL];
}

- (void) receiveItemFromData:(NSData*) d;
{
	L0Log(@"Full data received, unpacking");
	L0MoverItem* i = nil;
	
	NSString* error;
	id plist = [NSPropertyListSerialization propertyListFromData:d mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&error];
	
	if (error) {
		L0LogAlways(@"Could not turn the payload into a plist: %@", error);
		[error release];
	}
	
	NSString* title = nil, * type = nil;
	NSData* externalRep = nil;
	if (plist && [plist isKindOfClass:[NSDictionary class]]) {
		title = [plist objectForKey:kL0MoverBluetoothTitleKey];
		if (![title isKindOfClass:[NSString class]]) title = nil;
		
		type = [plist objectForKey:kL0MoverBluetoothTypeKey];
		if (![type isKindOfClass:[NSString class]]) type = nil;

		externalRep = [plist objectForKey:kL0MoverBluetoothExternalRepresentationKey];
		if (![externalRep isKindOfClass:[NSData class]]) externalRep = nil;
	}
	
	if (title && type && externalRep) {
		i = [[[[L0MoverItem classForType:type] alloc] initWithExternalRepresentation:externalRep type:type title:title] autorelease];
	}
	
	[self endReceivingItem:i];
}

- (void) endReceivingItem:(L0MoverItem*) i;
{
	L0Log(@"Ending reception...");
	if (!dataReceived) return;
	L0Log(@"Ending with received item %@", i);
	
	[currentTransfer setItem:i];
	[scanner.service channel:self didStopReceiving:currentTransfer];
	[currentTransfer setItem:nil];
	
	[dataReceived release];
	dataReceived = nil;
}

- (void) endCommunicationWithOtherEndpoint;
{
	[self endSendingItem];
	[self endReceivingItem:nil];
}

@synthesize name, peerID;

- (double) applicationVersion;
{
	return kL0UnknownApplicationVersion;
}

- (NSString*) userVisibleApplicationVersion;
{
	return nil;
}

@end
