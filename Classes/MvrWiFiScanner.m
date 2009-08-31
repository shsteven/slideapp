//
//  MvrWiFiScanner.m
//  Mover
//
//  Created by ∞ on 30/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFiScanner.h"

#import <sys/socket.h>
#import <netinet/in.h>

@interface MvrWiFiScanner ()

- (void) updateNetworkWithFlags:(SCNetworkReachabilityFlags)flags;

@end


@implementation MvrWiFiScanner

#pragma mark -
#pragma mark Reachability.

static void L0MoverWiFiNetworkStateChanged(SCNetworkReachabilityRef reach, SCNetworkReachabilityFlags flags, void* meAsPointer) {
	MvrWiFiScanner* myself = (MvrWiFiScanner*) meAsPointer;
	[NSObject cancelPreviousPerformRequestsWithTarget:myself selector:@selector(checkReachability) object:nil];
	[myself updateNetworkWithFlags:flags];
}

- (void) startMonitoringReachability;
{
	if (reach) return;
	
	// What follows comes from Reachability.m.
	// Basically, we look for reachability for the link-local address --
	// and filter for WWAN or connection-required responses in -updateNetworkWithFlags:.
	
	// Build a sockaddr_in that we can pass to the address reachability query.
	struct sockaddr_in sin;
	bzero(&sin, sizeof(sin));
	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET;
	
	// IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
	sin.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
	
	reach = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*) &sin);
	
	SCNetworkReachabilityContext selfContext = {0, self, NULL, NULL, &CFCopyDescription};
	SCNetworkReachabilitySetCallback(reach, &L0MoverWiFiNetworkStateChanged, &selfContext);
	SCNetworkReachabilityScheduleWithRunLoop(reach, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopDefaultMode);
	
	SCNetworkReachabilityFlags flags;
	if (!SCNetworkReachabilityGetFlags(reach, &flags))
		[self performSelector:@selector(checkReachability) withObject:nil afterDelay:0.5];
	else
		[self updateNetworkWithFlags:flags];
}

- (void) stopMonitoringReachability;
{
	if (!reach) return;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkReachability) object:nil];
	
	SCNetworkReachabilityUnscheduleFromRunLoop(reach, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopDefaultMode);
	CFRelease(reach); reach = NULL;
}

- (void) checkReachability;
{
	if (!reach) return;
	
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(reach, &flags))
		[self updateNetworkWithFlags:flags];
}

- (void) updateNetworkWithFlags:(SCNetworkReachabilityFlags) flags;
{
	BOOL habemusNetwork = 
	(flags & kSCNetworkReachabilityFlagsReachable) &&
	!(flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
	!(flags & kSCNetworkReachabilityFlagsIsWWAN);
	// note that unlike Reachability.m we don't care about WWANs.
	
	[self setValue:[NSNumber numberWithBool:!habemusNetwork] forKey:@"jammed"];	
}

- (void) dealloc;
{
	[self stopMonitoringReachability];
	[super dealloc];
}

@end
