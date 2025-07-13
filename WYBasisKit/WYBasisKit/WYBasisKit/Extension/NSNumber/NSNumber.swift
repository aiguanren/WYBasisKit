//
//  NSNumber.swift
//  WYBasisKit
//
//  Created by guanren on 2025/7/13.
//

import Foundation

public extension Optional where Wrapped == NSNumber {
    /// 获取非空安全值
    var wy_safe: NSNumber {
        return self ?? NSNumber(value: 0)
    }
}
