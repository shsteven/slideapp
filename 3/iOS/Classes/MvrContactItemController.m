//
//  MvrContactItemController.m
//  Mover3-iPad
//
//  Created by ∞ on 01/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrContactItemController.h"
#import "MvrShadowBackdropDraggableView.h"
#import "MvrItemAction.h"

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#import <MuiKit/MuiKit.h>

#import "MvrAppDelegate_iPad.h"

enum {
	kMvrDuplicateContactReview = 0,
	kMvrDuplicateContactSaveAsNew = 1,
	kMvrDuplicateContactDontSave = 2,	
};


// assumes strings are returned.
NSString* MvrFirstValueForContactMultivalue(ABRecordRef r, ABPropertyID ident) {
	NSString* result = nil;
	
	ABMultiValueRef mv = ABRecordCopyValue(r, ident);
	
	if (mv) {
		if (ABMultiValueGetCount(mv) > 0)
			result = [NSMakeCollectable(ABMultiValueCopyValueAtIndex(mv, 0)) autorelease];
		
		CFRelease(mv);
	}

	return result;
}

@interface MvrContactItemController ()

- (void) warnAboutDuplicateForItem;
- (void) saveItemInAddressBook:(ABAddressBookRef)addressBook;
- (UINavigationController*) navigationControllerToDisplayPersonItem:(MvrItem *)i;

- (void) showPersonPopover:(MvrItemAction *)a forItem:(MvrItem *)i;

@end


@implementation MvrContactItemController

+ (NSSet *) supportedItemClasses;
{
	return [NSSet setWithObject:[MvrContactItem class]];
}

- (void) viewDidLoad;
{
	[super viewDidLoad];
	[self itemDidChange];
	
	[self addManagedOutletKeys:
	 @"contactImageView",
	 @"contactNameLabel",
	 @"contactEmailButton",
	 @"contactPhoneLabel",
	 nil];
	
	CGPoint p;
	p.x = self.view.bounds.size.width - self.actionButton.bounds.size.width - 20;
	p.y = self.view.bounds.size.height - self.actionButton.bounds.size.height - 20;
	
	CGRect r = self.actionButton.frame;
	r.origin = p;
	self.actionButton.frame = r;
	
	[self.view addSubview:self.actionButton];
	
	((MvrShadowBackdropDraggableView*)self.view).contentAreaBackgroundColor = 
		[UIColor colorWithPatternImage:[UIImage imageNamed:@"PaperTexture.jpg"]];
	
	[contactEmailButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
	[contactEmailButton setTitle:NSLocalizedString(@"no e-mail.", @"No E-Mail marker") forState:UIControlStateDisabled];
}

- (void) itemDidChange;
{
	if (self.item) {
		ABRecordRef me = [self.item copyPersonRecord];
		
		CFDataRef imageData = ABPersonCopyImageData(me);
		if (imageData) {
			contactImageView.image = [UIImage imageWithData:(NSData*) imageData];
			CFRelease(imageData);
		} else
			contactImageView.image = [UIImage imageNamed:@"ContactWithoutImageIcon.png"];

		contactNameLabel.text = [self.item title];
		
		NSString* email = MvrFirstValueForContactMultivalue(me, kABPersonEmailProperty);
		NSString* phone = MvrFirstValueForContactMultivalue(me, kABPersonPhoneProperty);

		if (email) {
			[contactEmailButton setTitle:email forState:UIControlStateNormal];
			[contactEmailButton setTitle:email forState:UIControlStateHighlighted];
			
			contactEmailButton.enabled = YES;
			sendEmail.available = YES;
		} else {
			contactEmailButton.enabled = NO;
			sendEmail.available = NO;
		}

		if (phone) {
			contactPhoneLabel.text = phone;
			contactPhoneLabel.textColor = [UIColor blackColor];
		} else {
			contactPhoneLabel.text = NSLocalizedString(@"no phone number.", @"No Phone marker");
			contactPhoneLabel.textColor = [UIColor grayColor];
		}
				
		CFRelease(me);
	}
}

- (void) itemDidFinishReceivingFromNetwork;
{
	ABAddressBookRef addressBook = ABAddressBookCreate();
	NSString* searchString = [self.item nameAndSurnameForSearching];
	CFArrayRef people = searchString? ABAddressBookCopyPeopleWithName(addressBook, (CFStringRef) searchString) : NULL;
	BOOL foundDupe = people && CFArrayGetCount(people) > 0;
	if (people)
		CFRelease(people);
	
	if (foundDupe)
		[self warnAboutDuplicateForItem];
	else
		[self saveItemInAddressBook:addressBook];
	
	CFRelease(addressBook);
}

- (void) warnAboutDuplicateForItem;
{
	UIAlertView* alert = [UIAlertView alertNamed:@"MvrContactIsADuplicate"];
	[alert setTitleFormat:nil, [self.item title]];
	
	alert.cancelButtonIndex = kMvrDuplicateContactDontSave;
	alert.delegate = self;
	
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	switch (buttonIndex) {
		case kMvrDuplicateContactReview: 
			[self showPersonPopover:nil forItem:self.item];
			break;
			
		case kMvrDuplicateContactSaveAsNew: {
			ABAddressBookRef ab = ABAddressBookCreate();
			[self saveItemInAddressBook:ab];
			CFRelease(ab);
		}
			break;
			
		case kMvrDuplicateContactDontSave:
		default:
			break;
	}
	
	alertView.delegate = nil;
}

- (void) saveItemInAddressBook:(ABAddressBookRef) addressBook;
{
	ABRecordRef person = [self.item copyPersonRecord];
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
	
	[self.item setObject:[NSNumber numberWithBool:YES] forItemNotesKey:kMvrContactWasSaved];
}

- (NSArray *) defaultActions;
{
	MvrItemAction* show = [MvrItemAction actionWithDisplayName:NSLocalizedString(@"Show", @"Show action button") target:self selector:@selector(showPersonPopover:forItem:)];
	show.continuesInteractionOnTable = YES;
	
	if (!sendEmail) {
		sendEmail = [[MvrItemAction actionWithDisplayName:NSLocalizedString(@"Send E-Mail to Contact", @"Send e-mail to contact action button")
			block:^(MvrItem* i) {
			
				[self showMailComposerForContact];
			
			}] retain];
	}
	
	if (self.item) {
		ABRecordRef me = [self.item copyPersonRecord];
		NSString* email = MvrFirstValueForContactMultivalue(me, kABPersonEmailProperty);
		sendEmail.available = (email != nil);
		CFRelease(me);
	}
	
	return [NSArray arrayWithObjects:
			show,
			sendEmail,
			nil];
}

- (void) showPersonPopover:(MvrItemAction*) a forItem:(MvrItem*) i;
{
	if (personPopover)
		return;
	
	UINavigationController* nc = [self navigationControllerToDisplayPersonItem:i];
		
	personPopover = [[UIPopoverController alloc] initWithContentViewController:nc];
	personPopover.delegate = self;
	[personPopover presentPopoverFromRect:self.actionButton.bounds inView:self.actionButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
	
	const CGFloat dimmedInfoAlpha = 0.5;
	
	[UIView beginAnimations:nil context:NULL];
	contactNameLabel.alpha = dimmedInfoAlpha;
	contactPhoneLabel.alpha = dimmedInfoAlpha;
	contactEmailButton.alpha = dimmedInfoAlpha;
	contactImageView.alpha = dimmedInfoAlpha;
	
	self.view.alpha = 0.8;
	
	[UIView commitAnimations];
}

- (UINavigationController*) navigationControllerToDisplayPersonItem:(MvrItem*) i;
{
	ABUnknownPersonViewController* pc = [[ABUnknownPersonViewController new] autorelease];
	
	ABRecordRef ref = [self.item copyPersonRecord];
	pc.displayedPerson = ref;
	CFRelease(ref);
	
	pc.allowsAddingToAddressBook = YES;
	pc.allowsActions = YES;
	
	pc.title = [self.item title];
	
	UINavigationController* nc = [[[UINavigationController alloc] initWithRootViewController:pc] autorelease];
	return nc;
}

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController;
{
	[UIView beginAnimations:nil context:NULL];
	contactNameLabel.alpha = 1.0;
	contactPhoneLabel.alpha = 1.0;
	contactEmailButton.alpha = 1.0;
	contactImageView.alpha = 1.0;
	self.view.alpha = 1.0;
	[UIView commitAnimations];

	[self didFinishAction];
	personPopover.delegate = nil;
	[personPopover release]; personPopover = nil;
}

- (void) dealloc
{
	[sendEmail release];
	personPopover.delegate = nil;
	[personPopover release];
	[super dealloc];
}

- (IBAction) showMailComposerForContact;
{
	if (!self.item)
		return;
	
	ABRecordRef me = [self.item copyPersonRecord];
	
	NSString* email = MvrFirstValueForContactMultivalue(me, kABPersonEmailProperty);
	
	if (email) {
		MFMailComposeViewController* mail = [[MFMailComposeViewController new] autorelease];
		[mail setToRecipients:[NSArray arrayWithObject:email]];
		
		mail.mailComposeDelegate = self;
		
		[MvrServices() presentModalViewController:mail];
	}
	
	CFRelease(me);
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
{
	[controller dismissModalViewControllerAnimated:YES];
}

@end

