//
//  Array.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/20.
//

import Foundation

public extension Array {
    
    /// 安全获取下标位置数据(越界时返回 nil)
    subscript(wy_safeIndex index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    /// 安全获取下标位置数据(越界时返回指定的默认值)
    subscript(wy_safeIndex index: Int, default defaultValue: @autoclosure () -> Element) -> Element {
        return indices.contains(index) ? self[index] : defaultValue()
    }
    
    /// 安全获取(半开区间：start..<end)数据(越界部分会被自动裁剪)
    subscript(wy_safeRange range: Range<Int>) -> ArraySlice<Element> {
        let lower = Swift.max(range.lowerBound, startIndex)
        let upper = Swift.min(range.upperBound, endIndex)
        return (lower < upper) ? self[lower..<upper] : []
    }
    
    /// 安全获取(闭区间：start...end)数据(越界部分会被自动裁剪)
    subscript(wy_safeRange range: ClosedRange<Int>) -> ArraySlice<Element> {
        let lower = Swift.max(range.lowerBound, startIndex)
        let upper = Swift.min(range.upperBound, endIndex - 1)
        return (lower <= upper) ? self[lower...upper] : []
    }
}
