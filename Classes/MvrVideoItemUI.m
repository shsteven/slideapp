//
//  MvrVideoItemUI.m
//  Mover
//
//  Created by ∞ on 11/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrVideoItemUI.h"
#import "MvrVideoItem.h"
#import "MvrStorageCentral.h"
#import "L0MoverAppDelegate.h"

#import <MediaPlayer/MediaPlayer.h>

@implementation MvrVideoItemUI

+ (NSArray*) supportedItemClasses;
{
	return [NSArray arrayWithObject:[MvrVideoItem class]];
}

- (BOOL) removingFromTableIsSafeForItem:(L0MoverItem*) i;
{
	return NO;
}

- (L0MoverItemAction*) mainActionForItem:(L0MoverItem*) i;
{
	return [self showAction];
}

- (void) showOrOpenItem:(MvrVideoItem*) i forAction:(L0MoverItemAction*) a;
{
	if (player)
		return;
	
	player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:i.storage.path]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:player];
	
	[player play];
}

- (void) playerDidFinish:(NSNotification*) n;
{
	L0Log(@"%@", n);
	[player stop];
	[player autorelease]; player = nil;
	[L0Mover finishPerformingMainAction];
}

@end
