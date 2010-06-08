//
//  MvrTellAFriendController.h
//  Mover3
//
//  Created by ∞ on 12/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@interface MvrTellAFriendController : NSObject <MFMailComposeViewControllerDelegate> {

}

@property(readonly) BOOL canTellAFriend;

- (void) start;

@end
