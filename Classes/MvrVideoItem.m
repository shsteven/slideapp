//
//  MvrVideoItem.m
//  Mover
//
//  Created by ∞ on 11/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrVideoItem.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "MvrStorageCentral.h"

NSString* const kMvrVideoItemErrorDomain = @"net.infinite-labs.Mover.MvrVideoItemErrorDomain";

@implementation MvrVideoItem

+ (NSArray*) supportedTypes;
{
	return [NSArray arrayWithObjects:
			(id) kUTTypeQuickTimeMovie,
			(id) kUTTypeMPEG,
			(id) kUTTypeMPEG4,
			nil];
}

- (id) initWithStorage:(MvrItemStorage *)s type:(NSString *)ty title:(NSString *)ti;
{
	if (self = [super initWithStorage:s type:ty title:ti]) {
		
		NSError* e;
		BOOL done = [s setPathExtensionAssumingType:ty error:&e];
		if (!done) {
			L0Log(@"Error while setting the path extension assuming type %@: %@", ty, e);
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (id) initWithPath:(NSString*) path error:(NSError**) e;
{
	if (self = [super init]) {
		NSString* pathExt = [path pathExtension];
		CFStringRef ty = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef) pathExt, NULL);
		BOOL isOK = [[[self class] supportedTypes] containsObject:(id) ty];
		
		if (isOK)
			self.type = (id) ty;
		else if ([pathExt isEqual:@"m4v"] || [pathExt isEqual:@"mp4"]) {
			isOK = YES;
			self.type = (id) kUTTypeMPEG4;
		} else if ([pathExt isEqual:@"mov"]) {
			isOK = YES;
			self.type = (id) kUTTypeQuickTimeMovie;
		}
		
		if (ty)
			CFRelease(ty);
		
		if (!isOK) {
			if (e) *e = [NSError errorWithDomain:kMvrVideoItemErrorDomain code:kMvrVideoItemUnsupportedTypeForFileError userInfo:nil];
			[self release]; return nil;
		}

		MvrItemStorage* videoStorage = [MvrItemStorage itemStorageFromFileAtPath:path error:e];
		if (!videoStorage) {
			[self release]; return nil;
		}
		self.storage = videoStorage;
		
		self.title = @"Video";
	}
	
	return self;
}

@end
