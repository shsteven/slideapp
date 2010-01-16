//
//  MvrWiFiIncoming.m
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrGenericIncoming.h"

#import <MuiKit/MuiKit.h>
#import "MvrItem.h"

@implementation MvrGenericIncoming

@synthesize progress, item, type, cancelled;

- (void) dealloc;
{
	self.type = nil;
	self.item = nil;
	[super dealloc];
}

@end

@implementation MvrGenericIncoming (MvrKVOUtilityMethods)

- (void) observeUsingDispatcher:(L0KVODispatcher*) d invokeAtItemChange:(SEL) itemSel atCancelledChange:(SEL) cancelSel atKeyChange:(SEL) keySel;
{
	[d observe:@"item" ofObject:self usingSelector:itemSel options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
	[d observe:@"cancelled" ofObject:self usingSelector:cancelSel options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
	
	if (keySel)
		[d observe:@"type" ofObject:self usingSelector:keySel options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
}

- (void) endObservingUsingDispatcher:(L0KVODispatcher*) d;
{
	[d endObserving:@"cancelled" ofObject:self];
	[d endObserving:@"item" ofObject:self];
	
	[d endObserving:@"type" ofObject:self];
}

@end
