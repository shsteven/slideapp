//
//  MvrDevicesLineView.h
//  MoverWaypoint
//
//  Created by ∞ on 03/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface L0LineOfViewsView : NSView {
	NSMutableArray* contentViewControllers;
	NSMutableArray* content;
	
	NSViewController* selectedController;
	
	NSView* emptyContentView;
}

@property(readonly) NSArray* contentViewControllers;
@property(copy) NSArray* content;
@property(readonly) NSMutableArray* mutableContent;

@property(readonly) NSSize contentSize;
@property IBOutlet NSView* emptyContentView;

- (NSViewController*) viewControllerForContentObject:(id) o; // abstract

- (void) setSelectedViewController:(NSViewController*) vc;
- (void) setSelectedObject:(id) o;

@end

@interface MvrDevicesLineView : L0LineOfViewsView {}
@end


@protocol L0LineOfViewsItem <NSObject>

@property(assign) L0LineOfViewsView* lineOfViewsView;
@property BOOL selected;

@end
