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

static BOOL initialized = NO;
static MvrAppleAdItem* items[7];

+ adItemWithNumber:(int) n;
{
	return items[n];
}

+ adItemForReceiving;
{
	return items[3];
}

+ (void) initialize;
{
	if (!initialized) {
		initialized = YES;
		int i; for (i = 0; i < 7; i++) {
			items[i] = [[self alloc] initWithNumber:i];
		}
	}
}

- (id) initWithNumber:(int) n;
{
	if (self = [super init]) {
		self.title = @"";
		self.type = kMvrAppleAdItemType;

		NSString* path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%d", n] ofType:@"jpg"];
		image = [[UIImage alloc] initWithContentsOfFile:path];
		
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

- (void) dealloc;
{
	[image release];
	[super dealloc];
}

@end
