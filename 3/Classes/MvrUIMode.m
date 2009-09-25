//
//  MvrUIMode.m
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrUIMode.h"

#import "MvrArrowsView.h"

@interface MvrUIMode ()

- (NSString*) keyForDestination:(id) o;
- (NSArray*) unassignedDestinationKeys;

@end


@implementation MvrUIMode

- (id) init
{
	self = [super init];
	if (self != nil) {
		destinations = [NSMutableArray new];
	}
	return self;
}

@synthesize arrowsStratum, backdropStratum;
@synthesize northDestination, eastDestination, westDestination;
@synthesize delegate;

- (void) dealloc;
{
	[backdropStratum release];
	[arrowsStratum release];
	
	[destinations release];
	[northDestination release];
	[eastDestination release];
	[westDestination release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Arrows stratum

- (UIView*) arrowsStratum;
{
	if (!arrowsStratum) {
		self.arrowsStratum = [[[MvrArrowsView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)] autorelease];
	}
	
	return arrowsStratum;
}

- (MvrArrowsView*) arrowsView;
{
	id x = self.arrowsStratum;
	return [x isKindOfClass:[MvrArrowsView class]]? x : nil;
}

#pragma mark -
#pragma mark Destinations

- (NSString*) displayNameForDestination:(id) destination;
{
	L0AbstractMethod();
	return nil;
}

- (NSArray*) unassignedDestinationKeys;
{
	NSMutableArray* keys = [NSMutableArray arrayWithCapacity:3];
	if (!northDestination)
		[keys addObject:@"northDestination"];
	if (!eastDestination)
		[keys addObject:@"eastDestination"];
	if (!westDestination)
		[keys addObject:@"westDestination"];
	
	return keys;
}

- (NSString*) keyForDestination:(id) dest;
{
	if ([northDestination isEqual:dest])
		return @"northDestination";
	else if ([eastDestination isEqual:dest])
		return @"eastDestination";
	else if ([westDestination isEqual:dest])
		return @"westDestination";
	
	return nil;
}

- (NSMutableArray*) mutableDestinations;
{
	return [self mutableArrayValueForKey:@"destinations"];
}

- (NSArray*) destinations;
{
	return [[destinations copy] autorelease];
}

- (void) insertObject:(id) dest inDestinationsAtIndex:(NSUInteger) i;
{
	[destinations insertObject:dest atIndex:i];
	
	NSArray* keys = [self unassignedDestinationKeys];
	if ([keys count] > 0) {
		srandomdev();
		NSString* key = [keys objectAtIndex:random() % [keys count]];
		[self setValue:dest forKey:key];
	}
}

- (void) removeObjectFromDestinationsAtIndex:(NSUInteger) i;
{
	id o = [destinations objectAtIndex:i];
	[[o retain] autorelease];
	[destinations removeObjectAtIndex:i];
	
	NSString* key = [self keyForDestination:o];
	if (key) {
		id replacement = nil;
		
		for (id candidate in destinations) {
			if (![self keyForDestination:candidate]) {
				replacement = candidate;
				break;
			}
		}
		
		[self setValue:replacement forKey:key];
	}	
}

- (void) setNorthDestination:(id) dest;
{
	if (dest != northDestination) {
		[northDestination release];
		northDestination = [dest retain];
		
		[self.arrowsView setNorthViewLabel:dest? [self displayNameForDestination:dest] : nil];
	}
}

- (void) setEastDestination:(id) dest;
{
	if (dest != eastDestination) {
		[eastDestination release];
		eastDestination = [dest retain];
		
		[self.arrowsView setEastViewLabel:dest? [self displayNameForDestination:dest] : nil];
	}
}

- (void) setWestDestination:(id) dest;
{
	if (dest != westDestination) {
		[westDestination release];
		westDestination = [dest retain];
		
		[self.arrowsView setWestViewLabel:dest? [self displayNameForDestination:dest] : nil];
	}
}

- (id) destinationAtDirection:(MvrDirection) d;
{
	if (d == kMvrDirectionNorth)
		return self.northDestination;
	else if (d == kMvrDirectionEast)
		return self.eastDestination;
	else if (d == kMvrDirectionWest)
		return self.westDestination;
	else
		return nil;
}

- (MvrDirection) directionForDestination:(id) d;
{
	if ([northDestination isEqual:d])
		return kMvrDirectionNorth;
	else if ([eastDestination isEqual:d])
		return kMvrDirectionEast;
	else if ([westDestination isEqual:d])
		return kMvrDirectionWest;
	
	return kMvrDirectionNone;
}

#pragma mark -
#pragma mark Sending and receiving.

- (void) sendItem:(MvrItem*) i toDestinationAtDirection:(MvrDirection) dest;
{
	L0AbstractMethod();
}

@end
