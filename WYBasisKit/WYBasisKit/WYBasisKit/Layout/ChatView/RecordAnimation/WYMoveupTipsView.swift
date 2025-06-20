//
//  WYMoveupTipsView.swift
//  WYBasisKit
//
//  Created by Miraitowa on 2023/8/31.
//

import UIKit

public class WYMoveupTipsView: UIView {
    
    /// 提示文本View
    public var tipsView: UILabel = UILabel()
    
    /// 移动按钮
    public var moveuplView: UIButton = UIButton(type: .custom)
    
    /// isDefault为true时表示左侧取消控件，否则为右侧文字转语音(或其他)控件
    public init(isDefault: Bool) {
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
        
        moveuplView.setBackgroundImage(isDefault ? recordAnimationConfig.cancelRecordViewImage.onExternal : recordAnimationConfig.transferViewImage.onExternal, for: .normal)
        moveuplView.setBackgroundImage(isDefault ? recordAnimationConfig.cancelRecordViewImage.onInterior : recordAnimationConfig.transferViewImage.onInterior, for: .selected)
        
        moveuplView.setTitle(isDefault ? recordAnimationConfig.cancelRecordViewText.onInterior : recordAnimationConfig.transferViewText.onInterior, for: .normal)
        moveuplView.setTitle(isDefault ? recordAnimationConfig.cancelRecordViewText.onInterior : recordAnimationConfig.transferViewText.onInterior, for: .selected)
        
        moveuplView.setTitleColor(isDefault ? recordAnimationConfig.cancelRecordViewTextInfoForExternal.color : recordAnimationConfig.transferViewTextInfoForExternal.color, for: .normal)
        moveuplView.setTitleColor(isDefault ? recordAnimationConfig.cancelRecordViewTextInfoForInterior.color : recordAnimationConfig.transferViewTextInfoForInterior.color, for: .selected)
        
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
        
        moveuplView.transform = CGAffineTransform(rotationAngle: isDefault ? recordAnimationConfig.moveupViewDeviationAngle : -recordAnimationConfig.moveupViewDeviationAngle)
        
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
