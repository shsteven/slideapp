//
//  L0MoverAppDelegate+L0UITestingHooks.m
//  Mover
//
//  Created by ∞ on 11/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverAppDelegate+L0UITestingHooks.h"

#import "L0MoverWiFiScanner.h"
#import "L0MoverBluetoothScanner.h"
#import "MvrNetworkExchange.h"

#if DEBUG
@implementation L0MoverAppDelegate (L0UITestingHooks)

- (void) testWelcomeAlert;
{
	[[UIAlertView alertNamed:@"L0MoverWelcome"] performSelector:@selector(show) withObject:nil afterDelay:1.0];
}

- (void) testTellAFriendAlert;
{
	[[UIAlertView alertNamed:@"L0MoverTellAFriend"] performSelector:@selector(show) withObject:nil afterDelay:1.0];	
}

- (void) testContactTutorialAlert;
{
	[[UIAlertView alertNamed:@"L0ContactReceived"] performSelector:@selector(show) withObject:nil afterDelay:1.0];
}

- (void) testImageTutorialAlert;
{
	[[UIAlertView alertNamed:@"L0ImageReceived_iPhone"] performSelector:@selector(show) withObject:nil afterDelay:1.0];
}

- (void) testImageTutorialAlert_iPod;
{
	[[UIAlertView alertNamed:@"L0ImageReceived_iPod"] performSelector:@selector(show) withObject:nil afterDelay:1.0];
}

- (void) testNewVersionAlert;
{
	[self performSelector:@selector(displayNewVersionAlertWithVersion:) withObject:@"99.9" afterDelay:1.0];
}

- (void) testNetworkBecomingUnavailable; // WARNING: Disables network watching, use with care.
{
	[self performSelector:@selector(performTestNetworkUnavailable) withObject:nil afterDelay:1.0];
}

- (void) testNoEmailSetUpAlert;
{
	[[UIAlertView alertNamed:@"L0MoverNoEmailSetUp"] performSelector:@selector(show) withObject:nil afterDelay:1.0];
}

- (void) performTestNetworkUnavailable;
{
	[self beginTestingModeBannerAnimation];
	[self stopWatchingNetwork];
	self.networkAvailable = NO;
}

- (void) testNetworkBecomingAvailable; // WARNING: Disables network watching, use with care.
{
	[self performSelector:@selector(performTestNetworkAvailable) withObject:nil afterDelay:1.0];
}

- (void) performTestNetworkAvailable;
{
	[self beginTestingModeBannerAnimation];
	[self stopWatchingNetwork];
	self.networkAvailable = YES;
}

- (void) testByPerformingAlertParade; // WARNING: Disables network watching, use with care.
{
	[self performSelector:@selector(beginTestingModeBannerAnimation) withObject:nil afterDelay:0.01];
	[self performSelector:@selector(testWelcomeAlert) withObject:nil afterDelay:0.02];
	[self performSelector:@selector(testContactTutorialAlert) withObject:nil afterDelay:5.0];
	[self performSelector:@selector(testImageTutorialAlert) withObject:nil afterDelay:10.0];
	[self performSelector:@selector(testImageTutorialAlert_iPod) withObject:nil afterDelay:15.0];
	[self performSelector:@selector(testNewVersionAlert) withObject:nil afterDelay:20.0];
	[self performSelector:@selector(testTellAFriendAlert) withObject:nil afterDelay:25.0];
	[self performSelector:@selector(testNoEmailSetUpAlert) withObject:nil afterDelay:30.0];
}

- (void) testNetworkStateChanges;
{
	[self performSelector:@selector(beginTestingModeBannerAnimation) withObject:nil afterDelay:0.01];
	
	L0MoverWiFiScanner* wifi = [L0MoverWiFiScanner sharedScanner];
	L0MoverBluetoothScanner* bt = [L0MoverBluetoothScanner sharedScanner];
	
	[self performSelector:@selector(setWiFiEnabled:) withObject:[NSNumber numberWithBool:NO] afterDelay:0.01];
	[self performSelector:@selector(setBluetoothEnabled:) withObject:[NSNumber numberWithBool:NO] afterDelay:5.0];
	[self performSelector:@selector(setWiFiEnabled:) withObject:[NSNumber numberWithBool:YES] afterDelay:10.0];
	[self performSelector:@selector(setBluetoothEnabled:) withObject:[NSNumber numberWithBool:YES] afterDelay:15.0];
	
	[self performSelector:@selector(setWiFiJammed:) withObject:[NSNumber numberWithBool:YES] afterDelay:20.0];
	[self performSelector:@selector(setBluetoothJammed:) withObject:[NSNumber numberWithBool:YES] afterDelay:25.0];
	[self performSelector:@selector(setWiFiJammed:) withObject:[NSNumber numberWithBool:NO] afterDelay:30.0];
	[self performSelector:@selector(setBluetoothJammed:) withObject:[NSNumber numberWithBool:NO] afterDelay:35.0];
	
	MvrNetworkExchange* peering = [MvrNetworkExchange sharedExchange];
	[peering performSelector:@selector(removeAvailableScannersObject:) withObject:bt afterDelay:40.0];
	[self performSelector:@selector(setWiFiJammed:) withObject:[NSNumber numberWithBool:YES] afterDelay:45.0];
	[self performSelector:@selector(setWiFiJammed:) withObject:[NSNumber numberWithBool:NO] afterDelay:50.0];
	[peering performSelector:@selector(addAvailableScannersObject:) withObject:bt afterDelay:55.0];
	
	[wifi performSelector:@selector(testByStoppingJamSimulation) withObject:nil afterDelay:60.0];
	[bt performSelector:@selector(testByStoppingJamSimulation) withObject:nil afterDelay:60.0];
}

- (void) setWiFiEnabled:(NSNumber*) n;
{
	L0MoverWiFiScanner* wifi = [L0MoverWiFiScanner sharedScanner];
	wifi.enabled = [n boolValue];
}

- (void) setWiFiJammed:(NSNumber*) n;
{
	L0MoverWiFiScanner* wifi = [L0MoverWiFiScanner sharedScanner];
	[wifi testBySimulatingJamming:[n boolValue]];
}

- (void) setBluetoothEnabled:(NSNumber*) n;
{
	L0MoverBluetoothScanner* bt = [L0MoverBluetoothScanner sharedScanner];
	bt.enabled = [n boolValue];
}

- (void) setBluetoothJammed:(NSNumber*) n;
{
	L0MoverBluetoothScanner* bt = [L0MoverBluetoothScanner sharedScanner];
	[bt testBySimulatingJamming:[n boolValue]];
}

- (void) beginTestingModeBannerAnimation;
{
	static BOOL isInTestingMode = NO;
	static NSTimer* bannerAnimationTimer = nil; // silences a clang analyzer warning
	
	if (!isInTestingMode) {
		bannerAnimationTimer = [[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(switchStatusBarColorForTestingModeAnimation:) userInfo:nil repeats:YES] retain];
		isInTestingMode = YES;
	}
}

- (void) switchStatusBarColorForTestingModeAnimation:(NSTimer*) t;
{
	static BOOL black = NO;
	UIStatusBarStyle style = black? UIStatusBarStyleDefault : UIStatusBarStyleBlackOpaque;
	black = !black;
	[UIApp setStatusBarStyle:style animated:YES];
}

@end
#endif