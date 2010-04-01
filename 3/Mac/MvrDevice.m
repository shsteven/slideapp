//
//  MvrDevice.m
//  MoverWaypoint
//
//  Created by ∞ on 26/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "MvrDevice.h"

#import "Network+Storage/MvrProtocol.h"
#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrIncoming.h"
#import "Network+Storage/MvrOutgoing.h"

#import <QuartzCore/QuartzCore.h>
#import <MuiKit/MuiKit.h>

#import "MvrTransferController.h"

@interface MvrDeviceItem ()

- (void) animateMiniSlide;

- (CGFloat) currentProgress;
- (void) updateBar;

@end


@implementation MvrDeviceItem

- (id) initWithChannel:(id <MvrChannel>) chan;
{
	if (self = [super initWithNibName:@"MvrDeviceItem" bundle:nil]) {
		self.channel = chan;	
		kvo = [[L0KVODispatcher alloc] initWithTarget:self];
		
		[kvo observe:@"incomingTransfers" ofObject:self.channel usingSelector:@selector(transfersOf:didChange:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionPrior];
		[kvo observe:@"outgoingTransfers" ofObject:self.channel usingSelector:@selector(transfersOf:didChange:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionPrior];
	}
		
	return self;
}

- (void) transfersOf:(id) chan didChange:(NSDictionary*) change;
{
	if ([[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
		[self willChangeValueForKey:@"currentProgress"];
		return;
	}
	
	BOOL hasNewOnes = NO;
	for (id t in L0KVOChangedValue(change)) {
		[kvo observe:@"progress" ofObject:t usingSelector:@selector(progressOfTransfer:didChange:) options:NSKeyValueObservingOptionPrior];
		hasNewOnes = YES;
	}
	
	for (id t in L0KVOPreviousValue(change)) {
		[kvo endObserving:@"progress" ofObject:t];
	}
	
	transfersHappening = hasNewOnes || [self.channel.outgoingTransfers count] > 0 || [self.channel.incomingTransfers count] > 0;
	
	if (transfersHappening) {
		[spinnerView setHidden:NO];
		[spinner setHidden:NO];
		[spinner setIndeterminate:YES];
		[spinner startAnimation:self];
	} else {
		[spinner stopAnimation:self];
		[spinner setHidden:YES];
		[spinnerView setHidden:YES];		
	}
	
	[self didChangeValueForKey:@"currentProgress"];
	[self updateBar]; // grrr
}

- (void) progressOfTransfer:(id) transfer didChange:(NSDictionary*) change;
{
	if ([[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
		[self willChangeValueForKey:@"currentProgress"];
		return;
	}
	
	[self didChangeValueForKey:@"currentProgress"];
	[self updateBar]; // grrr
}

- (void) updateBar;
{
	CGFloat f = [self currentProgress];
	if (f != kMvrIndeterminateProgress && f >= 0.1) {
		[spinner setDoubleValue:f];
		[spinner setIndeterminate:NO];
	}
}

- (CGFloat) currentProgress;
{
	CGFloat progressSum = 0.0;
	
	NSMutableArray* a = [NSMutableArray array];
	[a addObjectsFromArray:[self.channel.outgoingTransfers allObjects]];
	[a addObjectsFromArray:[self.channel.incomingTransfers allObjects]];
	L0Log(@"Considering all of %@", a);
	
	for (id t in a) {
		L0Log(@"Considering %@.progress (%f)", t, (double) [t progress]);
		if ([t progress] == kMvrIndeterminateProgress) {
			L0Log(@"Indeterminate. Returning.");
			return kMvrIndeterminateProgress;
		}
		
		progressSum += [t progress];
	}
	
	L0Log(@"Will return %f divided by %d (indeterminate if 0)", (double) progressSum, (int) [a count]);
	
	if ([a count] > 0)
		return progressSum / (CGFloat) [a count];
	else
		return kMvrIndeterminateProgress;
}



- (void) awakeFromNib;
{
	[self.view setFrame:NSMakeRect(0, 0, 155, 140)];
	
	NSTrackingArea* area = [[NSTrackingArea alloc] initWithRect:self.view.bounds options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp owner:self userInfo:nil];
	[self.view addTrackingArea:area];
	
	[spinner stopAnimation:self];
	[spinnerView setHidden:YES];
}

- (void) mouseEntered:(NSEvent *)theEvent;
{
	[self performSelector:@selector(showProgressWindow) withObject:nil afterDelay:1.0];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideProgressWindow) object:nil];
}

- (void) mouseExited:(NSEvent *)theEvent;
{
	[self performSelector:@selector(hideProgressWindow) withObject:nil afterDelay:1.0];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showProgressWindow) object:nil];	
}

- (void) sendItemFile:(NSString *)file;
{
	[[MvrTransferController transferController] sendItemFile:file throughChannel:self.channel];
	[self animateMiniSlide];
}

@synthesize channel;
@dynamic view;


#pragma mark Animation

- (void) animateMiniSlide;
{
	NSImageView* iv = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)];
	[iv setImageScaling:NSImageScaleProportionallyUpOrDown];
	[iv setImage:[NSImage imageNamed:@"MiniSlide"]];
	[iv setWantsLayer:YES];	
	[iv setHidden:YES];
	[self.view addSubview:iv positioned:NSWindowBelow relativeTo:dropView];

	
	NSPoint origin = NSMakePoint(NSMidX([self.view bounds]) - [iv frame].size.width / 2, [self.view bounds].size.height + [iv frame].size.height);
	[iv setFrameOrigin:origin];
	
	[iv setAlphaValue:0.0];
	[iv setHidden:NO];
	
	[self performSelector:@selector(fadeMiniSlideIn:) withObject:iv afterDelay:0.001];
}

- (void) fadeMiniSlideIn:(NSImageView*) iv;
{
	[CATransaction begin];
	[CATransaction setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] forKey:kCATransactionAnimationTimingFunction];
	[CATransaction setValue:[NSNumber numberWithFloat:1.5] forKey:kCATransactionAnimationDuration];
	
	NSRect r = [iv frame];
	srandomdev();
	r.origin.y = 57; // + (random() % 20 - 10);
	
	[[iv animator] setFrameOrigin:r.origin];
	[[iv animator] setAlphaValue:1.0];
	
#define kMvrMaximumAngleRange (30)
	srandomdev();
	CGFloat angle = ((random() % kMvrMaximumAngleRange) - kMvrMaximumAngleRange / 2.0) * M_PI/180.0;
	[iv layer].transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(angle));
	
	
	[CATransaction commit];
	
	[self performSelector:@selector(fadeSlideOut:) withObject:iv afterDelay:7.0];
}

- (void) fadeSlideOut:(NSImageView*) iv;
{
	[CATransaction begin];
	[CATransaction setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] forKey:kCATransactionAnimationTimingFunction];
	[CATransaction setValue:[NSNumber numberWithFloat:3.0] forKey:kCATransactionAnimationDuration];
	
	[[iv animator] setAlphaValue:0.0];
	
	[CATransaction commit];
	
	
	[iv performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:4.0];
}

@end


@interface MvrDeviceDropDestinationView ()

- (NSDragOperation) updateAndReturnOperationForDragWithInfo:(id <NSDraggingInfo>)sender;

@end


@implementation MvrDeviceDropDestinationView

@synthesize owner;

- (void) awakeFromNib;
{
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]]; // TODO more types?
}

- (void) setDragging:(BOOL) d;
{
	dragging = d;
	[self setNeedsDisplay:YES];
}

- (void) drawRect:(NSRect)dirtyRect;
{
	if (dragging) {
		[[[NSColor selectedTextBackgroundColor] colorWithAlphaComponent:0.5] setFill]; 
		NSRectFillUsingOperation(self.bounds, NSCompositeSourceOver);
	} else
		[super drawRect:dirtyRect];
}

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>) sender;
{
	return [self updateAndReturnOperationForDragWithInfo:sender];
}

- (NSDragOperation) updateAndReturnOperationForDragWithInfo:(id <NSDraggingInfo>) sender;
{
	NSArray* files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	BOOL isDir;
	if ([files count] != 1 || ![[NSFileManager defaultManager] fileExistsAtPath:[files objectAtIndex:0] isDirectory:&isDir] || isDir) {
		[self setDragging:NO];
		return NSDragOperationNone;
	} else {
		[self setDragging:YES];
		return NSDragOperationCopy;
	}
}

- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>) sender;
{
	return [self updateAndReturnOperationForDragWithInfo:sender];
}

- (void) draggingExited:(id <NSDraggingInfo>)sender;
{
	[self setDragging:NO];
}

- (void) draggingEnded:(id <NSDraggingInfo>) sender;
{
	[self setDragging:NO];
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender;
{
	NSArray* files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	return [files count] == 1;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender;
{
	[self.owner sendItemFile:[[[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType] objectAtIndex:0]];
	return YES;
}

@end

@implementation MvrDeviceBaseView

- (NSView *) hitTest:(NSPoint)aPoint;
{
	return nil;
}

@end
