//
//  MvrDirectoryWatcher.h
//  Mover3
//
//  Created by ∞ on 25/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MvrDirectoryWatcher : NSObject {
	id target;
	SEL selector;
	NSString* path;
	
	BOOL running;
}

// selector is similar to -directoryWatcherDidDetectChange:.
- initForDirectoryAtPath:(NSString*) path target:(id) target selector:(SEL) selector;

- (void) start;
- (void) stop;

@end
