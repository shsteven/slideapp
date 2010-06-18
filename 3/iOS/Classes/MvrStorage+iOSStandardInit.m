//
//  MvrStorage+iOSStandardInit.m
//  Mover3
//
//  Created by ∞ on 18/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrStorage+iOSStandardInit.h"


@implementation MvrStorage (MvriOSStandardInit)

+ iOSStorage;
{
#warning TODO support Open /Mover Items subdirectory
	NSString* docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString* metaDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	metaDir = [metaDir stringByAppendingPathComponent:@"Mover Metadata"];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	
	if (![fm fileExistsAtPath:docsDir])
		ILAssertNoNSError(e, [fm createDirectoryAtPath:docsDir withIntermediateDirectories:YES attributes:nil error:&e]);
	
	if (![fm fileExistsAtPath:metaDir])
		ILAssertNoNSError(e, [fm createDirectoryAtPath:metaDir withIntermediateDirectories:YES attributes:nil error:&e]);
	
	return [[[self alloc] initWithItemsDirectory:docsDir metadataDirectory:metaDir] autorelease];
}

@end
