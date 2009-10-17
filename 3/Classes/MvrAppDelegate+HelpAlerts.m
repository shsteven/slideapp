//
//  MvrAppDelegate+HelpAlerts.m
//  Mover3
//
//  Created by ∞ on 17/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrAppDelegate+HelpAlerts.h"


@implementation MvrAppDelegate (MvrHelpAlerts)

static int MvrHelpAlertsSuppressionCount = 0;

- (void) suppressHelpAlerts;
{
	MvrHelpAlertsSuppressionCount++;
}

- (void) resumeHelpAlerts;
{
	MvrHelpAlertsSuppressionCount--;
	if (MvrHelpAlertsSuppressionCount < 0)
		MvrHelpAlertsSuppressionCount = 0;
}

- (BOOL) helpAlertsSuppressed;
{
	return MvrHelpAlertsSuppressionCount > 0;
}

- (void) showAlertIfNotShownBeforeNamed:(NSString*) name;
{
	// the first method returns nil if the alert was already
	// shown.
	[[self alertIfNotShownBeforeNamed:name] show];
}

- (UIAlertView*) alertIfNotShownBeforeNamed:(NSString*) name;
{
	if (MvrHelpAlertsSuppressionCount > 0) return nil;
	
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	NSString* key = [NSString stringWithFormat:@"L0HelpAlertShown_%@", name];
	
	if (![ud boolForKey:key]) {
		UIAlertView* alert = [UIAlertView alertNamed:name];
		[ud setBool:YES forKey:key];
		return alert;
	} else
		return nil;
}

// Device-dependent alerts.

- (UIAlertView*) alertIfNotShownBeforeNamedForiPhone:(NSString*) iPhoneName foriPodTouch:(NSString*) iPodTouchName;
{
	if ([UIDevice currentDevice].deviceFamily == kL0DeviceFamily_iPodTouch)
		return [self alertIfNotShownBeforeNamed:iPodTouchName];
	else
		return [self alertIfNotShownBeforeNamed:iPhoneName];
}

- (void) showAlertIfNotShownBeforeNamedForiPhone:(NSString*) iPhoneName foriPodTouch:(NSString*) iPodTouchName;
{
	[[self alertIfNotShownBeforeNamedForiPhone:iPhoneName foriPodTouch:iPodTouchName] show];
}

@end