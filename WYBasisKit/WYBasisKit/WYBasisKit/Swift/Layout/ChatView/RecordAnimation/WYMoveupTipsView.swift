//
//  WYMoveUpTipsView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/8/31.
//

import UIKit

@frozen public enum WYMoveUpTipsState: Int {
    
    /// 准备取消状态
    case cancel = 0
    
    /// 语音转文字状态
    case transfer
}

public class WYMoveUpTipsView: UIView {
    
    /// 提示文本View
    public var tipsView: UILabel = UILabel()
    
    /// 移动按钮
    public var moveUpView: UIButton = UIButton(type: .custom)
    
    public init(tipsState: WYMoveUpTipsState) {
        super.init(frame: .zero)
        
        tipsView.backgroundColor = .clear
        tipsView.textAlignment = .center
        tipsView.font = recordAnimationConfig.tipsInfoForMoveUp.font
        tipsView.textColor = recordAnimationConfig.tipsInfoForMoveUp.color
        addSubview(tipsView)
        tipsView.snp.makeConstraints { make in
            make.centerX.top.equalToSuperview()
            make.height.equalTo(tipsView.font.lineHeight)
        }

        addSubview(moveUpView)
        moveUpView.backgroundColor = .clear
        moveUpView.titleLabel?.numberOfLines = 0
        moveUpView.titleLabel?.textAlignment = .center
        
        moveUpView.setBackgroundImage((tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewImage.onExternal : recordAnimationConfig.transferViewImage.onExternal, for: .normal)
        moveUpView.setBackgroundImage((tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewImage.onInterior : recordAnimationConfig.transferViewImage.onInterior, for: .selected)
        
        moveUpView.setTitle((tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewText.onInterior : recordAnimationConfig.transferViewText.onInterior, for: .normal)
        moveUpView.setTitle((tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewText.onInterior : recordAnimationConfig.transferViewText.onInterior, for: .selected)
        
        moveUpView.setTitleColor((tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewTextInfoForExternal.color : recordAnimationConfig.transferViewTextInfoForExternal.color, for: .normal)
        moveUpView.setTitleColor((tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewTextInfoForInterior.color : recordAnimationConfig.transferViewTextInfoForInterior.color, for: .selected)
        
        moveUpView.snp.makeConstraints { make in
            make.centerY.equalTo(tipsView.snp.bottom).offset(recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal)
            make.width.height.equalTo(recordAnimationConfig.moveUpButtonDiameter.onExternal)
            make.left.bottom.right.equalToSuperview()
        }
    }
    
    /// 刷新取消录音或者转文字按钮状态
    public func refresh(tipsState: WYMoveUpTipsState, isTouched: Bool) {
        
        moveUpView.isSelected = isTouched
        
        if recordAnimationConfig.supportSpeechRecognition {
            moveUpView.transform = CGAffineTransform(rotationAngle: (tipsState == .cancel) ? -recordAnimationConfig.moveUpViewDeviationAngle : recordAnimationConfig.moveUpViewDeviationAngle)
        }
        
        if moveUpView.isSelected == true {
            
            tipsView.text = (tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewText.tips : recordAnimationConfig.transferViewText.tips
            
            moveUpView.titleLabel?.font = (tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewTextInfoForExternal.font : recordAnimationConfig.transferViewTextInfoForExternal.font
            
            moveUpView.snp.updateConstraints { make in
                make.width.height.equalTo(recordAnimationConfig.moveUpButtonDiameter.onInterior)
            }
            
        }else {
            
            tipsView.text = ""
            
            moveUpView.titleLabel?.font = (tipsState == .cancel) ? recordAnimationConfig.cancelRecordViewTextInfoForInterior.font : recordAnimationConfig.transferViewTextInfoForInterior.font
            
            moveUpView.snp.updateConstraints { make in
                make.width.height.equalTo(recordAnimationConfig.moveUpButtonDiameter.onExternal)
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
