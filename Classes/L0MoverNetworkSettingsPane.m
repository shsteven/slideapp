//
//  L0MoverNetworkSettingsPane.m
//  Mover
//
//  Created by ∞ on 13/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverNetworkSettingsPane.h"

#import "MvrNetworkExchange.h"
#import "L0MoverWiFiScanner.h"
#import "L0MoverBluetoothScanner.h"

#import "L0MoverAppDelegate.h"

#import <QuartzCore/QuartzCore.h>

#define kMvrWiFiClassFamily ([MvrWiFiScanner class])
#define kMvrBluetoothClassFamily ([L0MoverBluetoothScanner class])

@interface L0MoverNetworkSettingsPane ()

// -- New methods for handling families of scanners --
- (BOOL) areScannersAvailableForClass:(Class) c;
- (BOOL) areScannersEnabledForClass:(Class) c;
- (BOOL) areScannersJammedForClass:(Class) c;
- (void) setEnabled:(BOOL) e forScannersOfClass:(Class) c;
// -- - --

- (void) updateModel;
- (void) updateStateOfSwitch:(UISwitch*) enabledSwitch forScannerClass:(Class) c;

- (UITableViewCell*) cellForWiFiSectionAtRow:(NSInteger) row;
- (UITableViewCell*) cellForBluetoothSectionAtRow:(NSInteger) row;

- (NSString*) titleForFooterInWiFiSection;
- (NSString*) titleForFooterInBluetoothSection;

@property(readonly) MvrNetworkExchange* peering;

@end

enum {
	kL0MoverWiFiSection = 0,
	kL0MoverBluetoothSection,

	kMvrNetworkSettingsSectionCount,
};
typedef NSInteger L0MoverNetworkSettingsSection;


@implementation L0MoverNetworkSettingsPane

#pragma mark -
#pragma mark Scanner families

- (BOOL) areScannersAvailableForClass:(Class) c;
{
	for (id s in self.peering.availableScanners) {
		if ([s isKindOfClass:c])
			return YES;
	}
	
	return NO;
}

- (BOOL) areScannersEnabledForClass:(Class) c;
{
	for (id <L0MoverPeerScanner> s in self.peering.availableScanners) {
		if ([s isKindOfClass:c] && s.enabled)
			return YES;
	}
	
	return NO;
}

- (BOOL) areScannersEnabledForClassesOtherThan:(Class) c;
{
	for (id <L0MoverPeerScanner> s in self.peering.availableScanners) {
		if (![s isKindOfClass:c] && s.enabled)
			return YES;
	}
	
	return NO;
}

- (BOOL) areScannersJammedForClass:(Class) c;
{
	for (id <L0MoverPeerScanner> s in self.peering.availableScanners) {
		if ([s isKindOfClass:c] && s.enabled && s.jammed)
			return YES;
	}
	
	return NO;
}

- (void) setEnabled:(BOOL) e forScannersOfClass:(Class) c;
{
	for (id <L0MoverPeerScanner> s in self.peering.availableScanners) {
		if ([s isKindOfClass:c]) {
			s.enabled = e;
			[L0Mover setEnabledDefault:e forScanner:s];
		}
	}
}

- (void) setEnabled:(BOOL) e forScannersOfClassesOtherThan:(Class) c;
{
	for (id <L0MoverPeerScanner> s in self.peering.availableScanners) {
		if (![s isKindOfClass:c]) {
			s.enabled = e;
			[L0Mover setEnabledDefault:e forScanner:s];
		}
	}
}

#pragma mark -
#pragma mark Model

- (MvrNetworkExchange*) peering { return [MvrNetworkExchange sharedExchange]; }

#pragma mark -
#pragma mark UI implementation

- (void) loadView;
{
	UITableView* tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 10, 10) style:UITableViewStyleGrouped];

	tableView.delegate = self;
	tableView.dataSource = self;
	self.view = tableView;
	
	[tableView release];
	[self viewDidLoad];
}

- (void) viewWillAppear:(BOOL) animated;
{
    [super viewWillAppear:animated];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	
	
	
	[self updateModel];
	
	[self.peering addObserver:self forKeyPath:@"availableScanners" options:0 context:NULL];
	for (id s in [MvrNetworkExchange allScanners]) {
		[s addObserver:self forKeyPath:@"enabled" options:0 context:NULL];
		[s addObserver:self forKeyPath:@"jammed" options:0 context:NULL];
	}
}

- (void) viewDidDisappear:(BOOL) animated;
{
	[self.peering removeObserver:self forKeyPath:@"availableScanners"];
	for (id s in [MvrNetworkExchange allScanners]) {
		[s removeObserver:self forKeyPath:@"enabled"];
		[s removeObserver:self forKeyPath:@"jammed"];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	CATransition* t = [CATransition animation];
	t.type = kCATransitionFade;
	[self.tableView.layer addAnimation:t forKey:@"L0FadeTransition"];
	[self updateModel];
}

// -------

- (void) updateModel;
{
	isBluetoothAvailable = [self areScannersAvailableForClass:kMvrBluetoothClassFamily];
	
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view display

- (NSInteger) numberOfSectionsInTableView:(UITableView*) tableView;
{
	NSInteger sections = kMvrNetworkSettingsSectionCount;
	if (!isBluetoothAvailable)
		sections--;
	
	return sections;
}


// Customize the number of rows in the table view.
- (NSInteger) tableView:(UITableView*) tableView numberOfRowsInSection:(NSInteger) section;
{
	if (section < kMvrNetworkSettingsSectionCount)
		return 1;
	
	NSAssert(NO, @"Too high a section request!");
	return 0;
}

- (NSInteger) sectionIndexForScannerClass:(Class) c;
{
	if ([c isEqual:kMvrWiFiClassFamily])
		return kL0MoverWiFiSection;
	else if ([c isEqual:kMvrBluetoothClassFamily])
		return kL0MoverBluetoothSection;
	
	NSAssert(NO, @"This is an unknown scanner class!");
	return -1;
}

- (Class) scannerClassForSectionIndex:(NSInteger) section;
{
	if (section == kL0MoverWiFiSection)
		return kMvrWiFiClassFamily;
	else if (section == kL0MoverBluetoothSection)
		return kMvrBluetoothClassFamily;
	
	NSAssert(NO, @"This is an unknown section!");
	return nil;
}

- (void) prepareStatusCell:(UITableViewCell*) cell forScannerClass:(Class) c;
{		
	if ([self areScannersJammedForClass:c])
		cell.textLabel.textColor = [UIColor redColor];
	
	if (!isBluetoothAvailable) {
		
		// a label.
		UILabel* stateLabel = cell.detailTextLabel;
		
		// only Wi-Fi is available, so we show its state.
		if ([self areScannersJammedForClass:c]) {
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
		enabledSwitch.tag = [self sectionIndexForScannerClass:c];
		
		[self updateStateOfSwitch:enabledSwitch forScannerClass:c];
		cell.accessoryView = enabledSwitch;
		
	}
	
}

- (void) updateStateOfSwitch:(UISwitch*) enabledSwitch forScannerClass:(Class) c;
{
	// enable only if others are enabled.
	enabledSwitch.enabled = [self areScannersEnabledForClassesOtherThan:c];	
	
	// turn on if enabled, off if disabled.
	enabledSwitch.on = [self areScannersEnabledForClass:c];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{	
	if ([indexPath section] == kL0MoverWiFiSection) {
		return [self cellForWiFiSectionAtRow:[indexPath row]];
	} else if ([indexPath section] == kL0MoverBluetoothSection) {
		return [self cellForBluetoothSectionAtRow:[indexPath row]];
	}
	
	NSAssert(NO, @"An unknown scanner was encountered");
	return nil;
}

- (UITableViewCell*) statusCellForScannerClass:(Class) c withLabel:(NSString*) label;
{
	UITableViewCellStyle style = isBluetoothAvailable? UITableViewCellStyleValue1 : UITableViewCellStyleDefault;
	
	UITableViewCell* cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:nil] autorelease];
	cell.textLabel.text = label;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;

	[self prepareStatusCell:cell forScannerClass:c];
	
	return cell;
}

- (UITableViewCell*) cellForWiFiSectionAtRow:(NSInteger) row;
{
	return [self statusCellForScannerClass:kMvrWiFiClassFamily withLabel:NSLocalizedStringFromTable(@"Wi-Fi", @"L0MoverNetworkUI", @"Label to the settings pane cell.")];
}

- (UITableViewCell*) cellForBluetoothSectionAtRow:(NSInteger) row;
{
	return [self statusCellForScannerClass:kMvrBluetoothClassFamily withLabel:NSLocalizedStringFromTable(@"Bluetooth", @"L0MoverNetworkUI", @"Label to the settings pane cell.")];
}

#pragma mark -
#pragma mark Footers

- (NSString*) tableView:(UITableView*) tableView titleForFooterInSection:(NSInteger) section;
{
	if (section == kL0MoverWiFiSection)
		return [self titleForFooterInWiFiSection];
	else if (section == kL0MoverBluetoothSection)
		return [self titleForFooterInBluetoothSection];
	
	NSAssert(NO, @"This is an unknown section index!");
	return nil;
}

- (NSString*) titleForFooterInWiFiSection;
{
	BOOL jammed = [self areScannersJammedForClass:kMvrWiFiClassFamily],
		enabled = [self areScannersEnabledForClass:kMvrWiFiClassFamily];
	
	if (jammed) {
		return NSLocalizedStringFromTable(@"Connect to a network to use Wi-Fi.",
										  @"L0MoverNetworkUI", @"Wi-Fi is jammed (footer text in network config pane).");
	} else if (!enabled) {
		return NSLocalizedStringFromTable(@"Turn on to see other devices using Wi-Fi.\nIf you do, Bluetooth will be turned off.",
										  @"L0MoverNetworkUI", @"Wi-Fi is disabled (footer text in network config pane).");
	} else {
		return NSLocalizedStringFromTable(@"Connects with other devices on this Wi-Fi network.",
										  @"L0MoverNetworkUI", @"Wi-Fi is ok (footer text in network config pane).");		
	}
}

- (NSString*) titleForFooterInBluetoothSection;
{
	BOOL jammed = [self areScannersJammedForClass:kMvrBluetoothClassFamily],
		enabled = [self areScannersEnabledForClass:kMvrBluetoothClassFamily];
	
	if (jammed) {
		return NSLocalizedStringFromTable(@"Bluetooth is off. Turn it on in the Settings application to use it.",
										  @"L0MoverNetworkUI", @"Bluetooth is jammed (footer text in network config pane).");
	} else if (!enabled) {
		return NSLocalizedStringFromTable(@"Turn on to see newer iPhone and iPod touch models near you with Bluetooth on.\nIf you do, Wi-Fi will be turned off.",
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
	Class c = [self scannerClassForSectionIndex:sender.tag];
	
	L0Log(@"Toggling scanner class %@ at section %d", c, sender.tag);
	
	BOOL newValue = ![self areScannersEnabledForClass:c];
	[self setEnabled:newValue forScannersOfClass:c];
	[self setEnabled:!newValue forScannersOfClassesOtherThan:c];	
}

#pragma mark -
#pragma mark Construction

+ networkSettingsPane;
{	
	L0MoverNetworkSettingsPane* myself = [[L0MoverNetworkSettingsPane alloc] initWithStyle:UITableViewStyleGrouped];
	myself.title = NSLocalizedStringFromTable(@"Network", @"L0MoverNetworkUI", @"Title of the network settings pane");
	return [myself autorelease];
}

+ modalNetworkSettingsPane;
{
	L0MoverNetworkSettingsPane* myself = [self networkSettingsPane];
	UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:myself];
	
	myself.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:myself action:@selector(dismiss)] autorelease];
	
	return [nav autorelease];
}

- (IBAction) dismiss;
{
	[self dismissModalViewControllerAnimated:YES];
}

@end

