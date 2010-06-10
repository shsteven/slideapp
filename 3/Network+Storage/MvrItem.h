//
//  MvrItem.h
//  Network+Storage
//
//  Created by ∞ on 13/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>

// The item's title as shown on the slide.
#define kMvrItemTitleMetadataKey @"MvrTitle"

// The item's original filename, if any.
#define kMvrItemOriginalFilenameMetadataKey @"MvrOriginalFilename"


// An item note key that can be used to save a localized description of the object's origin. Associated to a NSString*.
#define kMvrItemWhereFromNoteKey @"MvrWhereFrom"


// These macros produce accessors that provide data from the autocache for the given key. The cache key is the same as the getter's name.

#define MvrItemSynthesizeRetainFromAutocache(type, name, setterName) \
	- (type) name;\
	{\
		return [self cachedObjectForKey:@#name];\
	}\
	- (void) setterName (type) newValue_;\
	{\
		[self setCachedObject:newValue_ forKey:@#name];\
	}

#define MvrItemSynthesizeCopyFromAutocache(type, name, setterName) \
	- (type) name;\
	{\
		return [self cachedObjectForKey:@#name];\
	}\
	- (void) setterName (type) newValue_;\
	{\
		[self setCachedObject:[[newValue_ copy] autorelease] forKey:@#name];\
	}

#define MvrItemSynthesizeReadOnlyFromAutocache(type, name) \
	- (type) name;\
	{\
		return [self cachedObjectForKey:@#name];\
	}\

#import "MvrItemStorage.h"
#import "MvrUTISupport.h"

@interface MvrItem : NSObject {
	MvrItemStorage* storage;
	NSString* type;
	NSMutableDictionary* metadata;
	NSMutableDictionary* autocache;
	NSMutableDictionary* itemNotes;
}

- (id) init;
- (id) initWithStorage:(MvrItemStorage*) s type:(NSString*) type metadata:(NSDictionary*) m;
- (NSDictionary*) defaultMetadata;

+ (void) registerClass;
+ (NSSet*) supportedTypes; // abstract
+ (NSDictionary*) knownFallbackPathExtensions; // default == none. return type -> extension entries.

+ (void) registerClass:(Class) c forType:(NSString*) type;
+ (Class) classForType:(NSString*) c;
+ (BOOL) canProduceItemForType:(NSString*) type allowGenericItems:(BOOL) generic;

// These manage a registry of known extensions, in case the OS doesn't help us by giving 'em via the UTI infrastructure.
+ (void) setFallbackPathExtension:(NSString*) ext forType:(NSString*) type;
+ (NSString*) fallbackPathExtensionForType:(NSString*) type;
+ (NSSet*) typesForFallbackPathExtension:(NSString*) ext;

+ itemWithStorage:(MvrItemStorage*) s type:(NSString*) t metadata:(NSDictionary*) m;

@property(readonly, retain) MvrItemStorage* storage;
@property(readonly) BOOL hasStorage;

@property(copy) NSString* title;
@property(copy) NSString* type;
@property(readonly) NSMutableDictionary* metadata;

- (id) produceExternalRepresentation; // abstract

// If YES, this item requires stream support -- that is, it's (potentially) so large that it requires modern channels and scanners to send. Legacy channels should refuse to send items that require stream support.
// Defaults to NO. Objects that say NO may still be sent through a item storage's -inputStream if this is desirable and supported by the channel.
@property(readonly) BOOL requiresStreamSupport;

// Item notes are saved alongside the item and loaded with it, but not transmitted over the network. Can only contain property list types.
@property(copy) NSDictionary* itemNotes;
- (void) setObject:(id) o forItemNotesKey:(NSString*) key;
- (id) objectForItemNotesKey:(id) o;

// This method is only for use in GC apps and must be called at least once before references to this instance are lost. This method invalidates the underlying storage. See -[MvrItemStorage invalidate] for details.
// Calling another method of MvrItem after this method is called is a programmer error.
- (void) invalidate;

// -- - --
// Autocache support

// The autocache is a set of key-value pairs that can be removed from memory at any time.
// You can use the accessors below to set and get objects from the cache, but if you try to access the cached object for a key that does not exist, it will be automatically recreated by calling -objectForEmptyCacheKey: (which in turn calls -objectForEmpty<Key>CacheKey if it exists).
// Additionally, the cache is guaranteed never to empty itself unless there is also a storage object attached to this item. In practice, this means that you can set an object in the cache in a constructor calling -init and it won't be lost until the item has had a chance to offload itself to disk. Make sure you're able to reconstruct the object from the storage and it'll automatically be managed.
- (id) cachedObjectForKey:(NSString*) key;
- (void) setCachedObject:(id) object forKey:(NSString*) key;
- (void) removeCachedObjectForKey:(NSString*) key;

// Called when a cached object is requested for an empty key. If - (id) objectForEmpty<Key>CacheKey; exists on self, it's called and its value returned. Otherwise, it returns nil.
// Example: @"image" calls -objectForEmptyImageCacheKey.
// Returning nil from this object does not alter the cache, and makes the cachedObjectForKey: call return nil.
- (id) objectForEmptyCacheKey:(NSString*) key;

@end
