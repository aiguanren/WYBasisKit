//
//  WYDanmakuView.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// 弹幕类型
@objc public enum WYDanmakuType: Int {

    /// 滚动弹幕，从弹幕区右缘进入匀速左移到完全走出
    case scroll = 0

    /// 顶部弹幕，在弹幕区上方轨道水平居中停留一段时间
    case top

    /// 底部弹幕，在弹幕区最下一轨往上数水平居中停留一段时间
    case bottom
}

/// 弹幕视图(叠在视频画面上使用，内部自动开时钟推进弹幕，也可以由播放方注入播放时间驱动暂停冻结与定位清屏)
public class WYDanmakuView: UIView {

    /// 弹幕配置(改动后对之后新发的弹幕与轨道划分生效)
    public var configuration = WYDanmakuConfiguration() {
        didSet {
            engine.layoutTracks()
        }
    }

    /// 运动引擎
    let engine: WYDanmakuEngine

    override public init(frame: CGRect) {
        engine = WYDanmakuEngine(danmakuView: nil)
        super.init(frame: frame)
        engine.setup(danmakuView: self)
        isUserInteractionEnabled = false
        clipsToBounds = true
        backgroundColor = .clear
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        engine.layoutTracks()
    }

    deinit {
        engine.invalidate()
    }

    /**
     *  发一条弹幕
     *
     *  @param text         弹幕文字，外观取配置里的字体颜色描边与阴影
     *  @param type         弹幕类型，默认滚动
     *  @param avatar       头像图片，默认 nil 不显示(配置关闭头像显示时传了也不显示)
     *
     */
    public func send(_ text: String, type: WYDanmakuType = .scroll, avatar: UIImage? = nil) {
        send(attributedText(for: text), type: type, avatar: avatar)
    }

    /**
     *  发一条富文本弹幕
     *
     *  @param attributedText    弹幕富文本，自带字体与颜色的段落保留自身样式，其余段落套配置外观
     *  @param type              弹幕类型，默认滚动
     *  @param avatar            头像图片，默认 nil 不显示(配置关闭头像显示时传了也不显示)
     *
     */
    public func send(_ attributedText: NSAttributedString, type: WYDanmakuType = .scroll, avatar: UIImage? = nil) {
        engine.send(attributedText, avatar: avatar, type: type)
        engine.startAutoClockIfNeeded()
    }

    /**
     *  注入播放时间驱动弹幕
     *
     *  @param time         当前播放时间，单位为秒(播放中周期调用，注入后内置时钟自动停用，注入时间倒退超过 0.5 秒按定位清屏，小幅度倒退只对齐引擎时间)
     *
     */
    public func play(at time: TimeInterval) {
        engine.play(at: time)
    }

    /// 冻结全部在屏弹幕(内置时钟停止，恢复走 resume)
    public func pause() {
        engine.pause()
    }

    /// 恢复内置时钟继续计时(只对没注入过播放时间的自驱场景有效)
    public func resume() {
        engine.resumeAutoClock()
    }

    /**
     *  播放定位
     *
     *  @param time         定位到的播放时间，单位为秒(清掉在屏与排队的弹幕后把弹幕时钟对到该位置)
     *
     */
    public func seek(to time: TimeInterval) {
        engine.seek(to: time)
    }

    /// 清空在屏与排队的全部弹幕
    public func clear() {
        engine.clear()
    }

    /// 把纯文本套上配置里的字体颜色描边与阴影
    private func attributedText(for text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byClipping
        var attributes: [NSAttributedString.Key: Any] = [.font: configuration.font,
                                                         .foregroundColor: configuration.textColor,
                                                         .strokeColor: configuration.textStrokeColor,
                                                         .strokeWidth: configuration.textStrokeWidth,
                                                         .paragraphStyle: paragraphStyle]
        if let shadowColor = configuration.textShadowColor {
            let shadow = NSShadow()
            shadow.shadowColor = shadowColor
            shadow.shadowBlurRadius = configuration.textShadowBlurRadius
            shadow.shadowOffset = configuration.textShadowOffset
            attributes[.shadow] = shadow
        }
        return NSAttributedString(string: text, attributes: attributes)
    }
}
