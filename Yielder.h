//
//  Yielder.h
//  Yielder
//
//  Created by Martin Kiss on 9.1.16.
//  Copyright © 2016 Martin Kiss. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface Yielder<T> : NSEnumerator

- (instancetype)initWithTarget:(NSObject *)target block:(void (^)(id))block;
+ (void)setObject:(id)object forKeyedSubscript:(id)key;

@end

#define Yield(target, invocation) \
    ((NSEnumerator *)({ \
        [[Yielder alloc] initWithTarget:target block:^(typeof(target) innerTarget) { \
            [innerTarget invocation]; \
        }]; \
    }))

#define yield   Yielder.self[(id)self] = 
