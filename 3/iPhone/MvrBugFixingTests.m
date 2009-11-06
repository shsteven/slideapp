//
//  MvrBugFixingTests.m
//  Mover3
//
//  Created by ∞ on 06/11/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrBugFixingTests.h"

#import "MvrBookmarkItem.h"

// Tests are suffixed with the commit or commits that describe the bug and the initial fix we're testing.

@implementation MvrBugFixingTests

// fba0098: an invalid (stored?) sequence of characters causes a nil assert crash when we try to produce a URL out of it in -objectForEmptyAddressCacheKey. Fixed by producing a nil address (which the generic constructor flags as invalid, causing self-releasing; we're assuming here there's no bug anywhere related to returning nil from that constructor, because it's part of its contract).
- (void) testInvalidStoredAddressTriggeringCrashInBookmarkItemCache_fba0098;
{
	uint8_t notUTF8[] = { 0xC0, 0x80 };
	NSData* notUTF8Data = [NSData dataWithBytes:notUTF8 length:2];
	
	MvrItemStorage* storage = [MvrItemStorage itemStorageWithData:notUTF8Data];
	NSDictionary* someMetadata = [NSDictionary dictionaryWithObject:@"Some title" forKey:kMvrItemTitleMetadataKey];
	
	// Crash would happen here if it does.
	MvrBookmarkItem* bookmarkItem = [[MvrBookmarkItem alloc] initWithStorage:storage type:(id) kUTTypeURL metadata:someMetadata];
	STAssertNil(bookmarkItem, @"The bookmark item found out about the invalid storage and returned nil.");
	[bookmarkItem release];
}

@end
