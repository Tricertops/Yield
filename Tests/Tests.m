//
//  Tests.m
//  Tests
//
//  Created by Martin Kiss on 9.1.16.
//  Copyright © 2016 Martin Kiss. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Yielder.h"

@interface Tests : XCTestCase

@property NSMutableString *recording;

@end

@implementation Tests

#pragma mark Functional Tests

- (void)setUp {
    self.recording = [NSMutableString new];
}

- (void)produceLetters {
    [self.recording appendString:@"A"];
    yield @"B";
    [self.recording appendString:@"C"];
    yield @"D";
    [self.recording appendString:@"E"];
    yield @"F";
}

- (void)test_yielding {
    NSEnumerator *enumerator = Yield(self, produceLetters);
    for (NSString *letter in enumerator) {
        [self.recording appendString:letter];
    }
    XCTAssertEqualObjects(self.recording, @"ABCDEF");
    
    __weak NSEnumerator *weakEnumerator = enumerator;
    enumerator = nil;
    XCTAssertNil(weakEnumerator, @"Should be deallocated.");
}

- (void)test_yielding_interrupted {
    NSEnumerator *enumerator = Yield(self, produceLetters);
    for (NSString *letter in enumerator) {
        [self.recording appendString:letter];
        if (self.recording.length >= 4)
            break;
    }
    XCTAssertEqualObjects(self.recording, @"ABCD");
    
    __weak NSEnumerator *weakEnumerator = enumerator;
    enumerator = nil;
    XCTAssertNil(weakEnumerator, @"Should be deallocated.");
}

- (void)test_collecting {
    NSEnumerator *enumerator = Yield(self, produceLetters);
    NSArray *objects = enumerator.allObjects;
    XCTAssertEqualObjects(self.recording, @"ACE");
    XCTAssertEqualObjects([objects componentsJoinedByString:@""], @"BDF");
    
    __weak NSEnumerator *weakEnumerator = enumerator;
    enumerator = nil;
    XCTAssertNil(weakEnumerator, @"Should be deallocated.");
}


#pragma mark Light Speed Tests

const NSUInteger YielderTestLightCount = 100000;

- (id)lightTask {
    return [NSDateFormatter new];
}

- (void)test_light_task {
    [self measureBlock:^{
        for (NSUInteger i = 0; i < 10000; i ++) {
            [self lightTask];
        }
    }];
}

- (void)produceLightObjects {
    for (NSUInteger index = 0; index < YielderTestLightCount; index ++) {
        yield [self lightTask];
    }
}

- (NSArray *)buildLightArray {
    NSMutableArray *array = [NSMutableArray new];
    for (NSUInteger index = 0; index < YielderTestLightCount; index ++) {
        [array addObject:[self lightTask]];
    }
    return array;
}

- (void)test_light_yield_enumeration {
    [self measureBlock:^{
        for (id object in Yield(self, produceLightObjects)) {
            [object self];
        }
    }];
}
- (void)test_light_array_enumeration {
    [self measureBlock:^{
        for (id object in [self buildLightArray]) {
            [object self];
        }
    }];
}

- (void)test_light_yield_collection {
    [self measureBlock:^{
        __unused NSArray *array = Yield(self, produceLightObjects).allObjects;
    }];
}
- (void)test_light_array_collection {
    [self measureBlock:^{
        __unused NSArray *array = [self buildLightArray];
    }];
}

#pragma mark Heavy Speed tests

const NSUInteger YielderTestHeavyCount = 1000;

- (id)heavyTask {
    for (NSUInteger i = 0; i < 200; i ++) {
        [NSDateFormatter new];
    }
    return [self lightTask];
}

- (void)test_heavy_task {
    [self measureBlock:^{
        for (NSUInteger i = 0; i < 100; i ++) {
            [self heavyTask];
        }
    }];
}

- (void)produceHeavyObjects {
    for (NSUInteger index = 0; index < YielderTestHeavyCount; index ++) {
        yield [self heavyTask];
    }
}

- (NSArray *)buildHeavyArray {
    NSMutableArray *array = [NSMutableArray new];
    for (NSUInteger index = 0; index < YielderTestHeavyCount; index ++) {
        [array addObject:[self heavyTask]];
    }
    return array;
}

- (void)test_heavy_yield_enumeration {
    [self measureBlock:^{
        for (id object in Yield(self, produceHeavyObjects)) {
            [object self];
        }
    }];
}
- (void)test_heavy_array_enumeration {
    [self measureBlock:^{
        for (id object in [self buildHeavyArray]) {
            [object self];
        }
    }];
}

- (void)test_heavy_yield_collection {
    [self measureBlock:^{
        __unused NSArray *array = Yield(self, produceHeavyObjects).allObjects;
    }];
}
- (void)test_heavy_array_collection {
    [self measureBlock:^{
        __unused NSArray *array = [self buildHeavyArray];
    }];
}

@end
