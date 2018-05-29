//
//  ViewController.m
//  ConcurrencyDemo
//
//  Created by 讯心科技 on 2018/3/15.
//  Copyright © 2018年 讯心科技. All rights reserved.
//

#import "ViewController.h"
#import "CustomOperation.h"


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
    
    NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(invocationOperation) object:nil];
    
    
    CustomOperation *customOperation = [[CustomOperation alloc] initWithIdentifier:@"4"];

    // 在将操作添加到操作队列之前，配置操作依赖性，invocationOperation会等到blockOperation完成后才开始执行
    [invocationOperation addDependency:blockOperation];
    
    [blockOperation addDependency:customOperation];

    [operationQueue addOperation:blockOperation];

    [operationQueue addOperation:invocationOperation];
    
    [operationQueue addOperation:customOperation];

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
