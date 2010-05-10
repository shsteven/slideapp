//
//  UIImage+ILIconTools.m
//  Mover3-iPad
//
//  Created by ∞ on 07/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "UIImage+ILIconTools.h"


@implementation UIImage (ILIconTools)

+ imageApproachingDesiredSize:(CGSize) s amongImages:(NSArray*) images;
{
	if ([images count] == 0)
		return nil;
	
	UIImage* pick = nil;
	for (UIImage* i in images) {
		if (i.size.width > s.width || i.size.height > s.height)
			continue;
		
		if (!pick || (pick.size.width < s.width || pick.size.height < s.height))
			pick = i;
	}
	
	if (!pick)
		pick = [images objectAtIndex:0];
	
	return pick;
}

@end
