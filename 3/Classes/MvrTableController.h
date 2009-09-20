//
//  MvrTableController.h
//  Mover3
//
//  Created by ∞ on 18/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MuiKit/MuiKit.h>

#import "MvrSlidesView.h"

@interface MvrTableController : NSObject <MvrSlidesViewDelegate> {
	UIView* hostView;
	
	UIView* backdropStratum;
	MvrSlidesView* slidesStratum;
	
	L0Map* itemsToViews;
	L0KVODispatcher* kvo;
}

- (void) setUp;

@property(retain) IBOutlet UIView* hostView;

@property(retain) IBOutlet UIView* backdropStratum;
@property(retain) MvrSlidesView* slidesStratum;

@end
