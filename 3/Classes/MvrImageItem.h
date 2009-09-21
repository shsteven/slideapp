//
//  MvrImageItem.h
//  Mover3
//
//  Created by ∞ on 21/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Network+Storage/MvrItem.h"

@interface MvrImageItem : MvrItem {
	
}

- (id) initWithImage:(UIImage*) image type:(NSString*) t;
@property(retain) UIImage* image;

@end
