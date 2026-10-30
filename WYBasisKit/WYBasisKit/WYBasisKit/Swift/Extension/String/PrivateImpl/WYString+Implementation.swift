//
//  WYString+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import Foundation

extension String {

    /// 将时间戳归一化为秒，未指定单位时按绝对值以100_000_000_000和100_000_000_000_000为界推断秒、毫秒、微秒
    func wy_normalizedTimestamp(_ mode: WYTimestampMode? = nil) -> TimeInterval? {

        guard let timestamp = Double(self), timestamp.isFinite else { return nil }

        let resolvedMode: WYTimestampMode
        if let mode = mode {
            resolvedMode = mode
        } else {
            let magnitude = abs(timestamp)
            if magnitude >= 100_000_000_000_000 {
                resolvedMode = .microseconds
            } else if magnitude >= 100_000_000_000 {
                resolvedMode = .millisecond
            } else {
                resolvedMode = .second
            }
        }

        let normalizedTimestamp: TimeInterval
        switch resolvedMode {
        case .second:
            normalizedTimestamp = timestamp
        case .millisecond:
            normalizedTimestamp = timestamp / 1000
        case .microseconds:
            normalizedTimestamp = timestamp / 1_000_000
        }

        guard normalizedTimestamp >= Date.distantPast.timeIntervalSince1970,
              normalizedTimestamp <= Date.distantFuture.timeIntervalSince1970 else { return nil }

        return normalizedTimestamp
    }

    /// 获取格式化后的时间格式
    func sharedTimeFormat(dateFormat: WYTimeFormat) -> String {

        switch dateFormat {
        case .HM:
            return "HH:mm"
        case .YMD:
            return "yyyy-MM-dd"
        case .HMS:
            return "HH:mm:ss"
        case .MDHM:
            return "MM-dd HH:mm"
        case .YMDHM:
            return "yyyy-MM-dd HH:mm"
        case .YMDHMS:
            return "yyyy-MM-dd HH:mm:ss"
        case .custom(format: let format):
            return format
        }
    }
}
