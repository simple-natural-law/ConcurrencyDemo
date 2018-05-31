//
//  DispatchQueueSampleViewController.m
//  ConcurrencyDemo
//
//  Created by 密码xxkj0912 on 2018/5/30.
//  Copyright © 2018年 讯心科技. All rights reserved.
//

#import "DispatchQueueSampleViewController.h"

@interface DispatchQueueSampleViewController ()

@end

@implementation DispatchQueueSampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Dispatch Queue";
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 创建一个串行调度队列，添加到串行调度队列的任务按照先进先出的顺序串行执行。(创建队列时，为队列指定一个名称以便调试)
    dispatch_queue_t serialQueue = dispatch_queue_create("com.jian.serialQueue", DISPATCH_QUEUE_SERIAL);
    
    // 将任务1添加到serialQueue中，该任务相对于调用dispatch_async函数的线程异步执行。
    dispatch_async(serialQueue, ^{

        for (int i = 0; i < 100; i++)
        {
            
        }
        NSLog(@"任务 ----> 1");
    });
    
    // 将任务2添加到serialQueue中，该任务相对于调用dispatch_sync函数的线程同步执行。
    dispatch_sync(serialQueue, ^{

        for (int i = 0; i < 20; i++)
        {
            
        }
        NSLog(@"任务 ----> 2");
    });
    
    // 创建一个并行调度队列，添加到并行调度队列中的任务按照先进先出的顺序并行执行。(创建队列时，为队列指定一个名称以便调试)
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.jian.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    
    // 将任务3添加到concurrentQueue中，该任务相对于调用dispatch_sync函数的线程同步执行。
    dispatch_sync(concurrentQueue, ^{
        
        for (int i = 0; i < 20; i++)
        {
            
        }
        NSLog(@"任务 ----> 3");
    });
    
    // 将任务4添加到concurrentQueue中，该任务相对于调用dispatch_async函数的线程异步执行。
    dispatch_async(concurrentQueue, ^{
        
        for (int i = 0; i < 100; i++)
        {
            
        }
        NSLog(@"任务 ----> 4");
    });
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
