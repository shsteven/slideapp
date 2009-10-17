//
//  MvrItemUI.h
//  Mover3
//
//  Created by ∞ on 17/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

#import "Network+Storage/MvrItem.h"

@class MvrItemSource, MvrItemAction;

@interface MvrItemUI : NSObject <MFMailComposeViewControllerDelegate> {}

+ (void) registerUI:(MvrItemUI*) ui forItemClass:(Class) c;
+ (void) registerClass;

+ (MvrItemUI*) UIForItemClass:(Class) i;
+ (MvrItemUI*) UIForItem:(MvrItem*) i;

+ (NSSet*) supportedItemClasses;
- (NSArray*) supportedItemSources;

// Called by item sources constructed with +[L0ItemSource itemSourceWithDisplayName:correspondingUI:].
// ABSTRACT! If you use an item source declared like that you MUST override this.
- (void) beginAddingItemForSource:(MvrItemSource*) source;

// Called to make a representing image for the item (shown on the slide). Should be as fast as humanly possible.
// ABSTRACT! MUST BE OVERRIDEN!
- (UIImage*) representingImageWithSize:(CGSize) size forItem:(id) i;

// Description of an item for accessibility purposes.
// ABSTRACT! MUST BE OVERRIDDEN!
- (NSString*) accessibilityLabelForItem:(id) i;

// Called to postprocess (usually, store) the item just before it gets added to the storage central.
- (void) didReceiveItem:(id) i;

// As above but just after adding to the storage central.
- (void) didStoreItem:(id) i;

// -- - -- Actions support -- - --

// The main action, which is executed on double-tapping and is the first shown on the actions menu. nil == do nothing on double tap.
// Default impl returns nil.
- (MvrItemAction*) mainActionForItem:(id) i;

// Additional actions, which are shown on the action menu.
// This does not include the Remove action, which is instead added automatically by the app delegate.
// Default impl returns empty array.
- (NSArray*) additionalActionsForItem:(id) i;

// YES if there is at least one action returned by additionalActionsForItem: that is available.
- (BOOL) hasAdditionalActionsAvailableForItem:(id) i;

// These control the Remove menu item:
// If NO, the user isn't offered the option to remove the item.
// Default impl returns YES.
- (BOOL) isItemRemovable:(id) i;

// If NO, Mover's got the only copy of the item and presents a much harsher message to the user on removal. If YES, it allows removal without a confirmation.
// Default impl returns NO.
- (BOOL) isItemSavedElsewhere:(id) i;


// These standard actions call the methods at the end of the list. You can return them from -additionalActions... or -mainAction... to exploit common localizations and implementations and such.

// Show or open the item. The difference between 'Show' and 'Open' is that the first is done within Mover, while the second closes Mover to open another app. Both call -performShowOrOpenAction:withItem:.
- (MvrItemAction*) showAction;
- (MvrItemAction*) openAction;

// Copies the item to the clipboard. It's 'copy', but 'copy' is a significant name in objc, so.
- (MvrItemAction*) clipboardAction;

// Send the item via e-mail.
- (MvrItemAction*) sendByEmailAction;

// Methods called by the above actions:
- (void) performShowOrOpenAction:(MvrItemAction*) showOrOpen withItem:(id) i; // ABSTRACT!
- (void) performCopyAction:(MvrItemAction*) copy withItem:(id) i; // by default, replaces general pasteboard with [ (item type) => (item storage's data) ].
- (void) performSendByEmail:(MvrItemAction*) send withItem:(id) i;

// E-mail support.

// If YES, shows an overlay view while preparing stuff. Good if you have to keep the main thread busy for a long time in fromItem:getData:etc.etc.
// Defaults to NO.
- (BOOL) showsOverlayWhilePreparingEmailForItem:(id) i;

// This method extracts e-mail-relevant data from the given item. None of the arguments can be NULL; they must all point to valid memory locations. The method must do the following:
// - Either set *data to nil, to indicate the e-mail message must have no attachment, or set *data, *mimeType and *fileName to valid attachment data, MIME type and filename for e-mail sending.
// - Either set *body to nil, to indicate the e-mail message will have no default body, or set *body to the default body and *html to whether the default body is HTML or not.
// The default implementation returns the item storage's data, retrieves the MIME type from UTType* functions for the item's type (using application/octet-stream if that fails), and retrieves the extension from the item path if available, from UTType* functions for the item's type if that fails, and finally tries calling -pathExtensionForItem: if that fails too. It provides no default body.
- (void) fromItem:(id) i getData:(NSData**) data mimeType:(NSString**) mimeType fileName:(NSString**) fileName messageBody:(NSString**) body isHTML:(BOOL*) html;

// ABSTRACT!
// Used by the default impl of -fromItem:getData:mimeType:fileName:messageBody:isHTML: if it can't determine the path extension for an item (because its path has none and CoreServices doesn't know).
- (NSString*) pathExtensionForItem:(id) i;

@end


// Item sources correspond to the choices available when pressing "+" on the main screen.

@interface MvrItemSource : NSObject {
	NSString* displayName;
	MvrItemUI* correspondingUI;
}

+ registeredItemSources;
- (void) registerSource;

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
	BOOL available;
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

// If NO, temporarily unavailable (won't be shown)
@property BOOL available;

@end
