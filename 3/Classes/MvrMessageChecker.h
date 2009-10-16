//
//  MvrMessageChecker.h
//  Mover3
//
//  Created by ∞ on 14/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "MvrMessage.h"
#import "MvrMessage+Showing.h"
#import "MvrMessageAction+ActingUpon.h"

@interface MvrMessageChecker : NSObject <UIAlertViewDelegate, MvrMessageDelegate> {
	NSURLConnection* connection;
	NSMutableData* receivedData;
	BOOL displayAtEndAnyway;
	BOOL isChecking;
	
	BOOL shouldRateLimitCheck;
	
	MvrMessage* lastMessage;
	
	SCNetworkReachabilityRef reach;
}

@property(readonly, copy) NSNumber* didFailLoading;
@property(readonly, copy) NSDate* lastLoadingAttempt;
@property(readonly, copy) NSDictionary* lastMessageDictionary;

@property(readonly, getter=isChecking) BOOL checking; // KVOable

@property(copy) NSNumber* userOptedInToMessages;

@property(readonly, retain) MvrMessage* lastMessage;

- (void) displayMessage;
- (void) checkOrDisplayMessage;

@end
