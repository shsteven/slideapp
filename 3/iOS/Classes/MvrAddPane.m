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
#import "MvrPasteboardItemSource.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface MvrAddPane ()

- (void) switchToViewControllerForSegmentIndex:(NSInteger)i;
- (void) switchToViewController:(UIViewController *)vc;

@property(nonatomic, retain) UIImagePickerController* libraryController;
@property(nonatomic, retain) ABPeoplePickerNavigationController* peoplePicker;

- (void) updatePasteButtonAvailable:(NSNotification *)n;

@end


static inline UIBarButtonItem* ILBarButtonItemFlexibleSpace() {
	return [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL] autorelease];
}

@implementation MvrAddPane

@synthesize delegate;
@synthesize libraryController, peoplePicker;

- (id) init;
{
	if ((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePasteButtonAvailable:) name:UIPasteboardChangedNotification object:[UIPasteboard generalPasteboard]];
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void) updatePasteButtonAvailable:(NSNotification*) n;
{
	if (paste)
		paste.enabled = [[MvrPasteboardItemSource sharedSource] available];
}

- (void) viewDidLoad;
{
	[super viewDidLoad];
	[self addManagedOutletKeys:
	 @"libraryController",
	 @"peoplePicker",
	 @"kindPicker",
	 @"currentViewController",
	 @"paste",
	 nil];

	// At the top
//	self.navigationItem.titleView = kindPicker;
	
	paste = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Paste", @"Paste button in iPad Add pane") style:UIBarButtonItemStyleBordered target:self action:@selector(paste)];
	
	// At the bottom
	self.toolbarItems = [NSArray arrayWithObjects:
						 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL] autorelease],				
						 [[[UIBarButtonItem alloc] initWithCustomView:kindPicker] autorelease],
						 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL] autorelease],				
						 paste,
						 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL] autorelease],				
						 nil];	
}

- (UIImagePickerController*) libraryController;
{
	if (!libraryController) {
		libraryController = [[UIImagePickerController alloc] init];
		libraryController.mediaTypes = [NSArray arrayWithObjects:(id) kUTTypeImage, (id) kUTTypeMovie, nil];
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
	[self updatePasteButtonAvailable:nil];
	
	self.navigationController.navigationBarHidden = YES;
	self.navigationController.toolbarHidden = NO;
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
	[self.delegate addPaneDidFinishPickingItems];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person;
{
	MvrContactItem* i = [[[MvrContactItem alloc] initWithContentsOfAddressBookRecord:person] autorelease];
	[self.delegate addPaneDidPickItem:i];
	[self.delegate addPaneDidFinishPickingItems];
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
	} else if ([[info objectForKey:UIImagePickerControllerMediaType] isEqual:(id) kUTTypeMovie])
		i = [MvrVideoItem itemWithVideoAtPath:[[info objectForKey:UIImagePickerControllerMediaURL] path] type:(id) kUTTypeMovie error:NULL];
	
	if (i)
		[self.delegate addPaneDidPickItem:i];
	[self.delegate addPaneDidFinishPickingItems];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker;
{
	[self.delegate addPaneDidFinishPickingItems];
}

- (IBAction) paste;
{
	MvrPasteboardItemSource* s = [MvrPasteboardItemSource sharedSource];
	
	if (!s.available)
		return;
	
	[s retrieveItemsFromPasteboard:[UIPasteboard generalPasteboard] invokingBlock:^(MvrItem* i) {
		
		[self.delegate addPaneDidPickItem:i];
		
	}];
	
	[self.delegate addPaneDidFinishPickingItems];
}

@end
