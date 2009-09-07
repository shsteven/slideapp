//
//  L0BookmarkItem.m
//  Mover
//
//  Created by ∞ on 12/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0BookmarkItem.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "MvrStorageCentral.h"

@implementation L0BookmarkItem

static id <L0BookmarkItemStorage> L0BookmarkItemCurrentStorage = nil;

+ (void) setStorage:(id <L0BookmarkItemStorage>) s;
{
	if (L0BookmarkItemCurrentStorage != s) {
		[L0BookmarkItemCurrentStorage release];
		L0BookmarkItemCurrentStorage = [s retain];
	}
}

+ (id <L0BookmarkItemStorage>) storage;
{
	return L0BookmarkItemCurrentStorage;
}

- (id) initWithAddress:(NSURL*) url title:(NSString*) t;
{
	if (self = [super init]) {
		self.type = (id) kUTTypeURL;
		self.address = url;
		self.title = t;
		self.representingImage = [UIImage imageNamed:@"BookmarkIcon.png"];
	}
	
	return self;
}

@synthesize address;

- (void) dealloc;
{
	[address release];
	[super dealloc];
}

+ (NSArray*) supportedTypes;
{
	return [NSArray arrayWithObject:(id) kUTTypeURL];
}

- (NSData*) produceExternalRepresentation;
{
	return [[self.address absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
}

- (id) initWithStorage:(MvrItemStorage*) s type:(NSString*) ty title:(NSString*) ti;
{
	if (self = [super initWithStorage:s type:ty title:ti]) {
		NSString* str = [[NSString alloc] initWithData:s.data encoding:NSUTF8StringEncoding];
		NSURL* theURL = [NSURL URLWithString:str];
		[str release];
		
		self.address = theURL;
	}
	
	return self;
}

- (void) storeToAppropriateApplication;
{
	[[[self class] storage] storeBookmarkItem:self];
}

@end
