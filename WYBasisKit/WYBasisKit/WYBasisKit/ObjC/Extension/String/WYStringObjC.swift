//
//  StringObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/5.
//

import Foundation
import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

/// 获取时间戳的模式
@objc(WYTimestampMode)
@frozen public enum WYTimestampModeObjC: Int {
    
    /// 秒
    case second = 0
    
    /// 毫秒
    case millisecond
    
    /// 微秒
    case microseconds
}

/// 时间格式化模式
@objc(WYTimeFormat)
@frozen public enum WYTimeFormatObjC: Int {
    
    /// 时:分
    case HM = 0
    /// 年-月-日
    case YMD
    /// 时:分:秒
    case HMS
    /// 月-日 时:分
    case MDHM
    /// 年-月-日 时:分
    case YMDHM
    /// 年-月-日 时:分:秒
    case YMDHMS
    /// 传入自定义格式
    case custom
}

/// 星期几
@objc(WYWhatDay)
@frozen public enum WYWhatDayObjC: Int {
    
    /// 未知
    case unknown = 0
    
    /// 周日(Sun)
    case sunday
    
    /// 周一(Mon)
    case monday
    
    /// 周二(Tue)
    case tuesday
    
    /// 周三(Wed)
    case wednesday
    
    /// 周四(Thu)
    case thursday
    
    /// 周五(Fri)
    case friday
    
    /// 周六(Sat)
    case saturday
}

@objc(WYTimeDistance)
@frozen public enum WYTimeDistanceObjC: Int {
    
    /// 未知
    case unknown = 0
    
    /// 今天
    case today
    
    /// 昨天
    case yesterday
    
    /// 前天
    case yesterdayBefore
    
    /// 一周内
    case withinWeek
    
    /// 同一个月内
    case withinSameMonth
    
    /// 同一年内
    case withinSameYear
}

/// 黄道十二宫(星座)
@objc(WYZodiacSign)
@frozen public enum WYZodiacSignObjC: Int, CaseIterable {
    /// 未知
    case unknown = 0
    /// 摩羯座
    case capricorn
    /// 水瓶座
    case aquarius
    /// 双鱼座
    case pisces
    /// 白羊座
    case aries
    /// 金牛座
    case taurus
    /// 双子座
    case gemini
    /// 巨蟹座
    case cancer
    /// 狮子座
    case leo
    /// 处女座
    case virgo
    /// 天秤座
    case libra
    /// 天蝎座
    case scorpio
    /// 射手座
    case sagittarius
    
    /// 星座日期范围(OC只能查看)
    var dateRange: String {
        switch self {
        case .unknown:      return ""
        case .capricorn:    return "12.22-1.19"
        case .aquarius:     return "1.20-2.18"
        case .pisces:       return "2.19-3.20"
        case .aries:        return "3.21-4.19"
        case .taurus:       return "4.20-5.20"
        case .gemini:       return "5.21-6.21"
        case .cancer:       return "6.22-7.22"
        case .leo:          return "7.23-8.22"
        case .virgo:        return "8.23-9.22"
        case .libra:        return "9.23-10.23"
        case .scorpio:      return "10.24-11.22"
        case .sagittarius:  return "11.23-12.21"
        }
    }
}

@objc public extension NSString {
    
    /// 获取非空安全值
    @objc static func wy_safe(_ optionalString: String?) -> String {
        return optionalString.wy_safe
    }
    
    /// 字符串是否为空
    @objc static func wy_isEmpty(_ optionalString: String?) -> Bool {
        return NSString.wy_safe(optionalString).isEmpty
    }
    
    /**
     *  获取一个随机字符串
     *
     *  @param min   最少需要多少个字符
     *
     *  @param max   最多需要多少个字符
     *
     */
    @objc static func wy_random(minimux: Int = 1, maximum: Int = 100) -> String {
        return String.wy_random(minimux: minimux, maximum: maximum)
    }
    
    /// String转CGFloat
    @objc func wy_floatValue() -> CGFloat {
        return (self as String).wy_convertTo(CGFloat.self)
    }
    
    /// String转Double
    @objc func wy_doubleValue() -> Double {
        return (self as String).wy_convertTo(Double.self)
    }
    
    /// String转NSInteger
    @objc func wy_intValue() -> Int {
        return (self as String).wy_convertTo(Int.self)
    }
    
    /// String转NSDecimalNumber
    @objc func wy_decimalValue() -> NSDecimalNumber {
        let string: String = (self as String).isEmpty ? "0" : (self as String)
        return NSDecimalNumber(string: string)
    }
    
    /// 返回一个计算好的字符串的宽度
    @objc func wy_calculateWidth(controlHeight: CGFloat, controlFont: UIFont) -> CGFloat {
        return wy_calculateWidth(controlHeight: controlHeight, controlFont: controlFont, lineSpacing: 0, wordsSpacing: 0)
    }
    @objc func wy_calculateWidth(controlHeight: CGFloat, controlFont: UIFont, lineSpacing: CGFloat = 0, wordsSpacing: CGFloat = 0) -> CGFloat {
        return (self as String).wy_calculateWidth(controlHeight: controlHeight, controlFont: controlFont, lineSpacing: lineSpacing, wordsSpacing: wordsSpacing)
    }
    
    /// 返回一个计算好的字符串的高度
    @objc func wy_calculateHeight(controlWidth: CGFloat, controlFont: UIFont) -> CGFloat {
        return wy_calculateHeight(controlWidth: controlWidth, controlFont: controlFont, lineSpacing: 0, wordsSpacing: 0)
    }
    @objc func wy_calculateHeight(controlWidth: CGFloat, controlFont: UIFont, lineSpacing: CGFloat = 0, wordsSpacing: CGFloat = 0) -> CGFloat {
        return (self as String).wy_calculateHeight(controlWidth: controlWidth, controlFont: controlFont, lineSpacing: lineSpacing, wordsSpacing: wordsSpacing)
    }
    
    /// 返回一个计算好的字符串的size
    @objc func wy_calculategSize(controlSize: CGSize, controlFont: UIFont) -> CGSize {
        return wy_calculategSize(controlSize: controlSize, controlFont: controlFont, lineSpacing: 0, wordsSpacing: 0)
    }
    @objc func wy_calculategSize(controlSize: CGSize, controlFont: UIFont, lineSpacing: CGFloat = 0, wordsSpacing: CGFloat = 0) -> CGSize {
        return (self as String).wy_calculategSize(controlSize: controlSize, controlFont: controlFont, lineSpacing: lineSpacing, wordsSpacing: wordsSpacing)
    }
    
    /// 判断字符串是否包含某个字符串(ignoreCase:是否忽略大小写)
    @objc func wy_contains(_ find: String, ignoreCase: Bool = false) -> Bool {
        return (self as String).wy_contains(find, ignoreCase: ignoreCase)
    }
    
    /// 字符串截取(从第几位截取到第几位)
    @objc func wy_substring(from: Int, to: Int) -> String {
        return (self as String).wy_substring(from: from, to: to)
    }
    
    /// 字符串截取(从第几位往后截取几位)
    @objc func wy_substring(from: Int, after: Int) -> String {
        return (self as String).wy_substring(from: from, after: after)
    }
    
    /**
     *  替换指定字符(useRegex为true时，会过滤掉 appointSymbol 字符中所包含的每一个字符, useRegex为false时，会过滤掉字符串中所包含的整个 appointSymbol 字符)
     *  @param appointSymbol: 要替换的字符
     *  @param replacement: 替换成什么字符
     *  @param useRegex: 过滤方式，true正则表达式过滤, false为系统方式过滤
     */
    @objc func wy_replace(appointSymbol: String ,replacement: String, useRegex: Bool = false) -> String {
        return (self as String).wy_replace(appointSymbol: appointSymbol, replacement: replacement, useRegex: useRegex)
    }
    
    /// 字符串去除特殊字符(特属字符编码)
    @objc func wy_specialCharactersEncoding(_ characterSet: CharacterSet = .urlQueryAllowed) -> String {
        return (self as String).wy_specialCharactersEncoding(characterSet)
    }
    
    /// 字符串去除Emoji表情(replacement:表情用什么来替换)
    @objc func wy_replaceEmoji(_ replacement: String = "") -> String {
        return (self as String).wy_replaceEmoji(replacement)
    }
    
    /**
     *  SHA256加密
     *  @param uppercase: 是否需要大写，默认false
     */
    @objc func wy_sha256(uppercase: Bool = false) -> String {
        return (self as String).wy_sha256(uppercase: uppercase)
    }
    
    /// Encode
    @objc func wy_encoded() -> String {
        return wy_encoded(escape: nil)
    }
    @objc func wy_encoded(escape: String?) -> String {
        return (self as String).wy_encoded(escape: escape ?? "?!@#$^&%*+,:;='\"`<>()[]{}/\\| ")
    }
    
    /// Decode
    @objc var wy_decoded: String {
        return (self as String).wy_decoded
    }
    
    /// base64编码
    @objc var wy_base64Encoded: String {
        return (self as String).wy_base64Encoded
    }
    
    /// base64解码
    @objc var wy_base64Decoded: String {
        return (self as String).wy_base64Decoded
    }
    
    /// 获取设备时间戳
    @objc static func wy_sharedDeviceTimestamp(_ mode: WYTimestampModeObjC = .second) -> String {
        
        return String.wy_sharedDeviceTimestamp(WYTimestampMode(rawValue: mode.rawValue) ?? .second)
    }
    
    /// 秒 转 时分秒（00:00:00）格式
    @objc func wy_secondConvertDate(check: Bool = true) -> String {
        return (self as String).wy_secondConvertDate(check: check)
    }
    
    /**
     *  时间戳转年月日格式
     *  dateFormat 要转换的格式
     *  showAmPmSymbol 是否显示上午下午，为true时为12小时制，否则为24小时制
     *  customFormat 仅dateFormat为custom时才需要传(如"yyyy-MM-dd HH:mm:ss")，其余传nil就行
     */
    @objc func wy_timestampConvertDate(_ dateFormat: WYTimeFormatObjC, showAmPmSymbol: Bool = false, customFormat: String?) -> String {
        return (self as String).wy_timestampConvertDate(wy_convertObjCTimeFormatToSwift(dateFormat, customFormat), showAmPmSymbol)
    }
    
    /**
     *  年月日格式转时间戳
     *  dateFormat 要转换的格式
     *  customFormat 仅dateFormat为custom时才需要传(如"yyyy-MM-dd HH:mm:ss")，其余传nil就行
     */
    @objc func wy_dateStrConvertTimestamp(_ dateFormat: WYTimeFormatObjC, customFormat: String?) -> String {
        return (self as String).wy_dateStrConvertTimestamp(wy_convertObjCTimeFormatToSwift(dateFormat, customFormat))
    }
    
    /// 获取当前的 年、月、日
    @objc static func wy_currentYearMonthDay() -> Dictionary<String, String> {
        let ymd: (year: String, month: String, day: String) = String.wy_currentYearMonthDay()
        return ["year": ymd.year, "month": ymd.month, "day": ymd.day]
    }
    
    /// 获取当前月的总天数
    @objc static func wy_curentMonthDays() -> String {
        return String.wy_curentMonthDays()
    }
    
    /// 时间戳转星期几
    @objc var wy_whatDay: WYWhatDayObjC {
        let whatDay: WYWhatDay = (self as String).wy_whatDay
        return WYWhatDayObjC(rawValue: whatDay.rawValue) ?? .unknown
    }
    
    /**
     *  计算两个时间戳之间的间隔周期(适用于IM项目)
     *  messageTimestamp  消息对应的时间戳
     *  clientTimestamp 客户端时间戳(当前的网络时间戳或者设备本地的时间戳)
     */
    @objc static func wy_timeIntervalCycle(_ messageTimestamp: String, clientTimestamp: String = wy_sharedDeviceTimestamp()) -> WYTimeDistanceObjC {
        
        let timeDistance: WYTimeDistance = String.wy_timeIntervalCycle(messageTimestamp, clientTimestamp)
        
        return WYTimeDistanceObjC(rawValue: timeDistance.rawValue) ?? .unknown
    }
    
    /**
     *  时间戳距离现在的间隔时间
     *  dateFormat 要转换的格式
     *  customFormat 仅dateFormat为custom时才需要传(如"yyyy-MM-dd HH:mm:ss")，其余传nil就行
     */
    @objc func wy_dateDifferenceWithNowTimer(_ dateFormat: WYTimeFormatObjC, customFormat: String?) -> String {
        return (self as String).wy_dateDifferenceWithNowTimer(wy_convertObjCTimeFormatToSwift(dateFormat, customFormat))
    }
    
    /// 从字符串中提取数字
    @objc var wy_extractNumbers: [String] {
        return (self as String).wy_extractNumbers
    }
    
    /**
     *  汉字转拼音
     *  @param tone: 是否需要保留音调
     *  @param interval: 拼音之间是否需要用空格间隔开
     */
    @objc func wy_phoneticTransform(tone: Bool = false, interval: Bool = false) -> String {
        return (self as String).wy_phoneticTransform(tone: tone, interval: interval)
    }
    
    /// 根据时间戳获取星座
    @objc static func wy_zodiacSign(with timestamp: String) -> WYZodiacSignObjC {
        return WYZodiacSignObjC(rawValue: String.wy_zodiacSign(from: timestamp).rawValue) ?? .unknown
    }
}

private extension NSString {
    
    /// 转换WYTimeFormatObjC为WYTimeFormat
    func wy_convertObjCTimeFormatToSwift(_ timeFormat: WYTimeFormatObjC, _ customFormat: String?) -> WYTimeFormat {
        let dateFormat: WYTimeFormat
        switch timeFormat {
        case .HM:
            dateFormat = .HM
        case .YMD:
            dateFormat = .YMD
        case .HMS:
            dateFormat = .HMS
        case .MDHM:
            dateFormat = .MDHM
        case .YMDHM:
            dateFormat = .YMDHM
        case .YMDHMS:
            dateFormat = .YMDHMS
        case .custom:
            if let customFormat = customFormat {
                dateFormat = .custom(format: customFormat)
            }else {
                dateFormat = .custom(format: "")
            }
        }
        return dateFormat
    }
}
