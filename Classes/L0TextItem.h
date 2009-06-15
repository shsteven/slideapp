//
//  L0TextItem.h
//  Mover
//
//  Created by ∞ on 15/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L0MoverItem.h"

@interface L0TextItem : L0MoverItem {
	NSString* text;
}

- (id) initWithText:(NSString*) text;
@property(readonly, copy) NSString* text;

@end
