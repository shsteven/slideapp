//
//  MoverWaypointAppDelegate.h
//  MoverWaypoint
//
//  Created by ∞ on 23/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MoverWaypointAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {
    IBOutlet NSWindow * window;
	CGFloat originalWindowHeight;
}

@end
