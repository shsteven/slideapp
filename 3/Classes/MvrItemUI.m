//
//  MvrItemUI.m
//  Mover3
//
//  Created by ∞ on 17/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrItemUI.h"
#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrUTISupport.h"

#import "MvrAppDelegate.h"

#pragma mark -
#pragma mark Item actions.

@interface MvrItemAction ()

- (id) initWithDisplayName:(NSString *)string target:(id) target selector:(SEL) selector;

@property(copy, setter=private_setDisplayName:) NSString* displayName;

@end


@implementation MvrItemAction

- (id) initWithDisplayName:(NSString*) string;
{
	if (self = [super init])
		self.displayName = string;
	
	return self;
}

- (id) initWithDisplayName:(NSString *)string target:(id) t selector:(SEL) s;
{
	if (self = [self initWithDisplayName:string]) {
		target = t; selector = s;
	}
	
	return self;
}

@synthesize displayName, available;

- (void) dealloc
{
	self.displayName = nil;
	[super dealloc];
}

+ actionWithDisplayName:(NSString*) name target:(id) target selector:(SEL) selector;
{
	return [[[self alloc] initWithDisplayName:name target:target selector:selector] autorelease];
}

- (void) performActionWithItem:(id) i;
{
	if (!target || !selector)
		L0AbstractMethod();
	
	// -performAction:self withItem:i
	[target performSelector:selector withObject:self withObject:i];
}

@end

#pragma mark Item sources.

static NSMutableArray* MvrItemSources = nil;

@interface MvrItemSource ()

- (id) initWithDisplayName:(NSString*) name correspondingUI:(MvrItemUI*) ui;

@property(setter=private_setDisplayName:, copy) NSString* displayName;
@property(setter=private_setCorrespondingUI:, retain) MvrItemUI* correspondingUI;

@end


@implementation MvrItemSource

+ registeredItemSources;
{
	if (MvrItemSources)
		return MvrItemSources;
	
	return [NSArray array];
}

- (void) registerSource;
{
	if (!MvrItemSources)
		MvrItemSources = [NSMutableArray new];
	
	if (![MvrItemSources containsObject:self])
		[MvrItemSources addObject:self];
}

+ itemSourceWithDisplayName:(NSString*) name;
{
	return [[[self alloc] initWithDisplayName:name] autorelease];
}

- (id) initWithDisplayName:(NSString *)name;
{
	return [self initWithDisplayName:name correspondingUI:nil];
}

+ itemSourceWithDisplayName:(NSString*) name correspondingUI:(MvrItemUI*) ui;
{
	return [[[self alloc] initWithDisplayName:name correspondingUI:ui] autorelease];
}

- (id) initWithDisplayName:(NSString*) name correspondingUI:(MvrItemUI*) ui;
{
	if (self = [super init]) {
		self.displayName = name;
		self.correspondingUI = ui;
	}
	
	return self;
}

@synthesize displayName, correspondingUI;

- (void) dealloc;
{
	[displayName release];
	[correspondingUI release];
	[super dealloc];
}

- (void) beginAddingItem;
{
	NSAssert(self.correspondingUI, @"Override -beginAddingItem in MvrItemSource if you don't want to delegate item addition to an item UI controller.");
	[self.correspondingUI beginAddingItemForSource:self];
}

- (BOOL) available;
{
	return YES;
}

@end

#pragma mark -
#pragma mark Item UI controllers

@interface MvrItemUI ()
- (void) sendItemByEmail:(id) i;
@end


@implementation MvrItemUI

static NSMutableDictionary* MvrItemClassesToUIs = nil;

#pragma mark Registering and retrieving

+ (void) registerUI:(MvrItemUI*) ui forItemClass:(Class) c;
{
	if (!MvrItemClassesToUIs)
		MvrItemClassesToUIs = [NSMutableDictionary new];
	
	[MvrItemClassesToUIs setObject:ui forKey:NSStringFromClass(c)];
}

+ (void) registerClass;
{
	id myself = [[self new] autorelease];
	
	for (Class c in [self supportedItemClasses])
		[self registerUI:myself forItemClass:c];
	
	// [MvrItemSources addObjectsFromArray:[self supportedItemSources]];
	// we don't do the above because we may have item sources shared between different item UIs. For example, the camera item source can produce either videos or photos, so both item ui controllers claim it as their own and we display it only once.
	for (id source in [myself supportedItemSources])
		[source registerSource];
}

+ (MvrItemUI*) UIForItemClass:(Class) i;
{
	Class current = i; id ui;
	do {
		if (!current || [current isEqual:[MvrItem class]])
			return nil;
		
		ui = [MvrItemClassesToUIs objectForKey:NSStringFromClass(current)];
		current = [current superclass];
	} while (ui == nil);
	
	return ui;
}

+ (MvrItemUI*) UIForItem:(MvrItem*) i;
{
	return [self UIForItemClass:[i class]];
}

#pragma mark Funnels

- (NSArray*) supportedItemSources;
{
	return [NSArray array];
}

+ (NSSet*) supportedItemClasses;
{
	L0AbstractMethod();
	return nil;
}

#pragma mark Working with items

- (void) beginAddingItemForSource:(MvrItemSource*) s;
{
	L0AbstractMethod();
}

- (UIImage*) representingImageWithSize:(CGSize) size forItem:(id) i;
{
	L0AbstractMethod();
	return nil;
}

- (void) didReceiveItem:(id) i;
{
}

- (void) didStoreItem:(id) i;
{	
}

#pragma mark Actions

- (MvrItemAction*) mainActionForItem:(id) i;
{
	return nil;
}

// Additional actions, which are shown on the action menu.
- (NSArray*) additionalActionsForItem:(id) i;
{
	return [NSArray array];
}

- (BOOL) hasAdditionalActionsAvailableForItem:(id) i;
{
	NSArray* as = [self additionalActionsForItem:i];
	if ([as count] == 0) return NO;
	
	for (MvrItemAction* a in as) {
		if (a.available) return YES;
	}
	
	return NO;
}

- (MvrItemAction*) showAction;
{
	return [MvrItemAction actionWithDisplayName:NSLocalizedString(@"Show", @"Title for the 'Show' action") target:self selector:@selector(performShowOrOpenAction:withItem:)];
}
- (MvrItemAction*) openAction;
{
	return [MvrItemAction actionWithDisplayName:NSLocalizedString(@"Open", @"Title for the 'Open' action") target:self selector:@selector(performShowOrOpenAction:withItem:)];
}

// Copies the item to the clipboard.
- (MvrItemAction*) clipboardAction;
{
	return [MvrItemAction actionWithDisplayName:NSLocalizedString(@"Copy", @"Title for the 'Copy' action") target:self selector:@selector(performCopyAction:withItem:)];
}

// Send the item via e-mail.
- (MvrItemAction*) sendByEmailAction;
{
	MvrItemAction* a = [MvrItemAction actionWithDisplayName:NSLocalizedString(@"Send by E-mail", @"Title for the 'Send by E-mail' action") target:self selector:@selector(performSendByEmail:withItem:)];
	a.available = [MFMailComposeViewController canSendMail];
	return a;
}

- (void) performShowOrOpenAction:(MvrItemAction*) showOrOpen withItem:(id) i;
{
	L0AbstractMethod();
}

- (void) performCopyAction:(MvrItemAction*) copy withItem:(id) i;
{
	[[UIPasteboard generalPasteboard] setData:((MvrItem*)i).storage.data forPasteboardType:((MvrItem*)i).type];
}

- (BOOL) showsOverlayWhilePreparingEmailForItem:(id) i;
{
	return NO;
}

- (void) performSendByEmail:(MvrItemAction*) send withItem:(id) i;
{
	if ([self showsOverlayWhilePreparingEmailForItem:i]) { 
		[MvrApp() beginDisplayingOverlayViewWithLabel:NSLocalizedString(@"Preparing e-mail\u2026", @"Overlay view label while preparing e-mail")];
		[self performSelector:@selector(sendItemByEmail:) withObject:i afterDelay:0.01];
	} else
		[self sendItemByEmail:i];
}

- (void) sendItemByEmail:(id) i;
{
	MFMailComposeViewController* ctl = [[MFMailComposeViewController new] autorelease];
	NSData* data; NSString* mimeType, * fileName, * body; BOOL isHTML;
	[self fromItem:i getData:&data mimeType:&mimeType fileName:&fileName messageBody:&body isHTML:&isHTML];
	
	if (data && mimeType && fileName)
		[ctl addAttachmentData:data mimeType:mimeType fileName:fileName];
	
	if (body)
		[ctl setMessageBody:body isHTML:isHTML];
	
	ctl.mailComposeDelegate = self;
	
	[MvrApp() presentModalViewController:ctl];
	[MvrApp() endDisplayingOverlayView];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
{
	[controller dismissModalViewControllerAnimated:YES];
}

- (void) fromItem:(id) i getData:(NSData**) data mimeType:(NSString**) mimeType fileName:(NSString**) fileName messageBody:(NSString**) body isHTML:(BOOL*) html;
{
	NSAssert(data != nil && mimeType != nil && fileName != nil && body != nil && html != nil, @"All pointer args must be nonnil");
	
	*data = [i storage].data; // !!!
	
	CFStringRef mime = UTTypeCopyPreferredTagWithClass((CFStringRef) [i type], kUTTagClassMIMEType);
	if (mime)
		*mimeType = [NSMakeCollectable(mime) autorelease];
	else
		*mimeType = @"application/octet-stream";
	
	NSString* ext = [[i storage].path pathExtension];
	if ([ext isEqual:@""]) {
		ext = (NSString*) UTTypeCopyPreferredTagWithClass((CFStringRef) [i type], kUTTagClassFilenameExtension);
		ext = [NSMakeCollectable(ext) autorelease];
		
		if (!ext)
			ext = [self pathExtensionForItem:i];
	}
	
	*fileName = [NSString stringWithFormat:NSLocalizedString(@"Shared.%@", @"Template for e-mail attachment name"), ext];
	
	*body = nil;
}

- (NSString*) pathExtensionForItem:(id) i;
{
	L0AbstractMethod();
	return nil;
}

- (BOOL) isItemRemovable:(id) i;
{
	return YES;
}

- (BOOL) isItemSavedElsewhere:(id) i;
{
	return NO;
}

- (NSString*) accessibilityLabelForItem:(id) i;
{
	L0AbstractMethod();
	return nil;
}

@end
