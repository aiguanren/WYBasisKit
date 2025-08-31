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
@frozen public enum WYWhatDay: Int {
    
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

public extension Optional where Wrapped == String {
    /// 获取非空安全值
    var wy_safe: String {
        if let value = self, !value.isEmpty {
            return value
        }
        return ""
    }
}

public extension String {
    
    /**
     *  获取一个随机字符串
     *
     *  @param min   最少需要多少个字符
     *
     *  @param max   最多需要多少个字符
     *
     */
    static func wy_random(minimux: Int = 1, maximum: Int = 100) -> String {
        
        guard maximum >= minimux else { return "" }
        
        let phrases = [
            "嗨",
            "美女",
            "么么哒",
            "阳光明媚",
            "春风拂面暖",
            "梦想照亮前路",
            "窗外繁花正盛开",
            "风花雪月诗意生活",
            "让时光沉淀爱的芬芳",
            "樱花飘落，温柔了梦乡",
            "微风不燥，时光正好，你我相遇，此时甚好。",
            "早知混成这样，不如找个对象，少妇一直是我的理想，她已有车有房，不用我去闯荡，吃着软饭是真的很香。",
            "关关雎鸠，在河之洲。窈窕淑女，君子好逑。参差荇菜，左右流之。窈窕淑女，寤寐求之。求之不得，寤寐思服。悠哉悠哉，辗转反侧。参差荇菜，左右采之。窈窕淑女，琴瑟友之。参差荇菜，左右芼之。窈窕淑女，钟鼓乐之。",
            "漫步海边，脚下的沙砾带着白日阳光的余温，细腻而柔软。海浪层层叠叠地涌来，热情地亲吻沙滩，又恋恋不舍地退去，发出悦耳声响。海风肆意穿梭，咸湿气息钻进鼻腔，带来大海独有的韵味。抬眼望去，落日熔金，余晖将海面染成橙红，粼粼波光像是无数碎钻在闪烁。我沉醉其中，心也被这梦幻海景悄然填满。"
        ]
        
        // 随机字符长度
        let targetLength = Int.random(in: minimux...maximum)
        
        guard targetLength >= 1 else { return "" }
        
        var contentPhrases: [String] = [];
        for _ in 0..<targetLength {
            // 获取拼接后的符合长度的字符串
            contentPhrases = findSpliceCharacter(targetLength: targetLength, phrases: contentPhrases)
            if (contentPhrases.joined().count >= targetLength) {
                break
            }
        }
        return contentPhrases.joined()
        
        /// 找出长度最接近 surplusLength 且小于 surplusLength 的 phrase
        func sharedBestFitPhrase(surplusLength: Int) -> String {
            var selectedPhrase = ""
            for phrase in phrases {
                
                if (phrase.count == surplusLength) {
                    return phrase
                }
                
                if phrase.count < surplusLength, phrase.count > selectedPhrase.count {
                    selectedPhrase = phrase
                }else {
                    break
                }
            }
            return selectedPhrase
        }
        
        /// 判断字符串最后或第一个字符是否是标点符号
        func phraseEndingsComplete(phrase: String, suffix: Bool) -> Bool {
            // 去除首尾空格和换行符
            let trimmedString = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 检查字符串是否为空
            guard let targetChar = (suffix ? trimmedString.last : trimmedString.first) else {
                return false
            }
            
            // 定义中英文标点集合（可根据需要扩展）
            let punctuation = ",，.。：:；;！!？?"
            
            // 判断最后一个字符是否在标点集合中
            return punctuation.contains(targetChar)
        }
        
        /// 判断下一个匹配的字符串尾部是否有标点符号
        func nextPhraseEndingsComplete(surplusLength: Int) -> Bool {
            
            // 获取下一个字符串
            let nextPhrase: String = sharedBestFitPhrase(surplusLength: surplusLength)
            
            // 判断nextPhrase中最后一个字符是否是标点符号
            return phraseEndingsComplete(phrase: nextPhrase, suffix: true)
        }
        
        /// 查找并拼接字符长度至目标长度
        func findSpliceCharacter(targetLength: Int, phrases: [String] = []) ->[String] {
            
            // 当前字符串
            let currentPhrase: String = phrases.joined()
            
            // 获取最接近targetLength的字符串
            let targetPhrase: String = sharedBestFitPhrase(surplusLength: targetLength - currentPhrase.count)
            
            var contentPhrases: [String] = phrases
            
            // 判断targetPhrase中最后一个字符是否是标点符号
            let suffix: Bool = phraseEndingsComplete(phrase: targetPhrase, suffix: true)
            
            // 获取并判断下一个匹配的字符串尾部是否是标点符号
            let nextSuffix: Bool = nextPhraseEndingsComplete(surplusLength: targetLength - currentPhrase.count - targetPhrase.count - 1)
            
            if suffix == false {
                // 判断拼接标点符号后是否满足长度
                if ((targetPhrase.count + currentPhrase.count) == targetLength) {
                    contentPhrases.insert(targetPhrase, at: 0)
                }else if ((targetPhrase.count + currentPhrase.count + 1) == targetLength) {
                    contentPhrases.insert("😄" + targetPhrase, at: 0)
                }else {
                    contentPhrases.insert(((nextSuffix == true) ? "" : "，") + targetPhrase, at: 0)
                }
            }else {
                // 判断拼接标点符号后是否满足长度
                if ((targetPhrase.count + currentPhrase.count) == targetLength) {
                    contentPhrases.insert(targetPhrase, at: 0)
                }else if ((targetPhrase.count + currentPhrase.count + 1) == targetLength) {
                    contentPhrases.insert("😄" + targetPhrase, at: 0)
                }else {
                    contentPhrases.insert(((nextSuffix == true) ? "" : "，") + targetPhrase, at: 0)
                }
            }
            return contentPhrases
        }
    }
    
    /// String转CGFloat、Double、Int、Decimal
    func wy_convertTo<T: Any>(_ type: T.Type) -> T {
        
        guard (type == CGFloat.self) || (type == Double.self) || (type == Int.self) || (type == Decimal.self) || (type == String.self) else {
            fatalError("type只能是CGFloat、Double、Int、Decimal中的一种")
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
    
        let attributeText: NSAttributedString = NSAttributedString(string: self, attributes: attributes)
        
        return attributeText.wy_calculateSize(controlSize: controlSize)
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
    func wy_substring(from: Int, to: Int) -> String {
        
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
    func wy_substring(from: Int, after: Int) -> String {
        
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
    
    /// 将 NSRange 转换为 Swift String.Index 范围（安全转换，避免越界，比如UITextView.selectedRange 是 NSRange，它的单位是 UTF-16 的位置。 而 Swift 的 String 是基于 Unicode 标量 来索引的，一些字符（尤其是 emoji）占 2 个或更多 UTF-16 单元。如果直接用 NSRange.location/length 来切 String，Swift 会按照字符来计算索引，这就可能导致越界或者切到半个 emoji，从而引起闪退，就像你有一个尺子，一个是厘米刻度（Swift String 的索引），一个是毫米刻度（NSRange 的 UTF16 单元），直接按毫米数去量厘米会出问题。正确的方法是先把毫米换算成厘米，再去量）
    func wy_range(from nsRange: NSRange) -> Range<String.Index>? {
        
        // 起点
        guard let from16 = utf16.index(utf16.startIndex,
                                       offsetBy: nsRange.location,
                                       limitedBy: utf16.endIndex) else { return nil }
        
        // 终点
        guard let to16 = utf16.index(from16,
                                     offsetBy: nsRange.length,
                                     limitedBy: utf16.endIndex) else { return nil }
        
        // 转换成 Swift String.Index
        guard let from = String.Index(from16, within: self),
              let to = String.Index(to16, within: self) else { return nil }
        
        return from..<to
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
        let characterSet = CharacterSet(charactersIn: escape).inverted
        return self.addingPercentEncoding(withAllowedCharacters: characterSet) ?? self
    }
    
    /// Decode
    var wy_decoded: String {
        
        // 去掉所有 "+" 符号
        let cleaned = self.replacingOccurrences(of: "+", with: "")
        // 进行 URL 解码，如果失败返回原字符串
        return cleaned.removingPercentEncoding ?? self
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
    func wy_secondConvertDate(check: Bool = true) -> String {
        let totalSeconds: Int = self.wy_convertTo(Int.self)
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
        let computingTime = (self.count <= 10) ? (Int(self) ?? 0) : ((Int(self) ?? 0) / 1000)
        // 距离当前的时间差
        let timeDifference = Int(currentTime) - computingTime
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
        return self.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap({$0.count > 0 ? $0 : nil})
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
        
        let phonetic = mString as String
        
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
