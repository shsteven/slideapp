//
//  MvrItem+UnidentifiedFileAdding.m
//  Mover3
//
//  Created by ∞ on 15/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrItem+UnidentifiedFileAdding.h"


@implementation MvrItem (MvrUnidentifiedFileAdding)

+ (MvrItem*) itemForUnidentifiedFileAtPath:(NSString*) path options:(MvrItemStorageOptions) options;
{
	id type = [NSMakeCollectable(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef) [path pathExtension], NULL)) autorelease];
	
	if (!type)
		type = [[MvrItem typesForFallbackPathExtension:[path pathExtension]] anyObject];
	
	if (!type)
		type = (id) kUTTypeData;
	
	NSError* e;
	MvrItemStorage* s = [MvrItemStorage itemStorageFromFileAtPath:path options:options error:&e];
	if (!s) {
		L0LogAlways(@"Could not create item storage (options = %d) for file at path %@: error %@", (int) options, path, e);
		return nil;
	}
	
	NSDictionary* m = [NSDictionary dictionaryWithObjectsAndKeys:
					   [path lastPathComponent], kMvrItemOriginalFilenameMetadataKey,
					   [[NSFileManager defaultManager] displayNameAtPath:path], kMvrItemTitleMetadataKey,
					   nil];
	
	return [MvrItem itemWithStorage:s type:type metadata:m];
}

@end
