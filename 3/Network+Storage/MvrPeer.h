
#import <Foundation/Foundation.h>

@class MvrItem;

@protocol MvrPeer <NSObject>

- (NSString*) displayName;

- (void) beginSendingItem:(MvrItem*) item;

@end
