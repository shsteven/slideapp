//
//  MvrModernWiFiChannel.h
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MvrChannel.h"

@interface MvrModernWiFiChannel : NSObject <MvrChannel> {
	NSNetService* netService;
}

- (id) initWithNetService:(NSNetService*) ns;

- (BOOL) hasSameServiceAs:(NSNetService*) n;

@end
