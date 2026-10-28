//
//  WYBool+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import Foundation

extension Bool {
    /// 正则匹配辅助方法
    static func wy_matchesRegex(_ string: String, regex: String) -> Bool {
        guard !string.isEmpty else { return false }
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: string)
    }
}

extension Character {

    /// 是否是Emoji（支持组合Emoji）
    var wy_isEmoji: Bool {
        // 单个 scalar
        if unicodeScalars.count == 1 {
            let scalar = unicodeScalars.first!
            return scalar.properties.isEmoji &&
            (scalar.properties.isEmojiPresentation || scalar.value > 0x238C)
        }
        if unicodeScalars.last?.value == 0x20E3,
           let first = unicodeScalars.first,
           "#*0123456789".unicodeScalars.contains(first) {
            return unicodeScalars.count == 2 || (unicodeScalars.count == 3 && unicodeScalars.dropFirst().first?.value == 0xFE0F)
        }
        // 多 scalar（组合 emoji），只要包含 ZWJ 或 emoji 标量即可认为是 emoji
        return unicodeScalars.contains {
            $0.properties.isEmoji &&
            ($0.properties.isEmojiPresentation || $0.value > 0x238C)
        }
    }
}
