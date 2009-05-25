//
//  L0MoverBookmarksAccountPane.m
//  Mover
//
//  Created by ∞ on 24/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverBookmarksAccountPane.h"

enum {
	kL0MoverDoNotSaveSection = 0,
	kL0MoverAccountsSection = 1,
	
	kL0MoverBookmarksAccountTableSectionCount,
};

@interface L0MoverBookmarksAccountPane ()
- (void) clearOutlets;
@end

@implementation L0MoverBookmarksAccountPane

- (id) initWithDefaultNibName;
{
	return [self initWithNibName:@"L0MoverBookmarksAccountPane" bundle:nil];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*) tableView;
{
	return kL0MoverBookmarksAccountTableSectionCount;	
}

- (NSInteger) tableView:(UITableView*) table numberOfRowsInSection:(NSInteger) section;
{
	switch (section) {
		case kL0MoverDoNotSaveSection:
			return 1;
			
		case kL0MoverAccountsSection:
			return 2;
			
		default:
			NSAssert(NO, @"Unknown section requested");
			return 0;
	}
}

- (CGFloat) tableView:(UITableView*) tableView heightForRowAtIndexPath:(NSIndexPath*) indexPath;
{
	switch ([indexPath section]) {
		case kL0MoverAccountsSection:
			return 130;
			
		default:
			return 50;
	}
}

- (UITableViewCell*) tableView:(UITableView*) tableView cellForRowAtIndexPath:(NSIndexPath*) indexPath;
{
	switch ([indexPath section]) {
		case kL0MoverDoNotSaveSection: {
			UITableViewCell* doNotSave = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0,0,10,10) reuseIdentifier:nil] autorelease];
			doNotSave.text = NSLocalizedString(@"Do Not Save", @"'Do Not Save' choice in the bookmarks account pane.");
			return doNotSave;
		}
		
		case kL0MoverAccountsSection: {
			switch ([indexPath row]) {
				case 0:
					return self.deliciousCell;
				case 1:
					return self.instapaperCell;
				default:
					NSAssert(NO, @"Accounts section has two cells.");
					return nil;
			}
		}
			
		default:
			NSAssert(NO, @"Unknown section requested.");
			return nil;
	}
}

- (NSString*) tableView:(UITableView*) tableView titleForHeaderInSection:(NSInteger) section;
{
	switch (section) {
		case kL0MoverDoNotSaveSection:
			return nil;
			
		case kL0MoverAccountsSection:
			return NSLocalizedString(@"Save Online", @"Section title for accounts in bookmarks account pane");

		default:
			NSAssert(NO, @"Unknown section requested.");
			return nil;
	}
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 30000
- (void) viewDidUnload;
{
	[self clearOutlets];
}
#else
- (void) setView:(UIView*) v;
{
	if (!v)
		[self clearOutlets];
	
	[super setView:v];
}
#endif

@synthesize table, deliciousCell, instapaperCell;
- (void) clearOutlets;
{
	self.table = nil;
	self.deliciousCell = nil;
	self.instapaperCell = nil;
}

- (void) dealloc;
{
	[self clearOutlets];
    [super dealloc];
}


@end
