//
//  MvrImageItemUI.m
//  Mover3
//
//  Created by ∞ on 21/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrImageItemUI.h"

#import <MuiKit/MuiKit.h>

#import "MvrImageItem.h"
#import "MvrImagePickerSource.h"
#import "MvrImageVisor.h"

#import "Network+Storage/MvrUTISupport.h"

#import "MvrAppDelegate.h"
#import "MvrAppDelegate+HelpAlerts.h"

#import "MvrSwapKitSendToAction.h"

@implementation MvrImageItemUI

- (id) init
{
	self = [super init];
	if (self != nil) {
		itemsBeingSaved = [NSMutableSet new];
	}
	return self;
}

- (void) dealloc
{
	[itemsBeingSaved release];
	[super dealloc];
}


+ supportedItemClasses;
{
	return [NSSet setWithObject:[MvrImageItem class]];
}

- supportedItemSources;
{
	return [NSArray arrayWithObjects:
			[MvrPhotoLibrarySource sharedSource],
			[MvrCameraSource sharedSource],
			nil];
}

- (UIImage*) representingImageWithSize:(CGSize) size forItem:(id) i;
{
	UIImage* original = [i image];
	return [original imageByRenderingRotationAndScalingWithMaximumSide:MAX(size.width, size.height)];
}

- (void) didStoreItem:(MvrItem*) i;
{
	[itemsBeingSaved addObject:i];
	
	CFRetain(i); // balanced in image:didFinishSavingWithError:context:
	UIImageWriteToSavedPhotosAlbum(((MvrImageItem*)i).image, self, @selector(image:didFinishSavingWithError:context:), (void*) i);
	
	[MvrApp() showAlertIfNotShownBeforeNamed:@"MvrImageReceived"];
}

- (void) image:(UIImage*) image didFinishSavingWithError:(NSError*) e context:(void*) context;
{
	MvrItem* i = (MvrItem*) context;
	
	if (e) {
		// TODO
		L0LogAlways(@"%@", e);
	}
	
	[itemsBeingSaved removeObject:i];
	CFRelease(i); // balances didReceiveItem:
}

- (BOOL) isItemSavedElsewhere:(MvrItem *)i;
{
	return ![itemsBeingSaved containsObject:i];
}

- (NSString*) accessibilityLabelForItem:(id)i;
{
	return @"Image";
}

#pragma mark -
#pragma mark Visor

- (MvrItemAction*) mainActionForItem:(id)i;
{
	return [self showAction];
}

- (void) performShowOrOpenAction:(MvrItemAction *)showOrOpen withItem:(id)i;
{
	MvrImageVisor* visor = [MvrImageVisor modalVisorWithItem:i];
	[MvrApp() presentModalViewController:visor];
}

#pragma mark -
#pragma mark More actions

- (NSArray*) additionalActionsForItem:(id)i;
{
	return [NSArray arrayWithObjects:
			[self clipboardAction],
			[self sendByEmailAction],
			[MvrSwapKitSendToAction sendToAction],
			nil];
}

- (void) performCopyAction:(MvrItemAction *)copy withItem:(MvrImageItem*)i;
{
	UIPasteboard* p = [UIPasteboard generalPasteboard];
	[p setData:UIImagePNGRepresentation(i.image) forPasteboardType:(id) kUTTypePNG];
}

@end
