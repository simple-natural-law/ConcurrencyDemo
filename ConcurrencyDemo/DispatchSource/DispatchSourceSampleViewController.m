//
//  DispatchSourceSampleViewController.m
//  ConcurrencyDemo
//
//  Created by 张诗健 on 2018/7/9.
//  Copyright © 2018年 讯心科技. All rights reserved.
//

#import "DispatchSourceSampleViewController.h"

@interface DispatchSourceSampleViewController ()
{
    dispatch_source_t timer;
}


@end


@implementation DispatchSourceSampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 创建定时器调度源
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    // 配置调度源(每30秒触发一次，误差值为1秒)
    // 所有定时器调度源都是间隔定时器--即一旦创建，它们会在我们指定的时间间隔传递定期事件。当创建一个定时器调度源时，误差值是必须指定的值之一，它能够使系统了解定时器事件所需的精度。误差值为系统管理功耗和唤醒内核提供了一定的灵活性。例如，系统可能会使用误差值来提前或者延迟触发时间，并将其与其他系统事件更好地对齐。因此，我们应该尽可能为定时器指定一个误差值。
    // 注意：即使我们指定误差值为0，也绝对不要期望一个定时器在要求的精确纳秒下触发。系统会尽最大努力满足我们的需求，但并不能保证准确的触发时间。
    // 当计算机进入睡眠状态时，所有定时器调度源都将暂停。当计算机唤醒时，这些定时器调度源也会自动唤醒。根据定时器的配置，这种性质的暂停可能会影响定时器下次触发的时间。如果使用dispatch_time函数或者DISPATCH_TIME_NOW常量设置定时器调度源，则定时器调度源使用默认系统时钟来确定何时触发。但是，计算机进入睡眠状态时，默认时钟不会前进。相比之下，当使用dispatch_walltime函数设置定时器调度源时，定时器调度源将其触发时间追踪到挂钟时间。后一种选择通常适用于定时间隔相对较大的定时器，因为其可以防止事件时间之间出现太多漂移。
    dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), 30.0 * NSEC_PER_SEC, 1.0 * NSEC_PER_SEC);
    // 安装事件处理程序
    dispatch_source_set_event_handler(timer, ^{
        
        NSLog(@"定时器事件触发");
    });
    dispatch_resume(timer);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    dispatch_source_cancel(timer);
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
