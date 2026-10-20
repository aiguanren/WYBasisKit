//
//  WYDanmakuItemView.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// 单条弹幕的展示视图(内部包一个自适应尺寸的文本标签，随复用池反复取用归还)
final class WYDanmakuItemView: UIView {

    /// 内容标签
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.textAlignment = .center
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 复用前重置内容
    func prepare(attributedText: NSAttributedString) {
        label.attributedText = attributedText
    }
}
