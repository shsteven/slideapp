//
//  L0BeamableItem.h
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdint.h>

#import "BLIP.h"

@class MvrItemStorage;


@interface L0MoverItem : NSObject {
	MvrItemStorage* storage;

	NSString* title;
	NSString* type;
	UIImage* representingImage;	
	
	NSMutableDictionary* autocache;
}

+ (void) registerClass;

+ (void) registerClass:(Class) c forType:(NSString*) type;
+ (Class) classForType:(NSString*) c;

@property(copy) NSString* title;
@property(copy) NSString* type;
@property(retain) UIImage* representingImage;

// Funnels

+ (NSArray*) supportedTypes;
- (NSData*) produceExternalRepresentation;

// Designated initializer for items that are loaded from existing storage.
// -init is also a designated initializer for items that are created "from nothing". In that case, the first call to -storage will produce a brand new storage from this item's external representation.
- (id) initWithStorage:(MvrItemStorage*) s type:(NSString*) ty title:(NSString*) ti;

- (void) storeToAppropriateApplication;

// Persistance methods.
+ itemWithStorage:(MvrItemStorage*) storage type:(NSString*) type title:(NSString*) title;
@property(readonly, retain) MvrItemStorage* storage;

- (void) clearCache;

// -- - --
// Autocache support

// The autocache is a set of key-value pairs that can be removed from memory at any time.
// You can use the accessors below to set and get objects from the cache, but if you try to access the cached object for a key that does not exist, it will be automatically recreated by calling -objectForEmptyCacheKey: (which in turn calls -objectForEmpty<Key>CacheKey if it exists).
// Additionally, the cache is guaranteed never to empty itself unless there is also a storage object attached to this item. In practice, this means that you can set an object in the cache in a constructor calling -init and it won't be lost until the item has had a chance to offload itself to disk. Make sure you're able to reconstruct the object from the storage and it'll automatically be managed.
- (id) cachedObjectForKey:(NSString*) key;
- (void) setCachedObject:(id) object forKey:(NSString*) key;
- (void) removeCachedObjectForKey:(NSString*) key;

// Called when a cached object is requested for an empty key. If - (id) <key>ForCaching; exists on self, it's called and its value returned. Otherwise, it returns nil.
// Returning nil from this object does not alter the cache, and makes the cachedObjectForKey: call return nil.
- (id) objectForEmptyCacheKey:(NSString*) key;

@end

@interface L0MoverItem (L0BLIPBeaming)

- (BLIPRequest*) contentsAsBLIPRequest;
+ (id) itemWithContentsOfBLIPRequest:(BLIPRequest*) req;

@end
