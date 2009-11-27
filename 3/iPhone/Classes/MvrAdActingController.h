//
//  MvrAdController.h
//  Mover3
//
//  Created by ∞ on 27/11/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#if kMvrInstrumentForAds

#import <Foundation/Foundation.h>
#import "Network+Storage/MvrItem.h"

#define kMvrAdActingInitialItemsForSenderDirectory @"Ad-SenderPics"
#define kMvrAdActingInitialItemsForReceiverDirectory @"Ad-ReceiverPics"
#define kMvrAdActingReceivedImageName @"Ad-Received" // .jpg

@interface MvrAdActingController : NSObject {

}

+ (MvrAdActingController*) sharedAdController;

- (void) start;

@property(readonly) NSArray* initialItemsForSender;
@property(readonly) NSArray* initialItemsForReceiver;

@property(readonly) MvrItem* itemForReceiving;

@property(readonly, getter=isReceiver) NSNumber* receiver;

@end

#endif