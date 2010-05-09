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

#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrItem.h"

@interface MvrStorage ()

- (void) addItemWithMetadataFile:(NSString *)itemMetaPath;

@end


@implementation MvrStorage

- (id) initWithItemsDirectory:(NSString*) i metadataDirectory:(NSString*) m;
{
	if (self = [super init]) {
		itemsDirectory = [i copy];
		metadataDirectory = [m copy];
	}
	
	return self;
}

- (void) dealloc
{
	[allStoredItems release];
	[itemsDirectory release];
	[metadataDirectory release];
	[super dealloc];
}

- (NSMutableSet *) storedItems;
{
	return [self mutableSetValueForKey:@"allStoredItems"];
}

- (NSSet*) allStoredItems;
{
	if (!allStoredItems) {
		allStoredItems = [NSMutableSet new];
		
		
		for (NSString* filename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:metadataDirectory error:NULL]) {
			
			if (![[filename pathExtension] isEqual:kMvrStorageMetadataFileExtension])
				continue;
			
			NSString* fullPath = [metadataDirectory stringByAppendingPathComponent:filename];
			[self addItemWithMetadataFile:fullPath];
		}
		
	}
	
	return [[allStoredItems copy] autorelease];
}

- (void) addItemWithMetadataFile:(NSString*) itemMetaPath;
{
	NSDictionary* itemMeta = [NSDictionary dictionaryWithContentsOfFile:itemMetaPath];
	if (!itemMeta)
		return;

	NSString* filename = [itemMeta objectForKey:kMvrStorageMetadataFilenameKey];
	
	NSString* fullPath = [itemsDirectory stringByAppendingPathComponent:filename];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:fullPath])
		return;
	
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
	
	[allStoredItems addObject:i];
}

- (void) addStoredItemsObject:(MvrItem*) i;
{
#warning TODO
	L0AbstractMethod();
}

- (void) removeStoredItemsObject:(MvrItem*) i;
{
#warning TODO
	L0AbstractMethod();
}

- (void) migrateFrom30StorageCentralMetadata:(id) meta;
{
#warning TODO
	L0AbstractMethod();
}

@end
