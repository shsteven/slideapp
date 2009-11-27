//
//  MvrAdController.m
//  Mover3
//
//  Created by ∞ on 27/11/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#if kMvrInstrumentForAds

#import "MvrAdActingController.h"
#import "Network+Storage/MvrUTISupport.h"
#import "Network+Storage/MvrItemStorage.h"
#import "MvrAppDelegate.h"
#import "MvrAppDelegate+HelpAlerts.h"
#import "MvrTableController.h"

@interface MvrAdActingController ()

- (NSArray*) initialItemsInDirectory:(NSString*) dir;

@end



@implementation MvrAdActingController

L0ObjCSingletonMethod(sharedAdController)

- (NSArray*) initialItemsForSender;
{
	return [self initialItemsInDirectory:kMvrAdActingInitialItemsForSenderDirectory];
}

- (NSArray*) initialItemsForReceiver;
{
	return [self initialItemsInDirectory:kMvrAdActingInitialItemsForReceiverDirectory];
}

- (NSArray*) initialItemsInDirectory:(NSString*) dir;
{
	NSMutableArray* items = [NSMutableArray array];
	
	for (NSString* path in [[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:dir]) {
		
		MvrItemStorage* storage = [MvrItemStorage itemStorageFromFileAtPath:path error:NULL];
		NSAssert(storage, @"We must be able to load our initial items from disk");
		
		MvrItem* i = [MvrItem itemWithStorage:storage type:(id) kUTTypeJPEG metadata:[NSDictionary dictionary]];
		NSAssert(i, @"We must be able to create items out of the files on disk");
		
		[items addObject:i];
	}
	
	return items;
}

- (MvrItem*) itemForReceiving;
{
	NSString* path = [[NSBundle mainBundle] pathForResource:kMvrAdActingReceivedImageName ofType:@"jpg"];
	MvrItemStorage* storage = [MvrItemStorage itemStorageFromFileAtPath:path error:NULL];
	NSAssert(storage, @"We must be able to load the item for receiving from disk");
	
	MvrItem* i = [MvrItem itemWithStorage:storage type:(id) kUTTypeJPEG metadata:[NSDictionary dictionary]];
	NSAssert(i, @"We must be able to create the item for receiving out of the file on disk");
	
	return i;
}

- (void) start;
{
	[MvrApp() suppressHelpAlerts];
	[MvrApp() moveToBluetoothMode];
	
	MvrTableController* table = MvrApp().tableController;
	NSArray* toAdd;
	if ([self.receiver boolValue])
		toAdd = self.initialItemsForReceiver;
	else
		toAdd = self.initialItemsForSender;
	
	for (MvrItem* i in toAdd)
		[table addItem:i animated:NO];
}

L0SynthesizeUserDefaultsGetter(NSNumber, @"MvrAppleAdIsReceiver", isReceiver)

@end

#endif
