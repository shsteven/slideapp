//
//  MvrDirectoryWatcher.m
//  Mover3
//
//  Created by ∞ on 25/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrDirectoryWatcher.h"

#import <fcntl.h>
#import <sys/types.h>
#import <sys/event.h>
#import <sys/time.h>
#import <stdio.h>
#import <unistd.h>

@interface MvrDirectoryWatcher ()

- (BOOL) shouldKeepRunning;

@end


@implementation MvrDirectoryWatcher

- initForDirectoryAtPath:(NSString*) p target:(id) t selector:(SEL) s;
{
	if ((self = [super init])) {
		path = [p copy];
		target = t;
		selector = s;
	}
	
	return self;
}

- (void) dealloc
{
	[path release];
	[super dealloc];
}


- (void) start;
{	
	@synchronized(self) {
		if (running)
			return;
		
		running = YES;
	}
	
	// [NSThread detachNewThreadSelector:@selector(runKQueueToMonitorDirectory:) toTarget:self withObject:path];
	NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(runKQueueToMonitorDirectory:) object:path] autorelease];
	
	[thread setName:[NSString stringWithFormat:@"%@ (watching %@)", [self class], path]];
	
	[thread start];
}

- (BOOL) shouldKeepRunning;
{
	BOOL d;
	@synchronized(self) {
		d = running;
	}
	return d;
}

- (void) stop;
{
	@synchronized(self) {
		running = NO;
	}
}

- (void) runKQueueToMonitorDirectory:(NSString*) dir;
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	int fdes = -1, kq = -1;
	
	fdes = open([dir fileSystemRepresentation], O_RDONLY);
	if (fdes == -1)
		goto cleanup;
	
	kq = kqueue();
	if (kq == -1)
		goto cleanup;
	
	struct kevent toMonitor;
	EV_SET(&toMonitor, fdes, EVFILT_VNODE, EV_ADD | EV_ENABLE | EV_ONESHOT,
		   NOTE_WRITE | NOTE_EXTEND | NOTE_DELETE | NOTE_LINK | NOTE_RENAME | NOTE_REVOKE,
		   0, 0);
	
	while ([self shouldKeepRunning]) {
		NSAutoreleasePool* innerPool = [NSAutoreleasePool new];
		
		const struct timespec time = { 10, 0 };
		struct kevent event;
		
		int result = kevent(kq, &toMonitor, 1, &event, 1, &time);
		
		if (result > 0)
			[target performSelectorOnMainThread:selector withObject:nil waitUntilDone:NO];
		
		[innerPool release];
		
		if (result == -1)
			break;
	}
	
cleanup:
	if (kq != -1)
		close(kq);
	
	if (fdes != -1)
		close(fdes);
	
	[pool release];
}

@end

