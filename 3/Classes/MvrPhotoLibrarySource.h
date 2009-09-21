//
//  MvrUIImagePickerSource.h
//  Mover3
//
//  Created by ∞ on 21/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrItemUI.h"
#import "MvrAppDelegate.h"

@interface MvrPhotoLibrarySource : MvrItemSource <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {

}

+ sharedSource;

@end
