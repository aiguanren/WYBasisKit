//
//  WYMoveupTipsView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/8/31.
//

import UIKit

@frozen public enum WYMoveupTipsState: Int {
    
    /// 准备取消状态
    case cancel = 0
    
    /// 语音转文字状态
    case transfer
}

public class WYMoveupTipsView: UIView {
    
    /// 提示文本View
    public var tipsView: UILabel = UILabel()
    
    /// 移动按钮
    public var moveuplView: UIButton = UIButton(type: .custom)
    
    public init(tipsState: WYMoveupTipsState) {
        super.init(frame: .zero)
        
        tipsView.backgroundColor = .clear
        tipsView.textAlignment = .center
        tipsView.font = recordAnimationConfig.tipsInfoForMoveup.font
        tipsView.textColor = recordAnimationConfig.tipsInfoForMoveup.color
        addSubview(tipsView)
        tipsView.snp.makeConstraints { make in
            make.centerX.top.equalToSuperview()
            make.height.equalTo(tipsView.font.lineHeight)
        }

        addSubview(moveuplView)
        moveuplView.backgroundColor = .clear
        moveuplView.titleLabel?.numberOfLines = 0
        moveuplView.titleLabel?.textAlignment = .center
        
        moveuplView.setBackgroundImage((tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewImage.onExternal : recordAnimationConfig.transferViewImage.onExternal, for: .normal)
        moveuplView.setBackgroundImage((tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewImage.onInterior : recordAnimationConfig.transferViewImage.onInterior, for: .selected)
        
        moveuplView.setTitle((tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewText.onInterior : recordAnimationConfig.transferViewText.onInterior, for: .normal)
        moveuplView.setTitle((tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewText.onInterior : recordAnimationConfig.transferViewText.onInterior, for: .selected)
        
        moveuplView.setTitleColor((tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewTextInfoForExternal.color : recordAnimationConfig.transferViewTextInfoForExternal.color, for: .normal)
        moveuplView.setTitleColor((tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewTextInfoForInterior.color : recordAnimationConfig.transferViewTextInfoForInterior.color, for: .selected)
        
        moveuplView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(tipsView.snp.bottom).offset(recordAnimationConfig.moveupButtonCenterOffsetY.onExternal)
            make.width.height.equalTo(recordAnimationConfig.moveupButtonDiameter.onExternal)
            make.bottom.equalToSuperview()
        }
    }
    
    /// 刷新取消录音或者转文字按钮状态
    public func refresh(isDefault: Bool, isTouched: Bool) {
        
        moveuplView.isSelected = isTouched
        
        moveuplView.transform = CGAffineTransform(rotationAngle: isDefault ? -recordAnimationConfig.moveupViewDeviationAngle : recordAnimationConfig.moveupViewDeviationAngle)
        
        if moveuplView.isSelected == true {
            
            tipsView.text = isDefault ? recordAnimationConfig.cancelRecordViewText.tips : recordAnimationConfig.transferViewText.tips
            
            moveuplView.titleLabel?.font = isDefault ? recordAnimationConfig.cancelRecordViewTextInfoForExternal.font : recordAnimationConfig.transferViewTextInfoForExternal.font
            
            moveuplView.snp.updateConstraints { make in
                make.width.height.equalTo(recordAnimationConfig.moveupButtonDiameter.onInterior)
            }
            
        }else {
            
            tipsView.text = ""
            
            moveuplView.titleLabel?.font = isDefault ? recordAnimationConfig.cancelRecordViewTextInfoForInterior.font : recordAnimationConfig.transferViewTextInfoForInterior.font
            
            moveuplView.snp.updateConstraints { make in
                make.width.height.equalTo(recordAnimationConfig.moveupButtonDiameter.onExternal)
            }
        }
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
