//
//  WYChatTestConfigurationChecks.swift
//  SwiftVerify
//
//  Created by guanren on 2026/11/11.
//

import UIKit

/// 配置目录与编辑输入的实际读写检查
@MainActor
enum WYChatTestConfigurationChecks {
    static func run() -> [WYChatTestResult] {
        let fields = WYChatTestConfigurationFields.all
        let defaults = WYChatTestConfigurationFields.defaults
        var results: [WYChatTestResult] = []
        func check(_ name: String, _ passed: Bool, _ detail: String = "") { results.append(WYChatTestResult(name: name, passed: passed, detail: detail, milliseconds: 0)) }
        @MainActor func paths(_ value: Any, prefix: String) -> [String] {
            let name = String(describing: type(of: value))
            guard WYChatTestConfigurationFields.expandedTypes.contains(name) else { return [String(prefix.dropLast())] }
            return Mirror(reflecting: value).children.flatMap { child -> [String] in
                guard let label = child.label else { return [] }
                return paths(child.value, prefix: prefix + label + ".")
            }
        }
        let runtime = Set(paths(defaults, prefix: ""))
        let declared = Set(WYChatTestConfigurationFields.rootPaths)
        check("configuration-source-directory", runtime == declared, "missing=\(runtime.subtracting(declared).sorted()), extra=\(declared.subtracting(runtime).sorted())")
        check("configuration-unique-paths", Set(fields.map(\.path)).count == fields.count)
        check("configuration-composite-expansion", declared.allSatisfy { path in fields.contains { $0.path == path || $0.path.hasPrefix(path + ".") } })
        for field in fields {
            let original = field.read(defaults)
            var config = defaults
            if let apply = field.apply {
                let image = field.type.hasPrefix("UIImage")
                let value = image ? "photo" : original
                let accepted = apply(&config, value)
                check("configuration-edit-" + field.path, accepted && (image || field.read(config) == original), "type=\(field.type), input=\(value), output=\(field.read(config))")
                field.reset(&config)
                check("configuration-default-" + field.path, field.read(config) == original)
                if field.kind != .special && field.type != "String" && field.type != "String?" && !image {
                    let before = field.read(config)
                    let invalid = field.type == "URL" ? "https://example.com/not-a-local-directory" : "__invalid_configuration_value__"
                    let accepted = apply(&config, invalid)
                    check("configuration-invalid-" + field.path, !accepted && field.read(config) == before)
                }
            } else {
                field.reset(&config)
                check("configuration-special-default-" + field.path, field.read(config) == original && !field.help.isEmpty)
            }
            if let clear = field.clear {
                clear(&config)
                field.reset(&config)
                check("configuration-clear-default-" + field.path, field.read(config) == original)
            }
        }
        let content = fields.filter { $0.path.hasPrefix("content.") }
        for style in WYChatMessageStyle.allCases {
            for field in content {
                let wrapped = field.contentOverride(style, key: String(style.rawValue))
                var config = defaults
                let input = field.type.hasPrefix("UIImage") ? "photo" : field.read(defaults)
                let accepted = wrapped.apply?(&config, input) == true
                check("configuration-override-edit-\(style.rawValue)-" + field.path, accepted && config.contentOverrides[style] != nil)
                check("configuration-override-base-\(style.rawValue)-" + field.path, field.read(config) == field.read(defaults))
                wrapped.clear?(&config)
                check("configuration-override-clear-\(style.rawValue)-" + field.path, config.contentOverrides[style] == nil)
            }
        }
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 300))
        let avatarCell = WYChatTextCell(style: .default, reuseIdentifier: nil)
        host.addSubview(avatarCell)
        for symbol in ["person.crop.square", "person.crop.circle", "person.fill"] {
            for size in [CGSize(width: 38, height: 38), CGSize(width: 40, height: 60)] {
                var config = defaults
                config.basic.avatarSize = size
                config.basic.defaultAvatar = UIImage(systemName: symbol)
                avatarCell.frame = host.bounds
                avatarCell.update(message: WYChatMessageModel(messageID: "avatar-size", sender: WYChatUserModel(id: "avatar-size-user"), content: WYChatMessageContentModel(text: "头像尺寸")), configuration: config, userID: "avatar-size-user")
                let measured = avatarCell.systemLayoutSizeFitting(CGSize(width: 393, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
                avatarCell.frame.size.height = measured.height
                avatarCell.layoutIfNeeded()
                check("configuration-avatar-physical-\(symbol)-\(size.width)-\(size.height)", abs(avatarCell.avatarView.bounds.width - size.width) < 0.5 && abs(avatarCell.avatarView.bounds.height - size.height) < 0.5, "actual=\(avatarCell.avatarView.bounds), imageInsets=\(String(describing: config.basic.defaultAvatar?.alignmentRectInsets))")
            }
        }
        return results
    }
}
