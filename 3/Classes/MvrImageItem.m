//
//  MvrImageItem.m
//  Mover3
//
//  Created by ∞ on 21/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrImageItem.h"

#import "Network+Storage/MvrUTISupport.h"
#import "Network+Storage/MvrItemStorage.h"

@implementation MvrImageItem

- (id) initWithImage:(UIImage*) image type:(NSString*) t;
{
	self = [super init];
	if (self != nil) {
		self.image = image;
		self.type = t;
	}
	
	return self;
}

- (UIImage*) image;
{
	return [self cachedObjectForKey:@"image"];
}

- (void) setImage:(UIImage *) i;
{
	[self setCachedObject:i forKey:@"image"];
}

- objectForEmptyImageCacheKey;
{
	[self.storage setPathExtensionAssumingType:self.type error:NULL];
	return [UIImage imageWithContentsOfFile:self.storage.path];
}

// -- - --

+ supportedTypes;
{
	return [NSSet setWithObjects:
			(id) kUTTypeTIFF,
			(id) kUTTypeJPEG,
			(id) kUTTypeGIF,
			(id) kUTTypePNG,
			(id) kUTTypeBMP,
			(id) kUTTypeICO,
			nil];
}

- (NSData*) produceExternalRepresentation;
{
	if ([self.type isEqual:(id) kUTTypePNG])
		return UIImagePNGRepresentation(self.image);
	else if ([self.type isEqual:(id) kUTTypeJPEG])
		return UIImageJPEGRepresentation(self.image, 0.7);
	else {
		[NSException raise:@"MvrImageItemCannotProduceTypeException" format:@"%@ cannot produce an external representation for type %@.", self, self.type];
		return nil;
	}
}

@end
