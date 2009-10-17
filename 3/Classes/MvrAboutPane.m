//
//  MvrAboutPane.m
//  Mover3
//
//  Created by ∞ on 12/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrAboutPane.h"
#import "MvrAppDelegate.h"
#import "MvrMorePane.h"

enum {
	// Top section
	kMvrAboutEntry_TellAFriend = 0,
	kMvrAboutEntry_Bookmarklet,
	kMvrAboutSectionOneEntriesCount,
	
	// Middle section
	kMvrAboutEntry_More = 0,
	kMvrAboutSectionTwoEntriesCount,
};


@implementation MvrAboutPane

- (id) init;
{
	if (self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil]) {
		self.wantsFullScreenLayout = YES;
		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		self.title = @"Mover"; // locale-invariant
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
	[UIApp setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
	[self dismissModalViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
	[UIApp setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];

	if (!self.navigationController.navigationBarHidden)
		[self.navigationController setNavigationBarHidden:YES animated:animated];
	
	[tableView reloadData];
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
    
    NSString* cellIdentifier = @"MvrRegularCell";
	if ([indexPath section] == 1 && [indexPath row] == kMvrAboutEntry_More)
		cellIdentifier = @"MvrLabeledCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		UITableViewCellStyle style = UITableViewCellStyleDefault;
		if ([indexPath section] == 1 && [indexPath row] == kMvrAboutEntry_More)
			style = UITableViewCellStyleValue1;
		
        cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier] autorelease];
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
				case kMvrAboutEntry_More:
					cell.textLabel.text = NSLocalizedString(@"Settings & More", @"More entry in about box");
					MvrMessageChecker* checker = MvrApp().messageChecker;
					cell.detailTextLabel.text = checker.lastMessage.miniTitle;
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
				case kMvrAboutEntry_More:
					{
						MvrMorePane* more = [[MvrMorePane new] autorelease];
						[self.navigationController pushViewController:more animated:YES];
						[self.navigationController setNavigationBarHidden:NO animated:YES];
					}					
					break;
			}
			
			break;
	}
}

- (IBAction) openSite;
{
	[UIApp openURL:[NSURL URLWithString:@"http://infinite-labs.net"]];
}


+ modalPane;
{
	MvrAboutPane* pane = [[MvrAboutPane new] autorelease];
	UINavigationController* nav = [[[UINavigationController alloc] initWithRootViewController:pane] autorelease];
	
	nav.navigationBarHidden = YES;
	nav.navigationBar.barStyle = UIBarStyleBlack;
	nav.navigationBar.translucent = YES;
	return nav;
}

@end

