//
//  String.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit
import CryptoKit

/// 获取时间戳的模式
@frozen public enum WYTimestampMode {
    
    /// 秒
    case second
    
    /// 毫秒
    case millisecond
    
    /// 微秒
    case microseconds
}

/// 时间格式化模式
@frozen public enum WYTimeFormat {
    
    /// 时:分
    case HM
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
    case custom(format: String)
}

/// 星期几
@frozen public enum WYWhatDay: NSInteger {
    
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

@frozen public enum WYTimeDistance {
    
    /// 未知
    case unknown
    
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

public extension String {
    
    /// String转CGFloat、Double、Int、NSInteger、Decimal
    func wy_convertTo<T: Any>(_ type: T.Type) -> T {
        
        guard (type == CGFloat.self) || (type == Double.self) || (type == Int.self) || (type == NSInteger.self) || (type == Decimal.self) || (type == String.self) else {
            fatalError("type只能是CGFloat、Double、Int、NSInteger、Decimal中的一种")
        }
        
        /// 判断是否是纯数字
        func securityCheck(_ string: String) -> String {
            return string.isEmpty ? "0" : self
        }
        
        if type == CGFloat.self {
            return CGFloat(Float(securityCheck(self)) ?? 0.0) as! T
        }
        
        if type == Double.self {
            return Double(securityCheck(self)) as! T
        }
        
        if type == Int.self {
            return Int(securityCheck(self)) as! T
        }
        
        if type == Decimal.self {
            return Decimal(string: securityCheck(self)) as! T
        }
        
        return self as! T
    }
    
    /// 返回一个计算好的字符串的宽度
    func wy_calculateWidth(controlHeight: CGFloat, controlFont: UIFont, lineSpacing: CGFloat = 0, wordsSpacing: CGFloat = 0) -> CGFloat {
        
        let sharedControlHeight = (controlHeight == 0) ? controlFont.lineHeight : controlHeight
        return wy_calculategSize(controlSize: CGSize(width: .greatestFiniteMagnitude, height: sharedControlHeight), controlFont: controlFont, lineSpacing: lineSpacing, wordsSpacing: wordsSpacing).width
    }
    
    /// 返回一个计算好的字符串的高度
    func wy_calculateHeight(controlWidth: CGFloat, controlFont: UIFont, lineSpacing: CGFloat = 0, wordsSpacing: CGFloat = 0) -> CGFloat {
        
        return wy_calculategSize(controlSize: CGSize(width: controlWidth, height: .greatestFiniteMagnitude), controlFont: controlFont, lineSpacing: lineSpacing, wordsSpacing: wordsSpacing).height
    }
    
    /// 返回一个计算好的字符串的size
    func wy_calculategSize(controlSize: CGSize, controlFont: UIFont, lineSpacing: CGFloat = 0, wordsSpacing: CGFloat = 0) -> CGSize {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        let attributes = [NSAttributedString.Key.font: controlFont, NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.kern: NSNumber(value: Double(wordsSpacing))]
        
        let string = self as NSString
        let stringSize: CGSize = string.boundingRect(with: controlSize, options: NSStringDrawingOptions(rawValue: NSStringDrawingOptions.truncatesLastVisibleLine.rawValue | NSStringDrawingOptions.usesLineFragmentOrigin.rawValue | NSStringDrawingOptions.usesFontLeading.rawValue), attributes: attributes, context: nil).size
        
        return CGSize(width: ceil(stringSize.width), height: ceil(stringSize.height))
    }
    
    /// 判断字符串包含某个字符串
    func wy_stringContains(find: String) -> Bool{
        return self.range(of: find) != nil
    }
    
    /// 判断字符串包含某个字符串(忽略大小写)
    func wy_stringContainsIgnoringCase(find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    
    /// 字符串截取(从第几位截取到第几位)
    func wy_substring(from: NSInteger, to: NSInteger) -> String {
        
        guard from < self.count else {
            return self
        }
        
        guard to < self.count else {
            return self
        }
        
        let startIndex = self.index(self.startIndex, offsetBy: from)
        let endIndex = self.index(self.startIndex, offsetBy: to)
        
        return String(self[startIndex...endIndex])
    }
    
    /// 字符串截取(从第几位往后截取几位)
    func wy_substring(from: NSInteger, after: NSInteger) -> String {
        
        guard from < self.count else {
            return self
        }
        
        guard (from + after) < self.count else {
            return self
        }
        
        let startIndex = self.index(self.startIndex, offsetBy: from)
        let endIndex = self.index(self.startIndex, offsetBy: from + after)
        
        return String(self[startIndex...endIndex])
    }
    
    /**
     *  替换指定字符(useRegex为true时，会过滤掉 appointSymbol 字符中所包含的每一个字符, useRegex为false时，会过滤掉字符串中所包含的整个 appointSymbol 字符)
     *  @param appointSymbol: 要替换的字符
     *  @param replacement: 替换成什么字符
     *  @param useRegex: 过滤方式，true正则表达式过滤, false为系统方式过滤
     */
    func wy_replace(appointSymbol: String ,replacement: String, useRegex: Bool = false) -> String {
        
        if (useRegex == true) {
            let regex = try! NSRegularExpression(pattern: "[\(appointSymbol)]", options: [])
            return regex.stringByReplacingMatches(in: self, options: [],
                                                  range: NSMakeRange(0, self.count),
                                                  withTemplate: replacement)
        }else {
            return self.replacingOccurrences(of: appointSymbol, with: replacement)
        }
    }
    
    /// 字符串去除特殊字符
    func wy_specialCharactersEncoding(_ characterSet: CharacterSet = .urlQueryAllowed) -> String {
        return self.addingPercentEncoding(withAllowedCharacters: characterSet) ?? ""
    }
    
    /// 字符串去除Emoji表情
    func wy_replaceEmoji(_ replacement: String = "") -> String {
        return self.unicodeScalars
            .filter { !$0.properties.isEmojiPresentation}
            .reduce(replacement) { $0 + String($1) }
    }
    
    /**
     *  SHA256加密
     *  @param uppercase: 是否需要大写，默认false
     */
    func wy_sha256(uppercase: Bool = false) -> String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        let hashString = hashed.map { String(format: "%02x", $0) }.joined()
        return uppercase ? hashString.uppercased() : hashString
    }
    
    /// Encode
    func wy_encoded(escape: String = "?!@#$^&%*+,:;='\"`<>()[]{}/\\| ") -> String {
        
        let characterSet = NSCharacterSet(charactersIn: escape).inverted
        return self.addingPercentEncoding(withAllowedCharacters: characterSet) ?? self
    }
    
    /// Decode
    var wy_decoded: String {
        
        let targetString: NSMutableString = NSMutableString(string: self)
        targetString.replaceOccurrences(of: "+", with: "", options: .literal, range: NSMakeRange(0, targetString.length))
        return targetString.removingPercentEncoding ?? self
    }
    
    /// base64编码
    var wy_base64Encoded: String {
        guard let data = data(using: .utf8) else {
            return self
        }
        return data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
    
    /// base64解码
    var wy_base64Decoded: String {
        
        guard let data = data(using: .utf8) else {
            return self
        }
        
        if let decodedData = Data(base64Encoded: data, options: Data.Base64DecodingOptions(rawValue: 0)) {
            return String(data: decodedData, encoding: .utf8) ?? self
        }
        return self
    }
    
    /// 获取设备时间戳
    static func wy_sharedDeviceTimestamp(_ mode: WYTimestampMode = .second) -> String {
        
        let timeInterval: TimeInterval = Date().timeIntervalSince1970
        switch mode {
        case .second:
            return "\(timeInterval)".components(separatedBy: ".").first ?? ""
        case .millisecond:
            return "\(CLongLong(round(timeInterval*1000)))".components(separatedBy: ".").first ?? ""
        case .microseconds:
            return "\(CLongLong(round(timeInterval*1000*1000)))".components(separatedBy: ".").first ?? ""
        }
    }
    
    /// 秒 转 时分秒（00:00:00）格式
    func wy_secondConvertDate(check: Bool) -> String {
        let totalSeconds: Int = Int((self as NSString).doubleValue)
        var hours = 0
        var minutes = 0
        var seconds = 0
        var hoursText = ""
        var minutesText = ""
        var secondsText = ""
        
        hours = totalSeconds / 3600
        hoursText = hours > 9 ? "\(hours)" : "0\(hours)"
        
        minutes = totalSeconds % 3600 / 60
        minutesText = minutes > 9 ? "\(minutes)" : "0\(minutes)"
        
        seconds = totalSeconds % 3600 % 60
        secondsText = seconds > 9 ? "\(seconds)" : "0\(seconds)"
        
        if ((check == true) && (hours <= 0)) {
            return "\(minutesText):\(secondsText)"
        }else {
            return "\(hoursText):\(minutesText):\(secondsText)"
        }
    }
    
    /**
     *  时间戳转年月日格式
     *  dateFormat 要转换的格式
     *  showAmPmSymbol 是否显示上午下午，为true时为12小时制，否则为24小时制
     */
    func  wy_timestampConvertDate(_ dateFormat: WYTimeFormat, _ showAmPmSymbol: Bool = false) -> String {
        
        if self.isEmpty {return ""}
        
        let dateString: String = self.count <= 10 ? self : "\(((NumberFormatter().number(from: self)?.doubleValue ?? 0.0) / 1000))"
        
        let date: Date = Date(timeIntervalSince1970: Double(dateString)!)
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.calendar.timeZone = NSTimeZone.local
        if showAmPmSymbol == false {
            // 不显示上午或者下午标识
            formatter.amSymbol = ""
            formatter.pmSymbol = ""
            formatter.locale = Locale(identifier: "")
        }
        formatter.dateFormat = sharedTimeFormat(dateFormat: dateFormat)
        
        return formatter.string(from: date as Date)
    }
    
    /// 获取当前的 年、月、日
    static func wy_currentYearMonthDay() -> (year: String, month: String, day: String) {
        let calendar = Calendar.current
        let dateComponets = calendar.dateComponents([Calendar.Component.year,Calendar.Component.month,Calendar.Component.day], from: Date())
        return ("\(dateComponets.year!)", "\(dateComponets.month!)", "\(dateComponets.day!)")
    }
    
    /// 获取当前月的总天数
    static func wy_curentMonthDays() -> String {
        let calendar = Calendar.current
        let range = calendar.range(of: Calendar.Component.day, in: Calendar.Component.month, for: Date())
        return "\(range!.count)"
    }
    
    /// 时间戳转星期几
    var wy_whatDay: WYWhatDay {

        guard [10, 13].contains(count) else {
            return .unknown
        }
        
        let timeInterval: TimeInterval = NumberFormatter().number(from: self)?.doubleValue ?? 0.0

        let date: Date = Date(timeIntervalSince1970: timeInterval / (count == 13 ? 1000.0 : 1.0))

        var calendar: Calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = NSTimeZone.local
        
        let dateComponents: DateComponents = calendar.dateComponents([Calendar.Component.year,Calendar.Component.month,Calendar.Component.weekday,Calendar.Component.day], from: date)
        
        return WYWhatDay(rawValue: dateComponents.weekday ?? 0) ?? .unknown
    }
    
    /// 年月日格式转时间戳
    func wy_dateStrConvertTimestamp(_ dateFormat: WYTimeFormat) -> String {
        
        if self.isEmpty {return ""}
        
        let format = DateFormatter()
        
        format.dateStyle = .medium
        format.timeStyle = .short
        format.dateFormat = sharedTimeFormat(dateFormat: dateFormat)
        
        let date = format.date(from: self)
        
        return String(date!.timeIntervalSince1970)
    }
    
    /**
     *  计算两个时间戳之间的间隔周期(适用于IM项目)
     *  messageTimestamp  消息对应的时间戳
     *  clientTimestamp 客户端时间戳(当前的网络时间戳或者设备本地的时间戳)
     */
    static func wy_timeIntervalCycle(_ messageTimestamp: String, _ clientTimestamp: String = wy_sharedDeviceTimestamp()) -> WYTimeDistance {

        guard ([10, 13].contains(messageTimestamp.count)) && ([10, 13].contains(clientTimestamp.count)) else {
            return .unknown
        }

        var calendar: Calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = NSTimeZone.local

        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.calendar = calendar

        var clientDate: Date!

        let message_timestamp: TimeInterval = NumberFormatter().number(from: messageTimestamp)?.doubleValue ?? 0

        let client_timestamp: TimeInterval = NumberFormatter().number(from: clientTimestamp)?.doubleValue ?? 0

        if ((message_timestamp >= client_timestamp) || (message_timestamp <= 0)) {
            clientDate = Date(timeIntervalSince1970: client_timestamp / (clientTimestamp.count == 13 ? 1000.0 : 1.0))
        }else {
            clientDate = Date(timeIntervalSince1970: message_timestamp / (messageTimestamp.count == 13 ? 1000.0 : 1.0))
        }
        
        /// 一天的秒数
        let secondsPerDay: TimeInterval = 24 * 60 * 60
        
        let componentsSet: Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day]
        
        func components(_ day: TimeInterval) -> DateComponents {
            
            let date: Date = Date(timeIntervalSince1970: (client_timestamp / (clientTimestamp.count == 13 ? 1000.0 : 1.0)) - (day * secondsPerDay))
            
            return calendar.dateComponents(componentsSet, from: date)
        }
        
        let clientComponents = calendar.dateComponents(componentsSet, from: clientDate)
        
        let dateComponents = (today: components(0),
                              aDayAgo: components(1),
                              twoDaysAgo: components(2),
                              threeDaysAgo: components(3),
                              fourDaysAgo: components(4),
                              fiveDaysAgo: components(5),
                              sixDaysAgo: components(6))

        if ((clientComponents.year == dateComponents.today.year) && (clientComponents.month == dateComponents.today.month) && (clientComponents.day == dateComponents.today.day)) {
            return .today
        }

        if ((clientComponents.year == dateComponents.aDayAgo.year) && (clientComponents.month == dateComponents.aDayAgo.month) && (clientComponents.day == dateComponents.aDayAgo.day)) {
            return .yesterday
        }

        if ((clientComponents.year == dateComponents.twoDaysAgo.year) && (clientComponents.month == dateComponents.twoDaysAgo.month) && (clientComponents.day == dateComponents.twoDaysAgo.day)) {
            return .yesterdayBefore
        }
        
        if (((clientComponents.year == dateComponents.threeDaysAgo.year) && (clientComponents.month == dateComponents.threeDaysAgo.month) && (clientComponents.day == dateComponents.threeDaysAgo.day)) || ((clientComponents.year == dateComponents.fourDaysAgo.year) && (clientComponents.month == dateComponents.fourDaysAgo.month) && (clientComponents.day == dateComponents.fourDaysAgo.day)) ||
            ((clientComponents.year == dateComponents.fiveDaysAgo.year) && (clientComponents.month == dateComponents.fiveDaysAgo.month) && (clientComponents.day == dateComponents.fiveDaysAgo.day)) ||
            ((clientComponents.year == dateComponents.sixDaysAgo.year) && (clientComponents.month == dateComponents.sixDaysAgo.month) && (clientComponents.day == dateComponents.sixDaysAgo.day))) {
            return .withinWeek
        }
        
        if ((clientComponents.year == dateComponents.twoDaysAgo.year) && (clientComponents.month == dateComponents.twoDaysAgo.month)) {
            return .withinSameMonth
        }
        
        if clientComponents.year == dateComponents.twoDaysAgo.year {
            return .withinSameYear
        }
        
        return .unknown
    }
    
    /// 时间戳距离现在的间隔时间
    func wy_dateDifferenceWithNowTimer(_ dateFormat: WYTimeFormat) -> String {
        
        // 当前时时间戳
        let currentTime = Date().timeIntervalSince1970
        // 传入的时间
        let computingTime = (self.count <= 10) ? (NSInteger(self) ?? 0) : ((NSInteger(self) ?? 0) / 1000)
        // 距离当前的时间差
        let timeDifference = NSInteger(currentTime) - computingTime
        // 秒转分钟
        let second = timeDifference / 60
        if (second <= 0) {
            return WYLocalized("WYLocalizable_30", table: WYBasisKitConfig.kitLocalizableTable)
        }
        if second < 60 {
            return String(format: WYLocalized("WYLocalizable_31", table: WYBasisKitConfig.kitLocalizableTable), "\(second)")
        }
        
        // 秒转小时
        let hours = timeDifference / 3600
        if hours < 24 {
            return String(format: WYLocalized("WYLocalizable_32", table: WYBasisKitConfig.kitLocalizableTable), "\(hours)")
        }
        
        // 秒转天数
        let days = timeDifference / 3600 / 24
        if days < 30 {
            return String(format: WYLocalized("WYLocalizable_33", table: WYBasisKitConfig.kitLocalizableTable), "\(days)")
        }
        
        // 秒转月
        let months = timeDifference / 3600 / 24 / 30
        if months < 12 {
            return String(format: WYLocalized("WYLocalizable_34", table: WYBasisKitConfig.kitLocalizableTable), "\(months)")
        }
        
        // 秒转年
        let years = timeDifference / 3600 / 24 / 30 / 12
        if years < 3 {
            return String(format: WYLocalized("WYLocalizable_35", table: WYBasisKitConfig.kitLocalizableTable), "\(years)")
        }
        return wy_timestampConvertDate(dateFormat)
    }
    
    /// 从字符串中提取数字
    var wy_extractNumbers: [String] {
        return self.components(separatedBy: NSCharacterSet.decimalDigits.inverted).compactMap({$0.count > 0 ? $0 : nil})
    }
    
    /**
     *  汉字转拼音
     *  @param tone: 是否需要保留音调
     *  @param interval: 拼音之间是否需要用空格间隔开
     */
    func wy_phoneticTransform(tone: Bool = false, interval: Bool = false) -> String {
        
        // 转化为可变字符串
        let mString = NSMutableString(string: self)
        
        // 转化为带声调的拼音
        CFStringTransform(mString, nil, kCFStringTransformToLatin, false)
        
        if !tone {
            // 转化为不带声调
            CFStringTransform(mString, nil, kCFStringTransformStripDiacritics, false)
        }
        
        let phonetic = (NSString(string: mString) as String)
        
        if !interval {
            // 去除字符串之间的空格
            return phonetic.replacingOccurrences(of: " ", with: "")
        }
        return phonetic
    }
    
    /// 根据时间戳获取星座
    static func wy_constellation(from timestamp: String) -> String {
        
        let timeInterval: TimeInterval = timestamp.count <= 10 ? (NumberFormatter().number(from: timestamp)?.doubleValue ?? 0.0) : ((NumberFormatter().number(from: timestamp)?.doubleValue ?? 0.0) / 1000)
        
        let oneDay:Double = 86400
        let constellationDics = [WYLocalized("WYLocalizable_37", table: WYBasisKitConfig.kitLocalizableTable): "12.22-1.19",
                                 WYLocalized("WYLocalizable_38", table: WYBasisKitConfig.kitLocalizableTable): "1.20-2.18",
                                 WYLocalized("WYLocalizable_39", table: WYBasisKitConfig.kitLocalizableTable): "2.19-3.20",
                                 WYLocalized("WYLocalizable_40", table: WYBasisKitConfig.kitLocalizableTable): "3.21-4.19",
                                 WYLocalized("WYLocalizable_41", table: WYBasisKitConfig.kitLocalizableTable): "4.20-5.20",
                                 WYLocalized("WYLocalizable_42", table: WYBasisKitConfig.kitLocalizableTable): "5.21-6.21",
                                 WYLocalized("WYLocalizable_43", table: WYBasisKitConfig.kitLocalizableTable): "6.22-7.22",
                                 WYLocalized("WYLocalizable_44", table: WYBasisKitConfig.kitLocalizableTable): "7.23-8.22",
                                 WYLocalized("WYLocalizable_45", table: WYBasisKitConfig.kitLocalizableTable): "8.23-9.22",
                                 WYLocalized("WYLocalizable_46", table: WYBasisKitConfig.kitLocalizableTable): "9.23-10.23",
                                 WYLocalized("WYLocalizable_47", table: WYBasisKitConfig.kitLocalizableTable): "10.24-11.22",
                                 WYLocalized("WYLocalizable_48", table: WYBasisKitConfig.kitLocalizableTable): "11.23-12.21"]
        
        let currConstellation = constellationDics.filter {
            
            let timeRange = constellationDivision(timestamp: timestamp, range: $1)
            let startTime = timeRange.0
            let endTime = timeRange.1 + oneDay
            
            return timeInterval > startTime && timeInterval < endTime
        }
        return currConstellation.first?.key ?? WYLocalized("WYLocalizable_37", table: WYBasisKitConfig.kitLocalizableTable)
    }
}

private extension String {
    
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
    
    /// 获取星座开始、结束时间
    static func constellationDivision(timestamp: String, range: String) -> (TimeInterval, TimeInterval) {
        
        /// 获取当前年份
        func getCurrYear(date:Date) -> String {
            
            let dm = DateFormatter()
            dm.dateFormat = "yyyy."
            let currYear = dm.string(from: date)
            return currYear
        }
        
        /// 日期转换当前时间戳
        func toTimeInterval(dateStr: String) -> TimeInterval? {
            
            let dm = DateFormatter()
            dm.dateFormat = "yyyy.MM.dd"
            
            let date = dm.date(from: dateStr)
            let interval = date?.timeIntervalSince1970
            
            return interval
        }
        
        let timeStrArr = range.components(separatedBy: "-")
        
        let timeInterval: TimeInterval = timestamp.count <= 10 ? (NumberFormatter().number(from: timestamp)?.doubleValue ?? 0.0) : ((NumberFormatter().number(from: timestamp)?.doubleValue ?? 0.0) / 1000)
        
        let dateYear = getCurrYear(date: Date(timeIntervalSince1970: timeInterval))
        let startTimeStr = dateYear + timeStrArr.first!
        let endTimeStr = dateYear + timeStrArr.last!
        
        let startTime = toTimeInterval(dateStr: startTimeStr)!
        let endTime = toTimeInterval(dateStr: endTimeStr)!
        
        return (startTime, endTime)
    }
}
