//
//  Yielder.h
//  Yielder
//
//  Created by Martin Kiss on 9.1.16.
//  Copyright © 2016 Martin Kiss. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface Yielder<T> : NSEnumerator

- (instancetype)initWithBlock: (void (^)(Yielder*))block;
- (void)setYield: (T)value;

@end

#define yield   (yielder.yield) = 
