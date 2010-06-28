//
//  MvrProgressReportPart.m
//  Mover3
//
//  Created by ∞ on 19/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrProgressReportPart.h"
#import "Network+Storage/MvrScanner.h"
#import "Network+Storage/MvrChannel.h"
#import "Network+Storage/MvrOutgoing.h"
#import "Network+Storage/MvrIncoming.h"
#import "Network+Storage/MvrProtocol.h"

#import "MvrAppDelegate_iPad.h"

@interface MvrProgressReportPart ()

- (void) getCurrentTransfersAverageProgress:(CGFloat*) progress state:(NSInteger*) state;
- (void) updateProgress;

@end


@implementation MvrProgressReportPart

- (MvrProgressState) progressState;
{
	MvrProgressState state;
	[self getCurrentTransfersAverageProgress:NULL state:&state];
	return state;
}

- (BOOL) shouldDisplay;
{
	return currentlyRunningTransfers > 0;
}

- (void) getCurrentTransfersAverageProgress:(CGFloat*) progress state:(NSInteger*) state;
{
	CGFloat sumOfProgresses = kMvrIndeterminateProgress;
	NSInteger newState = 0;
	
	if (currentlyRunningTransfers > 0) {
	
	
		for (id <MvrChannel> c in MvrApp_iPad().currentScanner.channels) {		
			for (id <MvrOutgoing> o in c.outgoingTransfers) {
				newState |= kMvrProgressStateSending;
				
				if (progress) {
					if (o.progress != kMvrIndeterminateProgress) {
						if (sumOfProgresses == kMvrIndeterminateProgress)
							sumOfProgresses = 0;
						sumOfProgresses += o.progress;
					}
				}
			}

			for (id <MvrIncoming> i in c.incomingTransfers) {
				newState |= kMvrProgressStateReceiving;
				
				if (progress) {
					if (i.progress != kMvrIndeterminateProgress) {
						if (sumOfProgresses == kMvrIndeterminateProgress)
							sumOfProgresses = 0;
						sumOfProgresses += i.progress;
					}
				}
			}
		}

	}
	
	if (transfersHighWaterMark > currentlyRunningTransfers)
		sumOfProgresses += 1.0 * (transfersHighWaterMark - currentlyRunningTransfers);
	
	if (progress) *progress = (transfersHighWaterMark == 0? kMvrIndeterminateProgress : sumOfProgresses / transfersHighWaterMark);
	if (state) *state = newState;
	
	L0LogDebugIf(progress, @"Reported progress of %f", *progress);
	L0LogDebugIf(state, @"Reported state of %d", *state);
}

- (void) updateProgress;
{
	NSInteger state; CGFloat progress;
	[self getCurrentTransfersAverageProgress:&progress state:&state];
	
	progressBar.progress = progress != kMvrIndeterminateProgress? progress : 0.0;
	
	NSString* stateText;
	
	if ((state & kMvrProgressStateSending) && (state & kMvrProgressStateReceiving))
		stateText = NSLocalizedString(@"Receiving & Sending\u2026", @"Receiving and sending label");
	else if (state & kMvrProgressStateSending)
		stateText = NSLocalizedString(@"Sending\u2026", @"Sending label");
	else if (state & kMvrProgressStateReceiving)
		stateText = NSLocalizedString(@"Receiving\u2026", @"Receiving label");
	else
		stateText = @"";
	
	stateLabel.text = stateText;
	
	BOOL shouldDisplay = currentlyRunningTransfers > 0;
	BOOL shown = self.viewLoaded && self.view.superview && !self.view.hidden;
	if (shouldDisplay && !shown)
		[delegate progressReportPartShouldDisplay:self];
	else if (!shouldDisplay && shown)
		[delegate progressReportPartShouldHide:self];
}

// KVO stuff.

- (id) initWithNibName:(NSString *)name bundle:(NSBundle *)b;
{
	if ((self = [super initWithNibName:name bundle:b])) {
		kvo = [[L0KVODispatcher alloc] initWithTarget:self];
		observer = [[MvrScannerObserver alloc] initWithScanner:MvrApp_iPad().currentScanner delegate:self];
				
		[kvo observe:@"currentScanner" ofObject:MvrApp_iPad() options:0 usingBlock:^(id o, NSDictionary* c) {
			
			[observer release];
			observer = [[MvrScannerObserver alloc] initWithScanner:MvrApp_iPad().currentScanner delegate:self];
			
			currentlyRunningTransfers = 0;
			[self updateProgress];
		}];
		
		[self addManagedOutletKeys:@"progressBar", @"stateLabel", nil];
	}
	
	return self;
}

- (void) viewDidLoad;
{
	[super viewDidLoad];
	self.view.userInteractionEnabled = NO;
	
	[self updateProgress];
}

- (void) dealloc
{
	[kvo release];
	[observer release];
	[super dealloc];
}

- (void) channel:(id <MvrChannel>)c didBeginSendingWithOutgoingTransfer:(id <MvrOutgoing>)outgoing;
{
	currentlyRunningTransfers++;
	transfersHighWaterMark++;
	[self updateProgress];
}

- (void) channel:(id <MvrChannel>)c didBeginReceivingWithIncomingTransfer:(id <MvrIncoming>)incoming;
{
	currentlyRunningTransfers++;
	transfersHighWaterMark++;
	[self updateProgress];
}

- (void) incomingTransfer:(id <MvrIncoming>)incoming didProgress:(float)progress;
{
	[self updateProgress];
}

- (void) outgoingTransfer:(id <MvrOutgoing>)outgoing didProgress:(float)progress;
{
	[self updateProgress];
}

- (void) outgoingTransferDidEndSending:(id <MvrOutgoing>)outgoing;
{
	currentlyRunningTransfers--;
	if (currentlyRunningTransfers == 0)
		transfersHighWaterMark = 0;
	[self updateProgress];
}

- (void) incomingTransfer:(id <MvrIncoming>)incoming didEndReceivingItem:(MvrItem *)i;
{
	currentlyRunningTransfers--;
	if (currentlyRunningTransfers == 0)
		transfersHighWaterMark = 0;
	[self updateProgress];
}

@synthesize delegate;

@end
