//
//  WYActivityObjC+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import Foundation

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

extension WYActivityObjC {
    
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
    static func internal_showScrollInfo(_ content: AnyObject, option: WYScrollInfoOptionsObjC? = nil) {
        
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
    static func internal_showInfo(_ content: AnyObject, option: WYMessageInfoOptionsObjC? = nil) {
        
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
    static func internal_showLoading(_ content: AnyObject? = nil, in contentView: UIView, option: WYLoadingInfoOptionsObjC? = nil) {
        
        let infoOption = option ?? WYLoadingInfoOptionsObjC()
        
        let activityAnimation: WYActivityAnimation = WYActivityAnimation(rawValue: infoOption.animation.rawValue) ?? .indicator
        
        let gifInfo: WYGifInfo = WYGifInfo(animationImages: infoOption.config.gifInfo.animationImages, animationDuration: infoOption.config.gifInfo.animationDuration, animatedImage: infoOption.config.gifInfo.animatedImage)
        
        var loadingConfig: WYLoadingConfig = WYLoadingConfig(backgroundColor: infoOption.config.backgroundColor, textColor: infoOption.config.textColor, textFont: infoOption.config.textFont, indicatorColor: infoOption.config.indicatorColor, numberOfLines: infoOption.config.numberOfLines, textBottomOffset: infoOption.config.textBottomOffset, animationSize: infoOption.config.animationSize, gifInfo: gifInfo)
        
        loadingConfig.targetAspectRatio = infoOption.config.targetAspectRatio
        loadingConfig.maximumWidthRatio = infoOption.config.maximumWidthRatio
        loadingConfig.contentInsets = infoOption.config.contentInsets
        loadingConfig.cornerRadius = infoOption.config.cornerRadius
        loadingConfig.animationTextSpacing = infoOption.config.animationTextSpacing

        WYActivity.showLoading(content, in: contentView, userInteraction: infoOption.userInteraction, animation: activityAnimation, delay: infoOption.delay, config: loadingConfig)
    }
    
    /**
     *  移除Loading窗口
     *  @param animate             true时0.5秒后才会移除(有个动画), false时无动画，立刻移除，
     */
    static func internal_dismissLoading(in contentView: UIView, animate: Bool = true) {
        WYActivity.dismissLoading(in: contentView, animate: animate)
    }
}
#endif
