//
//  MvrCrashReporting.m
//  Mover3
//
//  Created by ∞ on 13/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrCrashReporting.h"
#import "MvrAppDelegate.h"

@interface MvrCrashReporting ()
- (void) clear;
@end


@implementation MvrCrashReporting

- (void) dealloc;
{
	[self clear];
	[super dealloc];
}

#if kMvrDisableCrashReporting
// #warning Crash reporting is disabled for this build.
#endif


- (void) checkForPendingReports;
{
#if !kMvrDisableCrashReporting
	
#if DEBUG
	if ([[[[NSProcessInfo processInfo] environment] objectForKey:@"MvrDisableCrashReporting"] boolValue])
		return;
#endif
	
	if (reportData || report)
		return;
	
	if (![MFMailComposeViewController canSendMail])
		return;
	
	PLCrashReporter* rep = [PLCrashReporter sharedReporter];
	if (![rep hasPendingCrashReport])
		return;
	
	NSData* data = [rep loadPendingCrashReportData];
	PLCrashReport* parsed = data? [[[PLCrashReport alloc] initWithData:data error:NULL] autorelease] : nil;
	
	if (data && parsed) {
		reportData = [data retain];
		report = [parsed retain];
		
		UIAlertView* alert = [UIAlertView alertNamed:@"MvrAskAboutCrash"];
		alert.cancelButtonIndex = 0;
		alert.delegate = self;
		[alert show];
	}
	
	[rep purgePendingCrashReport];
#endif
}

NSUncaughtExceptionHandler* defaultExceptionHandler = NULL;
static void MvrHandleException(NSException* ex) {
	L0LogAlways(@" !!! We got an exception, which means we're going to suffer the horrible death we deserve. Ick! Since the reporting machinery may at times get stuck and we're insufferable paranoids, here are details of the exception just in case.\n\n%@, reason: %@, stack: %@", [ex name], [ex reason], [ex callStackReturnAddresses]);
	if (defaultExceptionHandler)
		defaultExceptionHandler(ex);
	else
		abort();
}

- (void) enableReporting;
{
#if !kMvrDisableCrashReporting
	
#if DEBUG
	if ([[[[NSProcessInfo processInfo] environment] objectForKey:@"MvrDisableCrashReporting"] boolValue])
		return;
#endif
	
	NSError* error;
	if (![[PLCrashReporter sharedReporter] enableCrashReporterAndReturnError:&error]) {
		L0LogAlways(@" !!! WARNING !!! Crash reporting was not enabled for this session due to this error: %@. This means that, if we crash, we'll never know. Oh well.", error);
	}
	
	defaultExceptionHandler = NSGetUncaughtExceptionHandler();
	NSSetUncaughtExceptionHandler(&MvrHandleException);

//	NSException* e = [NSException exceptionWithName:@"MvrTestException" reason:@"A test exception used to try out the reporting machinery" userInfo:nil];
//	[e performSelector:@selector(raise) withObject:nil afterDelay:7.0];
	
#endif
}

- (void) alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex;
{
#if !kMvrDisableCrashReporting
	
	if (buttonIndex == alert.cancelButtonIndex)
		return;
	
	MFMailComposeViewController* mail = [[MFMailComposeViewController new] autorelease];
	mail.mailComposeDelegate = self;
	mail.navigationBar.barStyle = UIBarStyleBlack;
	
	[mail setSubject:@"Mover Crash Report"]; // NOT localized
	[mail setToRecipients:[NSArray arrayWithObject:@"Mover Reports <me@infinite-labs.net>"]];
	
	NSMutableString* emailBody = [NSMutableString stringWithString:NSLocalizedString(@"(you can add additional details here before sending if you want.)", @"Crash report e-mail body.")];
	
	[emailBody appendString:@"\n\n\n"];
	
	if (report.hasExceptionInfo) {
		[emailBody appendFormat:@"Exception %@ -- %@\n", report.exceptionInfo.exceptionName, report.exceptionInfo.exceptionReason];
	}
	
	[emailBody appendFormat:@"Signal %@ -- %@ at 0x%llx\n",
	 report.signalInfo.name, report.signalInfo.code, (unsigned long long) report.signalInfo.address];
	
	[mail setMessageBody:emailBody isHTML:NO];
	[mail addAttachmentData:reportData mimeType:@"application/octet-stream" fileName:@"Crash Report.plcrash"];
	[MvrApp() presentModalViewController:mail];	
#endif
}

- (void)mailComposeController:(MFMailComposeViewController *)mail didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
{
	[self clear];
	[mail dismissModalViewControllerAnimated:YES];
}

- (void) clear;
{
	[reportData release]; reportData = nil;
	[report release]; report = nil;
}

@end
