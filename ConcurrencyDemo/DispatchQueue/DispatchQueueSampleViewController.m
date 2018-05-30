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
