//
//  BoolObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/6.
//

import Foundation
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

@objcMembers public class BoolObjC: NSObject {
    
    /// 判断是否是纯数字
    @objc public static func wy_isPureDigital(_ string: String) -> Bool {
        return Bool.wy_isPureDigital(string)
    }
    
    /// 判断是否是纯字母
    @objc public static func wy_isPureLetters(_ string: String) -> Bool {
        return Bool.wy_isPureLetters(string)
    }
    
    /// 判断是否是纯汉字
    @objc public static func wy_isChineseCharacters(_ string: String) -> Bool {
        return Bool.wy_isChineseCharacters(string)
    }
    
    /// 判断是否包含字母
    @objc public static func wy_isContainLetters(_ string: String) -> Bool {
        return Bool.wy_isContainLetters(string)
    }
    
    /// 判断仅字母或数字
    @objc public static func wy_isLettersOrNumbers(_ string: String) -> Bool {
        return Bool.wy_isLettersOrNumbers(string)
    }
    
    /// 判断仅中文、字母或数字
    @objc public static func wy_isChineseOrLettersOrNumbers(_ string: String) -> Bool {
        return Bool.wy_isChineseOrLettersOrNumbers(string)
    }
    
    /// 判断是否是指定位字母与数字的组合
    @objc(wy_isLettersAndNumbers:min:max:)
    public static func wy_isLettersAndNumbers(string: String, min: Int, max: Int) -> Bool {
        return Bool.wy_isLettersAndNumbers(string: string, min: min, max: max)
    }
    
    /// 判断单个字符是否是Emoji
    @objc(wy_isSingleEmoji:)
    public static func wy_isSingleEmoji(string: String) -> Bool {
        return Bool.wy_isSingleEmoji(string: string)
    }
    
    /// 判断字符串是否包含Emoji
    @objc(wy_containsEmoji:)
    public static func wy_containsEmoji(string: String) -> Bool {
        return Bool.wy_containsEmoji(string: string)
    }
    
    /**
     *  获取一个随机布尔值
     */
    @objc public static func wy_randoml() -> Bool {
        return Bool.wy_randoml()
    }
}
