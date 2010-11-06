//
//  MvrAgent.m
//  Mover Connect
//
//  Created by ∞ on 03/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrAgent.h"
#import <Carbon/Carbon.h>

#define kMvrModernWiFiBonjourServiceType @"_x-mover3._tcp."

@interface MvrAgent ()

- (void) removeSelfFromLoginItems;

@end


@implementation MvrAgent

- (void) applicationDidFinishLaunching:(NSNotification *)notification;
{	
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:21];
	[statusItem setImage:[NSImage imageNamed:@"SlideMenuIcon"]];
	[statusItem setAlternateImage:[NSImage imageNamed:@"SlideMenuIcon_Selected"]];
	[statusItem setHighlightMode:YES];
	
	[statusItem setMenu:statusItemMenu];
	
	browser = [NSNetServiceBrowser new];
	browser.delegate = self;
	[browser searchForServicesOfType:kMvrModernWiFiBonjourServiceType inDomain:@""];
	
	macBrowser = [NSNetServiceBrowser new];
	macBrowser.delegate = self;
	[macBrowser searchForServicesOfType:kMvrModernWiFiBonjourConduitServiceType inDomain:@""];
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldQuit:) name:kMvrAgentShouldQuitNotification object:kMvrAgentDistributedNotificationObject];
	
	bundlePath = [[NSBundle mainBundle] bundlePath];
	watcher = [[MvrDirectoryWatcher alloc] initForDirectoryAtPath:bundlePath target:self selector:@selector(didChangeSomethingInsideMainBundle)];
	[watcher start];
	
	NSString* connect = [[bundlePath stringByDeletingLastPathComponent] /* .app/Contents */ stringByDeletingLastPathComponent]; /* .app */;
	connectWatcher = [[MvrDirectoryWatcher alloc] initForDirectoryAtPath:connect target:self selector:@selector(didChangeSomethingInsideMainBundle)];
	[connectWatcher start];
	
}

- (void) removeSelfFromLoginItems;
{
	NSURL* agentURL = [NSURL fileURLWithPath:bundlePath];
	
	LSSharedFileListRef loginItems = (LSSharedFileListRef) CFMakeCollectable(LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL));
	
	CFArrayRef cfa = LSSharedFileListCopySnapshot(loginItems, NULL);
	
	if (cfa) {
		for (CFIndex i = 0; i < CFArrayGetCount(cfa); i++) {
			LSSharedFileListItemRef item = (LSSharedFileListItemRef) CFArrayGetValueAtIndex(cfa, i);
			
			NSURL* u;
			if (LSSharedFileListItemResolve(item, 0, (CFURLRef*) &u, NULL) != noErr)
				continue;
			
			if (u)
				NSMakeCollectable(u);
			
			if ([u isEqual:agentURL])
				LSSharedFileListItemRemove(loginItems, item);
		}
		CFRelease(cfa);
	}	
}

- (void) didChangeSomethingInsideMainBundle;
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
		[self removeSelfFromLoginItems];
		[NSApp terminate:self];
	}
}

- (void) shouldQuit:(NSNotification*) shouldQuit;
{
	[NSApp terminate:self];
}

- (void) applicationWillTerminate:(NSNotification *)notification;
{
	[[statusItem statusBar] removeStatusItem:statusItem];
	[browser stop];
}

// we assume we're in Mover Connect.app/Contents
- (IBAction) openMoverConnect:(id) sender;
{
	NSString* me = [[NSBundle mainBundle] bundlePath]; /* .app/Contents/Mover Agent.app */
	NSString* connect = [[me stringByDeletingLastPathComponent] /* .app/Contents */ stringByDeletingLastPathComponent]; /* .app */;
	
	[[NSWorkspace sharedWorkspace] openFile:connect];
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
{
	if (!moreComing)
		[self openMoverConnect:self];
}

@end
