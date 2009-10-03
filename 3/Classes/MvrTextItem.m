//
//  MvrTextItem.m
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrTextItem.h"

@interface MvrTextItem ()

@property(copy, setter=private_setText:) NSString* text;

@end


@implementation MvrTextItem

+ supportedTypes;
{
	return [NSSet setWithObject:(id) kUTTypeUTF8PlainText];
}

- (id) initWithText:(NSString*) text;
{
	if (self = [super init]) {
		self.text = text;
		self.type = (id) kUTTypeUTF8PlainText;
		self.title = [text length] > 40? [NSString stringWithFormat:@"%@\u2026", [text substringToIndex:40]] : text;
	}
	
	return self;
}

MvrItemSynthesizeCopyFromAutocache(NSString*, text, private_setText:)

- (NSString*) objectForEmptyTextCacheKey;
{
	return [[[NSString alloc] initWithData:self.storage.data encoding:NSUTF8StringEncoding] autorelease];
}

- (id) produceExternalRepresentation;
{
	return [self.text dataUsingEncoding:NSUTF8StringEncoding];
}

@end
