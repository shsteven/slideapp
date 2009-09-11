//
//  L0SlideItem.m
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverItem.h"
#import "MvrStorageCentral.h"

@implementation L0MoverItem

+ (void) registerClass;
{
	for (NSString* type in [self supportedTypes])
		[self registerClass:self forType:type];
}

+ (NSArray*) supportedTypes;
{
	NSAssert(NO, @"Subclasses of L0SlideItem must implement this method.");
	return nil;
}

static NSMutableDictionary* classes = nil;

+ (void) registerClass:(Class) c forType:(NSString*) type;
{
	if (!classes)
		classes = [NSMutableDictionary new];
	
	[classes setObject:c forKey:type];
}

+ (Class) classForType:(NSString*) c;
{
	return [classes objectForKey:c];
}

- (id) init;
{
	if (self = [super init])
		autocache = [NSMutableDictionary new];
		
	return self;
}

- (id) initWithStorage:(MvrItemStorage*) s type:(NSString*) ty title:(NSString*) ti;
{
	if (self = [self init]) {
		self.storage = s;
		self.title = ti;
		self.type = ty;
	}
	
	return self;
}

@synthesize storage;
- (MvrItemStorage*) storage;
{
	if (!storage) {
		L0Log(@"Producing a new item storage object for %@", self);
		storage = [[MvrItemStorage itemStorageWithData:[self produceExternalRepresentation]] retain];
	}
	
	return storage;
}

@synthesize title;
@synthesize type;
@synthesize representingImage;

- (NSData*) produceExternalRepresentation;
{
	NSAssert(NO, @"Subclasses of L0MoverItem must implement this method.");
	return nil;
}

- (void) storeToAppropriateApplication;
{
	// Overridden, optionally, by subclasses.
}

#pragma mark -
#pragma mark Persistance

+ itemWithStorage:(MvrItemStorage*) storage type:(NSString*) type title:(NSString*) title;
{	
	L0MoverItem* item = [[[self classForType:type] alloc] initWithStorage:storage type:type title:title];
	
	return [item autorelease];
}

- (void) clearCache;
{
	L0Log(@"Clearing for %@", self);
	if (storage) {
		[storage clearCache];
		[autocache removeAllObjects];
	}
}

- (id) cachedObjectForKey:(NSString*) key;
{
	L0Log(@"Accessing cached key '%@'", key);
	
	id object = [autocache objectForKey:key];
	if (!object) {
		L0Log(@"Reconstructing...");
		object = [self objectForEmptyCacheKey:key];
		if (object) {
			L0Log(@"Added object of class %@ to the cache for key %@", [object class], key);
			[autocache setObject:object forKey:key];
		}
	}
	
	return object;
}

- (void) setCachedObject:(id) object forKey:(NSString*) key;
{
	L0Log(@"Forcing object of class %@ in the cache for key %@", [object class], key);
	[autocache setObject:object forKey:key];
}

- (void) removeCachedObjectForKey:(NSString*) key;
{
	L0Log(@"Invalidating object in cache for key %@", key);
	[autocache removeObjectForKey:key];
}

- (id) objectForEmptyCacheKey:(NSString*) key;
{
	NSAssert([key length] > 0, @"Must be a nonempty key (that is, not '').");
	NSString* capitalizedKey;
	if ([key length] == 1)
		capitalizedKey = [key uppercaseString];
	else {
		capitalizedKey = [NSString stringWithFormat:@"%@%@", [[key substringToIndex:1] uppercaseString], [key substringFromIndex:1]];
	}
	
	NSString* selString = [NSString stringWithFormat:@"objectForEmpty%@CacheKey", capitalizedKey];
	L0Log(@"Will look for method %@ in order to refill empty cache key %@", selString, key);
	
	SEL s = NSSelectorFromString(selString);
	
	if ([self respondsToSelector:s])
		return [self performSelector:s];
	else {
		L0Log(@"No refill method found. Returning nil.");
		return nil;
	}
}

- (void) dealloc;
{
	[storage release];
	[title release];
	[type release];
	[representingImage release];
	[autocache release];
	[super dealloc];
}

@end

@implementation L0MoverItem (L0BLIPBeaming)

- (BLIPRequest*) contentsAsBLIPRequest;
{
	NSDictionary* properties = [NSDictionary dictionaryWithObjectsAndKeys:
								self.title, @"L0SlideItemTitle",
								self.type, @"L0SlideItemType",
								@"1", @"L0SlideItemWireProtocolVersion",
								nil];
								
	
	return [BLIPRequest requestWithBody:self.storage.data
							 properties:properties];
}

+ (id) itemWithContentsOfBLIPRequest:(BLIPRequest*) req;
{
	NSString* version = [req valueOfProperty:@"L0SlideItemWireProtocolVersion"];
	if (![version isEqualToString:@"1"])
		return nil;
	
	NSString* type = [req valueOfProperty:@"L0SlideItemType"];
	if (!type)
		return nil;
	
	
	NSString* title = [req valueOfProperty:@"L0SlideItemTitle"];
	if (!title)
		return nil;
	
	Class c = [self classForType:type];
	if (!c)
		return nil;
	
	MvrItemStorage* storage = [MvrItemStorage itemStorageWithData:req.body];
	return [[[c alloc] initWithStorage:storage type:type title:title] autorelease];
}

@end
