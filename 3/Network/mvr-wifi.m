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

@interface MvrWiFiTool : NSObject <DDCliApplicationDelegate>
{
	NSString* name;
}

@property(copy) NSString* name;

@end

@implementation MvrWiFiTool

- (void) application: (DDCliApplication *) app
    willParseOptions: (DDGetoptLongParser *) optionParser;
{
	DDGetoptOption optionTable[] = 
    {
        // Long, Short, Argument options
        {@"name", 'n', DDGetoptRequiredArgument},
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
	
	L0KVODispatcher* kvo = [[L0KVODispatcher alloc] initWithTarget:self];
	
	MvrWiFi* wifi = [[MvrWiFi alloc] initWithBroadcastedName:self.name];
	[kvo observe:@"channels" ofObject:wifi.modernWiFi usingSelector:@selector(channelsOfObject:changed:) options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
	
	wifi.modernWiFi.enabled = YES;
	
	[[NSRunLoop currentRunLoop] run];
	
	[kvo release];
	[wifi release];
	
	return 0;
}

- (void) channelsOfObject:(id) modernWiFi changed:(NSDictionary*) change;
{
	L0Log(@"%@", change);
}

@synthesize name;
- (void) dealloc;
{
	self.name = nil;
	[super dealloc];
}

@end



int main(int argc, const char* argv[]) {
	return DDCliAppRunWithClass([MvrWiFiTool class]);
}