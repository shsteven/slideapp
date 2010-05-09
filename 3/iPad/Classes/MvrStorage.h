//
//  MvrStorage.h
//  Mover3-iPad
//
//  Created by ∞ on 08/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MvrStorage : NSObject {
	NSString* itemsDirectory, * metadataDirectory;
	
	NSMutableSet* allStoredItems;
}

- (id) initWithItemsDirectory:(NSString*) i metadataDirectory:(NSString*) m;

@property(readonly) NSMutableSet* storedItems;
- (NSSet*) allStoredItems;

- (void) migrateFrom30StorageCentralMetadata:(id) meta;

@end
