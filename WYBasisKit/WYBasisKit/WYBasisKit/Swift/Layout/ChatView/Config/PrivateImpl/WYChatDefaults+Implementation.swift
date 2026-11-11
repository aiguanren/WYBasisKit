//
//  WYChatDefaults+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 共享只读默认资源
enum WYChatDefaultResources {
    static let recordActionBackground = UIImage.wy_createImage(from: .wy_rgb(57, 57, 57), size: CGSize(width: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels))).wy_cuttingRound()
    static let recordActionSelectedBackground = UIImage.wy_createImage(from: .wy_rgb(236, 236, 236), size: CGSize(width: UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels))).wy_cuttingRound()
    static let emojis: [String] = ((try? NSArray(contentsOf: URL(fileURLWithPath: emojiPath), error: ())) as? [String]) ?? []
}
