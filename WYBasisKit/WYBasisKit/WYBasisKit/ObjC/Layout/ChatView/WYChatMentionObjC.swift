//
//  WYChatMentionObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

#if canImport(WYBasisKitSwift)
import Foundation
import WYBasisKitSwift

/// 文本中提及的用户及其位置
@objc(WYChatMention)
@objcMembers public class WYChatMentionObjC: NSObject {
    /// 被提及的用户
    public var user: WYChatUserModelObjC
    /// 显示的提及文本，包含前缀
    public var text: String
    /// 提及文本在消息中的UTF16范围，不包含分隔文本
    public var range: NSRange
    public override convenience init() { self.init(WYChatMention(user: WYChatUserModel(), text: "", range: NSRange(location: 0, length: 0))) }
    @nonobjc public init(_ value: WYChatMention) { user = WYChatUserModelObjC(value.user); text = value.text; range = value.range; super.init() }
    @nonobjc public func toValue() -> WYChatMention { WYChatMention(user: user.toValue(), text: text, range: range) }
}
#endif
