//
//  MvrVideoItem.m
//  Mover3
//
//  Created by ∞ on 01/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrVideoItem.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrUTISupport.h"

@interface MvrVideoItem ()

- (NSString*) extensionForType:(NSString *)type;

@end


@implementation MvrVideoItem

+ supportedTypes;
{
	return [NSSet setWithObjects:
			(id) kUTTypeQuickTimeMovie,
			(id) kUTTypeMPEG4,
			nil];
}

- (id) initWithVideoAtPath:(NSString*) p type:(NSString*) t error:(NSError**) e;
{
	MvrItemStorage* s = [MvrItemStorage itemStorageFromFileAtPath:p error:e];
	if (!s) return nil;
	
	if (self = [self initWithStorage:s type:t metadata:nil]) {
		if (![self.storage setPathExtensionAssumingType:t error:e]) {
			BOOL didNotGetExtension = ([[*e domain] isEqual:kMvrItemStorageErrorDomain] && [*e code] == kMvrItemStorageNoFilenameExtensionForTypeError),
				shouldContinue = didNotGetExtension;
			
			if (didNotGetExtension) {
				NSString* ext = [self extensionForType:t];
				
				if (!ext) {
					*e = [NSError errorWithDomain:kMvrItemStorageErrorDomain code:kMvrItemStorageNoFilenameExtensionForTypeError userInfo:nil];
					shouldContinue = NO;
				} else 				
					shouldContinue = [self.storage setPathExtension:ext error:e];
			}
			
			if (!shouldContinue) {
				[self release];
				return nil;
			}
		}
	}
	
	return self;
}

- (NSString*) extensionForType:(NSString*) t;
{
	if ([t isEqual:(id) kUTTypeQuickTimeMovie])
		return @"mov";
	else if ([t isEqual:(id) kUTTypeMPEG4])
		return @"mp4";
	else
		return nil;
}

- (BOOL) requiresStreamSupport;
{
	return YES;
}

@end
