//
//  WYChatDefaults+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 为布局和动画提供有效的非负配置值
func wy_chatNonnegative<T: FloatingPoint>(_ value: T) -> T {
    value.isFinite ? max(0, value) : 0
}

/// 共享只读默认资源
enum WYChatDefaultResources {
    static func iconTint(for name: String) -> UIColor? {
        switch name {
        case "WYChatViewRedPacket": return .systemRed
        case "WYChatViewTransfer": return UIColor { $0.userInterfaceStyle == .dark ? .wy_hex("#FFC47E") : .wy_hex("#A45516") }
        case "WYChatViewMusic": return .systemIndigo
        default: return nil
        }
    }
    static let placeholderColor = UIColor(white: 0.88, alpha: 1)
    static let solidPlaceholder = UIImage.wy_createImage(from: placeholderColor)
    static let recordActionBackground = UIImage.wy_createImage(from: .wy_rgb(57, 57, 57), size: CGSize(width: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels))).wy_cuttingRound()
    static let recordActionSelectedBackground = UIImage.wy_createImage(from: .wy_rgb(236, 236, 236), size: CGSize(width: UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels))).wy_cuttingRound()
    static let emojis: [String] = ((try? NSArray(contentsOf: URL(fileURLWithPath: emojiPath), error: ())) as? [String]) ?? []

    static func makePlaceholder(color: UIColor, gradientColors: [UIColor], direction: WYGradientDirection, traits: UITraitCollection) -> UIImage {
        let colors = gradientColors.map { $0.resolvedColor(with: traits).cgColor }
        guard colors.count >= 2,
              let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil) else {
            return color === placeholderColor ? solidPlaceholder : UIImage.wy_createImage(from: color.resolvedColor(with: traits))
        }
        let size = CGSize(width: 64, height: 64)
        let start: CGPoint
        let end: CGPoint
        switch direction {
        case .leftToRight: (start, end) = (.zero, CGPoint(x: size.width, y: 0))
        case .topToBottom: (start, end) = (.zero, CGPoint(x: 0, y: size.height))
        case .leftToLowRight: (start, end) = (.zero, CGPoint(x: size.width, y: size.height))
        case .rightToLowLeft: (start, end) = (CGPoint(x: size.width, y: 0), CGPoint(x: 0, y: size.height))
        }
        return UIGraphicsImageRenderer(size: size).image { context in
            context.cgContext.drawLinearGradient(gradient, start: start, end: end, options: [])
        }
    }
}
