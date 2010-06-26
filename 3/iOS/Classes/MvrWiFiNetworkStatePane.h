//
//  MvrWiFiNetworkStatePane.h
//  Mover3
//
//  Created by ∞ on 13/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ILViewController.h"
#import "Network+Storage/MvrScannerObserver.h"

@interface MvrWiFiNetworkStatePane : ILViewController <MvrScannerObserverDelegate> {
	MvrScannerObserver* obs;
	
	IBOutlet UILabel* stateLabel;
	IBOutlet UIImageView* stateImage;
}

- (IBAction) switchToBluetooth;

@end
