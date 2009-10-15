//
//  MvrMessageChecker.m
//  Mover3
//
//  Created by ∞ on 14/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrMessageChecker.h"
#import "MvrAppDelegate.h"

static NSString* MvrURLPartForVariant(MvrAppVariant v) {
	switch (v) {
		case kMvrAppVariantMoverExperimental:
			return @"experimental";
			
		case kMvrAppVariantMoverOpen:
			return @"open";

		case kMvrAppVariantMoverPaid:
			return @"plus";

		case kMvrAppVariantMoverLite:
			return @"lite";

		default:
		case kMvrAppVariantNotMover:
			return @"unknown";
	}
}

@interface MvrMessageChecker ()

- (void) check;

@property(copy) NSNumber* didFailLoading;
@property(copy) NSDate* lastLoadingAttempt;
@property(copy) NSDictionary* lastMessageDictionary;

@property(copy) NSNumber* userWasAskedAboutOptingIn;
@property(copy) NSNumber* firstLaunchPassed;

- (void) endFailing;
- (void) endProcessingData;

@property BOOL shouldRateLimitCheck;

@property(retain) MvrMessage* lastMessage;

- (void) clear;

@end

static void MvrMessageCheckerReachabilityCallback(SCNetworkReachabilityRef reach, SCNetworkReachabilityFlags flags, void* myself) {
	MvrMessageChecker* me = (MvrMessageChecker*) myself;
	me.shouldRateLimitCheck = (flags & kSCNetworkReachabilityFlagsIsWWAN);
}

@implementation MvrMessageChecker

- (id) init
{
	self = [super init];
	if (self != nil) {
		NSDictionary* o = self.lastMessageDictionary;
		if (o)
			self.lastMessage = [MvrMessage messageWithContentsOfMessageDictionary:o];
		
		reach = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "infinite-labs.net");
		SCNetworkReachabilitySetCallback(reach, &MvrMessageCheckerReachabilityCallback, (void*) self);
		SCNetworkReachabilityScheduleWithRunLoop(reach, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopCommonModes);
	}
	
	return self;
}

@synthesize lastMessage, shouldRateLimitCheck;

- (void) dealloc
{
	[self clear];
	
	self.lastMessage = nil;
	
	SCNetworkReachabilityUnscheduleFromRunLoop(reach, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopCommonModes);
	SCNetworkReachabilitySetCallback(reach, NULL, NULL);
	CFRelease(reach);
	
	[super dealloc];
}

#pragma mark -
#pragma mark Periodic checking

- (void) checkIfNeeded;
{
	// first, make sure we have the user's permission to do so.
	if (!self.userWasAskedAboutOptingIn) {
		// we always ask if we don't know whether we've asked, to be sure.
		
		// don't ask on first launch.
		if (![self.firstLaunchPassed boolValue]) {
			self.firstLaunchPassed = [NSNumber numberWithBool:YES];
			return;
		}
				
		UIAlertView* alert = [UIAlertView alertNamed:@"MvrMessageOptIn"];
		alert.cancelButtonIndex = 0;
		alert.delegate = self;
		[alert show];
		return;
	}
	
	// policy: check always on Wi-Fi, once per week on cellular (per day until we succeed if we fail loading).
	if (self.shouldRateLimitCheck) {
		NSDate* lastCheck = self.lastLoadingAttempt;
		NSTimeInterval minimumTimeBeforeRetrying = 
			[self.didFailLoading boolValue]?
			24 * 60 * 60 :
			7 * 24 * 60 * 60;
		
		if (-[lastCheck timeIntervalSinceNow] < minimumTimeBeforeRetrying)
			return;
	}
	
	[self check];
}

#pragma mark -
#pragma mark Opt-in

- (void) alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	self.userWasAskedAboutOptingIn = [NSNumber numberWithBool:YES];
	self.userOptedInToMessages = [NSNumber numberWithBool:(buttonIndex != alert.cancelButtonIndex)];
	[self performSelector:@selector(checkIfNeeded) withObject:nil afterDelay:5.0];
}

#pragma mark -
#pragma mark Displaying messages

- (void) displayMessage;
{
	if (!self.lastMessage)
		return;
	
	self.lastMessage.delegate = self;
	[self.lastMessage show];
}

- (void) message:(MvrMessage *)message didEndShowingWithChosenAction:(MvrMessageAction *)action;
{
	[action perform];
}

#pragma mark -
#pragma mark Checking

- (void) check;
{
	if (connection)
		return;
	
	NSString* messagesBaseURL = @"http://infinite-labs.net/mover/in-app";
	
	NSString* messagesURLString =
		[NSString stringWithFormat:
		 @"%@/%@/%@/%.2f/",
		 messagesBaseURL,
		 [MvrApp() platform],
		 MvrURLPartForVariant([MvrApp() variant]),
		 [MvrApp() version],
		nil];
	NSURL* messagesURL = [NSURL URLWithString:messagesURLString];
	
	[UIApp beginNetworkUse];
	
	receivedData = [NSMutableData new];
	connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:messagesURL] delegate:self];
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
	if ([(NSHTTPURLResponse*)response statusCode] == 404)
		[self endFailing];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	[receivedData appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection;
{
	[self endProcessingData];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	[self endFailing];
}

- (void) endFailing;
{
	[UIApp endNetworkUse];
	[connection cancel];
	self.didFailLoading = [NSNumber numberWithBool:YES];
	self.lastLoadingAttempt = [NSDate date];
	[self clear];
}

- (void) endProcessingData;
{
	[UIApp endNetworkUse];
	MvrMessage* message = nil;
	
	NSString* errorString = nil;
	id o = [NSPropertyListSerialization propertyListFromData:receivedData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
	
	if (!o && errorString) {
		L0LogAlways(@"Could not make a property list out of the server's response. Ouch! (%@)", errorString);
		[errorString release];
		goto cleanup;
	}
	
	if (![o isKindOfClass:[NSDictionary class]])
		goto cleanup;
	
	message = [MvrMessage messageWithContentsOfMessageDictionary:o];
	NSString* oldIdentifier = self.lastMessage.identifier;
	BOOL hasNewMessage = NO;
	
	if (message && ![oldIdentifier isEqual:message.identifier]) {
		hasNewMessage = YES;
		self.lastMessageDictionary = o;
		self.lastMessage = message;
	}

	if (hasNewMessage)
		[self displayMessage];
	
cleanup:
	self.lastLoadingAttempt = [NSDate date];
	self.didFailLoading = [NSNumber numberWithBool:(message == nil)];
	[self clear];
}

- (void) clear;
{
	[connection release]; connection = nil;
	[receivedData release]; receivedData = nil;
}

#pragma mark -
#pragma mark Syntehsized accessors for user-defaults backed stuff.

L0SynthesizeUserDefaultsGetter(NSNumber, @"MvrLastMessageDictionaryCheckAttemptFailed", didFailLoading)
L0SynthesizeUserDefaultsSetter(NSNumber, @"MvrLastMessageDictionaryCheckAttemptFailed", setDidFailLoading:)

L0SynthesizeUserDefaultsGetter(NSDate, @"MvrLastMessageDictionaryCheckAttemptDate", lastLoadingAttempt)
L0SynthesizeUserDefaultsSetter(NSDate, @"MvrLastMessageDictionaryCheckAttemptDate", setLastLoadingAttempt:)

L0SynthesizeUserDefaultsGetter(NSDictionary, @"MvrLastMessageDictionary", lastMessageDictionary)
L0SynthesizeUserDefaultsSetter(NSDictionary, @"MvrLastMessageDictionary", setLastMessageDictionary:)

L0SynthesizeUserDefaultsGetter(NSNumber, @"MvrUserOptedInToMessages", userOptedInToMessages)
L0SynthesizeUserDefaultsSetter(NSNumber, @"MvrUserOptedInToMessages", setUserOptedInToMessages:)

L0SynthesizeUserDefaultsGetter(NSNumber, @"MvrUserWasAskedAboutOptingInToMessages", userWasAskedAboutOptingIn)
L0SynthesizeUserDefaultsSetter(NSNumber, @"MvrUserWasAskedAboutOptingInToMessages", setUserWasAskedAboutOptingIn:)

L0SynthesizeUserDefaultsGetter(NSNumber, @"MvrFirstLaunchPassed", firstLaunchPassed)
L0SynthesizeUserDefaultsSetter(NSNumber, @"MvrFirstLaunchPassed", setFirstLaunchPassed:)

@end

