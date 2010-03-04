//
//  MvrDevicesLineView.h
//  MoverWaypoint
//
//  Created by ∞ on 03/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MvrDevicesLineView : NSView {
	NSMutableArray* contentViewControllers;
	NSMutableArray* content;
}

@property(readonly) NSArray* contentViewControllers;
@property(copy) NSArray* content;
@property(readonly) NSMutableArray* mutableContent;

@end
