//
//  WYVideoPlayerMoreActionObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/23.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

/// 更多面板中的功能项目
@objc(WYVideoPlayerMoreAction)
@objcMembers public class WYVideoPlayerMoreActionObjC: NSObject {

    /// 功能类型
    public var kind: WYVideoPlayerMoreActionKind

    /// 功能标识，自定义功能可据此区分
    public var identifier: String = ""

    /// 显示名称，nil 使用功能类型的默认名称
    public var title: String?

    /// 功能图标，nil 使用功能类型的默认图标
    public var image: UIImage?

    /// 是否允许点击(默认 true)
    public var isEnabled = true

    /// 自定义项目是否显示为选中(默认 false)
    public var isSelected = false

    /// 点击回调，参数为播放器，设置后替代该项目的内置动作
    public var handler: ((_ player: WYVideoPlayer) -> Void)?

    /**
     *  创建更多功能项目
     *
     *  @param kind          功能类型
     *
     */
    public init(kind: WYVideoPlayerMoreActionKind) {
        self.kind = kind
        super.init()
    }

    /**
     *  转成更多功能项目
     *
     *  @return 更多功能项目
     *
     */
    public func toMoreAction() -> WYVideoPlayerMoreAction {
        return WYVideoPlayerMoreAction(kind: kind, identifier: identifier, title: title, image: image, isEnabled: isEnabled, isSelected: isSelected, handler: handler)
    }
}
#endif
