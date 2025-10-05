//
//  WYBasisKitObjC.h
//  WYBasisKit
//
//  Created by guanren on 2025/9/28.
//

#import <Foundation/Foundation.h>

/**
 WYBasisKitObjC import说明
 
 1. 基础导入方式：
    @import WYBasisKitObjC;                    // 模块导入
    #import <WYBasisKitObjC/WYBasisKitObjC.h>  // 传统头文件导入
    - 效果相同，只暴露真正 @objc 兼容的类型
    - 对于非 Swift 特有类型都能正常编译
 
 2. 完整桥接导入方式：
    #import <WYBasisKitObjC.h>                // 完整桥接映射
    #import <WYBasisKit-ObjC-umbrella.h>      // 完整桥接映射
    - 包含了完整的桥接映射，包括一些 Swift 特有类型的"伪"Objective-C 版本
    - 可以让 Objective-C 访问 WKWebpagePreferences、WKNavigationResponse 等 Swift 特有类型，但依赖 Xcode 的桥接机制，类型可能不完整
 
 3. 使用建议：
    - 如果不需要使用 Swift 特有类型，推荐使用基础导入方式
    - 如果需要使用 WKWebpagePreferences、WKNavigationResponse 等 Swift 特有类型，需使用完整桥接导入方式
 
 4. 注意事项：
    - 完整桥接导入方式可能在不同 Xcode 版本中存在兼容性差异
    - Swift 特有类型在 Objective-C 中的功能可能不如在 Swift 中完整
 */

#if __has_include(<WYBasisKitSwift/WYBasisKitSwift-Swift.h>)
@import WYBasisKitSwift;
#elif __has_include("WYBasisKitSwift-Swift.h")
#import "WYBasisKitSwift-Swift.h"
#endif

#if __has_include(<WYBasisKitObjC-Swift.h>)
#import <WYBasisKitObjC-Swift.h>
#endif

#if __has_include("WYLogManagerMacro.h")
#import "WYLogManagerMacro.h"
#endif

#if __has_include("WYLocalizableManagerMacro.h")
#import "WYLocalizableManagerMacro.h"
#endif
