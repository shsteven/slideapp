//
//  L0MoverNetworkSettingsPane.m
//  Mover
//
//  Created by ∞ on 13/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverNetworkSettingsPane.h"

#import "L0MoverPeering.h"
#import "L0MoverWiFiScanner.h"
#import "L0MoverBluetoothScanner.h"

#import <QuartzCore/QuartzCore.h>

@interface L0MoverNetworkSettingsPane ()

@property(readonly) L0MoverPeering* peering;
@property(readonly) L0MoverWiFiScanner* WiFi;
@property(readonly) L0MoverBluetoothScanner* bluetooth;

@property(copy) NSArray* model;

- (void) updateModel;
- (void) updateStateOfSwitch:(UISwitch*) enabledSwitch forScanner:(id <L0MoverPeerScanner>) s;

- (UITableViewCell*) cellForWiFiSectionAtRow:(NSInteger) row;
- (UITableViewCell*) cellForBluetoothSectionAtRow:(NSInteger) row;

- (NSString*) titleForFooterInWiFiSection;
- (NSString*) titleForFooterInBluetoothSection;

@end

enum {
	kL0MoverWiFiSection = 0,
	kL0MoverBluetoothSection,
};
typedef NSInteger L0MoverNetworkSettingsSection;

@interface L0MoverTableViewWithCustomSectionMargins : UITableView
{
}

@end

@implementation L0MoverTableViewWithCustomSectionMargins

- (CGRect) rectForFooterInSection:(NSInteger) section;
{
	CGRect rect = [super rectForFooterInSection:section];
	rect.origin.x += 10;
	rect.size.width -= 10;
	return rect;
}

@end



@implementation L0MoverNetworkSettingsPane

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void) loadView;
{
	UITableView* tableView = [[L0MoverTableViewWithCustomSectionMargins alloc] initWithFrame:CGRectMake(0, 0, 10, 10) style:UITableViewStyleGrouped];

	tableView.delegate = self;
	tableView.dataSource = self;
	self.view = tableView;
	
	[tableView release];
	[self viewDidLoad];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark -
#pragma mark Model

@synthesize model;

- (void) dealloc;
{
	[model release];
	[super dealloc];
}

- (void) viewWillAppear:(BOOL) animated;
{
    [super viewWillAppear:animated];

	self.title = NSLocalizedStringFromTable(@"Network", @"L0MoverNetworkUI", @"Title of the network settings pane");
	
	[self updateModel];
	
	[self.peering addObserver:self forKeyPath:@"availableScanners" options:0 context:NULL];
	[self.WiFi addObserver:self forKeyPath:@"jammed" options:0 context:NULL];
	[self.bluetooth addObserver:self forKeyPath:@"jammed" options:0 context:NULL];
	[self.WiFi addObserver:self forKeyPath:@"enabled" options:0 context:NULL];
	[self.bluetooth addObserver:self forKeyPath:@"enabled" options:0 context:NULL];
}

- (void) viewDidDisappear:(BOOL) animated;
{
	[self.peering removeObserver:self forKeyPath:@"availableScanners"];
	[self.WiFi removeObserver:self forKeyPath:@"jammed"];
	[self.bluetooth removeObserver:self forKeyPath:@"jammed"];
	[self.WiFi removeObserver:self forKeyPath:@"enabled"];
	[self.bluetooth removeObserver:self forKeyPath:@"enabled"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	CATransition* t = [CATransition animation];
	t.type = kCATransitionFade;
	[self.tableView.layer addAnimation:t forKey:@"L0FadeTransition"];
	[self updateModel];
}

- (L0MoverPeering*) peering { return [L0MoverPeering sharedService]; }
- (L0MoverWiFiScanner*) WiFi { return [L0MoverWiFiScanner sharedScanner]; }
- (L0MoverBluetoothScanner*) bluetooth { return [L0MoverBluetoothScanner sharedScanner]; }

// -------

- (void) updateModel;
{
	NSMutableArray* m = [NSMutableArray array];
	[m addObject:self.WiFi];
	
	if ([self.peering.availableScanners containsObject:self.bluetooth])
		[m addObject:self.bluetooth];
	
	self.model = m;
	
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view display

- (NSInteger) numberOfSectionsInTableView:(UITableView*) tableView;
{
	return [self.model count];
}


// Customize the number of rows in the table view.
- (NSInteger) tableView:(UITableView*) tableView numberOfRowsInSection:(NSInteger) section;
{
	id scanner = [self.model objectAtIndex:section];
	
	if (scanner == self.WiFi || scanner == self.bluetooth)
		return 1;
	
	return 0;
}

- (void) prepareStatusCell:(UITableViewCell*) cell forScanner:(id <L0MoverPeerScanner>) s;
{		
	if (s.jammed && s.enabled)
		cell.textLabel.textColor = [UIColor redColor];
	
	if ([self.model count] == 1) {
		
		// a label.
		UILabel* stateLabel = cell.detailTextLabel;
		
		// by implied contract, only one channel available == that chan is enabled.
		if (s.jammed) {
			stateLabel.text = NSLocalizedStringFromTable(@"Disconnected", @"L0MoverNetworkUI", @"Shown as a label in the config pane if the only available service is jammed.");
			stateLabel.textColor = [UIColor redColor];
		} else {
			stateLabel.text = NSLocalizedStringFromTable(@"On", @"L0MoverNetworkUI", @"Shown as a label in the config pane if the only available service is connected.");
		}
		
	} else {
		
		// a switch
		UISwitch* enabledSwitch = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
		[enabledSwitch sizeToFit];
		
		[enabledSwitch addTarget:self action:@selector(toggledEnabled:) forControlEvents:UIControlEventValueChanged];
		enabledSwitch.tag = [self.model indexOfObject:s]; // tag it with the scanner #
		
		[self updateStateOfSwitch:enabledSwitch forScanner:s];
		cell.accessoryView = enabledSwitch;
		
	}
	
}

- (void) updateStateOfSwitch:(UISwitch*) enabledSwitch forScanner:(id <L0MoverPeerScanner>) s;
{
	BOOL anyOtherIsEnabled = NO;
	for (id <L0MoverPeerScanner> other in self.model) {
		if (s == other) continue;
		
		if (other.enabled) {
			anyOtherIsEnabled = YES;
			break;
		}
	}
	
	if (!anyOtherIsEnabled)
		enabledSwitch.enabled = NO;
	
	enabledSwitch.on = s.enabled;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	id scanner = [self.model objectAtIndex:[indexPath section]];
		
	if (scanner == self.WiFi) {
		return [self cellForWiFiSectionAtRow:[indexPath row]];
	} else if (scanner == self.bluetooth) {
		return [self cellForBluetoothSectionAtRow:[indexPath row]];
	}
	
	NSAssert(NO, @"An unknown scanner was encountered");
	return nil;
}

- (UITableViewCell*) statusCellForScanner:(id <L0MoverPeerScanner>) s withLabel:(NSString*) label;
{
	BOOL requiresControl = [self.peering.availableScanners count] == 1;
	UITableViewCellStyle style = requiresControl? UITableViewCellStyleValue1 : UITableViewCellStyleDefault;
	UITableViewCell* cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:nil] autorelease];
	cell.textLabel.text = label;

	[self prepareStatusCell:cell forScanner:s];
	
	return cell;
}

- (UITableViewCell*) cellForWiFiSectionAtRow:(NSInteger) row;
{
	return [self statusCellForScanner:self.WiFi withLabel:NSLocalizedStringFromTable(@"Wi-Fi", @"L0MoverNetworkUI", @"Label to the settings pane cell.")];
}

- (UITableViewCell*) cellForBluetoothSectionAtRow:(NSInteger) row;
{
	return [self statusCellForScanner:self.bluetooth withLabel:NSLocalizedStringFromTable(@"Bluetooth", @"L0MoverNetworkUI", @"Label to the settings pane cell.")];
}

#pragma mark -
#pragma mark Footers

- (NSString*) tableView:(UITableView*) tableView titleForFooterInSection:(NSInteger) section;
{
	id scanner = [self.model objectAtIndex:section];
	
	if (scanner == self.WiFi) {
		return [self titleForFooterInWiFiSection];
	} else if (scanner == self.bluetooth) {
		return [self titleForFooterInBluetoothSection];
	}
	
	return nil;
}

- (NSString*) titleForFooterInWiFiSection;
{
	if (self.WiFi.jammed) {
		return NSLocalizedStringFromTable(@"Connect to a network to use Wi-Fi.",
										  @"L0MoverNetworkUI", @"Wi-Fi is jammed (footer text in network config pane).");
	} else if (!self.WiFi.enabled) {
		return NSLocalizedStringFromTable(@"Turn on to see other devices using Wi-Fi.",
										  @"L0MoverNetworkUI", @"Wi-Fi is disabled (footer text in network config pane).");
	} else {
		return NSLocalizedStringFromTable(@"Connects with other devices on this Wi-Fi network.",
										  @"L0MoverNetworkUI", @"Wi-Fi is ok (footer text in network config pane).");		
	}
}

- (NSString*) titleForFooterInBluetoothSection;
{
	if (self.bluetooth.jammed) {
		return NSLocalizedStringFromTable(@"Bluetooth is off in the Settings application. Turn it on to enable.",
										  @"L0MoverNetworkUI", @"Bluetooth is jammed (footer text in network config pane).");
	} else if (!self.bluetooth.enabled) {
		return NSLocalizedStringFromTable(@"Turn on to see newer iPhone and iPod touch models near you with Bluetooth on.",
										  @"L0MoverNetworkUI", @"Bluetooth is disabled (footer text in network config pane).");
	} else {
		return NSLocalizedStringFromTable(@"Connects with newer iPhone and iPod touch models with Bluetooth.",
										  @"L0MoverNetworkUI", @"Bluetooth is ok (footer text in network config pane).");
	}
}

- (NSIndexPath*) tableView:(UITableView*) tableView willSelectRowAtIndexPath:(NSIndexPath*) indexPath;
{
	return nil;
}

#pragma mark -
#pragma mark Setting changes

- (IBAction) toggledEnabled:(UISwitch*) sender;
{
	id <L0MoverPeerScanner> scanner = [self.model objectAtIndex:sender.tag];
	L0Log(@"Toggling scanner %@ at section %d", scanner, sender.tag);
	
	scanner.enabled = !scanner.enabled;
}

#pragma mark -
#pragma mark Construction

+ networkSettingsPane;
{
	L0MoverNetworkSettingsPane* myself = [[L0MoverNetworkSettingsPane alloc] initWithStyle:UITableViewStyleGrouped];
	UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:myself];
	
	myself.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:myself action:@selector(dismiss)] autorelease];
	
	[myself release];
	
	nav.navigationBar.barStyle = UIBarStyleBlack;
	return [nav autorelease];
}

- (IBAction) dismiss;
{
	[self dismissModalViewControllerAnimated:YES];
}

@end

