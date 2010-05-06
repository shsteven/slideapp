//
//  MvrItemViewController.h
//  Mover3-iPad
//
//  Created by ∞ on 23/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ILPartController.h"
#import "Network+Storage/MvrItem.h"
#import "MvrDraggableView.h"

@class MvrItemAction;

@protocol MvrItemsTable;

@interface MvrItemController : ILPartController <MvrDraggableViewDelegate, UIDocumentInteractionControllerDelegate> {
	id item;
	UIButton* actionButton;
	
	BOOL actionMenuShown;
	id <MvrItemsTable> itemsTable;
	
	UIDocumentInteractionController* doc;
	
	NSArray* actions;
}

+ (void) setItemControllerClass:(Class) vcc forItemClass:(Class) ic;
+ (Class) itemControllerClassForItem:(MvrItem*) i;

+ (NSSet*) supportedItemClasses;
+ (void) registerClass;

+ (MvrItemController*) itemControllerWithItem:(MvrItem*) i;

// may be nil. It's always a MvrItem, but id allows calling subclass methods.
@property(retain) id item;
- (void) itemDidChange;

// The draggable view that represents this item. This MUST return the same value as .view, and is here just for convenience.
@property(readonly) MvrDraggableView* draggableView;

// The action button.
@property(readonly) UIButton* actionButton;
- (void) setActionButtonHidden:(BOOL) hidden animated:(BOOL) animated;

@property(assign) id <MvrItemsTable> itemsTable;

- (void) showOpeningOptionsMenu;

- (void) showActionMenu;
- (void) didFinishAction;
@property(copy) NSArray* actions;
@property(readonly) NSArray* defaultActions;

- (MvrItemAction*) showOpeningOptionsMenuAction;

@end



@protocol MvrItemsTable <NSObject>

- (void) itemControllerViewDidFinishMoving:(MvrItemController*) ic velocity:(CGPoint) v;

@end