//
//  L0TextItem.m
//  Mover
//
//  Created by ∞ on 15/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0TextItem.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import "MvrStorageCentral.h"

@interface L0TextItem ()

@property(copy) NSString* text;

@end


@implementation L0TextItem

+ (NSArray*) supportedTypes;
{
	return [NSArray arrayWithObjects:
			(id) kUTTypeUTF8PlainText,
			nil];
}

- (NSData*) produceExternalRepresentation;
{	
	return [self.text dataUsingEncoding:NSUTF8StringEncoding];
}

- (id) initWithStorage:(MvrItemStorage *)s type:(NSString *)ty title:(NSString *)ti
{
	if (self = [super initWithStorage:s type:ty title:ti])
		self.representingImage = [UIImage imageNamed:@"TextIcon.png"];
		
	return self;
}

- (id) initWithText:(NSString*) t;
{
	if (self = [super init]) {
		self.type = (id) kUTTypeUTF8PlainText;
		self.text = t;
		self.title = [t length] > 20? [NSString stringWithFormat:@"%@\u2026", [t substringToIndex:20]] : t;
		self.representingImage = [UIImage imageNamed:@"TextIcon.png"];
	}
	
	return self;
}

- (NSString*) text;
{
	return [self cachedObjectForKey:@"text"];
}

- (void) setText:(NSString *) t;
{
	[self setCachedObject:t forKey:@"text"];
}

- (id) objectForEmptyTextCacheKey;
{
	return [[[NSString alloc] initWithContentsOfFile:self.storage.path encoding:NSUTF8StringEncoding error:NULL] autorelease];
}

- (void) dealloc;
{
	[text release];
	[super dealloc];
}

@end
