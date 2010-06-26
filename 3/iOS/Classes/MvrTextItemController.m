//
//  MvrTextItemController.m
//  Mover3
//
//  Created by ∞ on 25/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrTextItemController.h"
#import "MvrTextVisor.h"
#import "MvrAppDelegate_iPad.h"
#import "MvrItemAction.h"

@implementation MvrTextItemController

+ (NSSet *) supportedItemClasses;
{
	return [NSSet setWithObject:[MvrTextItem class]];
}

- (void) viewDidLoad;
{
	[super viewDidLoad];
	
	[self addManagedOutletKeys:
	 @"stickyNoteView",
	 @"titleView",
	 @"contentView",
	 nil];
	
	MvrDraggableView* dv = self.draggableView;
	
	CGRect bounds = stickyNoteView.frame;
	self.actionButton.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds) + 2);
	[dv addSubview:self.actionButton];
	[dv bringSubviewToFront:self.actionButton];
	
	dv.draggingDisabledOnScrollViews = YES;
}

- (void) itemDidChange;
{
	if (self.item) {
		
		if (titleView)
			titleView.text = [NSString stringWithFormat:@"\u201c%@\u201d", [self.item title]];
		
		if (contentView) {
			contentView.text = [self.item text];
			
			CGSize s = CGSizeMake(contentView.bounds.size.width, CGFLOAT_MAX);
			CGSize textSize = [contentView.text sizeWithFont:contentView.font constrainedToSize:s lineBreakMode:UILineBreakModeWordWrap];
			
			contentView.scrollEnabled = (textSize.height > contentView.bounds.size.height);
		}
	}
}

- (void) setActionButtonHidden:(BOOL)hidden animated:(BOOL)animated;
{
	[super setActionButtonHidden:hidden animated:animated];
	
	if (titleView) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:animated? (hidden? 0.5 : 0.2) : 0];
	
		titleView.alpha = hidden? 1.0 : 0.0;
		
		[UIView commitAnimations];
	}
}

- (NSArray *) defaultActions;
{
	return [NSArray arrayWithObjects:
			[MvrItemAction actionWithDisplayName:NSLocalizedString(@"Show", @"Show action") block:^(MvrItem* i) {
				
				UIViewController* visor = [MvrTextVisor modalVisorWithItem:i];
				visor.modalPresentationStyle = UIModalPresentationPageSheet;
				[MvrApp_iPad() presentModalViewController:visor];
				
			}],
			
			[MvrItemAction actionWithDisplayName:NSLocalizedString(@"Copy", @"Copy action") block:^(MvrItem* i) {
		
				[UIPasteboard generalPasteboard].string = [(MvrTextItem*)i text];
		
			}],
			
			[self showOpeningOptionsMenuAction],
			nil];
}

- (void) didPrepareDocumentInteractionController:(UIDocumentInteractionController *)d;
{
	[super didPrepareDocumentInteractionController:d];
	d.UTI = (id) kUTTypeText;
}

@end
