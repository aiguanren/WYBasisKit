//
//  WYTestTableViewFooterView.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/7/4.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit

class WYTestTableViewFooterView: UITableViewHeaderFooterView {
    
    var titleView = UILabel()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .blue
        
        titleView.frame = CGRect(x: 20, y: 0, width: wy_screenWidth - 20, height: 30)
        titleView.textColor = .white
        titleView.font = .systemFont(ofSize: wy_screenWidth(14))
        contentView.addSubview(titleView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
