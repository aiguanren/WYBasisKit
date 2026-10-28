//
//  WYString+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import Foundation

extension String {

    /**
     *  将时间戳字符串归一化为秒级时间间隔
     *
     *  @param timestamp 时间戳字符串，支持秒、毫秒、微秒 （支持包含小数的时间戳）
     *  @return 归一化后的秒级 TimeInterval，若转换失败则返回 nil
     *
     *  判断逻辑：通过数值大小自动识别精度
     *  - 绝对值 > 1_000_000_000_000 → 微秒级
     *  - 绝对值 > 1_000_000_000 → 毫秒级
     *  - 其他 → 秒级
     */
    func wy_normalizedTimestamp() -> TimeInterval? {

        let timestamp: String = self

        guard let t = Double(timestamp), t.isFinite else { return nil }

        let absT = abs(t)
        var normalizedTimestamp = t

        // 微秒级时间戳通常大于1万亿(如 1700000000000000)，除以 1_000_000 归一化成秒
        if absT >= 100_000_000_000_000 {
            normalizedTimestamp = t / 1_000_000
        }

        // 毫秒级时间戳通常大于10亿(如 1700000000000)，除以 1000 归一化成秒
        if absT >= 100_000_000_000 && absT < 100_000_000_000_000 {
            normalizedTimestamp = t / 1000
        }

        // 秒级时间戳通常小于10亿，直接返回(支持小数如 1700000000.123)
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
