//
//  MvrStorageCentral.m
//  Mover
//
//  Created by ∞ on 07/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrStorageCentral.h"
#import <MuiKit/MuiKit.h>

#import <MobileCoreServices/MobileCoreServices.h>

#import "L0MoverAppDelegate.h"

NSString* const kMvrItemStorageErrorDomain = @"net.infinite-labs.Mover.MvrItemStorageErrorDomain";

// 1 MB or more of data? go straight to disk whenever possible.
#define kMvrItemStorageMaximumAmountOfDataBeforeOffloading 1024 * 1024

@interface MvrItemStorage ()
+ itemStorageFromFileAtPath:(NSString*) path persistent:(BOOL) persistent error:(NSError**) e;
- (void) resetData;
@property(copy, setter=private_setPath:) NSString* path;
@property(assign, setter=private_setPersistent:) BOOL persistent;

@property(copy, getter=private_outputStreamPath, setter=private_setOutputStreamPath:) NSString* outputStreamPath;

@end

@interface MvrStorageCentral ()

+ (NSString*) unusedTemporaryFileNameWithPathExtension:(NSString*) ext;
+ (NSString*) unusedPathInDirectory:(NSString*) path withPathExtension:(NSString*) ext fileName:(NSString**) name;
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
	if (self = [super init]) {
		metadata = [NSMutableDictionary new];
		dispatcher = [[L0KVODispatcher alloc] initWithTarget:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	}
	
	return self;
}

- (void) didReceiveMemoryWarning:(NSNotification*) n;
{
	[self clearCache];
}

- (void) dealloc;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[metadata release];
	[dispatcher release];
	[mutableStoredItems release];
	[super dealloc];
}

+ (NSString*) unusedTemporaryFileNameWithPathExtension:(NSString*) ext;
{
	return [self unusedPathInDirectory:NSTemporaryDirectory() withPathExtension:ext fileName:NULL];
}

+ (NSString*) unusedPathInDirectory:(NSString*) path withPathExtension:(NSString*) ext fileName:(NSString**) name;
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* newPath, * uuidName;
	do {
		uuidName = [[L0UUID UUID] stringValue];
		if (ext && ![ext isEqual:@""])
			uuidName = [uuidName stringByAppendingPathExtension:ext];
		newPath = [path stringByAppendingPathComponent:uuidName];
	} while ([fm fileExistsAtPath:newPath]);
	
	if (name) *name = uuidName;
	return newPath;
}

- (NSSet*) storedItems;
{
	if (mutableStoredItems)
		return mutableStoredItems;
	
	mutableStoredItems = [NSMutableSet new];
	[metadata removeAllObjects];

	NSDictionary* storedMetadata = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"L0SlidePersistedItems"];
	if (!storedMetadata)
		return mutableStoredItems; // empty
	
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
				[mutableStoredItems addObject:item];
				[metadata setObject:[NSDictionary dictionaryWithObjectsAndKeys:
									 title, @"Title",
									 type, @"Type",
									 nil] forKey:name];
			}
		}
	}
	
	return mutableStoredItems;
}

- (void) addStoredItemsObject:(L0MoverItem *)item;
{
	if ([self.storedItems containsObject:item])
		return;
	
	MvrItemStorage* storage = [item storage];
	NSString* path, * name;
	path = [[self class] unusedPathInDirectory:[L0Mover documentsDirectory] withPathExtension:[storage.path pathExtension] fileName:&name];
	
	L0Log(@"Older path of storage about to be made persistent: %@", storage.hasPath? @"(none)" : storage.path);
	
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
	
	L0Log(@"Item made persistent: %@ (%@)", item, storage);
	
	[mutableStoredItems addObject:item];
	
	[dispatcher observe:@"path" ofObject:storage usingSelector:@selector(pathOfItemStorage:changed:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
}

- (void) pathOfItemStorage:(MvrItemStorage*) storage changed:(NSDictionary*) change;
{
	NSString* oldPath = L0KVOPreviousValue(change);
	
	if (!storage.persistent || ![mutableStoredItems containsObject:storage] || !storage.path || !oldPath)
		return;
	
	NSString* oldItemName = [oldPath lastPathComponent];
	id oldMetadata;
	if ((oldMetadata = [metadata objectForKey:oldItemName])) {
		[metadata setObject:oldMetadata forKey:[storage.path lastPathComponent]];
		[metadata removeObjectForKey:oldPath];
		[self saveMetadata];
	}
}

- (void) removeStoredItemsObject:(L0MoverItem*) item;
{
	if (![self.storedItems containsObject:item])
		return;
	
	[dispatcher endObserving:@"path" ofObject:item];
	
	[mutableStoredItems removeObject:item];

	MvrItemStorage* storage = [item storage];
	if (storage.hasPath) {
		NSString* path = storage.path, * name = [path lastPathComponent],
			* newPath = [[self class] unusedTemporaryFileNameWithPathExtension:[storage.path pathExtension]];
		
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
		NSString* newPath = [MvrStorageCentral unusedTemporaryFileNameWithPathExtension:[path pathExtension]];
		
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
	NSAssert(data || path, @"Either we have data in memory or we have a file on disk.");

	if (data)
		return [data length];
	else if (path) {
		NSError* e;
		id contentLengthObject = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:&e] objectForKey:NSFileSize];
		
		if (!contentLengthObject)
			[NSException raise:@"MvrStorageException" format:@"Could not find out the new size for the offloading file. Error: %@", e];
		
		return [contentLengthObject unsignedLongLongValue];
	}
	
	return 0; // Should never happen due to the assert.
}

- (NSData*) data;
{
	NSAssert(data || path, @"Either we have data in memory or we have a file on disk.");
	
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
	NSAssert(data || path, @"Either we have data in memory or we have a file on disk.");
	
	if (!path)
		[self clearCache];
	
	return path;
}

- (void) private_setPath:(NSString*) p;
{
	if (p != path) {
		[path release];
		path = [p copy];
		
		L0Log(@"path now = '%@', length = %llu", path, self.contentLength);
	}
}

- (NSInputStream*) inputStream;
{
	NSAssert(data || path, @"Either we have data in memory or we have a file on disk.");
	
	if (data)
		return [NSInputStream inputStreamWithData:data];
	else
		return [NSInputStream inputStreamWithFileAtPath:path];
}

- (id) preferredContentObject;
{
	NSAssert(data || path, @"Either we have data in memory or we have a file on disk.");
	
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
	NSAssert(!persistent, @"Persistent item storage cannot be altered. Remove the item from the storage central first.");
	
	if (destination == kMvrStorageDestinationMemory) {
		lastOutputStream = [[NSOutputStream outputStreamToMemory] retain];
		return lastOutputStream;
	} else {
		self.outputStreamPath = [MvrStorageCentral unusedTemporaryFileNameWithPathExtension:@""];
		return [NSOutputStream outputStreamToFileAtPath:self.outputStreamPath append:NO];
	}
}

- (void) endUsingOutputStream;
{
	if (lastOutputStream) {
		self.data = [lastOutputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
		[lastOutputStream release]; lastOutputStream = nil;
	} else {
		self.path = self.outputStreamPath;
		self.outputStreamPath = nil;
	}
}

- (void) clearCache;
{
	if (!data) return;
	
	NSString* thePath = path;
	if (!thePath) // we'd have a path if we had been made persistant by the storage central.
		thePath = [MvrStorageCentral unusedTemporaryFileNameWithPathExtension:@""];
	
	NSError* e;
	BOOL done = [data writeToFile:thePath options:NSAtomicWrite error:&e];
	if (!done)
		[NSException raise:@"MvrStorageException" format:@"Could not clear cache for this storage item: %@ (error: %@)", self ,e];

	if (!path)
		self.path = thePath;
	
	[data release]; data = nil;
}

- (void) resetData;
{
	NSAssert(!persistent, @"Persistent item storage cannot be altered. Remove the item from the storage central first.");

	if (path) {
		[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
		self.path = nil;
	}
	
	if (data) {
		[data release]; data = [NSData new];
	}
}

@synthesize path, outputStreamPath;

- (BOOL) hasPath;
{
	return path != nil;
}

- (BOOL) setPathExtension:(NSString*) ext error:(NSError**) e;
{
	NSString* currentExt = [self.path pathExtension];
	if ([currentExt isEqual:ext])
		return YES;
	
	[self willChangeValueForKey:@"path"];
	NSString* newPath = [[self.path stringByDeletingPathExtension] stringByAppendingPathExtension:ext];
	BOOL done = [[NSFileManager defaultManager] moveItemAtPath:self.path toPath:newPath error:e];
	if (done)
		self.path = newPath;
	[self didChangeValueForKey:@"path"];
	
	return done;
}

- (BOOL) setPathExtensionAssumingType:(id) uti error:(NSError**) e;
{
	CFStringRef ext = UTTypeCopyPreferredTagWithClass((CFStringRef) uti, kUTTagClassFilenameExtension);

	if (!ext) {
		if (e) *e = [NSError errorWithDomain:kMvrItemStorageErrorDomain code:kMvrItemStorageNoFilenameExtensionForTypeError userInfo:nil];
		return NO;
	}
	
	BOOL done = [self setPathExtension:(NSString*) ext error:e];
	CFRelease(ext);
	
	return done;
}

- (NSString*) description;
{
	return [NSString stringWithFormat:@"%@ { path = '%@', data = %@, length = %llu, pending output stream = %@, persistent? = %d }", [super description], path, data? @"not nil" : @"nil", self.contentLength, lastOutputStream, persistent];
}

@end