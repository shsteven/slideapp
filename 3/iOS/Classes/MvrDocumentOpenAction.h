//
//  MvrDocumentOpenAction.h
//  Mover3
//
//  Created by ∞ on 27/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrItemAction.h"

// UIDocumentInteractionController-powered 'Open' action for iPhone on iOS 4.0+

@interface MvrDocumentOpenAction : MvrItemAction <UIDocumentInteractionControllerDelegate> {
	UIDocumentInteractionController* documentInteractionController;
}

+ openAction;

@end
