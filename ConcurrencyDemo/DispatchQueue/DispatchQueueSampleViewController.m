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
    
    // 创建一个串行调度队列，添加到串行调度队列的任务按照先进先出的顺序被串行调度（需要等待上一个任务执行完毕后才会继续调度下一个任务）到合适的线程上执行。(创建队列时，为队列指定一个名称以便调试)
    dispatch_queue_t serialQueue = dispatch_queue_create("com.jian.serialQueue", DISPATCH_QUEUE_SERIAL);
    
    // 将任务1添加到serialQueue中，任务1会被serialQueue调度到一个新线程（并非调用dispatch_async函数的线程）上执行。dispatch_async函数是一个异步函数，其在任务1被调度到新线程之后就直接返回了。
    dispatch_async(serialQueue, ^{

        for (int i = 0; i < 100; i++)
        {
            
        }
        NSLog(@"任务 ----> 1");
        NSLog(@"1 ----> %@",[NSThread currentThread]);
    });
    
    // 将任务2添加到serialQueue中，任务2会被serialQueue调度到调用dispatch_sync函数的线程上执行。dispatch_sync函数是一个同步函数，其会在任务2被调度到调用dispatch_sync函数的线程上并且执行完毕后才会返回。
    dispatch_sync(serialQueue, ^{

        for (int i = 0; i < 20; i++)
        {
            
        }
        NSLog(@"任务 ----> 2");
        NSLog(@"2 ----> %@",[NSThread currentThread]);
    });
    
    // 创建一个并行调度队列，添加到并行调度队列的任务按照先进先出的顺序被并行调度（不用等待上一个任务执行完毕，就继续调度下一个任务）到合适的线程上执行。(创建队列时，为队列指定一个名称以便调试)
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.jian.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    
    
    dispatch_sync(concurrentQueue, ^{
        
        for (int i = 0; i < 20; i++)
        {
            
        }
        NSLog(@"任务 ----> 3");
    });
    
    
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
