//
//  WYButton+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit

extension UIButton {
    
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
            guard imageRect != nil || titleRect != nil else { return }
            
            // 强制 layout 前先 sizeToFit 避免 size 0
            button.titleLabel?.sizeToFit()
            button.imageView?.sizeToFit()
            
            if let imageView = button.imageView {
                if let frame = imageRect {
                    imageView.frame = frame
                }
            }
            
            if let titleLabel = button.titleLabel {
                if let frame = titleRect {
                    titleLabel.frame = frame
                }
            }
        })
    }()
    
    /***** 利用运行时自由设置UIButton的titleLabel和imageView的显示位置 *****/
    
    struct WYAssociatedKeys {
        static var intervalSelector: UInt8 = 0
        static var selectorInterval: UInt8 = 0
        static var positionKey: UInt8 = 0
        static var spacingKey: UInt8 = 0
        static var imageViewSizeKey: UInt8 = 0
        static var titleLabelSizeKey: UInt8 = 0
        static var wy_imageRect: UInt8 = 0
        static var wy_titleRect: UInt8 = 0
    }
}
