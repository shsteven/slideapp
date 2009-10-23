//
//  MvrMorePane.h
//  Mover3
//
//  Created by ∞ on 16/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MvrMorePane : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	NSArray* cellsBySection;
	UITableView* table;
}

@property(readonly) UITableView* tableView;

@end

extern UIView* MvrWhiteSectionFooterView(NSString* footerText, UITableView* tableView, UILineBreakMode footerLineBreakMode, UIFont* footerFont);
extern CGFloat MvrWhiteSectionFooterHeight(NSString* footerText, UITableView* tableView, UILineBreakMode footerLineBreakMode, UIFont* footerFont);

extern UIFont* MvrWhiteSectionFooterDefaultFont();

#define kMvrWhiteSectionDefaultTopBottomMargin (20.0)
#define kMvrWhiteSectionDefaultLineBreakMode (UILineBreakModeWordWrap)