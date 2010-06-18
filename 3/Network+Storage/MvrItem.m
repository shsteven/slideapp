//
//  MvrItem.m
//  Network+Storage
//
//  Created by ∞ on 13/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrItem.h"

#import "MvrItemStorage.h"
#import "MvrGenericItem.h"

@interface MvrItem ()

@property(retain) MvrItemStorage* storage;

- (MvrItemStorage*) storageFromExternalRepresentation;

@end


@implementation MvrItem

#pragma mark Construction

- (id) init;
{
	if (self = [super init]) {
		autocache = [NSMutableDictionary new];
		metadata = [NSMutableDictionary new];
		itemNotesDictionary = [NSMutableDictionary new];
	}
	
	return self;
}

- (id) initWithStorage:(MvrItemStorage*) s type:(NSString*) t metadata:(NSDictionary*) m;
{
	if (self = [self init]) {
		self.storage = s;
		self.type = t;
		
		if (m && [m count] != 0)
			[self.metadata setDictionary:m];
		else
			[self.metadata setDictionary:[self defaultMetadata]];
	}
	
	return self;
}

@synthesize storage, metadata, type;

- (void) dealloc;
{
	[storage release];
	[type release];
	[metadata release],
	[autocache release];
	[itemNotesDictionary release];
	[super dealloc];
}

- (NSDictionary*) defaultMetadata;
{
	return [NSDictionary dictionary];
}

- (NSString*) title;
{
	NSString* title = [self.metadata objectForKey:kMvrItemTitleMetadataKey];
	if (!title)
		title = @"";
	
	return title;
}

- (void) setTitle:(NSString *) t;
{
	[self.metadata setObject:[[t copy] autorelease] forKey:kMvrItemTitleMetadataKey];
}

#pragma mark Storage

- (id) produceExternalRepresentation;
{
	L0AbstractMethod();
	return nil;
}

- (BOOL) hasStorage;
{
	return storage != nil;
}

- (MvrItemStorage*) storage;
{
	if (!storage)
		self.storage = [self storageFromExternalRepresentation];
	
	return storage;
}

- (MvrItemStorage*) storageFromExternalRepresentation;
{
	NSError* e;
	
	id rep = [self produceExternalRepresentation];
	if ([rep isKindOfClass:[NSData class]]) {
		
		return [MvrItemStorage itemStorageWithData:rep];

	} else if ([rep isKindOfClass:[NSString class]]) {

		MvrItemStorage* s = [MvrItemStorage itemStorageFromFileAtPath:rep error:&e];
		if (!s)
			[NSException raise:@"MvrItemStorageException" format:@"Could not produce item storage from path %@, error was: %@", rep, e];
		return s;
		
	} else {
		[NSException raise:@"MvrItemStorageException" format:@"This object is not suitable to produce an item storage object from: %@", rep];
		return nil;
	}
}

#pragma mark Registering a class

+ (void) registerClass;
{
	for (NSString* type in [self supportedTypes])
		[self registerClass:self forType:type];
	
	NSDictionary* d = [self knownFallbackPathExtensions];
	for (NSString* type in d)
		[self setFallbackPathExtension:[d objectForKey:type] forType:type];
}

+ (NSSet*) supportedTypes;
{
	L0AbstractMethod();
	return nil;
}

+ (NSDictionary*) knownFallbackPathExtensions;
{
	return [NSDictionary dictionary];
}

static NSMutableDictionary* MvrItemTypesToClasses = nil;

+ (void) registerClass:(Class) c forType:(NSString*) type;
{
	if (!MvrItemTypesToClasses)
		MvrItemTypesToClasses = [NSMutableDictionary new];
	
	[MvrItemTypesToClasses setObject:c forKey:type];
}

+ (Class) classForType:(NSString*) c;
{
	// Class cls = [MvrItemTypesToClasses objectForKey:c];
	
	Class cls = Nil;
	
	for (NSString* type in MvrItemTypesToClasses) {
		if (UTTypeConformsTo((CFStringRef) c, (CFStringRef) type)) {
			cls = [MvrItemTypesToClasses objectForKey:c];
			break;
		}
	}
	
	if (!cls)
		cls = [MvrGenericItem class];
	
	return cls;
}

+ (BOOL) canProduceItemForType:(NSString*) type allowGenericItems:(BOOL) generic;
{
	if (generic)
		return YES;
	
	return [MvrItemTypesToClasses objectForKey:type] != nil;
}

+ itemWithStorage:(MvrItemStorage*) s type:(NSString*) t metadata:(NSDictionary*) m;
{
	return [[[[self classForType:t] alloc] initWithStorage:s type:t metadata:m] autorelease];
}

#pragma mark File extensions registry

static NSMutableDictionary* MvrItemFallbackPathExtensions = nil;

+ (void) setFallbackPathExtension:(NSString*) ext forType:(NSString*) type;
{
	if (!MvrItemFallbackPathExtensions)
		MvrItemFallbackPathExtensions = [NSMutableDictionary new];
	
	[MvrItemFallbackPathExtensions setObject:ext forKey:type];
}

+ (NSString*) fallbackPathExtensionForType:(NSString*) type;
{
	return [MvrItemFallbackPathExtensions objectForKey:type];
}

+ (NSSet*) typesForFallbackPathExtension:(NSString*) ext;
{
	if (!MvrItemFallbackPathExtensions)
		return [NSSet set];
	
	return [NSSet setWithArray:[MvrItemFallbackPathExtensions allKeysForObject:ext]];
}

#pragma mark Caching

- (void) clearCache;
{
	L0Note();
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

#pragma mark Legacy support

- (BOOL) requiresStreamSupport;
{
	return NO;
}

#pragma mark Item notes

- (NSDictionary*) itemNotes;
{
	return itemNotesDictionary;
}

- (void) setItemNotes:(NSDictionary *) d;
{
	[itemNotesDictionary setDictionary:(d?: [NSDictionary dictionary])];
}

- (void) setObject:(id) o forItemNotesKey:(NSString*) key;
{
	[self willChangeValueForKey:@"itemNotes"];
	[itemNotesDictionary setObject:o forKey:key];
	[self didChangeValueForKey:@"itemNotes"];
}

- (id) objectForItemNotesKey:(id) o;
{
	return [itemNotesDictionary objectForKey:o];
}


#pragma mark GC support

- (void) invalidate;
{
	[self.storage invalidate];
	self.storage = nil;
}

@end
