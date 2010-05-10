//
//  MvrItemAction.h
//  Mover3-iPad
//
//  Created by ∞ on 05/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MvrItem;

#if __BLOCKS__
typedef void (^MvrItemActionBlock)(MvrItem* i);
#endif

// Item actions correspond to the choices available when pressing the action button on an item (or press-and-holding).

@interface MvrItemAction : NSObject {
	NSString* displayName;
	id target; SEL selector;
	BOOL available;
	
#if __BLOCKS__
	MvrItemActionBlock block;
#endif
	
	BOOL continuesInteractionOnTable;
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

// If NO, unavailable for this specific item (won't be shown). Defaults to .available's value.
- (BOOL) isAvailableForItem:(MvrItem*) i;

#if __BLOCKS__
+ actionWithDisplayName:(NSString*) name block:(MvrItemActionBlock) block;
#endif

// if NO (default), works just like item actions in Mover for iPhone -- fire and forget.
// if YES, the action will continue interaction on the table (for example, displaying an additional popover on the item's view). In that case, the action must later call the -didFinishAction method on the appropriate item controller.
@property BOOL continuesInteractionOnTable;

@end
