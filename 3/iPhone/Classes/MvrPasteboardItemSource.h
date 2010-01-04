//
//  MvrPasteboardItemSource.h
//  Mover3
//
//  Created by ∞ on 07/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SwapKit/SwapKit.h>

#import "MvrItemUI.h"

@interface MvrPasteboardItemSource : MvrItemSource {

}

+ sharedSource;

// Adds all applicable items from the given pasteboard to the table.
- (void) addAllItemsFromPasteboard:(UIPasteboard*) pb;

- (void) addAllItemsFromSwapKitRequest:(ILSwapRequest*) req;

@end
