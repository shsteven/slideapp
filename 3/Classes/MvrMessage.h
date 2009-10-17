//
//  MvrMessage.h
//  Mover3
//
//  Created by ∞ on 14/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MvrMessageDelegate;

// a message has:
// a URL we fetched it from.
// a title.
// a blurb.
// N actions, which can either be of the form 'launch an URL', or of the form 'show a URL in the app via a web view controller'.
// each of the user-visible strings can be localized.

@interface MvrMessageAction : NSObject {
	NSString* title;
	NSURL* URL;
	BOOL shouldDisplayInApp;
	BOOL usesTranslucentTopBar;
	// styling stuff
}

// convenience inits.
- (id) initWithContentsOfDictionary:(NSDictionary*) d;
+ actionWithContentsOfDictionary:(NSDictionary*) dict;

@property(copy) NSString* title;
@property(copy) NSURL* URL;
@property BOOL shouldDisplayInApp;
@property BOOL usesTranslucentTopBar;

@end


@interface MvrMessage : NSObject {
	NSString* identifier;
	
	NSString* miniTitle;
	NSString* title;
	NSString* blurb;
	NSArray* actions;
	
	id <MvrMessageDelegate> delegate;
}

// convenience inits.
- (id) initWithContentsOfMessageDictionary:(NSDictionary*) dict;
+ messageWithContentsOfMessageDictionary:(NSDictionary*) dict;

@property(copy) NSString* identifier;

@property(copy) NSString* miniTitle;
@property(copy) NSString* title;
@property(copy) NSString* blurb;
@property(copy) NSArray* actions;

@property(assign) id <MvrMessageDelegate> delegate;

@end


@protocol MvrMessageDelegate <NSObject>

- (void) message:(MvrMessage*) message didEndShowingWithChosenAction:(MvrMessageAction*) action;

@end
