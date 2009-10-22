//
//  MvrAboutPane.h
//  Mover3
//
//  Created by ∞ on 12/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MvrAboutPane : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	IBOutlet UITableView* tableView;
	IBOutlet UIView* headerView;
	IBOutlet UIView* footerView;
	
	IBOutlet UILabel* versionLabel;
}

- (IBAction) dismiss;
- (IBAction) openSite;

+ modalPane;

@end
