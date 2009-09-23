//
//  MvrWiFiMode.m
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFiMode.h"

#import "Network+Storage/MvrModernWiFi.h"
#import "Network+Storage/MvrLegacyWiFi.h"

#import "MvrAppDelegate.h"

@implementation MvrWiFiMode

- (void) awakeFromNib;
{
	wifi = [[MvrWiFi alloc] initWithPlatformInfo:MvrApp() modernPort:kMvrModernWiFiPort legacyPort:kMvrLegacyWiFiPort];
	observer = [[MvrScannerObserver alloc] initWithScanner:wifi delegate:self];
	wifi.enabled = YES;
}

- (void) scanner:(id <MvrScanner>) s didAddChannel:(id <MvrChannel>) channel;
{
	[self.mutableDestinations addObject:channel];
}

- (void) scanner:(id <MvrScanner>) s didRemoveChannel:(id <MvrChannel>) channel;			
{
	[self.mutableDestinations removeObject:channel];
}

- (NSString*) displayNameForDestination:(id) dest;
{
	return [dest displayName];
}

@end
