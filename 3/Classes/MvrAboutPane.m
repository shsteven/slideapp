//
//  MvrAboutPane.m
//  Mover3
//
//  Created by ∞ on 12/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrAboutPane.h"
#import "MvrAppDelegate.h"

enum {
	// Top section
	kMvrAboutEntry_TellAFriend = 0,
	kMvrAboutEntry_Bookmarklet,
	kMvrAboutSectionOneEntriesCount,
	
	// Middle section
	kMvrAboutEntry_Licenses = 0,
	kMvrAboutSectionTwoEntriesCount,
};


@implementation MvrAboutPane

- (id) init;
{
	if (self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil]) {
		self.wantsFullScreenLayout = YES;
		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	}
	
	return self;
}

- (void) viewDidLoad;
{
    [super viewDidLoad];
	tableView.tableHeaderView = headerView;
	tableView.tableFooterView = footerView;
	tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"DrawerBackdrop.png"]];
	tableView.delegate = self;
	tableView.dataSource = self;
	
	versionLabel.text = [NSString stringWithFormat:versionLabel.text, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}

- (void) viewDidUnload;
{
	[headerView release]; headerView = nil;
	[footerView release]; footerView = nil;
	[tableView release]; tableView = nil;
	[versionLabel release]; versionLabel = nil;
	
	[super viewDidUnload];
}

- (IBAction) dismiss;
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
	[UIApp setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated;
{
    [super viewDidDisappear:animated];
	[UIApp setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return kMvrAboutSectionOneEntriesCount;
		case 1:
			return kMvrAboutSectionTwoEntriesCount;
		default:
			return 0;
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString* cellIdentifier = @"MvrRegularCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    

	switch ([indexPath section]) {
		case 0:
			switch ([indexPath row]) {
				case kMvrAboutEntry_TellAFriend:
					cell.textLabel.text = NSLocalizedString(@"Tell a Friend", @"Tell a Friend entry in about box");
					if (!MvrApp().tellAFriend.canTellAFriend)
						cell.textLabel.textColor = [UIColor grayColor];
					
					break;
				case kMvrAboutEntry_Bookmarklet:
					cell.textLabel.text = NSLocalizedString(@"Add Bookmarks from Safari", @"Bookmarklet entry in about box");
					break;
			}
			
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			
			break;

		case 1:
			switch ([indexPath row]) {
				case kMvrAboutEntry_Licenses:
					cell.textLabel.text = NSLocalizedString(@"Licenses & Copyright", @"Licenses entry in about box");
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
			}
			
			break;
	}
	
	
    return cell;
}


- (void) tableView:(UITableView*) tv didSelectRowAtIndexPath:(NSIndexPath*) indexPath;
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	switch ([indexPath section]) {
		case 0:
			switch ([indexPath row]) {
				case kMvrAboutEntry_TellAFriend:
					[MvrApp().tellAFriend start];
					break;
					
				case kMvrAboutEntry_Bookmarklet:
					[UIApp openURL:[NSURL URLWithString:@"http://infinite-labs.net/mover/safari-bookmarklet"]];
					break;
			}
			
			break;
			
		case 1:
			switch ([indexPath row]) {
				case kMvrAboutEntry_Licenses:
					// TODO
					break;
			}
			
			break;
	}
}

- (IBAction) openSite;
{
	[UIApp openURL:[NSURL URLWithString:@"http://infinite-labs.net"]];
}


//- (NSIndexPath*) tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
//{
//	if ([indexPath section] == 0 && [indexPath row] == kMvrAboutEntry_TellAFriend)
//		return MvrApp().tellAFriend.canTellAFriend? indexPath : nil;
//	
//	return indexPath;
//}

@end

