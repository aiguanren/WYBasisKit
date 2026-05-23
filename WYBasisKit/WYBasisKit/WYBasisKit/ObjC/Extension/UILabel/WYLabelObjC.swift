//
//  UILabel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/23.
//

import Foundation
import UIKit

@objc public extension UILabel {
    
    /// 内边距（上、左、下、右）
    @objc(wy_contentInsets)
    var wy_contentInsetsObjC: UIEdgeInsets {
        get { return wy_contentInsets }
        set { wy_contentInsets = newValue }
    }
}
