//
//  MvrTransferController.m
//  Mover Connect
//
//  Created by ∞ on 01/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrTransferController.h"

#import "Network+Storage/MvrChannel.h"
#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrPacketParser.h"

#import "Network+Storage/MvrGenericItem.h"
#import "Network+Storage/MvrItemStorage.h"

#import "MvrTextItem.h"
#import "MvrBookmarkItem.h"

#import "MvrAppDelegate_Mac.h"


static NSArray* MvrTypeForExtension(NSString* ext) {
	if ([ext isEqual:@"m4v"])
		return [NSArray arrayWithObject:(id) kUTTypeMPEG4];
	
	return NSMakeCollectable(UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, (CFStringRef) ext, NULL));
}


@implementation MvrTransferController

- (id) init;
{
	if (self = [super init]) {
		[MvrPacketParser setAutomaticConsumptionThreshold:1024 * 1024];
		
		channels = [NSMutableSet new];
		channelsByIncoming = [L0Map new];

		wifi = [[MvrModernWiFi alloc] initWithPlatformInfo:self serverPort:kMvrModernWiFiConduitPort options:kMvrUseConduitService|kMvrAllowBrowsingForConduitService|kMvrAllowConnectionsFromConduitService];
		wifiObserver = [[MvrScannerObserver alloc] initWithScanner:wifi delegate:self];
	}
	
	return self;
}

- (BOOL) enabled;
{
	return wifi.enabled;
}
- (void) setEnabled:(BOOL) e;
{
	wifi.enabled = e;
}

@synthesize channels;


#pragma mark Sending files

- (void) sendItemFile:(NSString*) file throughChannel:(id <MvrChannel>) c;
{
	NSString* title = [[NSFileManager defaultManager] displayNameAtPath:file];
	
	NSString* ext = [file pathExtension];
	NSArray* types = MvrTypeForExtension(ext);
	
	NSString* filename = [file lastPathComponent];
	NSDictionary* md = [NSDictionary dictionaryWithObjectsAndKeys:
						title, kMvrItemTitleMetadataKey,
						filename, kMvrItemOriginalFilenameMetadataKey,
						nil];
	
	MvrItemStorage* is = [MvrItemStorage itemStorageFromFileAtPath:file options:kMvrItemStorageDoNotTakeOwnershipOfFile error:NULL];
	if (is && [types count] > 0) {
		MvrGenericItem* item = [[MvrGenericItem alloc] initWithStorage:is type:[types objectAtIndex:0] metadata:md];
		[c beginSendingItem:item];
	}
}

- (void) sendItemFile:(NSString*) file;
{
	if ([channels count] == 1)
		[self sendItemFile:file throughChannel:[channels anyObject]];
	else
		[MvrApp() beginPickingChannelWithDelegate:self selector:@selector(didPickChannel:forSendingFile:) context:file];
}

- (void) didPickChannel:(id <MvrChannel>)chan forSendingFile:(NSString*) file;
{
	[self sendItemFile:file throughChannel:chan];
}

- (BOOL) canSendFile:(NSString*) path;
{
	
	BOOL isDir;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] || isDir)
		return NO;
	else
		return YES;
	
}

#pragma mark Sending pasteboards

- (NSArray*) knownPasteboardTypes;
{
	return [NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, NSTIFFPboardType, NSURLPboardType, (id) kUTTypePNG, nil];
}

- (BOOL) canSendContentsOfPasteboard:(NSPasteboard*) pb;
{
	L0Log(@"%@", [pb types]);
	
	BOOL containsKnownType = NO;
	
	NSArray* types = [pb types];
	for (id x in [self knownPasteboardTypes]) {
		if ([types containsObject:x]) {
			containsKnownType = YES;
			break;
		}
	}
	
	NSArray* files = L0As(NSArray, [pb propertyListForType:NSFilenamesPboardType]);
	for (NSString* file in files) {
		containsKnownType = YES;
		
		if (![self canSendFile:file])
			return NO;
	}
	
	return containsKnownType;
}

- (void) sendContentsOfPasteboard:(NSPasteboard*) pb throughChannel:(id <MvrChannel>) c;
{
	BOOL sent = NO;
	
	for (NSString* path in L0As(NSArray, [pb propertyListForType:NSFilenamesPboardType])) {
		sent = YES;
		[self sendItemFile:path throughChannel:c];
	}
	
	if (sent)
		return;
	
	NSImage* image = [[NSImage alloc] initWithPasteboard:pb];
	if (image && [[image representations] count] > 0 && [[[image representations] objectAtIndex:0] isKindOfClass:[NSBitmapImageRep class]]) {
		
		NSBitmapImageRep* rep = [[image representations] objectAtIndex:0];
		NSData* d = [rep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
		
		MvrItemStorage* s = [MvrItemStorage itemStorageWithData:d];
		MvrGenericItem* item = [[MvrGenericItem alloc] initWithStorage:s type:(id) kUTTypePNG metadata:nil];
		
		[c beginSendingItem:item];
		return;
	}
	
	NSString* str = [pb stringForType:NSStringPboardType];
	if (str) {
		// autodetect URLs.
		NSURL* url = [NSURL URLWithString:str];
		if (url) {
			MvrBookmarkItem* bookmark = [[MvrBookmarkItem alloc] initWithAddress:url];
			if (bookmark) {
				[c beginSendingItem:bookmark];
				return;
			}
		}
		
		MvrTextItem* text = [[MvrTextItem alloc] initWithText:str];
		[c beginSendingItem:text];
	}
}

- (void) sendContentsOfPasteboard:(NSPasteboard*) pb;
{
	if ([channels count] == 1)
		[self sendContentsOfPasteboard:pb throughChannel:[channels anyObject]];
	else
		[MvrApp() beginPickingChannelWithDelegate:self selector:@selector(didPickChannel:forSendingPasteboard:) context:pb];
}

- (void) didPickChannel:(id <MvrChannel>) chan forSendingPasteboard:(NSPasteboard*) pb;
{
	[self sendContentsOfPasteboard:pb throughChannel:chan];
}

#pragma mark Incoming

- (void) channel:(id <MvrChannel>) c didBeginReceivingWithIncomingTransfer:(id <MvrIncoming>) incoming;
{
	[channelsByIncoming setObject:c forKey:incoming];
}

- (NSString*) destinationDirectory;
{
	NSString* downloadDir = MvrApp().preferences.selectedDownloadPath;

	if (MvrApp().preferences.shouldGroupStuffInMoverItemsFolder) {		
		downloadDir = [downloadDir stringByAppendingPathComponent:@"Mover Items.localized"];
		
		NSFileManager* fm = [NSFileManager defaultManager];
		if (![fm fileExistsAtPath:downloadDir]) {
			
			NSAssert([fm createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:NULL], @"We must be able to create the Mover Items directory");
			
			NSString* localizedMoverItemsStuff = [[NSBundle mainBundle] pathForResource:@"LocalizedMoverItemsStrings" ofType:@""];
			[fm copyItemAtPath:localizedMoverItemsStuff toPath:[downloadDir stringByAppendingPathComponent:@".localized"]  error:NULL];
			
		}
	}
	
	return downloadDir;
}

- (void) incomingTransfer:(id <MvrIncoming>) incoming didEndReceivingItem:(MvrItem*) i;
{
	if (!i)
		return;
	
	MvrModernWiFiChannel* chan = [channelsByIncoming objectForKey:incoming];
	
	if (!chan.allowsConduitConnections)
		return;
	
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* downloadDir = [self destinationDirectory];
	BOOL isDir;
	
	NSString* baseName = [i.metadata objectForKey:kMvrItemOriginalFilenameMetadataKey], * ext = nil;
	
	if (!baseName) {
		baseName = [NSString stringWithFormat:NSLocalizedString(@"From %@", @"Base for received filenames"), chan.displayName];
		ext = NSMakeCollectable(UTTypeCopyPreferredTagWithClass((CFStringRef) i.type, kUTTagClassFilenameExtension));
		
		if (!ext && [i.type isEqual:(id) kUTTypeUTF8PlainText])
			ext = @"txt";
	} else {
		ext = [baseName pathExtension];
		baseName = [baseName stringByDeletingPathExtension];
	}
	
	// !!! Check whether the sanitization of the path parts is sane or not.
	baseName = [baseName stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	ext = [ext stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	
	BOOL goOn = ([fm fileExistsAtPath:downloadDir isDirectory:&isDir] && isDir) || [fm createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:NULL];
	
	if (goOn && ext) {
		NSString* attempt = baseName;
		
		int idx = 1;
		BOOL alreadyExists;
		NSString* targetPath;
		do {
			targetPath = [downloadDir stringByAppendingPathComponent:[attempt stringByAppendingPathExtension:ext]];
			alreadyExists = [fm fileExistsAtPath:targetPath];
			
			if (alreadyExists) {
				idx++;
				attempt = [baseName stringByAppendingFormat:@" (%d)", idx];
			}
		} while (alreadyExists);
		
		BOOL ok = [fm copyItemAtPath:i.storage.path toPath:targetPath error:NULL];
		
		if (ok) {
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.DownloadFileFinished" object:targetPath];
			[[NSWorkspace sharedWorkspace] selectFile:targetPath inFileViewerRootedAtPath:@""];
		}
	}
	
	[channelsByIncoming removeObjectForKey:incoming];
	[i invalidate];
}

#pragma mark Channels

- (void) scanner:(id <MvrScanner>) s didAddChannel:(id <MvrChannel>) channel;
{
	MvrModernWiFiChannel* c = (MvrModernWiFiChannel*) channel;
	
	if (c.allowsConduitConnections)
		[[self mutableSetValueForKey:@"channels"] addObject:c];
}

- (void) scanner:(id <MvrScanner>)s didRemoveChannel:(id <MvrChannel>)channel;
{
	[[self mutableSetValueForKey:@"channels"] removeObject:channel];
}

#pragma mark Mover Platform info stuff.

- (NSString *) displayNameForSelf;
{
	NSString* name;
	NSHost* me = [NSHost currentHost];
	
	// 10.6-only
	if ([me respondsToSelector:@selector(localizedName)])
		name = [me localizedName];
	else
		name = [me name];
	
	return name;
}

- (L0UUID*) identifierForSelf;
{
	if (!identifier)
		identifier = [L0UUID UUID];
	
	return identifier;
}

- (MvrAppVariant) variant;
{
	return kMvrAppVariantMoverConduit;
}

- (NSString *) variantDisplayName;
{
	return @"Mover Conect";
}

- (id) platform;
{
	return kMvrAppleMacOSXPlatform;
}

- (double) version;
{
	return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] doubleValue];
}

- (NSString *) userVisibleVersion;
{
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];	
}

@end
