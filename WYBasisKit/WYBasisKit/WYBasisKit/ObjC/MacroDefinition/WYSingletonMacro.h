//
//  WYSingletonMacro.h
//  WYBasisKit
//
//  Created by guanren on 16/9/4.
//  Copyright © 2016年 guanren. All rights reserved.
//

#ifndef WYSingletonMacro_h
#define WYSingletonMacro_h

#pragma mark - 单例宏

/**
 * 单例宏使用方式
 *
 *   // 在 .h 文件中（类接口部分，必须写在 @interface ... : SuperClass 下面）
 *   @interface YourClass : SuperClass
 *   wy_singletonInterface(YourClass)
 *
 *   @end
 *
 *   // 在 .m 文件中（类实现部分，必须写在 @implementation YourClass 下面)
 *   @implementation YourClass
 *   wy_singletonImplementation(YourClass)
 *
 *   @end
 *
 *   // 任何地方获取单例实例
 *   YourClass *yourClass = [YourClass shared];
 *
 */
#define wy_singletonInterface(className) \
+ (instancetype)shared;

/**
 * 单例实现宏 - 在 .m 文件中使用（线程安全、防止 alloc/copy 创建多实例）
 * 支持同一个 .m 文件中声明多个单例，静态变量名自动带类名，且不会冲突。
 */
#define wy_singletonImplementation(className) \
static id _shared##className = nil; \
\
+ (instancetype)shared \
{ \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        _shared##className = [[self alloc] init]; \
    }); \
    return _shared##className; \
} \
\
+ (instancetype)allocWithZone:(struct _NSZone *)zone \
{ \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        _shared##className = [super allocWithZone:zone]; \
    }); \
    return _shared##className; \
} \
\
- (id)copyWithZone:(struct _NSZone *)zone \
{ \
    return _shared##className; \
} \
\
- (id)mutableCopyWithZone:(struct _NSZone *)zone \
{ \
    return _shared##className; \
}

#endif /* WYSingletonMacro_h */
