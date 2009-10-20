//
//  MvrBTDebugTracker.h
//  Mover3
//
//  Created by ∞ on 20/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMvrBTTrackConnections 1

#if DEBUG && kMvrBTTrackConnections
#define MvrBTTrack(x, ...) [[MvrBTDebugTracker sharedTracker] track:([NSString stringWithFormat:x, ## __VA_ARGS__]) from:self at:__func__]
#define MvrBTCTrack(x, ...) [[MvrBTDebugTracker sharedTracker] track:([NSString stringWithFormat:x, ## __VA_ARGS__]) from:nil at:__func__]
#define MvrBTTrackEnd() [[MvrBTDebugTracker sharedTracker] endTrackingFrom:self at:__func__]
#define MvrBTCTrackEnd() [[MvrBTDebugTracker sharedTracker] endTrackingFrom:nil at:__func__]
#else
#define MvrBTTrack(...) L0Log(__VA_ARGS__)
#define MvrBTCTrack(...) L0CLog(__VA_ARGS__)
#define MvrBTTrackEnd() L0Log(@"Tracking for connection ended.")
#define MvrBTCTrackEnd() L0CLog(@"Tracking for connection ended.")
#endif

#if DEBUG && kMvrBTTrackConnections

@interface MvrBTDebugTracker : NSObject {
	NSFileHandle* file;
	NSDate* lastTrackingTime;
}

+ sharedTracker;

- (void) track:(NSString*) track from:(id) object at:(const char*) function;
- (void) endTrackingFrom:(id) object at:(const char*) function;

@end

#endif