//
//  L0MoverTextViewer.h
//  Mover
//
//  Created by ∞ on 15/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "L0TextItem.h"

@interface L0MoverTextViewer : UIViewController {
	L0TextItem* item;
	id delegate;
	SEL didDismissSelector;
	
	UITextView* textView;
}

+ navigationControllerWithViewerForItem:(L0TextItem*) i delegate:(id) d didDismissSelector:(SEL) s;
- (id) initWithItem:(L0TextItem*) item delegate:(id) delegate didDismissSelector:(SEL) didDismissSelector;

@property(assign) IBOutlet UITextView* textView;

@end
