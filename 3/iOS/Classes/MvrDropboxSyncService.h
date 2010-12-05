//
//  MvrDropboxSyncService.h
//  Mover3
//
//  Created by ∞ on 04/11/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrSyncService.h"
#import "DBSession.h"

@class DBLoginController, UIViewController, UINavigationController;

#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
	#import "DBLoginController.h"

	#define MvrDropboxSync_DBLoginControllerDelegate() DBLoginControllerDelegate,
#else
	#define MvrDropboxSync_DBLoginControllerDelegate()
#endif


#define kMvrDropboxSyncPathKey @"MvrDropboxSyncPath"

@interface MvrDropboxSyncService : MvrSyncService <MvrDropboxSync_DBLoginControllerDelegate() DBSessionDelegate>
{
	DBLoginController* loginController; UINavigationController* modalLoginController;
}

+ (void) setUpSharedSessionWithKey:(NSString*) key secret:(NSString*) secret;
+ sharedDropboxSyncService;

- (void) didChangeDropboxAccountLinkState;

@property(readonly, getter=isLinked) BOOL linked;
- (void) unlink;

#if TARGET_OS_IPHONE
@property(readonly) UIViewController* loginController;
#endif

@end
