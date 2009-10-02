//
//  MvrUIImagePickerSource.m
//  Mover3
//
//  Created by ∞ on 21/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrImagePickerSource.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrUTISupport.h"

#import "MvrImageItem.h"
#import "MvrVideoItem.h"

@interface MvrImagePickerSource ()

- (id) initWithDisplayName:(NSString*) dn displayNameWithoutVideo:(NSString*) dnNoVideo sourceType:(UIImagePickerControllerSourceType) s;

- (void) performAddingImage:(UIImage*) i;
- (void) performAddingImageAtPath:(NSString*) path type:(NSString*) type;
- (void) performAddingVideoAtPath:(NSString *)path type:(NSString *)type;

@end


@implementation MvrImagePickerSource

- (id) initWithDisplayName:(NSString*) dn displayNameWithoutVideo:(NSString*) dnNoVideo sourceType:(UIImagePickerControllerSourceType) s;
{
	// UIImagePicker has two possible display names:
	// "Add Photo" -- if no available video, or
	// "Add Photo or Video" if video.
	
	BOOL isVideoAvailable = [UIImagePickerController isSourceTypeAvailable:sourceType] && [[UIImagePickerController availableMediaTypesForSourceType:s] containsObject:(id) kUTTypeMovie];
	
	NSString* name = isVideoAvailable?
		dn : dnNoVideo;
	
	if (self = [super initWithDisplayName:name])
		sourceType = s;
	
	return self;
}

- (void) beginAddingItem;
{
	UIImagePickerController* picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
	picker.sourceType = sourceType;
	picker.mediaTypes = [NSArray arrayWithObjects:(id) kUTTypeImage, (id) kUTTypeMovie, nil];
	[MvrApp() presentModalViewController:picker];
	[picker release];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
	L0Log(@"Picked: %@", info);
	
	NSString* uti = [info objectForKey:UIImagePickerControllerMediaType];
	if (uti) {
	
		NSURL* url = [info objectForKey:UIImagePickerControllerMediaURL];
		
		if (UTTypeConformsTo((CFStringRef) uti, kUTTypeImage)) {
			
			if (url && [url isFileURL]) {
				[self performAddingImageAtPath:[url path] type:uti];
			} else {
				UIImage* i = [info objectForKey:UIImagePickerControllerOriginalImage];
				if (i) [self performAddingImage:i];
			}
			
		} else if (UTTypeConformsTo((CFStringRef) uti, kUTTypeMovie)) {
			
			if (url && [url isFileURL])
				[self performAddingVideoAtPath:[url path] type:uti];
			
		}
		
	}
	
	[picker dismissModalViewControllerAnimated:YES];
}

- (void) performAddingVideoAtPath:(NSString *)path type:(NSString *)type;
{
	NSError* e;
	MvrVideoItem* video = [MvrVideoItem itemWithVideoAtPath:path type:type error:&e];
	
	if (video)
		[MvrApp() addItemFromSelf:video];
	else
		L0Log(@"Could not add video, there was an error: %@", e);
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

- (BOOL) available;
{
	return [UIImagePickerController isSourceTypeAvailable:sourceType];
}

@end

@implementation MvrPhotoLibrarySource

L0ObjCSingletonMethod(sharedSource)

- (id) init;
{
	return [self initWithDisplayName:NSLocalizedString(@"Add Photo or Video", @"Add photo button when video is available.") displayNameWithoutVideo:NSLocalizedString(@"Add Photo", @"Add photo button (no video).") sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

@end

@implementation MvrCameraSource

L0ObjCSingletonMethod(sharedSource)

- (id) init;
{
	return [self initWithDisplayName:NSLocalizedString(@"Capture Photo or Video", @"Add photo button when video is available.") displayNameWithoutVideo:NSLocalizedString(@"Take Photo", @"Add photo button (no video).") sourceType:UIImagePickerControllerSourceTypeCamera];
}

@end
