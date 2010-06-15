    //
//  MvrWiFiNetworkStatePane.m
//  Mover3
//
//  Created by ∞ on 13/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrWiFiNetworkStatePane.h"

#import "MvrAppDelegate_iPad.h"

@implementation MvrWiFiNetworkStatePane

- (void) viewDidLoad;
{
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"DrawerBackdrop.png"]];
}

- (CGSize) contentSizeForViewInPopover;
{
	return CGSizeMake(320, 115);
}

- (IBAction) switchToBluetooth;
{
	[MvrApp_iPad() switchToBluetooth];
}

@end
