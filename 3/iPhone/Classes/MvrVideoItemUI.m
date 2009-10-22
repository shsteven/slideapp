//
//  MvrVideoItemUI.m
//  Mover3
//
//  Created by ∞ on 02/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrVideoItemUI.h"
#import "MvrVideoItem.h"
#import "MvrImagePickerSource.h"
#import "Network+Storage/MvrItemStorage.h"

#import "MvrAppDelegate+HelpAlerts.h"

@implementation MvrVideoItemUI

- (void) dealloc
{
	[currentPlayer release];
	[super dealloc];
}


+ (NSSet*) supportedItemClasses;
{
	return [NSSet setWithObject:[MvrVideoItem class]];
}

- (NSArray*) supportedItemSources;
{
	return [NSArray arrayWithObjects:
			[MvrPhotoLibrarySource sharedSource],
			[MvrCameraSource sharedSource],
			nil];
}

#pragma mark Storage

- (void) didStoreItem:(MvrItem *)i;
{
	if ((UIVideoAtPathIsCompatibleWithSavedPhotosAlbum) == NULL || (UISaveVideoAtPathToSavedPhotosAlbum) == NULL)
		return;
	
	if (!UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(i.storage.path)) {
		L0Log(@"Video of item %@ cannot be saved in the saved photos album. Uh. Not doing that.", i);
		return;
	}
	
	CFRetain(i); // balanced in the completion handler
	UISaveVideoAtPathToSavedPhotosAlbum(i.storage.path, self, @selector(videoAtPath:didFinishSavingWithError:context:), (void*) i);
	
	[MvrApp() showAlertIfNotShownBeforeNamed:@"MvrVideoReceived"];
}

- (void) videoAtPath:(NSString*) path didFinishSavingWithError:(NSError*) e context:(void*) context;
{
	MvrVideoItem* i = (MvrVideoItem*) context;
	if (e)
		L0Log(@"Could not save video at path %@ (item %@) because of this error: %@", path, i, e);
	else
		[i setObject:[NSNumber numberWithBool:YES] forItemNotesKey:kMvrVideoItemDidSave];
	
	CFRelease(i);
}

- (BOOL) isItemSavedElsewhere:(MvrItem *)i;
{
	return [[i objectForItemNotesKey:kMvrVideoItemDidSave] boolValue];
}

#pragma mark Playing

- (MvrItemAction*) mainActionForItem:(MvrItem *)i;
{
	return [MvrItemAction actionWithDisplayName:NSLocalizedString(@"Play", @"'Play' action for videos") target:self selector:@selector(performShowOrOpenAction:withItem:)];
}

- (void) performShowOrOpenAction:(MvrItemAction *)showOrOpen withItem:(MvrItem *)i;
{
	if (currentPlayer)
		return;
	
	currentPlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:i.storage.path]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishPlaying:) name:MPMoviePlayerPlaybackDidFinishNotification object:currentPlayer];
	
	[currentPlayer play];
}

- (void) didFinishPlaying:(NSNotification*) n;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:currentPlayer];
	[currentPlayer autorelease]; currentPlayer = nil;
}

- (UIImage*) representingImageWithSize:(CGSize)size forItem:(id)i;
{
	return [UIImage imageNamed:@"VideoItemIcon.png"];
}

- (NSString*) accessibilityLabelForItem:(id) i;
{
	return @"Video"; // TODO
}

@end
