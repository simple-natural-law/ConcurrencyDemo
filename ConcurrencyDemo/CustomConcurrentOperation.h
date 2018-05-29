//
//  CustomConcurrentOperation.h
//  ConcurrencyDemo
//
//  Created by 密码xxkj0912 on 2018/5/29.
//  Copyright © 2018年 讯心科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomConcurrentOperation : NSOperation

- (instancetype)initWithIdentifier:(NSString *)identifier;

@end
