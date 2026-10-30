//
//  WYAppleServices+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/30.
//

import Foundation
import UIKit

/// Apple系统相关功能封装
extension WYAppleServices {

    /// 弹出 eSIM 不支持的提示(有自定义文案用自定义，没有用默认文案，挂在当前最上层的界面控制器上弹出)
    static func showUnsupportedTip(_ tip: String?) {

        var presenter = UIApplication.shared.wy_keyWindow.rootViewController
        while let presented = presenter?.presentedViewController {
            presenter = presented
        }
        let alert = UIAlertController(title: tip ?? WYLocalized("当前设备不支持 eSIM", table: WYBasisKitConfig.kitLocalizableTable), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable), style: .default))
        presenter?.present(alert, animated: true)
    }

    /// 把获取到的 LPA 串归一成带大写 LPA: 前缀的完整格式(兼容任意大小写的 lpa: 前缀与不带前缀，空串或全空白返回 nil)
    static func normalizedLpa(_ lpa: String) -> String? {

        let trimmed = lpa.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // 带任意大小写 lpa: 前缀时先去掉再统一补大写前缀
        let body = trimmed.lowercased().hasPrefix("lpa:") ? String(trimmed.dropFirst(4)) : trimmed
        return "LPA:" + body
    }

    /// 查询字段值编码字符集(排除 & = + ? 分隔符，防止字段值里的符号破坏链接结构)
    static let fieldValueAllowed: CharacterSet = .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+=?"))

    /// 去掉地址前后空白后用逗号拼接(空地址自动跳过，拼完为空说明没有可用地址)
    static func joinedAddresses(_ addresses: [String]) -> String {
        return addresses.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.joined(separator: ",")
    }

    /// 拼发邮件用的 mailto 链接(收件人列表没有可用地址时返回 nil)
    static func mailURL(to: [String], cc: [String], bcc: [String], subject: String, body: String) -> URL? {

        let toPart = joinedAddresses(to)
        guard !toPart.isEmpty else { return nil }

        var queryItems: [String] = []
        let ccPart = joinedAddresses(cc)
        if !ccPart.isEmpty {
            queryItems.append("cc=\(ccPart.addingPercentEncoding(withAllowedCharacters: fieldValueAllowed) ?? "")")
        }
        let bccPart = joinedAddresses(bcc)
        if !bccPart.isEmpty {
            queryItems.append("bcc=\(bccPart.addingPercentEncoding(withAllowedCharacters: fieldValueAllowed) ?? "")")
        }
        if !subject.isEmpty {
            queryItems.append("subject=\(subject.addingPercentEncoding(withAllowedCharacters: fieldValueAllowed) ?? "")")
        }
        if !body.isEmpty {
            queryItems.append("body=\(body.addingPercentEncoding(withAllowedCharacters: fieldValueAllowed) ?? "")")
        }

        var urlString = "mailto:\(toPart)"
        if !queryItems.isEmpty {
            urlString += "?" + queryItems.joined(separator: "&")
        }
        return URL(string: urlString)
    }

    /// 拼发短信用的 sms 链接(收件人列表没有可用地址时返回 nil，iOS 的短信链接用 & 接内容而不是 ?，这是系统短信应用的约定)
    static func smsURL(to: [String], body: String) -> URL? {

        let toPart = joinedAddresses(to)
        guard !toPart.isEmpty else { return nil }

        var urlString = "sms:\(toPart)"
        if !body.isEmpty {
            urlString += "&body=\(body.addingPercentEncoding(withAllowedCharacters: fieldValueAllowed) ?? "")"
        }
        return URL(string: urlString)
    }

    /// 拼 itms-apps 链接并唤起(App Store 专用 scheme，action 传 nil 打开详情页、传 write-review 打开评分页，appId 为空时直接回调 false)
    static func openStore(appId: String, action: String?, completion: ((_ success: Bool) -> Void)?) {

        let trimmed = appId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion?(false)
            return
        }

        var urlString = "itms-apps://itunes.apple.com/app/id\(trimmed)"
        if let action, !action.isEmpty {
            urlString += "?action=\(action)"
        }
        guard let url = URL(string: urlString) else {
            completion?(false)
            return
        }
        open(url: url, completion: completion)
    }
}
