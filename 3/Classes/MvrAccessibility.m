//
//  MvrAccessibility.m
//  Mover3
//
//  Created by ∞ on 08/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrAccessibility.h"

@interface UIAlertView (MvrAccessibilityToasts)
- (void) mvrDismissToast;
@end

@implementation UIAlertView (MvrAccessibilityToasts)

- (void) mvrDismissToast;
{
	[self dismissWithClickedButtonIndex:0 animated:YES];
}

@end

@implementation MvrAppDelegate (MvrAccessibility)

- (void) didChangeLayout;
{
	MvrAccessibilityDidChangeLayout();
}

- (void) didChangeScreen;
{
	MvrAccessibilityDidChangeScreen();
}

- (void) showToast:(NSString*) toast;
{
	MvrAccessibilityShowToast(toast);
}

@end


void MvrAccessibilityDidChangeLayout() {
	[[NSNotificationCenter defaultCenter] postNotificationName:kMvrAccessibilityDidChangeLayoutNotification object:nil];
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

void MvrAccessibilityDidChangeScreen() {
	[[NSNotificationCenter defaultCenter] postNotificationName:kMvrAccessibilityDidChangeScreenNotification object:nil];
	UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

void MvrAccessibilityShowToast(NSString* toast) {
//	static BOOL isEnabled, didCheckEnabled = NO;
//	
//	if (!didCheckEnabled) {
//		isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kMvrDefaultsKeyAreToastsEnabled];
//		didCheckEnabled = YES;
//	}
//	
//	if (!isEnabled)
//		return;
//	
//	UIAlertView* a = [[UIAlertView new] autorelease];
//	a.title = toast;
//	[a show];
//	[a performSelector:@selector(mvrDismissToast) withObject:nil afterDelay:4.0];
}
