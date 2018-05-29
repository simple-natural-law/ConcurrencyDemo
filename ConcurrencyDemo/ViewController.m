//
//  ViewController.m
//  ConcurrencyDemo
//
//  Created by 讯心科技 on 2018/3/15.
//  Copyright © 2018年 讯心科技. All rights reserved.
//

#import "ViewController.h"
#import "CustomOperation.h"
#import "CustomConcurrentOperation.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 创建一个操作队列对象
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    // 设置操作队列的最大并发数
    operationQueue.maxConcurrentOperationCount = 5;
    
    // 创建一个NSBlockOperation
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        for (int i = 0; i < 20; i++)
        {
            
        }
        
        NSLog(@"操作 ------> 1");
    }];
    // 创建一个NSInvocationOperation
    NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(invocationOperation) object:nil];
    
    // 创建一个并发自定义操作
    CustomConcurrentOperation *customConcurrentOperation = [[CustomConcurrentOperation alloc] initWithIdentifier:@"4"];
    
    // 创建一个非并发自定义操作
    CustomOperation *customOperation = [[CustomOperation alloc] initWithIdentifier:@"5"];

    // 在将操作添加到操作队列之前，配置操作依赖性，invocationOperation会等到blockOperation完成后才开始执行
    [invocationOperation addDependency:blockOperation];
    
    [blockOperation addDependency:customOperation];

    [customOperation addDependency:customConcurrentOperation];
    
    // 将操作添加到操作队列
    [operationQueue addOperation:blockOperation];

    [operationQueue addOperation:invocationOperation];
    
    [operationQueue addOperation:customOperation];
    
    [operationQueue addOperation:customConcurrentOperation];

    // 直接添加一个操作到operationQueue中
    [operationQueue addOperationWithBlock:^{

        for (int i = 0; i < 20; i++)
        {
            
        }
        
        NSLog(@"操作 ------> 3");
    }];
}

- (void)invocationOperation
{
    for (int i = 0; i < 20; i++)
    {
        
    }
    
    NSLog(@"操作 ------> 2");
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
