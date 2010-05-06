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

// assumes strings are returned.
NSString* MvrFirstValueForContactMultivalue(ABRecordRef r, ABPropertyID ident) {
	NSString* result = nil;
	
	ABMultiValueRef mv = ABRecordCopyValue(r, ident);
	
	if (mv) {
		if (ABMultiValueGetCount(mv) > 0)
			result = [(NSString*)ABMultiValueCopyValueAtIndex(mv, 0) autorelease];
		
		CFRelease(mv);
	}

	return result;
}

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
	 @"contactEmailLabel",
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
			contactEmailLabel.text = email;
			contactEmailLabel.textColor = [UIColor blackColor];
		} else {
			contactEmailLabel.text = NSLocalizedString(@"no e-mail.", @"No E-mail marker");
			contactEmailLabel.textColor = [UIColor grayColor];
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

- (NSArray *) defaultActions;
{
	MvrItemAction* show = [MvrItemAction actionWithDisplayName:NSLocalizedString(@"Show", @"Show action button") target:self selector:@selector(showPersonPopover:forItem:)];
	show.continuesInteractionOnTable = YES;
	
	return [NSArray arrayWithObjects:
			show,
			nil];
}

- (void) showPersonPopover:(MvrItemAction*) a forItem:(MvrItem*) i;
{
	if (personPopover)
		return;
	
	ABUnknownPersonViewController* pc = [[ABUnknownPersonViewController new] autorelease];
	
	ABRecordRef ref = [self.item copyPersonRecord];
	pc.displayedPerson = ref;
	CFRelease(ref);
	
	pc.allowsAddingToAddressBook = YES;
	pc.allowsActions = YES;
	
	pc.title = [self.item title];
	
	UINavigationController* nc = [[[UINavigationController alloc] initWithRootViewController:pc] autorelease];
		
	personPopover = [[UIPopoverController alloc] initWithContentViewController:nc];
	personPopover.delegate = self;
	[personPopover presentPopoverFromRect:self.actionButton.bounds inView:self.actionButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
	
	const CGFloat dimmedInfoAlpha = 0.5;
	
	[UIView beginAnimations:nil context:NULL];
	contactNameLabel.alpha = dimmedInfoAlpha;
	contactPhoneLabel.alpha = dimmedInfoAlpha;
	contactEmailLabel.alpha = dimmedInfoAlpha;
	contactImageView.alpha = dimmedInfoAlpha;
	
	self.view.alpha = 0.8;
	
	[UIView commitAnimations];
}

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController;
{
	[UIView beginAnimations:nil context:NULL];
	contactNameLabel.alpha = 1.0;
	contactPhoneLabel.alpha = 1.0;
	contactEmailLabel.alpha = 1.0;
	contactImageView.alpha = 1.0;
	self.view.alpha = 1.0;
	[UIView commitAnimations];

	[self didFinishAction];
	personPopover.delegate = nil;
	[personPopover release]; personPopover = nil;
}

- (void) dealloc
{
	personPopover.delegate = nil;
	[personPopover release];
	[super dealloc];
}

@end

