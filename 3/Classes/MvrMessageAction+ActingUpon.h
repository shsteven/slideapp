//
//  MvrMessageAction+ActingUpon.h
//  Mover3
//
//  Created by ∞ on 14/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrMessage.h"

@interface MvrMessageAction (MvrActingUpon) 

// for in-app == NO
- (void) openURLAfterRedirects:(BOOL) reds;

// for in-app == YES
- (UIViewController*) nonmodalViewController;
- (UIViewController*) modalViewController;

@end
