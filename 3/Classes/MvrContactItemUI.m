//
//  MvrContactItemUI.m
//  Mover3
//
//  Created by ∞ on 02/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrContactItemUI.h"

#import <MuiKit/MuiKit.h>
#import <AddressBook/AddressBook.h>

#import "MvrContactItem.h"
#import "MvrAppDelegate.h"


@interface MvrContactItemUI ()

- (IBAction) hideDisplay;

@end


@implementation MvrContactItemUI

+ supportedItemClasses;
{
	return [NSSet setWithObject:[MvrContactItem class]];
}

- supportedItemSources;
{
	return [NSArray arrayWithObject:
			[MvrItemSource itemSourceWithDisplayName:NSLocalizedString(@"Add Contact", @"'Add contact' item source button") correspondingUI:self]
			];
}

- (void) dealloc
{
	[shownPerson release];
	[super dealloc];
}


- (UIImage*) representingImageWithSize:(CGSize) size forItem:(id) i;
{
	NSData* imageData = [[i contactPropertyList] objectForKey:kMvrContactImageData];
	UIImage* image = imageData? [UIImage imageWithData:imageData] : nil;
	
	return [image imageByRenderingRotationAndScalingWithMaximumSide:MAX(size.width, size.height)];
}

#pragma mark -
#pragma mark Adding.

- (void) beginAddingItemForSource:(MvrItemSource*) source;
{
	ABPeoplePickerNavigationController* picker = [[ABPeoplePickerNavigationController new] autorelease];
	picker.peoplePickerDelegate = self;
	[MvrApp() presentModalViewController:picker];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
	[peoplePicker dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person;
{
	MvrContactItem* item = [[[MvrContactItem alloc] initWithContentsOfAddressBookRecord:person] autorelease];
	[MvrApp() addItemFromSelf:item];
	
	[peoplePicker dismissModalViewControllerAnimated:YES];
	return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier;
{
	return NO;
}

#pragma mark -
#pragma mark Displaying.

- (MvrItemAction*) mainActionForItem:(MvrItem*) i;
{
	return [self showAction];
}

- (void) performShowOrOpenAction:(MvrItemAction*) a withItem:(id) i;
{
	if (shownPerson)
		[self hideDisplay];
	
	ABUnknownPersonViewController* unknown = [[ABUnknownPersonViewController new] autorelease];
	
	ABRecordRef person = [i copyPersonRecord];
	unknown.displayedPerson = person;
	CFRelease(person);
	
	unknown.allowsActions = YES;
	unknown.allowsAddingToAddressBook = YES;
	unknown.title = [i title];
	
	unknown.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hideDisplay)] autorelease];
	
	shownPerson = [[UINavigationController alloc] initWithRootViewController:unknown];
	shownPerson.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	[MvrApp() presentModalViewController:shownPerson];
}

- (IBAction) hideDisplay;
{
	[shownPerson dismissModalViewControllerAnimated:YES];
	[shownPerson release]; shownPerson = nil;
}

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownCardViewController didResolveToPerson:(ABRecordRef)person;
{
	// we don't really care, since it's just for display.
}

#pragma mark -
#pragma mark Saving in the Address Book.

- (BOOL) isItemSavedElsewhere:(id) i;
{
	return YES;
}

- (void) didReceiveItem:(id)i;
{
	ABAddressBookRef addressBook = ABAddressBookCreate();
	ABRecordRef person = [i copyPersonRecord];
	NSAssert(person, @"Did copy a person off the item");
	
	CFErrorRef error;
	if (!ABAddressBookAddRecord(addressBook, person, &error)) {
		CFRelease(addressBook);
		CFRelease(person);

		[NSException raise:@"MvrContactItemUICouldNotSave" format:@"An error occurred while adding an item to the address book: %@", [NSMakeCollectable(error) autorelease]];
		return;
	}
	
	if (!ABAddressBookSave(addressBook, &error)) {
		CFRelease(addressBook);
		CFRelease(person);
		
		[NSException raise:@"MvrContactItemUICouldNotSave" format:@"An error occurred while saving the address book: %@", [NSMakeCollectable(error) autorelease]];
		return;
	}
	
	CFRelease(addressBook);
	CFRelease(person);
}

@end
