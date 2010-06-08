//
//  MvrMessageChecker.m
//  Mover3
//
//  Created by ∞ on 14/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrMessageChecker.h"
#import "MvrAppDelegate.h"
#import "MvrAppDelegate+HelpAlerts.h"
#import "MvrPiracyDetector.h"

#import <sys/sysctl.h>

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

static NSString* MvrDeviceCode() {
	const char* sysctlName = "hw.machine";
	size_t length;
	if (sysctlbyname(sysctlName, NULL, &length, NULL, 0) != 0)
		return nil;
	
	char* contents = alloca(length);
	NSString* result = nil;
	if (sysctlbyname(sysctlName, contents, &length, NULL, 0) == 0) {
		result = [[[NSString alloc] initWithCString:contents encoding:NSASCIIStringEncoding] autorelease];
	}
	
	return result;
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
- (void) displayAtEndIfNeeded;

- (void) clear;

- (void) private_setUserOptedInToMessages:(NSNumber*) n;

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
		
		// don't ask while help alerts are suppressed.
		if (MvrApp().helpAlertsSuppressed)
			return;
				
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
	[self performSelector:@selector(checkIfNeeded) withObject:nil afterDelay:50.0];
}

#pragma mark -
#pragma mark Displaying messages

- (void) displayMessage;
{
	if (!self.lastMessage)
		return;
	
	if (![self.userOptedInToMessages boolValue])
		return;
	
	self.lastMessage.delegate = self;
	[self.lastMessage show];
}

- (void) message:(MvrMessage *)message didEndShowingWithChosenAction:(MvrMessageAction *)action;
{
	[action perform];
}

- (void) checkOrDisplayMessage;
{
	displayAtEndAnyway = YES;
	[self check];
}

#pragma mark -
#pragma mark Checking

- (void) check;
{
	if (connection)
		return;
	
	if (![self.userOptedInToMessages boolValue])
		return;
	
	NSString* messagesBaseURL = @"http://infinite-labs.net/mover/in-app";

#if DEBUG
	NSString* envBaseURL = [[[NSProcessInfo processInfo] environment] objectForKey:@"MvrMessagesBaseURL"];
	if (envBaseURL)
		messagesBaseURL = envBaseURL;
#endif
	
	NSString* messagesURLString =
		[NSString stringWithFormat:
		 @"%@/%@/%@/%.2f/",
		 messagesBaseURL,
		 [MvrApp() platform],
		 MvrURLPartForVariant([MvrApp() variant]),
		 [MvrApp() version],
		nil];
	L0Log(@"Will check for news at URL %@", messagesURLString);
	NSURL* messagesURL = [NSURL URLWithString:messagesURLString];
	
	[UIApp beginNetworkUse];
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:messagesURL];
	[request setValue:[UIDevice currentDevice].systemVersion forHTTPHeaderField:@"X-Mover-OS-Version"];
	
	NSString* model = MvrDeviceCode();
	if (model)
		[request setValue:model forHTTPHeaderField:@"X-Mover-Device"];
	
#if !kMvrIsOpen
	
	[request setValue:(MvrIsRunningUnsignedInSeatbeltedEnvironment()? @"yes" : @"no") forHTTPHeaderField:@"X-Mover-Unsigned"];
	
#endif

	receivedData = [NSMutableData new];
	
	[self willChangeValueForKey:@"checking"];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[self didChangeValueForKey:@"checking"];
}

- (BOOL) isChecking;
{
	return connection != nil;
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
	
	[self displayAtEndIfNeeded];
}

- (void) displayAtEndIfNeeded;
{
	if (displayAtEndAnyway) {
		if (self.lastMessage)
			[self displayMessage];
		else
			[[UIAlertView alertNamed:@"MvrNoNews"] show];

		displayAtEndAnyway = NO;
	}
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
	else
		[self displayAtEndIfNeeded];
	
cleanup:
	displayAtEndAnyway = NO;
	self.lastLoadingAttempt = [NSDate date];
	self.didFailLoading = [NSNumber numberWithBool:(message == nil)];
	[self clear];
}

- (void) clear;
{
	[self willChangeValueForKey:@"checking"];
	[connection release]; connection = nil;
	[self didChangeValueForKey:@"checking"];
	
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
L0SynthesizeUserDefaultsSetter(NSNumber, @"MvrUserOptedInToMessages", private_setUserOptedInToMessages:)

- (void) setUserOptedInToMessages:(NSNumber *) n;
{
	if ([n boolValue])
		self.userWasAskedAboutOptingIn = n;
	else {
		if (connection)
			[self endFailing];
		
		self.lastMessage = nil;
		self.lastMessageDictionary = nil;
		self.lastLoadingAttempt = nil;
		self.didFailLoading = [NSNumber numberWithBool:NO];
	}
	
	[self private_setUserOptedInToMessages:n];
}

L0SynthesizeUserDefaultsGetter(NSNumber, @"MvrUserWasAskedAboutOptingInToMessages", userWasAskedAboutOptingIn)
L0SynthesizeUserDefaultsSetter(NSNumber, @"MvrUserWasAskedAboutOptingInToMessages", setUserWasAskedAboutOptingIn:)

L0SynthesizeUserDefaultsGetter(NSNumber, @"MvrFirstLaunchPassed", firstLaunchPassed)
L0SynthesizeUserDefaultsSetter(NSNumber, @"MvrFirstLaunchPassed", setFirstLaunchPassed:)

@end

