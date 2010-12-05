//
//  MvrBluetoothMode.h
//  Mover3
//
//  Created by ∞ on 05/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MvrUIMode.h"
#import "MvrBTScanner.h"

#import "Network+Storage/MvrScannerObserver.h"

@interface MvrBluetoothMode : MvrUIMode <GKPeerPickerControllerDelegate, MvrScannerObserverDelegate, UIAlertViewDelegate> {
	MvrBTScanner* scanner;
	GKPeerPickerController* peerPicker;
	MvrScannerObserver* observer;
	
	BOOL didPickAfterSwitch;
	
	id nextDestination; MvrItem* nextItem;
}

- (IBAction) beginPickingPeer;
- (void) stopPickingPeer;

@property(readonly, getter=isAvailable) BOOL available;
@property(readonly) MvrBTScanner* scanner;

@end

extern BOOL MvrBluetoothIsAvailable();