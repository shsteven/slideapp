//
//  L0MoverNetworkCalloutController.h
//  Mover
//
//  Created by ∞ on 05/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface L0MoverNetworkCalloutController : NSObject {
	UIView* networkCalloutView;
	UILabel* networkLabel;
	UILabel* availableNetworksLabel;
	
	UIView* anchorView;
	
	BOOL allJammed;
	BOOL waitingForHide;
}

@property(retain) IBOutlet UILabel* networkLabel;
@property(retain) IBOutlet UILabel* availableNetworksLabel;

@property(retain) IBOutlet UIView* networkCalloutView;

@property(assign) UIView* anchorView;

- (IBAction) highlightCallout;
- (IBAction) unhighlightCallout;

- (IBAction) pressedCallout;

- (void) startWatchingForJams;

- (void) showCallout;
- (void) hideCalloutUnlessJammed;
- (void) toggleCallout;

- (void) showNetworkSettingsPane;

@end

