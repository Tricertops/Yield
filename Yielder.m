//
//  Yielder.m
//  Yielder
//
//  Created by Martin Kiss on 9.1.16.
//  Copyright © 2016 Martin Kiss. All rights reserved.
//

@import ObjectiveC;
#import "Yielder.h"

@interface Yielder ()

@property (weak) NSObject *target;
@property (copy) void (^block)(id);

@property id nextObject;
@property BOOL isRunning;
@property dispatch_queue_t queue;
@property dispatch_semaphore_t producingSemaphore;
@property dispatch_semaphore_t consumingSemaphore;

@end

@implementation Yielder

#pragma mark Attaching

+ (void *)key {
    return (__bridge void *)Yielder.class;
}

- (instancetype)initWithTarget:(NSObject *)target block:(void (^)(id))block {
    self = [super init];
    if (self) {
        self->_target = target;
        self->_block = block;
        objc_setAssociatedObject(target, Yielder.key, self, OBJC_ASSOCIATION_RETAIN);
    }
    return self;
}

+ (void)setObject:(id)value forKeyedSubscript:(NSObject *)target {
    //TODO: Support multiple (recursive) enumerations at once.
    Yielder *yielder = objc_getAssociatedObject(target, Yielder.key);
    [yielder setNextObject:value];
}

#pragma mark Next Object

@synthesize nextObject = _nextObject;

- (id)nextObject {
    while (self->_nextObject == nil)
        [self continueExecution];
    
    id next = self->_nextObject;
    self->_nextObject = nil;
    if (next == self)
        next = nil; //! Yielding self means end.
    return next;
}

- (void)setNextObject:(id)next {
    self->_nextObject = next;
    [self continueEnumeration];
}

#pragma mark Threading

- (void)start {
    dispatch_queue_t queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t parent = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0);
    dispatch_set_target_queue(queue, parent);
    self->_queue = queue;
    
    self->_producingSemaphore = dispatch_semaphore_create(0);
    self->_consumingSemaphore = dispatch_semaphore_create(0);
    
    dispatch_async(queue, ^{
        self->_block(self->_target);
        [self setNextObject:self]; //! Yielding self means end.
    });
}

- (void)continueExecution {
    if (self->_queue)
        dispatch_semaphore_signal(self->_consumingSemaphore);
    else
        [self start];
    //TODO: Maybe wait limited time?
    dispatch_semaphore_wait(self->_producingSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)continueEnumeration {
    dispatch_semaphore_signal(self->_producingSemaphore);
    //TODO: Maybe wait limited time?
    dispatch_semaphore_wait(self->_consumingSemaphore, DISPATCH_TIME_FOREVER);
}

@end
