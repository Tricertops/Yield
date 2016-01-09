//
//  Yielder.m
//  Yielder
//
//  Created by Martin Kiss on 9.1.16.
//  Copyright © 2016 Martin Kiss. All rights reserved.
//

@import ObjectiveC;
#import "Yielder.h"

NS_ASSUME_NONNULL_BEGIN

@interface Yielder ()

@property id nextObject;
@property NSMutableArray *remainingObjects;
@property BOOL shouldTerminate;

@property dispatch_queue_t queue;
@property dispatch_group_t execution;
@property dispatch_semaphore_t productionEnter;
@property dispatch_semaphore_t productionLeave;

@end

@implementation Yielder

#pragma mark Initializing

+ (void *)key {
    return (__bridge void *)Yielder.class;
}

- (instancetype)initWithTarget:(NSObject *)target block:(void (^)(id))block {
    self = [super init];
    if (self) {
        dispatch_queue_t queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL);
        dispatch_queue_t parent = dispatch_get_global_queue(qos_class_self(), 0);
        dispatch_set_target_queue(queue, parent);
        self->_queue = queue;
        
        self->_execution = dispatch_group_create();
        self->_productionEnter = dispatch_semaphore_create(0);
        self->_productionLeave = dispatch_semaphore_create(0);
        
        [self associateWithTarget:target];
        dispatch_group_enter(self->_execution); //! Don’t wait for async to start.
        
        __unsafe_unretained Yielder *weakSelf = self;
        __unsafe_unretained NSObject *weakTarget = target;
        dispatch_async(queue, ^{
            NSObject *target = weakTarget;
            __unsafe_unretained Yielder *self = weakSelf;
            
            dispatch_semaphore_wait(self->_productionEnter, DISPATCH_TIME_FOREVER);
            if ( ! self->_shouldTerminate) {
                block(target);
            }
            [self deassociateFromTarget:target];
            self->_shouldTerminate = YES;
            dispatch_semaphore_signal(self->_productionLeave);
            dispatch_group_leave(self->_execution);
        });
    }
    return self;
}

- (void)associateWithTarget:(NSObject *)target {
    objc_setAssociatedObject(target, Yielder.key, self, OBJC_ASSOCIATION_ASSIGN);
}

- (void)deassociateFromTarget:(NSObject *)target {
    objc_setAssociatedObject(target, Yielder.key, nil, OBJC_ASSOCIATION_ASSIGN);
}

+ (nullable Yielder *)associatedWithTarget:(NSObject *)target {
    //TODO: Support multiple (recursive) enumerations at once.
    return objc_getAssociatedObject(target, Yielder.key);
}

- (void)dealloc {
    self->_shouldTerminate = YES;
    dispatch_semaphore_signal(self->_productionEnter);
    dispatch_group_wait(self->_execution, DISPATCH_TIME_FOREVER);
}

#pragma mark Next Object

+ (BOOL)shouldReturnAfterYielding:(nullable id)next fromTarget:(NSObject *)target {
    if (next == nil)
        return NO; //! Skip yielded nils.
    
    __unsafe_unretained Yielder *yielder = [self associatedWithTarget:target];
    [yielder setNextObject:(id)next]; // Silence nullable warning.
    return yielder->_shouldTerminate;
}

@synthesize nextObject = _nextObject;

- (BOOL)hasNextObject {
    return (self->_nextObject != nil || self->_shouldTerminate);
}

- (id)nextObject {
    while ( ! [self hasNextObject]) {
        dispatch_semaphore_signal(self->_productionEnter);
        dispatch_semaphore_wait(self->_productionLeave, DISPATCH_TIME_FOREVER);
    }
    id next = self->_nextObject;
    self->_nextObject = nil; //! Nullify for next call.
    return next;
}

- (void)setNextObject:(id)next {
    if (self->_remainingObjects) {
        [self->_remainingObjects addObject:next];
    }
    else {
        self->_nextObject = next;
        dispatch_semaphore_signal(self->_productionLeave);
        dispatch_semaphore_wait(self->_productionEnter, DISPATCH_TIME_FOREVER);
    }
}

- (NSArray *)allObjects {
    NSMutableArray *remaining = [NSMutableArray new];
    self->_remainingObjects = remaining;
    
    dispatch_semaphore_signal(self->_productionEnter);
    dispatch_group_wait(self->_execution, DISPATCH_TIME_FOREVER);
    
    self->_remainingObjects = nil;
    return remaining;
}


@end

NS_ASSUME_NONNULL_END
