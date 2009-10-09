//
//  MvrImageItem.h
//  Mover3
//
//  Created by ∞ on 21/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Network+Storage/MvrItem.h"

@class L0KVODispatcher;

@interface MvrImageItem : MvrItem {
	BOOL observingPath;
	L0KVODispatcher* dispatcher;
}

- (id) initWithImage:(UIImage*) image type:(NSString*) t;
@property(retain) UIImage* image;

@end
