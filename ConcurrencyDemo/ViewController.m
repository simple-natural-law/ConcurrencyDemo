//
//  ViewController.m
//  ConcurrencyDemo
//
//  Created by 讯心科技 on 2018/3/15.
//  Copyright © 2018年 讯心科技. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 创建一个操作队列对象
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    // 设置操作队列的最大并发数
    operationQueue.maxConcurrentOperationCount = 1;
    
    // 创建一个NSBlockOperation
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        NSLog(@"操作 ------> 1");
        
        for (int i = 0; i < 2; i++) {
            
        }
        
        NSLog(@"gggggggg");
    }];
    
    [blockOperation addExecutionBlock:^{
        
        NSLog(@"a");
        
        for (int i = 0; i < 2; i++) {
            
        }
        
        NSLog(@"==========");
    }];
    
    [blockOperation addExecutionBlock:^{
        
        NSLog(@"b");
        
        for (int i = 0; i < 2; i++) {
            
        }
        
        NSLog(@"1111111111");
    }];
    
    [blockOperation addExecutionBlock:^{
        
        NSLog(@"c");
        
        for (int i = 0; i < 2; i++) {
            
        }
        
        NSLog(@"333333333333");
    }];
    
    [blockOperation start];
    
//    NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(invocationOperation) object:nil];
//
//    // 在将操作添加到操作队列之前，配置操作依赖性，invocationOperation会等到blockOperation完成后才开始执行
//    //[invocationOperation addDependency:blockOperation];
//
//    [operationQueue addOperation:blockOperation];
//
//    [operationQueue addOperation:invocationOperation];
//
//    // 直接添加一个操作到operationQueue中
//    [operationQueue addOperationWithBlock:^{
//
//        NSLog(@"操作 ------> 3");
//    }];
}

- (void)invocationOperation
{
    NSLog(@"操作 ------> 2");
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
