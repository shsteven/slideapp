//
//  MvrAppleAdItem.m
//  Mover
//
//  Created by ∞ on 20/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrAppleAdItem.h"

#define kMvrAppleAdItemType @"net.infinite-labs.AppleAdItem"

@implementation MvrAppleAdItem

+ adItemWithNumber:(int) n;
{
	return [[[self alloc] initWithNumber:n] autorelease];
}

+ (void) initialize;
{
	int i; for (i = 0; i < 7; i++)
		(void) [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", i]];
}

- (id) initWithNumber:(int) n;
{
	if (self = [super init]) {
		self.title = @"";
		self.type = kMvrAppleAdItemType;
		number = n;
	}
	
	return self;
}

+ (NSArray*) supportedTypes;
{
	return [NSArray arrayWithObject:kMvrAppleAdItemType];
}

- (NSData*) externalRepresentation;
{
	uint32_t rep = CFSwapInt32HostToBig(number);
	return [NSData dataWithBytes:&rep length:sizeof(uint32_t)];
}

- (UIImage*) representingImage;
{
	return [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", number]];
}

- (id) initWithExternalRepresentation:(NSData*) payload type:(NSString*) ty title:(NSString*) ti;
{
	if ([payload length] != sizeof(uint32_t)) {
		[self release];
		return nil;
	}
	
	uint32_t* value = (uint32_t*) [payload bytes];
	int i = CFSwapInt32BigToHost(*value);
	return [self initWithNumber:i];
}

@end
