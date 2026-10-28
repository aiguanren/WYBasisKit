//
//  WYNavigationBootstrap.m
//  WYBasisKit
//
//  Created by guanren on 2026/10/23.
//

#import <Foundation/Foundation.h>

/// 导航扩展初始化
@interface WYNavigationBootstrapInstaller : NSObject
+ (void)install;
@end

/// 导航扩展自动加载入口
@interface WYNavigationBootstrap : NSObject
@end

@implementation WYNavigationBootstrap

+ (void)load {
    [WYNavigationBootstrapInstaller install];
}

@end
