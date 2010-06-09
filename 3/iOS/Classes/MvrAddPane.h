//
//  MvrAddPane.h
//  Mover3-iPad
//
//  Created by ∞ on 05/06/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ILViewController.h"
#import "Network+Storage/MvrItem.h"

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@protocol MvrAddPaneDelegate <NSObject>

- (void) addPaneDidPickItem:(MvrItem*) i;
- (void) addPaneDidFinishPickingItems;

@end


@interface MvrAddPane : ILViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, ABPeoplePickerNavigationControllerDelegate> {
	UIImagePickerController* libraryController;
	ABPeoplePickerNavigationController* peoplePicker;
	
	UIViewController* currentViewController;
	
	IBOutlet UISegmentedControl* kindPicker;
	
	id <MvrAddPaneDelegate> delegate;
	
	UIBarButtonItem* paste;
}

@property(assign) UIViewController* currentViewController;

- (IBAction) updateDisplayedViewController;

@property(assign) id <MvrAddPaneDelegate> delegate;

- (IBAction) paste;

@end
