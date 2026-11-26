//
//  WYEmojiHeaderView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/4/13.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit

public class WYEmojiHeaderView: UICollectionReusableView {

    /// 当前实例配置
    public var emojiViewConfig: WYEmojiViewConfig = WYEmojiViewConfig() {
        didSet { wy_applyHeaderConfiguration() }
    }

        
    public let textView: UILabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textView)
        wy_applyHeaderConfiguration()
    }

    private func wy_applyHeaderConfiguration() {
        backgroundColor = emojiViewConfig.headerBackgroundColor
        textView.textColor = emojiViewConfig.headerTextColor
        textView.font = emojiViewConfig.headerTextFont
        textView.textAlignment = emojiViewConfig.headerTextAlignment
        textView.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(emojiViewConfig.headerTextOffset.x)
            make.right.equalToSuperview().offset(-emojiViewConfig.headerTextOffset.x)
            make.top.equalToSuperview().offset(emojiViewConfig.headerTextOffset.y)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
