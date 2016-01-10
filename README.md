Objective-C Yield
=================
Introduces concept of multiple return values from Objective-C methods using `yield` keyword. Integrates nicely with `for-in` loop and allows early breaks.

Example
-------
This code shows logging of six letters: 3 are logged directly and 3 from the `for-in` loop:

```objc
- (void)produceLetters {
    NSLog(@"A");
    yield(@"B");
    NSLog(@"C");
    yield(@"D");
    NSLog(@"E");
    yield(@"F");
}

- (void)test {
    for (NSString *letter in Yieldable(self, produceLetters)) {
        NSLog(@"%@", letter);
    }
}
```

On output, they have proper order (newlines removed):

>A B C D E F

The `yield` macro uses _magic_ to pass value to the enumeration and continues execution when needed. The _magic_ is invoking the method on another queue and interrupting its execution.

Usage
-----
1. Implement a method with `void` return value and **any arguments**. This method will be called from another queue, but **mutually exclusive** with the caller queue, never consurrently.
2. Use `yield(x)` to output any number of values. This macro needs ability to call `return`, so don’t call it from nested blocks or called functions.
3. Use `Yieldable(…)` macro in `for-in` statement. Arguments to this macro are similar to calling the method directly, here’s the example:

    ```objc
    Yieldable(self, methodWithString:@"String" boolean:YES)
    ```

4. You can call `break` inside the `for-in` loop and the rest of your method will **be skipped**. Macro `yield()` will internally call `return`.
5. You can collect all objects to an array using `.allObjects` property, since the returned object from `Yieldable(…)` is an `NSEnumerator` instance. In the example above, the array would contain: `B`, `D`, `F`.
