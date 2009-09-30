//
//  MvrItemUI.h
//  Mover3
//
//  Created by ∞ on 17/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Network+Storage/MvrItem.h"

@class MvrItemSource, MvrItemAction;

@interface MvrItemUI : NSObject {}

+ (void) registerUI:(MvrItemUI*) ui forItemClass:(Class) c;
+ (void) registerClass;

+ (MvrItemUI*) UIForItemClass:(Class) i;
+ (MvrItemUI*) UIForItem:(MvrItem*) i;

+ (NSSet*) supportedItemClasses;
+ (NSArray*) supportedItemSources;

// Called by item sources constructed with +[L0ItemSource itemSourceWithDisplayName:correspondingUI:].
- (void) beginAddingItemForSource:(MvrItemSource*) source;

// Called to make a representing image for the item (shown on the slide). Should be as fast as humanly possible.
- (UIImage*) representingImageWithSize:(CGSize) size forItem:(id) i;

// Called to postprocess (usually, store) the item just before it gets added to the storage central.
- (void) didReceiveItem:(MvrItem*) i;

// -- - -- Actions support -- - --

// The main action, which is executed on double-tapping and is the first shown on the actions menu. nil == do nothing on double tap.
- (MvrItemAction*) mainActionForItem:(MvrItem*) i;

// Additional actions, which are shown on the action menu.
// This does not include the Remove action, which is instead added automatically by the app delegate.
- (NSArray*) additionalActionsForItem:(MvrItem*) i;

// These control the Remove menu item.

// If NO, the user isn't offered the option to remove the item.
- (BOOL) isItemRemovable:(MvrItem*) i;

// If NO, Mover's got the only copy of the item and presents a much harsher message to the user on removal. If YES, it allows removal without a confirmation.
- (BOOL) isItemSavedElsewhere:(MvrItem*) i;


// These standard actions call the methods at the end of the list. You can return them from -additionalActions... or -mainAction... to exploit common localizations and implementations and such.

// Show or open the item. The difference between 'Show' and 'Open' is that the first is done within Mover, while the second closes Mover to open another app. Both call -performShowOrOpenAction:withItem:.
- (MvrItemAction*) showAction;
- (MvrItemAction*) openAction;

// Copies the item to the clipboard.
- (MvrItemAction*) copyAction;

// Send the item via e-mail.
- (MvrItemAction*) sendByEmailAction;

// Methods called by the above actions:
- (void) performShowOrOpenAction:(MvrItemAction*) showOrOpen withItem:(MvrItem*) i; // abstract!
- (void) performCopyAction:(MvrItemAction*) copy withItem:(MvrItem*) i; // by default, replaces general pasteboard with [ (item type) => (item storage's data) ].
- (void) performSendByEmail:(MvrItemAction*) send withItem:(MvrItem*) i;

@end


// Item sources correspond to the choices available when pressing "+" on the main screen.

@interface MvrItemSource : NSObject {
	NSString* displayName;
	MvrItemUI* correspondingUI;
}

+ registeredItemSources;

// For sources that subclass MvrItemSource and override -beginAddingItem;
+ itemSourceWithDisplayName:(NSString*) name;
- (id) initWithDisplayName:(NSString*) name;

// For UI controllers that make vanilla MvrItemSources and want to get -beginAddingItemForSource:
+ itemSourceWithDisplayName:(NSString*) name correspondingUI:(MvrItemUI*) ui;

@property(readonly, copy) NSString* displayName;

- (void) beginAddingItem;
@property(readonly, retain) MvrItemUI* correspondingUI;

// If NO, temporarily unavailable (won't be shown)
@property(readonly) BOOL available;

@end

// Item actions correspond to the choices available when pressing the action button on an item (or press-and-holding).

@interface MvrItemAction : NSObject {
	NSString* displayName;
	id target; SEL selector;
}

// Uses the default impl.
// The selector must be of the form -performAction:(MvrItemAction*) thisAction withItem:(MvrItem*) guessWhat;
+ actionWithDisplayName:(NSString*) name target:(id) target selector:(SEL) selector;

// Designated for subclasses.
- (id) initWithDisplayName:(NSString*) string;

// Runs the action.
- (void) performActionWithItem:(MvrItem*) i;

// Display name.
@property(readonly, copy) NSString* displayName;

@end
