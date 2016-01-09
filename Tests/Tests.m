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

@end

@implementation Tests

- (void)executeWithYielder:(Yielder<NSString *> *)yielder argument:(NSString *)suffix {
    NSLog(@"Sending: A");
    yield @"A";
    NSLog(@"Sending: B");
    yield @"B";
    NSLog(@"Sending: C");
    yield @"C";
    NSLog(@"Sending: %@", suffix);
    yield suffix;
}

- (void)test_yielding {
    Yielder<NSString *> *yielder = [[Yielder alloc] initWithBlock:^(Yielder *yielder) {
        [self executeWithYielder:yielder argument:@"Done!"];
    }];
    for (NSString *value in yielder) {
        NSLog(@"Received: %@", value);
    }
}

@end
