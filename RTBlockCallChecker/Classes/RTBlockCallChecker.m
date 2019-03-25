// RTBlockCallChecker.m
// 
// Copyright (c) 2018年 ricky.tan.xin@gmail.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Block.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "RTBlockCallChecker.h"

struct RTBlock_Descriptor {
    uintptr_t reserved;
    uintptr_t size;
    void (*copy)(void *dst, const void *src);
    void (*dispose)(const void *);
    const char *signature;
    const char *layout;
};

enum {
    BLOCK_NEEDS_FREE       = (1 << 24),
    BLOCK_HAS_COPY_DISPOSE = (1 << 25),
    BLOCK_IS_GC            = (1 << 27),
    BLOCK_IS_GLOBAL        = (1 << 28),
    BLOCK_HAS_STRET        = (1 << 29),
    BLOCK_HAS_SIGNATURE    = (1 << 30),
};

struct RTBlock {
    Class isa;
    int32_t flags;
    int32_t reserved;
    IMP invoke;
    const struct RTBlock_Descriptor* descriptor;
    void *forwardingBlock;
    void *message;
};
typedef struct RTBlock RTBlock;

static NSMethodSignature *rt_blockMethodSignature(id block) {
    if (!block) {
        return nil;
    }
    
    RTBlock *layout = (__bridge RTBlock *)block;
    if (!(layout->flags & BLOCK_HAS_SIGNATURE)) {
        return nil;
    }
    
    char *desc = (char *)layout->descriptor;
    desc += 2 * sizeof(uintptr_t);
    if (layout->flags & BLOCK_HAS_COPY_DISPOSE) {
        desc += 2 * sizeof(void *);
    }
    if (!desc) {
        return nil;
    }
    const char *signature = *(const char **)desc;
    return [NSMethodSignature signatureWithObjCTypes:signature];
}


static void rt_blockDispose(const RTBlock *ptr) {
    Block_release(ptr->forwardingBlock);
    
    id message = (__bridge_transfer id)(ptr->message);
    
    if (!ptr->reserved) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"%@", message];
    }
    
    message = nil;
}
        
static const struct RTBlock_Descriptor RTDescriptor = {
    0,
    sizeof(RTBlock),
    NULL,
    (void (*)(const void *))rt_blockDispose,
};

@implementation RTBlockCallChecker

static Class __RTBlockClass = nil;

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __RTBlockClass = objc_allocateClassPair(NSClassFromString(@"__NSMallocBlock__"), "__RTMallocBlock__", 0);
        
        {
            Method method = class_getInstanceMethod(self, @selector(methodSignatureForSelector:));
            class_replaceMethod(__RTBlockClass, @selector(methodSignatureForSelector:), method_getImplementation(method), method_getTypeEncoding(method));
        }
        
        {
            Method method = class_getInstanceMethod(self, @selector(forwardInvocation:));
            class_replaceMethod(__RTBlockClass, @selector(forwardInvocation:), method_getImplementation(method), method_getTypeEncoding(method));
        }
        
        objc_registerClassPair(__RTBlockClass);
    });
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return rt_blockMethodSignature((__bridge id)((__bridge RTBlock *)self)->forwardingBlock);
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    RTBlock *layout = (__bridge RTBlock *)self;
    layout->reserved = 1;
    
    [anInvocation invokeWithTarget:(__bridge id)layout->forwardingBlock];
}

+ (id)buildBlock:(id)completeBlock message:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    RTBlock *block = (RTBlock *)(malloc(sizeof(RTBlock)));
    block->isa = __RTBlockClass;
    
    const unsigned retainCount = 1;

    block->flags = BLOCK_HAS_COPY_DISPOSE | BLOCK_NEEDS_FREE | (retainCount << 1);
    block->reserved = 0;
    if (((__bridge RTBlock *)completeBlock)->flags & BLOCK_HAS_STRET) {
#if __arm64
        block->invoke = (IMP)_objc_msgForward;
#else
        block->invoke = (IMP)_objc_msgForward_stret;
#endif
    }
    else {
        block->invoke = (IMP)_objc_msgForward;
    }
    block->descriptor = &RTDescriptor;
    block->forwardingBlock = (__bridge void *)[completeBlock copy];
    block->message = (__bridge_retained void *)message;
    
    return (__bridge_transfer id)block;
}

@end
