//
//  L0MoverAppDelegate+MvrCrashReporting.h
//  Mover
//
//  Created by ∞ on 15/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "L0MoverAppDelegate.h"

@interface L0MoverAppDelegate (MvrCrashReporting)

- (void) startCrashReporting;
- (void) processPendingCrashReportIfRequired;

#if DEBUG && kMvrCrashReportingInsertCrashTests
- (void) testByInducingCrash;
- (void) testByRaisingException;
#endif

@end
