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

@property (weak) NSObject *target;
@property (copy) void (^block)(id);

@property id nextObject;
@property NSMutableArray *remainingObjects;
@property BOOL isFinished;

@property dispatch_queue_t queue;
@property dispatch_semaphore_t consumptionSemaphore;
@property dispatch_semaphore_t productionSemaphore;
@property dispatch_semaphore_t finishingSemaphore;

@end

@implementation Yielder

#pragma mark Initializing

+ (void *)key {
    return (__bridge void *)Yielder.class;
}

- (instancetype)initWithTarget:(NSObject *)target block:(void (^)(id))block {
    self = [super init];
    if (self) {
        self->_target = target;
        self->_block = block;
        objc_setAssociatedObject(target, Yielder.key, self, OBJC_ASSOCIATION_RETAIN);
        
        [self start];
    }
    return self;
}

- (void)start {
    dispatch_queue_t queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t parent = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0);
    dispatch_set_target_queue(queue, parent);
    self->_queue = queue;
    
    self->_consumptionSemaphore = dispatch_semaphore_create(0);
    self->_productionSemaphore = dispatch_semaphore_create(0);
    self->_finishingSemaphore = dispatch_semaphore_create(0);
    
    dispatch_async(queue, ^{
        [self waitForProductionRequest];
        self->_block(self->_target);
        [self signalFinish];
        [self allowConsumption];
    });
}

#pragma mark Next Object

+ (void)setObject:(nullable id)value forKeyedSubscript:(NSObject *)target {
    if (value == nil)
        return; //! Skip yielded nils.
    
    //TODO: Support multiple (recursive) enumerations at once.
    Yielder *yielder = objc_getAssociatedObject(target, Yielder.key);
    [yielder setNextObject:(id)value]; // Silence nullable warning.
}

@synthesize nextObject = _nextObject;

- (BOOL)hasNextObject {
    return (self->_nextObject != nil || self->_isFinished);
}

- (id)nextObject {
    while ( ! [self hasNextObject]) {
        [self requestProduction];
        [self waitForConsumption];
    }
    id next = self->_nextObject;
    self->_nextObject = nil; //! Nullify for next call.
    return next;
}

- (void)setNextObject:(id)next {
    if (self->_remainingObjects) {
        if (next)
            [self->_remainingObjects addObject:next];
    }
    else {
        self->_nextObject = next;
        [self allowConsumption];
        [self waitForProductionRequest];
    }
}

- (NSArray *)allObjects {
    NSMutableArray *remaining = [NSMutableArray new];
    self->_remainingObjects = remaining;
    [self requestProduction];
    [self waitForFinish];
    self->_remainingObjects = nil;
    return remaining;
}

#pragma mark Semaphores

- (void)waitForProductionRequest {
    if (self->_isFinished)
        return;
    
    dispatch_semaphore_wait(self->_productionSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)requestProduction {
    dispatch_semaphore_signal(self->_productionSemaphore);
}

- (void)waitForConsumption {
    if (self->_isFinished)
        return;
    
    dispatch_semaphore_wait(self->_consumptionSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)allowConsumption {
    dispatch_semaphore_signal(self->_consumptionSemaphore);
}

- (void)waitForFinish {
    if (self->_isFinished)
        return;
    
    dispatch_semaphore_wait(self->_finishingSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)signalFinish {
    self->_isFinished = YES;
    dispatch_semaphore_signal(self->_finishingSemaphore);
}

@end

NS_ASSUME_NONNULL_END
