//
//  L0MoverAppDelegate+MvrTransferManagement.h
//  Mover
//
//  Created by ∞ on 06/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "L0MoverAppDelegate.h"

@interface L0MoverAppDelegate (MvrTransferManagement) <L0MoverPeerDelegate>

- (void) stopTrackingIncomingTransfer:(id <MvrIncoming>) t;

@end
