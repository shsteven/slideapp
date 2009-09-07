//
//  MvrStorageCentral.m
//  Mover
//
//  Created by ∞ on 07/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrStorageCentral.h"
#import <MuiKit/MuiKit.h>

#import "L0MoverAppDelegate.h"

// 1 MB or more of data? go straight to disk whenever possible.
#define kMvrItemStorageMaximumAmountOfDataBeforeOffloading 1024 * 1024

@interface MvrItemStorage ()
+ itemStorageFromFileAtPath:(NSString*) path persistent:(BOOL) persistent error:(NSError**) e;
- (void) resetData;
@property(copy, setter=private_setPath:) NSString* path;
@property(assign, setter=private_setPersistent:) BOOL persistent;

@end

@interface MvrStorageCentral ()

+ (NSString*) unusedTemporaryFileName;
+ (NSString*) unusedPathInDirectory:(NSString*) path fileName:(NSString**) name;
- (void) saveMetadata;

@end

static BOOL MvrFileIsInDirectory(NSString* file, NSString* directory) {
	NSArray* dirParts = [[directory stringByStandardizingPath] pathComponents],
		* fileParts = [[file stringByStandardizingPath] pathComponents];
	
	if ([dirParts count] <= [fileParts count])
		return NO;
	
	int i = 0; for (NSString* part in dirParts) {
		if (![[fileParts objectAtIndex:i] isEqual:part])
			return NO;
		i++;
	}
	
	return YES;
}

#pragma mark -
#pragma mark Storage Central.


@implementation MvrStorageCentral

L0ObjCSingletonMethod(sharedCentral)

- (id) init;
{
	if (self = [super init])
		metadata = [NSMutableDictionary new];
	
	return self;
}

- (void) dealloc;
{
	[metadata release];
	[storedItems release];
	[super dealloc];
}

+ (NSString*) unusedTemporaryFileName;
{
	return [self unusedPathInDirectory:NSTemporaryDirectory() fileName:NULL];
}

+ (NSString*) unusedPathInDirectory:(NSString*) path fileName:(NSString**) name;
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* newPath, * uuidName;
	do {
		uuidName = [[L0UUID UUID] stringValue];
		newPath = [path stringByAppendingPathComponent:uuidName];
	} while ([fm fileExistsAtPath:newPath]);
	
	if (name) *name = uuidName;
	return newPath;
}

- (NSSet*) storedItems;
{
	if (storedItems)
		return storedItems;
	
	storedItems = [NSMutableSet new];
	[metadata removeAllObjects];

	NSDictionary* storedMetadata = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"L0SlidePersistedItems"];
	if (!storedMetadata)
		return storedItems; // empty
	
	NSString* docs = [L0Mover documentsDirectory];
	
	for (NSString* name in storedMetadata) {
		NSDictionary* itemInfo = [storedMetadata objectForKey:name];
		if (![itemInfo isKindOfClass:[NSDictionary class]])
			continue;
		
		NSString* title = [itemInfo objectForKey:@"Title"];
		NSString* type = [itemInfo objectForKey:@"Type"];
		
		if (!title || !type)
			continue;
		
		NSString* path = [docs stringByAppendingPathComponent:name];
		
		NSError* e;
		MvrItemStorage* itemStorage = [MvrItemStorage itemStorageFromFileAtPath:path persistent:YES error:&e];
		if (!itemStorage) {
			L0LogAlways(@"%@", e);
		} else {
			L0MoverItem* item = [L0MoverItem itemWithStorage:itemStorage type:type title:title];
			if (item) {
				[storedItems addObject:item];
				[metadata setObject:[NSDictionary dictionaryWithObjectsAndKeys:
									 title, @"Title",
									 type, @"Type",
									 nil] forKey:name];
			}
		}
	}
	
	return storedItems;
}

- (void) addStoredItemsObject:(L0MoverItem *)item;
{
	if ([self.storedItems containsObject:item])
		return;
	
	MvrItemStorage* storage = [item storage];
	NSString* path, * name;
	path = [[self class] unusedPathInDirectory:[L0Mover documentsDirectory] fileName:&name];
	
	NSError* e;
	BOOL done = [[NSFileManager defaultManager] moveItemAtPath:storage.path toPath:path error:&e];
	if (!done) {
		L0LogAlways(@"%@", e);
		return;
	}
	
	[metadata setObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 item.title, @"Title",
						 item.type, @"Type",
						 nil] forKey:name];
	[self saveMetadata];
	
	storage.path = path;
	storage.persistent = YES;
	
	[storedItems addObject:item];
}

- (void) removeStoredItemsObject:(L0MoverItem*) item;
{
	if (![storedItems containsObject:item])
		return;
	
	[storedItems removeObject:item];

	MvrItemStorage* storage = [item storage];
	if (storage.hasPath) {
		NSString* path = storage.path, * name = [path lastPathComponent],
			* newPath = [[self class] unusedTemporaryFileName];
		
		[metadata removeObjectForKey:name];
		[self saveMetadata];
		
		NSError* e;
		BOOL done = [[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:&e];
		if (!done)
			L0LogAlways(@"%@", e);
		
		storage.path = newPath;
	}
	
	storage.persistent = NO;
}

- (void) saveMetadata;
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:metadata forKey:@"L0SlidePersistedItems"];
	[ud synchronize];
}

- (void) clearCache;
{
	[self.storedItems makeObjectsPerformSelector:@selector(clearCache)];
}

@end

#pragma mark -
#pragma mark Item storage.


@implementation MvrItemStorage

+ itemStorage;
{
	return [[self new] autorelease];
}

+ itemStorageWithData:(NSData*) data;
{
	MvrItemStorage* me = [self itemStorage];
	me.data = data;
	return me;
}

+ itemStorageFromFileAtPath:(NSString*) path error:(NSError**) e;
{
	return [self itemStorageFromFileAtPath:path persistent:NO error:e];
}

- (void) dealloc;
{
	if (!persistent && path) {
		L0Log(@"Deleting offloading file %@", path);
		[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
	}
	
	[data release];
	[path release];
	[lastOutputStream release];
	[super dealloc];
}

+ itemStorageFromFileAtPath:(NSString*) path persistent:(BOOL) persistent error:(NSError**) e;
{
	NSFileManager* fm = [NSFileManager defaultManager];
	if (![fm attributesOfItemAtPath:path error:e])
		return nil;
	
	// if persistent == YES, we simply assume the file is already in persistent storage.
	// Otherwise...
	if (!persistent && !MvrFileIsInDirectory(path, NSTemporaryDirectory())) {
		NSString* newPath = [MvrStorageCentral unusedTemporaryFileName];
		
		if (![fm copyItemAtPath:path toPath:newPath error:e])
			return nil;
		
		path = newPath;
	}
	
	MvrItemStorage* me = [self itemStorage];
	me.path = path;
	return me;
}

@synthesize persistent;

- (unsigned long long) contentLength;
{
	if (data)
		return [data length];
	
	return contentLength;
}

- (NSData*) data;
{
	if (!data)
		data = [[NSData dataWithContentsOfMappedFile:path] retain];

	return data;
}

- (void) setData:(NSData*) d;
{
	if (d != data) {
		[self resetData];
		
		[data release]; data = nil;
		data = [d copy];
		
		if ([data length] > kMvrItemStorageMaximumAmountOfDataBeforeOffloading)
			[self clearCache];
	}
}

- (NSString*) path;
{
	if (!path)
		[self clearCache];
	
	return path;
}

- (NSInputStream*) inputStream;
{
	if (data)
		return [NSInputStream inputStreamWithData:data];
	else
		return [NSInputStream inputStreamWithFileAtPath:path];
}

- (id) preferredContentObject;
{
	if (path && !data)
		return [self inputStream];
	else
		return data;
}

- (NSData*) dataIfLengthIsAtMost:(unsigned long long) maximumLength;
{
	if (self.contentLength <= maximumLength)
		return self.data;
	else
		return nil;
}

- (NSOutputStream*) outputStreamForContentOfAssumedSize:(unsigned long long) size;
{
	MvrStorageDestination d = (size > kMvrItemStorageMaximumAmountOfDataBeforeOffloading)?
		kMvrStorageDestinationDisk : kMvrStorageDestinationMemory;
	return [self outputStreamForStorageIn:d];
}

- (NSOutputStream*) outputStreamForStorageIn:(MvrStorageDestination) destination;
{
	if (destination == kMvrStorageDestinationMemory) {
		lastOutputStream = [[NSOutputStream outputStreamToMemory] retain];
		return lastOutputStream;
	} else {
		self.path = [MvrStorageCentral unusedTemporaryFileName];
		return [NSOutputStream outputStreamToFileAtPath:self.path append:NO];
	}
}

- (void) endUsingOutputStream;
{
	if (lastOutputStream) {
		self.data = [lastOutputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
		[lastOutputStream release]; lastOutputStream = nil;
	} else {
		NSError* e;
		id contentLengthObject = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:&e] objectForKey:NSFileSize];
		if (!contentLengthObject)
			[NSException raise:@"MvrStorageException" format:@"Could not find out the new size for the offloading file. Error: %@", e];
		
		contentLength = [contentLengthObject unsignedLongLongValue];
	}
}

- (void) clearCache;
{
	if (!data) return;
	
	if (!path) // we'd have a path if we had been made persistant by the storage central.
		self.path = [MvrStorageCentral unusedTemporaryFileName];
	
	NSError* e;
	BOOL done = [data writeToFile:path options:NSAtomicWrite error:&e];
	if (!done)
		[NSException raise:@"MvrStorageException" format:@"Could not clear cache for this storage item: %@ (error: %@)", self ,e];
	
	[data release]; data = nil;
}

- (void) resetData;
{
	if (path) {
		[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
		self.path = nil;
	}
	
	if (data) {
		[data release]; data = [NSData new];
	}
}

@synthesize contentLength, path;

- (BOOL) hasPath;
{
	return path != nil;
}

- (NSString*) description;
{
	return [NSString stringWithFormat:@"%@ { path = '%@', data = %@, length = %llu, pending output stream = %@ }", [super description], path, data? @"not nil" : @"nil", self.contentLength, lastOutputStream];
}

@end