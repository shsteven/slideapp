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

#if kMvrIsLite
#import "MvrStorePane.h"
#endif

enum {
#if !kMvrIsLite
	kMvrAboutSectionOne,
#endif
	
	kMvrAboutSectionTwo,

#if kMvrIsLite
	kMvrAboutSectionUpsell,
#endif
	
	kMvrAboutSectionsCount,
};

enum {
#if kMvrIsLite
	// Upsell
	kMvrAboutEntry_Upsell = 0,
	kMvrAboutSectionUpsellCount,
#endif
	
#if !kMvrIsLite
	// Top section
	kMvrAboutEntry_TellAFriend = 0,
	kMvrAboutEntry_Bookmarklet,
	kMvrAboutSectionOneEntriesCount,
#endif
	
	// Middle section
	kMvrAboutEntry_More = 0,
	kMvrAboutSectionTwoEntriesCount,
};

@interface MvrAboutPane ()

#if kMvrIsLite
@property(readonly) NSString* upsellSectionMoverText;
#endif

@end


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

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
	L0Log(@"Asked about sections, answer = %d", kMvrAboutSectionsCount);
    return kMvrAboutSectionsCount;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
	switch (section) {
#if kMvrIsLite
		case kMvrAboutSectionUpsell:
			return kMvrAboutSectionUpsellCount;
#endif
#if !kMvrIsLite
		case kMvrAboutSectionOne:
			return kMvrAboutSectionOneEntriesCount;
#endif
		case kMvrAboutSectionTwo:
			return kMvrAboutSectionTwoEntriesCount;
		default:
			return 0;
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString* cellIdentifier = nil;
	if ([indexPath section] == kMvrAboutSectionTwo && [indexPath row] == kMvrAboutEntry_More)
		cellIdentifier = @"MvrLabeledCell";
    
    UITableViewCell *cell = nil;
	if (cellIdentifier)
		[tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
		UITableViewCellStyle style = UITableViewCellStyleDefault;
		if ([indexPath section] == kMvrAboutSectionTwo && [indexPath row] == kMvrAboutEntry_More)
			style = UITableViewCellStyleValue1;
		
        cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier] autorelease];
    }
    
	cell.imageView.image = nil;

	switch ([indexPath section]) {
#if kMvrIsLite
		case kMvrAboutSectionUpsell:
			switch ([indexPath row]) {
				case kMvrAboutEntry_Upsell:
					// cell.textLabel.text = NSLocalizedString(@"Get more features in Mover+", @"Upsell entry in about box");
					
				{
					UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"StoreTableViewCell.png"]];
					
					iv.highlightedImage = [UIImage imageNamed:@"StoreTableViewCell_Highlighted.png"];
					
					iv.contentMode = UIViewContentModeTop;
					iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
					iv.frame = cell.contentView.bounds;
					
					[cell.contentView addSubview:iv];
					[iv release];
					
					[cell setAccessibilityLabel:NSLocalizedString(@"Store", @"Store cell accessibility label")];
					
				}
					break;
			}
			
			break;
#endif
			
#if !kMvrIsLite
		case kMvrAboutSectionOne:
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
#endif

		case kMvrAboutSectionTwo:
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


#if kMvrIsLite

- (void) openAppStoreURL:(NSURL*) url;
{
	[self autorelease]; // balances the -retain in -...didSelectRow....
	if (!url)
		url = kMvrUpsellURL;
	[UIApp openURL:url];
	[UIApp endIgnoringInteractionEvents];
}

#endif

- (void) tableView:(UITableView*) tv didSelectRowAtIndexPath:(NSIndexPath*) indexPath;
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	switch ([indexPath section]) {
#if kMvrIsLite
		case kMvrAboutSectionUpsell:
			switch ([indexPath row]) {
				case kMvrAboutEntry_Upsell:
//					[self retain]; // balanced in -openAppStoreURL:
//					[UIApp beginIgnoringInteractionEvents];
//					[kMvrUpsellURL beginResolvingRedirectsWithDelegate:self selector:@selector(openAppStoreURL:)];
				{
					MvrStorePane* pane = [[MvrStorePane alloc] initWithDefaultNibName];
					[self.navigationController pushViewController:pane animated:YES];
					[self.navigationController setNavigationBarHidden:NO animated:YES];
					[pane release];
				}
					
					break;
			}
			
			break;
#endif

#if !kMvrIsLite
		case kMvrAboutSectionOne:
			switch ([indexPath row]) {
				case kMvrAboutEntry_TellAFriend:
					[MvrApp().tellAFriend start];
					break;

				case kMvrAboutEntry_Bookmarklet:
					[UIApp openURL:[NSURL URLWithString:@"http://infinite-labs.net/mover/safari-bookmarklet"]];
					break;
			}
			
			break;
#endif
			
		case kMvrAboutSectionTwo:
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

#if kMvrIsLite

- (NSString*) upsellSectionMoverText {
	return NSLocalizedString(@"Find out about Mover Lite's feature packs, or get more information on Mover+, the paid version of Mover, at the Store.", @"Upsell section text");
}

- (CGFloat) tableView:(UITableView *)tv heightForFooterInSection:(NSInteger)section;
{
	switch (section) {
		case kMvrAboutSectionUpsell:
			return MvrWhiteSectionFooterHeight(self.upsellSectionMoverText, tv, kMvrWhiteSectionDefaultLineBreakMode, MvrWhiteSectionFooterDefaultFont()) + kMvrWhiteSectionDefaultTopBottomMargin / 2.0;
			
		default:
			return 0;
	}
}

- (UIView*) tableView:(UITableView *)tv viewForFooterInSection:(NSInteger)section;
{
	switch (section) {
		case kMvrAboutSectionUpsell:
			return MvrWhiteSectionFooterView(self.upsellSectionMoverText, tv, kMvrWhiteSectionDefaultLineBreakMode, MvrWhiteSectionFooterDefaultFont());
			
		default:
			return nil;
	}
}

#endif

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

