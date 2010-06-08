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
#import "MvrImageItem.h"
#import "MvrAppDelegate.h"
#import "MvrAppDelegate+HelpAlerts.h"
#import "MvrTableController.h"

@interface MvrAdActingController ()

@end

static UIImage* MvrUIImageEnsureLoaded(UIImage* i) {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	UIGraphicsBeginImageContext(i.size);
	[i drawAtPoint:CGPointZero];
	UIGraphicsEndImageContext();
	
	[pool drain];
	
	return i;
}


@implementation MvrAdActingController

L0ObjCSingletonMethod(sharedAdController)

- (NSArray*) initialItemsForSender;
{
	NSMutableArray* items = [NSMutableArray arrayWithCapacity:[senderImages count]];
	for (UIImage* i in senderImages)
		[items addObject:[[[MvrImageItem alloc] initWithImage:i type:(id) kUTTypeJPEG] autorelease]];
	
	return items;
}

- (NSArray*) initialItemsForReceiver;
{
	NSMutableArray* items = [NSMutableArray arrayWithCapacity:[receiverImages count]];
	for (UIImage* i in receiverImages)
		[items addObject:[[[MvrImageItem alloc] initWithImage:i type:(id) kUTTypeJPEG] autorelease]];
	
	return items;
}

- (MvrItem*) itemForReceiving;
{
	return [[[MvrImageItem alloc] initWithImage:receivedImage type:(id) kUTTypeJPEG] autorelease];
}

- (void) start;
{
	[MvrApp() suppressHelpAlerts];
	[MvrApp() moveToBluetoothMode];
	
	senderImages = [NSMutableArray new];
	
	for (NSString* path in [[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:kMvrAdActingInitialItemsForSenderDirectory])
		[senderImages addObject:MvrUIImageEnsureLoaded([UIImage imageWithContentsOfFile:path])];

	receiverImages = [NSMutableArray new];

	for (NSString* path in [[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:kMvrAdActingInitialItemsForReceiverDirectory])
		[receiverImages addObject:MvrUIImageEnsureLoaded([UIImage imageWithContentsOfFile:path])];

	NSString* path = [[NSBundle mainBundle] pathForResource:kMvrAdActingReceivedImageName ofType:@"jpg" inDirectory:kMvrAdActingImageDirectory];
	receivedImage = [MvrUIImageEnsureLoaded([UIImage imageWithContentsOfFile:path]) retain];
	
	MvrTableController* table = MvrApp().tableController;
	NSArray* toAdd;
	if ([self.receiver boolValue])
		toAdd = self.initialItemsForReceiver;
	else
		toAdd = self.initialItemsForSender;
	
	[MvrApp().storageCentral.mutableStoredItems removeAllObjects];
	
	for (MvrItem* i in toAdd)
		[table addItem:i animated:NO];
}

L0SynthesizeUserDefaultsGetter(NSNumber, @"MvrAppleAdIsReceiver", isReceiver)

@end

#endif
