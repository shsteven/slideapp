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

#define kMvrAdActingImageDirectory @"AdImages"

#define kMvrAdActingInitialItemsForSenderDirectory (kMvrAdActingImageDirectory @"/Sender")
#define kMvrAdActingInitialItemsForReceiverDirectory (kMvrAdActingImageDirectory @"/Receiver")
#define kMvrAdActingReceivedImageName @"Received" // in kMvrAdActingImageDirectory, of type @"jpg"

@interface MvrAdActingController : NSObject {
	NSMutableArray* senderImages;
	NSMutableArray* receiverImages;
	UIImage* receivedImage;
}

+ (MvrAdActingController*) sharedAdController;

- (void) start;

@property(readonly) NSArray* initialItemsForSender;
@property(readonly) NSArray* initialItemsForReceiver;

@property(readonly) MvrItem* itemForReceiving;

@property(readonly, getter=isReceiver) NSNumber* receiver;

@end

#endif