//
//  MvrVideoItem.h
//  Mover3
//
//  Created by ∞ on 01/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Network+Storage/MvrItem.h"

@interface MvrVideoItem : MvrItem {

}

- (id) initWithVideoAtPath:(NSString*) p type:(NSString*) t error:(NSError**) e;

@end
