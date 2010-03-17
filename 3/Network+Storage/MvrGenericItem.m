//
//  MvrGenericItem.m
//  Network+Storage
//
//  Created by ∞ on 13/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrGenericItem.h"

#import "MvrUTISupport.h"
#import "MvrItemStorage.h"

@implementation MvrGenericItem

+ supportedTypes;
{
	return [NSSet setWithObject:(id) kUTTypeData];
}

- (id) initWithStorage:(MvrItemStorage*) s metadata:(NSDictionary*) m;
{
	return [self initWithStorage:s type:(id) kUTTypeData metadata:m];
}

- (id) initWithStorage:(MvrItemStorage *)s type:(NSString *)t metadata:(NSDictionary *)m;
{
	L0Log(@"Will create a generic item for storage %@ of type %@, metadata %@", s, t, m);
	return [super initWithStorage:s type:t metadata:m];
}

- (id) produceExternalRepresentation;
{
	return [self.storage preferredContentObject];
}

- (BOOL) requiresStreamSupport;
{
	return YES;
}

@end
