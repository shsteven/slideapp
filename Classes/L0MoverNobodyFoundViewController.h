//
//  L0MoverTroubleshootingController.h
//  Mover
//
//  Created by ∞ on 24/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class L0MoverItemsTableController;

@interface L0MoverNobodyFoundViewController : NSObject {
	L0MoverItemsTableController* tableController;
	
	UIView* nobodyFoundView;
	UIActivityIndicatorView* nobodyFoundViewSpinner;
	CGRect nobodyFoundViewFrame;
	
	UIView* nobodyFoundViewHost;
}

@property(assign) IBOutlet L0MoverItemsTableController* tableController;

@property(retain) IBOutlet UIView* nobodyFoundView;
@property(assign) IBOutlet UIActivityIndicatorView* nobodyFoundViewSpinner;

@property(assign) IBOutlet UIView* nobodyFoundViewHost;

- (IBAction) showNetworkHelp;
- (IBAction) showNetworkState;

- (void) updateDisplayOfNobodyFoundView;

@end
