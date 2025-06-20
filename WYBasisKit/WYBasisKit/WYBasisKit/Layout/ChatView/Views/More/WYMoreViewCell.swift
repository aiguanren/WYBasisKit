//
//  WYMoreViewCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/2.
//

import UIKit

class WYMoreViewCell: UICollectionViewCell {
    
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
