//
//  MvrAddPane.h
//  Mover3-iPad
//
//  Created by ∞ on 05/06/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ILViewController.h"

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface MvrAddPane : ILViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, ABPeoplePickerNavigationControllerDelegate> {
	UIImagePickerController* libraryController;
	ABPeoplePickerNavigationController* peoplePicker;
	
	UIViewController* currentViewController;
	
	IBOutlet UISegmentedControl* kindPicker;
}

@property(assign) UIViewController* currentViewController;

- (IBAction) updateDisplayedViewController;

@end
