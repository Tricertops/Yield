//
//  Yielder.h
//  Yielder
//
//  Created by Martin Kiss on 9.1.16.
//  Copyright © 2016 Martin Kiss. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Used to wrap method call in NSEnumerator that can be used in for-in loop. Example: for (id x in Yieldable(self, produceObjects:100)) {…}
#define Yieldable(target, invocation) \
    ((NSEnumerator *)({ \
        [[Yielder alloc] initWithTarget:target block:^(typeof(target) innerTarget) { \
            [innerTarget invocation]; \
        }]; \
    }))

//! Use from within a void method to produce multiple values.
#define yield(x) \
    ((void)({ \
        if ([Yielder shouldReturnAfterYielding:(x) fromTarget:(self)]) \
            return; \
    }))


NS_ASSUME_NONNULL_BEGIN

//! Internal class with the multithreading logic.
@interface Yielder<T> : NSEnumerator

- (instancetype)initWithTarget:(NSObject *)target block:(void (^)(id))block;
+ (BOOL)shouldReturnAfterYielding:(nullable T)next fromTarget:(NSObject *)target;

@end

NS_ASSUME_NONNULL_END
