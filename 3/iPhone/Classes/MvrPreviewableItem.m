//
//  MvrPreviewableItem.m
//  Mover3
//
//  Created by ∞ on 17/03/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrPreviewableItem.h"
#import "Network+Storage/MvrGenericItem.h"

@interface MvrPreviewableItem ()

+ (NSDictionary*) previewFileExtensionsByType;

@end


@implementation MvrPreviewableItem

+ (NSDictionary*) previewFileExtensionsByType;
{
	static NSDictionary* d = nil; if (!d) {
		d = [[NSDictionary alloc] initWithObjectsAndKeys:
			 @"rtf", (id) kUTTypeRTF,
			 @"pdf", (id) kUTTypePDF,
			 @"ppt", @"com.microsoft.powerpoint.ppt",
			 @"doc", @"com.microsoft.word.doc",
			 @"xls", @"com.microsoft.excel.xls",
			 @"pptx", @"com.microsoft.powerpoint.pptx",
			 @"docx", @"com.microsoft.word.docx",
			 @"xlsx", @"com.microsoft.excel.xlsx",
			 @"pages", @"com.apple.iWork.Pages.pages",
			 @"numbers", @"com.apple.iWork.Numbers.numbers",
			 @"key", @"com.apple.iWork.Keynote.key",
			 @"pages", @"com.apple.iwork.pages.pages",
			 @"numbers", @"com.apple.iwork.numbers.numbers",
			 @"key", @"com.apple.iwork.keynote.key",
			 nil];
	}
	
	return d;
}

+ (NSSet*) supportedTypes;
{
	return [NSSet setWithArray:[[self previewFileExtensionsByType] allKeys]];
}

- (id) initWithStorage:(MvrItemStorage*) s type:(NSString*) t metadata:(NSDictionary*) m;
{
	if (self = [super initWithStorage:s type:t metadata:m]) {
		NSString* ext = [[[self class] previewFileExtensionsByType] objectForKey:t];
		
		BOOL ok = NO;
		if (ext)
			ok = [self.storage setPathExtension:ext error:NULL];
		
		if (!ok) {
			[self release];
			return [[MvrGenericItem alloc] initWithStorage:s type:t metadata:m];
		}
	}
	
	return self;
}

- (id) produceExternalRepresentation;
{
	return [self.storage preferredContentObject];
}

- (BOOL) requiresStreamSupport;
{
	return YES;
}

@end
