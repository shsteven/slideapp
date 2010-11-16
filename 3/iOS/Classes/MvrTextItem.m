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
	return [NSSet setWithObjects:
			(id) kUTTypeUTF8PlainText,
			(id) kUTTypeUTF16PlainText,
			(id) kUTTypeUTF16ExternalPlainText,
			(id) kUTTypePlainText,
			nil];
}

- (id) initWithText:(NSString*) text;
{
	if ((self = [super init])) {
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

- (BOOL) getEncodingForCurrentType:(NSStringEncoding*) enc;
{
	BOOL found = YES;
	
	if ([type isEqual:(id) kUTTypeUTF8PlainText])
		*enc = NSUTF8StringEncoding;
	else if ([type isEqual:(id) kUTTypeUTF16PlainText] || [type isEqual:(id) kUTTypeUTF16ExternalPlainText])
		*enc = NSUTF16StringEncoding;
	else
		found = NO;
	
	return found;
}

- (NSString*) objectForEmptyTextCacheKey;
{
	NSStringEncoding enc;
	if ([self getEncodingForCurrentType:&enc])
		return [[[NSString alloc] initWithData:self.storage.data encoding:enc] autorelease];
	else
		return [[[NSString alloc] initWithContentsOfFile:self.storage.path usedEncoding:&enc error:NULL] autorelease];
}

- (id) produceExternalRepresentation;
{
	NSStringEncoding enc;
	if (![self getEncodingForCurrentType:&enc])
		enc = NSUTF8StringEncoding;
	
	return [self.text dataUsingEncoding:enc];
}

+ (NSDictionary *) knownFallbackPathExtensions;
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"txt", (id) kUTTypePlainText,
			@"txt", (id) kUTTypeUTF8PlainText,
			@"txt", (id) kUTTypeUTF16PlainText,
			@"txt", (id) kUTTypeUTF16ExternalPlainText,
			nil];
}

@end
