//
//  L0MoverAppDelegate+MvrCrashReporting.m
//  Mover
//
//  Created by ∞ on 15/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverAppDelegate+MvrCrashReporting.h"

#import <CrashReporter/CrashReporter.h>
#import <MessageUI/MessageUI.h>
#import "L0MoverAppDelegate+L0HelpAlerts.h"

@interface MvrCrashReportSender : NSObject <UIAlertViewDelegate, MFMailComposeViewControllerDelegate>
{
	NSData* data;
}

- (id) initWithCrashReportData:(NSData*) d;
- (void) show;

@end

@implementation MvrCrashReportSender

- (id) initWithCrashReportData:(NSData*) d;
{
	if (self = [super init])
		data = [d copy];
		
	return self;
}

- (void) dealloc;
{
	[data release];
	[super dealloc];
}


- (void) show;
{
	if (![MFMailComposeViewController canSendMail])
		return;
	
	[self retain];
	[L0Mover suppressHelpAlerts];
	
	UIAlertView* alert = [UIAlertView alertNamed:@"MvrCrashPending"];
	alert.cancelButtonIndex = 0;
	alert.delegate = self;
	[alert show];
}

- (void) alertView:(UIAlertView*) alertView clickedButtonAtIndex:(NSInteger) buttonIndex;
{
	if (buttonIndex != alertView.cancelButtonIndex) {
		MFMailComposeViewController* mail = [[MFMailComposeViewController alloc] init];
		mail.mailComposeDelegate = self;
		[mail setSubject:@"Mover Crash Report"]; // locale-invariant.
		[mail setToRecipients:[NSArray arrayWithObject:@"Mover Reports <me@infinite-labs.net>"]];
		[mail setMessageBody:NSLocalizedString(@"(you can add additional details here before sending if you want.)", @"Crash report e-mail body.") isHTML:NO];
		[mail addAttachmentData:data mimeType:@"application/octet-stream" fileName:@"Crash Report.plcrash"];
		[L0Mover presentModalViewController:mail];
		[mail release];
	}
	
	alertView.delegate = nil;
}

- (void) mailComposeController:(MFMailComposeViewController*) controller didFinishWithResult:(MFMailComposeResult) result error:(NSError*) error;
{
	[controller dismissModalViewControllerAnimated:YES];
	controller.mailComposeDelegate = nil;
	[L0Mover resumeHelpAlerts];
	[self autorelease];
}

@end



@implementation L0MoverAppDelegate (MvrCrashReporting)

#if DEBUG
- (void) testByInducingCrash;
{
	char* nowhere = NULL;
	*nowhere = 'X';
}

- (void) testByRaisingException;
{
	srandomdev();
	[NSException raise:@"MvrTestException" format:@"This exception was raised to test the crash reporting machinery. A random value follows: %ld", random()];
}
#endif

- (void) startCrashReporting;
{
	PLCrashReporter* cr = [PLCrashReporter sharedReporter];

	NSError* e;
	if (![cr enableCrashReporterAndReturnError:&e])
		L0LogAlways(@"This shouldn't have happened: crash reporting is turned off due to this error: %@. This means that if Mover crashes, we will never know. Ouch.", e);
	else
		L0Log(@"Crash reporting reporting for duty!");
	
	//[self performSelector:@selector(testByInducingCrash) withObject:nil afterDelay:3.0];
}

- (void) processPendingCrashReportIfRequired;
{
	PLCrashReporter* cr = [PLCrashReporter sharedReporter];
	
	if (![cr hasPendingCrashReport])
		return;
	
	NSError* e;
	NSData* crashReportData = [cr loadPendingCrashReportDataAndReturnError:&e];
	if (!crashReportData) {
		L0LogAlways(@"Ouch! Looks like there was a partial crash report, but it couldn't be read because of this error: %@. Hope it wasn't anything important.", e);
	} else {
#if DEBUG
		// In case we debug, it might be interesting to grab the file anyway (esp on the simulator, where we cannot send e-mail for real.
		NSString* crashReportLocation = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Crash Report.plcrash"];
		[crashReportData writeToFile:crashReportLocation atomically:YES];
		L0Log(@"Written crash report data at: %@", crashReportLocation);
#endif
		
		MvrCrashReportSender* sender = [[[MvrCrashReportSender alloc] initWithCrashReportData:crashReportData] autorelease];
		[sender show];
	}
	
	[cr purgePendingCrashReport];
}

@end
