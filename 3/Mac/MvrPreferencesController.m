//
//  MvrPreferencesController.m
//  Mover Connect
//
//  Created by ∞ on 03/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrPreferencesController.h"
#import <Carbon/Carbon.h>

#import "MvrAgent.h"

@implementation MvrPreferencesController

- (NSString*) selectedDownloadPath;
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	id x = [ud stringForKey:@"MvrDownloadsDirectory"];
	BOOL isDir;
	if (!x || ![[NSFileManager defaultManager] fileExistsAtPath:x isDirectory:&isDir] || !isDir)
		x = self.systemDownloadPath;
	
	return x;
}

- (void) setSelectedDownloadPath:(NSString *) p;
{
	[self willChangeValueForKey:@"systemDownloadPathSelected"];
	
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:p forKey:@"MvrDownloadsDirectory"];
	
	[self didChangeValueForKey:@"systemDownloadPathSelected"];
}

- (BOOL) isSystemDownloadPathSelected;
{
	return [self.systemDownloadPath isEqual:self.selectedDownloadPath];
}


- (BOOL) shouldGroupStuffInMoverItemsFolder;
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	if (![ud objectForKey:@"MvrShouldGroupStuffInMoverItemsFolder"])
		return YES;
	
	return [ud boolForKey:@"MvrShouldGroupStuffInMoverItemsFolder"];
}

- (void) setShouldGroupStuffInMoverItemsFolder:(BOOL) gs;
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:gs forKey:@"MvrShouldGroupStuffInMoverItemsFolder"];
}

- (BOOL) hasSystemDownloadPath;
{
	NSArray* a = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	return [a count] > 0;
}

- (NSString*) systemDownloadPath;
{
	NSArray* a = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	return [a count] > 0? [a objectAtIndex:0] : nil;	
}

- (NSURL*) agentURL;
{
	return [NSURL fileURLWithPath:[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Mover Agent.app"]];
}

- (BOOL) runMoverAgent;
{
	NSURL* agentURL = [self agentURL];
	BOOL result = NO;
	
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	CFArrayRef cfa = LSSharedFileListCopySnapshot(loginItems, NULL);
	
	for (CFIndex i = 0; i < CFArrayGetCount(cfa); i++) {
		LSSharedFileListItemRef item = (LSSharedFileListItemRef) CFArrayGetValueAtIndex(cfa, i);
		
		NSURL* u;
		if (LSSharedFileListItemResolve(item, 0, (CFURLRef*) &u, NULL) != noErr)
			continue;
		
		if ([u isEqual:agentURL]) {
			result = YES;
		}
		
		if (u)
			CFRelease(u);
		
		if (result)
			goto done;
	}
	
done:
	if (cfa)
		CFRelease(cfa);
	if (loginItems)
		CFRelease(loginItems);
	
	return result;
}

- (void) setRunMoverAgent:(BOOL) a;
{
	BOOL current = self.runMoverAgent;
	
	if (current != a) {
		
		LSSharedFileListRef loginItems = (LSSharedFileListRef) CFMakeCollectable(LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL));
		
		NSURL* agentURL = [self agentURL];
		
		if (a) {
			
			LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, (CFURLRef) agentURL, NULL, NULL);
			[[NSWorkspace sharedWorkspace] openURL:agentURL];
			
		} else {
			
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kMvrAgentShouldQuitNotification object:kMvrAgentDistributedNotificationObject];
			
			
			CFArrayRef cfa = LSSharedFileListCopySnapshot(loginItems, NULL);
			
			if (cfa) {
				for (CFIndex i = 0; i < CFArrayGetCount(cfa); i++) {
					LSSharedFileListItemRef item = (LSSharedFileListItemRef) CFArrayGetValueAtIndex(cfa, i);
					
					NSURL* u;
					if (LSSharedFileListItemResolve(item, 0, (CFURLRef*) &u, NULL) != noErr)
						continue;
					
					if (u)
						NSMakeCollectable(u);
					
					if ([u isEqual:agentURL])
						LSSharedFileListItemRemove(loginItems, item);
				}
				CFRelease(cfa);
			}
		}
		
		CFRelease(loginItems);
		
	}
}

#pragma mark UI stuff

- (void) awakeFromNib;
{
	[downloadsFolderPicker selectItemAtIndex:0];
}

- (IBAction) pickSystemDownloadsFolder:(id) sender;
{
	if (self.systemDownloadPath)
		self.selectedDownloadPath = self.systemDownloadPath;
	[downloadsFolderPicker selectItemAtIndex:0];
}

- (IBAction) pickDownloadsFolder:(id) sender;
{
	[downloadsFolderPicker selectItemAtIndex:0];
	
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	
	[openPanel beginSheetForDirectory:self.selectedDownloadPath file:nil modalForWindow:[downloadsFolderPicker window] modalDelegate:self didEndSelector:@selector(downloadPicker:didEndWithCode:context:) contextInfo:NULL];
}

- (void) downloadPicker:(NSOpenPanel*) openPanel didEndWithCode:(NSInteger) i context:(void*) nothing;
{
	[downloadsFolderPicker selectItemAtIndex:0];
	self.selectedDownloadPath = [openPanel filename];
}

@end

// ---------
#pragma mark Transformers

@implementation MvrPreferencesControllerIconTransformer

- (id) transformedValue:(id) value;
{
	NSImage* i;
	
	if (!value)
		i = [NSImage imageNamed:NSImageNameFolder];
	else
		i = [[NSWorkspace sharedWorkspace] iconForFile:value];
	
	[i setSize:NSMakeSize(16, 16)];
	return i;
}

@end

@implementation MvrPreferencesControllerDisplayNameTransformer

- (id) transformedValue:(id) value;
{
	return value? [[NSFileManager defaultManager] displayNameAtPath:value] : nil;
}

@end

// ---------
