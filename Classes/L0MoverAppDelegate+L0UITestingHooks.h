//
//  L0MoverAppDelegate+L0UITestingHooks.h
//  Mover
//
//  Created by ∞ on 11/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define L0MoverAppDelegateAllowFriendMethods 1
#import "L0MoverAppDelegate.h"


#if DEBUG
@interface L0MoverAppDelegate (L0UITestingHooks)


- (void) testWelcomeAlert;
- (void) testContactTutorialAlert;
- (void) testTellAFriendAlert;
- (void) testImageTutorialAlert;
- (void) testImageTutorialAlert_iPod;
- (void) testNewVersionAlert;
- (void) testNoEmailSetUpAlert;

// Performs all of the above 5s one from the other.
- (void) testByPerformingAlertParade; // WARNING: Disables network watching, use with care.

// toggles enabling and simulated jamming on wifi and bluetooth, then finally makes bt unavailable. USE ONCE PER SESSION (restart before reusing).
- (void) testNetworkStateChanges;

// If the app is in "testing mode" (ie we've clobbered it beyond recognition by using the test... methods above
// and it needs a restart to return behaving like it does in normal operation)
// then we make the status bar flash between black opaque and normal to indicate it.
- (void) beginTestingModeBannerAnimation;

@end
#endif
