//
//  MvrMorePane.m
//  Mover3
//
//  Created by ∞ on 16/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrMorePane.h"

#import "MvrLegalitiesPane.h"
#import "MvrAppDelegate.h"
#import "MvrMessagesCell.h"

#if kMvrIsLite
#import "MvrStore.h"
#import "MvrStorePane.h"
#endif

UIView* MvrWhiteSectionFooterView(NSString* footerText, UITableView* tableView, UILineBreakMode footerLineBreakMode, UIFont* footerFont) {
	UIView* footer = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 100)] autorelease];
	footer.backgroundColor = [UIColor clearColor];
	footer.opaque = NO;
	
	CGRect labelFrame = CGRectInset(footer.bounds, 20, 0);
	UILabel* label = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
	label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	label.contentMode = UIViewContentModeCenter;
	[footer addSubview:label];
	
	label.text = footerText;
	label.numberOfLines = 0;
	label.lineBreakMode = footerLineBreakMode;
	label.textAlignment = UITextAlignmentCenter;
	
	label.font = footerFont;
	label.textColor = [UIColor whiteColor];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(0, 1);	
	
	label.backgroundColor = [UIColor clearColor];
	label.opaque = NO;
	
	return footer;
}

CGFloat MvrWhiteSectionFooterHeight(NSString* footerText, UITableView* tableView, UILineBreakMode footerLineBreakMode, UIFont* footerFont) {
	CGSize theSize = CGSizeMake(tableView.bounds.size.width, CGFLOAT_MAX);
	return [footerText sizeWithFont:footerFont constrainedToSize:theSize lineBreakMode:footerLineBreakMode].height;
}

UIFont* MvrWhiteSectionFooterDefaultFont() {
	return [UIFont systemFontOfSize:13];
}


@interface MvrMorePaneActionCell : UITableViewCell {
	SEL action;
}
// - performActionForCell:(MvrMorePaneCell*) sender;
@property SEL action;
@end

@implementation MvrMorePaneActionCell
@synthesize action;
@end

@interface MvrMorePaneSection : NSObject
{
	NSMutableArray* cells;
	NSString* header;
	NSString* footer;
}

@property(readonly) NSMutableArray* cells;
@property(copy) NSString* header, * footer;

+ section;

@end

@implementation MvrMorePaneSection

- (id) init
{
	self = [super init];
	if (self != nil) {
		cells = [NSMutableArray new];
	}
	return self;
}

@synthesize cells, header, footer;

- (void) dealloc
{
	[cells release];
	[header release]; [footer release];
	[super dealloc];
}

+ section;
{
	return [[self new] autorelease];
}

@end



@interface MvrMorePane ()

- (void) makeTableStructure:(NSMutableArray*) table;

@property(readonly) UIFont* footerFont;
@property(readonly) UILineBreakMode footerLineBreakMode;
@property(readonly) CGFloat footerTopBottomMargin;

@end


@implementation MvrMorePane

- (id) init;
{
	if (self = [super initWithNibName:nil bundle:nil]) {
		self.title = NSLocalizedString(@"More", @"Title of the More pane pushed by the about box");
		self.wantsFullScreenLayout = YES;
		NSMutableArray* structure = [NSMutableArray array];
		[self makeTableStructure:structure];
		cellsBySection = [structure copy];
		
#if kMvrIsLite
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUnlockProduct:) name:kMvrStoreProductUnlockedNotification object:nil];
#endif
	}
	
	return self;
}

@synthesize tableView = table;

- (void) dealloc
{
#if kMvrIsLite
	[[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
	
	[cellsBySection release];
	[super dealloc];
}

- (void) loadView;
{
	UIView* view = [[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
	view.backgroundColor =
		[UIColor colorWithWhite:0.200 alpha:1.000];

	table = [[UITableView alloc] initWithFrame:view.bounds style:UITableViewStyleGrouped];
	table.delegate = self;
	table.dataSource = self;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		table.contentInset = UIEdgeInsetsMake(44 + UIApp.statusBarFrame.size.height, 0, 0, 0);
	table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	table.backgroundColor = [UIColor colorWithWhite:0.200 alpha:1.000];
	if ([table respondsToSelector:@selector(setBackgroundView:)])
		[table setBackgroundView:nil];
	
	[view addSubview:table];
	self.view = view;
}

- (CGSize) contentSizeForViewInPopover;
{
	return CGSizeMake(320, 430);
}

- (void) viewDidUnload;
{
	[table release]; table = nil;
}

- (void) viewWillAppear:(BOOL)animated;
{
	[super viewWillAppear:animated];
	if ([table respondsToSelector:@selector(backgroundView)])
		[table backgroundView].backgroundColor = self.view.backgroundColor;
	
}

- (void) tellAFriend:(id) sender;
{
	[MvrServices().tellAFriend start];
}

#if kMvrIsLite
- (void) pushStore:(id) store;
{
	MvrStorePane* pane = [[MvrStorePane alloc] initWithDefaultNibName];
	[self.navigationController pushViewController:pane animated:YES];
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[pane release];	
}
#endif

- (void) makeTableStructure:(NSMutableArray*) content;
{
#if kMvrIsLite
	// All stuff that wasn't in the MvrAboutPane because of the upsell is here now.
	MvrMorePaneSection* commandsSection = [MvrMorePaneSection section];
	[content addObject:commandsSection];
	
	MvrMorePaneActionCell* tellAFriend = [[[MvrMorePaneActionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
	
	tellAFriend.textLabel.text = NSLocalizedString(@"Tell a Friend", @"Tell a Friend entry in about box");
	tellAFriend.textLabel.textAlignment = UITextAlignmentCenter;
	
	if (!MvrServices().tellAFriend.canTellAFriend)
		tellAFriend.textLabel.textColor = [UIColor grayColor];
	tellAFriend.action = @selector(tellAFriend:);
	[commandsSection.cells addObject:tellAFriend];
	

	// ||| STORE |||
	MvrMorePaneSection* moverStoreSection = [MvrMorePaneSection section];
	[content addObject:moverStoreSection];
	MvrMorePaneActionCell* store = [[[MvrMorePaneActionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];

	UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"StoreTableViewCell.png"]];
		
	iv.highlightedImage = [UIImage imageNamed:@"StoreTableViewCell_Highlighted.png"];
	
	iv.contentMode = UIViewContentModeTop;
	iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	iv.frame = store.contentView.bounds;
	
	[store.contentView addSubview:iv];
	[iv release];
	
	[store setAccessibilityLabel:NSLocalizedString(@"Store", @"Store cell accessibility label")];
	
	store.action = @selector(pushStore:);
	moverStoreSection.footer = NSLocalizedString(@"Find out about Mover Lite's feature packs, or get more information on Mover+, the paid version of Mover, at the Store.", @"Upsell section text");
	[moverStoreSection.cells addObject:store];
	
#endif
	
	MvrMorePaneSection* messagesSection = [MvrMorePaneSection section];
	[content addObject:messagesSection];
	
	// News & Updates  (no news)
	MvrMessagesCell* cell = [[MvrMessagesCell new] autorelease];
	[messagesSection.cells addObject:cell];
	
	// Check for News |--1| <-- UISwitch
	UITableViewCell* messagesConsent = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
	messagesConsent.textLabel.text = NSLocalizedString(@"Check for News", @"Messages opt-in/out cell title");
	
	UISwitch* switchy = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
	[switchy sizeToFit];
	[switchy addTarget:self action:@selector(didChangeOptInOutForMessages:) forControlEvents:UIControlEventValueChanged];
	switchy.on = [MvrServices().messageChecker.userOptedInToMessages boolValue];
	
	messagesConsent.accessoryView = switchy;
	messagesConsent.selectionStyle = UITableViewCellSelectionStyleNone;
	
	[messagesConsent setAccessibilityLabel:nil];
	
	[messagesSection.cells addObject:messagesConsent];
	
	messagesSection.footer = NSLocalizedString(@"Mover can check for news when launched and warn you of available updates. This will be done at most once a day while on the cellular network, and will send no personal data.", @"Privacy/bandwidth text for message checking in the More pane.");
	
	// ---
	
	if (MvrServices().soundsAvailable) {
	
		MvrMorePaneSection* soundsSection = [MvrMorePaneSection section];
		[content addObject:soundsSection];
		
		// Sounds |--1| <-- UISwitch
		UITableViewCell* sounds = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
		sounds.textLabel.text = NSLocalizedString(@"Sounds", @"Sounds on/off cell title");
		
		[sounds setIsAccessibilityElement:NO];
		
		switchy = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
		[switchy sizeToFit];
		[switchy addTarget:self action:@selector(didChangeSounds:) forControlEvents:UIControlEventValueChanged];
		switchy.on = MvrServices().soundsEnabled;
		
		sounds.accessoryView = switchy;
		sounds.selectionStyle = UITableViewCellSelectionStyleNone;
		
		[soundsSection.cells addObject:sounds];
		
	}
	
	// ---
	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] containsObject:(id) kUTTypeMovie] && [MvrServices() isFeatureAvailable:kMvrFeatureVideoSending]) {
		
		MvrMorePaneSection* videoQualitySection = [MvrMorePaneSection section];
		[content addObject:videoQualitySection];
		
		// High Quality Videos |--1| <-- UISwitch
		UITableViewCell* videos = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
		videos.textLabel.text = NSLocalizedString(@"High Quality Video", @"HQ Video on/off cell title");
		
		[videos setIsAccessibilityElement:NO];
		
		switchy = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
		[switchy sizeToFit];
		[switchy addTarget:self action:@selector(didChangeSounds:) forControlEvents:UIControlEventValueChanged];
		switchy.on = MvrServices().highQualityVideoEnabled;
		
		videos.accessoryView = switchy;
		videos.selectionStyle = UITableViewCellSelectionStyleNone;
		
		[videoQualitySection.cells addObject:videos];
		videoQualitySection.footer = NSLocalizedString(@"High quality videos take more time to transfer. Turn off to transfer a smaller, compressed video instead.", @"HQ Video section footer");
	}
	
	// ---
	
	MvrMorePaneSection* legalitiesSection = [MvrMorePaneSection section];
	[content addObject:legalitiesSection];
	
	// Licenses & Copyrights >
	MvrMorePaneActionCell* legalities = [[[MvrMorePaneActionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
	legalities.textLabel.text = NSLocalizedString(@"Licenses & Copyrights", @"Licenses & Copyrights cell in the More pane.");
	legalities.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	legalities.action = @selector(showLegalities:);
	
	[legalitiesSection.cells addObject:legalities];
	
	// ---
	
	MvrMorePaneSection* feedbackSection = [MvrMorePaneSection section];
	[content addObject:feedbackSection];
	
	// Ask for Support >
	MvrMorePaneActionCell* support = [[[MvrMorePaneActionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
	support.textLabel.text = NSLocalizedString(@"Ask for Support", @"Ask for Support cell in the More pane.");
	support.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	support.action = @selector(openSupport:);
	
	[feedbackSection.cells addObject:support];
}

- (void) didChangeOptInOutForMessages:(UISwitch*) sender;
{
	MvrServices().messageChecker.userOptedInToMessages = [NSNumber numberWithBool:sender.on];
}

- (void) didChangeSounds:(UISwitch*) sender;
{
	MvrServices().soundsEnabled = sender.on;
}

- (void) showLegalities:(id) sender;
{
	MvrLegalitiesPane* pane = [[MvrLegalitiesPane new] autorelease];
	[self.navigationController pushViewController:pane animated:YES];
}

- (void) openSupport:(id) sender;
{
	[UIApp openURL:[NSURL URLWithString:@"http://infinite-labs.net/support"]];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [cellsBySection count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[cellsBySection objectAtIndex:section] cells] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    
    NSUInteger sectionIndex = [indexPath section], rowIndex = [indexPath row];
	MvrMorePaneSection* section = [cellsBySection objectAtIndex:sectionIndex];
    UITableViewCell* cell = [section.cells objectAtIndex:rowIndex];
	cell.backgroundView.backgroundColor = [UIColor clearColor];
	cell.backgroundView.opaque = NO;
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	id cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	if ([cell isKindOfClass:[MvrMorePaneActionCell class]])
		[self performSelector:[(MvrMorePaneActionCell*)cell action]];
	else if ([cell isKindOfClass:[MvrMessagesCell class]])
		[MvrServices().messageChecker checkOrDisplayMessage];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;
{
	NSString* footerText = [[cellsBySection objectAtIndex:section] footer];
	if (!footerText)
		return nil;
	
	return MvrWhiteSectionFooterView(footerText, tableView, self.footerLineBreakMode, self.footerFont);
}

- (UIFont*) footerFont;
{
	return MvrWhiteSectionFooterDefaultFont();
}

- (UILineBreakMode) footerLineBreakMode;
{
	return kMvrWhiteSectionDefaultLineBreakMode;
}

- (CGFloat) footerTopBottomMargin;
{
	return kMvrWhiteSectionDefaultTopBottomMargin;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;
{
	NSString* footerText = [[cellsBySection objectAtIndex:section] footer];
	if (!footerText)
		return 0;
	
	return MvrWhiteSectionFooterHeight(footerText, tableView, self.footerLineBreakMode, self.footerFont) + self.footerTopBottomMargin * 1.8;
}

- (void) didUnlockProduct:(NSNotification*) n;
{
	NSMutableArray* structure = [NSMutableArray array];
	[self makeTableStructure:structure];
	[cellsBySection release];
	cellsBySection = [structure copy];

	[self.tableView reloadData];
}

@end

