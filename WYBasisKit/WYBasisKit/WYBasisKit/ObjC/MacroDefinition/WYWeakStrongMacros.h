//
//  WYWeakStrongMacros.h
//  WYBasisKit
//
//  Created by guanren on 16/9/4.
//  Copyright © 2016年 guanren. All rights reserved.
//

#ifndef WYWeakStrongMacros_h
#define WYWeakStrongMacros_h

#pragma mark - WeakSelf / StrongSelf (用于 Block 避免循环引用)

/**
 * weakify和strongify 推荐用法：
 *
 *   ⚠️注意：
 *     wy_weakify 和 wy_strongify 必须成对使用，且参数列表必须完全一致，如果只写 wy_weakify(...) 而没有对应的 wy_strongify(...)，编译器会报 "Unused variable 'self_weak_'" 警告，提醒需要成对使用。
 *
 *   ⚠️重要：
 *     由于宏展开后包含多条语句，请始终在 if/else/for/while 等语句后使用花括号 {}，避免控制流错误。
 *
 *   ✅正确示例：
 *       if (condition) {
 *           wy_weakify(self);
 *       }
 *   ❎错误示例（会导致 @autoreleasepool 受 if 控制，而变量声明不受控制）：
 *       if (condition)
 *           wy_weakify(self);   // 禁止这样写
 *
 *   单变量使用示例：
 *       wy_weakify(self);
 *       [xxx completion:^{
 *           wy_strongify(self);
 *           // 直接使用 self，如：self.param = nil
 *       }];
 *
 *   多变量使用示例（1-10个，最大不能超过10个）：
 *       wy_weakify(self, array, object);
 *       [xxx completion:^{
 *           wy_strongify(self, array, object);
 *           if (!self || !array || !object) return;
 *           // 直接使用 self，如：self.param = nil
 *       }];
 */

/// weakSelf – 定义弱引用变量
#define wy_weakify(...) \
    basisKit_internal_weakStrong_macro_concat( \
        basisKit_internal_weakStrong_weakify_, \
        basisKit_internal_weakStrong_arg_count(__VA_ARGS__) \
    )(__VA_ARGS__)

/// strongSelf – 定义强引用变量
#define wy_strongify(...) \
    basisKit_internal_weakStrong_macro_concat( \
        basisKit_internal_weakStrong_strongify_, \
        basisKit_internal_weakStrong_arg_count(__VA_ARGS__) \
    )(__VA_ARGS__)


/**************************** 以下为内部实现  ****************************/

// 辅助：连接宏（强制多层展开，确保参数计数先计算出数字）
#define basisKit_internal_weakStrong_macro_concat(a, b) basisKit_internal_weakStrong_macro_concat_(a, b)
#define basisKit_internal_weakStrong_macro_concat_(a, b) a##b

// 参数计数宏（最多10个）
#define basisKit_internal_weakStrong_arg_count(...) \
    basisKit_internal_weakStrong_arg_count_(__VA_ARGS__, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1)

#define basisKit_internal_weakStrong_arg_count_(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, N, ...) N

// Debug 强制提醒：未使用 weak 变量时报警告
#if DEBUG
    #define basisKit_internal_weakStrong_WEAK_UNUSED_ATTR   // 空，产生未使用变量警告
#else
    #define basisKit_internal_weakStrong_WEAK_UNUSED_ATTR __attribute__((unused))
#endif


#if __OBJC__

// 单变量 weakify / strongify（基础实现）
#define basisKit_internal_weakStrong_weakify_one(var) \
    @autoreleasepool {} \
    __weak __auto_type var##_weak_ basisKit_internal_weakStrong_WEAK_UNUSED_ATTR = (var);

#define basisKit_internal_weakStrong_strongify_one(var) \
    @try {} @finally {} \
    __strong __auto_type var = var##_weak_;

#else

// 非 Objective-C 环境下（如纯 C/C++），宏降级为空，避免编译错误
#define basisKit_internal_weakStrong_weakify_one(var)
#define basisKit_internal_weakStrong_strongify_one(var)

#endif


// 单变量版本（参数个数为1时使用）
#define basisKit_internal_weakStrong_weakify_1(v1)               basisKit_internal_weakStrong_weakify_one(v1)
#define basisKit_internal_weakStrong_strongify_1(v1)             basisKit_internal_weakStrong_strongify_one(v1)

// 多变量组合（2-10个）
#define basisKit_internal_weakStrong_weakify_2(v1, v2)           basisKit_internal_weakStrong_weakify_one(v1) basisKit_internal_weakStrong_weakify_one(v2)
#define basisKit_internal_weakStrong_weakify_3(v1, v2, v3)       basisKit_internal_weakStrong_weakify_2(v1, v2) basisKit_internal_weakStrong_weakify_one(v3)
#define basisKit_internal_weakStrong_weakify_4(v1, v2, v3, v4)   basisKit_internal_weakStrong_weakify_3(v1, v2, v3) basisKit_internal_weakStrong_weakify_one(v4)
#define basisKit_internal_weakStrong_weakify_5(v1, v2, v3, v4, v5) basisKit_internal_weakStrong_weakify_4(v1, v2, v3, v4) basisKit_internal_weakStrong_weakify_one(v5)
#define basisKit_internal_weakStrong_weakify_6(v1, v2, v3, v4, v5, v6) basisKit_internal_weakStrong_weakify_5(v1, v2, v3, v4, v5) basisKit_internal_weakStrong_weakify_one(v6)
#define basisKit_internal_weakStrong_weakify_7(v1, v2, v3, v4, v5, v6, v7) basisKit_internal_weakStrong_weakify_6(v1, v2, v3, v4, v5, v6) basisKit_internal_weakStrong_weakify_one(v7)
#define basisKit_internal_weakStrong_weakify_8(v1, v2, v3, v4, v5, v6, v7, v8) basisKit_internal_weakStrong_weakify_7(v1, v2, v3, v4, v5, v6, v7) basisKit_internal_weakStrong_weakify_one(v8)
#define basisKit_internal_weakStrong_weakify_9(v1, v2, v3, v4, v5, v6, v7, v8, v9) basisKit_internal_weakStrong_weakify_8(v1, v2, v3, v4, v5, v6, v7, v8) basisKit_internal_weakStrong_weakify_one(v9)
#define basisKit_internal_weakStrong_weakify_10(v1, v2, v3, v4, v5, v6, v7, v8, v9, v10) basisKit_internal_weakStrong_weakify_9(v1, v2, v3, v4, v5, v6, v7, v8, v9) basisKit_internal_weakStrong_weakify_one(v10)

#define basisKit_internal_weakStrong_strongify_2(v1, v2)         basisKit_internal_weakStrong_strongify_one(v1) basisKit_internal_weakStrong_strongify_one(v2)
#define basisKit_internal_weakStrong_strongify_3(v1, v2, v3)     basisKit_internal_weakStrong_strongify_2(v1, v2) basisKit_internal_weakStrong_strongify_one(v3)
#define basisKit_internal_weakStrong_strongify_4(v1, v2, v3, v4) basisKit_internal_weakStrong_strongify_3(v1, v2, v3) basisKit_internal_weakStrong_strongify_one(v4)
#define basisKit_internal_weakStrong_strongify_5(v1, v2, v3, v4, v5) basisKit_internal_weakStrong_strongify_4(v1, v2, v3, v4) basisKit_internal_weakStrong_strongify_one(v5)
#define basisKit_internal_weakStrong_strongify_6(v1, v2, v3, v4, v5, v6) basisKit_internal_weakStrong_strongify_5(v1, v2, v3, v4, v5) basisKit_internal_weakStrong_strongify_one(v6)
#define basisKit_internal_weakStrong_strongify_7(v1, v2, v3, v4, v5, v6, v7) basisKit_internal_weakStrong_strongify_6(v1, v2, v3, v4, v5, v6) basisKit_internal_weakStrong_strongify_one(v7)
#define basisKit_internal_weakStrong_strongify_8(v1, v2, v3, v4, v5, v6, v7, v8) basisKit_internal_weakStrong_strongify_7(v1, v2, v3, v4, v5, v6, v7) basisKit_internal_weakStrong_strongify_one(v8)
#define basisKit_internal_weakStrong_strongify_9(v1, v2, v3, v4, v5, v6, v7, v8, v9) basisKit_internal_weakStrong_strongify_8(v1, v2, v3, v4, v5, v6, v7, v8) basisKit_internal_weakStrong_strongify_one(v9)
#define basisKit_internal_weakStrong_strongify_10(v1, v2, v3, v4, v5, v6, v7, v8, v9, v10) basisKit_internal_weakStrong_strongify_9(v1, v2, v3, v4, v5, v6, v7, v8, v9) basisKit_internal_weakStrong_strongify_one(v10)

/**************************** 以上为内部实现  ****************************/

#endif /* WYWeakStrongMacros_h */
