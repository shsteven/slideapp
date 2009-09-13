//
//  MvrItemStorageTests.m
//  Network+Storage
//
//  Created by ∞ on 13/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrStorageDirectoryTests.h"


@implementation MvrStorageDirectoryTests

- (void) setUp;
{
	MvrStorageSetTemporaryDirectory(nil);
	MvrStorageSetPersistentDirectory(nil);
}

- (void) testTemporaryDirectoryDefaultIsNSTemp;
{
	STAssertEqualObjects(MvrStorageTemporaryDirectory(), NSTemporaryDirectory(), nil);
}

- (void) testTemporaryDirectoryIsSetOnceSet;
{
	NSString* const root = @"/";
	MvrStorageSetTemporaryDirectory(root);
	STAssertEqualObjects(MvrStorageTemporaryDirectory(), root, nil);
}

- (void) testPersistentDirectoryDefaultRaisesException;
{
	STAssertThrows(MvrStoragePersistentDirectory(), nil);
}

- (void) testPersistentDirectoryIsSetOnceSet;
{
	NSString* const root = @"/";
	MvrStorageSetPersistentDirectory(root);
	STAssertEqualObjects(MvrStoragePersistentDirectory(), root, nil);
}

@end
