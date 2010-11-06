//
//  MvrPrintAction.h
//  Mover3
//
//  Created by ∞ on 30/09/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MvrItemAction.h"
#import "MvrItemController.h"

@interface MvrPrintAction : MvrItemAction <UIPrintInteractionControllerDelegate> {
	__weak MvrItemController* itemController;
}

- (id) initWithItemController:(MvrItemController*) ic;

@end
