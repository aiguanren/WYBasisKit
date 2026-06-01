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
@frozen public enum WYConstellationObjC: Int, CaseIterable {
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
    @objc(wy_safe:)
    static func wy_safeObjC(_ optionalString: String?) -> String {
        return optionalString.wy_safe
    }
    
    /// 字符串是否为空
    @objc(wy_isEmpty:)
    static func wy_isEmptyObjC(_ optionalString: String?) -> Bool {
        return NSString.wy_safeObjC(optionalString).isEmpty
    }
    
    /**
     *  获取一个随机字符串
     *
     *  @param min   最少需要多少个字符
     *
     *  @param max   最多需要多少个字符
     *
     */
    @objc(wy_randomWithMinimum:maximum:)
    static func wy_randomObjC(minimum: Int, maximum: Int) -> String {
        return String.wy_random(minimum: minimum, maximum: maximum)
    }
    
    /// String转CGFloat
    @objc(wy_floatValue)
    func wy_floatValueObjC() -> CGFloat {
        return (self as String).wy_convertTo(CGFloat.self)
    }
    
    /// String转Double
    @objc(wy_doubleValue)
    func wy_doubleValueObjC() -> Double {
        return (self as String).wy_convertTo(Double.self)
    }
    
    /// String转NSInteger
    @objc(wy_intValue)
    func wy_intValueObjC() -> Int {
        return (self as String).wy_convertTo(Int.self)
    }
    
    /// String转NSDecimalNumber
    @objc(wy_decimalValue)
    func wy_decimalValueObjC() -> NSDecimalNumber {
        let string: String = (self as String).isEmpty ? "0" : (self as String)
        return NSDecimalNumber(string: string)
    }
    
    /// 返回一个计算好的字符串的宽度
    @objc(wy_calculateWidthWithControlHeight:controlFont:lineSpacing:)
    func wy_calculateWidthObjC(controlHeight: CGFloat, controlFont: UIFont, lineSpacing: CGFloat = 0) -> CGFloat {
        return (self as String).wy_calculateWidth(controlHeight: controlHeight, controlFont: controlFont, lineSpacing: lineSpacing)
    }
    
    /// 返回一个计算好的字符串的高度
    @objc(wy_calculateHeightWithControlWidth:controlFont:lineSpacing:)
    func wy_calculateHeightObjC(controlWidth: CGFloat, controlFont: UIFont, lineSpacing: CGFloat = 0) -> CGFloat {
        return (self as String).wy_calculateHeight(controlWidth: controlWidth, controlFont: controlFont, lineSpacing: lineSpacing)
    }
    
    /// 返回一个计算好的字符串的size
    @objc(wy_calculateSizeWithControlSize:controlFont:lineSpacing:)
    func wy_calculateSizeObjC(controlSize: CGSize, controlFont: UIFont, lineSpacing: CGFloat = 0) -> CGSize {
        return (self as String).wy_calculateSize(controlSize: controlSize, controlFont: controlFont, lineSpacing: lineSpacing)
    }
    
    /// 判断字符串是否包含某个字符串(ignoreCase:是否忽略大小写)
    @objc(wy_containsSubString:ignoreCase:)
    func wy_containsObjC(_ subString: String, ignoreCase: Bool = false) -> Bool {
        return (self as String).wy_contains(subString, ignoreCase: ignoreCase)
    }
    
    /**
     *  提取字符串中的链接(默认支持 http://、https://、www.、ftp://、mailto:、tel: 等)
     *  @return 提取到的链接字符串数组，顺序按链接在原始字符串中首次出现的位置排列；若 content 为空或无效，返回空数组。
     */
    @objc(wy_extractLinks)
    func wy_extractLinksObjC() -> [String] {
        return (self as String).wy_extractLinks()
    }
    
    /// 字符串截取(从第几位截取到第几位)
    @objc(wy_substringFrom:to:)
    func wy_substringObjC(from: Int, to: Int) -> String {
        return (self as String).wy_substring(from: from, to: to)
    }
    
    /// 字符串截取(从第几位往后截取几位)
    @objc(wy_substringFrom:after:)
    func wy_substringObjC(from: Int, after: Int) -> String {
        return (self as String).wy_substring(from: from, after: after)
    }
    
    /**
     *  替换指定字符(useRegex为true时，会过滤掉 appointSymbol 字符中所包含的每一个字符, useRegex为false时，会过滤掉字符串中所包含的整个 appointSymbol 字符)
     *  @param appointSymbol: 要替换的字符
     *  @param replacement: 替换成什么字符
     *  @param useRegex: 过滤方式，true正则表达式过滤, false为系统方式过滤
     */
    @objc(wy_replaceWithAppointSymbol:replacement:useRegex:)
    func wy_replaceObjC(appointSymbol: String ,replacement: String, useRegex: Bool = false) -> String {
        return (self as String).wy_replace(appointSymbol: appointSymbol, replacement: replacement, useRegex: useRegex)
    }
    
    /// 字符串去除特殊字符(特殊字符编码)
    @objc(wy_specialCharactersEncodingWithCharacterSet:)
    func wy_specialCharactersEncodingObjC(_ characterSet: CharacterSet? = .urlQueryAllowed) -> String {
        return (self as String).wy_specialCharactersEncoding(characterSet ?? .urlQueryAllowed)
    }
    
    /// 字符串去除Emoji表情(replacement:表情用什么来替换)
    @objc(wy_replaceEmoji:)
    func wy_replaceEmojiObjC(_ replacement: String = "") -> String {
        return (self as String).wy_replaceEmoji(replacement)
    }
    
    /**
     *  SHA256加密
     *  @param uppercase: 是否需要大写，默认false
     */
    @objc(wy_sha256WithUppercase:)
    func wy_sha256ObjC(uppercase: Bool = false) -> String {
        return (self as String).wy_sha256(uppercase: uppercase)
    }
    
    /**
     字符串Encode

     - Parameter shouldNotEncode: 一个字符串，用于指定 **不进行编码** 的字符集合。
       默认值为 `"?!@#$^&%*+,:;='\"`<>()[]{}/\\| "`，即该字符串中的所有字符将原样保留，其余字符会被编码。
     - Returns: 编码后的字符串。如果编码失败（例如字符串本身无法转换为 UTF-8），则返回原字符串。
     */
    @objc(wy_encoded)
    func wy_encodedObjC() -> String {
        return wy_encodedObjC(shouldNotEncode: nil)
    }
    @objc(wy_encodedWithShouldNotEncode:)
    func wy_encodedObjC(shouldNotEncode: String?) -> String {
        return (self as String).wy_encoded(shouldNotEncode: shouldNotEncode ?? "?!@#$^&%*+,:;='\"`<>()[]{}/\\| ")
    }
    
    /// Decode
    @objc(wy_decoded)
    var wy_decodedObjC: String {
        return (self as String).wy_decoded
    }
    
    /// base64编码
    @objc(wy_base64Encoded)
    var wy_base64EncodedObjC: String {
        return (self as String).wy_base64Encoded
    }
    
    /// base64解码
    @objc(wy_base64Decoded)
    var wy_base64DecodedObjC: String {
        return (self as String).wy_base64Decoded
    }
    
    /// 获取设备时间戳
    @objc(wy_sharedDeviceTimestamp:)
    static func wy_sharedDeviceTimestampObjC(_ mode: WYTimestampModeObjC = .second) -> String {
        return String.wy_sharedDeviceTimestamp(WYTimestampMode(rawValue: mode.rawValue) ?? .second)
    }
    
    /**
     将秒数转换为时间格式字符串（`HH:MM:SS` 或 `MM:SS`）。

     - Parameter omitHoursIfZero: 是否检查小时部分。
       - 当 `omitHoursIfZero == true` 且小时数为 `0` 时，返回 `MM:SS` 格式（不包含小时部分）。
       - 当 `omitHoursIfZero == false` 或小时数大于 `0` 时，始终返回 `HH:MM:SS` 格式。
       - 默认值为 `true`。
     - Returns: 格式化后的时间字符串。
     */
    @objc(wy_formatDurationWithOmitHoursIfZero:)
    func wy_formatDurationObjC(omitHoursIfZero: Bool = true) -> String {
        return (self as String).wy_formatDuration(omitHoursIfZero: omitHoursIfZero)
    }
    
    /**
     *  时间戳转年月日格式
     *  dateFormat 要转换的格式
     *  showAmPmSymbol 是否显示上午下午，为true时为12小时制，否则为24小时制
     *  customFormat 仅dateFormat为custom时才需要传(如"yyyy-MM-dd HH:mm:ss")，其余传nil就行
     */
    @objc(wy_timestampConvertDate:showAmPmSymbol:)
    func wy_timestampConvertDateObjC(_ dateFormat: WYTimeFormatObjC, showAmPmSymbol: Bool = false) -> String {
        return wy_timestampConvertDateObjC(dateFormat, showAmPmSymbol: showAmPmSymbol, customFormat: nil)
    }
    @objc(wy_timestampConvertDate:showAmPmSymbol:customFormat:)
    func wy_timestampConvertDateObjC(_ dateFormat: WYTimeFormatObjC, showAmPmSymbol: Bool = false, customFormat: String?) -> String {
        return (self as String).wy_timestampConvertDate(wy_convertObjCTimeFormatToSwift(dateFormat, customFormat), showAmPmSymbol)
    }
    
    /**
     *  年月日格式转时间戳
     *  dateFormat 要转换的格式
     *  customFormat 仅dateFormat为custom时才需要传(如"yyyy-MM-dd HH:mm:ss")，其余传nil就行
     */
    @objc(wy_dateStrConvertTimestamp:)
    func wy_dateStrConvertTimestampObjC(_ dateFormat: WYTimeFormatObjC) -> String {
        return wy_dateStrConvertTimestampObjC(dateFormat, customFormat: nil)
    }
    @objc(wy_dateStrConvertTimestamp:customFormat:)
    func wy_dateStrConvertTimestampObjC(_ dateFormat: WYTimeFormatObjC, customFormat: String?) -> String {
        return (self as String).wy_dateStrConvertTimestamp(wy_convertObjCTimeFormatToSwift(dateFormat, customFormat))
    }
    
    /// 获取当前的 年、月、日
    @objc(wy_currentYearMonthDay)
    static func wy_currentYearMonthDayObjC() -> Dictionary<String, String> {
        let ymd: (year: String, month: String, day: String) = String.wy_currentYearMonthDay()
        return ["year": ymd.year, "month": ymd.month, "day": ymd.day]
    }
    
    /// 获取当前月的总天数
    @objc(wy_currentMonthDays)
    static func wy_currentMonthDaysObjC() -> String {
        return String.wy_currentMonthDays()
    }
    
    /// 时间戳转星期几
    @objc(wy_whatDay)
    var wy_whatDayObjC: WYWhatDayObjC {
        let whatDay: WYWhatDay = (self as String).wy_whatDay
        return WYWhatDayObjC(rawValue: whatDay.rawValue) ?? .unknown
    }
    
    /**
     *  计算两个时间戳之间的间隔周期(适用于IM项目)
     *  messageTimestamp  消息对应的时间戳
     *  clientTimestamp 客户端时间戳(当前的网络时间戳或者设备本地的时间戳)
     */
    @objc(wy_timeIntervalCycleWithTimestamp:clientTimestamp:)
    static func wy_timeIntervalCycleObjC(_ timestamp: String, clientTimestamp: String = String.wy_sharedDeviceTimestamp()) -> WYTimeDistanceObjC {
        
        let timeDistance: WYTimeDistance = String.wy_timeIntervalCycle(timestamp, clientTimestamp)
        
        return WYTimeDistanceObjC(rawValue: timeDistance.rawValue) ?? .unknown
    }
    
    /**
     *  时间戳距离现在的间隔时间
     *  dateFormat 要转换的格式
     *  customFormat 仅dateFormat为custom时才需要传(如"yyyy-MM-dd HH:mm:ss")，其余传nil就行
     */
    @objc(wy_dateDifferenceWithNowTimer:)
    func wy_dateDifferenceWithNowTimerObjC(_ dateFormat: WYTimeFormatObjC) -> String {
        return wy_dateDifferenceWithNowTimerObjC(dateFormat, customFormat: nil)
    }
    @objc(wy_dateDifferenceWithNowTimer:customFormat:)
    func wy_dateDifferenceWithNowTimerObjC(_ dateFormat: WYTimeFormatObjC, customFormat: String?) -> String {
        return (self as String).wy_dateDifferenceWithNowTimer(wy_convertObjCTimeFormatToSwift(dateFormat, customFormat))
    }
    
    /**
     从字符串中提取数字（支持可选前缀、千分位、小数）

     - Parameter prefixs: 可选前缀（如 ["+", "-", "¥", "$"]，最多1个且在最前）

     - 示例：
       输入："价格 ¥1,234.56，优惠 $999，再加 +100，折扣 0.5"
       输出：["¥1,234.56", "$999", "+100", "0.5"]

       输入："数量 123 和 45.67"
       输出：["123", "45.67"]

     - Returns: 提取到的数字字符串数组
     */
    @objc(wy_extractNumbers)
    func wy_extractNumbersObjC() -> [String] {
        return wy_extractNumbersObjC(prefixs: [])
    }
    @objc(wy_extractNumbersWithPrefixs:)
    func wy_extractNumbersObjC(prefixs: [String] = []) -> [String] {
        return (self as String).wy_extractNumbers(prefixs: prefixs)
    }
    
    /**
     *  汉字转拼音
     *  @param tone: 是否需要保留音调
     *  @param interval: 拼音之间是否需要用空格间隔开
     */
    @objc(wy_phoneticTransformWithTone:interval:)
    func wy_phoneticTransformObjC(tone: Bool = false, interval: Bool = false) -> String {
        return (self as String).wy_phoneticTransform(tone: tone, interval: interval)
    }
    
    /**
     解析范围值，返回有效的 `NSRange(NSValue包装)` 数组。
     
     支持类型：`String`、`NSRange(NSValue包装)`、`[String]`、`[NSRange(NSValue包装)]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange(NSValue包装)]`）。
     
     - Returns: 经过边界有效性检查并去重后的 `[NSRange(NSValue包装)]` 数组。
     */
    @objc(wy_parseRangesWithValue:)
    func wy_parseRangesObjC(_ rangeValue: Any) -> [NSValue] {
        let ranges = (self as String).wy_parseRanges(from: rangeValue)
        return ranges.map { NSValue(range: $0) }
    }
    
    /// 根据时间戳获取星座
    @objc(wy_convertToConstellation:)
    static func wy_convertToConstellationObjC(_ timestamp: String) -> WYConstellationObjC {
        return WYConstellationObjC(rawValue: String.wy_convertToConstellation(timestamp).rawValue) ?? .unknown
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
