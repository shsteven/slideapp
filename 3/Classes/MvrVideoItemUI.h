//
//  MvrVideoItemUI.h
//  Mover3
//
//  Created by ∞ on 02/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

#import "MvrItemUI.h"

@interface MvrVideoItemUI : MvrItemUI {
	MPMoviePlayerController* currentPlayer;
}

@end
