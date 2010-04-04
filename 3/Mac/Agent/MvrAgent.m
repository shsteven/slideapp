//
//  MvrAgent.m
//  Mover Connect
//
//  Created by ∞ on 03/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrAgent.h"

#define kMvrModernWiFiBonjourServiceType @"_x-mover3._tcp."

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
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldQuit:) name:kMvrAgentShouldQuitNotification object:kMvrAgentDistributedNotificationObject];
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
