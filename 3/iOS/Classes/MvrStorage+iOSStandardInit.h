//
//  MvrStorage+iOSStandardInit.h
//  Mover3
//
//  Created by ∞ on 18/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrStorage.h"

extern BOOL MvrIsDirectory(NSString* path);

@interface MvrStorage (MvrOSStandardInit)

+ (NSString*) defaultItemsDirectory;
+ (NSString *) defaultMetadataDirectory;

+ iOSStorage;
- (void) migrateFrom30StorageInUserDefaultsIfNeeded;

@end
