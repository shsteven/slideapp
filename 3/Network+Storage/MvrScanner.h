
#import <Foundation/Foundation.h>

@protocol MvrScanner <NSObject>

// Turns the scanner on and off.
// The scanner MUST clear its .channels key when off.
@property BOOL enabled;

// Can be KVO'd. Will fill with id <MvrChannel>s as they're found.
- (NSSet*) channels;

@end