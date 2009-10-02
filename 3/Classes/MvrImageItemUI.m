//
//  MvrImageItemUI.m
//  Mover3
//
//  Created by ∞ on 21/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrImageItemUI.h"

#import <MuiKit/MuiKit.h>

#import "MvrImageItem.h"
#import "MvrImagePickerSource.h"

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

- (void) didReceiveItem:(MvrItem*) i;
{
	[itemsBeingSaved addObject:i];
	
	CFRetain(i); // balanced in image:didFinishSavingWithError:context:
	UIImageWriteToSavedPhotosAlbum(((MvrImageItem*)i).image, self, @selector(image:didFinishSavingWithError:context:), (void*) i);
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

@end
