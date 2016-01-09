//
//  Yielder.m
//  Yielder
//
//  Created by Martin Kiss on 9.1.16.
//  Copyright © 2016 Martin Kiss. All rights reserved.
//

#import "Yielder.h"

@interface Yielder ()

@property (copy) void (^block)(Yielder *);
@property id nextObject;

@end

@implementation Yielder

- (instancetype)initWithBlock: (void (^)(Yielder*))block {
    self = [super init];
    if (self) {
        self->_block = block;
    }
    return self;
}

- (void)setYield: (id)value {
    self.nextObject = value;
}

- (id)nextObject {
    return self->_nextObject;
}

@end
