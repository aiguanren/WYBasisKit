//
//  WYLogManagerMacro.h
//  WYBasisKit
//
//  Created by guanren on 2025/9/27.
//

#ifndef WYLogManagerMacro_h
#define WYLogManagerMacro_h

#if __has_include(<WYBasisKitSwift-Swift.h>)
#import <WYBasisKitSwift-Swift.h>
#elif __has_include("WYBasisKitSwift-Swift.h")
#import "WYBasisKitSwift-Swift.h"
#endif

/// 输出日志（仅输出到控制台）
#define wy_print(format, ...) \
    [WYLogManager output:[NSString stringWithFormat:(format), ##__VA_ARGS__] \
              outputMode:WYLogOutputModeDebugConsoleOnly \
                    file:@(__FILE__) \
                function:@(__FUNCTION__) \
                    line:__LINE__]

/// 输出日志（自定义日志模式）
#define wy_printWithMode(format, mode, ...) \
    [WYLogManager output:[NSString stringWithFormat:(format), ##__VA_ARGS__] \
              outputMode:(mode) \
                    file:@(__FILE__) \
                function:@(__FUNCTION__) \
                    line:__LINE__]

#endif /* WYLogManagerMacro_h */
