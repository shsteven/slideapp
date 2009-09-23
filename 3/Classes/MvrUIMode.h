//
//  MvrUIMode.h
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrArrowsView.h"

@interface MvrUIMode : NSObject {
	UIView* backdropStratum;
	UIView* arrowsStratum;
	
	NSMutableArray* destinations;
	id northDestination, eastDestination, westDestination;
	
}

@property(retain) IBOutlet UIView* backdropStratum;
@property(retain) IBOutlet UIView* arrowsStratum;
@property(readonly) MvrArrowsView* arrowsView;

@property(readonly) NSMutableArray* mutableDestinations;
- (NSString*) displayNameForDestination:(id) destination;

@end
