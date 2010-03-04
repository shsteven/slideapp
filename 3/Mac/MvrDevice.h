//
//  MvrDevice.h
//  MoverWaypoint
//
//  Created by ∞ on 26/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Network+Storage/MvrChannel.h"

#if !__OBJC_GC__
#error This class assumes garbage collection is available.
#endif

@interface MvrDevicesCollectionView : NSCollectionView {}
@end

@interface MvrDeviceBaseView : NSView {}
@end


@interface MvrDeviceItem : NSViewController {
	id <MvrChannel> channel;
	
	IBOutlet NSProgressIndicator* spinner;
	IBOutlet NSView* spinnerView;
}

- (id) initWithChannel:(id <MvrChannel>) chan;

@property id <MvrChannel> channel;
@property IBOutlet NSView* view;

- (void) sendItemFile:(NSString*) file;

@end


@interface MvrDeviceDropDestinationView : NSView {
	MvrDeviceItem* owner;
	BOOL dragging;
}

@property(assign) IBOutlet MvrDeviceItem* owner;

@end