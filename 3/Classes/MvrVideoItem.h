//
//  MvrVideoItem.h
//  Mover3
//
//  Created by ∞ on 01/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Network+Storage/MvrItem.h"

#define kMvrVideoItemDidSave @"MvrVideoItemDidSave"

@interface MvrVideoItem : MvrItem {

}

+ itemWithVideoAtPath:(NSString*) p type:(NSString*) t error:(NSError**) e;

@end
