//
//  L0BeamableImage.m
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0ImageItem.h"
#import "MvrStorageCentral.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <MuiKit/MuiKit.h>

@implementation L0ImageItem

+ (NSArray*) supportedTypes;
{
	return [NSArray arrayWithObjects:
			(id) kUTTypeTIFF,
			(id) kUTTypeJPEG,
			(id) kUTTypeGIF,
			(id) kUTTypePNG,
			(id) kUTTypeBMP,
			(id) kUTTypeICO,
			nil];
}

- (BOOL) allowsSendingFromOffloadedFile;
{
	return YES;
}

- (NSData*) produceExternalRepresentation;
{	
	return UIImageJPEGRepresentation([self.image imageByRenderingRotation], 0.8);
}

- (id) initWithTitle:(NSString*) ti image:(UIImage*) img;
{
	if (self = [super init]) {
		self.title = ti;
		self.image = img;
		self.type = (id) kUTTypeJPEG;
	}
	
	return self;
}

- (UIImage*) representingImage;
{
	UIImage* storedImage = [super representingImage];
	if (!storedImage) {
		storedImage = [self.image imageByRenderingRotationAndScalingWithMaximumSide:130.0];
		self.representingImage = storedImage;
	}
	
	return storedImage;
}

- (id) initWithStorage:(MvrItemStorage *)s type:(NSString *)ty title:(NSString *)ti;
{
	if (self = [super initWithStorage:s type:ty title:ti]) {
		UIImage* img = [UIImage imageWithContentsOfFile:storage.path];
		
		if (!img) {
			[self release];
			return nil;
		}
		
		self.image = img;
	}
	
	return self;
}

- (void) storeToAppropriateApplication;
{
	UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, NULL);
}

- (void) clearCache;
{
	L0Log(@"%@", self);
	self.image = nil;
	[super clearCache];
}

@synthesize image;
- (UIImage*) image;
{
	if (!image) {
		L0Log(@"Caching from storage: %@", self.storage);
		self.image = [UIImage imageWithContentsOfFile:self.storage.path];
	}
	
	return image;
}

- (void) dealloc;
{
	[image release];
	[super dealloc];
}

@end
