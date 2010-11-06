//
//  MvrAgent.h
//  Mover Connect
//
//  Created by ∞ on 03/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MvrDirectoryWatcher.h"

#define kMvrAgentShouldQuitNotification @"net.infinite-labs.Mover.Mac.Agent.ShouldQuit"
#define kMvrAgentDistributedNotificationObject @"net.infinite-labs.Mover.Mac.Agent"

#define kMvrModernWiFiBonjourConduitServiceType @"_x-mover-conduit._tcp."

@interface MvrAgent : NSObject <NSApplicationDelegate, NSNetServiceBrowserDelegate> {
	NSStatusItem* statusItem;
	IBOutlet NSMenu* statusItemMenu;
	
	NSNetServiceBrowser* browser, * macBrowser;
	
	MvrDirectoryWatcher* watcher, * connectWatcher;
	NSString* bundlePath;
}

- (IBAction) openMoverConnect:(id) sender;

@end
