#import <Foundation/Foundation.h>
@interface REAValidationProbe : NSObject
- (uint64_t)echo:(uint64_t)value;
@end
@implementation REAValidationProbe
- (uint64_t)echo:(uint64_t)value { return value * 3 + 7; }
@end
uint64_t objc_probe(uint64_t value) {
    @autoreleasepool {
        REAValidationProbe *probe = [REAValidationProbe new];
        return [probe echo:value];
    }
}
