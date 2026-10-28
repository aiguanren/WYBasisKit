//
//  WYDanmakuItemView.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// 单条弹幕的展示视图(内部包一个头像视图与一个自适应尺寸的文本标签，随复用池反复取用归还)
final class WYDanmakuItemView: UIView {

    /// 内容标签
    let label = UILabel()

    /// 头像视图
    let avatarView = UIImageView()

    /// 头像与前导间距合计占用的宽度(无头像时 0)
    private var avatarLeadingWidth: CGFloat = 0

    /// 头像边长
    private var avatarSide: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textAlignment = .center
        addSubview(label)
        avatarView.contentMode = .scaleAspectFill
        avatarView.isHidden = true
        addSubview(avatarView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if avatarLeadingWidth > 0 {
            avatarView.isHidden = false
            avatarView.frame = CGRect(x: 0, y: (bounds.height - avatarSide) / 2, width: avatarSide, height: avatarSide)
        }else {
            avatarView.isHidden = true
        }
        label.frame = CGRect(x: avatarLeadingWidth, y: 0, width: max(0, bounds.width - avatarLeadingWidth), height: bounds.height)
    }

    /// 复用前重置内容并套用配置里的背景与头像外观
    func prepare(attributedText: NSAttributedString, avatar: UIImage?, configuration: WYDanmakuConfiguration) {
        label.attributedText = attributedText
        backgroundColor = configuration.itemBackgroundColor
        layer.cornerRadius = configuration.itemBackgroundCornerRadius
        let showsAvatar = avatar != nil && configuration.showsAvatar
        avatarSide = configuration.avatarSize
        avatarLeadingWidth = showsAvatar ? configuration.avatarSize + configuration.avatarSpacing : 0
        avatarView.image = showsAvatar ? avatar : nil
        avatarView.layer.cornerRadius = showsAvatar ? configuration.avatarCornerRadius : 0
        avatarView.layer.masksToBounds = showsAvatar
        setNeedsLayout()
    }
}
