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

#import "MvrPlatformInfo.h"

#import <MuiKit/MuiKit.h>

static const NSKeyValueObservingOptions kMvrKVOOptions = NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionInitial;

static id MvrBlockForLoggingPropertyChange(NSString* propertyName) {
	id block = ^(id object, NSDictionary* change) {
		L0Log(@"%@.%@ == %@ (from %@)", object, propertyName, L0KVOChangedValue(change), L0KVOPreviousValue(change));
	};
	
	return [[block copy] autorelease];
}

@interface MvrWiFiTool : NSObject <DDCliApplicationDelegate>
{
	NSString* name;
	NSString* temporary, * persistent, * identifier;
	MvrWiFi* wifi;
	L0KVODispatcher* kvo;
	
	int port, legacyPort;
	
	BOOL stopped;
}

@property(copy) NSString* name;

@property(copy) NSString* temporary;
@property(copy) NSString* persistent;

@property(copy) NSString* identifier;

@property(retain, setter=private_setWiFi:) MvrWiFi* wifi;

- (id) makeItemWithFile:(NSString*) f type:(NSString*) type;
- (id) makeItemWithFile:(NSString*) f;

- (void) updateLoggingForChangesOfKeys:(NSSet*) keys inSetChanges:(NSDictionary*) kvoChanges;

@end

#pragma mark -
#pragma mark Platform info

@interface MvrWiFiToolPlatform : NSObject <MvrPlatformInfo> {
	L0UUID* identifierForSelf;
}

+ sharedInfo;

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
		
	NSConnection* c = [[NSConnection serviceConnectionWithName:self.identifier rootObject:self] retain];
	L0Log(@" == Wi-Fi tool registered on connection %@ with name '%@'", c, self.identifier);
	
	MvrStorageSetTemporaryDirectory(self.temporary);
	MvrStorageSetPersistentDirectory(self.persistent);
	
	kvo = [[L0KVODispatcher alloc] initWithTarget:self];
	
	if (port == 0)
		port = kMvrModernWiFiPort;
	if (legacyPort == 0)
		legacyPort = kMvrLegacyWiFiPort;
	
	self.wifi = [[MvrWiFi alloc] initWithPlatformInfo:[MvrWiFiToolPlatform sharedInfo] modernPort:port legacyPort:legacyPort];
	
	[kvo observe:@"enabled" ofObject:wifi.modernWiFi options:kMvrKVOOptions usingBlock:MvrBlockForLoggingPropertyChange(@"enabled")];
	
	[kvo observe:@"channels" ofObject:wifi.modernWiFi usingSelector:@selector(channelsOfObject:changed:) options:kMvrKVOOptions];
	
	[kvo observe:@"jammed" ofObject:wifi.modernWiFi  options:kMvrKVOOptions usingBlock:MvrBlockForLoggingPropertyChange(@"jammed")];
	
	[kvo observe:@"enabled" ofObject:wifi.legacyWiFi options:kMvrKVOOptions usingBlock:MvrBlockForLoggingPropertyChange(@"enabled")];
	
	[kvo observe:@"channels" ofObject:wifi.legacyWiFi usingSelector:@selector(channelsOfObject:changed:) options:kMvrKVOOptions];
	
	[kvo observe:@"jammed" ofObject:wifi.legacyWiFi  options:kMvrKVOOptions usingBlock:MvrBlockForLoggingPropertyChange(@"jammed")];
	
	self.wifi.modernWiFi.enabled = YES;
	self.wifi.legacyWiFi.enabled = YES;
	
	while (!stopped)
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
	
	[kvo release]; kvo = nil;
	[c release];
	
	return 0;
}

- (void) stop;
{
	stopped = YES;
}

- (void) channelsOfObject:(id) modernWiFi changed:(NSDictionary*) change;
{	
	L0Log(@"%@", change);
	[kvo forEachSetChange:change
	  invokeBlockForInsertion:
	 ^(id added){
	  
		 [kvo observe:@"outgoingTransfers" ofObject:added options:kMvrKVOOptions
		   usingBlock:^(id outgoing, NSDictionary* change) {
			   [self updateLoggingForChangesOfKeys:[NSSet setWithObjects:@"progress", @"finished", nil] inSetChanges:change]; 
		   }];
		 [kvo observe:@"incomingTransfers" ofObject:added options:kMvrKVOOptions
		   usingBlock:^(id outgoing, NSDictionary* change) {
			   [self updateLoggingForChangesOfKeys:[NSSet setWithObjects:@"progress", @"cancelled", @"item", nil] inSetChanges:change]; 
		   }];
		 
	 }
	  removal:
	 ^(id removed) {
		 
		 [kvo endObserving:@"outgoingTransfers" ofObject:removed];
		 [kvo endObserving:@"incomingTransfers" ofObject:removed];
		 
	 }];
}

- (void) updateLoggingForChangesOfKeys:(NSSet*) keys inSetChanges:(NSDictionary*) kvoChanges;
{
	[kvo forEachSetChange:kvoChanges
	  invokeBlockForInsertion: ^(id added) {
		  
		  for (NSString* key in keys)
			  [kvo observe:key ofObject:added options:kMvrKVOOptions usingBlock:MvrBlockForLoggingPropertyChange(key)];
		  
		  
	  } 
	  removal: ^(id removed) {
		  
		  for (NSString* key in keys)
			  [kvo endObserving:key ofObject:removed];
		  
	  }];
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

@synthesize name, wifi, temporary, persistent, identifier;
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
