//
//  PLActionSheet.h
//
//  Created by Landon Fuller on 7/3/09.
//  Copyright 2009 Plausible Labs Cooperative, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * A simple block-enabled API wrapper on top of UIActionSheet.
 */
@interface PLActionSheet : NSObject <UIActionSheetDelegate> {
@private
    UIActionSheet *_sheet;
    NSMutableArray *_blocks;
	void (^_cancelledBlock)();
	void (^_finishedBlock)();
	
	BOOL _cleanedUp;
}

- (void) addButtonWithTitle: (NSString *) title action: (void (^)()) block;

- (void) addCancelButtonWithTitle: (NSString *) title action: (void (^)()) block;
- (void) addDestructiveButtonWithTitle:(NSString*) title action:(void (^)()) block;

- (void) showInView: (UIView *) view;

- (void) showFromBarButtonItem:(UIBarButtonItem*) bi animated:(BOOL) ani;
- (void) showFromRect:(CGRect) r inView:(UIView*) v animated:(BOOL) ani;

- (void) setCancelledAction:(void (^)()) block;
- (void) setFinishedAction:(void (^)()) finished;

@property(nonatomic, readonly) UIActionSheet* sheet;

@end
