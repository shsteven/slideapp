//
//  MvrBookmarkItemController.m
//  Mover3
//
//  Created by ∞ on 26/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrBookmarkItemController.h"
#import "MvrItemAction.h"

@implementation MvrBookmarkItemController

+ (NSSet *) supportedItemClasses;
{
	return [NSSet setWithObject:[MvrBookmarkItem class]];
}

- (void) viewDidLoad;
{
	[super viewDidLoad];
	
	[self addManagedOutletKeys:
	 @"addressButton",
	 @"compassImageView",
	 nil];
	
	self.actionButton.center = compassImageView.center;
	[self.view addSubview:self.actionButton];
}

- (void) itemDidChange;
{
	if (self.item) {
		
		if (addressButton) {
			NSURL* u = [(MvrBookmarkItem*)self.item address];
			NSString* buttonLabel;
			
			if ([[u scheme] isEqual:@"http"])
				buttonLabel = [[u absoluteString] substringFromIndex:7]; // cut 'http://'
			else
				buttonLabel = [u absoluteString];
			
			[addressButton setTitle:buttonLabel forState:UIControlStateNormal];
		}
	}
}

- (void) setActionButtonHidden:(BOOL)hidden animated:(BOOL)animated;
{
	[super setActionButtonHidden:hidden animated:animated];
	
	if (compassImageView) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:animated? (hidden? 0.5 : 0.2) : 0];
		
		compassImageView.alpha = hidden? 1.0 : 0.0;
		
		[UIView commitAnimations];
	}
}

- (NSArray *) defaultActions;
{
	return [NSArray arrayWithObjects:
			[MvrItemAction actionWithDisplayName:NSLocalizedString(@"Open", @"Open action") block:^(MvrItem* i) {
				
				[self openInSafari];
				
			}],

			[MvrItemAction actionWithDisplayName:NSLocalizedString(@"Copy", @"Copy action") block:^(MvrItem* i) {

				[UIPasteboard generalPasteboard].URL = [(MvrBookmarkItem*)i address];
				
			}],
			nil];
}

- (IBAction) openInSafari;
{
	if (self.item)
		[UIApp openURL:[(MvrBookmarkItem*)self.item address]];
}

@end
