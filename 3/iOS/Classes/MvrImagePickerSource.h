//
//  MvrUIImagePickerSource.h
//  Mover3
//
//  Created by ∞ on 21/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrItemUI.h"
#import "MvrAppDelegate.h"

@interface MvrImagePickerSource : MvrItemSource <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
	UIImagePickerControllerSourceType sourceType;
	BOOL isVideoAvailable;
	
	NSString* displayNameWithVideo, * displayNameWithoutVideo;
}

@end


@interface MvrPhotoLibrarySource : MvrImagePickerSource {}
+ sharedSource;
@end

@interface MvrCameraSource : MvrImagePickerSource {}
+ sharedSource;
@end
