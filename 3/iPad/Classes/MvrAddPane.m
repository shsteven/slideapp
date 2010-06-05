//
//  MvrAddPane.m
//  Mover3-iPad
//
//  Created by ∞ on 05/06/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrAddPane.h"

@interface MvrAddPane ()

- (void) switchToViewControllerForSegmentIndex:(NSInteger)i;
- (void) switchToViewController:(UIViewController *)vc;

@end



@implementation MvrAddPane

- (void) viewDidLoad;
{
	[super viewDidLoad];
	[self addManagedOutletKeys:
	 @"libraryController",
	 @"peoplePicker",
	 @"kindPicker",
	 @"currentViewController",
	 nil];
	
	libraryController = [[UIImagePickerController alloc] init];
	libraryController.delegate = self;
	
	peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
	peoplePicker.peoplePickerDelegate = self;
	
	self.navigationItem.titleView = kindPicker;
}

@synthesize currentViewController;

- (CGSize) contentSizeForViewInPopover;
{
	return CGSizeMake(320, 400);
}

- (IBAction) updateDisplayedViewController;
{
	[self switchToViewControllerForSegmentIndex:kindPicker.selectedSegmentIndex];
}

- (void) switchToViewControllerForSegmentIndex:(NSInteger) i;
{
	switch (i) {
		case 0:
			[self switchToViewController:libraryController];
			break;
		case 1:
			[self switchToViewController:peoplePicker];
			break;
	}
}

- (void) switchToViewController:(UIViewController*) vc;
{
	BOOL isSwitchingAway = (currentViewController && [currentViewController isViewLoaded]);
	
	if (isSwitchingAway)
		[currentViewController viewWillDisappear:NO];
	
	[vc viewWillAppear:NO];
	
	if (isSwitchingAway) {
		[currentViewController.view removeFromSuperview];
		[currentViewController viewDidDisappear:NO];
	}
	
	UIView* v = vc.view;
	v.frame = self.view.bounds;
	[self.view addSubview:v];
	[vc viewDidAppear:NO];
	
	self.currentViewController = vc;	
}

- (void) viewWillAppear:(BOOL) ani;
{
	[super viewWillAppear:ani];
	[self updateDisplayedViewController];
}

- (void) viewWillDisappear:(BOOL) ani;
{
	[super viewDidDisappear:ani];
	[self.currentViewController viewWillDisappear:ani];
}

- (void) viewDidDisappear:(BOOL) ani;
{
	[super viewDidDisappear:ani];
	[self.currentViewController viewDidDisappear:ani];
}


- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person;
{ return NO; }

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier;
{ return NO; }


- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{}

@end
