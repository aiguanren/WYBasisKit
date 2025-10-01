//
//  WYLogManagerMacro.h
//  WYBasisKit
//
//  Created by guanren on 2025/9/27.
//

#ifndef WYLogManagerMacro_h
#define WYLogManagerMacro_h

/// 覆盖系统发能发输出日志（仅输出到控制台）
#define NSLog(format, ...) \
    [WYLogManager output:[NSString stringWithFormat:(format), ##__VA_ARGS__] \
              outputMode:WYLogOutputModeDebugConsoleOnly \
                    file:@(__FILE__) \
                function:@(__FUNCTION__) \
                    line:__LINE__]

/// 输出日志（仅输出到控制台）
#define WYLog(format, ...) \
    [WYLogManager output:[NSString stringWithFormat:(format), ##__VA_ARGS__] \
              outputMode:WYLogOutputModeDebugConsoleOnly \
                    file:@(__FILE__) \
                function:@(__FUNCTION__) \
                    line:__LINE__]

/// 输出日志（自定义日志模式）
#define WYLogWithMode(format, mode, ...) \
    [WYLogManager output:[NSString stringWithFormat:(format), ##__VA_ARGS__] \
              outputMode:(mode) \
                    file:@(__FILE__) \
                function:@(__FUNCTION__) \
                    line:__LINE__]

#endif /* WYLogManagerMacro_h */
