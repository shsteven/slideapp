//
//  MvrContactItem.h
//  Mover3
//
//  Created by ∞ on 02/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

#import "Network+Storage/MvrItem.h"

// The UTI of a contact item. Yep, it has 'Slide' in it. Relic of happier times.
#define kMvrContactAsPropertyListType @"net.infinite-labs.Slide.AddressBookPersonPropertyList"

// These constants are used in the plist we wrap person records into.
#define kMvrContactMultiValueItemValue @"L0AddressBookValue"
#define kMvrContactMultiValueItemLabel @"L0AddressBookLabel"

#define kMvrContactProperties @"L0AddressBookPersonInfoProperties"
#define kMvrContactImageData @"L0AddressBookPersonInfoImageData"

@interface MvrContactItem : MvrItem {
	NSDictionary* contactPropertyList;
}

- (id) initWithContentsOfAddressBookRecord:(ABRecordRef) ref;

@property(readonly, copy) NSDictionary* contactPropertyList;
- (ABRecordRef) copyPersonRecord;

@end
