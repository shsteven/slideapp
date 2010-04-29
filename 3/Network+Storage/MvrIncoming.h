
#import <Foundation/Foundation.h>

@class MvrItem;
@protocol MvrChannel;

@protocol MvrIncoming <NSObject>

// Set on first appearance.
- (id <MvrChannel>) channel;

// All KVOable past this point. All could be set on first appearance, so use NSKeyValueObservingOptionInitial or something.

// These can be set if they're found during the transfer but before it finishes.
- (NSString*) type;
// - (NSString*) title;

// Can be 0.0..1.0 or kMvrIndeterminateProgress.
- (float) progress;

// When item != nil or cancelled == YES, the transfer is over.
- (MvrItem*) item;
- (BOOL) cancelled;

@end
