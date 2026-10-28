//
//  WYActivity.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/8/29.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit
import Foundation

/// 信息提示窗口的显示位置
@frozen public enum WYActivityPosition: Int {
    
    /// 相对于父控件的中部
    case middle = 0
    
    /// 相对于父控件的顶部
    case top
    
    /// 相对于父控件的底部
    case bottom
}

/// Loading提示窗动画类型
@frozen public enum WYActivityAnimation: Int {
    
    /// 默认，系统小菊花
    case indicator = 0
    
    /// gif图或者apng格式图片
    case gifOrApng
}

/// 滚动信息提示窗口默认配置项
public struct WYScrollInfoConfig {
    
    /// 设置滚动信息提示窗口的默认背景色
    public static var backgroundColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
    public var backgroundColor: UIColor
    
    /// 设置滚动信息提示窗口的移动速度
    public static var movingSpeed: CGFloat = 1.2
    public var movingSpeed: CGFloat
    
    /// 设置滚动信息提示窗口文本控件的默认颜色
    public static var textColor: UIColor = .white
    public var textColor: UIColor
    
    /// 设置滚动信息提示窗口文本控件的默认字体、字号
    public static var textFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))
    public var textFont: UIFont
    
    public init(backgroundColor: UIColor = backgroundColor, movingSpeed: CGFloat = movingSpeed, textColor: UIColor = textColor, textFont: UIFont = textFont) {
        self.backgroundColor = backgroundColor
        self.movingSpeed = movingSpeed
        self.textColor = textColor
        self.textFont = textFont
    }
}

/// 信息提示窗口默认配置项
public struct WYMessageInfoConfig {
    
    /// 设置信息提示窗口的默认背景色
    public static var backgroundColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
    public var backgroundColor: UIColor
    
    /// 设置信息提示窗口文本控件的默认颜色
    public static var textColor: UIColor = .white
    public var textColor: UIColor
    
    /// 设置信息提示窗口文本控件的默认字体、字号
    public static var textFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))
    public var textFont: UIFont
    
    public init(backgroundColor: UIColor = backgroundColor, textColor: UIColor = textColor, textFont: UIFont = textFont) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.textFont = textFont
    }
}

/// Loading提示窗口配置项
public struct WYLoadingConfig {
    
    /// 设置Loading提示窗口的默认背景色
    public static var backgroundColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
    public var backgroundColor: UIColor
    
    /// 设置Loading提示窗口文本控件的默认颜色
    public static var textColor: UIColor = .white
    public var textColor: UIColor
    
    /// 设置Loading提示窗口文本控件的默认字体、字号
    public static var textFont: UIFont = .boldSystemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))
    public var textFont: UIFont
    
    /// 设置Loading提示窗口 indicator 的颜色
    public static var indicatorColor: UIColor = .white
    public var indicatorColor: UIColor
    
    /// 设置Loading提示窗口文本最多可显示几行
    public static var numberOfLines: Int = 2
    public var numberOfLines: Int
    
    /// 设置Loading提示窗口文本距离窗口底部的间距
    public static var textBottomOffset: CGFloat = 5
    public var textBottomOffset: CGFloat
    
    /// 设置Loading提示窗口动画控件的Size
    public static var animationSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(45, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(45, WYBasisKitConfig.defaultScreenPixels))
    public var animationSize: CGSize
    
    /// Loading提示窗口的目标宽高比(默认1，必须为有限正数，文本放不下时优先扩宽)
    public static var targetAspectRatio: CGFloat = 1
    public var targetAspectRatio: CGFloat = WYLoadingConfig.targetAspectRatio

    /// Loading提示窗口占可用区域的最大宽度比例(默认0.8，取值大于0且不超过1)
    public static var maximumWidthRatio: CGFloat = 0.8
    public var maximumWidthRatio: CGFloat = WYLoadingConfig.maximumWidthRatio

    /// Loading提示窗口内边距(有文本时底边距使用textBottomOffset)
    public static var contentInsets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenHeight(10, WYBasisKitConfig.defaultScreenPixels), left: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenHeight(10, WYBasisKitConfig.defaultScreenPixels), right: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels))
    public var contentInsets: UIEdgeInsets = WYLoadingConfig.contentInsets

    /// Loading提示窗口的圆角半径
    public static var cornerRadius: CGFloat = UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)
    public var cornerRadius: CGFloat = WYLoadingConfig.cornerRadius

    /// Loading提示窗口动画与文本之间的间距
    public static var animationTextSpacing: CGFloat = UIDevice.wy_screenHeight(5, WYBasisKitConfig.defaultScreenPixels)
    public var animationTextSpacing: CGFloat = WYLoadingConfig.animationTextSpacing

    /// 设置Loading提示窗口动图信息
    public static var gifInfo: WYGifInfo = defaultGifInfo()
    public var gifInfo: WYGifInfo
    
    public init(backgroundColor: UIColor = backgroundColor, textColor: UIColor = textColor, textFont: UIFont = textFont, indicatorColor: UIColor = indicatorColor, numberOfLines: Int = numberOfLines, textBottomOffset: CGFloat = textBottomOffset, animationSize: CGSize = animationSize, gifInfo: WYGifInfo = gifInfo) {
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


public struct WYActivityConfig {
    
    /// 滚动信息提示窗口默认配置
    public static let scroll: WYScrollInfoConfig = WYScrollInfoConfig()
    
    /// 信息提示窗口默认配置
    public static let info: WYMessageInfoConfig = WYMessageInfoConfig()
    
    /// 默认Loading提示窗口配置
    public static let `default`: WYLoadingConfig = WYLoadingConfig()
    
    /// 透明Loading提示窗口配置(适用于没有显示文本的自定义Gif Loading提示窗)
    public static let concise: WYLoadingConfig = WYLoadingConfig(backgroundColor: .clear)
}

public struct WYActivity {
    
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
    public static func showScrollInfo(_ content: Any, in contentView: UIView? = nil, offset: CGFloat? = nil, config: WYScrollInfoConfig = WYActivityConfig.scroll) {
        
        guard let windowView = sharedContentView(contentView) else {
            return
        }
        WYActivityScrollInfoView().showContent(content, in: windowView, offset: sharedContentViewOffset(offset: offset, window: windowView), config: config)
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
    public static func showInfo(_ content: Any, in contentView: UIView? = nil, position: WYActivityPosition = .middle, offset: CGFloat? = nil, config: WYMessageInfoConfig = WYActivityConfig.info) {
        
        guard let windowView = sharedContentView(contentView) else {
            return
        }
        WYActivityInfoView().showContent(content, in: windowView, position: position, offset: sharedContentViewOffset(offset: offset, window: windowView), config: config)
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
    public static func showLoading(_ content: Any? = nil, in contentView: UIView, userInteraction: Bool = true, animation: WYActivityAnimation = .indicator, delay: TimeInterval = 0, config: WYLoadingConfig = WYActivityConfig.default) {
        
        WYActivityLoadingView.showContent(content, in: contentView, userInteraction: userInteraction, animation: animation, delay: delay, config: config)
    }
    
    /**
     *  移除Loading窗口
     *  @param animate             true时0.5秒后才会移除(有个动画), false时无动画，立刻移除，
     */
    public static func dismissLoading(in contentView: UIView, animate: Bool = true) {
        
        WYActivityLoadingView.dismissLoading(in: contentView, animate: animate)
    }
}

