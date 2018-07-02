//
//  RTViewController.m
//  RTBlockCallChecker
//
//  Created by rickytan on 03/20/2018.
//  Copyright (c) 2018 rickytan. All rights reserved.
//

#import <RTBlockCallChecker/RTBlockCallChecker.h>

#import "RTViewController.h"

@interface RTViewController ()

@end

struct my_struct {
    char ch;
    __unsafe_unretained NSString * name;
    BOOL b;
    CGRect rect;
};

@implementation RTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self reloadDataWithCompletion:RT_CHECK_BLOCK_CALLED(^struct my_struct(NSString *text, struct my_struct s, CGRect frame, int a[7]){
        NSLog(@"%p:%@", text, text);
        NSLog(@"%p:%c %@", (void *)&s, s.ch, s.name);
        NSLog(@"%p:%@", (void *)&frame, NSStringFromCGRect(frame));
        NSLog(@"%d %d %d", a[0], a[1], a[2]);
        return s;
    })];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadDataWithCompletion:(struct my_struct (^)(NSString *, struct my_struct, CGRect, int[7]))completionBlock
{

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        int a[7] = {100, 101, 102, 103};
        return ;
        struct my_struct s = completionBlock(@"abc", (struct my_struct){
            .ch = 'w',
            .name = @"Ricky",
            .b = YES,
            .rect = {{111, 222}, {333, 444}}
        }, CGRectMake(10, 20, 30, 40), a);
        NSLog(@"%@", s.name);
    });
}

@end
