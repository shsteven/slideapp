//
//  MvrProgressReportPart.h
//  Mover3
//
//  Created by ∞ on 19/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ILPartController.h"

#import <MuiKit/MuiKit.h>
#import "Network+Storage/MvrScannerObserver.h"

enum {
	kMvrProgressStateReceiving = 1 << 0,
	kMvrProgressStateSending = 1 << 1,
};
typedef NSInteger MvrProgressState;

@protocol MvrProgressReportPartDelegate;

@interface MvrProgressReportPart : ILPartController <MvrScannerObserverDelegate> {
	L0KVODispatcher* kvo;
	MvrScannerObserver* observer;
	
	IBOutlet UIProgressView* progressBar;
	IBOutlet UILabel* stateLabel;
	
	id <MvrProgressReportPartDelegate> delegate;
	
	NSInteger currentlyRunningTransfers;
}

@property(readonly) MvrProgressState progressState;
@property(readonly) BOOL shouldDisplay;

@property(assign) id <MvrProgressReportPartDelegate> delegate;

@end


@protocol MvrProgressReportPartDelegate

- (void) progressReportPartShouldDisplay:(MvrProgressReportPart*) part;
- (void) progressReportPartShouldHide:(MvrProgressReportPart*) part;

@end
