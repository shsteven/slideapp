//
//  MvrItem+UnidentifiedFileAdding.h
//  Mover3
//
//  Created by ∞ on 15/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"

@interface MvrItem (MvrUnidentifiedFileAdding)

+ (MvrItem*) itemForUnidentifiedFileAtPath:(NSString*) path options:(MvrItemStorageOptions) options;

@end
