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

#import "MvrItemStorage.h"
#import "MvrItem.h"
#import "MvrUTISupport.h"

@interface MvrWiFiTool : NSObject <DDCliApplicationDelegate>
{
	NSString* name;
	NSString* temporary, * persistent, * identifier;
	MvrWiFi* wifi;
	L0KVODispatcher* kvo;
}

@property(copy) NSString* name;

@property(copy) NSString* temporary;
@property(copy) NSString* persistent;

@property(copy) NSString* identifier;

@property(retain, setter=private_setWiFi:) MvrWiFi* wifi;

- (id) makeItemWithFile:(NSString*) f type:(NSString*) type;
- (id) makeItemWithFile:(NSString*) f;

@end

@implementation MvrWiFiTool

- (void) application: (DDCliApplication *) app
    willParseOptions: (DDGetoptLongParser *) optionParser;
{
	DDGetoptOption optionTable[] = 
    {
        // Long, Short, Argument options
        {@"name", 'n', DDGetoptRequiredArgument},
        {@"temporary", 't', DDGetoptRequiredArgument},
        {@"persistent", 'p', DDGetoptRequiredArgument},
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
	
	MvrStorageSetTemporaryDirectory(self.temporary);
	MvrStorageSetPersistentDirectory(self.persistent);
	
	kvo = [[L0KVODispatcher alloc] initWithTarget:self];
	
	self.wifi = [[MvrWiFi alloc] initWithBroadcastedName:self.name];
	
	[kvo observe:@"channels" ofObject:wifi.modernWiFi usingSelector:@selector(channelsOfObject:changed:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
	
	[kvo observe:@"jammed" ofObject:wifi.modernWiFi options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld usingBlock:
	 ^(id object, NSDictionary* change) {
			
		L0Log(@"%@", change);
		
	 }];
	
	self.wifi.modernWiFi.enabled = YES;
	
	[[NSRunLoop currentRunLoop] run];
	
	[kvo release]; kvo = nil;
	[c release];
	
	return 0;
}

- (void) channelsOfObject:(id) modernWiFi changed:(NSDictionary*) change;
{
	L0Log(@"%@", change);
	[kvo forEachSetChange:change
	  invokeBlockForInsertion:
	 ^(id added){
	  
		 [kvo observe:@"outgoingTransfers" ofObject:added usingSelector:@selector(outgoingTransfersOfObject:changed:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
		 
	 }
	  removal:
	 ^(id removed) {
		 
		 [kvo endObserving:@"outgoingTransfers" ofObject:removed];
		 		 
	 }];
}

- (void) outgoingTransfersOfObject:(id) modernWiFi changed:(NSDictionary*) change;
{
	L0Log(@"%@", change);
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
