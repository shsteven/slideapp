//
//  L0MoverBookmarksAccountLoginPane.m
//  Mover
//
//  Created by ∞ on 25/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverBookmarksAccountLoginPane.h"

enum {
	kL0MoverUsernameFieldTag = 1,
	kL0MoverPasswordFieldTag = 2,
};

@interface L0MoverBookmarksAccountLoginPane ()
- (UITextField*) textFieldForCellInRow:(NSInteger) row;
@end

@implementation L0MoverBookmarksAccountLoginPane

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (id) initWithDefaultStyle;
{
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		// TODO
	}
	
	return self;
}

- (void) viewDidAppear:(BOOL) ani;
{
	[[self textFieldForCellInRow:0] becomeFirstResponder];
}

@synthesize passwordOptional, username, password;

- (void) dealloc;
{
	[username release];
	[password release];
    [super dealloc];
}

- (UITextField*) textFieldForCellInRow:(NSInteger) row;
{
	UITableViewCell* c = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
	return (UITextField*) c.accessoryView;
}

#pragma mark Table view methods

- (NSInteger) numberOfSectionsInTableView:(UITableView*) tableView;
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger) tableView:(UITableView*) tableView numberOfRowsInSection:(NSInteger) section;
{
    return 2;
}

- (CGFloat) tableView:(UITableView*) tableView heightForHeaderInSection:(NSInteger) section;
{
	return 50;
}

- (NSString*) tableView:(UITableView*) tableView titleForHeaderInSection:(NSInteger) section;
{
	return @" ";
}

- (BOOL) textFieldShouldReturn:(UITextField*) textField;
{
	switch (textField.tag) {
		case kL0MoverUsernameFieldTag:
			[[self textFieldForCellInRow:1] becomeFirstResponder];
			break;
		case kL0MoverPasswordFieldTag:
			[[self textFieldForCellInRow:0] becomeFirstResponder];
			break;
	}
	
	return NO;
}

// Customize the appearance of table view cells.
- (UITableViewCell*) tableView:(UITableView*) tableView cellForRowAtIndexPath:(NSIndexPath*) indexPath;
{
    
    UITableViewCell* cell = [[[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 10, 10) reuseIdentifier:nil] autorelease];
	
	UITextField* field = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 180, 30)];
	field.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	field.font = [UIFont systemFontOfSize:16];
	field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	field.textColor = [UIColor colorWithRed:(CGFloat)81.0/255.0 green:(CGFloat)102.0/255.0 blue:(CGFloat)145.0/255.0 alpha:1.0];
	field.delegate = self;
	cell.accessoryView = field;

	switch ([indexPath row]) {
		case 0: {
			cell.text = NSLocalizedString(@"Username", @"Username label in bookmarks login pane.");
			if (self.username)
				field.text = self.username;
			field.tag = kL0MoverUsernameFieldTag;
		}
			break;
			
		case 1: {
			cell.text = NSLocalizedString(@"Password", @"Password label in bookmarks login pane.");
			field.secureTextEntry = YES;
			if (self.password)
				field.text = self.password;
			
			if (self.passwordOptional)
				field.placeholder = NSLocalizedString(@"(only if required)", @"Optional password placeholder");
			else
				field.placeholder = NSLocalizedString(@"required", @"Required password placeholder");
			field.tag = kL0MoverPasswordFieldTag;
		}
			break;
	}
	
	[field release];
    return cell;
}

- (NSIndexPath*) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	[(UITextField*)cell.accessoryView becomeFirstResponder];
	return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


@end

