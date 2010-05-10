//
//  MvrItemAction.m
//  Mover3-iPad
//
//  Created by ∞ on 05/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrItemAction.h"

@interface MvrItemAction ()

- (id) initWithDisplayName:(NSString *)string target:(id) target selector:(SEL) selector;

@property(copy, setter=private_setDisplayName:) NSString* displayName;

@end


@implementation MvrItemAction

- (id) initWithDisplayName:(NSString*) string;
{
	if (self = [super init]) {
		self.displayName = string;
		self.available = YES;
	}
	
	return self;
}

- (id) initWithDisplayName:(NSString *)string target:(id) t selector:(SEL) s;
{
	if (self = [self initWithDisplayName:string]) {
		target = t; selector = s;
	}
	
	return self;
}

@synthesize displayName, available;

- (void) dealloc
{
	self.displayName = nil;
	
#if __BLOCKS__
	[block release];
#endif
	
	[super dealloc];
}

+ actionWithDisplayName:(NSString*) name target:(id) target selector:(SEL) selector;
{
	return [[[self alloc] initWithDisplayName:name target:target selector:selector] autorelease];
}

- (void) performActionWithItem:(id) i;
{
	if (!(target && selector)
#if __BLOCKS__
		&& !(block && !target && !selector)
#endif
	)	
		L0AbstractMethod();
	
	if (target && selector)
		[target performSelector:selector withObject:self withObject:i];
	
#if __BLOCKS__
	if (block)
		block(i);
#endif
}

- (BOOL) isAvailableForItem:(MvrItem*) i;
{
	return self.available;
}

#if __BLOCKS__
- (id) initWithDisplayName:(NSString *)string block:(MvrItemActionBlock) b;
{
	if (self = [self initWithDisplayName:string])
		block = [b copy];
	
	return self;
}

+ actionWithDisplayName:(NSString*) name block:(MvrItemActionBlock) block;
{
	return [[[self alloc] initWithDisplayName:name block:block] autorelease];
}
#endif

@synthesize continuesInteractionOnTable;

@end
