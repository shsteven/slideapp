//
//  MvrPreferencesController.h
//  Mover Connect
//
//  Created by ∞ on 03/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MvrPreferencesController : NSObject {
	IBOutlet NSPanel* preferencesPanel;
	
	IBOutlet NSPopUpButton* downloadsFolderPicker;
}

@property(copy) NSString* selectedDownloadPath;
@property(readonly, getter=isSystemDownloadPathSelected) BOOL systemDownloadPathSelected;

@property BOOL shouldGroupStuffInMoverItemsFolder;

@property(readonly) BOOL hasSystemDownloadPath;
@property(readonly) NSString* systemDownloadPath;

@property BOOL runMoverAgent;

// UI stuff
- (IBAction) pickSystemDownloadsFolder:(id) sender;
- (IBAction) pickDownloadsFolder:(id) sender;

// updating
- (void) prepareAgentForUpdating;
- (void) restartAgentIfJustUpdated;

@end


@interface MvrPreferencesControllerIconTransformer : NSValueTransformer {}
@end

@interface MvrPreferencesControllerDisplayNameTransformer : NSValueTransformer {}
@end