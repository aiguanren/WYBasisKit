//
//  UITabBar.swift
//  WYBasisKit
//
//  Created by guanren on 2025/8/25.
//

import UIKit

/// 徽章样式枚举
public enum WYBadgeStyle: Int {
    /// 不显示徽章值
    case none = 0
    
    /// 显示色(圆)点徽章值
    case colorDot = 1
    
    /// 显示数字徽章值
    case number = 2
}

public extension UITabBar {
    
    /// 设置徽章背景颜色(默认红色，仅限初始化时设置)
    var wy_badgeBackgroundColor: UIColor {
        get {
            if let color = objc_getAssociatedObject(self, &WYAssociatedKeys.badgeBackgroundColor) as? UIColor {
                return color
            }
            return UIColor.red
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.badgeBackgroundColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 设置徽章文本颜色(默认白色，仅限初始化时设置)
    var wy_badgeTextColor: UIColor {
        get {
            if let color = objc_getAssociatedObject(self, &WYAssociatedKeys.badgeTextColor) as? UIColor {
                return color
            }
            return UIColor.white
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.badgeTextColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 设置徽章显示风格
    func wy_tabBarBadgeStyle(_ badgeStyle: WYBadgeStyle, badgeValue: Int, tabBarIndex: Int) {
        // 确保徽章视图已初始化
        if !isBadgeViewInited {
            isBadgeViewInited = true
            wy_addBadgeViews()
        }
        
        // 检查索引是否有效
        guard tabBarIndex >= 0,
              tabBarIndex < badgeRedDotViews.count,
              tabBarIndex < badgeNumberViews.count else {
            return
        }
        
        let redDotViews = badgeRedDotViews
        let badgeNumberViews = badgeNumberViews

        redDotViews[tabBarIndex].isHidden = true
        badgeNumberViews[tabBarIndex].isHidden = true
        
        var style = badgeStyle
        if badgeValue == 0 {
            style = .none
        }
        
        switch style {
        case .colorDot:
            redDotViews[tabBarIndex].isHidden = false
            
        case .number:
            let label = badgeNumberViews[tabBarIndex] as! UILabel
            label.isHidden = false
            wy_adjustBadgeNumberView(with: label, number: badgeValue)
            
        case .none:
            break
        }
    }
}

private extension UITabBar {
    
    /// 添加徽章视图
    func wy_addBadgeViews() {
        guard let items = self.items, items.count > 0 else { return }
        
        let itemsCount = items.count
        let itemWidth = self.bounds.size.width / CGFloat(itemsCount)
        let tabBarIconTop: CGFloat = 10.0
        
        // 创建红点视图数组
        var redDotViews: [UIView] = []
        for i in 0..<itemsCount {
            let tabBarIconWidth = items[i].image?.size.width ?? 0
            
            let redDot = UIView()
            redDot.bounds = CGRect(x: 0, y: 0, width: 8, height: 8)
            redDot.center = CGPoint(x: itemWidth * (CGFloat(i) + 0.5) + tabBarIconWidth/2, y: tabBarIconTop)
            redDot.layer.cornerRadius = redDot.bounds.size.width / 2
            redDot.clipsToBounds = true
            redDot.backgroundColor = wy_badgeBackgroundColor
            redDot.isHidden = true
            
            self.addSubview(redDot)
            redDotViews.append(redDot)
        }
        self.badgeRedDotViews = redDotViews
        
        // 创建数字徽章视图数组
        var badgeNumberViews: [UIView] = []
        for i in 0..<itemsCount {
            let tabBarIconWidth = items[i].image?.size.width ?? 0
            
            let redNum = UILabel()
            redNum.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            redNum.bounds = CGRect(x: 0, y: 0, width: 16, height: 12)
            redNum.center = CGPoint(x: itemWidth * (CGFloat(i) + 0.5) + tabBarIconWidth/2 - 8, y: tabBarIconTop)
            redNum.layer.cornerRadius = redNum.bounds.size.height / 2
            redNum.clipsToBounds = true
            redNum.backgroundColor = wy_badgeBackgroundColor
            redNum.isHidden = true
            
            redNum.textAlignment = .center
            redNum.font = UIFont.systemFont(ofSize: 10)
            redNum.textColor = wy_badgeTextColor
            
            self.addSubview(redNum)
            badgeNumberViews.append(redNum)
        }
        self.badgeNumberViews = badgeNumberViews
    }
    
    /// 调整数字徽章视图
    func wy_adjustBadgeNumberView(with label: UILabel, number: Int) {
        label.text = number > 99 ? "99+" : "\(number)"
        
        if number < 10 {
            label.bounds = CGRect(x: 0, y: 0, width: 12, height: 12)
        } else if number < 99 {
            label.bounds = CGRect(x: 0, y: 0, width: 18, height: 12)
        } else {
            label.bounds = CGRect(x: 0, y: 0, width: 25, height: 12)
        }
        
        label.layer.cornerRadius = label.bounds.size.height / 2
    }
    
    var isBadgeViewInited: Bool {
        get {
            return (objc_getAssociatedObject(self, &WYAssociatedKeys.badgeViewInited) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.badgeViewInited, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var badgeRedDotViews: [UIView] {
        get {
            return (objc_getAssociatedObject(self, &WYAssociatedKeys.badgeRedDotViews) as? [UIView]) ?? []
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.badgeRedDotViews, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var badgeNumberViews: [UIView] {
        get {
            return (objc_getAssociatedObject(self, &WYAssociatedKeys.badgeNumberViews) as? [UIView]) ?? []
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.badgeNumberViews, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 关联对象键
    private struct WYAssociatedKeys {
        static var badgeBackgroundColor: UInt8 = 0
        static var badgeTextColor: UInt8 = 0
        static var badgeViewInited: UInt8 = 0
        static var badgeRedDotViews: UInt8 = 0
        static var badgeNumberViews: UInt8 = 0
    }
}
