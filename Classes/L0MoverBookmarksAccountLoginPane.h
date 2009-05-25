//
//  L0MoverBookmarksAccountLoginPane.h
//  Mover
//
//  Created by ∞ on 25/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface L0MoverBookmarksAccountLoginPane : UITableViewController <UITextFieldDelegate> {
	BOOL passwordOptional;
	NSString* username, * password;
}

- (id) initWithDefaultStyle;

@property(getter=isPasswordOptional) BOOL passwordOptional;
@property(copy) NSString* username;
@property(copy) NSString* password;

@end
