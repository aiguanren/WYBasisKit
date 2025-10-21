//
//  WYCodableConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/21.
//

import Foundation

@objcMembers public class WYCodableConfig: NSObject {
    
    /// 日期格式化器（可自定义）
    @objc public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    
    /// Data 在 JSON 中的表示前缀
    @objc public static var dataPrefix: String = "__WYCODABLE_DATA__:"
    
    /// 是否启用调试模式
    @objc public static var debugMode: Bool = false
    
    /// 是否忽略未知属性（默认true）
    @objc public static var ignoreUnknownProperties: Bool = true
    
    /// 自定义需要跳过的属性名（如果设置了，将覆盖默认的系统属性过滤）
    @objc public static var skipProperties: Set<String> = defaultSkipProperties()
    
    /// 默认过滤属性
    @objc public static func defaultSkipProperties() -> Set<String> {
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

/// DEBUG打印日志
public func wy_codablePrint(_ messages: Any..., file: String = #file, function: String = #function, line: Int = #line) {
#if DEBUG
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    let time = timeFormatter.string(from: Date())
    let message = messages.compactMap { "\($0)" }.joined(separator: " ")
    let fileName = URL(fileURLWithPath: file).lastPathComponent
    print("\n\(time) ——> \(fileName) ——> \(function) ——> line:\(line)\n\n \(message)\n\n\n")
#endif
}
