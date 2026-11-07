//
//  WYAppleServices+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/30.
//

import Foundation
import UIKit
import CoreImage
import CoreTelephony

/// Apple系统相关功能封装
extension WYAppleServices {

    static let fieldValueAllowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+=?#%"))
    static let phoneCharacters = CharacterSet(charactersIn: "+0123456789-().")
    static let serverCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-.")

    static var installationLinkAvailable: Bool {
        if #available(iOS 17.4, *) { return true }
        return false
    }

    static func currentEsimCapability() -> WYEsimRegionSupport {
        #if targetEnvironment(simulator)
        return .unknown
        #else
        guard #available(iOS 16.0, *) else { return .unknown }
        return reportedEsimCapability(CTCellularPlanProvisioning().supportsEmbeddedSIM)
        #endif
    }

    static func reportedEsimCapability(_ supported: Bool) -> WYEsimRegionSupport {
        return supported ? .supported : .unknown
    }

    static func performOnMain(_ action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        }else {
            DispatchQueue.main.async(execute: action)
        }
    }

    static func openSystemURL(_ url: URL, completion: ((_ success: Bool) -> Void)?) {
        performOnMain {
            guard let scheme = url.scheme, !scheme.isEmpty, !url.isFileURL else {
                completion?(false)
                return
            }
            UIApplication.shared.open(url, options: [:]) { success in
                completion?(success)
            }
        }
    }

    static func openSettings(completion: ((_ success: Bool) -> Void)?) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            performOnMain { completion?(false) }
            return
        }
        open(url: url, completion: completion)
    }

    static func requestInstallation(_ lpa: String, completion: ((_ result: WYEsimRequestResult) -> Void)?) {
        performOnMain {
            guard let url = installationURL(lpa) else {
                completion?(.invalidLpa)
                return
            }
            guard isEsimInstallationLinkAvailable else {
                completion?(.linkUnavailable)
                return
            }
            UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { success in
                completion?(success ? .requestAccepted : .requestRejected)
            }
        }
    }

    static func installLegacy(_ lpa: String, tip: String?, completion: ((_ success: Bool) -> Void)?) {
        requestEsimInstallation(lpa: lpa) { result in
            let success = result == .requestAccepted
            if !success { showUnsupportedTip(tip) }
            completion?(success)
        }
    }

    static func showUnsupportedTip(_ tip: String?) {
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.filter { $0.activationState == .foregroundActive }.flatMap { $0.windows }
        var presenter = windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = presenter?.presentedViewController {
            presenter = presented
        }
        guard let presenter, presenter.viewIfLoaded?.window != nil, !presenter.isBeingDismissed else { return }
        let alert = UIAlertController(title: tip ?? WYLocalized("无法打开 eSIM 安装入口", table: WYBasisKitConfig.kitLocalizableTable), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable), style: .default))
        presenter.present(alert, animated: true)
    }

    static func normalizedLpa(_ lpa: String) -> String? {
        let trimmed = lpa.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = trimmed.lowercased().hasPrefix("lpa:") ? String(trimmed.dropFirst(4)) : trimmed
        guard !body.isEmpty, !body.unicodeScalars.contains(where: { CharacterSet.whitespacesAndNewlines.union(.controlCharacters).contains($0) }) else { return nil }
        let fields = body.components(separatedBy: "$")
        guard fields.count >= 3, fields[0] == "1", !fields[1].isEmpty,
              fields[1].unicodeScalars.allSatisfy({ serverCharacters.contains($0) }),
              fields[1].split(separator: ".", omittingEmptySubsequences: false).allSatisfy({ !$0.isEmpty && $0.first != "-" && $0.last != "-" }) else { return nil }
        return "LPA:" + body
    }

    static func installationURL(_ lpa: String) -> URL? {
        guard let normalized = normalizedLpa(lpa), let carddata = normalized.addingPercentEncoding(withAllowedCharacters: fieldValueAllowed) else { return nil }
        return URL(string: "https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=\(carddata)")
    }

    static func makeQRCode(_ lpa: String, size: CGSize) -> UIImage? {
        guard let normalized = normalizedLpa(lpa), size.width.isFinite, size.height.isFinite,
              size.width > 0, size.height > 0, size.width <= maximumQRCodeDimension, size.height <= maximumQRCodeDimension,
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(normalized.utf8), forKey: "inputMessage")
        guard let output = filter.outputImage else { return nil }
        let extent = output.extent.integral
        guard !extent.isEmpty, !extent.isInfinite, !extent.isNull else { return nil }
        let scale = floor(min(size.width / extent.width, size.height / extent.height))
        guard scale >= 1 else { return nil }
        let image = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = CIContext().createCGImage(image, from: image.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    static func normalizedPhone(_ number: String) -> String? {
        guard !number.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return nil }
        let trimmed = number.filter { !$0.isWhitespace }
        guard !trimmed.isEmpty, trimmed.unicodeScalars.allSatisfy({ phoneCharacters.contains($0) }),
              trimmed.contains(where: { $0.isASCII && $0.isNumber }),
              !trimmed.dropFirst().contains("+") else { return nil }
        return trimmed
    }

    static func mailAddresses(_ addresses: [String]) -> String? {
        var valid: [String] = []
        for address in addresses {
            let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            let parts = trimmed.components(separatedBy: "@")
            guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty,
                  !trimmed.unicodeScalars.contains(where: { CharacterSet.whitespacesAndNewlines.union(.controlCharacters).contains($0) }),
                  trimmed.rangeOfCharacter(from: CharacterSet(charactersIn: ",;:<>\"/\\?&#")) == nil,
                  let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: fieldValueAllowed) else { return nil }
            valid.append(encoded)
        }
        return valid.joined(separator: ",")
    }

    static func mailURL(to: [String], cc: [String], bcc: [String], subject: String, body: String) -> URL? {
        guard let toPart = mailAddresses(to), !toPart.isEmpty, let ccPart = mailAddresses(cc), let bccPart = mailAddresses(bcc) else { return nil }
        var queryItems: [String] = []
        if !ccPart.isEmpty { queryItems.append("cc=\(ccPart)") }
        if !bccPart.isEmpty { queryItems.append("bcc=\(bccPart)") }
        if !subject.isEmpty, let value = subject.addingPercentEncoding(withAllowedCharacters: fieldValueAllowed) {
            queryItems.append("subject=\(value)")
        }
        if !body.isEmpty, let value = body.addingPercentEncoding(withAllowedCharacters: fieldValueAllowed) {
            queryItems.append("body=\(value)")
        }
        return URL(string: "mailto:\(toPart)" + (queryItems.isEmpty ? "" : "?" + queryItems.joined(separator: "&")))
    }

    static func openMail(to: [String], cc: [String], bcc: [String], subject: String, body: String, completion: ((_ success: Bool) -> Void)?) {
        guard let url = mailURL(to: to, cc: cc, bcc: bcc, subject: subject, body: body) else {
            performOnMain { completion?(false) }
            return
        }
        open(url: url, completion: completion)
    }

    static func smsURL(to: [String], body: String) -> URL? {
        var numbers: [String] = []
        for number in to {
            if number.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            guard let normalized = normalizedPhone(number) else { return nil }
            numbers.append(normalized)
        }
        guard !numbers.isEmpty else { return nil }
        var urlString = "sms:" + numbers.joined(separator: ",")
        if !body.isEmpty, let value = body.addingPercentEncoding(withAllowedCharacters: fieldValueAllowed) {
            urlString += "&body=\(value)"
        }
        return URL(string: urlString)
    }

    static func openSms(to: [String], body: String, completion: ((_ success: Bool) -> Void)?) {
        guard let url = smsURL(to: to, body: body) else {
            performOnMain { completion?(false) }
            return
        }
        open(url: url, completion: completion)
    }

    static func openPhone(_ number: String, completion: ((_ success: Bool) -> Void)?) {
        guard let number = normalizedPhone(number), let url = URL(string: "tel:\(number)") else {
            performOnMain { completion?(false) }
            return
        }
        open(url: url, completion: completion)
    }

    static func openStore(appId: String, action: String?, completion: ((_ success: Bool) -> Void)?) {
        let trimmed = appId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }), trimmed.contains(where: { $0 != "0" }),
              var components = URLComponents(string: "itms-apps://itunes.apple.com/app/id\(trimmed)") else {
            performOnMain { completion?(false) }
            return
        }
        if let action { components.queryItems = [URLQueryItem(name: "action", value: action)] }
        guard let url = components.url else {
            performOnMain { completion?(false) }
            return
        }
        open(url: url, completion: completion)
    }
}
