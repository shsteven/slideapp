//
//  MvrTableController.h
//  Mover3
//
//  Created by ∞ on 18/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MvrTableController : NSObject {
	UIView* hostView;
	
	UIView* backdropStratum;
	UIView* slidesStratum;
}

@property(retain) IBOutlet UIView* hostView;

@property(retain) IBOutlet UIView* backdropStratum;
@property(retain) UIView* slidesStratum;

@end
