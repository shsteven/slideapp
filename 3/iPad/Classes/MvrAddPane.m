//
//  MvrAddPane.m
//  Mover3-iPad
//
//  Created by ∞ on 05/06/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrAddPane.h"

#import "MvrContactItem.h"
#import "MvrImageItem.h"
#import "MvrVideoItem.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface MvrAddPane ()

- (void) switchToViewControllerForSegmentIndex:(NSInteger)i;
- (void) switchToViewController:(UIViewController *)vc;

@property(nonatomic, retain) UIImagePickerController* libraryController;
@property(nonatomic, retain) ABPeoplePickerNavigationController* peoplePicker;

@end


@implementation MvrAddPane

@synthesize delegate;
@synthesize libraryController, peoplePicker;

- (void) viewDidLoad;
{
	[super viewDidLoad];
	[self addManagedOutletKeys:
	 @"libraryController",
	 @"peoplePicker",
	 @"kindPicker",
	 @"currentViewController",
	 nil];
		
	self.navigationItem.titleView = kindPicker;
}

- (UIImagePickerController*) libraryController;
{
	if (!libraryController) {
		libraryController = [[UIImagePickerController alloc] init];
		libraryController.mediaTypes = [NSArray arrayWithObjects:(id) kUTTypeImage, (id) kUTTypeVideo, nil];
		libraryController.delegate = self;
	}
	
	return libraryController;
}

- (ABPeoplePickerNavigationController*) peoplePicker;
{
	if (!peoplePicker) {
		peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
		peoplePicker.peoplePickerDelegate = self;
		peoplePicker.delegate = self;
	}
	
	return peoplePicker;
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
			[self switchToViewController:self.libraryController];
			break;
		case 1:
			[self switchToViewController:self.peoplePicker];
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
	if ([self.currentViewController isViewLoaded])
		[self.currentViewController.view removeFromSuperview];
	
	self.currentViewController = nil;
	self.libraryController = nil;
	self.peoplePicker = nil;
}


- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
	[self.delegate addPaneDidCancel];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person;
{
	MvrContactItem* i = [[[MvrContactItem alloc] initWithContentsOfAddressBookRecord:person] autorelease];
	[self.delegate addPaneDidPickItem:i];
	return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier;
{ return NO; }


- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
	MvrItem* i = nil;
	
	if ([[info objectForKey:UIImagePickerControllerMediaType] isEqual:(id) kUTTypeImage]) {
		UIImage* img = [info objectForKey:UIImagePickerControllerOriginalImage];
		if (!img && [info objectForKey:UIImagePickerControllerMediaURL])
			img = [UIImage imageWithContentsOfFile:[info objectForKey:UIImagePickerControllerMediaURL]];

		if (img)
			i = [[[MvrImageItem alloc] initWithImage:img type:(id) kUTTypePNG] autorelease];
	} else if ([[info objectForKey:UIImagePickerControllerMediaType] isEqual:(id) kUTTypeImage])
		i = [MvrVideoItem itemWithVideoAtPath:[[info objectForKey:UIImagePickerControllerMediaURL] path] type:(id) kUTTypeMovie error:NULL];
	
	if (i)
		[self.delegate addPaneDidPickItem:i];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker;
{
	[self.delegate addPaneDidCancel];
}

//- (void) navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
//{
//	if ((navigationController == libraryController || navigationController == peoplePicker) && viewController.navigationItem.rightBarButtonItem)
//		viewController.navigationItem.rightBarButtonItem = nil;
//}
//
//- (void) navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
//{
//	if ((navigationController == libraryController || navigationController == peoplePicker) && viewController.navigationItem.rightBarButtonItem)
//		viewController.navigationItem.rightBarButtonItem = nil;
//}

@end
