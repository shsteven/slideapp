//
//  MvrAccessibility.h
//  Mover3
//
//  Created by ∞ on 08/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrAppDelegate.h"

#define kMvrDefaultsKeyAreToastsEnabled @"MvrAreToastsEnabled"

#define kMvrAccessibilityDidChangeLayoutNotification @"MvrAccessibilityDidChangeLayoutNotification"
#define kMvrAccessibilityDidChangeScreenNotification @"MvrAccessibilityDidChangeScreenNotification"

extern void MvrAccessibilityDidChangeLayout();
extern void MvrAccessibilityDidChangeScreen();

extern void MvrAccessibilityShowToast(NSString* toast);

@interface MvrAppDelegate (MvrAccessibility)

- (void) didChangeLayout;
- (void) didChangeScreen;
- (void) showToast:(NSString*) toast;

@end
