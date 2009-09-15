
#import <Foundation/Foundation.h>

@class MvrItem;

@protocol MvrOutgoing <NSObject>

// All KVOable past this point. All could be set on first appaerance, so use NSKeyValueObservingOptionInitial or something.

// When finished == YES, the item was sent.
- (BOOL) finished;

@end
