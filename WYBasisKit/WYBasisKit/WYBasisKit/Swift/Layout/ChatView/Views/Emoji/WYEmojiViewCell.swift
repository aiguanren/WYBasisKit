//
//  WYEmojiViewCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/4/13.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit


public class WYEmojiViewCell: UICollectionViewCell {

    /// 表情图(WYChatEmojiView长按拖动时以它为锚点更新预览浮层)
    let emojiView: UIImageView = UIImageView()

    private var emojiString: String = ""
    public var emoji: String {

        set {
            emojiString = newValue
            emojiView.image = UIImage.wy_find(newValue, inBundle: emojiViewConfig.emojiBundle)
        }
        get {
            return emojiString
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(emojiView)
        emojiView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
