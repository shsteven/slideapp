//
//  PLActionSheet.m
//
//  Created by Landon Fuller on 7/3/09.
//  Copyright 2009 Plausible Labs Cooperative, Inc.. All rights reserved.
//

#import "PLActionSheet.h"


@implementation PLActionSheet

- (id) init {
    if (!(self = [super init]))
        return nil;
    
    /* Initialize the sheet */
    _sheet = [[UIActionSheet alloc] init];
	_sheet.delegate = self;

    /* Initialize button -> block array */
    _blocks = [[NSMutableArray alloc] init];

    return self;
}

- (void) dealloc {
    _sheet.delegate = nil;
    [_sheet release];

    [_blocks release];
	[_cancelledBlock release];
	[_finishedBlock release];
	
    [super dealloc];
}


- (void) addCancelButtonWithTitle: (NSString *) title action: (void (^)()) block {
    [self addButtonWithTitle: title action: block];
	[self setCancelledAction:block];
    _sheet.cancelButtonIndex = _sheet.numberOfButtons - 1;
}

- (void) addButtonWithTitle: (NSString *) title action: (void (^)()) block {
    [_blocks addObject: [[block copy] autorelease]];
    [_sheet addButtonWithTitle: title];
}

- (void) showInView: (UIView *) view {
	_cleanedUp = NO;
    [_sheet showInView: view];

    /* Ensure that the delegate (that's us) survives until the sheet is dismissed */
    [self retain];
}

- (void) actionSheet: (UIActionSheet *) actionSheet clickedButtonAtIndex: (NSInteger) buttonIndex {
    /* Run the button's block */
    if (buttonIndex >= 0 && buttonIndex < [_blocks count]) {
        void (^b)() = [_blocks objectAtIndex: buttonIndex];
        b();
    }

	if (buttonIndex == -1 && _cancelledBlock) // cancelled without picking a button
		_cancelledBlock();
	
	if (!_cleanedUp && _finishedBlock) {
		_finishedBlock();
		_cleanedUp = YES;
	}
	
    /* Sheet to be dismissed, drop our self reference */
    [self release];
}

- (void) actionSheetCancel:(UIActionSheet *)actionSheet;
{
	if (!_cleanedUp && _finishedBlock) {
		_finishedBlock();
		_cleanedUp = YES;
	}	
}

- (void) showFromBarButtonItem:(UIBarButtonItem*) bi animated:(BOOL) ani;
{
	_cleanedUp = NO;
	[_sheet showFromBarButtonItem:bi animated:ani];
	[self retain];
}

- (void) showFromRect:(CGRect) r inView:(UIView*) v animated:(BOOL) ani;
{
	_cleanedUp = NO;
	[_sheet showFromRect:r inView:v animated:ani];
	[self retain];
}

@synthesize sheet = _sheet;

- (void) setCancelledAction:(void (^)()) block;
{
	if (_cancelledBlock != block) {
		[_cancelledBlock release];
		_cancelledBlock = [block copy];
	}
}

- (void) setFinishedAction:(void (^)()) block;
{
	if (_finishedBlock != block) {
		[_finishedBlock release];
		_finishedBlock = [block copy];
	}
}

@end
