//
//  L0BluetoothPeer.h
//  Mover
//
//  Created by ∞ on 05/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L0MoverPeer.h"

@interface L0BluetoothPeer : L0MoverPeer {
	NSString* peerID;
	NSString* displayName;
}

- (id) initWithPeerID:(NSString*) ident displayName:(NSString*) displayName;

@property(readonly) NSString* peerID;

@end
