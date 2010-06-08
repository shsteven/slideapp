//
//  MvrPreviewVisor.h
//  Mover3
//
//  Created by ∞ on 17/03/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrVisor.h"

@interface MvrPreviewVisor : MvrVisor <UIWebViewDelegate> {
	IBOutlet UIWebView* webView;
}

@end
