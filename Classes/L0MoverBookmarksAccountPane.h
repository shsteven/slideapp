//
//  L0MoverBookmarksAccountPane.h
//  Mover
//
//  Created by ∞ on 24/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface L0MoverBookmarksAccountPane : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	UITableView* table;
	UITableViewCell* deliciousCell;
	UITableViewCell* instapaperCell;
	
}

- (id) initWithDefaultNibName;

@property(assign) IBOutlet UITableView* table;
@property(retain) IBOutlet UITableViewCell* deliciousCell;
@property(retain) IBOutlet UITableViewCell* instapaperCell;

@end
