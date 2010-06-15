//
//  MvrItemStorage.m
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#define kMvrItemStorageAllowFriendMethods 1
#import "MvrItemStorage.h"

#import <MuiKit/MuiKit.h>
#import "MvrUTISupport.h"

#pragma mark -
#pragma mark Error stuff.

NSString* const kMvrItemStorageErrorDomain = @"net.infinite-labs.Mover.MvrItemStorageErrorDomain";

#pragma mark -
#pragma mark Directory functions.

static NSString* MvrStorageTemporaryDirectoryPath = nil;

NSString* MvrStorageTemporaryDirectory()
{
	if (!MvrStorageTemporaryDirectoryPath)
		MvrStorageSetTemporaryDirectory(NSTemporaryDirectory());
	
	return MvrStorageTemporaryDirectoryPath;
}

void MvrStorageSetTemporaryDirectory(NSString* path)
{
	if (MvrStorageTemporaryDirectoryPath != path) {
		[MvrStorageTemporaryDirectoryPath release];
		MvrStorageTemporaryDirectoryPath = [path copy];
	}
}

NSString* MvrUnusedPathInDirectoryWithExtension(NSString* path, NSString* ext, NSString** name)
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

NSString* MvrUnusedTemporaryFileNameWithPathExtension(NSString* ext)
{
	return MvrUnusedPathInDirectoryWithExtension(MvrStorageTemporaryDirectory(), ext, NULL);
}

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
#pragma mark Item storage.

@interface MvrItemStorage ()

- (void) resetDataByDeletingOffloadFile:(BOOL) delete;
@property(copy, getter=private_outputStreamPath, setter=private_setOutputStreamPath:) NSString* outputStreamPath;

@end


@implementation MvrItemStorage

#pragma mark Constructors

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
	return [self itemStorageFromFileAtPath:path options:0 error:e];
}

+ itemStorageFromFileAtPath:(NSString*) path options:(MvrItemStorageOptions) options error:(NSError**) e;
{
	return [self itemStorageFromFileAtPath:path persistent:(options & kMvrItemStorageDoNotTakeOwnershipOfFile) != 0 canMove:(options & kMvrItemStorageCanMoveOrDeleteFile) != 0 error:e];
}

- (void) dealloc;
{
	if (!persistent && path) {
		L0Log(@"Deleting offloading file %@", path);
		NSFileManager* fm = [NSFileManager new];
		[fm removeItemAtPath:path error:NULL];
		[fm release];
	}
	
	[data release];
	[path release];
	[lastOutputStream release];
	[desiredExtension release];
	[super dealloc];
}

+ itemStorageFromFileAtPath:(NSString*) path persistent:(BOOL) persistent canMove:(BOOL) canMove error:(NSError**) e;
{
	NSFileManager* fm = [NSFileManager defaultManager];
	if (![fm attributesOfItemAtPath:path error:e])
		return nil;
	
	// if persistent == YES, we simply assume the file is already in persistent storage.
	// Otherwise...
	if (!persistent && !MvrFileIsInDirectory(path, MvrStorageTemporaryDirectory())) {
		NSString* newPath = MvrUnusedTemporaryFileNameWithPathExtension([path pathExtension]);

		BOOL done = NO;
		if (canMove) {
			NSError* localError;
			if ([fm moveItemAtPath:path toPath:newPath error:&localError])
				done = YES;
			else
				L0LogAlways(@"An error occurred while moving file %@: %@. Retrying with copy.", path, localError);
		}
		
		if (!done) {
			if (![fm copyItemAtPath:path toPath:newPath error:e])
				return nil;
		}
		
		path = newPath;
	}
	
	MvrItemStorage* me = [self itemStorage];
	me.path = path;
	me.persistent = persistent;
	return me;
}

#pragma mark Accessing the storage

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

- (NSString*) path;
{
	NSAssert(data || path, @"Either we have data in memory or we have a file on disk.");
	
	if (!path)
		[self clearCache];
	
	return path;
}

- (void) private_setPath:(NSString*) p;
{
	[self willChangeValueForKey:@"path"];
	if (p != path) {
		[path release];
		path = [p copy];
		
		L0Log(@"path now = '%@'", path);
	}
	[self didChangeValueForKey:@"path"];
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

#pragma mark Writing to item storage

// 1 MB or more of data? go straight to disk whenever possible.
#define kMvrItemStorageMaximumAmountOfDataBeforeOffloading 1024 * 1024

- (void) setData:(NSData*) d;
{	
	if (d != data) {
		[self resetDataByDeletingOffloadFile:YES];
		
		[data release]; data = nil;
		data = [d copy];
		
		if ([data length] > kMvrItemStorageMaximumAmountOfDataBeforeOffloading)
			[self clearCache];
	}
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
		self.outputStreamPath = MvrUnusedTemporaryFileNameWithPathExtension(desiredExtension?: @"");
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
		thePath = MvrUnusedTemporaryFileNameWithPathExtension(desiredExtension?: @"");
	
	NSError* e;
	BOOL done = [data writeToFile:thePath options:NSAtomicWrite error:&e];
	if (!done)
		[NSException raise:@"MvrStorageException" format:@"Could not clear cache for this storage item: %@ (error: %@)", self ,e];
	
	if (!path)
		self.path = thePath;
	
	[data release]; data = nil;
}

- (void) invalidate;
{
	BOOL canInvalidate = NO;
	
#if TARGET_OS_MAC && !TARGET_OS_IPHONE
	canInvalidate = ([NSClassFromString(@"NSGarbageCollector") performSelector:@selector(defaultCollector)] != nil);
#endif
	
	NSAssert(canInvalidate, @"This method can only be called from a garbage-collected environment!");
	[self resetDataByDeletingOffloadFile:YES];
}

- (void) resetDataByDeletingOffloadFile:(BOOL) delete;
{
	NSAssert(!persistent, @"Persistent item storage cannot be altered. Remove the item from the storage central first.");
	
	if (path) {
		if (delete)
			[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
		self.path = nil;
	}
	
	if (data) {
		[data release]; data = [NSData new];
	}
}

#pragma mark Path stuff.

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
	
	NSString* storageDir = [self.path stringByDeletingLastPathComponent];
	NSString* newPath = nil;
	if (self.hasPath)
		newPath = [[self.path stringByDeletingPathExtension] stringByAppendingPathExtension:ext];
	
	if (!newPath || [[NSFileManager defaultManager] fileExistsAtPath:newPath])
		newPath = MvrUnusedPathInDirectoryWithExtension(storageDir, ext, NULL);
	
	BOOL done = [[NSFileManager defaultManager] moveItemAtPath:self.path toPath:newPath error:e];
	if (done)
		self.path = newPath;
	
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

- (BOOL) setDesiredExtension:(NSString*) ext error:(NSError**) e;
{
	if (self.hasPath)
		return [self setPathExtension:ext error:e];
	else {
		if (desiredExtension != ext) {
			[desiredExtension release];
			desiredExtension = [ext copy];
		}
		
		return YES;
	}
}

- (BOOL) setDesiredExtensionAssumingType:(id) uti error:(NSError**) e;
{
	if (self.hasPath)
		return [self setPathExtensionAssumingType:uti error:e];
	else {
		CFStringRef ext = UTTypeCopyPreferredTagWithClass((CFStringRef) uti, kUTTagClassFilenameExtension);
		
		if (!ext) {
			if (e) *e = [NSError errorWithDomain:kMvrItemStorageErrorDomain code:kMvrItemStorageNoFilenameExtensionForTypeError userInfo:nil];
			return NO;
		}
		
		if (desiredExtension != (id) ext) {
			[desiredExtension release];
			desiredExtension = [(id)ext copy];
		}
		
		CFRelease(ext);
		return YES;	
	}
}

- (BOOL) makePersistentByOffloadingToPath:(NSString*) p error:(NSError**) e;
{
	if (self.persistent) {
		L0Log(@"Already persistent!");
		if (e) *e = [NSError errorWithDomain:kMvrItemStorageErrorDomain code:kMvrItemStorageAlreadyPersistentError userInfo:nil];
		return NO;
	}
	
	NSError* localError;
	if (data && !path) {
		if (![data writeToFile:p options:NSAtomicWrite error:&localError]) {
			L0Log(@"Could not offload from RAM to %@, error %@", p, localError);
			if (e) *e = localError;
			return NO;
		}
	} else if (![p isEqual:path]) {
		if (![[NSFileManager defaultManager] moveItemAtPath:path toPath:p error:&localError]) {			
			L0Log(@"Could not offload by moving %@ to %@, error %@", path, p, localError);
			if (e) *e = localError;
			return NO;
		}
	}

	[data release]; data = nil;
	self.path = p;
	self.persistent = YES;
	return YES;
}

- (void) stopBeingPersistent;
{
	if (self.persistent) {
		self.persistent = NO;
		[self resetDataByDeletingOffloadFile:NO];
	}
}

#pragma mark Debugging aids

- (NSString*) description;
{
	return [NSString stringWithFormat:@"%@ { path = '%@', data = %@, pending output stream = %@, persistent? = %d }", [super description], path, data? @"not nil" : @"nil", lastOutputStream, persistent];
}

@end
