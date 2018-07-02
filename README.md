# RTBlockCallChecker

[![CI Status](http://img.shields.io/travis/rickytan/RTBlockCallChecker.svg?style=flat)](https://travis-ci.org/rickytan/RTBlockCallChecker)
[![Version](https://img.shields.io/cocoapods/v/RTBlockCallChecker.svg?style=flat)](http://cocoapods.org/pods/RTBlockCallChecker)
[![License](https://img.shields.io/cocoapods/l/RTBlockCallChecker.svg?style=flat)](http://cocoapods.org/pods/RTBlockCallChecker)
[![Platform](https://img.shields.io/cocoapods/p/RTBlockCallChecker.svg?style=flat)](http://cocoapods.org/pods/RTBlockCallChecker)

## Introduction

Sometimes, as a third-party library, we must make sure that the completion block we passed 
to a developer must be called, or it will cause an error and unexpedted states. For example,
in **WebKit**, we have a navigation delegate method: 

```objc
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
```

What if for some reason the developer forget to call `decisionHandler`? This is not allowed.
In fact, if you do forget to call it, **WebKit** will raise a exception for you. How did **WebKit** 
do that? well, it implements a [CompletionHandlerCallChecker](https://opensource.apple.com/source/WebKit2/WebKit2-7602.1.50.0.10/Shared/Cocoa/CompletionHandlerCallChecker.mm.auto.html) in **CPP**, and 
use the template magic. But this project provides a tricky way in **Objective-C**. for more 
information, please read the source code, quite simple.

## Usage

RTBlockCallChecker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RTBlockCallChecker'
```

```objc
void (^someBlockMustBeCalled)() = ^{
   ...
};
[self passBlockToAMethod:RT_CHECK_BLOCK_CALLED(someBlockMustBeCalled)];

- (void)passBlockToAMethod:(void(^)(void))block {
    // 1. call the block immediatedlly
    block();        // ok
    // 2. call the block width delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        block();    // ok
    });
    // 3. pass the block to another instance, and it will call the block in the future
    someObj.completion = block; // ok
    // 4. forget to call the block, raise a exception!
}
```

## Author

rickytan, ricky.tan.xin@gmail.com

## License

RTBlockCallChecker is available under the MIT license. See the LICENSE file for more info.
