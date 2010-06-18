//
//  MvrStorage.m
//  Mover3-iPad
//
//  Created by ∞ on 08/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrStorage.h"

#define kMvrStorageMetadataFileExtension @"mover-item"

#define kMvrStorageMetadataFilenameKey @"MvrFilename"
#define kMvrStorageMetadadaTypeKey @"MvrType"
#define kMvrStorageMetadataItemInfoKey @"MvrMetadata"
#define kMvrStorageNotesItemInfoKey @"MvrNotes"

#define kMvrStorageCorrespondingMetadataFileNameItemNoteKey @"MvrMetadataFileName"

#import "Network+Storage/MvrItemStorage.h"

#import <MuiKit/MuiKit.h>

@interface MvrStorage ()

- (void) processMetadataFile:(NSString *)itemMetaPath;
- (void) makeMetadataFileForItem:(MvrItem*) i;
- (NSString*) userVisibleFilenameForItem:(MvrItem*) i;

@property(readonly) NSMutableSet* mutableStoredItems;

@end


@implementation MvrStorage

- (id) initWithItemsDirectory:(NSString*) i metadataDirectory:(NSString*) m;
{
	if (self = [super init]) {
		itemsDirectory = [i copy];
		metadataDirectory = [m copy];
		knownFiles = [NSMutableSet new];
	}
	
	return self;
}

@synthesize itemsDirectory, metadataDirectory;

- (void) dealloc
{
	[storedItemsSet release];
	[itemsDirectory release];
	[metadataDirectory release];
	[knownFiles release];
	[super dealloc];
}

- (NSSet*) storedItems;
{
	return [[self.mutableStoredItems copy] autorelease];
}

- (NSMutableSet*) mutableStoredItems;
{
	if (!storedItemsSet) {
		storedItemsSet = [NSMutableSet new];
		
		
		for (NSString* filename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:metadataDirectory error:NULL]) {
			
			if (![[filename pathExtension] isEqual:kMvrStorageMetadataFileExtension])
				continue;
			
			NSString* fullPath = [metadataDirectory stringByAppendingPathComponent:filename];
			[self processMetadataFile:fullPath];
		}
		
	}
	
	return storedItemsSet;
}

- (void) processMetadataFile:(NSString*) itemMetaPath;
{
	NSDictionary* itemMeta = [NSDictionary dictionaryWithContentsOfFile:itemMetaPath];
	if (!itemMeta)
		return;

	NSString* filename = [itemMeta objectForKey:kMvrStorageMetadataFilenameKey];
	if ([knownFiles containsObject:filename]) {
		[[NSFileManager defaultManager] removeItemAtPath:itemMetaPath error:NULL];
		return;
	}
	
	NSString* fullPath = [itemsDirectory stringByAppendingPathComponent:filename];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:fullPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:itemMetaPath error:NULL];
		return;
	}
	
	id meta = L0As(NSDictionary, [itemMeta objectForKey:kMvrStorageMetadataItemInfoKey]);
	if (!meta)
		return;
	
	NSString* type = L0As(NSString, [itemMeta objectForKey:kMvrStorageMetadadaTypeKey]);
	if (!type)
		return;
	
	MvrItemStorage* s = [MvrItemStorage itemStorageFromFileAtPath:fullPath options:kMvrItemStorageIsPersistent error:NULL];
	if (!s)
		return;
		
	MvrItem* i = [MvrItem itemWithStorage:s type:type metadata:meta];
	if (!i)
		return;
	
	[i setItemNotes:L0As(NSDictionary, [itemMeta objectForKey:kMvrStorageNotesItemInfoKey])];
	
	[knownFiles addObject:filename];
	[self.mutableStoredItems addObject:i];
}

- (void) addStoredItemsObject:(MvrItem*) i;
{
	if ([storedItemsSet containsObject:i])
		return;
	
	NSAssert(!i.storage.persistent, @"This object is already persistent and cannot be managed by this storage central.");
	
	NSString* filename = [self userVisibleFilenameForItem:i];
	
	NSString* path = [itemsDirectory stringByAppendingPathComponent:filename];
	NSError* e;
	BOOL done = [i.storage makePersistentByOffloadingToPath:path error:&e];
	if (!done)
		L0Log(@"Error while making the thing persistent: %@", e);
	
	NSAssert(done, @"Can't make this item persistent. Why?");

	[knownFiles addObject:[path lastPathComponent]];
	[self makeMetadataFileForItem:i];
	[self.mutableStoredItems addObject:i];
}

- (void) adoptPersistentItem:(MvrItem*) i;
{
	if ([storedItemsSet containsObject:i])
		return;
	
	NSAssert(i.storage.persistent, @"To adopt, the item must already be persistent on its own.");
	
	BOOL sameDir = i.storage.hasPath && [self isPathInItemsDirectory:i.storage.path];
	NSAssert(sameDir, @"To adopt, the item's storage must have been offloaded to the items directory.");
	
	[knownFiles addObject:[i.storage.path lastPathComponent]];
	[self makeMetadataFileForItem:i];
	[self.mutableStoredItems addObject:i];
}

- (void) makeMetadataFileForItem:(MvrItem*) i;
{
	NSAssert(i.storage.persistent && i.storage.hasPath && i.storage.path, @"The item must be saved to persistent storage before metadata can be written");
	
	
	NSString* name, * path;
	do {
		name = [NSString stringWithFormat:@"%@.%@", [[L0UUID UUID] stringValue], kMvrStorageMetadataFileExtension];
		
		path = [metadataDirectory stringByAppendingPathComponent:name];
	} while ([[NSFileManager defaultManager] fileExistsAtPath:path]);
	

	[i setObject:name forItemNotesKey:kMvrStorageCorrespondingMetadataFileNameItemNoteKey];
	
	NSMutableDictionary* itemMeta = [NSMutableDictionary dictionary];
	[itemMeta setObject:[i.storage.path lastPathComponent] forKey:kMvrStorageMetadataFilenameKey];
	[itemMeta setObject:i.type forKey:kMvrStorageMetadadaTypeKey];
	[itemMeta setObject:(i.metadata?: [NSDictionary dictionary]) forKey:kMvrStorageMetadataItemInfoKey];
	[itemMeta setObject:[i itemNotes] forKey:kMvrStorageNotesItemInfoKey];
	
	[itemMeta writeToFile:path atomically:YES];
}

- (NSString*) userVisibleFilenameForItem:(MvrItem*) i;
{
	// step one: does this have a filename? return it then.
	NSString* filename = [i.metadata objectForKey:kMvrItemOriginalFilenameMetadataKey];
	
	if (!filename) {
		NSString* ext = nil;
		
		// step one-bis: if the item already has an extension, use that.
		if (i.storage.hasPath) {
			ext = [i.storage.path pathExtension];
			if ([ext isEqual:@""])
				ext = nil;
		}
		
		// step one-ter: we need to know this file's extension (ick). We'll query the OS (and probably ship with a ton of UTImported types to match).
		
		if (!ext)
			ext = [(id)UTTypeCopyPreferredTagWithClass((CFStringRef) i.type, kUTTagClassFilenameExtension) autorelease];
		
		// step one-quater: see if we know a fallback extension for this type.
		
		if (!ext)
			ext = [MvrItem fallbackPathExtensionForType:i.type];
		
		if (!ext) {
			// if we don't know what type of file this is, we hide the file from view.
			
			ext = @"";
			filename = [NSString stringWithFormat:@".%@", [[L0UUID UUID] stringValue]];
		}
		
		if (!filename) {
		
			// step two: do we know where it's from? then we use "From %@.xxx".
			// TODO see if this sanitation is sufficient.
			NSString* whereFrom = [[i objectForItemNotesKey:kMvrItemWhereFromNoteKey] stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
			if (whereFrom)
				filename = [NSString stringWithFormat:NSLocalizedString(@"From %@.%@", @"Format for file name as in 'from DEVICE'."), whereFrom, ext];
			else
				filename = [NSString stringWithFormat:NSLocalizedString(@"Item.%@", @"Generic item filename"), ext];
			
		}
	}
	
	NSAssert(filename, @"We have found a name for this file.");
	
	int attempt = 1;
	NSString* actualName, * basename = nil, * ext = nil;
	
	do {
		
		if (attempt == 1)
			actualName = filename;
		else {
			if (!basename)
				basename = [filename stringByDeletingPathExtension];
			if (!ext)
				ext = [filename pathExtension];
			
			actualName = [NSString stringWithFormat:@"%@ (%d).%@", basename, attempt, ext];
		}
		
		attempt++;
		
	} while ([[NSFileManager defaultManager] fileExistsAtPath:[itemsDirectory stringByAppendingPathComponent:actualName]]);
	
	return actualName;
}

- (void) removeStoredItemsObject:(MvrItem*) i;
{
	if (![storedItemsSet containsObject:i])
		return;
	
	NSAssert(i.storage.persistent, @"This object isn't persistent -- something disabled persistency behind the back of this storage central");
	
	// two-step!
	// one: gather files
	
	NSMutableSet* filesToDelete = [NSMutableSet set];
	NSString* itemFile = [[i.storage.path copy] autorelease];
	[filesToDelete addObject:itemFile];
	
	NSString* metadataFileName = [i objectForItemNotesKey:kMvrStorageCorrespondingMetadataFileNameItemNoteKey];
	if (metadataFileName) {
		// we're gonna double-check that this metadata file actually corresponds to the item before deleting it.
		
		NSString* metadataFilePath = [metadataDirectory stringByAppendingPathComponent:metadataFileName];
		
		if ([[[NSDictionary dictionaryWithContentsOfFile:metadataFilePath] objectForKey:kMvrStorageMetadataFilenameKey] isEqual:[i.storage.path lastPathComponent]])
			[filesToDelete addObject:metadataFilePath];
	}
	
	// two: invalidate the storage and kill the item and delete the files.
	
	[i.storage stopBeingPersistent];
	[storedItemsSet removeObject:i];
	
	for (NSString* file in filesToDelete)
		[[NSFileManager defaultManager] removeItemAtPath:file error:NULL];
	
	[knownFiles removeObject:[itemFile lastPathComponent]];
}

- (void) migrateFrom30StorageCentralMetadata:(id) meta;
{
#warning TODO
	L0AbstractMethod();
}

- (BOOL) hasItemForFileAtPath:(NSString*) path;
{
	if (![self isPathInItemsDirectory:path])
		return NO;
	
	return [knownFiles containsObject:[path lastPathComponent]];
}

- (BOOL) isPathInItemsDirectory:(NSString*) path;
{
	return ([[[path stringByDeletingLastPathComponent] stringByStandardizingPath] isEqual:[itemsDirectory stringByStandardizingPath]]);
}

@end
