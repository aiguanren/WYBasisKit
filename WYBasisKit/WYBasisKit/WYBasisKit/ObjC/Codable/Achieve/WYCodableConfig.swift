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
