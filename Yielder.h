//
//  Yielder.h
//  Yielder
//
//  Created by Martin Kiss on 9.1.16.
//  Copyright © 2016 Martin Kiss. All rights reserved.
//

#import <Foundation/Foundation.h>

#define Yield(target, invocation) \
    ((NSEnumerator *)({ \
        [[Yielder alloc] initWithTarget:target block:^(typeof(target) innerTarget) { \
            [innerTarget invocation]; \
        }]; \
    }))

#define yield   Yielder.self[(id)self] =

NS_ASSUME_NONNULL_BEGIN

@interface Yielder<T> : NSEnumerator

- (instancetype)initWithTarget:(NSObject *)target block:(void (^)(id))block;

@end

NS_ASSUME_NONNULL_END
