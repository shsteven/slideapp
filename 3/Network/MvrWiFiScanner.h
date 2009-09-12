//
//  MvrWiFiScanner.h
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MuiKit/MuiKit.h>


@interface MvrWiFiScanner : NSObject {
	// NSNetService and NSNetServiceBrowser instances.
	NSMutableSet* netServices;
	NSMutableSet* soughtServices;
	
	BOOL enabled;
	L0Map* browsers;
	NSMutableSet* servicesBeingResolved;
	
}

@property(assign) BOOL enabled;

// Called when .enabled changes.
- (void) start;
- (void) stop;

// Subclasses use these to set up stuff. Must be done while the scanner is disabled.
- (void) addServiceWithName:(NSString*) name type:(NSString*) type port:(int) port;
- (void) addBrowserForServicesWithType:(NSString*) type;

// Called when services are found.
- (void) foundService:(NSNetService*) s;
- (void) lostService:(NSNetService*) s;

@end
