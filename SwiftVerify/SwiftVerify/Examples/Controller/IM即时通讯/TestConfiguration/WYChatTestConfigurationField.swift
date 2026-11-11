//
//  WYChatTestConfigurationField.swift
//  SwiftVerify
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 聊天配置测试页的字段读写
@MainActor
struct WYChatTestConfigurationField {
    enum Kind { case boolean, color, text, special }
    typealias Read = @MainActor (WYChatConfig) -> String
    typealias Apply = @MainActor (inout WYChatConfig, String) -> Bool
    typealias Reset = @MainActor (inout WYChatConfig) -> Void
    let path: String
    let title: String
    let type: String
    let kind: Kind
    let read: Read
    let apply: Apply?
    let reset: Reset
    var clear: Reset?
    var color: (@MainActor (WYChatConfig) -> UIColor?)?
    var setColor: (@MainActor (inout WYChatConfig, UIColor) -> Void)?
    var clearTitle = "设为空"
    var help = ""

    func contentOverride(_ style: WYChatMessageStyle, key: String) -> Self {
        let field = self
        @MainActor func proxy(_ config: WYChatConfig) -> WYChatConfig {
            var result = config
            result.content = config.contentOverrides[style] ?? config.content
            return result
        }
        let edit: Apply?
        if let operation = apply {
            edit = { config, text in
                var result = proxy(config)
                guard operation(&result, text) else { return false }
                config.contentOverrides[style] = result.content
                return true
            }
        } else { edit = nil }
        var result = Self(path: "contentOverrides." + key + "." + String(path.dropFirst("content.".count)), title: title, type: type, kind: kind, read: { field.read(proxy($0)) }, apply: edit, reset: { config in
            var value = proxy(config)
            field.reset(&value)
            config.contentOverrides[style] = value.content
        }, clear: { $0.contentOverrides.removeValue(forKey: style) }, clearTitle: "取消覆盖", help: help + "\n取消覆盖会移除此消息类型的全部覆盖，重新使用content")
        if let color { result.color = { color(proxy($0)) } }
        if let setColor {
            result.setColor = { config, color in
                var value = proxy(config)
                setColor(&value, color)
                config.contentOverrides[style] = value.content
            }
        }
        return result
    }

    static func boolean(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> Bool, set: @escaping @MainActor (inout WYChatConfig, Bool) -> Void) -> Self {
        Self(path: path, title: title, type: "Bool", kind: .boolean, read: { String(get($0)) }, apply: { config, text in guard let value = Bool(text) else { return false }; set(&config, value); return true }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) })
    }
    static func scalar(_ path: String, _ title: String, _ type: String, get: @escaping @MainActor (WYChatConfig) -> Double, set: @escaping @MainActor (inout WYChatConfig, Double) -> Void) -> Self {
        Self(path: path, title: title, type: type, kind: .text, read: { String(get($0)) }, apply: { config, text in guard let value = Double(text.trimmingCharacters(in: .whitespacesAndNewlines)), value.isFinite, type != "Float" || Float(value).isFinite else { return false }; set(&config, value); return true }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) })
    }
    static func integer(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> Int, set: @escaping @MainActor (inout WYChatConfig, Int) -> Void) -> Self {
        Self(path: path, title: title, type: "Int", kind: .text, read: { String(get($0)) }, apply: { config, text in guard let value = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }; set(&config, value); return true }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) })
    }
    static func string(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> String, set: @escaping @MainActor (inout WYChatConfig, String) -> Void) -> Self {
        Self(path: path, title: title, type: "String", kind: .text, read: get, apply: { config, text in set(&config, text); return true }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) })
    }
    static func optionalString(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> String?, set: @escaping @MainActor (inout WYChatConfig, String?) -> Void) -> Self {
        Self(path: path, title: title, type: "String?", kind: .text, read: { get($0) ?? "nil" }, apply: { config, text in set(&config, text == "nil" ? nil : text); return true }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, clear: { set(&$0, nil) }, help: "nil表示未设置")
    }

    static func vector(_ path: String, _ title: String, _ type: String, labels: [String], get: @escaping @MainActor (WYChatConfig) -> [Double], set: @escaping @MainActor (inout WYChatConfig, [Double]) -> Void) -> Self {
        Self(path: path, title: title, type: type, kind: .text, read: { get($0).map { String($0) }.joined(separator: ", ") }, apply: { config, text in
            let parts = text.replacingOccurrences(of: "，", with: ",").split(separator: ",", omittingEmptySubsequences: false).map { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            guard parts.count == labels.count, parts.allSatisfy({ $0?.isFinite == true }) else { return false }
            set(&config, parts.compactMap { $0 }); return true
        }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, help: labels.joined(separator: ", "))
    }
    static func color(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> UIColor?, set: @escaping @MainActor (inout WYChatConfig, UIColor) -> Void, clear: Reset? = nil) -> Self {
        Self(path: path, title: title, type: clear == nil ? "UIColor" : "UIColor?", kind: .color, read: { get($0).map(hex) ?? "nil" }, apply: { config, text in if text.trimmingCharacters(in: .whitespacesAndNewlines) == "nil", let clear { clear(&config); return true }; guard let value = parseColor(text) else { return false }; set(&config, value); return true }, reset: { config in if let value = get(WYChatTestConfigurationFields.defaults) { set(&config, value) } else { clear?(&config) } }, clear: clear, color: get, setColor: set, help: "#RRGGBB 或 #RRGGBBAA")
    }
    static func font(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> UIFont, set: @escaping @MainActor (inout WYChatConfig, UIFont) -> Void) -> Self {
        Self(path: path, title: title, type: "UIFont", kind: .text, read: { get($0).fontName + ", " + String(Double(get($0).pointSize)) }, apply: { config, text in
            let parts = text.split(separator: ",", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard let size = Double(parts.last ?? ""), size.isFinite, size > 0 else { return false }
            let original = get(config)
            let name = parts.count > 1 ? parts.dropLast().joined(separator: ",") : original.fontName
            guard let font = name == original.fontName ? original.withSize(CGFloat(size)) : UIFont(name: name, size: CGFloat(size)) else { return false }
            set(&config, font); return true
        }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, help: "字体名称, 字号，省略字体名称时保留当前字体")
    }
    static func image(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> UIImage?, set: @escaping @MainActor (inout WYChatConfig, UIImage) -> Void, clear: Reset? = nil) -> Self {
        Self(path: path, title: title, type: clear == nil ? "UIImage" : "UIImage?", kind: .text, read: { get($0).map { "UIImage \($0.size.width)×\($0.size.height)" } ?? "nil" }, apply: { config, text in
            let name = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let image = UIImage(systemName: name) ?? UIImage(named: name) ?? UIImage(contentsOfFile: name) else { return false }
            set(&config, image); return true
        }, reset: { config in if let image = get(WYChatTestConfigurationFields.defaults) { set(&config, image) } else { clear?(&config) } }, clear: clear, help: "输入SF Symbols名称、宿主资源名或本地图片路径")
    }
    static func raw<T: RawRepresentable>(_ path: String, _ title: String, options: String, allowed: [T.RawValue]? = nil, get: @escaping @MainActor (WYChatConfig) -> T, set: @escaping @MainActor (inout WYChatConfig, T) -> Void) -> Self where T.RawValue: FixedWidthInteger {
        Self(path: path, title: title, type: String(describing: T.self), kind: .text, read: { String(get($0).rawValue) }, apply: { config, text in guard let raw = T.RawValue(text.trimmingCharacters(in: .whitespacesAndNewlines), radix: 10), let value = T(rawValue: raw), allowed?.contains(raw) ?? true else { return false }; set(&config, value); return true }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, help: options)
    }
    static func numbers(_ path: String, _ title: String, _ type: String, get: @escaping @MainActor (WYChatConfig) -> [Double], set: @escaping @MainActor (inout WYChatConfig, [Double]) -> Void) -> Self {
        Self(path: path, title: title, type: type, kind: .text, read: { get($0).map { String($0) }.joined(separator: ", ") }, apply: { config, text in
            let values = text.split(whereSeparator: { $0 == "," || $0 == "\n" }).map { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            guard values.allSatisfy({ $0?.isFinite == true && (type != "[Float]" || Float($0!).isFinite) }) else { return false }
            set(&config, values.compactMap { $0 }); return true
        }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, help: "用逗号或换行分隔数值，空文本表示空数组")
    }
    static func rawArray<T: RawRepresentable>(_ path: String, _ title: String, options: String, get: @escaping @MainActor (WYChatConfig) -> [T], set: @escaping @MainActor (inout WYChatConfig, [T]) -> Void) -> Self where T.RawValue: FixedWidthInteger {
        Self(path: path, title: title, type: "[\(T.self)]", kind: .text, read: { get($0).map { String($0.rawValue) }.joined(separator: ", ") }, apply: { config, text in
            let parts = text.split(whereSeparator: { $0 == "," || $0 == "\n" })
            let values = parts.compactMap { T.RawValue($0.trimmingCharacters(in: .whitespacesAndNewlines), radix: 10) }.compactMap(T.init(rawValue:))
            guard parts.count == values.count else { return false }
            set(&config, values); return true
        }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, help: options)
    }
    static func json<T>(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> T, set: @escaping @MainActor (inout WYChatConfig, T) -> Void) -> Self {
        Self(path: path, title: title, type: String(describing: T.self), kind: .text, read: { config in guard let data = try? JSONSerialization.data(withJSONObject: get(config), options: [.prettyPrinted, .sortedKeys]), let value = String(data: data, encoding: .utf8) else { return "" }; return value }, apply: { config, text in guard let data = text.data(using: .utf8), let value = try? JSONSerialization.jsonObject(with: data) as? T else { return false }; set(&config, value); return true }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, help: "输入JSON，类型必须与当前字段一致")
    }
    static func colors(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> [UIColor], set: @escaping @MainActor (inout WYChatConfig, [UIColor]) -> Void) -> Self {
        Self(path: path, title: title, type: "[UIColor]", kind: .text, read: { get($0).map(hex).joined(separator: ", ") }, apply: { config, text in
            let parts = text.split(whereSeparator: { $0 == "," || $0 == "\n" })
            let values = parts.compactMap { parseColor(String($0)) }
            guard values.count == parts.count else { return false }
            set(&config, values); return true
        }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, help: "用逗号或换行分隔#RRGGBB或#RRGGBBAA，空文本表示空数组")
    }
    static func optionalPoint(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> CGPoint?, set: @escaping @MainActor (inout WYChatConfig, CGPoint?) -> Void) -> Self {
        Self(path: path, title: title, type: "CGPoint?", kind: .text, read: { get($0).map { String(Double($0.x)) + ", " + String(Double($0.y)) } ?? "nil" }, apply: { config, text in
            if text.trimmingCharacters(in: .whitespacesAndNewlines) == "nil" { set(&config, nil); return true }
            let parts = text.split(separator: ",", omittingEmptySubsequences: false).map { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            guard parts.count == 2, parts.allSatisfy({ $0?.isFinite == true }) else { return false }
            set(&config, CGPoint(x: CGFloat(parts[0]!), y: CGFloat(parts[1]!))); return true
        }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, clear: { set(&$0, nil) }, help: "x, y，nil表示使用自动位置")
    }
    static func directory(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> URL, set: @escaping @MainActor (inout WYChatConfig, URL) -> Void) -> Self {
        Self(path: path, title: title, type: "URL", kind: .text, read: { get($0).absoluteString }, apply: { config, text in
            let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return false }
            let url = URL(string: value).flatMap { $0.scheme == nil ? URL(fileURLWithPath: value) : $0 }
            guard let url, url.isFileURL else { return false }
            set(&config, url); return true
        }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, help: "输入本地目录路径或file URL")
    }
    static func sourceBundle(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> WYSourceBundle?, set: @escaping @MainActor (inout WYChatConfig, WYSourceBundle?) -> Void) -> Self {
        Self(path: path, title: title, type: "WYSourceBundle?", kind: .text, read: { get($0).map { ($0.targetClass.map(NSStringFromClass) ?? "") + "|" + $0.bundleName + "|" + $0.subdirectory } ?? "nil" }, apply: { config, text in
            if text == "nil" { set(&config, nil); return true }
            let parts = text.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard parts.count == 3 else { return false }
            let type: AnyClass? = parts[0].isEmpty ? nil : NSClassFromString(parts[0])
            guard parts[0].isEmpty || type != nil else { return false }
            set(&config, WYSourceBundle(targetClass: type, bundleName: parts[1], subdirectory: parts[2])); return true
        }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, clear: { set(&$0, nil) }, help: "类型名|Bundle名|子目录，各组成项可以留空，nil表示默认资源")
    }
    static func classes(_ path: String, _ title: String, get: @escaping @MainActor (WYChatConfig) -> [AnyClass], set: @escaping @MainActor (inout WYChatConfig, [AnyClass]) -> Void) -> Self {
        Self(path: path, title: title, type: "[AnyClass]", kind: .text, read: { get($0).map(NSStringFromClass).joined(separator: "\n") }, apply: { config, text in
            let names = text.split(whereSeparator: { $0 == "," || $0 == "\n" }).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            let values = names.compactMap(NSClassFromString)
            guard names.count == values.count, values.allSatisfy({ $0 is UITableViewCell.Type }) else { return false }
            set(&config, values); return true
        }, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, help: "每行一个UITableViewCell类型名，Swift类型包含模块名")
    }
    static func special<T>(_ path: String, _ title: String, _ type: String, related: String, get: @escaping @MainActor (WYChatConfig) -> T, set: @escaping @MainActor (inout WYChatConfig, T) -> Void) -> Self {
        Self(path: path, title: title, type: type, kind: .special, read: { String(describing: get($0)) }, apply: nil, reset: { config in set(&config, get(WYChatTestConfigurationFields.defaults)) }, help: related)
    }
    private static func hex(_ color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return color.description }
        return String(format: "#%02X%02X%02X%02X", Int((min(1, max(0, r)) * 255).rounded()), Int((min(1, max(0, g)) * 255).rounded()), Int((min(1, max(0, b)) * 255).rounded()), Int((min(1, max(0, a)) * 255).rounded()))
    }
    private static func parseColor(_ text: String) -> UIColor? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard [6, 8].contains(value.count), let raw = UInt64(value, radix: 16) else { return nil }
        let rgba = value.count == 6 ? (raw << 8) | 255 : raw
        return UIColor(red: CGFloat((rgba >> 24) & 255) / 255, green: CGFloat((rgba >> 16) & 255) / 255, blue: CGFloat((rgba >> 8) & 255) / 255, alpha: CGFloat(rgba & 255) / 255)
    }
}
