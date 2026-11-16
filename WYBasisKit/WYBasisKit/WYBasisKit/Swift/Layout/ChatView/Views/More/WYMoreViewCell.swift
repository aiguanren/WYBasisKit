//
//  WYMoreViewCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/2.
//

import UIKit

class WYMoreViewCell: UICollectionViewCell {

    /// 当前实例配置
    public var moreViewConfig: WYMoreViewConfig = WYMoreViewConfig() {
        didSet {
            guard iconView.superview != nil else { return }
            let size = moreViewConfig.iconSize
            iconView.snp.updateConstraints { make in
                make.size.equalTo(CGSize(width: size.width.isFinite ? max(0, size.width) : 0, height: size.height.isFinite ? max(0, size.height) : 0)).priority(999)
            }
        }
    }

    
    let iconView: UIImageView = UIImageView()
    let titleView: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = moreViewConfig.backgroundColor
        
        let cornerView: UIView = UIView()
        cornerView.backgroundColor = moreViewConfig.imageBackgroundColor
        contentView.addSubview(cornerView)
        cornerView.wy_makeVisual { make in
            make.wy_cornerRadius(moreViewConfig.imageViewCornerRadius)
        }
        cornerView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(moreViewConfig.imageViewSize.height)
        }
        
        iconView.contentMode = .scaleAspectFit
        cornerView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.size.lessThanOrEqualToSuperview()
            make.size.equalTo(moreViewConfig.iconSize).priority(999)
            make.center.equalToSuperview()
        }
        
        titleView.textColor = moreViewConfig.textColor
        titleView.font = moreViewConfig.textViewFont
        titleView.adjustsFontSizeToFitWidth = true
        titleView.textAlignment = .center
        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(cornerView.snp.bottom).offset(moreViewConfig.textTopOffset)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
