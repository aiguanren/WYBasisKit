//
//  WYDanmakuViewObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

/// 弹幕外观与行为配置(改动后对之后新发的弹幕与轨道划分生效，属性转调弹幕视图持有的同一份配置实例)
@objc(WYDanmakuConfiguration)
@objcMembers public class WYDanmakuConfigurationObjC: NSObject {

    /// 底层配置实例
    let configuration: WYDanmakuConfiguration

    init(configuration: WYDanmakuConfiguration) {
        self.configuration = configuration
        super.init()
    }

    /// 轨道条数(0 表示按显示高度与轨道行高自动计算)
    public var trackCount: Int {
        get { return configuration.trackCount }
        set { configuration.trackCount = newValue }
    }

    /// 单条轨道的行高，单位为pt
    public var trackHeight: CGFloat {
        get { return configuration.trackHeight }
        set { configuration.trackHeight = newValue }
    }

    /// 弹幕显示区占弹幕视图高度的比例(0~1，从顶部往下取，底部型弹幕按比例区内底部对齐)
    public var displayAreaRatio: CGFloat {
        get { return configuration.displayAreaRatio }
        set { configuration.displayAreaRatio = newValue }
    }

    /// 滚动弹幕横穿一个弹幕区宽度的行程时长，单位为秒(所有滚动弹幕同一速度，先发后发不会追尾)
    public var scrollDuration: TimeInterval {
        get { return configuration.scrollDuration }
        set { configuration.scrollDuration = newValue }
    }

    /// 顶部与底部弹幕的停留时长，单位为秒
    public var fixedDuration: TimeInterval {
        get { return configuration.fixedDuration }
        set { configuration.fixedDuration = newValue }
    }

    /// 弹幕字体(发纯文本与发富文本都会套这个字体，富文本自己带字体的段落除外)
    public var font: UIFont {
        get { return configuration.font }
        set { configuration.font = newValue }
    }

    /// 弹幕文字颜色(富文本自己带颜色的段落除外)
    public var textColor: UIColor {
        get { return configuration.textColor }
        set { configuration.textColor = newValue }
    }

    /// 文字描边颜色(与描边宽度配合让弹幕在浅色画面上也看得清)
    public var textStrokeColor: UIColor {
        get { return configuration.textStrokeColor }
        set { configuration.textStrokeColor = newValue }
    }

    /// 文字描边宽度，单位为pt(负数表示描边同时保留文字填充，正数表示只描边不填充，绝对值越大边越粗)
    public var textStrokeWidth: CGFloat {
        get { return configuration.textStrokeWidth }
        set { configuration.textStrokeWidth = newValue }
    }

    /// 文字阴影颜色(nil 表示不画阴影)
    public var textShadowColor: UIColor? {
        get { return configuration.textShadowColor }
        set { configuration.textShadowColor = newValue }
    }

    /// 文字阴影模糊半径，单位为pt
    public var textShadowBlurRadius: CGFloat {
        get { return configuration.textShadowBlurRadius }
        set { configuration.textShadowBlurRadius = newValue }
    }

    /// 文字阴影偏移，单位为pt
    public var textShadowOffset: CGSize {
        get { return configuration.textShadowOffset }
        set { configuration.textShadowOffset = newValue }
    }

    /// 单条弹幕的背景色(nil 表示不画背景)
    public var itemBackgroundColor: UIColor? {
        get { return configuration.itemBackgroundColor }
        set { configuration.itemBackgroundColor = newValue }
    }

    /// 单条弹幕背景的圆角半径，单位为pt
    public var itemBackgroundCornerRadius: CGFloat {
        get { return configuration.itemBackgroundCornerRadius }
        set { configuration.itemBackgroundCornerRadius = newValue }
    }

    /// 弹幕文字距条目背景左右边缘的留白，单位为pt
    public var itemHorizontalPadding: CGFloat {
        get { return configuration.itemHorizontalPadding }
        set { configuration.itemHorizontalPadding = newValue }
    }

    /// 弹幕文字距条目背景上下边缘的留白，单位为pt(条目高按轨道行高减上下留白后在轨道内垂直居中)
    public var itemVerticalPadding: CGFloat {
        get { return configuration.itemVerticalPadding }
        set { configuration.itemVerticalPadding = newValue }
    }

    /// 同轨相邻两条弹幕之间的最小间距，单位为pt(前一条让出这个距离后同轨才允许进新条)
    public var itemSpacing: CGFloat {
        get { return configuration.itemSpacing }
        set { configuration.itemSpacing = newValue }
    }

    /// 轨道行与行之间的纵向间距，单位为pt(轨道条数自适应时按轨道行高加本间距计算)
    public var trackSpacing: CGFloat {
        get { return configuration.trackSpacing }
        set { configuration.trackSpacing = newValue }
    }

    /// 是否显示弹幕头像(发送时传了头像图片且此项为 true 才显示)
    public var showsAvatar: Bool {
        get { return configuration.showsAvatar }
        set { configuration.showsAvatar = newValue }
    }

    /// 头像边长，单位为pt
    public var avatarSize: CGFloat {
        get { return configuration.avatarSize }
        set { configuration.avatarSize = newValue }
    }

    /// 头像圆角半径，单位为pt(设为头像边长的一半即圆形头像)
    public var avatarCornerRadius: CGFloat {
        get { return configuration.avatarCornerRadius }
        set { configuration.avatarCornerRadius = newValue }
    }

    /// 头像与文字的间距，单位为pt
    public var avatarSpacing: CGFloat {
        get { return configuration.avatarSpacing }
        set { configuration.avatarSpacing = newValue }
    }

    /// 轨道满时的处理方式
    public var overflowPolicy: WYDanmakuOverflowPolicy {
        get { return configuration.overflowPolicy }
        set { configuration.overflowPolicy = newValue }
    }

    /// 在屏弹幕总条数上限，超过后按轨道满时的处理方式对待(0 表示不限制)
    public var maxVisibleCount: Int {
        get { return configuration.maxVisibleCount }
        set { configuration.maxVisibleCount = newValue }
    }
}

@objc public extension WYDanmakuView {

    /// 弹幕配置(改动后对之后新发的弹幕与轨道划分生效)
    @objc(configuration)
    var configurationObjC: WYDanmakuConfigurationObjC {
        return WYDanmakuConfigurationObjC(configuration: configuration)
    }

    /**
     *  发一条弹幕
     *
     *  @param text         弹幕文字，外观取配置里的字体颜色描边与阴影
     *  @param type         弹幕类型，默认滚动
     *
     */
    @objc(send:type:)
    func sendObjC(_ text: String, type: WYDanmakuType) {
        send(text, type: type)
    }

    /**
     *  发一条带头像的弹幕
     *
     *  @param text         弹幕文字，外观取配置里的字体颜色描边与阴影
     *  @param type         弹幕类型，默认滚动
     *  @param avatar       头像图片(配置关闭头像显示时传了也不显示)
     *
     */
    @objc(send:type:avatar:)
    func sendAvatarObjC(_ text: String, type: WYDanmakuType, avatar: UIImage?) {
        send(text, type: type, avatar: avatar)
    }

    /**
     *  发一条富文本弹幕
     *
     *  @param attributedText    弹幕富文本，自带字体与颜色的段落保留自身样式，其余段落套配置外观
     *  @param type              弹幕类型，默认滚动
     *
     */
    @objc(sendAttributedText:type:)
    func sendAttributedObjC(_ attributedText: NSAttributedString, type: WYDanmakuType) {
        send(attributedText, type: type)
    }

    /**
     *  注入播放时间驱动弹幕
     *
     *  @param time         当前播放时间，单位为秒(播放中周期调用，注入后内置时钟自动停用，注入时间倒退超过 0.5 秒按定位清屏，小幅度倒退只对齐引擎时间)
     *
     */
    @objc(playAtTime:)
    func playObjC(at time: TimeInterval) {
        play(at: time)
    }

    /// 冻结全部在屏弹幕(内置时钟停止，恢复走 resume)
    @objc(pauseDanmaku)
    func pauseObjC() {
        pause()
    }

    /// 恢复内置时钟继续计时(只对没注入过播放时间的自驱场景有效)
    @objc(resumeDanmaku)
    func resumeObjC() {
        resume()
    }

    /**
     *  播放定位
     *
     *  @param time         定位到的播放时间，单位为秒(清掉在屏与排队的弹幕后把弹幕时钟对到该位置)
     *
     */
    @objc(seekToTime:)
    func seekObjC(to time: TimeInterval) {
        seek(to: time)
    }

    /// 清空在屏与排队的全部弹幕
    @objc(clearDanmaku)
    func clearObjC() {
        clear()
    }
}
#endif
