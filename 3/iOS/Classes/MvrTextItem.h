//
//  MvrTextItem.h
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Network+Storage/MvrItem.h"

@interface MvrTextItem : MvrItem {

}

- (id) initWithText:(NSString*) text;
@property(copy, readonly) NSString* text;

@end
