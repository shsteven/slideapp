//
//  MvrWiFiNetworkStatePane.m
//  Mover3
//
//  Created by ∞ on 13/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrWiFiNetworkStatePane.h"

#import "MvrAppDelegate_iPad.h"
#import "Network+Storage/MvrScanner.h"

@interface MvrWiFiNetworkStatePane ()

- (void) updateState;

@end



@implementation MvrWiFiNetworkStatePane

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		
		obs = [[MvrScannerObserver alloc] initWithScanner:MvrApp_iPad().wifi delegate:self];
		
	}
	
	return self;
}

- (void) dealloc
{
	[obs release];
	[super dealloc];
}


- (void) viewDidLoad;
{
	[super viewDidLoad];
	
	[self addManagedOutletKeys:
	 @"stateLabel", @"stateImage",
	 nil];
	
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

- (void) scanner:(id <MvrScanner>)s didChangeEnabledKey:(BOOL)enabled;
{
	[self updateState];
}

- (void) scanner:(id <MvrScanner>)s didChangeJammedKey:(BOOL)jammed;
{
	[self updateState];
}

- (void) viewWillAppear:(BOOL)animated;
{
	[super viewWillAppear:animated];
	[self updateState];
}

- (void) updateState;
{
	id <MvrScanner> s = MvrApp_iPad().wifi;
	
	if (!s.enabled)
		return;	

	if (!s.jammed) {
		
		stateLabel.text = NSLocalizedString(@"Wi-Fi On", @"Wi-Fi unjammed text");
		stateImage.image = [UIImage imageNamed:@"GreenDot.png"];
		
	} else {
		
		stateLabel.text = NSLocalizedString(@"Wi-Fi Disconnected", @"Wi-Fi jammed text");
		stateImage.image = [UIImage imageNamed:@"RedDot.png"];
		
	}
}

@end
