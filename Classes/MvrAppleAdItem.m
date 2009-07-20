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
	float color = number * 40 / 255.0;
	if (color > 1)
		color = 1;
	
	UIGraphicsBeginImageContext(CGSizeMake(30, 30));
	CGContextRef context = UIGraphicsGetCurrentContext();
	UIColor* gray = [UIColor colorWithWhite:color alpha:1.0];
	CGContextSetFillColorWithColor(context, gray.CGColor);
	UIImage* i = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return i;
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
