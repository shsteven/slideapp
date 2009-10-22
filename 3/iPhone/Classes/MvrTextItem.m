//
//  MvrTextItem.m
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
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
		[self.metadata setDictionary:[self defaultMetadata]];
	}
	
	return self;
}

- (NSDictionary*) defaultMetadata;
{
	NSString* title = [self.text length] > 40? [NSString stringWithFormat:@"%@\u2026", [self.text substringToIndex:40]] : self.text;
	return [NSDictionary dictionaryWithObject:title forKey:kMvrItemTitleMetadataKey];
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
