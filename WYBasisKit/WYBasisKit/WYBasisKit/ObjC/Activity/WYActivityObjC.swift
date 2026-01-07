//
//  WYActivityObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/8/29.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit
import Foundation
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

/// 信息提示窗口的显示位置
@objc(WYActivityPosition)
@frozen public enum WYActivityPositionObjC: Int {
    
    /// 相对于父控件的中部
    case middle = 0
    
    /// 相对于父控件的顶部
    case top
    
    /// 相对于父控件的底部
    case bottom
}

/// Loading提示窗动画类型
@objc(WYActivityAnimation)
@frozen public enum WYActivityAnimationObjC: Int {
    
    /// 默认，系统小菊花
    case indicator = 0
    
    /// gif图或者apng格式图片
    case gifOrApng
}

/// 滚动信息提示窗口默认配置项
@objc(WYScrollInfoConfig)
@objcMembers public class WYScrollInfoConfigObjC: NSObject {
    
    /// 设置滚动信息提示窗口的默认背景色
    @objc public static var backgroundColor: UIColor {
        get { return WYScrollInfoConfig.backgroundColor }
        set { WYScrollInfoConfig.backgroundColor = newValue }
    }
    @objc public var backgroundColor: UIColor
    
    /// 设置滚动信息提示窗口的移动速度
    @objc public static var movingSpeed: CGFloat {
        get { return WYScrollInfoConfig.movingSpeed }
        set { WYScrollInfoConfig.movingSpeed = newValue }
    }
    @objc public var movingSpeed: CGFloat
    
    /// 设置滚动信息提示窗口文本控件的默认颜色
    @objc public static var textColor: UIColor {
        get { return WYScrollInfoConfig.textColor }
        set { WYScrollInfoConfig.textColor = newValue }
    }
    @objc public var textColor: UIColor
    
    /// 设置滚动信息提示窗口文本控件的默认字体、字号
    @objc public static var textFont: UIFont {
        get { return WYScrollInfoConfig.textFont }
        set { WYScrollInfoConfig.textFont = newValue }
    }
    @objc public var textFont: UIFont
    
    @objc public init(backgroundColor: UIColor = backgroundColor, movingSpeed: CGFloat = movingSpeed, textColor: UIColor = textColor, textFont: UIFont = textFont) {
        self.backgroundColor = backgroundColor
        self.movingSpeed = movingSpeed
        self.textColor = textColor
        self.textFont = textFont
    }
}

/// 信息提示窗口默认配置项
@objc(WYMessageInfoConfig)
@objcMembers public class WYMessageInfoConfigObjC: NSObject {
    
    /// 设置信息提示窗口的默认背景色
    @objc public static var backgroundColor: UIColor {
        get { return WYMessageInfoConfig.backgroundColor }
        set { WYMessageInfoConfig.backgroundColor = newValue }
    }
    @objc public var backgroundColor: UIColor
    
    /// 设置信息提示窗口文本控件的默认颜色
    @objc public static var textColor: UIColor {
        get { return WYMessageInfoConfig.textColor }
        set { WYMessageInfoConfig.textColor = newValue }
    }
    @objc public var textColor: UIColor
    
    /// 设置信息提示窗口文本控件的默认字体、字号
    @objc public static var textFont: UIFont {
        get { return WYMessageInfoConfig.textFont }
        set { WYMessageInfoConfig.textFont = newValue }
    }
    @objc public var textFont: UIFont
    
    @objc public init(backgroundColor: UIColor = backgroundColor, textColor: UIColor = textColor, textFont: UIFont = textFont) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.textFont = textFont
    }
}

/// Loading提示窗口配置项
@objc(WYLoadingConfig)
@objcMembers public class WYLoadingConfigObjC: NSObject {
    
    /// 设置Loading提示窗口的默认背景色
    @objc public static var backgroundColor: UIColor {
        get { return WYLoadingConfig.backgroundColor }
        set { WYLoadingConfig.backgroundColor = newValue }
    }
    @objc public var backgroundColor: UIColor
    
    /// 设置Loading提示窗口文本控件的默认颜色
    @objc public static var textColor: UIColor {
        get { return WYLoadingConfig.textColor }
        set { WYLoadingConfig.textColor = newValue }
    }
    @objc public var textColor: UIColor
    
    /// 设置Loading提示窗口文本控件的默认字体、字号
    @objc public static var textFont: UIFont {
        get { return WYLoadingConfig.textFont }
        set { WYLoadingConfig.textFont = newValue }
    }
    @objc public var textFont: UIFont
    
    /// 设置Loading提示窗口 indicator 的颜色
    @objc public static var indicatorColor: UIColor {
        get { return WYLoadingConfig.indicatorColor }
        set { WYLoadingConfig.indicatorColor = newValue }
    }
    @objc public var indicatorColor: UIColor
    
    /// 设置Loading提示窗口文本最多可显示几行
    @objc public static var numberOfLines: Int {
        get { return WYLoadingConfig.numberOfLines }
        set { WYLoadingConfig.numberOfLines = newValue }
    }
    @objc public var numberOfLines: Int
    
    /// 设置Loading提示窗口文本距离窗口底部的间距
    @objc public static var textBottomOffset: CGFloat {
        get { return WYLoadingConfig.textBottomOffset }
        set { WYLoadingConfig.textBottomOffset = newValue }
    }
    @objc public var textBottomOffset: CGFloat
    
    /// 设置Loading提示窗口动画控件的Size
    @objc public static var animationSize: CGSize {
        get { return WYLoadingConfig.animationSize }
        set { WYLoadingConfig.animationSize = newValue }
    }
    @objc public var animationSize: CGSize
    
    /// 设置Loading提示窗口动图信息
    @objc public static var gifInfo: WYGifInfoObjC {
        get {
            let info = WYLoadingConfig.gifInfo
            return WYGifInfoObjC(animationImages: info.animationImages, animationDuration: info.animationDuration, animatedImage: info.animatedImage)
        }
        set {
            WYLoadingConfig.gifInfo = WYGifInfo(animationImages: newValue.animationImages, animationDuration: newValue.animationDuration, animatedImage: newValue.animatedImage)
        }
    }
    @objc public var gifInfo: WYGifInfoObjC
    
    @objc public init(backgroundColor: UIColor = backgroundColor, textColor: UIColor = textColor, textFont: UIFont = textFont, indicatorColor: UIColor = indicatorColor, numberOfLines: Int = numberOfLines, textBottomOffset: CGFloat = textBottomOffset, animationSize: CGSize = animationSize, gifInfo: WYGifInfoObjC = gifInfo) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.textFont = textFont
        self.indicatorColor = indicatorColor
        self.numberOfLines = numberOfLines
        self.textBottomOffset = textBottomOffset
        self.animationSize = animationSize
        self.gifInfo = gifInfo
    }
}

@objc(WYActivityConfig)
@objcMembers public class WYActivityConfigObjC: NSObject {
    
    /// 滚动信息提示窗口默认配置
    @objc public static let scroll: WYScrollInfoConfigObjC = WYScrollInfoConfigObjC()
    
    /// 信息提示窗口默认配置
    @objc public static let info: WYMessageInfoConfigObjC = WYMessageInfoConfigObjC()
    
    /// 默认Loading提示窗口配置
    @objc public static let `default`: WYLoadingConfigObjC = WYLoadingConfigObjC()
    
    /// 透明Loading提示窗口配置(适用于没有显示文本的自定义Gif Loading提示窗)
    @objc public static let concise: WYLoadingConfigObjC = WYLoadingConfigObjC(backgroundColor: .clear)
}

@objc(WYScrollInfoOptions)
@objcMembers public class WYScrollInfoOptionsObjC: NSObject {
    
    /// 加载活动控件的父视图，内部会按照 传入的View、控制器的View 的顺序去设置显示
    @objc public var contentView: UIView?
    
    /// 信息提示窗口相对于contentView的偏移量
    @objc public var offset: NSNumber?
    
    /// 信息提示窗口配置选项
    @objc public var config: WYScrollInfoConfigObjC = WYActivityConfigObjC.scroll
}

@objc(WYMessageInfoOptions)
@objcMembers public class WYMessageInfoOptionsObjC: NSObject {
    
    /// 加载信息提示窗口的父视图，内部会按照 传入的View、控制器的View 的顺序去设置显示
    @objc public var contentView: UIView?
    
    /// 信息提示窗口的显示位置
    @objc public var position: WYActivityPositionObjC = .middle
    
    /// 信息提示窗口相对于contentView的偏移量(仅 position == top 时有效)
    @objc public var offset: NSNumber?
    
    /// 信息提示窗口配置选项
    @objc public var config: WYMessageInfoConfigObjC = WYActivityConfigObjC.info
}

@objc(WYLoadingInfoOptions)
@objcMembers public class WYLoadingInfoOptionsObjC: NSObject {
    
    /// 窗口显示期间是否允许用户对界面进行交互，默认允许
    @objc public var userInteraction: Bool = true
    
    /// 动画类型，默认系统小菊花
    @objc public var animation: WYActivityAnimationObjC = .indicator
    
    /// 是否需要延时显示，设置后会延时 delay(秒) 后再显示Loading窗口
    @objc public var delay: TimeInterval = 0
    
    /// 信息提示窗口相对于 contentView 的偏移量
    @objc public var offset: NSNumber?
    
    /// 信息提示窗口配置选项
    @objc public var config: WYLoadingConfigObjC = WYActivityConfigObjC.default
}

@objc(WYActivity)
@objcMembers public class WYActivityObjC: NSObject {
    
    /**
     *  显示一个滚动信息提示窗口
     *
     *  @param content            要显示的文本内容，支持 String 与 AttributedString
     *
     *  @param contentView        加载活动控件的父视图，内部会按照 传入的View、控制器的View 的顺序去设置显示
     *
     *  @param offset             信息提示窗口相对于contentView的偏移量
     *
     *  @param config             信息提示窗口配置选项
     *
     */
    @objc public static func showScrollInfo(_ content: AnyObject) {
        internal_showScrollInfo(content)
    }
    @objc public static func showScrollInfo(_ content: AnyObject, option: WYScrollInfoOptionsObjC? = nil) {
        internal_showScrollInfo(content, option: option)
    }
    
    /**
     *  显示一个信息提示窗口
     *
     *  @param content            要显示的文本内容，支持 String 与 AttributedString
     *
     *  @param contentView        加载信息提示窗口的父视图，内部会按照 传入的View、控制器的View 的顺序去设置显示
     *
     *  @param position           信息提示窗口的显示位置，支持 top、middle、bottom
     *
     *  @param offset             信息提示窗口相对于contentView的偏移量(仅 position == top 时有效)
     *
     *  @param config             信息提示窗口配置选项
     */
    @objc public static func showInfo(_ content: AnyObject) {
        internal_showInfo(content)
    }
    @objc public static func showInfo(_ content: AnyObject, option: WYMessageInfoOptionsObjC? = nil) {
        internal_showInfo(content, option: option)
    }
    
    /**
     *  显示一个Loading提示窗口
     *
     *  @param content            要显示的文本内容，支持 String 与 AttributedString
     *
     *  @param contentView        加载活动控件的父视图
     *
     *  @param userInteraction    窗口显示期间是否允许用户对界面进行交互，默认允许
     *
     *  @param animation          动画类型，默认系统小菊花
     *
     *  @param delay              是否需要延时显示，设置后会延时 delay(秒) 后再显示Loading窗口
     *
     *  @param config             信息提示窗口配置选项
     *
     */
    @objc(showLoading:)
    public static func showLoading(in contentView: UIView) {
        internal_showLoading(in: contentView)
    }
    @objc public static func showLoading(_ content: AnyObject, in contentView: UIView) {
        internal_showLoading(content, in: contentView)
    }
    @objc(showLoading:option:)
    public static func showLoading(in contentView: UIView, option: WYLoadingInfoOptionsObjC? = nil) {
        internal_showLoading(in: contentView, option: option)
    }
    @objc public static func showLoading(_ content: AnyObject, in contentView: UIView, option: WYLoadingInfoOptionsObjC? = nil) {
        internal_showLoading(content, in: contentView, option: option)
    }
    
    /**
     *  移除Loading窗口
     *  @param animate             true时0.5秒后才会移除(有个动画), false时无动画，立刻移除，
     */
    @objc(dismissLoading:)
    public static func dismissLoading(in contentView: UIView) {
        internal_dismissLoading(in: contentView)
    }
    @objc(dismissLoading:animate:)
    public static func dismissLoading(in contentView: UIView, animate: Bool = true) {
        internal_dismissLoading(in: contentView, animate: animate)
    }
}

private extension WYActivityObjC {
    
    /**
     *  显示一个滚动信息提示窗口
     *
     *  @param content            要显示的文本内容，支持 String 与 AttributedString
     *
     *  @param contentView        加载活动控件的父视图，内部会按照 传入的View、控制器的View 的顺序去设置显示
     *
     *  @param offset             信息提示窗口相对于contentView的偏移量
     *
     *  @param config             信息提示窗口配置选项
     *
     */
    private static func internal_showScrollInfo(_ content: AnyObject, option: WYScrollInfoOptionsObjC? = nil) {
        
        let infoOption = option ?? WYScrollInfoOptionsObjC()
        
        let numberOffset: CGFloat? = (infoOption.offset != nil) ? CGFloat(infoOption.offset!.doubleValue) : nil
        
        let scrollInfoConfig: WYScrollInfoConfig = WYScrollInfoConfig(backgroundColor: infoOption.config.backgroundColor, movingSpeed: infoOption.config.movingSpeed, textColor: infoOption.config.textColor, textFont: infoOption.config.textFont)
        
        WYActivity.showScrollInfo(content, in: infoOption.contentView, offset: numberOffset, config: scrollInfoConfig)
    }
    
    /**
     *  显示一个信息提示窗口
     *
     *  @param content            要显示的文本内容，支持 String 与 AttributedString
     *
     *  @param contentView        加载信息提示窗口的父视图，内部会按照 传入的View、控制器的View 的顺序去设置显示
     *
     *  @param position           信息提示窗口的显示位置，支持 top、middle、bottom
     *
     *  @param offset             信息提示窗口相对于contentView的偏移量(仅 position == top 时有效)
     *
     *  @param config             信息提示窗口配置选项
     */
    private static func internal_showInfo(_ content: AnyObject, option: WYMessageInfoOptionsObjC? = nil) {
        
        let infoOption = option ?? WYMessageInfoOptionsObjC()
        
        let numberOffset: CGFloat? = (infoOption.offset != nil) ? CGFloat(infoOption.offset!.doubleValue) : nil
        
        let activityPosition: WYActivityPosition = WYActivityPosition(rawValue: (infoOption.position).rawValue) ?? .middle
        
        let messageInfoConfig: WYMessageInfoConfig = WYMessageInfoConfig(backgroundColor: infoOption.config.backgroundColor, textColor: infoOption.config.textColor, textFont: infoOption.config.textFont)
        
        WYActivity.showInfo(content, in: infoOption.contentView, position: activityPosition, offset: numberOffset, config: messageInfoConfig)
    }
    
    /**
     *  显示一个Loading提示窗口
     *
     *  @param content            要显示的文本内容，支持 String 与 AttributedString
     *
     *  @param contentView        加载活动控件的父视图
     *
     *  @param userInteraction    窗口显示期间是否允许用户对界面进行交互，默认允许
     *
     *  @param animation          动画类型，默认系统小菊花
     *
     *  @param delay              是否需要延时显示，设置后会延时 delay(秒) 后再显示Loading窗口
     *
     *  @param config             信息提示窗口配置选项
     *
     */
    private static func internal_showLoading(_ content: AnyObject? = nil, in contentView: UIView, option: WYLoadingInfoOptionsObjC? = nil) {
        
        let infoOption = option ?? WYLoadingInfoOptionsObjC()
        
        let activityAnimation: WYActivityAnimation = WYActivityAnimation(rawValue: infoOption.animation.rawValue) ?? .indicator
        
        let gifInfo: WYGifInfo = WYGifInfo(animationImages: infoOption.config.gifInfo.animationImages, animationDuration: infoOption.config.gifInfo.animationDuration, animatedImage: infoOption.config.gifInfo.animatedImage)
        
        let loadingConfig: WYLoadingConfig = WYLoadingConfig(backgroundColor: infoOption.config.backgroundColor, textColor: infoOption.config.textColor, textFont: infoOption.config.textFont, indicatorColor: infoOption.config.indicatorColor, numberOfLines: infoOption.config.numberOfLines, textBottomOffset: infoOption.config.textBottomOffset, animationSize: infoOption.config.animationSize, gifInfo: gifInfo)
        
        WYActivity.showLoading(content, in: contentView, userInteraction: infoOption.userInteraction, animation: activityAnimation, delay: infoOption.delay, config: loadingConfig)
    }
    
    /**
     *  移除Loading窗口
     *  @param animate             true时0.5秒后才会移除(有个动画), false时无动画，立刻移除，
     */
    private static func internal_dismissLoading(in contentView: UIView, animate: Bool = true) {
        WYActivity.dismissLoading(in: contentView, animate: animate)
    }
}
