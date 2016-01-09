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
    for (NSString *letter in Yield(self, produceLetters)) {
        [self.recording appendString:letter];
    }
    XCTAssertEqualObjects(self.recording, @"ABCDEF");
}

- (void)test_collecting {
    NSArray *objects = Yield(self, produceLetters).allObjects;
    XCTAssertEqualObjects(self.recording, @"ACE");
    XCTAssertEqualObjects([objects componentsJoinedByString:@""], @"BDF");
}

- (id)heavyTask {
    for (NSUInteger i = 0; i < 200; i ++) {
        [NSDateFormatter new];
    }
    return [NSDateFormatter new];
}

- (void)test_speedOfHeavyTask {
    [self measureBlock:^{
        for (NSUInteger i = 0; i < 20; i ++) {
            [self heavyTask];
        }
    }];
}

const NSUInteger YielderTestCount = 1000;

- (void)produceObjects {
    for (NSUInteger index = 0; index < YielderTestCount; index ++) {
        yield [self heavyTask];
    }
}

- (void)buildArray {
    NSMutableArray *array = [NSMutableArray new];
    for (NSUInteger index = 0; index < YielderTestCount; index ++) {
        [array addObject:[self heavyTask]];
    }
    yield array;
}

- (void)test_speedOfYield_enumeration {
    dispatch_qos_class_t qos = qos_class_self();
    __block NSUInteger count = 0;
    [self measureBlock:^{
        count = 0;
        for (id object in Yield(self, produceObjects)) {
            [object self];
            count ++;
        }
    }];
    XCTAssertEqual(count, YielderTestCount);
    XCTAssertEqual(qos_class_self(), qos);
}

- (void)test_speedOfYield_collection {
    dispatch_qos_class_t qos = qos_class_self();
    __block NSArray *array = nil;
    [self measureBlock:^{
        array = Yield(self, produceObjects).allObjects;
    }];
    XCTAssertEqual(array.count, YielderTestCount);
    XCTAssertEqual(qos_class_self(), qos);
}

- (void)test_speedOfArray_enumeration {
    dispatch_qos_class_t qos = qos_class_self();
    __block NSUInteger count = 0;
    [self measureBlock:^{
        count = 0;
        NSArray *array = Yield(self, buildArray).nextObject; // This way it’s built on another queue.
        for (id object in array) {
            [object self];
            count ++;
        }
    }];
    XCTAssertEqual(count, YielderTestCount);
    XCTAssertEqual(qos_class_self(), qos);
}

- (void)test_speedOfArray_collection {
    dispatch_qos_class_t qos = qos_class_self();
    __block NSArray *array = nil;
    [self measureBlock:^{
        array = Yield(self, buildArray).nextObject; // This way it’s built on another queue.
    }];
    XCTAssertEqual(array.count, YielderTestCount);
    XCTAssertEqual(qos_class_self(), qos);
}

@end
