//
//  MvrWiFiMode.h
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrUIMode.h"
#import "Network+Storage/MvrScannerObserver.h"
#import "Network+Storage/MvrWiFi.h"

@interface MvrWiFiMode : MvrUIMode <MvrScannerObserverDelegate> {
	MvrWiFi* wifi;
	MvrScannerObserver* observer;
	
	UILabel* connectionStateInfo;
	UIImageView* connectionStateImage;
	UIView* connectionStateContainer;
	UIView* bluetoothButtonView;
}

@property(assign) IBOutlet UILabel* connectionStateInfo;
@property(assign) IBOutlet UIImageView* connectionStateImage;
@property(assign) IBOutlet UIView* connectionStateContainer;
@property(assign) IBOutlet UIView* bluetoothButtonView;

@end
