//
//  WYEmojiViewCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/4/13.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit

@objc public protocol WYEmojiViewCellDelegate {
    
    /// 长按了表情预览控件(仅限WYEmojiPreviewStyle == other时才会回调)
    @objc optional func willShowPreviewView(_ gestureRecognizer: UILongPressGestureRecognizer, emoji: String, according: UIImageView)
}

public class WYEmojiViewCell: UICollectionViewCell {
    
    weak var delegate: WYEmojiViewCellDelegate? = nil
    
    private let emojiView: UIImageView = UIImageView()
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
        
        let gesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(sender:)))
        gesture.minimumPressDuration = 0.5
        addGestureRecognizer(gesture)
    }
    
    @objc private func didLongPress(sender: UILongPressGestureRecognizer) {
        delegate?.willShowPreviewView?(sender, emoji: emoji, according: emojiView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
