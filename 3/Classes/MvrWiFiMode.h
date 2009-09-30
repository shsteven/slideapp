//
//  MvrWiFiMode.h
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrUIMode.h"
#import "Network+Storage/MvrScannerObserver.h"
#import "Network+Storage/MvrWiFi.h"

@interface MvrWiFiMode : MvrUIMode <MvrScannerObserverDelegate> {
	MvrWiFi* wifi;
	MvrScannerObserver* observer;
	
	UIView* connectionStateDrawerView;
	UILabel* connectionStateInfo;
	UIImageView* connectionStateImage;
}

@property(retain) IBOutlet UIView* connectionStateDrawerView;

@property(assign) IBOutlet UILabel* connectionStateInfo;
@property(assign) IBOutlet UIImageView* connectionStateImage;

@end
