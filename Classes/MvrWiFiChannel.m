//
//  MvrWiFiChannel.m
//  Mover
//
//  Created by ∞ on 26/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFiChannel.h"

static NSString* MvrStringFromDataOrString(id x) {
	if (!x) return nil;
	
	if ([x isKindOfClass:[NSString class]])
		return x;
	
	if ([x isKindOfClass:[NSData class]])
		return [[[NSString alloc] initWithData:x encoding:NSUTF8StringEncoding] autorelease];
	
	NSCAssert(NO, @"Neither a NSString nor a NSData instance: %@");
	return nil;
}

@interface MvrWiFiChannel ()

@property(setter=private_setName:, copy) NSString* name;
@property(setter=private_setUniquePeerIdentifier:, copy) NSString* uniquePeerIdentifier;
@property(setter=private_setApplicationVersion:, assign) double applicationVersion;
@property(setter=private_setUserVisibleApplicationVersion:, copy) NSString* userVisibleApplicationVersion;

@end


@implementation MvrWiFiChannel

@synthesize name, uniquePeerIdentifier, userVisibleApplicationVersion, applicationVersion;
@synthesize service;

- (id) initWithNetService:(NSNetService*) s;
{
	if (self = [super init]) {
		if ([s TXTRecordData]) {
			NSDictionary* d = [NSNetService dictionaryFromTXTRecordData:[s TXTRecordData]];
			
			self.name = s.name;
			self.uniquePeerIdentifier = MvrStringFromDataOrString([d objectForKey:kMvrWiFiChannelUniqueIdentifierKey]);
			self.userVisibleApplicationVersion = MvrStringFromDataOrString([d objectForKey:kMvrWiFiChannelUserVisibleApplicationVersionKey]);
			
			NSString* appVersion = MvrStringFromDataOrString([d objectForKey:kMvrWiFiChannelApplicationVersionKey]);
			self.applicationVersion = appVersion? [appVersion doubleValue] : 0;
		}
		
		service = [s retain];
	}
	
	return self;
}

- (void) dealloc;
{
	[name release];
	[uniquePeerIdentifier release];
	[userVisibleApplicationVersion release];
	
	[service release];
	
	[super dealloc];
}

- (BOOL) sendItemToOtherEndpoint:(L0MoverItem*) i;
{
	return NO;
}

@end
