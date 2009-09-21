//
//  MvrUIImagePickerSource.m
//  Mover3
//
//  Created by ∞ on 21/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrPhotoLibrarySource.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrUTISupport.h"

#import "MvrImageItem.h"

@interface MvrPhotoLibrarySource ()

- (void) performAddingImage:(UIImage*) i;
- (void) performAddingImageAtPath:(NSString*) path type:(NSString*) type;

@end


@implementation MvrPhotoLibrarySource

L0ObjCSingletonMethod(sharedSource)

- (id) init
{
	// UIImagePicker has two possible display names:
	// "Add Photo" -- if no available video, or
	// "Add Photo or Video" if video.
	
	BOOL isVideoAvailable = [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] containsObject:(id) kUTTypeMovie];
	
	NSString* dN = isVideoAvailable?
		NSLocalizedString(@"Add Photo or Video", @"Add photo button when video is available.") :
		NSLocalizedString(@"Add Photo", @"Add photo button (no video).");
	
	return [super initWithDisplayName:dN];
}

- (void) beginAddingItem;
{
	UIImagePickerController* picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.mediaTypes = [NSArray arrayWithObjects:(id) kUTTypeImage, (id) kUTTypeMovie, nil];
	[MvrApp() presentModalViewController:picker];
	[picker release];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
	NSString* uti = [info objectForKey:UIImagePickerControllerMediaType];
	if (uti) {
	
		if (UTTypeConformsTo((CFStringRef) uti, kUTTypeImage)) {
			
			NSURL* url;
			if ((url = [info objectForKey:UIImagePickerControllerMediaURL]) && [url isFileURL]) {
				[self performAddingImageAtPath:[url path] type:uti];
			} else {
				UIImage* i = [info objectForKey:UIImagePickerControllerOriginalImage];
				if (i) [self performAddingImage:i];
			}
			
		} else if (UTTypeConformsTo((CFStringRef) uti, kUTTypeMovie)) {
			L0AbstractMethod();
		}
		
	}
	
	[picker dismissModalViewControllerAnimated:YES];
}

- (void) performAddingImage:(UIImage *)i;
{
	MvrImageItem* image = [[MvrImageItem alloc] initWithImage:i type:(id) kUTTypeJPEG];
	[MvrApp() addItemFromSelf:image];
	[image release];
}

- (void) performAddingImageAtPath:(NSString *)path type:(NSString *)type;
{
	if ([type isEqual:(id) kUTTypeImage]) {
		CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef) [path pathExtension], kUTTypeImage);
		type = [(id)uti autorelease];
	}
	
	NSError* e;
	MvrItemStorage* storage = [MvrItemStorage itemStorageFromFileAtPath:path error:&e];
	if (!storage) {
		L0Log(@"%@", e);
		return;
	}
	
	MvrImageItem* imageItem = [[MvrImageItem alloc] initWithStorage:storage type:type metadata:nil];
	[MvrApp() addItemFromSelf:imageItem];
	[imageItem release];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker;
{
	[picker dismissModalViewControllerAnimated:YES];
}

@end
