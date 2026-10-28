//
//  WYDevice+Foldable.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit

/// 当前窗口的系统铰链信息
@available(iOS 27.1, *)
final class WYDeviceFoldableContext {

    var hinge: UIHinge?
    var hasReceivedUpdate = false

    static var hasObservedFoldablePhone = false
    private static var associatedKey: UInt8 = 0

    private lazy var interaction = UIHingeInteraction { [weak self] _, update in
        guard let self = self else { return }
        self.hinge = update.hinge
        self.hasReceivedUpdate = true
        if UIDevice.current.userInterfaceIdiom == .phone, update.hinge != nil {
            Self.hasObservedFoldablePhone = true
        }
    }

    static func context(in window: UIWindow) -> WYDeviceFoldableContext? {
        guard window.windowScene != nil else { return nil }
        if let context = objc_getAssociatedObject(window, &associatedKey) as? WYDeviceFoldableContext {
            return context
        }
        let context = WYDeviceFoldableContext()
        objc_setAssociatedObject(window, &associatedKey, context, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        window.addInteraction(context.interaction)
        return context
    }

    static func state(for hinge: UIHinge?, hasReceivedUpdate: Bool) -> WYDeviceFoldableState {
        guard let hinge = hinge else { return hasReceivedUpdate ? .unavailable : .unknown }
        switch hinge.status {
        case .closed: return .closed
        case .partiallyOpen: return .partiallyOpen
        case .fullyOpen: return .fullyOpen
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }

    static func observe(in view: UIView, handler: @escaping (_ state: WYDeviceFoldableState) -> Void) -> UIHingeInteraction {
        let interaction = UIHingeInteraction { _, update in
            handler(state(for: update.hinge, hasReceivedUpdate: true))
        }
        view.addInteraction(interaction)
        return interaction
    }
}
