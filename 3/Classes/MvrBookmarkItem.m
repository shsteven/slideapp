//
//  MvrBookmarkItem.m
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrBookmarkItem.h"
#import "Network+Storage/MvrUTISupport.h"
#import "Network+Storage/MvrItemStorage.h"

@interface MvrBookmarkItem ()

@property(setter=private_setAddress:, copy) NSURL* address;

@end


@implementation MvrBookmarkItem

+ supportedTypes;
{
	return [NSSet setWithObject:(id) kUTTypeURL];
}

- (id) initWithAddress:(NSURL*) url;
{
	if (self = [super init]) {
		if (![[url scheme] isEqual:@"http"] && ![[url scheme] isEqual:@"https"] && ![[url scheme] isEqual:@"ftp"]) {
			[self release];
			return nil;
		}
		
		self.type = (id) kUTTypeURL;
		self.address = url;
		self.title = [url host];
	}
	
	return self;
}

MvrItemSynthesizeCopyFromAutocache(NSURL*, address, private_setAddress:)

- (NSURL*) objectForEmptyAddressCacheKey;
{
	NSString* string = [[[NSString alloc] initWithData:self.storage.data encoding:NSUTF8StringEncoding] autorelease];
	return [NSURL URLWithString:string];
}

- (id) produceExternalRepresentation;
{
	NSString* string = [self.address absoluteString];
	return [string dataUsingEncoding:NSUTF8StringEncoding];
}

@end
