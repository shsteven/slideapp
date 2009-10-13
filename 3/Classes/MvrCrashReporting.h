//
//  MvrCrashReporting.h
//  Mover3
//
//  Created by ∞ on 13/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CrashReporter/CrashReporter.h>
#import <MessageUI/MessageUI.h>

@interface MvrCrashReporting : NSObject <MFMailComposeViewControllerDelegate, UIAlertViewDelegate> {
	NSData* reportData;
	PLCrashReport* report;
}

- (void) checkForPendingReports;
- (void) enableReporting;

@end
