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
	PLCrashReport* report;
}

- (id) initWithCrashReport:(PLCrashReport*) r data:(NSData*) d;
- (void) show;

@end

@implementation MvrCrashReportSender

- (id) initWithCrashReport:(PLCrashReport*) r data:(NSData*) d;
{
	if (self = [super init]) {
		report = [r retain];
		data = [d copy];
	}
		
	return self;
}

- (void) dealloc;
{
	[report release];
	[data release];
	[super dealloc];
}


- (void) show;
{
	if (![MFMailComposeViewController canSendMail]) {
		L0Log(@"The user can't send e-mail, so we drop this one.");
		return;
	}
	
	[self retain];
	[L0Mover suppressHelpAlerts];
	
	UIAlertView* alert = [UIAlertView alertNamed:@"MvrCrashPending"];
	alert.cancelButtonIndex = 0;
	alert.delegate = self;
	[alert show];
}

- (void) alertView:(UIAlertView*) alertView clickedButtonAtIndex:(NSInteger) buttonIndex;
{
	L0Log(@"%d", buttonIndex);
	
	if (buttonIndex != alertView.cancelButtonIndex) {
		L0Log(@"Displaying mail compose view.");
		MFMailComposeViewController* mail = [[MFMailComposeViewController alloc] init];
		mail.mailComposeDelegate = self;
		[mail setSubject:@"Mover Crash Report"]; // locale-invariant.
		[mail setToRecipients:[NSArray arrayWithObject:@"Mover Reports <me@infinite-labs.net>"]];
		
		NSMutableString* emailBody = [NSMutableString stringWithString:NSLocalizedString(@"(you can add additional details here before sending if you want.)", @"Crash report e-mail body.")];
		
		[emailBody appendString:@"\n\n\n"];
		
		if (report.hasExceptionInfo) {
			[emailBody appendFormat:@"Exception %@ -- %@\n", report.exceptionInfo.exceptionName, report.exceptionInfo.exceptionReason];
		}
		
		[emailBody appendFormat:@"Signal %@ -- %@ at 0x%llx\n",
		 report.signalInfo.name, report.signalInfo.code, (unsigned long long) report.signalInfo.address];
		
		[mail setMessageBody:emailBody isHTML:NO];
		[mail addAttachmentData:data mimeType:@"application/octet-stream" fileName:@"Crash Report.plcrash"];
		[L0Mover presentModalViewController:mail];
		[mail release];
	}
	
	alertView.delegate = nil;
}

- (void) mailComposeController:(MFMailComposeViewController*) controller didFinishWithResult:(MFMailComposeResult) result error:(NSError*) error;
{
	L0Log(@"Ending the reporting session.");
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

static NSUncaughtExceptionHandler* MvrRealUncaughtExceptionHandler = NULL;
static void L0LogUncaughtExceptionAndForward(NSException* e) {
	L0LogAlways(@"Looks like we got an exception. This is unfortunately NOT GOOD AT ALL. Full details follow for posterity, just in case something goes wrong with the reporting machinery. Owch.\n\nException details:\n  name = %@\n  reason = %@\n   user info = %@\n   stack = %@",
				[e name], [e reason], [e userInfo], [e callStackReturnAddresses]);
	
	if (MvrRealUncaughtExceptionHandler)
		MvrRealUncaughtExceptionHandler(e);
	else
		abort();
}

- (void) startCrashReporting;
{
	PLCrashReporter* cr = [PLCrashReporter sharedReporter];

	NSError* e;
	if (![cr enableCrashReporterAndReturnError:&e])
		L0LogAlways(@"This shouldn't have happened: crash reporting is turned off due to this error: %@. This means that if Mover crashes, we will never know. Ouch.", e);
	else
		L0Log(@"Crash reporting reporting for duty!");
	
	MvrRealUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
	NSSetUncaughtExceptionHandler(&L0LogUncaughtExceptionAndForward);
}

- (void) processPendingCrashReportIfRequired;
{
	L0Note();
	PLCrashReporter* cr = [PLCrashReporter sharedReporter];
	
	if (![cr hasPendingCrashReport]) {
		L0Log(@"No pending crash reports detected.");
		return;
	}
	
	L0Log(@"Loading the pending crash reports and starting a sending session...");
	
	NSError* e = nil;
	NSData* crashReportData = [cr loadPendingCrashReportDataAndReturnError:&e];
	if (!crashReportData) {
		L0LogAlways(@"Ouch! Looks like there was a partial crash report, but it couldn't be read because of this error: %@. Hope it wasn't anything important.", e);
		return;
	}
	
	PLCrashReport* crashReport = [[[PLCrashReport alloc] initWithData:crashReportData error:&e] autorelease];
	if (!crashReport) {
		L0LogAlways(@"Ouch! Looks like there was crash report data, but it couldn't be parsed into a full report because of this error: %@. Hope it wasn't anything important.", e);
		return;
	} else {
		
#if DEBUG
		// In case we debug, it might be interesting to grab the file anyway (esp on the simulator, where we cannot send e-mail for real.
		NSString* crashReportLocation = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Crash Report.plcrash"];
		[crashReportData writeToFile:crashReportLocation atomically:YES];
		L0Log(@"Written crash report data at: %@", crashReportLocation);
#endif
		
		L0Log(@"Displaying reporting UI.");
		MvrCrashReportSender* sender = [[[MvrCrashReportSender alloc] initWithCrashReport:crashReport data:crashReportData] autorelease];
		[sender show];
	}

	[cr purgePendingCrashReport];
}

@end
