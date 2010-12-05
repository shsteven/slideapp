//
//  ILReachability.h
//  Mover3
//
//  Created by ∞ on 04/12/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define kILReachabilityDidChangeStateNotification @"ILReachabilityDidChangeStateNotification"

@interface ILHostReachability : NSObject {
	SCNetworkReachabilityRef reach;
}

@end

@protocol ILHostReachabilityDelegate <NSObject>

- (void) hostReachabilityDidChange:(ILHostReachability*) reach;

@end
