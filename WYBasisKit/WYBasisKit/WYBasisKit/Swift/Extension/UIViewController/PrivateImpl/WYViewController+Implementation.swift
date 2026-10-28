//
//  WYViewController+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit

extension UIViewController {

    func wy_sharedControllerName(className: String) -> String {
        return WYProjectInfo.isSwiftProject ? (WYProjectInfo.projectName + "." + className) : className
    }
}
