//
//  L0BeamableItem.h
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdint.h>

#import "BLIP.h"

@class MvrItemStorage;


@interface L0MoverItem : NSObject {
	MvrItemStorage* storage;

	NSString* title;
	NSString* type;
	UIImage* representingImage;	
}

+ (void) registerClass;

+ (void) registerClass:(Class) c forType:(NSString*) type;
+ (Class) classForType:(NSString*) c;

@property(copy) NSString* title;
@property(copy) NSString* type;
@property(retain) UIImage* representingImage;

// Funnels

+ (NSArray*) supportedTypes;
- (NSData*) produceExternalRepresentation;
- (id) initWithStorage:(MvrItemStorage*) s type:(NSString*) ty title:(NSString*) ti;

- (void) storeToAppropriateApplication;

// Persistance methods.
+ itemWithStorage:(MvrItemStorage*) storage type:(NSString*) type title:(NSString*) title;
@property(readonly, retain) MvrItemStorage* storage;

- (void) clearCache;

@end

@interface L0MoverItem (L0BLIPBeaming)

- (BLIPRequest*) contentsAsBLIPRequest;
+ (id) itemWithContentsOfBLIPRequest:(BLIPRequest*) req;

@end
