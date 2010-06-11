//
//  MvrVideoItem.m
//  Mover3
//
//  Created by ∞ on 01/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrVideoItem.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrUTISupport.h"

@interface MvrVideoItem ()

+ (NSString*) extensionForType:(NSString *)type;
+ (NSString*) typeForPath:(NSString*) path;
+ (BOOL) fixExtensionOfPathOfStorage:(MvrItemStorage*) s type:(NSString*) t error:(NSError**) e;

@end


@implementation MvrVideoItem

+ supportedTypes;
{
	return [NSSet setWithObjects:
			(id) kUTTypeQuickTimeMovie,
			(id) kUTTypeMPEG4,
			@"com.apple.protected-mpeg-4-video",
			nil];
}

+ itemWithVideoAtPath:(NSString*) p type:(NSString*) t error:(NSError**) e;
{
	MvrItemStorage* s = [MvrItemStorage itemStorageFromFileAtPath:p error:e];
	if (!s)
		return nil;
	
	if ([t isEqual:(id) kUTTypeMovie])
		t = [self typeForPath:p];
	if (!t)
		return nil;
	
	if (![self fixExtensionOfPathOfStorage:s type:t error:e])
		return nil;
	
	id me = [[[self alloc] initWithStorage:s type:t metadata:nil] autorelease];
	[me setObject:[NSNumber numberWithBool:YES] forItemNotesKey:kMvrVideoItemDidSave];
	return me;
}

- (id) initWithStorage:(MvrItemStorage *)s type:(NSString *)t metadata:(NSDictionary *)m;
{
	if (self = [super initWithStorage:s type:t metadata:m]) {
		if (![[self class] fixExtensionOfPathOfStorage:self.storage type:t error:NULL]) {
			[self release];
			return nil;
		}
	}
	
	return self;
}

+ (BOOL) fixExtensionOfPathOfStorage:(MvrItemStorage*) s type:(NSString*) t error:(NSError**) e;
{
	if (![[s.path pathExtension] isEqual:@""])
		return YES;
	
	NSError* errorHandledByUs;
	if (![s setPathExtensionAssumingType:t error:&errorHandledByUs]) {
		if (e) *e = errorHandledByUs;
		BOOL didNotGetExtension = ([[errorHandledByUs domain] isEqual:kMvrItemStorageErrorDomain] && [errorHandledByUs code] == kMvrItemStorageNoFilenameExtensionForTypeError),
		shouldContinue = didNotGetExtension;
		
		if (didNotGetExtension) {
			NSString* ext = [self extensionForType:t];
			
			if (!ext) {
				if (e) *e = [NSError errorWithDomain:kMvrItemStorageErrorDomain code:kMvrItemStorageNoFilenameExtensionForTypeError userInfo:nil];
				shouldContinue = NO;
			} else 				
				shouldContinue = [s setPathExtension:ext error:e];
		}
		
		return shouldContinue;
	} else
		return YES;
}

+ (NSString*) typeForPath:(NSString*) path;
{
	NSString* ext = [path pathExtension];
	if ([ext isEqual:@""])
		return nil;
	
	CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef) ext, kUTTypeMovie);
	
	return uti? [NSMakeCollectable(uti) autorelease] : nil;
}

+ (NSString*) extensionForType:(NSString*) t;
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
