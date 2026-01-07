//
//  ArrayObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/20.
//

import Foundation
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

@objc public extension NSArray {
    
    /// 安全获取下标位置数据(越界时返回 nil)
    @objc func wy_safeIndex(_ index: Int) -> Any? {
        return (index >= 0 && index < self.count) ? self[index] : nil
    }
    
    /// 安全获取下标位置数据(越界时返回指定默认值)
    @objc func wy_safeIndex(_ index: Int, default defaultValue: Any) -> Any {
        return (index >= 0 && index < self.count) ? self[index] : defaultValue
    }
    
    /// 安全获取半开区间 start..<end 数据(越界部分会被自动裁剪)
    @objc func wy_safeRange(_ range: NSRange) -> [Any] {
        guard self.count > 0 else { return [] }
        let lower = Swift.max(range.location, 0)
        let upper = Swift.min(range.location + range.length, self.count)
        guard lower < upper else { return [] }
        
        var result: [Any] = []
        for i in lower..<upper {
            result.append(self[i])
        }
        return result
    }
    
    /// 安全获取闭区间 start...end 数据(越界部分会被自动裁剪)
    @objc func wy_safeClosedRange(_ range: NSRange) -> [Any] {
        guard self.count > 0 else { return [] }
        let lower = Swift.max(range.location, 0)
        let upper = Swift.min(range.location + range.length - 1, self.count - 1)
        guard lower <= upper else { return [] }
        
        var result: [Any] = []
        for i in lower...upper {
            result.append(self[i])
        }
        return result
    }
}
