//
//  MvrPacketBuilderTest.m
//  Mover
//
//  Created by ∞ on 24/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <OCMock/OCMock.h>

#import "MvrPacketBuilder.h"
#import "MvrPacketTestsCommon.h"

@interface MvrPacketBuilderTest_AccumulatingDelegate : NSObject <MvrPacketBuilderDelegate>
{
	BOOL didStart, didFinish;
	NSMutableData* packetData;
	NSError* finalError;
}

@property(readonly) NSData* packet;
@property(readonly) BOOL didStart, didFinish;
@property(readonly) NSError* finalError;

- (BOOL) runBuilderToEnd:(MvrPacketBuilder*) b;

@end

@implementation MvrPacketBuilderTest_AccumulatingDelegate

- (NSData*) packet;
{
	return packetData;
}

- (id) init;
{
	if (self = [super init])
		packetData = [NSMutableData new];
	
	return self;
}

- (void) dealloc;
{
	[packetData release];
	[finalError release];
	[super dealloc];
}

- (void) packetBuilderWillStart:(MvrPacketBuilder*) builder;
{
	didStart = YES;
}

- (void) packetBuilder:(MvrPacketBuilder*) builder didProduceData:(NSData*) d;
{
	[packetData appendData:d];
}

- (void) packetBuilder:(MvrPacketBuilder*) builder didEndWithError:(NSError*) e;
{
	if (e != finalError) {
		[finalError release];
		finalError = [e retain];
		
		if (e) {
			NSLog(@"Did detect an error: %@", e);
		}
	}
	
	didFinish = YES;
}

- (BOOL) runBuilderToEnd:(MvrPacketBuilder*) b;
{
	int attempts = 0;
	[b start];
	
	while (!didFinish) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
		attempts++;
		if (attempts >= 10) return NO;
	}
	
	return YES;
}

@synthesize finalError, didStart, didFinish;

@end



#pragma mark -
#pragma mark Actual tests

@interface MvrPacketBuilderTest : SenTestCase
{
}

@end

@implementation MvrPacketBuilderTest

- (void) testConstructingValidPacket;
{
	MvrPacketBuilderTest_AccumulatingDelegate* delegate = 
		[[MvrPacketBuilderTest_AccumulatingDelegate new] autorelease];
	
	MvrPacketBuilder* builder = [[[MvrPacketBuilder alloc] initWithDelegate:delegate] autorelease];
	[builder setMetadataValue:@"A short test packet" forKey:@"Title"];
	[builder setMetadataValue:@"net.infinite-labs.Mover.test-packet" forKey:@"Type"];
	[builder addPayloadWithData:[@"OK" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"okay"];
	[builder addPayloadWithData:[@"WOW" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"wow"];

	STAssertTrue([delegate runBuilderToEnd:builder], @"Does not time out");
	
	STAssertTrue(delegate.didStart, nil);
	STAssertNil(delegate.finalError, nil);
	STAssertEqualObjects(delegate.packet, MvrPacketTestValidPacket(), nil);
}

- (void) testConstructingValidPacketFromFileStreams;
{
	MvrPacketBuilderTest_AccumulatingDelegate* delegate = 
		[[MvrPacketBuilderTest_AccumulatingDelegate new] autorelease];
	
	MvrPacketBuilder* builder = [[[MvrPacketBuilder alloc] initWithDelegate:delegate] autorelease];
	[builder setMetadataValue:@"A short test packet" forKey:@"Title"];
	[builder setMetadataValue:@"net.infinite-labs.Mover.test-packet" forKey:@"Type"];
	
	NSString* resourcesPath = [[NSBundle bundleForClass:[self class]] resourcePath];
	NSError* e = nil;
	STAssertTrue([builder addPayloadByReferencingFile:[resourcesPath stringByAppendingPathComponent:@"OK.data"] forKey:@"okay" error:&e],
				 @"Should not fail with an error: %@", e);
	STAssertTrue([builder addPayloadByReferencingFile:[resourcesPath stringByAppendingPathComponent:@"WOW.data"] forKey:@"wow" error:&e],
				 @"Should not fail with an error: %@", e);
	
	[builder addPayloadWithData:[@"WOW" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"wow"];
	
	STAssertTrue([delegate runBuilderToEnd:builder], @"Does not time out");
	
	STAssertTrue(delegate.didStart, nil);
	STAssertNil(delegate.finalError, nil);
	STAssertEqualObjects(delegate.packet, MvrPacketTestValidPacket(), nil);
}

- (void) testConstructingValidPacketFromLongerFileStreams_FirstIsLonger;
{
	MvrPacketBuilderTest_AccumulatingDelegate* delegate = 
	[[MvrPacketBuilderTest_AccumulatingDelegate new] autorelease];
	
	MvrPacketBuilder* builder = [[[MvrPacketBuilder alloc] initWithDelegate:delegate] autorelease];
	[builder setMetadataValue:@"A short test packet" forKey:@"Title"];
	[builder setMetadataValue:@"net.infinite-labs.Mover.test-packet" forKey:@"Type"];
	
	NSString* resourcesPath = [[NSBundle bundleForClass:[self class]] resourcePath];
	NSError* e = nil;
	
	NSInputStream* ist = [NSInputStream inputStreamWithFileAtPath:[resourcesPath stringByAppendingPathComponent:@"OK-longer.data"]];
	[builder addPayload:ist length:2 forKey:@"okay"];
	
	STAssertTrue([builder addPayloadByReferencingFile:[resourcesPath stringByAppendingPathComponent:@"WOW.data"] forKey:@"wow" error:&e],
				 @"Should not fail with an error: %@", e);
	
	STAssertTrue([delegate runBuilderToEnd:builder], @"Does not time out");
	
	STAssertTrue(delegate.didStart, nil);
	STAssertNil(delegate.finalError, @"Error: %@", delegate.finalError);
	STAssertEqualObjects(delegate.packet, MvrPacketTestValidPacket(), nil);
}

- (void) testConstructingValidPacketFromLongerFileStreams_SecondIsLonger;
{
	MvrPacketBuilderTest_AccumulatingDelegate* delegate = 
	[[MvrPacketBuilderTest_AccumulatingDelegate new] autorelease];
	
	MvrPacketBuilder* builder = [[[MvrPacketBuilder alloc] initWithDelegate:delegate] autorelease];
	[builder setMetadataValue:@"A short test packet" forKey:@"Title"];
	[builder setMetadataValue:@"net.infinite-labs.Mover.test-packet" forKey:@"Type"];
	
	NSString* resourcesPath = [[NSBundle bundleForClass:[self class]] resourcePath];	
	[builder addPayloadWithData:[@"OK" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"okay"];
	
	NSInputStream* ist = [NSInputStream inputStreamWithFileAtPath:[resourcesPath stringByAppendingPathComponent:@"WOW-longer.data"]];
	[builder addPayload:ist length:3 forKey:@"wow"];
	
	[builder addPayloadWithData:[@"WOW" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"wow"];
	
	STAssertTrue([delegate runBuilderToEnd:builder], @"Does not time out");
	
	STAssertTrue(delegate.didStart, nil);
	STAssertNil(delegate.finalError, nil);
	STAssertEqualObjects(delegate.packet, MvrPacketTestValidPacket(), nil);
}

- (void) testConstructingValidPacketFromLongerFileStreams_BothAreLonger;
{
	MvrPacketBuilderTest_AccumulatingDelegate* delegate = 
		[[MvrPacketBuilderTest_AccumulatingDelegate new] autorelease];
	
	MvrPacketBuilder* builder = [[[MvrPacketBuilder alloc] initWithDelegate:delegate] autorelease];
	[builder setMetadataValue:@"A short test packet" forKey:@"Title"];
	[builder setMetadataValue:@"net.infinite-labs.Mover.test-packet" forKey:@"Type"];
	
	NSString* resourcesPath = [[NSBundle bundleForClass:[self class]] resourcePath];
	
	NSInputStream* ist = [NSInputStream inputStreamWithFileAtPath:[resourcesPath stringByAppendingPathComponent:@"OK-longer.data"]];
	[builder addPayload:ist length:2 forKey:@"okay"];
	
	ist = [NSInputStream inputStreamWithFileAtPath:[resourcesPath stringByAppendingPathComponent:@"WOW-longer.data"]];
	[builder addPayload:ist length:3 forKey:@"wow"];
	
	[builder addPayloadWithData:[@"WOW" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"wow"];
	
	STAssertTrue([delegate runBuilderToEnd:builder], @"Does not time out");
	
	STAssertTrue(delegate.didStart, nil);
	STAssertNil(delegate.finalError, nil);
	STAssertEqualObjects(delegate.packet, MvrPacketTestValidPacket(), nil);
}

- (void) testFailingWhenStreamIsTooShort;
{
	MvrPacketBuilderTest_AccumulatingDelegate* delegate = 
	[[MvrPacketBuilderTest_AccumulatingDelegate new] autorelease];
	
	MvrPacketBuilder* builder = [[[MvrPacketBuilder alloc] initWithDelegate:delegate] autorelease];
	[builder setMetadataValue:@"A short test packet" forKey:@"Title"];
	[builder setMetadataValue:@"net.infinite-labs.Mover.test-packet" forKey:@"Type"];
	
	NSString* resourcesPath = [[NSBundle bundleForClass:[self class]] resourcePath];
	
	[builder addPayloadWithData:[@"OK" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"okay"];
		
	NSInputStream* ist = [NSInputStream inputStreamWithFileAtPath:[resourcesPath stringByAppendingPathComponent:@"WOW-tooshort.data"]];
	[builder addPayload:ist length:3 forKey:@"wow"];
	
	STAssertTrue([delegate runBuilderToEnd:builder], @"Does not time out");
	
	STAssertTrue(delegate.didStart, nil);
	STAssertNotNil(delegate.finalError, nil);
}

@end
