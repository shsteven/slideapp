//
//  MvrGenericItemController.m
//  Mover3-iPad
//
//  Created by ∞ on 07/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrGenericItemController.h"

#import "Network+Storage/MvrGenericItem.h"
#import "Network+Storage/MvrItemStorage.h"

#import "UIImage+ILIconTools.h"

@implementation MvrGenericItemController

+ (NSSet *) supportedItemClasses;
{
	return [NSSet setWithObject:[MvrGenericItem class]];
}

- (void) viewDidLoad;
{
	[super viewDidLoad];
	
	[self addManagedOutletKeys:@"iconView", @"titleLabel", nil];
	
	CGRect f = self.actionButton.frame;
	f.origin = CGPointMake(104, 221);
	self.actionButton.frame = f;
	[self.view addSubview:self.actionButton];
	[self.view bringSubviewToFront:self.actionButton];
	
	[self itemDidChange];
}

- (void) itemDidChange;
{
	if (self.item) {
		
		[[self.item storage] setDesiredExtensionAssumingType:[self.item type] error:NULL];
		
		UIDocumentInteractionController* doc = self.documentInteractionController;
		
		UIImage* icon = [UIImage imageApproachingDesiredSize:iconView.bounds.size amongImages:doc.icons];
		if (!icon)
			icon = [UIImage imageNamed:@"DocIcon.png"];
		iconView.image = icon;
		
		titleLabel.text = [self.item title];
		
	}
}

- (NSArray *) actions;
{
	return [NSArray arrayWithObjects:
			[self showOpeningOptionsMenuAction],
			nil];
}

@end
