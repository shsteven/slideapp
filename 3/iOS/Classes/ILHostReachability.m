//
//  ILReachability.m
//  Mover3
//
//  Created by ∞ on 04/12/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "ILHostReachability.h"

@interface ILHostReachability ()

- (void) updateNetworkWithFlags:(SCNetworkReachabilityFlags) flags;

@end


@implementation ILHostReachability

static void ILHostReachabilityDidChangeNetworkState(SCNetworkReachabilityRef reach, SCNetworkReachabilityFlags flags, void* info) {
	// TODO
}

- (id) initWithHostAddressString:(NSString*) host;
{
	if ((self = [super init])) {
		
		reach = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [host UTF8String]);
		
		SCNetworkReachabilityContext selfContext = {0, self, NULL, NULL, &CFCopyDescription};
		SCNetworkReachabilitySetCallback(reach, &ILHostReachabilityDidChangeNetworkState, &selfContext);
		SCNetworkReachabilityScheduleWithRunLoop(reach, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopDefaultMode);
		
		SCNetworkReachabilityFlags flags;
		if (!SCNetworkReachabilityGetFlags(reach, &flags))
			[self performSelector:@selector(checkReachability) withObject:nil afterDelay:0.5];
		else
			[self updateNetworkWithFlags:flags];
		
	}
	
	return self;
}

- (void) updateNetworkWithFlags:(SCNetworkReachabilityFlags) flags;
{
	
}

@end
