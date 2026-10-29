//
//  WYChatMoreView+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit

extension WYChatMoreView {
    
    /// 分页控制器设置选项
    internal var pageControlSetting: (currentColor: UIColor?, defaultColor: UIColor?, currentImage: UIImage?, defaultImage: UIImage?) {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.pageControlSetting, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.pageControlSetting) as? (currentColor: UIColor?, defaultColor: UIColor?, currentImage: UIImage?, defaultImage: UIImage?) ?? (currentColor: nil, defaultColor: nil, currentImage: nil, defaultImage: nil)
        }
    }
    
    /// 自定义设置分页控件图片及颜色
    internal func updatePageControlStyle() {
        
        if pageControl?.hidesForSinglePage != moreViewConfig.pageControlHideForSingle {
            pageControl?.hidesForSinglePage = moreViewConfig.pageControlHideForSingle
        }
        
        if let defaultColor: UIColor = pageControlSetting.defaultColor {
            pageControl?.pageIndicatorTintColor = defaultColor
            pageControlSetting.defaultColor = nil
        }
        if let currentColor: UIColor = pageControlSetting.currentColor {
            pageControl?.currentPageIndicatorTintColor = currentColor
            pageControlSetting.currentColor = nil
        }
        
        if let defaultImage: UIImage = pageControlSetting.defaultImage, let currentImage: UIImage = pageControlSetting.currentImage {
            for page: Int in 0..<(pageControl?.numberOfPages ?? 0) {
                pageControl?.setIndicatorImage(page == pageControl?.currentPage ? currentImage : defaultImage, forPage: page)
            }
        }else {
            if let defaultImage: UIImage = pageControlSetting.defaultImage {
                pageControl?.preferredIndicatorImage = defaultImage
                pageControlSetting.defaultImage = nil
            }
            
            if let currentImage: UIImage = pageControlSetting.currentImage {
                pageControl?.preferredIndicatorImage = currentImage
                pageControlSetting.currentImage = nil
            }
        }
    }
    
    internal struct WYAssociatedKeys {
        static var pageControl: UInt8 = 0
        static var pageControlSetting: UInt8 = 0
    }
}
