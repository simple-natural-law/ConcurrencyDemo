//
//  OperationQueueSampleViewController.m
//  ConcurrencyDemo
//
//  Created by 密码xxkj0912 on 2018/5/30.
//  Copyright © 2018年 讯心科技. All rights reserved.
//

#import "OperationQueueSampleViewController.h"
#import "CustomOperation.h"
#import "CustomConcurrentOperation.h"


@interface OperationQueueSampleViewController ()

@end

@implementation OperationQueueSampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
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
    // 设置操作的completionBlock
    [customConcurrentOperation setCompletionBlock:^{
       
        NSLog(@" =====> 操作4已完成");
    }];
    
    // 创建一个非并发自定义操作
    CustomOperation *customOperation = [[CustomOperation alloc] initWithIdentifier:@"5"];
    // 设置操作的执行优先级
    [customOperation setQueuePriority:NSOperationQueuePriorityHigh];
    
    // 在将操作添加到操作队列之前，配置操作依赖性，invocationOperation会等到blockOperation完成后才开始执行
    [invocationOperation addDependency:blockOperation];
    
    [blockOperation addDependency:customConcurrentOperation];
    
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
    
    // 大致观察一下operationQueue什么时候开始执行操作
    for (int i = 0; i < 100; i++)
    {
        
    }
    NSLog(@"==========");
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
