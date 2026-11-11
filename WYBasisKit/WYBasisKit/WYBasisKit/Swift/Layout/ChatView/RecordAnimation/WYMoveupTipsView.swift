//
//  WYMoveUpTipsView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/8/31.
//

import UIKit

@objc @frozen public enum WYMoveUpTipsState: Int {
    
    /// 准备取消状态
    case cancel = 0
    
    /// 语音转文字状态
    case transfer
}

public class WYMoveUpTipsView: UIView {

    internal var actionTipsState: WYMoveUpTipsState = .cancel

    /// 当前实例配置
    public var recordAnimationConfig: WYRecordAnimationConfig = WYRecordAnimationConfig()

    
    /// 提示文本View
    public var tipsView: UILabel = UILabel()
    
    /// 移动按钮
    public var moveUpView: UIButton = WYChatRecordingActionButton(type: .custom)
    
    public init(tipsState: WYMoveUpTipsState, configuration: WYRecordAnimationConfig = WYRecordAnimationConfig()) {
        self.recordAnimationConfig = configuration
        super.init(frame: .zero)
        (moveUpView as? WYChatRecordingActionButton)?.layoutHandler = { [weak self] in self?.wy_layoutAction() }
        
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
        wy_refreshAction(tipsState: tipsState, isTouched: false)
    }
    
    /// 刷新取消录音或者转文字按钮状态
    public func refresh(tipsState: WYMoveUpTipsState, isTouched: Bool) {
        
        wy_refreshAction(tipsState: tipsState, isTouched: isTouched)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        moveUpView.layoutIfNeeded()
        if !(moveUpView is WYChatRecordingActionButton) { wy_layoutAction() }
    }

    
}
