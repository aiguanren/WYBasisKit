//
//  WYButton+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit

public typealias WYIntervalSelector = ((_ button: UIButton) -> Void)

extension UIButton {
    enum WYImageLayout {
        case fillBounds(contentMode: UIView.ContentMode)
        case centered(maximumSide: CGFloat)
    }

    /// 根据按钮当前尺寸和图片更新图标位置。
    var wy_imageLayout: WYImageLayout? {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_imageLayout, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            UIButton.swizzleLayoutSubviews()
            setNeedsLayout()
        }
        get {
            objc_getAssociatedObject(self, &WYAssociatedKeys.wy_imageLayout) as? WYImageLayout
        }
    }

    
    var intervalSelector: WYIntervalSelector? {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.intervalSelector, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.intervalSelector) as? WYIntervalSelector
        }
    }
    
    var selectorInterval: TimeInterval {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.selectorInterval, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.selectorInterval) as? TimeInterval ?? 0
        }
    }
    
    @objc func buttonDelayHandler(_ button: UIButton) {
        intervalSelector?(button)
        isUserInteractionEnabled = false
        let interval = selectorInterval
        Task { [weak self] in
            try? await Task.wy_delay(interval, cancelThrows: false, onMain: { [weak self] in
                self?.isUserInteractionEnabled = true
            })
        }
    }
    
    /***** 利用运行时自由设置UIButton的titleLabel和imageView的显示位置 *****/
    static func swizzleLayoutSubviews() {
        _ = self.wy_swizzleLayoutSubviewsOnce
    }
    
    // 方法交换
    private static let wy_swizzleLayoutSubviewsOnce: Void = {
        
        wy_swizzlerLayoutSubviews(for: UIButton.self, after: { currentView in
            
            guard let button = currentView as? UIButton else { return }
            let imageRect = button.wy_imageRect
            let titleRect = button.wy_titleRect

            if imageRect != nil || titleRect != nil {
                button.titleLabel?.sizeToFit()
                button.imageView?.sizeToFit()
            }

            if let imageRect {
                button.imageView?.frame = imageRect
            } else if let layout = button.wy_imageLayout {
                button.wy_applyImageLayout(layout)
            }

            if let titleRect {
                button.titleLabel?.frame = titleRect
            }
        })
    }()
    
    /***** 利用运行时自由设置UIButton的titleLabel和imageView的显示位置 *****/
    
    private func wy_applyImageLayout(_ layout: WYImageLayout) {
        guard let imageView else { return }

        switch layout {
        case let .fillBounds(contentMode):
            imageView.contentMode = contentMode
            imageView.frame = bounds
        case let .centered(maximumSide):
            guard let image = currentImage, image.size.width > 0, image.size.height > 0,
                  currentTitle?.isEmpty != false else { return }

            let insets = configuration?.contentInsets ?? .zero
            let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
            let contentRect = bounds.inset(by: UIEdgeInsets(
                top: insets.top,
                left: isRightToLeft ? insets.trailing : insets.leading,
                bottom: insets.bottom,
                right: isRightToLeft ? insets.leading : insets.trailing
            ))
            let limit = max(0, min(maximumSide, contentRect.width, contentRect.height))
            let scale = limit / max(image.size.width, image.size.height)
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: contentRect.midX - size.width / 2, y: contentRect.midY - size.height / 2,
                                     width: size.width, height: size.height)
        }
    }

    struct WYAssociatedKeys {
        static var intervalSelector: UInt8 = 0
        static var selectorInterval: UInt8 = 0
        static var positionKey: UInt8 = 0
        static var spacingKey: UInt8 = 0
        static var imageViewSizeKey: UInt8 = 0
        static var titleLabelSizeKey: UInt8 = 0
        static var wy_imageLayout: UInt8 = 0
        static var wy_imageRect: UInt8 = 0
        static var wy_titleRect: UInt8 = 0
    }
}
