//
//  MvrWiFiIncoming.h
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrIncoming.h"

@class MvrItem, L0KVODispatcher;

@interface MvrGenericIncoming : NSObject <MvrIncoming> {
@private
	float progress;
	
	MvrItem* item;
	NSString* type;
	BOOL cancelled;
}

@property float progress;

@property(retain) MvrItem* item;
@property(copy) NSString* type;
@property BOOL cancelled;

@end

@interface MvrGenericIncoming (MvrKVOUtilityMethods)

- (void) observeUsingDispatcher:(L0KVODispatcher*) d invokeAtItemChange:(SEL) itemSel atCancelledChange:(SEL) cancelSel atKeyChange:(SEL) keySel;
- (void) endObservingUsingDispatcher:(L0KVODispatcher*) d;

@end