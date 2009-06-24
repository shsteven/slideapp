//
//  L0MoverWebPane.h
//  Mover
//
//  Created by ∞ on 24/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface L0MoverWebPane : UIViewController <UIWebViewDelegate> {
	UIWebView* webView;
	NSURL* startingURL;
}

- (id) initWithStartingURL:(NSURL*) url;

@property(readonly, copy) NSURL* startingURL;
@property(readonly, retain) UIWebView* webView;

@end
