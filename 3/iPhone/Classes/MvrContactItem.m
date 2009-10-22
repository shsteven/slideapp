//
//  MvrContactItem.m
//  Mover3
//
//  Created by ∞ on 02/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrContactItem.h"

#import "Network+Storage/MvrItemStorage.h"

static void MvrEnsureABFrameworkIsLoaded() {
	static BOOL initialized = NO; if (!initialized) {
		ABAddressBookRef ab = ABAddressBookCreate();
		CFRelease(ab);
		// this causes constants to have the right value and such.
	}
}

// We use this to iterate among known AB properties.
#define kMvrCountOfABProperties (23) // sizeof(properties) / sizeof(ABPropertyID);

static ABPropertyID MvrGetABPropertyAtIndex(int idx) {
	static ABPropertyID L0AddressBookProperties[kMvrCountOfABProperties];
	static BOOL initialized = NO;
	
	if (!initialized) {
		MvrEnsureABFrameworkIsLoaded();
		
		ABPropertyID properties[] = {
			kABPersonFirstNameProperty,
			kABPersonLastNameProperty,
			kABPersonMiddleNameProperty,
			kABPersonPrefixProperty,
			kABPersonSuffixProperty,
			kABPersonNicknameProperty,
			kABPersonFirstNamePhoneticProperty,
			kABPersonLastNamePhoneticProperty,
			kABPersonMiddleNamePhoneticProperty,
			kABPersonOrganizationProperty,
			kABPersonJobTitleProperty,
			kABPersonDepartmentProperty,
			kABPersonEmailProperty,
			kABPersonBirthdayProperty,
			kABPersonNoteProperty,
			kABPersonCreationDateProperty,
			kABPersonModificationDateProperty,
			kABPersonAddressProperty,
			kABPersonDateProperty,
			kABPersonKindProperty,
			kABPersonPhoneProperty,
			kABPersonInstantMessageProperty,
			kABPersonURLProperty,
			kABPersonRelatedNamesProperty
		};
		
		L0CLog(@"kABPersonLastNameProperty == %d at %p", kABPersonLastNameProperty, &kABPersonLastNameProperty);
		
		int i; for (i = 0; i < kMvrCountOfABProperties; i++)
			L0AddressBookProperties[i] = properties[i];
		
		initialized = YES;
	}
	
	return L0AddressBookProperties[idx];
}

static id MvrKeyForABProperty(ABPropertyID prop) {
	return [NSString stringWithFormat:@"%d", prop];
}

#pragma mark -
#pragma mark The item itself.

@interface MvrContactItem ()

@property(copy) NSDictionary* contactPropertyList;

- (NSDictionary*) propertyListFromAddressBookRecord:(ABRecordRef) record;

- (NSString*) shortenedNameFromAddressBookRecord:(ABRecordRef) record;
- (NSString*) shortenedNameFromContactPropertyList;
- (NSString*) shortenedNameFromNickname:(NSString*) nickname name:(NSString*) name surname:(NSString*) surname companyName:(NSString*) companyName;

- (ABRecordRef) copyPersonRecordFromPropertyList:(NSDictionary*) personInfoDictionary;

@end


@implementation MvrContactItem

+ supportedTypes;
{
	// one day we'll also have kUTTypeVCard in here, but not now.
	return [NSSet setWithObject:kMvrContactAsPropertyListType];
}

- (id) initWithContentsOfAddressBookRecord:(ABRecordRef) ref;
{
	if (self = [super init]) {
		MvrEnsureABFrameworkIsLoaded();
		
		self.contactPropertyList = [self propertyListFromAddressBookRecord:ref];
		self.type = kMvrContactAsPropertyListType;
		[self.metadata setDictionary:[self defaultMetadata]];
		
		[self setObject:[NSNumber numberWithBool:YES] forItemNotesKey:kMvrContactWasSaved];
	}
	
	return self;
}

- (NSDictionary*) defaultMetadata;
{
	NSString* title = [self shortenedNameFromContactPropertyList];
	return [NSDictionary dictionaryWithObject:title forKey:kMvrItemTitleMetadataKey];
}

#pragma mark -
#pragma mark Name shortening

- (NSString*) shortenedNameFromAddressBookRecord:(ABRecordRef) record;
{
	NSString* nickname = [NSMakeCollectable(ABRecordCopyValue(record, kABPersonNicknameProperty)) autorelease];
	NSString* name = [NSMakeCollectable(ABRecordCopyValue(record, kABPersonFirstNameProperty)) autorelease];
	NSString* surname = [NSMakeCollectable(ABRecordCopyValue(record, kABPersonLastNameProperty)) autorelease];
	NSString* companyName = [NSMakeCollectable(ABRecordCopyValue(record, kABPersonOrganizationProperty)) autorelease];
	
	return [self shortenedNameFromNickname:nickname name:name surname:surname companyName:companyName];
}

- (NSString*) shortenedNameFromContactPropertyList;
{
	NSDictionary* props = [self.contactPropertyList objectForKey:kMvrContactProperties];
	
	NSString* nickname = [props objectForKey:MvrKeyForABProperty(kABPersonNicknameProperty)];
	NSString* name = [props objectForKey:MvrKeyForABProperty(kABPersonFirstNameProperty)];
	NSString* surname = [props objectForKey:MvrKeyForABProperty(kABPersonLastNameProperty)];
	NSString* companyName = [props objectForKey:MvrKeyForABProperty(kABPersonOrganizationProperty)];
	
	return [self shortenedNameFromNickname:nickname name:name surname:surname companyName:companyName];
}

- (NSString*) shortenedNameFromNickname:(NSString*) nickname name:(NSString*) name surname:(NSString*) surname companyName:(NSString*) companyName;
{	
	if (nickname)
		return nickname;
	
	if (!name && !surname) {
		if (companyName)
			return companyName;
		else
			return @"?";
	}
	
	// should we shorten at all?
	// This includes all latin letters but not IPA extensions, spacing modifiers
	// and combining diacriticals.
	NSCharacterSet* latinLetters = [NSCharacterSet characterSetWithRange:NSMakeRange(0, 0x250)];
	NSCharacterSet* notLatinLetters = [latinLetters invertedSet];
	
	BOOL shouldShorten = (!name || [name rangeOfCharacterFromSet:notLatinLetters].location == NSNotFound) && (!surname || [surname rangeOfCharacterFromSet:notLatinLetters].location == NSNotFound);
	
	if (!shouldShorten) {
		if (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst) {
			if (!name && surname)
				return surname;
			else if (!surname && name)
				return name;
			else
				return [NSString stringWithFormat:@"%@ %@", name, surname];
		} else {
			if (!surname && name)
				return name;
			else if (!name && surname)
				return surname;
			else
				return [NSString stringWithFormat:@"%@ %@", surname, name];
		}
	}
	
	// shortening!
	if (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst) {
		// "Emanuele V."		
		if (!name && surname)
			return surname;
		else if (!surname && name)
			return name;
		else {
			surname = [surname substringToIndex:1];
			return [NSString stringWithFormat:@"%@ %@.", name, surname];
		}
	} else {
		// "Vulcano, E."
		if (!name && surname)
			return surname;
		else if (!surname && name)
			return name;
		else {
			name = [name substringToIndex:1];
			return [NSString stringWithFormat:@"%@, %@.", surname, name];
		}
	}
}


#pragma mark -
#pragma mark To and from property lists.

#define MvrIsABMultiValueType(propertyType) (( (propertyType) & kABMultiValueMask ) != 0)

- (NSDictionary*) propertyListFromAddressBookRecord:(ABRecordRef) record;
{
	NSMutableDictionary* info = [NSMutableDictionary dictionary];
	
	int i; for (i = 0; i < kMvrCountOfABProperties; i++) {
		ABPropertyID propertyID = MvrGetABPropertyAtIndex(i);
		
		ABPropertyType t = ABPersonGetTypeOfProperty(propertyID);
		if (!MvrIsABMultiValueType(t)) {
			// we simply lift the value from the record -- since
			// all nonmulti are, or should be, property list types, that's fine.
			
			id value = (id) ABRecordCopyValue(record, propertyID);
			if (value)
				[info setObject:value forKey:MvrKeyForABProperty(propertyID)];
			
			[value release];
		} else {
			// multis are transformed into arrays of dictionaries.
			// (this is fine because NSArray is not one of the types
			// used by the AB framework).
			
			NSMutableArray* multiTransposed = [NSMutableArray array];
			ABMultiValueRef multi = ABRecordCopyValue(record, propertyID);
			
			NSArray* values = (NSArray*) ABMultiValueCopyArrayOfAllValues(multi);
			int valueIndex = 0;
			for (id value in values) {
				id label = (id) ABMultiValueCopyLabelAtIndex(multi, valueIndex);
				if (!label) label = [[NSNull null] retain]; // balances the release below
				NSDictionary* item = [NSDictionary dictionaryWithObjectsAndKeys:
									  value, kMvrContactMultiValueItemValue,
									  label, kMvrContactMultiValueItemLabel,
									  nil];
				[multiTransposed addObject:item];
				[label release];
				valueIndex++;
			}
			[values release];
			
			[info setObject:multiTransposed forKey:MvrKeyForABProperty(propertyID)];
			CFRelease(multi);
		}
	}
	
	NSMutableDictionary* person = [NSMutableDictionary dictionary];
	[person setObject:info forKey:kMvrContactProperties];
	
	if (ABPersonHasImageData(record)) {
		NSData* data = (NSData*) ABPersonCopyImageData(record);
		[person setObject:data forKey:kMvrContactImageData];
		[data release];
	}
	
	return person;
}

- (ABRecordRef) copyPersonRecord;
{
	return [self copyPersonRecordFromPropertyList:self.contactPropertyList];
}

- (ABRecordRef) copyPersonRecordFromPropertyList:(NSDictionary*) personInfoDictionary;
{
	NSDictionary* info = [personInfoDictionary objectForKey:kMvrContactProperties];
	NSAssert(info, @"We must have the person info in order to store in the address book.");
	
	ABRecordRef person = ABPersonCreate();
	
	for (NSString* propertyIDString in info) {
		ABPropertyID propertyID = [propertyIDString intValue];
		id value = [info objectForKey:propertyIDString];
		
		CFTypeRef setValue;
		BOOL shouldReleaseSetValue = NO;
		if (![value isKindOfClass:[NSArray class]]) 
			setValue = (CFTypeRef) value;
		else {
			ABPropertyType propertyType = ABPersonGetTypeOfProperty(propertyID);
			ABMultiValueRef multi = ABMultiValueCreateMutable(propertyType);
			
			for (NSDictionary* valuePart in value) {
				id multiValue = [valuePart objectForKey:kMvrContactMultiValueItemValue];
				id label = [valuePart objectForKey:kMvrContactMultiValueItemLabel];
				
				ABMultiValueAddValueAndLabel(multi, (CFTypeRef) multiValue, (CFStringRef) label, NULL);
			}
			
			setValue = (CFTypeRef) multi;
			shouldReleaseSetValue = YES;
		}
		
		CFErrorRef error = NULL;
		ABRecordSetValue(person, propertyID, setValue, &error);
		
		if (error) {
			NSLog(@"%@", (id) error);
			CFRelease(error);
		}
		
		if (shouldReleaseSetValue)
			CFRelease(setValue);
	}
	
	NSData* imageData;
	if (imageData = [personInfoDictionary objectForKey:kMvrContactImageData]) {
		CFErrorRef error = NULL;
		
		ABPersonSetImageData(person, (CFDataRef) imageData, &error);
		
		if (error) {
			NSLog(@"%@", (id) error);
			CFRelease(error);
		}
	}
	
	return person;
}

- (NSDictionary*) contactPropertyList;
{
	return [self cachedObjectForKey:@"contactPropertyList"];
}

- (void) setContactPropertyList:(NSDictionary*) d;
{
	[self setCachedObject:[[d copy] autorelease] forKey:@"contactPropertyList"];
}

- (NSDictionary*) objectForEmptyContactPropertyListCacheKey;
{
	NSString* error = nil;
	
	NSDictionary* info = [NSPropertyListSerialization propertyListFromData:self.storage.data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&error];
	
	if (error) {
		NSLog(@"An error occurred while deserializing an address book contact: %@", error);
		[error release]; error = nil;
	}
	
	return info;
}

- (NSData*) produceExternalRepresentation;
{
	NSString* errorString = nil;
	
	NSData* plistData = [NSPropertyListSerialization dataFromPropertyList:self.contactPropertyList format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
	
	if (!plistData) {
		[NSException raise:@"MvrContactItemCannotProducePlistException" format:@"Had an error while serializing a contact plist into data. NSDictionary was %@ -- error was %@", self.contactPropertyList, [errorString autorelease]];
		return nil;
	}
	
	return plistData;
}

- (NSString*) nameAndSurnameForSearching;
{
	NSDictionary* props = [self.contactPropertyList objectForKey:kMvrContactProperties];
	
	NSString* name = [props objectForKey:MvrKeyForABProperty(kABPersonFirstNameProperty)];					  
	NSString* surname = [props objectForKey:MvrKeyForABProperty(kABPersonLastNameProperty)];
	NSString* companyName = [props objectForKey:MvrKeyForABProperty(kABPersonOrganizationProperty)];
	
	if (!name && !surname)
		return companyName;
	
	if (!name && surname)
		return surname;
	
	if (!surname && name)
		return name;
	
	NSString* result;
	if (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst)
		result = [NSString stringWithFormat:@"%@ %@", name, surname];
	else
		result = [NSString stringWithFormat:@"%@ %@", surname, name];
	
	return result;
}

@end
