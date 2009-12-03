//
//  MvrBugFixingTests.m
//  Mover3
//
//  Created by ∞ on 06/11/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrBugFixingTests.h"

#import "MvrBookmarkItem.h"
#import "MvrContactItem.h"
#import "Network+Storage/MvrGenericItem.h"

#import <AddressBook/AddressBook.h>

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

// Long-standing, masqued-by-transition bug: NULL labels in contacts trip us up (assertion crash).
// 7e6c58a has the fix, but note that it does not impact decoding code that we test here -- the code we run here is the same one we ship since 3.0. We only test decoding because AB can *store* items with NULL labels but not *produce* them, so we cannot test by introducing faulty values into the encoding code. Still, this allows us to test with an input equal to that produced by MvrContactItem.
- (void) testNullLabelInContactItemDecoding_7e6c58a;
{
	// make a person plist with a NULL label.
	
	ABAddressBookRef ab = ABAddressBookCreate();
	CFRelease(ab); // inits AB.framework
	
	NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"John", [NSString stringWithFormat:@"%d", kABPersonFirstNameProperty],
					   @"Doe", [NSString stringWithFormat:@"%d", kABPersonLastNameProperty],
					   [NSArray arrayWithObject:
						[NSDictionary dictionaryWithObjectsAndKeys:
						 @"john@doe.net", kMvrContactMultiValueItemValue,
						 @"-", kMvrContactMultiValueItemLabel,
						 nil]
						], [NSString stringWithFormat:@"%d", kABPersonEmailProperty],
					   nil];
	NSDictionary* personDictionary = [NSDictionary dictionaryWithObject:d forKey:kMvrContactProperties];
	
	NSString* errorString = nil;
	
	NSData* plistData = [NSPropertyListSerialization dataFromPropertyList:personDictionary format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
	
	STAssertNotNil(plistData, @"Plist data was nonnull. (error = %@)", plistData? nil : errorString);
	
	// make a contact item out of it.
	
	MvrItemStorage* receivedStorage = [MvrItemStorage itemStorageWithData:plistData];
	MvrContactItem* received = [[[MvrContactItem alloc] initWithStorage:receivedStorage type:kMvrContactAsPropertyListType metadata:[NSDictionary dictionaryWithObject:@"John D." forKey:kMvrItemTitleMetadataKey]] autorelease];
	
	STAssertNotNil(received, @"We should have received an item!");
	STAssertFalse([[received class] isEqual:[MvrGenericItem class]], @"We should have gotten a real item, not a generic fallback");
	
	ABRecordRef person = [received copyPersonRecord];
	STAssertNotNil((id) person, @"AB should have been able to create a person record!");
	
	ABMultiValueRef ref = ABRecordCopyValue(person, kABPersonEmailProperty);
	STAssertNotNil((id) ref, @"AB should have been able to create a multivalue for the e-mails!");
	STAssertTrue(ABMultiValueGetCount(ref) == 1, @"AB should have been able to make only one e-mail out of the plist!");
	
	id v = (id) ABMultiValueCopyValueAtIndex(ref, 0);
	id l = (id) ABMultiValueCopyLabelAtIndex(ref, 0);
	
	STAssertEqualObjects(v, @"john@doe.net", @"Value should have been preserved");
	STAssertEqualObjects(l, @"-", @"Label should have been preserved");
	
	[v release];
	[l release];
	CFRelease(ref);
	CFRelease(person);
}

@end
