//
//  MvrVideoItemController.h
//  Mover3-iPad
//
//  Created by ∞ on 30/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MvrItemController.h"

#import <MediaPlayer/MediaPlayer.h>

@interface MvrVideoItemController : MvrItemController {
	MPMoviePlayerController* pc;
	//IBOutlet UIImageView* image;
}

@end
