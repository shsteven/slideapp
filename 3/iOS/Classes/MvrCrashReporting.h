//
//  MvrCrashReporting.h
//  Mover3
//
//  Created by ∞ on 13/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLCrashReport;

#if !kMvrDisableCrashReporting
#import <CrashReporter/CrashReporter.h>
#endif

#import <MessageUI/MessageUI.h>

@interface MvrCrashReporting : NSObject <MFMailComposeViewControllerDelegate, UIAlertViewDelegate> {
	NSData* reportData;
	PLCrashReport* report;
}

- (void) checkForPendingReports;
- (void) enableReporting;

@end
