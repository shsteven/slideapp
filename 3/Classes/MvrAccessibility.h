//
//  MvrAccessibility.h
//  Mover3
//
//  Created by ∞ on 08/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kMvrAccessibilityDidChangeLayoutNotification @"MvrAccessibilityDidChangeLayoutNotification"
#define kMvrAccessibilityDidChangeScreenNotification @"MvrAccessibilityDidChangeScreenNotification"

extern void MvrAccessibilityDidChangeLayout();
extern void MvrAccessibilityDidChangeScreen();
