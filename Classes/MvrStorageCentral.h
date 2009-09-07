//
//  MvrStorageCentral.h
//  Mover
//
//  Created by ∞ on 07/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L0MoverItem.h"

@interface MvrStorageCentral : NSObject {
	NSMutableSet* mutableStoredItems;
	NSMutableDictionary* metadata;
}

+ sharedCentral;

// Add an item here to save it to persistent storage. Remove it from here to remove it from persistent storage. The item storage object used by this item will be made persistent on addition and nonpersistent on removal.
// The item may be asked to immediately clear its cache. You should access the item (eg to produce thumbnails) BEFORE putting it into storage, to avoid the item's content being needlessly reloaded from disk.
- (void) addStoredItemsObject:(L0MoverItem*) item;
- (void) removeStoredItemsObject:(L0MoverItem*) item;
@property(readonly) NSSet* storedItems;

@end


// -----

enum {
	kMvrStorageDestinationMemory,
	kMvrStorageDestinationDisk,
};
typedef NSUInteger MvrStorageDestination;

@interface MvrItemStorage : NSObject {
	BOOL persistent;
	unsigned long long contentLength;
	
	NSData* data;
	NSString* path;
	
	NSOutputStream* lastOutputStream;
	NSString* outputStreamPath;
}

// Creating a new item storage.
+ itemStorage; // a new empty one.
+ itemStorageWithData:(NSData*) data;
+ itemStorageFromFileAtPath:(NSString*) path error:(NSError**) e; // If not in NSTemporaryDirectory(), it might be copied.
// + itemStorageWithContentsOfStream:(NSInputStream*) stream;

// If NO, the contents will be lost when the item storage is deallocated.
// You cannot set this property. Instead, add an item with this storage to the storage central.
@property(readonly, getter=isPersistent) BOOL persistent;

// The size in bytes of the content of this storage. (See 'Writing' for caveats.)
@property unsigned long long contentLength;

// Causes the item storage to clear its cache and remove all in-memory content by offloading it to disk.
- (void) clearCache;

#pragma mark -
#pragma mark Reading from item storage
// These methods are independent of the actual kind of storage (in memory or on disk) used for this storage.
// The above means that if you call -data and the item was saved on a file on disk, it will be loaded. This is usually not the desired behavior if the item is big. See below for opportunistic reading methods.

@property(copy) NSData* data;

// The whole content of the storage as a NSData object. (For info on setting, see below in the 'Writing' section.)
- (NSData*) data;

// The path to an app-accessible file on disk that contains the item's contents. Exists for as long as this object does if no undue interference happens.
- (NSString*) path;

// YES if this object has written data to a path on disk, NO if it only exists in memory (and would be offloaded by a call to -path).
@property(readonly) BOOL hasPath;

// An input stream reading from the content of the storage. Returned unopened.
- (NSInputStream*) inputStream;

// Opportunistic reading. These methods are used to choose a "good", performance-wise and memory-wise, way to access the storage's content.

// Returns the 'best' way you can access the storage's contents. This is either a NSData or a NSInputStream object. Roughly speaking, if the object is already entirely in memory, it will exploit this by returning the NSData object; but if not, it will instead return a stream to that data on disk (or wherever it is stored).
- (id) preferredContentObject;

// Returns a NSData object if the contentLength is equal or less to the limit, otherwise nil.
- (NSData*) dataIfLengthIsAtMost:(unsigned long long) maximumLength;

#pragma mark -
#pragma mark Writing to item storage
// All writing methods clear whatever contents the item storage previously held when called.

// Returns an unopened output stream. Write to this stream to set the contents of the item storage. The size for ...OfAssumedSize: will be used as a hint to the item storage to choose where to store what is written to the stream. Otherwise, if the size is unknown but the order of magnitude is, you can use ...ForStorageIn: to choose where to save the stream yourself.
// When you have finished writing to the stream and closed it, you MUST call the -endUsingOutputStream method to let the item storage take ownership of the data you wrote.
// It's a programmer error to use ANY method or access ANY property of this object before using -endUsingOutputStream OR to call it before closing the stream. Behavior is undefined in either case.
- (NSOutputStream*) outputStreamForContentOfAssumedSize:(unsigned long long) size;
- (NSOutputStream*) outputStreamForStorageIn:(MvrStorageDestination) destination;
- (void) endUsingOutputStream;

// Setting the .data property causes the whole content of the storage item to be reset to whatever you passed. Depending on the length of the data, it might immediately be written to disk rather than keeping a copy in memory (with similar size limits than those used for outputStreamForContentOfAssumedSize:).
- (void) setData:(NSData*) data;

@end
