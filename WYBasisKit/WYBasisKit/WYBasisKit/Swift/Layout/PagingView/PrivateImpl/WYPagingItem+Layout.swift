//
//  WYPagingItem+Layout.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/10.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYPagingItem 内容布局构建，图文混排/仅图片/仅文本三种模式的内容创建与排布(setupContentLayout)、选中状态切换后按当前字号重新测量内容尺寸(updateTextContentSize)
extension WYPagingItem {

    /**
     * 创建内容布局并返回最终内边距(智能边距计算/图文排布/内容尺寸下限约束)
     *
     * @param insideMargins 外部传入的按钮内边距(.zero时内部智能计算)
     * @param itemWidth 外部指定的Item固定宽度(0表示自适应)
     * @param itemHeight 外部指定的Item固定高度(0表示自适应)
     * @return 最终生效的按钮内边距(由初始化方法存入insideMargins)
     */
    @discardableResult
    func setupContentLayout(insideMargins: UIEdgeInsets, itemWidth: CGFloat, itemHeight: CGFloat) -> UIEdgeInsets {

        // 存储的字体是可选值，这里兜底成非可选供布局计算使用(公开初始化方法传入的字体恒非空，兜底值不会真正生效)
        let normalTextFont = self.normalTextFont ?? .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))

        // ==================== 智能计算 insideMargins ====================
        var finalMargins = insideMargins

        // 只有用户没有主动设置 insideMargins 时才自动计算
        if insideMargins == .zero {
            let iconSize = (contentImageViewSize == .zero ? normalImage?.size : contentImageViewSize) ?? .zero
            let textSize = (normalText as NSString?)?.size(withAttributes: [.font: normalTextFont]) ?? .zero

            // 防设边框后内容被压扁(Item高度被分页栏固定，边框宽度再叠加进自动边距会把内容盒挤得比内容本身小，文字被裁上下边、图片被缩小):自动边距先扣掉四周边框占位再分配剩余空间，边框宽度只作为最外圈内边距
            let borderInset: CGFloat = (borderWidth > 0) ? borderWidth : 0

            switch contentPosition {
            case .imageTopTitleBottom, .imageBottomTitleTop:
                // 竖向布局
                if itemHeight > 0 {
                    let contentHeight = iconSize.height + contentDividingOffset + textSize.height
                    let remaining = max(0, itemHeight - borderInset * 2 - contentHeight)
                    finalMargins.top = borderInset + remaining / 2
                    finalMargins.bottom = borderInset + remaining / 2
                }
                // 水平方向：如果有固定宽度则居中，否则不加额外左右边距（让内容自然显示）
                if itemWidth > 0 {
                    let contentWidth = iconSize.width + contentDividingOffset + textSize.width
                    let remaining = max(0, itemWidth - borderInset * 2 - contentWidth)
                    finalMargins.left = borderInset + remaining / 2
                    finalMargins.right = borderInset + remaining / 2
                }

            case .imageLeftTitleRight, .imageRightTitleLeft:
                // 横向布局
                if itemWidth > 0 {
                    let contentWidth = iconSize.width + contentDividingOffset + textSize.width
                    let remaining = max(0, itemWidth - borderInset * 2 - contentWidth)
                    finalMargins.left = borderInset + remaining / 2
                    finalMargins.right = borderInset + remaining / 2
                }
                // 垂直方向：如果有固定高度则居中，否则不加额外上下边距
                if itemHeight > 0 {
                    let contentHeight = max(iconSize.height, textSize.height)
                    let remaining = max(0, itemHeight - borderInset * 2 - contentHeight)
                    finalMargins.top = borderInset + remaining / 2
                    finalMargins.bottom = borderInset + remaining / 2
                }
            }

            // 防自适应方向上内容压到边框线上:未传Item宽/高的方向没有剩余空间可分，边框占位仍然要单独保留
            if borderInset > 0 {
                if itemWidth <= 0 {
                    finalMargins.left = borderInset
                    finalMargins.right = borderInset
                }
                if itemHeight <= 0 {
                    finalMargins.top = borderInset
                    finalMargins.bottom = borderInset
                }
            }
        }

        // ==================== 创建内容视图 ====================
        let contentView = UIView()
        contentView.backgroundColor = .clear
        contentView.isUserInteractionEnabled = false
        addSubview(contentView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: finalMargins.top),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -finalMargins.bottom),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: finalMargins.left),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -finalMargins.right)
        ])

        // ==================== 图文混排 ====================
        if let normalImage = normalImage, let _ = selectedImage,
           let normalText = normalText, let _ = selectedText {

            let icon = UIImageView(image: normalImage)
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.contentMode = .scaleAspectFit
            contentView.addSubview(icon)
            self.iconView = icon

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = normalText
            label.textColor = normalTextColor
            label.font = normalTextFont
            label.textAlignment = .center
            contentView.addSubview(label)
            self.textView = label

            let iconSize = (contentImageViewSize == .zero) ? normalImage.size : contentImageViewSize
            let textSize = (normalText as NSString).size(withAttributes: [.font: normalTextFont])

            switch contentPosition {
            case .imageLeftTitleRight:
                let totalWidth = iconSize.width + contentDividingOffset + textSize.width
                NSLayoutConstraint.activate([
                    icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                    icon.widthAnchor.constraint(equalToConstant: iconSize.width),
                    icon.heightAnchor.constraint(equalToConstant: iconSize.height),
                    label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: contentDividingOffset),
                    label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                    // 防文本无右边界时宽度不足不触发换行或缩字(直接画出Item外):给文本补右边界
                    label.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
                ])
                // 宽度下限用可更新约束(选中/未选中字体不同时随状态重算，见updateTextContentSize)
                textContentWidthConstraint = contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: totalWidth)
                // 防宽度下限与固定Item宽度的必需约束冲突(固定宽度小于文本宽时被随机打断后内容溢出Item):下限降为999让位固定宽度，宽度不足时按缩字或换行处理
                textContentWidthConstraint?.priority = .init(999)
                textContentWidthConstraint?.isActive = true

            case .imageRightTitleLeft:
                let totalWidth = iconSize.width + contentDividingOffset + textSize.width
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                    icon.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: contentDividingOffset),
                    icon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                    icon.widthAnchor.constraint(equalToConstant: iconSize.width),
                    icon.heightAnchor.constraint(equalToConstant: iconSize.height)
                ])
                textContentWidthConstraint = contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: totalWidth)
                // 防宽度下限与固定Item宽度的必需约束冲突(固定宽度小于文本宽时被随机打断后内容溢出Item):下限降为999让位固定宽度，宽度不足时按缩字或换行处理
                textContentWidthConstraint?.priority = .init(999)
                textContentWidthConstraint?.isActive = true

            case .imageTopTitleBottom:
                let maxWidth = max(iconSize.width, textSize.width)
                let totalHeight = iconSize.height + contentDividingOffset + textSize.height
                NSLayoutConstraint.activate([
                    icon.topAnchor.constraint(equalTo: contentView.topAnchor),
                    icon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    icon.widthAnchor.constraint(equalToConstant: iconSize.width),
                    icon.heightAnchor.constraint(equalToConstant: iconSize.height),
                    label.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: contentDividingOffset),
                    label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    // 防文本无左右边界时宽度不足不触发换行或缩字(直接画出Item外):给文本补左右边界，配合centerX保持换行后居中
                    label.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
                    label.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
                ])
                textContentWidthConstraint = contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: maxWidth)
                // 防宽度下限与固定Item宽度的必需约束冲突(固定宽度小于文本宽时被随机打断后内容溢出Item):下限降为999让位固定宽度，宽度不足时按缩字或换行处理
                textContentWidthConstraint?.priority = .init(999)
                textContentWidthConstraint?.isActive = true
                textContentHeightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: totalHeight)
                // 防止顶部偏移后内容高度下限把item底部挤出分页栏，降为998给底部边界约束让路
                textContentHeightConstraint?.priority = .init(998)
                textContentHeightConstraint?.isActive = true

            case .imageBottomTitleTop:
                let maxWidth = max(iconSize.width, textSize.width)
                let totalHeight = iconSize.height + contentDividingOffset + textSize.height
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: contentView.topAnchor),
                    label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    icon.topAnchor.constraint(equalTo: label.bottomAnchor, constant: contentDividingOffset),
                    icon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    icon.widthAnchor.constraint(equalToConstant: iconSize.width),
                    icon.heightAnchor.constraint(equalToConstant: iconSize.height),
                    // 防文本无左右边界时宽度不足不触发换行或缩字(直接画出Item外):给文本补左右边界，配合centerX保持换行后居中
                    label.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
                    label.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
                ])
                textContentWidthConstraint = contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: maxWidth)
                // 防宽度下限与固定Item宽度的必需约束冲突(固定宽度小于文本宽时被随机打断后内容溢出Item):下限降为999让位固定宽度，宽度不足时按缩字或换行处理
                textContentWidthConstraint?.priority = .init(999)
                textContentWidthConstraint?.isActive = true
                textContentHeightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: totalHeight)
                // 防止顶部偏移后内容高度下限把item底部挤出分页栏，降为998给底部边界约束让路
                textContentHeightConstraint?.priority = .init(998)
                textContentHeightConstraint?.isActive = true
            }
        }
        // ==================== 仅图片 ====================
        else if let normalImage = normalImage, let _ = selectedImage {
            let icon = UIImageView(image: normalImage)
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.contentMode = .scaleAspectFit
            addSubview(icon)
            self.iconView = icon

            NSLayoutConstraint.activate([
                icon.topAnchor.constraint(equalTo: topAnchor, constant: finalMargins.top),
                icon.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -finalMargins.bottom),
                icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: finalMargins.left),
                icon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -finalMargins.right)
            ])
        }
        // ==================== 仅文本 ====================
        else if let normalText = normalText, let _ = selectedText {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = normalText
            label.textColor = normalTextColor
            label.font = normalTextFont
            label.textAlignment = .center
            addSubview(label)
            self.textView = label

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: topAnchor, constant: finalMargins.top),
                label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -finalMargins.bottom),
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: finalMargins.left),
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -finalMargins.right)
            ])
        } else {
            fatalError("❌ 不支持的WYPagingItem显示类型")
        }

        return finalMargins
    }

    // 按当前选中状态的文字与图片重新测量并更新图文内容的最小宽高(仅图文混排模式有这些约束，其余模式空操作)
    func updateTextContentSize() {

        guard textContentWidthConstraint != nil else { return }

        let currentText: String? = isSelected ? selectedText : normalText
        let currentFont: UIFont? = isSelected ? selectedTextFont : normalTextFont
        let currentIcon: UIImage? = isSelected ? selectedImage : normalImage

        guard let text = currentText, let font = currentFont else { return }

        let iconSize = (contentImageViewSize == .zero ? currentIcon?.size : contentImageViewSize) ?? .zero
        let textSize = (text as NSString).size(withAttributes: [.font: font])

        switch contentPosition {
        case .imageLeftTitleRight, .imageRightTitleLeft:
            textContentWidthConstraint?.constant = iconSize.width + contentDividingOffset + textSize.width
        case .imageTopTitleBottom, .imageBottomTitleTop:
            textContentWidthConstraint?.constant = max(iconSize.width, textSize.width)
            textContentHeightConstraint?.constant = iconSize.height + contentDividingOffset + textSize.height
        }
    }
}
