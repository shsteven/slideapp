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
	}
	
	return self;
}

@synthesize tableView = table;

- (void) dealloc
{
	[cellsBySection release];
	[super dealloc];
}

- (void) loadView;
{
	UIView* view = [[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
	view.backgroundColor =
		[UIColor colorWithPatternImage:[UIImage imageNamed:@"DrawerBackdrop.png"]];

	table = [[UITableView alloc] initWithFrame:view.bounds style:UITableViewStyleGrouped];
	table.backgroundColor = view.backgroundColor;
	table.delegate = self;
	table.dataSource = self;
	table.contentInset = UIEdgeInsetsMake(44 + UIApp.statusBarFrame.size.height, 0, 0, 0);
	[view addSubview:table];
	
	self.view = view;
}

- (void) viewDidUnload;
{
	[table release]; table = nil;
}

- (void) makeTableStructure:(NSMutableArray*) content;
{
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
	switchy.on = [MvrApp().messageChecker.userOptedInToMessages boolValue];
	
	messagesConsent.accessoryView = switchy;
	messagesConsent.selectionStyle = UITableViewCellSelectionStyleNone;
	
	[messagesSection.cells addObject:messagesConsent];
	
	messagesSection.footer = NSLocalizedString(@"Mover can check for news when launched and warn you of available updates. This will be done at most once a day while on the cellular network, and will send no personal data.", @"Privacy/bandwidth text for message checking in the More pane.");
	
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
	MvrApp().messageChecker.userOptedInToMessages = [NSNumber numberWithBool:sender.on];
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
		[MvrApp().messageChecker checkOrDisplayMessage];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;
{
	NSString* footerText = [[cellsBySection objectAtIndex:section] footer];
	if (!footerText)
		return nil;
	
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
	label.lineBreakMode = self.footerLineBreakMode;
	label.textAlignment = UITextAlignmentCenter;
	
	label.font = self.footerFont;
	label.textColor = [UIColor whiteColor];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(0, 1);	
	
	label.backgroundColor = [UIColor clearColor];
	label.opaque = NO;
	
	return footer;
}

- (UIFont*) footerFont;
{
	return [UIFont systemFontOfSize:13];
}

- (UILineBreakMode) footerLineBreakMode;
{
	return UILineBreakModeWordWrap;
}

- (CGFloat) footerTopBottomMargin;
{
	return 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;
{
	NSString* footerText = [[cellsBySection objectAtIndex:section] footer];
	if (!footerText)
		return 0;
	
	CGSize theSize = CGSizeMake(tableView.bounds.size.width, CGFLOAT_MAX);
	CGSize actualSize = [footerText sizeWithFont:self.footerFont constrainedToSize:theSize lineBreakMode:self.footerLineBreakMode];
	return actualSize.height + self.footerTopBottomMargin * 2;
}

@end

