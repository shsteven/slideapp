
#import <Foundation/Foundation.h>

@protocol MvrScanner <NSObject>

// Can be KVO'd. Will fill with id <MvrChannel>s as they're found.
- (NSSet*) channels;

@end