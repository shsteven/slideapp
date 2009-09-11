//
//  MvrVideoItem.h
//  Mover
//
//  Created by ∞ on 11/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L0MoverItem.h"

enum {
	kMvrVideoItemUnsupportedTypeForFileError = 1,
};
extern NSString* const kMvrVideoItemErrorDomain;

@interface MvrVideoItem : L0MoverItem {}

- (id) initWithPath:(NSString*) path error:(NSError**) e;

@end
