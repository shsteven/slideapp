//
//  MoverWaypointAppDelegate.h
//  MoverWaypoint
//
//  Created by ∞ on 23/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Network+Storage/MvrPlatformInfo.h"
#import "Network+Storage/MvrModernWiFi.h"
#import "Network+Storage/MvrScannerObserver.h"

#import <MuiKit/MuiKit.h>

@interface MoverWaypointAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, MvrPlatformInfo, MvrScannerObserverDelegate> {
    IBOutlet NSWindow * window;
	CGFloat originalWindowHeight;
	L0UUID* identifier;

	MvrModernWiFi* wifi;
	MvrScannerObserver* wifiObserver;
	
	IBOutlet NSArrayController* channelsController;
	
	L0Map* channelsByIncoming;
	
	IBOutlet NSCollectionView* devicesView;
}

@end
