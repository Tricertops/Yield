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

@end
