//
//  MvrItemUI.h
//  Mover3
//
//  Created by ∞ on 17/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Network+Storage/MvrItem.h"

@class MvrItemSource;

@interface MvrItemUI : NSObject {}

+ (void) registerUI:(MvrItemUI*) ui forItemClass:(Class) c;
+ (void) registerClass;

+ (MvrItemUI*) UIForItemClass:(Class) i;
+ (MvrItemUI*) UIForItem:(MvrItem*) i;

+ (NSArray*) supportedItemClasses;
+ (NSArray*) supportedItemSources;

- (void) beginAddingItemForSource:(MvrItemSource*) source;

@end



@interface MvrItemSource : NSObject {
	NSString* displayName;
	MvrItemUI* correspondingUI;
}

+ registeredItemSources;

// For sources that subclass MvrItemSource and override -beginAddingItem;
+ itemSourceWithDisplayName:(NSString*) name;

// For UI controllers that make vanilla MvrItemSources and want to get -beginAddingItemForSource:
+ itemSourceWithDisplayName:(NSString*) name correspondingUI:(MvrItemUI*) ui;

@property(readonly, copy) NSString* displayName;

- (void) beginAddingItem;
@property(readonly, retain) MvrItemUI* correspondingUI;

@end