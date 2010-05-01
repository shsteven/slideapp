//
//  MvrContactItemController.m
//  Mover3-iPad
//
//  Created by ∞ on 01/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrContactItemController.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

// assumes strings are returned.
NSString* MvrFirstValueForContactMultivalue(ABRecordRef r, ABPropertyID ident) {
	NSString* result = nil;
	
	ABMultiValueRef mv = ABRecordCopyValue(r, ident);
	
	if (ABMultiValueGetCount(mv) > 0)
		result = [(NSString*)ABMultiValueCopyValueAtIndex(mv, 0) autorelease];
	
	CFRelease(mv);
	
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
}

- (void) itemDidChange;
{
	if (self.item) {
		ABRecordRef me = [self.item copyPersonRecord];
		
		CFDataRef imageData = ABPersonCopyImageData(me);
		if (imageData) {
			contactImageView.image = [UIImage imageWithData:(NSData*) imageData];
			CFRelease(imageData);
		}
		
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

@end

