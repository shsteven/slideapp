//
//  MvrUIImagePickerSource.m
//  Mover3
//
//  Created by ∞ on 21/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrImagePickerSource.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrUTISupport.h"

#import "MvrImageItem.h"
#import "MvrVideoItem.h"

#import "MvrItemUI.h" // for kMvrItemHighQualityNoteKey

#import <AssetsLibrary/AssetsLibrary.h>

@interface MvrImagePickerSource ()

- (id) initWithDisplayName:(NSString*) dn displayNameWithoutVideo:(NSString*) dnNoVideo sourceType:(UIImagePickerControllerSourceType) s;

- (void) performAddingImage:(UIImage*) i;
- (void) performAddingImageAtPath:(NSString*) path type:(NSString*) type;
- (void) performAddingVideoAtPath:(NSString *)path type:(NSString *)type;

- (void) continueImportingMediaForPicker:(UIImagePickerController *)picker withInfo:(NSDictionary *)info;

@end


@implementation MvrImagePickerSource

- (id) initWithDisplayName:(NSString*) dn displayNameWithoutVideo:(NSString*) dnNoVideo sourceType:(UIImagePickerControllerSourceType) s;
{
	if ((self = [super initWithDisplayName:nil])) {
		// UIImagePicker has two possible display names:
		// "Add Photo" -- if no available video, or
		// "Add Photo or Video" if video.
		
		isVideoAvailable = [UIImagePickerController isSourceTypeAvailable:sourceType] && [[UIImagePickerController availableMediaTypesForSourceType:s] containsObject:(id) kUTTypeMovie];
		
		displayNameWithVideo = [dn copy];
		displayNameWithoutVideo = [dnNoVideo copy];
		
		sourceType = s;
	}
	
	return self;
}

- (void) dealloc
{
	[displayNameWithVideo release];
	[displayNameWithoutVideo release];
	[super dealloc];
}


- (NSString *) displayName;
{
	return (isVideoAvailable && [MvrApp() isFeatureAvailable:kMvrFeatureVideoSending])? displayNameWithVideo : displayNameWithoutVideo;
}

- (void) beginAddingItem;
{
	UIImagePickerController* picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
	picker.sourceType = sourceType;
	picker.mediaTypes = (isVideoAvailable && [MvrApp() isFeatureAvailable:kMvrFeatureVideoSending])? [NSArray arrayWithObjects:(id) kUTTypeImage, (id) kUTTypeMovie, nil] : [NSArray arrayWithObject:(id) kUTTypeImage];
	
	picker.videoQuality = MvrServices().highQualityVideoEnabled? UIImagePickerControllerQualityTypeHigh : UIImagePickerControllerQualityTypeMedium;
	
	[MvrApp() presentModalViewController:picker];
	[picker release];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
	L0Log(@"Picked: %@", info);
	
	Class al = NSClassFromString(@"ALAssetsLibrary");
	if (&UIImagePickerControllerReferenceURL != NULL && al) {
		ALAssetsLibrary* library = [[al new] autorelease];
		
		[library assetForURL:[info objectForKey:UIImagePickerControllerReferenceURL]
				 resultBlock:^(ALAsset* ala) {
					 L0Log(@"Asset: %@", ala);
					 
					 // video? sidetrack
					 if (MvrApp().highQualityVideoEnabled && [[ala valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo]) {
						 ALAssetRepresentation* rep = [ala defaultRepresentation];
						 id type = [rep UTI];
						 
						 MvrItemStorage* storage = [MvrItemStorage itemStorage];
						 NSOutputStream* output = [storage outputStreamForContentOfAssumedSize:[rep size]];
						 [output open];
						 
						 long long size = [rep size];
						 uint8_t* bytes = (uint8_t*) malloc(1024 * 1024);
						 
						 while (size > 0) {
							 long long toRead = MIN(size, 1024 * 1024);
							 NSInteger actuallyRead = [rep getBytes:bytes fromOffset:[rep size] - size length:toRead error:NULL];
							 if (actuallyRead != toRead)
								 break;
							 [output write:bytes maxLength:actuallyRead];
							 if ([output streamError])
								 break;
							 
							 size -= actuallyRead;
						 }
						 
						 free(bytes);
						 
						 [output close];
						 [storage endUsingOutputStream];
						 
						 if (size == 0) { // all was read
							 MvrVideoItem* videoItem = [[MvrVideoItem alloc] initWithStorage:storage type:type metadata:nil];
							 [videoItem setObject:[NSNumber numberWithBool:YES] forItemNotesKey:kMvrVideoItemDidSave];
							 [videoItem setObject:[NSNumber numberWithBool:YES] forItemNotesKey:kMvrItemHighQualityNoteKey];

							 [MvrApp() addItemFromSelf:videoItem];
							 [videoItem release];
							 [picker dismissModalViewControllerAnimated:YES];
							 return;
						 }
						 
					 } else {
						 id type = (id) kUTTypeJPEG;
						 
						 ALAssetRepresentation* rep = [ala representationForUTI:type];
						 if (!rep) {
							 type = (id) kUTTypePNG;
							 rep = [ala representationForUTI:type];
						 }
						 
						 if (rep) {
							 // we're loading it all in memory for now.
							 NSMutableData* d = [NSMutableData dataWithLength:[rep size]];
							 NSUInteger bytes = [rep getBytes:[d mutableBytes] fromOffset:0 length:[rep size] error:NULL];
							 if (bytes == [d length]) {
								 
								 MvrItemStorage* storage = [MvrItemStorage itemStorageWithData:d];
								 MvrItem* item = [[MvrImageItem alloc] initWithStorage:storage type:type metadata:nil];
								 [item setObject:[NSNumber numberWithBool:YES] forItemNotesKey:kMvrItemHighQualityNoteKey];
								 
								 [MvrApp() addItemFromSelf:item];
								 
								 [item release];
								 
								 [picker dismissModalViewControllerAnimated:YES];
								 return;
								
							 }
						 }
					 }
					 
					 [self continueImportingMediaForPicker:picker withInfo:info];
				 }
				failureBlock:^(NSError* e) {
					L0Log(@"Error: %@", e);
					[self continueImportingMediaForPicker:picker withInfo:info];
				}];		
	} else
		[self continueImportingMediaForPicker:picker withInfo:info];
}

- (void) continueImportingMediaForPicker:(UIImagePickerController*) picker withInfo:(NSDictionary*) info;
{
	NSString* uti = [info objectForKey:UIImagePickerControllerMediaType];
	if (uti) {
		
		NSURL* url = [info objectForKey:UIImagePickerControllerMediaURL];
		
		if (UTTypeConformsTo((CFStringRef) uti, kUTTypeImage)) {
			
			if (url && [url isFileURL]) {
				[self performAddingImageAtPath:[url path] type:uti];
			} else {
				UIImage* i = [info objectForKey:UIImagePickerControllerOriginalImage];
				if (i) {
					[self performAddingImage:i];
					
					if (sourceType == UIImagePickerControllerSourceTypeCamera)
						UIImageWriteToSavedPhotosAlbum(i, nil, NULL, NULL);
				}
			}
			
		} else if (UTTypeConformsTo((CFStringRef) uti, kUTTypeMovie) && [MvrApp() isFeatureAvailable:kMvrFeatureVideoSending]) {
			
			if (url && [url isFileURL]) {
				[self performAddingVideoAtPath:[url path] type:uti];
				
				if (sourceType == UIImagePickerControllerSourceTypeCamera && (UISaveVideoAtPathToSavedPhotosAlbum) != NULL)
					UISaveVideoAtPathToSavedPhotosAlbum([url path], nil, NULL, NULL);
			}
			
		}
		
	}
	
	[picker dismissModalViewControllerAnimated:YES];
}

- (void) performAddingVideoAtPath:(NSString *)path type:(NSString *)type;
{
	if (![MvrApp() isFeatureAvailable:kMvrFeatureVideoSending])
		return;
	
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
