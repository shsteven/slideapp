//
//  MoverWaypointAppDelegate.h
//  MoverWaypoint
//
//  Created by ∞ on 23/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Network+Storage/MvrPlatformInfo.h"

#import "MvrDevicesLineView.h"
#import "MvrTransferController.h"

#import <MuiKit/MuiKit.h>

@interface MvrAppDelegate_Mac : NSObject <NSApplicationDelegate, NSWindowDelegate> {
    IBOutlet NSWindow * window;
	CGFloat originalWindowHeight;
	
	IBOutlet NSArrayController* channelsController;
	
	IBOutlet MvrDevicesLineView* devicesView;
	
	MvrTransferController* transfer;
}

- (IBAction) openMoverPlusAppStore:(id) sender;

@property(readonly) MvrTransferController* transfer;

@end

static inline MvrAppDelegate_Mac* MvrApp() {
	return (MvrAppDelegate_Mac*) [NSApp delegate];
}
