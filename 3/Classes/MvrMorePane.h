//
//  MvrMorePane.h
//  Mover3
//
//  Created by ∞ on 16/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MvrMorePane : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	NSArray* cellsBySection;
	UITableView* table;
}

@property(readonly) UITableView* tableView;

@end
