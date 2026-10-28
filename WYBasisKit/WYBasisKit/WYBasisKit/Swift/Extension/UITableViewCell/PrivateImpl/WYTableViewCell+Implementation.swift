//
//  WYTableViewCell+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit

final class WYTableViewCellPanGestureRecognizer: UIPanGestureRecognizer {

    var navigationGestureShouldWait: ((_ gestureRecognizer: UIGestureRecognizer) -> Bool)?

    override func shouldBeRequiredToFail(by otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationGestureShouldWait?(otherGestureRecognizer) == true || super.shouldBeRequiredToFail(by: otherGestureRecognizer)
    }
}

extension UITableViewCell {

    func wy_navigationGestureShouldWait(_ otherGestureRecognizer: UIGestureRecognizer, navigationController: UINavigationController?) -> Bool {
        guard let navigationController = navigationController else {
            return false
        }
        if #available(iOS 26.0, *), otherGestureRecognizer == navigationController.interactiveContentPopGestureRecognizer {
            return true
        }
        return otherGestureRecognizer == navigationController.interactivePopGestureRecognizer
    }
}
