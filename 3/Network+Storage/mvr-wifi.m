//
//  mvr-wifi.m
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DDCommandLineInterface/DDCommandLineInterface.h>

#import "MvrWiFi.h"
#import "MvrModernWiFi.h"
#import "MvrLegacyWiFi.h"

#import "MvrItemStorage.h"
#import "MvrItem.h"
#import "MvrUTISupport.h"
#import "MvrStorageCentral.h"

#import "MvrIncoming.h"

#import "MvrPlatformInfo.h"
#import "MvrMetadataStorage.h"

#import "MvrScannerObserver.h"

#import <MuiKit/MuiKit.h>

static const NSKeyValueObservingOptions kMvrKVOOptions = NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionInitial;

static id MvrBlockForLoggingPropertyChange(NSString* propertyName) {
	id block = ^(id object, NSDictionary* change) {
		L0CLog(@"%@.%@ == %@ (from %@)", object, propertyName, L0KVOChangedValue(change), L0KVOPreviousValue(change));
	};
	
	return [[block copy] autorelease];
}

@interface MvrWiFiTool : NSObject <DDCliApplicationDelegate, MvrScannerObserverDelegate>
{
	NSString* name;
	NSString* temporary, * persistent, * identifier;
	MvrWiFi* wifi;
	L0KVODispatcher* kvo;
	
	MvrStorageCentral* central;
	
	int port, legacyPort;
	
	BOOL stopped;
}

@property(copy) NSString* name;

@property(copy) NSString* temporary;
@property(copy) NSString* persistent;

@property(copy) NSString* metadata;

@property(copy) NSString* identifier;

@property(retain, setter=private_setWiFi:) MvrWiFi* wifi;
@property(readonly) MvrStorageCentral* central;

- (id) makeItemWithFile:(NSString*) f type:(NSString*) type;
- (id) makeItemWithFile:(NSString*) f;

@end

#pragma mark -
#pragma mark Platform info

@interface MvrWiFiToolPlatform : NSObject <MvrPlatformInfo, MvrMetadataStorage> {
	L0UUID* identifierForSelf;
	NSDictionary* metadata; NSString* metadataFile;
}

+ sharedInfo;

@property(copy) NSString* metadataFile;

@property(copy) NSString* displayNameForSelf;
@property(readonly) L0UUID* identifierForSelf;

@end

@implementation MvrWiFiToolPlatform

L0ObjCSingletonMethod(sharedInfo)

- (id) init
{
	self = [super init];
	if (self != nil) {
		identifierForSelf = [L0UUID new];
	}
	return self;
}

@synthesize displayNameForSelf, identifierForSelf;

- (NSDictionary*) metadata;
{
	if (!metadata) {
		metadata = [[NSDictionary alloc] initWithContentsOfFile:self.metadataFile];
		L0Log(@"Metadata was loaded = %@", metadata);
	}
	
	return metadata;
}

- (void) setMetadata:(NSDictionary *) d;
{
	if (d != metadata) {
		[metadata release];
		metadata = [d copy];
		
		BOOL saved = [metadata writeToFile:self.metadataFile atomically:YES];
		L0Log(@"Metadata was set to = %@ and saved? = %d", metadata, saved);
	}
}

@synthesize metadataFile;
- (NSString*) metadataFile;
{
	if (!metadataFile)
		self.metadataFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"mvr-wifi.%ld.plist", getpid()]];
	
	return metadataFile;
}

- (void) dealloc;
{
	[identifierForSelf release];
	self.displayNameForSelf = nil;
	[super dealloc];
}

// -----

- (MvrAppVariant) variant;
{
	return kMvrAppVariantNotMover;
}

- (NSString*) variantDisplayName;
{
	return @"mvr-wifi";
}

- (id) platform { return kMvrAppleMacOSXPlatform; }
- (double) version { return kMvrUnknownVersion; }
- (NSString*) userVisibleVersion { return @"n/a"; }

@end



#pragma mark -
#pragma mark Implementation.

@implementation MvrWiFiTool

- (void) setPort:(NSString *) portString;
{
	port = [portString intValue];
}

- (void) setLegacyPort:(NSString *) portString;
{
	legacyPort = [portString intValue];
}

- (void) application: (DDCliApplication *) app
    willParseOptions: (DDGetoptLongParser *) optionParser;
{
	DDGetoptOption optionTable[] = 
    {
        // Long, Short, Argument options
        {@"name", 'n', DDGetoptRequiredArgument},
        {@"port", 'p', DDGetoptRequiredArgument},
        {@"legacyPort", 'L', DDGetoptRequiredArgument},
        {@"temporary", 't', DDGetoptRequiredArgument},
        {@"persistent", 'P', DDGetoptRequiredArgument},
        {@"metadata", 'm', DDGetoptRequiredArgument},
        {@"identifier", 'I', DDGetoptRequiredArgument},
		{nil, 0, 0}
    };
    [optionParser addOptionsFromTable:optionTable];
}

- (int) application: (DDCliApplication *) app
   runWithArguments: (NSArray *) arguments;
{
	if (!self.name) {
		ddprintf(@"Please specify a name with the --name <name> (-n <name>) option.");
		return 1;
	}
	
	[[MvrWiFiToolPlatform sharedInfo] setDisplayNameForSelf:self.name];
	
	if (!self.identifier)
		self.identifier = @"net.infinite-labs.Mover.TestTools.WiFi";
		
	NSConnection* c = [NSConnection serviceConnectionWithName:self.identifier rootObject:self];
	L0Log(@" == Wi-Fi tool registered on connection %@ with name '%@'", c, self.identifier);
	
	MvrStorageSetTemporaryDirectory(self.temporary);
	[[MvrWiFiToolPlatform sharedInfo] setMetadataFile:self.metadata];
	
	if (self.persistent) {
		central = [[MvrStorageCentral alloc] initWithPersistentDirectory:self.persistent metadataStorage:[MvrWiFiToolPlatform sharedInfo]];
		L0Log(@" == Will store data that arrives during this section in %@ using %@", self.persistent, central);
	}
	
	
	if (port == 0)
		port = kMvrModernWiFiPort;
	if (legacyPort == 0)
		legacyPort = kMvrLegacyWiFiPort;
	
	self.wifi = [[MvrWiFi alloc] initWithPlatformInfo:[MvrWiFiToolPlatform sharedInfo] modernPort:port legacyPort:legacyPort];
	MvrScannerObserver* observer = [[MvrScannerObserver alloc] initWithScanner:self.wifi delegate:self];
	
	MvrScannerObserver* testObserverForModern = [[MvrScannerObserver alloc] initWithScanner:self.wifi.modernWiFi delegate:self];
	MvrScannerObserver* testObserverForLegacy = [[MvrScannerObserver alloc] initWithScanner:self.wifi.legacyWiFi delegate:self];
	
	self.wifi.enabled = YES;
	
	while (!stopped)
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
	
	[observer release];
	[testObserverForLegacy release];
	[testObserverForModern release];
	
	return 0;
}

- (void) scanner:(id <MvrScanner>) s didChangeJammedKey:(BOOL) jammed;
{
	L0Log(@"%@.jammed == %d", s, jammed);
}

- (void) scanner:(id <MvrScanner>) s didChangeEnabledKey:(BOOL) enabled;
{
	L0Log(@"%@.enabled == %d", s, enabled);
}

- (void) scanner:(id <MvrScanner>) s didAddChannel:(id <MvrChannel>) channel;
{
	L0Log(@"%@.channels += %@", s, channel);
}

- (void) scanner:(id <MvrScanner>) s didRemoveChannel:(id <MvrChannel>) channel;			
{
	L0Log(@"%@.channels -= %@", s, channel);
}

- (void) channel:(id <MvrChannel>) c didBeginReceivingWithIncomingTransfer:(id <MvrIncoming>) incoming;
{
	L0Log(@"%@.incomingTransfers += %@", c, incoming);
}

- (void) channel:(id <MvrChannel>) c didBeginSendingWithOutgoingTransfer:(id <MvrOutgoing>) outgoing;
{
	L0Log(@"%@.outgoingTransfers += %@", c, outgoing);
}

- (void) outgoingTransferDidEndSending:(id <MvrOutgoing>) outgoing;
{
	L0Log(@"(its channel).outgoingTransfers -= %@", outgoing);
}

// i == nil if cancelled.
- (void) incomingTransfer:(id <MvrIncoming>) incoming didEndReceivingItem:(MvrItem*) i;
{
	L0Log(@"(its channel).incomingTransfers -= %@ (finished with %@)", incoming, i);
	
	if (i)
		[central.mutableStoredItems addObject:i];
}

#pragma mark -
#pragma mark DO methods.

- (void) stop;
{
	stopped = YES;
}

- (id) makeItemWithFile:(NSString*) f type:(NSString*) type;
{
	NSError* e;
	MvrItemStorage* s = [MvrItemStorage itemStorageFromFileAtPath:f error:&e];
	if (!s)
		return e;
	
	return [MvrItem itemWithStorage:s type:type metadata:[NSDictionary dictionary]];
}

- (id) makeItemWithFile:(NSString *)f;
{
	return [self makeItemWithFile:f type:(id) kUTTypeData];
}

#pragma mark Boilerplate

@synthesize name, wifi, central, temporary, persistent, identifier, metadata;
- (void) dealloc;
{
	self.temporary = nil;
	self.persistent = nil;
	self.identifier = nil;
	self.name = nil;
	self.wifi = nil;
	[super dealloc];
}

@end

int main(int argc, const char* argv[]) {
	return DDCliAppRunWithClass([MvrWiFiTool class]);
}
