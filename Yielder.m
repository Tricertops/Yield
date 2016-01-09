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
@property BOOL isRunning;
@property dispatch_queue_t queue;
@property dispatch_semaphore_t producingSemaphore;
@property dispatch_semaphore_t consumingSemaphore;

@end

@implementation Yielder

- (instancetype)initWithBlock:(void (^)(Yielder *))block {
    self = [super init];
    if (self) {
        self->_block = block;
        self->_queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL);
        dispatch_queue_t parent = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0);
        dispatch_set_target_queue(self->_queue, parent);
        self->_producingSemaphore = dispatch_semaphore_create(0);
        self->_consumingSemaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (void)setYield:(id)value {
    self->_nextObject = value;
    dispatch_semaphore_signal(self->_producingSemaphore);
    dispatch_semaphore_wait(self->_consumingSemaphore, DISPATCH_TIME_FOREVER);
}

- (id)nextObject {
    if (self.isRunning) {
        dispatch_semaphore_signal(self->_consumingSemaphore);
    }
    else {
        self.isRunning = YES;
        dispatch_async(self->_queue, ^{
            self->_block(self);
            self->_nextObject = nil;
            dispatch_semaphore_signal(self->_producingSemaphore);
        });
    }
    dispatch_semaphore_wait(self->_producingSemaphore, DISPATCH_TIME_FOREVER);
    return self->_nextObject;
}

@end
