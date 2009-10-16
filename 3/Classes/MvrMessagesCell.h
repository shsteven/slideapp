//
//  MvrMessagesCell.h
//  Mover3
//
//  Created by ∞ on 16/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MuiKit/MuiKit.h>

@interface MvrMessagesCell : UITableViewCell {
	L0KVODispatcher* kvo;
	BOOL hadOptIn;
}

@end
