//
//  MvrBTDebugTracker.m
//  Mover3
//
//  Created by ∞ on 20/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrBTDebugTracker.h"

#if DEBUG && kMvrBTTrackConnections

@implementation MvrBTDebugTracker

L0ObjCSingletonMethod(sharedTracker)

- (void) dealloc
{
	[self endTrackingFrom:self at:__func__];
	[lastTrackingTime release];
	[super dealloc];
}

- (void) track:(NSString*) track from:(id) object at:(const char*) function;
{
	if (!file) {
		NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"MvrBTDebugTracking.log"];
		BOOL done = [[NSData data] writeToFile:path options:0 error:NULL];
		NSAssert(done, @"Could create the tracking file");
		
		file = [[NSFileHandle fileHandleForWritingAtPath:path] retain];
		NSAssert(file, @"The tracking file was opened");
		
		L0LogAlways(@"Tracking a new transfer at %@", path);
		
		NSString* start = @"\n\n\n\n == !! == !! ==\nSTARTING TRACKING OF A NEW CONNECTION.\n\n";
		[file writeData:[start dataUsingEncoding:NSUTF8StringEncoding]];

		lastTrackingTime = [NSDate new];
	}
	
	NSString* toWrite = [NSString stringWithFormat:@"%@\n(at %f ms after start, in %s for %@)\n\n", track, lastTrackingTime? 0 : (double) -[lastTrackingTime timeIntervalSinceNow] * 1000.0, function, object];
	[file writeData:[toWrite dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void) endTrackingFrom:(id) object at:(const char*) function;
{
	if (!file)
		return;
	
	NSString* toWrite = [NSString stringWithFormat:@"\n== !! == !! ==\nENDING TRACKING (at %s for %@)\n", function, object];
	[file writeData:[toWrite dataUsingEncoding:NSUTF8StringEncoding]];
	
	[file synchronizeFile];
	[file closeFile];
	[file release]; file = nil;
	
	[lastTrackingTime release]; lastTrackingTime = nil;
}

@end

#endif
