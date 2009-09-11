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

@implementation MvrVideoItem

+ (NSArray*) supportedTypes;
{
	return [NSArray arrayWithObject:(id) kUTTypeVideo];
}

- (id) initWithPath:(NSString*) path error:(NSError**) e;
{
	if (self = [super init]) {
		MvrItemStorage* videoStorage = [MvrItemStorage itemStorageFromFileAtPath:path error:e];
		if (!videoStorage) {
			[self release]; return nil;
		}
		
		self.storage = videoStorage;
	}
	
	return self;
}

@end
