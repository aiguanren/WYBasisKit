//
//  WYChatAvatarGestures.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

final class WYChatAvatarImageView: UIImageView {
    override var alignmentRectInsets: UIEdgeInsets { .zero }
}

/// 头像单击、双击与长按操作
final class WYChatAvatarGestures: NSObject, UIGestureRecognizerDelegate {
    private weak var view: UIView?
    private let tap = UITapGestureRecognizer()
    private let doubleTap = UITapGestureRecognizer()
    private let longPress = UILongPressGestureRecognizer()
    private var configuration = WYBasicChatConfig()
    private let action: (WYChatAvatarAction) -> Void

    init(view: UIView, action: @escaping (WYChatAvatarAction) -> Void) {
        self.action = action
        self.view = view
        super.init()
        view.isUserInteractionEnabled = true
        tap.addTarget(self, action: #selector(tapped))
        doubleTap.addTarget(self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        longPress.addTarget(self, action: #selector(held(_:)))
        tap.require(toFail: doubleTap)
        for gesture in [tap, doubleTap, longPress] { gesture.delegate = self; view.addGestureRecognizer(gesture) }
    }
    func apply(_ configuration: WYBasicChatConfig) {
        self.configuration = configuration
        tap.isEnabled = configuration.avatarTapAction != .none
        doubleTap.isEnabled = configuration.avatarDoubleTapAction != .none
        longPress.isEnabled = configuration.avatarLongPressAction != .none
        longPress.minimumPressDuration = configuration.avatarLongPressDuration.isFinite ? max(0, configuration.avatarLongPressDuration) : WYBasicChatConfig().avatarLongPressDuration
    }
    private func perform(_ requested: WYChatAvatarAction) {
        if requested == .takePat, configuration.avatarPatAnimationDuration.isFinite, configuration.avatarPatAnimationDuration > 0 {
            let angles = configuration.avatarPatAnimationAngles.filter(\.isFinite)
            if angles.count > 1 {
                let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
                animation.values = angles.map { NSNumber(value: Double($0)) }
                animation.duration = configuration.avatarPatAnimationDuration
                view?.layer.add(animation, forKey: String(describing: Self.self))
            }
        }
        action(requested)
    }
    @objc private func tapped() { perform(configuration.avatarTapAction) }
    @objc private func doubleTapped() { perform(configuration.avatarDoubleTapAction) }
    @objc private func held(_ gesture: UILongPressGestureRecognizer) { if gesture.state == .began { perform(configuration.avatarLongPressAction) } }
}

extension WYChatBasicCell {
    func wy_avatarAction(_ action: WYChatAvatarAction) {
        let requested: WYChatAction
        switch action {
        case .none: return
        case .profile: requested = .avatar
        case .mention: requested = .mention
        case .takePat: requested = .takePat
        }
        actionHandler?(requested, message.messageID)
    }
}
