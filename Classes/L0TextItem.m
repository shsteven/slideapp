//
//  L0TextItem.m
//  Mover
//
//  Created by ∞ on 15/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0TextItem.h"
#import <MobileCoreServices/MobileCoreServices.h>

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

- (id) initWithExternalRepresentation:(NSData*) payload type:(NSString*) ty title:(NSString*) ti;
{
	NSString* str = [[[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding] autorelease];	
	return [self initWithText:str];
}

@synthesize text;
- (NSString*) text;
{
	if (!text && self.offloadingFile) {
		L0Log(@"Caching from contents of offloading file: %@", self.offloadingFile);
		self.text = [[[NSString alloc] initWithContentsOfFile:self.offloadingFile encoding:NSUTF8StringEncoding error:NULL] autorelease];
	}
	
	return text;
}

- (void) clearCache;
{
	self.text = nil;
}

- (void) dealloc;
{
	[text release];
	[super dealloc];
}

@end
