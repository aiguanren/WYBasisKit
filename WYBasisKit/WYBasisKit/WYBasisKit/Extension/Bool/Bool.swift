//
//  Bool.swift
//  WYBasisKit
//
//  Created by 官人 on 2022/4/24.
//  Copyright © 2022 官人. All rights reserved.
//

import Foundation

public extension Bool {
    
    /// 判断是否是纯数字
    static func wy_isPureDigital(_ string: String) -> Bool {
        guard string.isEmpty == false else {
            return false
        }
        let regex = "^[0-9]+$"
        let regextest = NSPredicate(format: "SELF MATCHES %@",regex)
        return regextest.evaluate(with: string)
    }
    
    /// 判断是否是纯字母
    static func wy_isPureLetters(_ string: String) -> Bool {
        guard string.isEmpty == false else {
            return false
        }
        let regex = "^[a-zA-Z]+$"
        let regextest = NSPredicate(format: "SELF MATCHES %@",regex)
        return regextest.evaluate(with: string)
    }
    
    /// 判断是否是纯汉字
    static func wy_isChineseCharacters(_ string: String) -> Bool {
        guard string.isEmpty == false else {
            return false
        }
        // 中文编码范围是0x4e00~0x9fa5
        let regex = "(^[\\u4e00-\\u9fa5]+$)"
        let regextest = NSPredicate(format: "SELF MATCHES %@",regex)
        return regextest.evaluate(with: string)
    }
    
    /// 判断是否包含字母
    static func wy_isContainLetters(_ string: String) -> Bool {
        
        guard string.isEmpty == false else {
            return false
        }
        
        let regular = try! NSRegularExpression(pattern: "[A-Za-z]", options: .caseInsensitive)
        let count = regular.numberOfMatches(in: string, options: .reportProgress, range: NSMakeRange(0, string.count))
        return count > 0 ? true : false
    }
    
    /// 判断仅字母或数字
    static func wy_isLettersOrNumbers(_ string: String) -> Bool {
        
        guard string.isEmpty == false else {
            return false
        }
        
        let regex = "[a-zA-Z0-9]*"
        let regextest = NSPredicate(format: "SELF MATCHES %@",regex)
        return regextest.evaluate(with: string)
    }
    
    /// 判断仅中文、字母或数字
    static func wy_isChineseOrLettersOrNumbers(_ string: String) -> Bool {
        
        guard string.isEmpty == false else {
            return false
        }

        let regex = "^[A-Za-z0-9\\u4e00-\\u9fa5]+?$"
        let regextest = NSPredicate(format: "SELF MATCHES %@",regex)
        return regextest.evaluate(with: string)
    }
    
    /// 判断是否是指定位字母与数字的组合
    static func wy_isLettersAndNumbers(string: String, min: Int, max: Int) -> Bool {
        guard string.isEmpty == false else {
            return false
        }
        let regex =  "^(?![0-9]+$)(?![a-zA-Z]+$)[0-9A-Za-z]{\(min),\(max)}$"
        let regextest = NSPredicate(format: "SELF MATCHES %@",regex)
        return regextest.evaluate(with: string)
    }
    
    /// 判断单个字符是否是Emoji
    static func wy_isSingleEmoji(string: String) -> Bool {
        
        guard string.isEmpty == false else {
            return false
        }

        if string.count == 1 {
            let emodjiGlyphPattern = "\\p{RI}{2}|(\\p{Emoji}(\\p{EMod}|\\x{FE0F}\\x{20E3}?|[\\x{E0020}-\\x{E007E}]+\\x{E007F})|[\\p{Emoji}&&\\p{Other_symbol}])(\\x{200D}(\\p{Emoji}(\\p{EMod}|\\x{FE0F}\\x{20E3}?|[\\x{E0020}-\\x{E007E}]+\\x{E007F})|[\\p{Emoji}&&\\p{Other_symbol}]))*"
            
            let fullRange = NSRange(location: 0, length: string.utf16.count)
            if let regex = try? NSRegularExpression(pattern: emodjiGlyphPattern, options: .caseInsensitive) {
                let regMatches = regex.matches(in: string, options: NSRegularExpression.MatchingOptions(), range: fullRange)
                if regMatches.count > 0 {
                    return true
                }
            }
        }
        return false
    }
    
    /// 判断字符串是否包含Emoji
    static func wy_containsEmoji(string: String) -> Bool {
        for index in string.indices {
            let singleString = string[index]
            if wy_isSingleEmoji(string: singleString.description) == true {
                return true
            }
        }
        return false
    }
}
