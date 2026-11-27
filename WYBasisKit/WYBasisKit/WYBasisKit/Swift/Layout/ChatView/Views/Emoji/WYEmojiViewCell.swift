//
//  WYEmojiViewCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/4/13.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit


public class WYEmojiViewCell: UICollectionViewCell {

    /// 当前实例配置
    public var emojiViewConfig: WYEmojiViewConfig = WYEmojiViewConfig()
    let state = WYEmojiViewCellPrivateState()
    public var emoji: String {

        set {
            state.emojiString = newValue
            state.emojiView.image = emojiViewConfig.staticEmojiImage(newValue)
        }
        get {
            return state.emojiString
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(state.emojiView)
        state.emojiView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
