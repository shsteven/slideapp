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
		ddprintf(@"Please specify a name with the --name (-n) option.");
		return 1;
	}
	
	MvrWiFi* wifi = [[MvrWiFi alloc] initWithBroadcastedName:self.name];
	wifi.modernWiFi.enabled = YES;
	
	[[NSRunLoop currentRunLoop] run];
	
	return 0;
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