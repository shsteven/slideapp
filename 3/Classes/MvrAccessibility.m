//
//  MvrAccessibility.m
//  Mover3
//
//  Created by ∞ on 08/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrAccessibility.h"


void MvrAccessibilityDidChangeLayout() {
	[[NSNotificationCenter defaultCenter] postNotificationName:kMvrAccessibilityDidChangeLayoutNotification object:nil];
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

void MvrAccessibilityDidChangeScreen() {
	[[NSNotificationCenter defaultCenter] postNotificationName:kMvrAccessibilityDidChangeScreenNotification object:nil];
	UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}
