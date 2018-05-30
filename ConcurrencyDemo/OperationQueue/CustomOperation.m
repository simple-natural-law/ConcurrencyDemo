//
//  CustomOperation.m
//  ConcurrencyDemo
//
//  Created by 密码xxkj0912 on 2018/5/29.
//  Copyright © 2018年 讯心科技. All rights reserved.
//

#import "CustomOperation.h"

@interface CustomOperation ()

@property (nonatomic, strong) NSString *identifier;

@end


@implementation CustomOperation

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    self = [super init];
    
    if (self)
    {
        self.identifier = identifier;
    }
    
    return self;
}


- (void)main
{
    @try {
        
        // 在执行实际的工作之前，检查操作是否已被取消
        if (![self isCancelled])
        {
            for (int i = 0; i < 20; i++)
            {
                
            }
            
            NSLog(@"操作 ----> %@",self.identifier);
        }
        
    }@catch(...) {
        
    }
}

@end
