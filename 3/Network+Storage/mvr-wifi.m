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

#import "MvrItemStorage.h"
#import "MvrItem.h"
#import "MvrUTISupport.h"

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
	
	int port;
	
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

@implementation MvrWiFiTool

- (void) setPort:(NSString *) portString;
{
	port = [portString intValue];
}

- (void) application: (DDCliApplication *) app
    willParseOptions: (DDGetoptLongParser *) optionParser;
{
	DDGetoptOption optionTable[] = 
    {
        // Long, Short, Argument options
        {@"name", 'n', DDGetoptRequiredArgument},
        {@"port", 'p', DDGetoptRequiredArgument},
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
	
	if (!self.identifier)
		self.identifier = @"net.infinite-labs.Mover.TestTools.WiFi";
		
	NSConnection* c = [[NSConnection serviceConnectionWithName:self.identifier rootObject:self] retain];
	L0Log(@" == Wi-Fi tool registered on connection %@ with name '%@'", c, self.identifier);
	
	MvrStorageSetTemporaryDirectory(self.temporary);
	MvrStorageSetPersistentDirectory(self.persistent);
	
	kvo = [[L0KVODispatcher alloc] initWithTarget:self];
	
	self.wifi = [[MvrWiFi alloc] initWithBroadcastedName:self.name];
	
	if (port != 0)
		self.wifi.modernWiFi.serverPort = port;
	
	[kvo observe:@"enabled" ofObject:wifi.modernWiFi options:kMvrKVOOptions usingBlock:MvrBlockForLoggingPropertyChange(@"enabled")];
	
	[kvo observe:@"channels" ofObject:wifi.modernWiFi usingSelector:@selector(channelsOfObject:changed:) options:kMvrKVOOptions];
	
	[kvo observe:@"jammed" ofObject:wifi.modernWiFi  options:kMvrKVOOptions usingBlock:MvrBlockForLoggingPropertyChange(@"jammed")];
	
	self.wifi.modernWiFi.enabled = YES;
	
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
		 
		 [kvo observe:@"hasOutgoingTransfers" ofObject:added options:kMvrKVOOptions usingBlock:MvrBlockForLoggingPropertyChange(@"hasOutgoingTransfers")];
	 }
	  removal:
	 ^(id removed) {
		 
		 [kvo endObserving:@"outgoingTransfers" ofObject:removed];
		 [kvo endObserving:@"incomingTransfers" ofObject:removed];
		 [kvo endObserving:@"hasOutgoingTransfers" ofObject:removed];
		 
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
