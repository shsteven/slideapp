//
//  MvrDevice.m
//  MoverWaypoint
//
//  Created by ∞ on 26/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "MvrDevice.h"

#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrGenericItem.h"
#import "Network+Storage/MvrItemStorage.h"

@implementation MvrDevicesCollectionView

- (NSCollectionViewItem*) newItemForRepresentedObject:(id) object;
{
	return [[MvrDeviceItem alloc] initWithChannel:(id <MvrChannel>) object];
}

@end


@implementation MvrDeviceItem

- (id) initWithChannel:(id <MvrChannel>) chan;
{
	if ([NSCollectionViewItem instancesRespondToSelector:@selector(initWithNibName:bundle:)])
		self = [super initWithNibName:@"MvrDeviceItem" bundle:nil];
	else {
		self = [super init];
		[NSBundle loadNibNamed:@"MvrDeviceItem" owner:self];
	}
	
	if (self) {
		[(id)chan addObserver:self forKeyPath:@"incomingTransfers" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
		[(id)chan addObserver:self forKeyPath:@"outgoingTransfers" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
		self.channel = chan;
	}
		
	return self;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	L0Log(@"%@.%@ changed: %@", object, keyPath, change);
	
	
	if ([self.channel.incomingTransfers count] != 0 || [self.channel.outgoingTransfers count] != 0) {
		[spinnerView setHidden:NO];
		[spinner startAnimation:self];
	} else {
		[spinnerView setHidden:YES];
		[spinner stopAnimation:self];
	}	
}

- (void) awakeFromNib;
{
	[spinner stopAnimation:self];
	[spinnerView setHidden:YES];
}

- (void) sendItemFile:(NSString*) file;
{
	NSString* ext = [file pathExtension];
	NSArray* types = NSMakeCollectable(UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, (CFStringRef) ext, NULL));
	
	MvrItemStorage* is = [MvrItemStorage itemStorageFromFileAtPath:file options:kMvrItemStorageDoNotTakeOwnershipOfFile error:NULL];
	if (is && [types count] > 0) {
		MvrGenericItem* item = [[MvrGenericItem alloc] initWithStorage:is type:[types objectAtIndex:0] metadata:[NSDictionary dictionary]];
		[self.channel beginSendingItem:item];
	}
}

@synthesize channel;
@dynamic view;

@end


@implementation MvrDeviceDropDestinationView

@synthesize owner;

- (void) awakeFromNib;
{
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]]; // TODO more types?
}

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>) sender;
{
	NSArray* files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if ([files count] != 1)
		return NSDragOperationNone;
	else
		return NSDragOperationCopy;
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender;
{
	NSArray* files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	return [files count] == 1;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender;
{
	[self.owner sendItemFile:[[[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType] objectAtIndex:0]];
	return YES;
}

@end
