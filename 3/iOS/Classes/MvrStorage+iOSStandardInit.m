//
//  MvrStorage+iOSStandardInit.m
//  Mover3
//
//  Created by ∞ on 18/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrStorage+iOSStandardInit.h"

BOOL MvrIsDirectory(NSString* path) {
	BOOL exists, isDir;
	exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
	return exists && isDir;
}

#define kMvrItemsMetadataUserDefaultsKey @"L0SlidePersistedItems"

@implementation MvrStorage (MvriOSStandardInit)

+ (NSString*) defaultItemsDirectory;
{
	NSArray* docsDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSAssert([docsDirs count] > 0, @"At least one documents directory is known");
			
	NSString* docsDir = [docsDirs objectAtIndex:0];
			
#if kMvrVariantSettings_UseSubdirectoryForItemStorage
	docsDir = [docsDir stringByAppendingPathComponent:@"Mover Items"];
#endif
	
	return docsDir;
}

+ (NSString*) defaultMetadataDirectory;
{
	NSString* metaDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	metaDir = [metaDir stringByAppendingPathComponent:@"Mover Metadata"];

	return metaDir;
}

+ iOSStorage;
{
// TODO support Open /Mover Items subdirectory
	NSString* docsDir = [self defaultItemsDirectory];
	NSString* metaDir = [self defaultMetadataDirectory];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	
	if (![fm fileExistsAtPath:docsDir])
		ILAssertNoNSError(e, [fm createDirectoryAtPath:docsDir withIntermediateDirectories:YES attributes:nil error:&e]);
	
	if (![fm fileExistsAtPath:metaDir])
		ILAssertNoNSError(e, [fm createDirectoryAtPath:metaDir withIntermediateDirectories:YES attributes:nil error:&e]);
	
	return [[[self alloc] initWithItemsDirectory:docsDir metadataDirectory:metaDir] autorelease];
}

- (void) migrateFrom30StorageInUserDefaultsIfNeeded;
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id meta = [ud objectForKey:kMvrItemsMetadataUserDefaultsKey];
	if (meta) {
		[self migrateFrom30StorageCentralMetadata:meta];
		[ud removeObjectForKey:kMvrItemsMetadataUserDefaultsKey];
	}
}	

@end
