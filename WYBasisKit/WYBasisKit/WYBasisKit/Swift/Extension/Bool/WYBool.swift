//
//  Bool.swift
//  WYBasisKit
//
//  Created by 官人 on 2022/4/24.
//  Copyright © 2022 官人. All rights reserved.
//

import Foundation

public extension Optional where Wrapped == Bool {
    /// 获取非空安全值
    var wy_safe: Bool {
        return self ?? false
    }
}

public extension Bool {
    
    /**
     判断字符串是否为整数或小数（支持可选前缀、千分位）

       @param string 待校验字符串
       @param prefixes 可选前缀（如 ["+", "-", "¥", "$"]，最多1个且在最前）

     - 示例：
       ✅ 123 / 123.45 / 1,234 / 1,234.56 / +123 / -123.45 / ¥1,234 / $1,234.56等
       ❎ 1,23,456 / 1,234,56 / ++123 / abc123 / 123. / 1,234. / 1,234.5.6等
     
     @return 是否合法
     */
    static func wy_isValidIntegerOrDecimal(_ string: String, prefixes: [String] = []) -> Bool {
        let prefixPattern = prefixes.isEmpty
            ? ""
            : "(?:\(prefixes.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")))?"
        
        let numberPattern = "([0-9]{1,3}(,[0-9]{3})*|[0-9]+)(\\.[0-9]+)?"
        
        let regex = "^\(prefixPattern)\(numberPattern)$"
        return wy_matchesRegex(string, regex: regex)
    }
    
    /// 判断是否是纯数字
    static func wy_isPureDigital(_ string: String) -> Bool {
        let regex = "^[0-9]+$"
        return wy_matchesRegex(string, regex: regex)
    }
    
    /// 判断是否是纯字母
    static func wy_isPureLetters(_ string: String) -> Bool {
        let regex = "^[a-zA-Z]+$"
        return wy_matchesRegex(string, regex: regex)
    }
    
    /// 判断是否是纯汉字
    static func wy_isChineseCharacters(_ string: String) -> Bool {
        // 中文编码范围是 4E00-9FFF
        let regex = "^[\u{4E00}-\u{9FFF}]+$"
        return wy_matchesRegex(string, regex: regex)
    }
    
    /// 判断是否包含字母
    static func wy_isContainLetters(_ string: String) -> Bool {
        guard !string.isEmpty else { return false }
        let range = string.rangeOfCharacter(from: .letters)
        return range != nil
    }
    
    /// 判断仅字母或数字
    static func wy_isLettersOrNumbers(_ string: String) -> Bool {
        let regex = "^[a-zA-Z0-9]+$"
        return wy_matchesRegex(string, regex: regex)
    }
    
    /// 判断仅中文、字母或数字
    static func wy_isChineseOrLettersOrNumbers(_ string: String) -> Bool {
        let regex = "^[A-Za-z0-9\u{4E00}-\u{9FFF}]+$"
        return wy_matchesRegex(string, regex: regex)
    }
    
    /// 判断是否是指定位字母与数字的组合
    static func wy_isLettersAndNumbers(string: String, min: Int, max: Int) -> Bool {
        guard min > 0, max >= min else { return false }
        let regex = "^(?![0-9]+$)(?![a-zA-Z]+$)[0-9A-Za-z]{\(min),\(max)}$"
        return wy_matchesRegex(string, regex: regex)
    }
    
    /// 判断单个字符是否是Emoji
    static func wy_isSingleEmoji(string: String) -> Bool {
        guard string.count == 1 else { return false }
        return string.first?.wy_isEmoji == true
    }
    
    /// 判断字符串是否包含Emoji
    static func wy_containsEmoji(string: String) -> Bool {
        // 遍历每个字符，使用系统 isEmoji 判断
        return string.contains { $0.wy_isEmoji }
    }
    
    /**
     *  获取一个随机布尔值
     */
    static func wy_random() -> Bool {
        return Bool.random()
    }
}
