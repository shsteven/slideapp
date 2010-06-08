//
//  MvrImageItem.m
//  Mover3
//
//  Created by ∞ on 21/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrImageItem.h"

#import "Network+Storage/MvrUTISupport.h"
#import "Network+Storage/MvrItemStorage.h"

#import <MuiKit/MuiKit.h>

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

- (void) dealloc
{
	[dispatcher release];
	[super dealloc];
}


- (MvrItemStorage*) storage;
{
	MvrItemStorage* s = [super storage];
	
	if (!observingPath) {
		if (!dispatcher)
			dispatcher = [[L0KVODispatcher alloc] initWithTarget:self];
		[dispatcher observe:@"path" ofObject:s usingSelector:@selector(pathOfStorage:changed:) options:0];
		observingPath = YES;
	}
	
	[s setDesiredExtensionAssumingType:self.type error:NULL];
	
	return s;
}

- (void) pathOfStorage:(MvrItemStorage*) s changed:(NSDictionary*) d;
{
	L0Log(@"Path has changed, so we're killing the old UIImage object that might be primed to start with the previous path.");
	[self removeCachedObjectForKey:@"image"];
}

MvrItemSynthesizeRetainFromAutocache(UIImage*, image, setImage:)

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

+ (NSDictionary *) knownFallbackPathExtensions;
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"tiff", (id) kUTTypeTIFF,
			@"jpeg", (id) kUTTypeJPEG,
			@"gif", (id) kUTTypeGIF,
			@"png", (id) kUTTypePNG,
			@"bmp", (id) kUTTypeBMP,
			@"ico", (id) kUTTypeICO,
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
