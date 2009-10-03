//
//  MvrVisor.h
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Network+Storage/MvrItem.h"

@interface MvrVisor : UIViewController {
	MvrItem* item;
	
	BOOL changesStatusBarStyleOnAppearance;
	BOOL didChangeStatusBarStyle;
	UIBarStyle previousStatusBarStyle;
}

- (id) initWithItem:(MvrItem*) i;

+ modalVisorWithItem:(MvrItem*) i;
+ visorWithItem:(MvrItem*) i;

@property(retain) id item;

@property BOOL changesStatusBarStyleOnAppearance;
@property(readonly) UIStatusBarStyle preferredStatusBarStyle;

@property(readonly) UIBarButtonItem* doneButton, * actionButton;

@end
