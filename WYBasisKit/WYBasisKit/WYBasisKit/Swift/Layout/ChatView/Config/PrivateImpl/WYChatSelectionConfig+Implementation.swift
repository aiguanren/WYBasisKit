//
//  WYChatSelectionConfig+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatSelectionConfig {
    static let defaultSelectedImage = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)

    static let defaultUnselectedImage = UIImage(systemName: "circle", withConfiguration: UIImage.SymbolConfiguration(weight: .light))?.withRenderingMode(.alwaysTemplate)
}
