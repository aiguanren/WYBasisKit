//
//  WYPhotoBrowserMenuView.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//

import UIKit

/// 长按菜单浮层(深色圆角竖排动作列表，出现在长按点附近，点动作项回调选择)
class WYPhotoBrowserMenuView: UIView {

    /// 外观配置(底色、文字色、字号、高亮色与圆角)
    let appearance: WYPhotoBrowserAppearance

    /// 动作列表(与按钮一一对应)
    var actions: [WYPhotoBrowserAction] = []

    /// 动作按钮列表(重建动作时清空重排)
    var actionButtons: [UIButton] = []

    /// 动作选择回调(参数为被点的动作)
    var selectHandler: ((WYPhotoBrowserAction) -> Void)?

    /**
     * 菜单初始化
     *   @param appearance 外观配置
     */
    init(appearance: WYPhotoBrowserAppearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        backgroundColor = appearance.menuBackgroundColor
        layer.cornerRadius = UIDevice.wy_screenWidth(appearance.menuCornerRadius, WYBasisKitConfig.defaultScreenPixels)
        layer.masksToBounds = true
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     * 显示菜单(动作列表按顺序竖排，浮层优先落在长按点上方，放不下落下方)
     *   @param actions 动作列表
     *   @param anchorPoint 长按点(父视图坐标)
     *   @param parentView 父视图
     *   @param handler 动作选择回调
     */
    func show(actions: [WYPhotoBrowserAction], anchorPoint: CGPoint, in parentView: UIView, handler: @escaping (WYPhotoBrowserAction) -> Void) {
        self.actions = actions
        selectHandler = handler

        actionButtons.forEach { $0.removeFromSuperview() }
        actionButtons.removeAll()

        let menuFont = UIFont.systemFont(ofSize: UIFont.wy_fontSize(appearance.menuFontSize, WYBasisKitConfig.defaultScreenPixels))
        let rowHeight = UIDevice.wy_screenHeight(44, WYBasisKitConfig.defaultScreenPixels)
        let horizontalPadding = UIDevice.wy_screenWidth(18, WYBasisKitConfig.defaultScreenPixels)
        let iconSpacing = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels)

        var menuWidth: CGFloat = 0
        for (actionIndex, action) in actions.enumerated() {
            let button = UIButton(type: .system)
            button.tag = actionIndex
            button.wy_nTitle = action.title
            button.wy_title_nColor = appearance.menuTextColor
            button.wy_titleFont = menuFont
            if let icon = action.icon {
                button.wy_nImage = icon
                button.wy_adjust(position: .imageLeftTitleRight, spacing: iconSpacing)
            }
            button.wy_backgroundColor(UIColor.clear, forState: .normal)
            button.wy_backgroundColor(appearance.menuHighlightBackgroundColor, forState: .highlighted)
            button.wy_contentInsets(UIEdgeInsets(top: 0, left: horizontalPadding, bottom: 0, right: horizontalPadding))
            button.clipsToBounds = true
            button.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside)
            addSubview(button)
            actionButtons.append(button)

            button.sizeToFit()
            let rowWidth = button.bounds.width + horizontalPadding * 2
            menuWidth = max(menuWidth, rowWidth)
        }

        let maxMenuWidth = parentView.bounds.width - UIDevice.wy_screenWidth(32, WYBasisKitConfig.defaultScreenPixels)
        menuWidth = min(menuWidth, maxMenuWidth)
        let menuHeight = rowHeight * CGFloat(actions.count)
        frame = CGRect(x: 0, y: 0, width: menuWidth, height: menuHeight)

        for (rowIndex, button) in actionButtons.enumerated() {
            button.frame = CGRect(x: 0, y: CGFloat(rowIndex) * rowHeight, width: menuWidth, height: rowHeight)
        }

        let margin = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels)
        let centerX = max(menuWidth / 2 + margin, min(anchorPoint.x, parentView.bounds.width - menuWidth / 2 - margin))
        let aboveOriginY = anchorPoint.y - margin - menuHeight
        let topBound = parentView.safeAreaInsets.top + margin
        let originY = aboveOriginY >= topBound ? aboveOriginY : min(anchorPoint.y + margin, parentView.bounds.height - menuHeight - margin)
        center = CGPoint(x: centerX, y: originY + menuHeight / 2)

        alpha = 0
        transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    /// 动作按钮点击(回调选择并交给浏览器收起)
    @objc func actionTapped(_ button: UIButton) {
        guard actionButtons.indices.contains(button.tag) else { return }
        selectHandler?(actions[button.tag])
    }
}
