//
//  CustomConcurrentOperation.m
//  ConcurrencyDemo
//
//  Created by 密码xxkj0912 on 2018/5/29.
//  Copyright © 2018年 讯心科技. All rights reserved.
//

#import "CustomConcurrentOperation.h"

@interface CustomConcurrentOperation ()
{
    BOOL _executing;

    BOOL _finished;
}

@property (nonatomic, strong) NSString *identifier;

@end



@implementation CustomConcurrentOperation

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    self = [super init];
    
    if (self)
    {
        self.identifier = identifier;
        
        _finished  = NO;
        _executing = NO;
    }
    
    return self;
}


- (void)start
{
    if ([self isCancelled])
    {
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
    }else
    {
        [self willChangeValueForKey:@"isExecuting"];
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(main) object:nil];
        [thread start];
        _executing = YES;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)main
{
    @try {
        
        for (int i = 0; i < 20; i++)
        {
            
        }
        
        NSLog(@"操作 ----> %@",self.identifier);
        
        [self willChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        _finished  = YES;
        _executing = NO;
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];
        
    }@catch(...) {
        
    }
}


- (BOOL)isExecuting
{
    return _executing;
}

- (BOOL)isFinished
{
    return _finished;
}

- (BOOL)isConcurrent
{
    return YES;
}

@end
