//
//  MvrMessage.m
//  Mover3
//
//  Created by ∞ on 14/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrMessage.h"



static NSString* MvrLocalizedStringFromPack(id pack) {
	if (![pack isKindOfClass:[NSDictionary class]])
		return nil;
	
	NSLocale* l = [NSLocale currentLocale];
	id o = [pack objectForKey:[l localeIdentifier]];
	if (!o)
		o = [pack objectForKey:[l objectForKey:NSLocaleLanguageCode]];
	
	if (![o isKindOfClass:[NSString class]])
		o = nil;
	
	return o;
}


@implementation MvrMessageAction

- (id) initWithContentsOfDictionary:(NSDictionary*) d;
{
	self = [super init];
	if (self != nil) {
		
		self.title = MvrLocalizedStringFromPack([d objectForKey:@"MvrTitle"]);
		NSString* urlString = MvrLocalizedStringFromPack([d objectForKey:@"MvrURL"]);
		self.URL = urlString? [NSURL URLWithString:urlString] : nil;
		
		if (!self.title || !self.URL) {
			[self release]; return nil;
		}
		
		self.shouldDisplayInApp = [[d objectForKey:@"MvrInApp"] boolValue];
		self.usesTranslucentTopBar = [[d objectForKey:@"MvrTranslucent"] boolValue];
		
	}
	return self;
}


@synthesize title, URL, shouldDisplayInApp, usesTranslucentTopBar;

- (void) dealloc;
{
	self.title = nil;
	self.URL = nil;
	[super dealloc];
}

+ actionWithContentsOfDictionary:(NSDictionary*) dict;
{
	return [[[self alloc] initWithContentsOfDictionary:dict] autorelease];
}

@end


@implementation MvrMessage

- (id) initWithContentsOfMessageDictionary:(NSDictionary*) dict;
{
	if (self = [super init]) {
		self.identifier = L0As(NSString, [dict objectForKey:@"MvrIdentifier"]);
		if (!self.identifier) {
			[self release];
			return nil;
		}
		
		self.miniTitle = MvrLocalizedStringFromPack([dict objectForKey:@"MvrMiniTitle"]);
		self.title = MvrLocalizedStringFromPack([dict objectForKey:@"MvrTitle"]);
		self.blurb = MvrLocalizedStringFromPack([dict objectForKey:@"MvrBlurb"]);
		if (!self.title || !self.blurb || !self.miniTitle) {
			[self release];
			return nil;
		}
		
		id acts = [dict objectForKey:@"MvrActions"];
		if (![acts isKindOfClass:[NSArray class]]) {
			[self release];
			return nil;
		}
		
		NSMutableArray* actObjects = [NSMutableArray arrayWithCapacity:[acts count]];
		for (id o in acts) {
			if (![o isKindOfClass:[NSDictionary class]]) {
				[self release]; return nil;
			}
			
			MvrMessageAction* action = [MvrMessageAction actionWithContentsOfDictionary:o];
			if (!action) {
				[self release]; return nil;
			}
			
			[actObjects addObject:action];
		}
		self.actions = actObjects;
	}
	
	return self;
}

@synthesize identifier, miniTitle, title, blurb, actions, delegate;

- (void) dealloc
{
	self.title = nil;
	self.blurb = nil;
	self.actions = nil;
	[super dealloc];
}

+ messageWithContentsOfMessageDictionary:(NSDictionary*) dict;
{
	return [[[self alloc] initWithContentsOfMessageDictionary:dict] autorelease];
}

@end
