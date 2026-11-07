//
//  WYCodableConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/21.
//

import Foundation

extension WYCodableConfig {

    @nonobjc static func internal_dateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }

    @nonobjc static func internal_defaultSkipProperties() -> Set<String> {
        return [
            // NSObject 核心属性
            "hash",                   // 对象的哈希值
            "superclass",             // 父类信息
            "description",            // 对象描述
            "debugDescription",       // 调试描述
            
            // KVC/KVO 相关
            "accessInstanceVariablesDirectly", // 是否直接访问实例变量
            "observationInfo",                 // KVO 观察信息
            
            // 消息转发相关
            "methodSignatureForSelector",      // 方法签名
            "forwardInvocation",               // 消息转发
            
            // 内存管理相关 (MRC/ARC)
            "retainCount",            // 引用计数 (MRC)
            "retain",                 // 保留对象 (MRC)
            "release",                // 释放对象 (MRC)
            "autorelease",            // 自动释放 (MRC)
            
            // 运行时相关
            "zone",                   // 内存区域 (已废弃)
            "isProxy",                // 是否为代理对象
            
            // 归档/序列化相关
            "classForKeyedArchiver",           // 归档类
            "replacementObjectForKeyedArchiver", // 归档替换对象
            "classForCoder",                   // 编码类
            "replacementObjectForCoder",       // 编码替换对象
            "secureCodingProtocol"             // 安全编码协议
        ]
    }
}

func internal_wy_codablePrint(_ messages: [Any], file: String, function: String, line: Int) {
#if DEBUG
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    let time = timeFormatter.string(from: Date())
    let message = messages.compactMap { "\($0)" }.joined(separator: " ")
    let fileName = URL(fileURLWithPath: file).lastPathComponent
    print("\n\(time) ——> \(fileName) ——> \(function) ——> line:\(line)\n\n \(message)\n\n\n")
#endif
}
