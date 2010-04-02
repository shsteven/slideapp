//
//  MvrBookmarkItem.m
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrBookmarkItem.h"
#import "Network+Storage/MvrUTISupport.h"
#import "Network+Storage/MvrItemStorage.h"


@interface MvrBookmarkItem ()

@property(setter=private_setAddress:, copy) NSURL* address;

@end

static BOOL MvrBookmarkURLIsNonNilAndSeemsSafe(NSURL* url) {
	return url && ([[url scheme] isEqual:@"http"] || [[url scheme] isEqual:@"https"] || [[url scheme] isEqual:@"ftp"]);
}

@implementation MvrBookmarkItem

+ supportedTypes;
{
	return [NSSet setWithObject:(id) kUTTypeURL];
}

- (id) initWithAddress:(NSURL*) url;
{
	if (self = [super init]) {
		if (!MvrBookmarkURLIsNonNilAndSeemsSafe(url)) {
			[self release];
			return nil;
		}
		
		self.type = (id) kUTTypeURL;
		self.address = url;
		[self.metadata setDictionary:[self defaultMetadata]];
	}
	
	return self;
}

- (id) initWithStorage:(MvrItemStorage *)s type:(NSString *)t metadata:(NSDictionary *)m;
{
	if (self = [super initWithStorage:s type:t metadata:m]) {
		if (!MvrBookmarkURLIsNonNilAndSeemsSafe(self.address)) {
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (NSDictionary*) defaultMetadata;
{
	NSString* host = [self.address host];
	return host? [NSDictionary dictionaryWithObject:host forKey:kMvrItemTitleMetadataKey] : [NSDictionary dictionary];
}

MvrItemSynthesizeCopyFromAutocache(NSURL*, address, private_setAddress:)

- (NSURL*) objectForEmptyAddressCacheKey;
{
	NSString* string = [[[NSString alloc] initWithData:self.storage.data encoding:NSUTF8StringEncoding] autorelease];
	return string? [NSURL URLWithString:string] : nil;
}

- (id) produceExternalRepresentation;
{
	NSString* string = [self.address absoluteString];
	return [string dataUsingEncoding:NSUTF8StringEncoding];
}

@end
