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
#import "MvrPhotoLibrarySource.h"

@implementation MvrImageItemUI

+ supportedItemClasses;
{
	return [NSSet setWithObject:[MvrImageItem class]];
}

+ supportedItemSources;
{
	return [NSArray arrayWithObject:[MvrPhotoLibrarySource sharedSource]];
}

- (UIImage*) representingImageWithSize:(CGSize) size forItem:(id) i;
{
	UIImage* original = [i image];
	return [original imageByRenderingRotationAndScalingWithMaximumSide:MAX(size.width, size.height)];
}

- (void) didReceiveItem:(MvrItem*) i;
{
	UIImageWriteToSavedPhotosAlbum(((MvrImageItem*)i).image, nil, NULL, NULL);
}

@end
