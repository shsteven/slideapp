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

#define kMvrContactWasSaved @"MvrContactWasSaved"

@class MvrDuplicateContactHandler;

@interface MvrContactItemUI ()

- (IBAction) hideDisplay;
- (void) saveItem:(MvrContactItem*) i inAddressBook:(ABAddressBookRef) addressBook;

- (void) warnAboutDuplicateForItem:(MvrContactItem*) i;

- (void) saveItem:(MvrContactItem*) i inAddressBook:(ABAddressBookRef) addressBook;
- (void) didEndResolvingDuplicate:(MvrDuplicateContactHandler*) dupe;

@end



enum {
	kMvrDuplicateContactReview = 0,
	kMvrDuplicateContactSaveAsNew = 1,
	kMvrDuplicateContactDontSave = 2,	
};

@interface MvrDuplicateContactHandler : NSObject <UIAlertViewDelegate>
{
	MvrContactItem* item;
	MvrContactItemUI* ui;
}

- (id) initWithContact:(MvrContactItem*) item UI:(MvrContactItemUI*) ui;
- (void) start;

@end

@implementation MvrDuplicateContactHandler

- (id) initWithContact:(MvrContactItem*) i UI:(MvrContactItemUI*) u;
{
	if (self = [super init]) {
		item = [i retain];
		ui = u; // it owns us
	}
	
	return self;
}

- (void) dealloc
{
	[item release];
	[super dealloc];
}


- (void) start;
{
	UIAlertView* alert = [UIAlertView alertNamed:@"MvrContactIsADuplicate"];
	[alert setTitleFormat:nil, item.title];
	
	alert.cancelButtonIndex = kMvrDuplicateContactDontSave;
	alert.delegate = self;
	
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	switch (buttonIndex) {
		case kMvrDuplicateContactReview: {
			[ui performShowOrOpenAction:nil withItem:item];
		}
			break;
			
		case kMvrDuplicateContactSaveAsNew: {
			ABAddressBookRef ab = ABAddressBookCreate();
			[ui saveItem:item inAddressBook:ab];
			CFRelease(ab);
		}
			break;
			
		case kMvrDuplicateContactDontSave:
		default:
			break;
	}
	
	alertView.delegate = nil;
	[ui didEndResolvingDuplicate:self];
}

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

- (id) init
{
	self = [super init];
	if (self != nil) {
		duplicateContactHandlers = [NSMutableSet new];
	}
	return self;
}


- (void) dealloc
{
	[duplicateContactHandlers release];
	[shownPerson release];
	[super dealloc];
}


- (UIImage*) representingImageWithSize:(CGSize) size forItem:(id) i;
{
	NSData* imageData = [[i contactPropertyList] objectForKey:kMvrContactImageData];
	UIImage* image = imageData? [UIImage imageWithData:imageData] : nil;
	
	if (image)
		return [image imageByRenderingRotationAndScalingWithMaximumSide:MAX(size.width, size.height)];
	else
		return [UIImage imageNamed:@"ContactWithoutImageIcon.png"];
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

- (NSString*) accessibilityLabelForItem:(id)i;
{
	return [NSString stringWithFormat:NSLocalizedString(@"%@, Contact", @"Template for the accessibility label of contact items"), [i title]];
}

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
	return [[i objectForItemNotesKey:kMvrContactWasSaved] boolValue];
}

- (void) didReceiveItem:(id)i;
{
	ABAddressBookRef addressBook = ABAddressBookCreate();
	CFArrayRef people = ABAddressBookCopyPeopleWithName(addressBook, (CFStringRef) [i nameAndSurnameForSearching]);
	
	BOOL foundDupe = people && CFArrayGetCount(people) > 0;
	if (people)
		CFRelease(people);
	
	if (foundDupe)
		[self warnAboutDuplicateForItem:i];
	else
		[self saveItem:i inAddressBook:addressBook];
	
	CFRelease(addressBook);
}

- (void) saveItem:(MvrContactItem*) i inAddressBook:(ABAddressBookRef) addressBook;
{
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
	
	CFRelease(person);
	
	[i setObject:[NSNumber numberWithBool:YES] forItemNotesKey:kMvrContactWasSaved];
}

- (void) warnAboutDuplicateForItem:(MvrContactItem*) i;
{
	MvrDuplicateContactHandler* dupe = [[[MvrDuplicateContactHandler alloc] initWithContact:i UI:self] autorelease];
	[duplicateContactHandlers addObject:dupe];
	
	[dupe start];
}

- (void) didEndResolvingDuplicate:(MvrDuplicateContactHandler*) dupe;
{
	[[dupe retain] autorelease];
	[duplicateContactHandlers removeObject:dupe];
}

@end
