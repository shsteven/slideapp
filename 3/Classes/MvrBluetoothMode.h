//
//  MvrBluetoothMode.h
//  Mover3
//
//  Created by ∞ on 05/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MvrUIMode.h"
#import "MvrBluetoothScanner.h"

#import "Network+Storage/MvrScannerObserver.h"

@interface MvrBluetoothMode : MvrUIMode <GKPeerPickerControllerDelegate, MvrScannerObserverDelegate> {
	MvrBluetoothScanner* scanner;
	GKPeerPickerController* peerPicker;
	MvrScannerObserver* observer;
	
	BOOL didPickAfterSwitch;
}

- (IBAction) beginPickingPeer;
- (void) stopPickingPeer;

@property(readonly, getter=isAvailable) BOOL available;

@end
