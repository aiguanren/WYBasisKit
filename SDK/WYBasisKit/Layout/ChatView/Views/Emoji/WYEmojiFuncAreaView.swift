//
//  WYEmojiFuncAreaView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/4/27.
//

import UIKit

public struct WYEmojiFuncAreaConfig {
    
    /// 是否需要在右下角显示功能区(内含删除按钮和发送按钮)
    public var show: Bool = true
    
    /// 设置使用独立的发送按钮(当输入框中有字符出现时，会在InputBar的右侧出现一个独立的发送按钮)时，是否需要继续在功能区显示发送按钮
    public var removeSendView: Bool = inputBarConfig.showSpecialSendButton
    
    /// 功能区显示后，如果列表最后一行的表情被功能区遮挡，被遮挡的表情是否需要换行显示
    public var wrapLastLineOfEmoji: Bool = true
    
    /// 整个功能区高度
    public var areaHeight: CGFloat = wy_screenWidth(100)
    
    /// 删除按钮是否需要支持长按连续删除输入框内容
    public var longPressDelete: Bool = true
    
    /// 整个功能区距离emoji控件右侧的间距
    public var areaRightOffset: CGFloat = wy_screenWidth(15)
    
    /// 整个功能区距离emoji控件底部的间距
    public var areaBottomOffset: CGFloat = 0
    
    /// 删除按钮左侧距离功能区左侧的间距
    public var deleteViewLeftOffsetWithArea: CGFloat = inputBarConfig.showSpecialSendButton ? wy_screenWidth(20) : 0
    
    /// 发送按钮size
    public var sendViewSize: CGSize = CGSize(width: wy_screenWidth(60), height: wy_screenWidth(50))
    
    /// 删除按钮size
    public var deleteViewSize: CGSize = CGSize(width: wy_screenWidth(60), height: wy_screenWidth(50))
    
    /// 发送按钮左侧和删除按钮右侧之间的间距
    public var sendViewLeftOffsetWithDeleteView: CGFloat = wy_screenWidth(8)
    
    /// 发送按钮距离功能区右侧间距
    public var sendViewRightOffset: CGFloat = 0
    
    /// 发送按钮和删除按钮距离功能区顶部的间距
    public var sendViewAndDeleteViewTopOffset: CGFloat = wy_screenWidth(40)
    
    /// 删除按钮和发送按钮的圆角半径
    public var deleteViewAndSendViewCornerRadius: CGFloat = wy_screenWidth(5)
    
    /// 删除按钮不可点击时背景图
    public var deleteViewImageWithUnenable: UIImage = UIImage.wy_find("WYChatDeleteUnenable", inBundle: WYChatSourceBundle)
    
    /// 发送按钮不可点击时背景图
    public var sendViewImageWithUnenable: UIImage = UIImage.wy_createImage(from: .white, size: CGSize(width: wy_screenWidth(60), height: wy_screenWidth(50)))
    
    /// 删除按钮可点击时背景图
    public var deleteViewImageWithEnable: UIImage = UIImage.wy_find("WYChatDeleteEnable", inBundle: WYChatSourceBundle)
    
    /// 发送按钮可点击时背景图
    public var sendViewImageWithEnable: UIImage = UIImage.wy_createImage(from: .wy_rgb(64, 118, 246), size: CGSize(width: wy_screenWidth(60), height: wy_screenWidth(50)))
    
    /// 删除按钮按压状态背景图
    public var deleteViewImageWithHighly: UIImage = UIImage.wy_find("WYChatDeleteEnable", inBundle: WYChatSourceBundle)
    
    /// 发送按钮按压状态背景图
    public var sendViewImageWithHighly: UIImage = UIImage.wy_createImage(from: .wy_rgb(64, 118, 246), size: CGSize(width: wy_screenWidth(60), height: wy_screenWidth(50)))
    
    /// 删除按钮文本
    public var deleteViewText: String = "删除"
    
    /// 发送按钮文本
    public var sendViewText: String = "发送"
    
    /// 删除按钮字体字号
    public var deleteViewFont: UIFont = .boldSystemFont(ofSize: wy_screenWidth(16.5))
    
    /// 发送按钮字体字号
    public var sendViewFont: UIFont = .boldSystemFont(ofSize: wy_screenWidth(16.5))
    
    /// 删除按钮不可点击时文本颜色
    public var deleteViewTextColorWithUnenable: UIColor = .wy_hex("#E5E5E5")
    
    /// 发送按钮不可点击时文本颜色
    public var sendViewTextColorWithUnenable: UIColor = .wy_hex("#E5E5E5")
    
    /// 删除按钮可点击时文本颜色
    public var deleteViewTextColorWithEnable: UIColor = .blue
    
    /// 发送按钮可点击时文本颜色
    public var sendViewTextColorWithEnable: UIColor = .white
    
    /// 删除按钮按压状态文本颜色
    public var deleteViewTextColorWithHighly: UIColor = .blue
    
    /// 发送按钮按压状态文本颜色
    public var sendViewTextColorWithHighly: UIColor = .white
    
    public init() {
        /// 在这里判断是否需要调整功能区内发送按钮相关的间距、size等设置
        if removeSendView == true {
            sendViewSize = .zero
            sendViewLeftOffsetWithDeleteView = 0
        }
    }
}

@objc public protocol WYEmojiFuncAreaViewDelegate {
    
    /// 点击了发送按钮
    @objc optional func didClickEmojiSendView(_ sendView: UIButton)
    
    /// 点击了删除按钮
    @objc optional func didClickEmojiDeleteView(_ deleteView: UIButton)
}

public class WYEmojiFuncAreaView: UIView {
    
    var sendView: UIButton!
    var deleteView: UIButton!
    var longPressTimer: DispatchSourceTimer?
    
    public weak var delegate: WYEmojiFuncAreaViewDelegate? = nil
    
    public let gradualView: UIView = UIView()
    
    public init() {
        super.init(frame: .zero)
        
        addSubview(gradualView)
        gradualView.snp.makeConstraints { make in
            make.top.width.right.equalToSuperview()
            make.height.equalTo(emojiViewConfig.funcAreaConfig.sendViewAndDeleteViewTopOffset)
        }
        gradualView.wy_makeVisual { make in
            make.wy_gradualColors([emojiViewConfig.backgroundColor.withAlphaComponent(0),emojiViewConfig.backgroundColor.withAlphaComponent(0.3),emojiViewConfig.backgroundColor.withAlphaComponent(0.6),emojiViewConfig.backgroundColor.withAlphaComponent(0.8), emojiViewConfig.backgroundColor])
            make.wy_gradientDirection(.topToBottom)
        }

        let contentView: UIView = UIView()
        contentView.backgroundColor = emojiViewConfig.backgroundColor
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(emojiViewConfig.funcAreaConfig.sendViewAndDeleteViewTopOffset)
            make.left.equalTo(gradualView)
        }

        sendView = createFuncButton(text: emojiViewConfig.funcAreaConfig.sendViewText, textColorWithUnenable: emojiViewConfig.funcAreaConfig.sendViewTextColorWithUnenable, textColorWithEnable: emojiViewConfig.funcAreaConfig.sendViewTextColorWithEnable, textColorWithHighly: emojiViewConfig.funcAreaConfig.sendViewTextColorWithHighly, backgroundImageWithUnenable: emojiViewConfig.funcAreaConfig.sendViewImageWithUnenable, backgroundImageWithEnable: emojiViewConfig.funcAreaConfig.sendViewImageWithEnable, backgroundImageWithHighly: emojiViewConfig.funcAreaConfig.sendViewImageWithHighly, target: self, selector: #selector(clickSendView))
        sendView.wy_titleFont = emojiViewConfig.funcAreaConfig.sendViewFont
        contentView.addSubview(sendView)
        sendView.snp.makeConstraints { make in
            make.size.equalTo(emojiViewConfig.funcAreaConfig.sendViewSize)
            make.right.equalToSuperview().offset(-emojiViewConfig.funcAreaConfig.sendViewRightOffset)
            make.top.equalToSuperview()
        }

        deleteView = createFuncButton(text: emojiViewConfig.funcAreaConfig.deleteViewText, textColorWithUnenable: emojiViewConfig.funcAreaConfig.deleteViewTextColorWithUnenable, textColorWithEnable: emojiViewConfig.funcAreaConfig.deleteViewTextColorWithEnable, textColorWithHighly: emojiViewConfig.funcAreaConfig.deleteViewTextColorWithHighly, backgroundImageWithUnenable: emojiViewConfig.funcAreaConfig.deleteViewImageWithUnenable, backgroundImageWithEnable: emojiViewConfig.funcAreaConfig.deleteViewImageWithEnable, backgroundImageWithHighly: emojiViewConfig.funcAreaConfig.deleteViewImageWithHighly, target: self, selector: #selector(clickDeleteView))
        deleteView.wy_titleFont = emojiViewConfig.funcAreaConfig.deleteViewFont
        if (emojiViewConfig.funcAreaConfig.longPressDelete == true) {
            let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(sender:)))
            longPress.minimumPressDuration = 1
            deleteView.addGestureRecognizer(longPress)
        }
        contentView.addSubview(deleteView)
        deleteView.snp.makeConstraints { make in
            make.size.equalTo(emojiViewConfig.funcAreaConfig.deleteViewSize)
            make.right.equalTo(sendView.snp.left).offset(-emojiViewConfig.funcAreaConfig.sendViewLeftOffsetWithDeleteView)
            make.top.equalToSuperview()
        }
    }

    public func createFuncButton(text: String, textColorWithUnenable: UIColor, textColorWithEnable: UIColor, textColorWithHighly: UIColor, backgroundImageWithUnenable: UIImage, backgroundImageWithEnable: UIImage, backgroundImageWithHighly: UIImage, target: Any?, selector: Selector) -> UIButton {

        let button: UIButton = UIButton(type: .custom)
        button.wy_sTitle = text
        button.wy_nTitle = text
        button.wy_hTitle = text
        button.wy_title_sColor = textColorWithUnenable
        button.wy_title_nColor = textColorWithEnable
        button.wy_title_hColor = textColorWithHighly
        button.setBackgroundImage(backgroundImageWithUnenable, for: .selected)
        button.setBackgroundImage(backgroundImageWithEnable, for: .normal)
        button.setBackgroundImage(backgroundImageWithHighly, for: .highlighted)
        button.wy_cornerRadius(emojiViewConfig.funcAreaConfig.deleteViewAndSendViewCornerRadius).wy_showVisual()
        button.addTarget(target, action: selector, for: .touchUpInside)

        return button
    }

    public func updateFuncAreaStyle() {
        sendView.isSelected = isUserInteractionEnabled
        deleteView.isSelected = sendView.isSelected
    }
    
    @objc public func didLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            cancelLongPressTimer()
            
            longPressTimer = DispatchSource.makeTimerSource()
            longPressTimer?.schedule(deadline: .now(), repeating: 0.25)
            longPressTimer?.setEventHandler(handler: {
                DispatchQueue.main.async {
                    self.clickDeleteView()
                }
            })
            longPressTimer?.resume()
        }
        
        if (sender.state == .cancelled) || (sender.state == .ended) {
            cancelLongPressTimer()
        }
    }
    
    @objc public func clickDeleteView() {
        delegate?.didClickEmojiDeleteView?(deleteView)
    }
    
    @objc public func clickSendView() {
        delegate?.didClickEmojiSendView?(sendView)
    }
    
    public func cancelLongPressTimer() {
        longPressTimer?.cancel()
        longPressTimer = nil
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView: UIView? = super.hitTest(point, with: event)
        return (hitView == gradualView) ? nil : hitView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cancelLongPressTimer()
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
