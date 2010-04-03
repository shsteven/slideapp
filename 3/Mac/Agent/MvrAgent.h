//
//  MvrAgent.h
//  Mover Connect
//
//  Created by ∞ on 03/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kMvrAgentShouldQuitNotification @"net.infinite-labs.Mover.Mac.Agent.ShouldQuit"
#define kMvrAgentDistributedNotificationObject @"net.infinite-labs.Mover.Mac.Agent"

@interface MvrAgent : NSObject <NSApplicationDelegate, NSNetServiceBrowserDelegate> {
	NSStatusItem* statusItem;
	IBOutlet NSMenu* statusItemMenu;
	
	NSNetServiceBrowser* browser;
}

- (IBAction) openMoverConnect:(id) sender;

@end
