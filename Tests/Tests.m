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

- (NSArray *)buildArray {
    NSMutableArray *array = [NSMutableArray new];
    for (NSUInteger index = 0; index < YielderTestCount; index ++) {
        [array addObject:[self heavyTask]];
    }
    return array;
}

- (void)test_speedOfYield_enumeration {
    __block NSUInteger count = 0;
    [self measureBlock:^{
        count = 0;
        for (id object in Yield(self, produceObjects)) {
            [object self];
            count ++;
        }
    }];
    XCTAssertEqual(count, YielderTestCount);
}

- (void)test_speedOfYield_collection {
    __block NSArray *array = nil;
    [self measureBlock:^{
        array = Yield(self, produceObjects).allObjects;
    }];
    XCTAssertEqual(array.count, YielderTestCount);
}

- (void)test_speedOfArray_enumeration {
    __block NSUInteger count = 0;
    [self measureBlock:^{
        count = 0;
        for (id object in [self buildArray]) {
            [object self];
            count ++;
        }
    }];
    XCTAssertEqual(count, YielderTestCount);
}

- (void)test_speedOfArray_collection {
    __block NSArray *array = nil;
    [self measureBlock:^{
        array = [self buildArray];
    }];
    XCTAssertEqual(array.count, YielderTestCount);
}

@end
