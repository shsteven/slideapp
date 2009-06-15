//
//  L0MoverItemUI.h
//  Mover
//
//  Created by ∞ on 15/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#import "L0MoverItemAction.h"
#import "L0MoverItem.h"

@interface L0MoverItemUI : NSObject <MFMailComposeViewControllerDelegate> {}

+ (void) registerUI:(L0MoverItemUI*) ui forItemClass:(Class) c;
+ (void) registerClass;

+ (L0MoverItemUI*) UIForItemClass:(Class) i;
+ (L0MoverItemUI*) UIForItem:(L0MoverItem*) i;

// Funnels
+ (NSArray*) supportedItemClasses;

- (L0MoverItemAction*) mainActionForItem:(L0MoverItem*) i;
- (NSArray*) additionalActionsForItem:(L0MoverItem*) i;

- (L0MoverItemAction*) showAction;
- (L0MoverItemAction*) openAction;
// The above actions have the receiver as target and the following method as their selector.
- (void) showOrOpenItem:(L0MoverItem*) i forAction:(L0MoverItemAction*) a;

- (L0MoverItemAction*) resaveAction;
// whose target is self and whose selector is:
- (void) resaveItem:(L0MoverItem*) i forAction:(L0MoverItemAction*) a;

- (L0MoverItemAction*) shareByEmailAction;
// target = self, action:
- (void) shareItemByEmail:(L0MoverItem*) i forAction:(L0MoverItemAction*) a;
// Unlike the above this action is implemented — by default, it shows a
// mail sheet with a single attachment (the item). 
// You can override the method below to fine-tune what happens next.

// Any out param may be NULL if we're not interested in it.
// default: d == [i externalRepresentation]; t == result of UTTypeCopyPreferredTagWithClass() on i.type for MIME type; f == i.title, followed by the result of UTTypeCopyPreferredTagWithClass() on i.type for extension.
// returns NO if any of the parts that weren't NULL could not be made.
- (BOOL) fromItem:(L0MoverItem*) i getMailAttachmentData:(NSData**) d mimeType:(NSString**) t fileName:(NSString**) f;

- (BOOL) removingFromTableIsSafeForItem:(L0MoverItem*) i;

@end
