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
    
    /// 相对于父控件的顶部
    case top = 0
    
    /// 相对于父控件的中部
    case middle
    
    /// 相对于父控件的底部
    case bottom
}

/// Loading提示窗动画类型
@frozen public enum WYActivityAnimation {
    
    /// 默认，系统小菊花
    case indicator
    
    /// gif图或者apng格式图片
    case gifOrApng
}

/// 滚动信息提示窗口默认配置项
public struct WYScrollInfoConfig {
    
    /// 设置滚动信息提示窗口的默认背景色
    public static var backgroundColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
    public var backgroundColor: UIColor = backgroundColor
    
    /// 设置滚动信息提示窗口的移动速度
    public static var movingSpeed: CGFloat = 1.2
    public var movingSpeed: CGFloat = movingSpeed
    
    /// 设置滚动信息提示窗口文本控件的默认颜色
    public static var textColor: UIColor = .white
    public var textColor: UIColor = textColor
    
    /// 设置滚动信息提示窗口文本控件的默认字体、字号
    public static var textFont: UIFont = .systemFont(ofSize: 15)
    public var textFont: UIFont = textFont
    
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
    public var backgroundColor: UIColor = backgroundColor
    
    /// 设置信息提示窗口文本控件的默认颜色
    public static var textColor: UIColor = .white
    public var textColor: UIColor = textColor
    
    /// 设置信息提示窗口文本控件的默认字体、字号
    public static var textFont: UIFont = .systemFont(ofSize: 15)
    public var textFont: UIFont = textFont
    
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
    public var backgroundColor: UIColor = backgroundColor
    
    /// 设置Loading提示窗口文本控件的默认颜色
    public static var textColor: UIColor = .white
    public var textColor: UIColor = textColor
    
    /// 设置Loading提示窗口文本控件的默认字体、字号
    public static var textFont: UIFont = .boldSystemFont(ofSize: 15)
    public var textFont: UIFont = textFont
    
    /// 设置Loading提示窗口 indicator 的颜色
    public static var indicatorColor: UIColor = .white
    public var indicatorColor: UIColor = indicatorColor
    
    /// 设置Loading提示窗口文本最多可显示几行
    public static var numberOfLines: NSInteger = 2
    public var numberOfLines: NSInteger = numberOfLines
    
    /// 设置Loading提示窗口动画控件的Size
    public static var animationSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(45, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(45, WYBasisKitConfig.defaultScreenPixels))
    public var animationSize: CGSize = animationSize
    
    /// 设置Loading提示窗口动图信息
    public static var gifInfo: WYGifInfo = defaultGifInfo()
    public var gifInfo: WYGifInfo = gifInfo
    
    /// 获取Loading提示窗口默认Gif图
    private static func defaultGifInfo() -> WYGifInfo {
        
        var defaultImages: [UIImage] = []
        for index in 0..<8 {
            defaultImages.append(UIImage.wy_find("indicator0" + "\(index + 1)", inBundle: WYSourceBundle(bundleName: "WYActivity", subdirectory: "Indicator")))
        }
        return WYGifInfo(animationImages: defaultImages, animationDuration: 0.8)
    }
    
    public init(backgroundColor: UIColor = backgroundColor, textColor: UIColor = textColor, textFont: UIFont = textFont, indicatorColor: UIColor = indicatorColor, numberOfLines: NSInteger = numberOfLines, animationSize: CGSize = animationSize, gifInfo: WYGifInfo = gifInfo) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.textFont = textFont
        self.indicatorColor = indicatorColor
        self.numberOfLines = numberOfLines
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
     *  @param content            要显示的文本内容，支持 String 与 NSAttributedString
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
     *  @param content            要显示的文本内容，支持 String 与 NSAttributedString
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
     *  @param content            要显示的文本内容，支持 String 与 NSAttributedString
     *
     *  @param contentView        加载活动控件的父视图
     *
     *  @param userInteraction    窗口显示期间是否允许用户对界面进行交互，默认允许
     *
     *  @param animation          动画类型，默认系统小菊花
     *
     *  @param delay              是否需要延时显示，设置后会延时 delay 后再显示Loading窗口
     *
     *  @param config             信息提示窗口配置选项
     *
     */
    public static func showLoading(_ content: Any? = nil, in contentView: UIView, userInteraction: Bool = true, animation: WYActivityAnimation = .indicator, delay: TimeInterval = 0, config: WYLoadingConfig = WYActivityConfig.default) {
        
        WYActivityLoadingView.showContent(content, in: contentView, userInteraction: userInteraction, animation: animation, delay: delay, config: config)
    }
    
    /**
     *  移除Loading窗口
     */
    public static func dismissLoading(in contentView: UIView) {
        
        WYActivityLoadingView.dismissLoading(in: contentView)
    }
}

private class WYActivityScrollInfoView: UIView {
    
    lazy var displayLink: CADisplayLink = {
        
        let displayLink = CADisplayLink(target: self, selector: #selector(refreshScrollInfo))
        displayLink.add(to: .current, forMode: RunLoop.Mode.common)
        displayLink.isPaused = true
        
        return displayLink
    }()
    
    lazy var contentLabel: UILabel = {
        
        let label = UILabel()
        addSubview(label)
        return label
    }()
    
    var movingSpeed: CGFloat = 0.0
    
    func showContent(_ content: Any, in contentView: UIView, offset: CGFloat, config: WYScrollInfoConfig) {
        
        if contentView.wy_scrollInfoView != nil {
            contentView.wy_scrollInfoView?.stopScroll(initial: true)
        }
        
        let attributedText = WYActivity.sharedContentAttributed(content: content, textColor: config.textColor, textFont: config.textFont)
        
        let contentSize: CGSize = attributedText.wy_calculateSize(controlSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        
        self.backgroundColor = config.backgroundColor
        
        self.frame = CGRect(x: 0, y: offset, width: contentView.frame.size.width, height: contentSize.height + 10)
        contentView.addSubview(self)
        
        contentLabel.attributedText = attributedText
        
        contentLabel.frame = CGRect(x: frame.size.width, y: 0, width: contentSize.width, height: frame.size.height)
        
        movingSpeed = config.movingSpeed
        
        displayLink.isPaused = false
        
        contentView.wy_scrollInfoView = self
    }
    
    @objc func refreshScrollInfo() {
        contentLabel.frame.origin.x = contentLabel.frame.origin.x - movingSpeed
        if contentLabel.frame.size.width < self.frame.size.width {
            if contentLabel.frame.origin.x <= UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels) {
                stopScroll()
            }
        }else {
            if (contentLabel.frame.origin.x + contentLabel.frame.size.width) <= (self.frame.size.width - UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)) {
                stopScroll()
                self.superview?.wy_scrollInfoView = nil
            }
        }
    }
    
    func stopScroll(initial: Bool = false) {
        
        displayLink.isPaused = true
        displayLink.invalidate()
        
        UIView.animate(withDuration: (initial ? 0 : 2)) {
            self.alpha = 0.0
        }completion: { _ in
            self.removeActivity()
            self.superview?.wy_scrollInfoView = nil
        }
    }
    
    func removeActivity() {
        var activity: UIView? = self
        activity?.removeFromSuperview()
        activity = nil
    }
}

private class WYActivityInfoView: UIView {
    
    var activityTimer: Timer? = nil
    
    lazy var contentLabel: UILabel = {
        
        let label = UILabel()
        label.numberOfLines = 0
        addSubview(label)
        return label
    }()
    
    lazy var swipeGesture: UISwipeGestureRecognizer = {
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
        swipe.numberOfTouchesRequired = 1
        addGestureRecognizer(swipe)
        return swipe
    }()
    
    var dismissOffset: CGFloat = 0
    
    func showContent(_ content: Any, in contentView: UIView, position: WYActivityPosition, offset: CGFloat, config: WYMessageInfoConfig) {
        
        if contentView.wy_infoView != nil {
            contentView.wy_infoView?.removeActivity()
        }
        
        let attributedText = WYActivity.sharedContentAttributed(content: content, textColor: config.textColor, textFont: config.textFont)
        
        contentLabel.attributedText = attributedText
        
        self.backgroundColor = config.backgroundColor
        self.wy_makeVisual { make in
            make.wy_rectCorner(.allCorners)
            make.wy_cornerRadius(UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels))
            
        }
        contentView.addSubview(self)
        
        layoutActivity(contentView: contentView, position: position, offset: offset, config: config)
        
        contentView.wy_infoView = self
    }
    
    func layoutActivity(contentView: UIView, position: WYActivityPosition, offset: CGFloat, config: WYMessageInfoConfig) {
        
        let controlWidth: CGFloat = contentView.frame.size.width - [UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels), UIDevice.wy_screenWidth(120, WYBasisKitConfig.defaultScreenPixels), UIDevice.wy_screenWidth(120, WYBasisKitConfig.defaultScreenPixels)][position.rawValue]
        
        contentLabel.frame = CGRect(x: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), y: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), width: controlWidth - UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels))
        contentLabel.sizeToFit()
        
        swipeGesture.direction = [.up, .left, .down][position.rawValue]
        if position == .middle {
            
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
            swipe.numberOfTouchesRequired = 1
            swipe.direction = .right
            addGestureRecognizer(swipe)
        }
        
        showAnimate(contentView: contentView, position: position, offset: offset, config: config)
    }
    
    func showAnimate(contentView: UIView, position: WYActivityPosition, offset: CGFloat, config: WYMessageInfoConfig) {
        
        let controlWidth: CGFloat = contentView.frame.size.width - [UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels), UIDevice.wy_screenWidth(120, WYBasisKitConfig.defaultScreenPixels), UIDevice.wy_screenWidth(120, WYBasisKitConfig.defaultScreenPixels)][position.rawValue]
        
        switch position {
        case .top:
            
            contentLabel.textAlignment = .left
            let controlHeight: CGFloat = contentLabel.frame.size.height + UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels)
            
            dismissOffset = -controlHeight
            
            self.frame = CGRect(x: (contentView.frame.size.width - controlWidth) / 2, y: -controlHeight, width: controlWidth, height: controlHeight)
            
            UIView.animate(withDuration: 0.5) {
                
                self.frame = CGRect(x: (contentView.frame.size.width - controlWidth) / 2, y: offset + UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), width: controlWidth, height: controlHeight)
                
            } completion: { _ in
                
                self.activityTimer = Timer.scheduledTimer(withTimeInterval: self.sharedTimeInterval(config: config), repeats: false, block: { [weak self] _ in
                    self?.dismissActivity(direction: .up, isHandleSwipe: false)
                    self?.superview?.wy_infoView = nil
                })
            }
            break
        default:
            
            contentLabel.textAlignment = .center
            
            let contentSize = WYActivity.sharedLayoutSize(contentView: contentView, contentLabel: contentLabel, minimux: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels), maxWidth: (contentView.frame.size.width - UIDevice.wy_screenWidth(120, WYBasisKitConfig.defaultScreenPixels)), defaultFont: config.textFont)
            
            contentLabel.frame = CGRect(x: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), y: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), width: contentSize.width, height: contentSize.height)
            contentLabel.sizeToFit()
            
            let offsetx = (contentView.frame.size.width - contentLabel.frame.size.width - UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels)) / 2
            var offsety = (contentView.frame.size.height - contentLabel.frame.size.height - UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels)) / 2
            
            let tabbarOffset = UIViewController.wy_currentController()?.tabBarController?.tabBar.isHidden ?? true ? 0 : UIDevice.wy_tabBarHeight
            
            if position == .middle {
                offsety = (contentView.frame.size.height - contentLabel.frame.size.height - UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels) - tabbarOffset) / 2
            }else {
                offsety = contentView.frame.size.height - contentLabel.frame.size.height - UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels) - tabbarOffset
                
                dismissOffset = contentView.frame.size.height
            }
            self.frame = CGRect(x: offsetx, y: offsety, width: contentLabel.frame.size.width + UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels), height: contentLabel.frame.size.height + UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels))
            
            self.alpha = 0
            UIView.animate(withDuration: 0.5) {
                self.alpha = 1.0
            } completion: { _ in
                
                self.activityTimer = Timer.scheduledTimer(withTimeInterval: self.sharedTimeInterval(config: config), repeats: false, block: { [weak self] _ in
                    self?.dismissActivity(direction: .right, isHandleSwipe: false)
                    self?.superview?.wy_infoView = nil
                })
            }
            break
        }
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        dismissActivity(direction: sender.direction, isHandleSwipe: true)
        superview?.wy_infoView = nil
    }
    
    func dismissActivity(direction: UISwipeGestureRecognizer.Direction, isHandleSwipe: Bool) {
        
        switch direction {
        case .up, .down:
            UIView.animate(withDuration: 0.5) {
                self.wy_top = self.dismissOffset
            } completion: { _ in
                self.removeActivity()
                self.superview?.wy_infoView = nil
            }
            break
        case .left:
            UIView.animate(withDuration: 0.5) {
                self.wy_right = self.superview?.frame.origin.x ?? 0
            } completion: { _ in
                self.removeActivity()
                self.superview?.wy_infoView = nil
            }
            break
        default:
            UIView.animate(withDuration: 0.5) {
                if isHandleSwipe {
                    self.wy_left = self.superview?.wy_right ?? 0
                }else {
                    self.alpha = 0.0
                }
            } completion: { _ in
                self.removeActivity()
                self.superview?.wy_infoView = nil
            }
            break
        }
    }
    
    func sharedTimeInterval(config: WYMessageInfoConfig) -> TimeInterval {
        return 1.5 + Double((WYActivity.textNumberOfLines(contentLabel: contentLabel, defaultFont: config.textFont) - 1) * 1)
    }
    
    func removeActivity() {
        
        activityTimer?.invalidate()
        activityTimer = nil
        
        var activity: UIView? = self
        activity?.removeFromSuperview()
        activity = nil
    }
}

private class WYActivityLoadingView: UIView {
    
    var interactionEnabled: Bool = true
    
    lazy var textlabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        addSubview(label)
        return label
    }()
    
    lazy var imageView: UIImageView = {
        let imageview = UIImageView()
        imageview.contentMode = .scaleAspectFit
        addSubview(imageview)
        return imageview
    }()
    
    lazy var indicator: UIActivityIndicatorView = {
        
        let activity: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
        addSubview(activity)
        return activity
    }()
    
    class func showContent(_ content: Any?, in contentView: UIView, userInteraction: Bool = true, animation: WYActivityAnimation, delay: TimeInterval, config: WYLoadingConfig) {
        
        if contentView.wy_loadingView != nil {
            contentView.wy_loadingView?.removeActivity()
        }
        
        let loadingView = WYActivityLoadingView()
        loadingView.isHidden = true
        loadingView.backgroundColor = config.backgroundColor
        contentView.addSubview(loadingView)
        
        loadingView.interactionEnabled = contentView.isUserInteractionEnabled
        
        contentView.isUserInteractionEnabled = userInteraction
        
        loadingView.layoutActivity(content: content, contentView: contentView, animation: animation, delay: delay, config: config)
        
        loadingView.wy_makeVisual { make in
            make.wy_rectCorner(.allCorners)
            make.wy_cornerRadius(UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels))
            
        }
        
        contentView.wy_loadingView = loadingView
    }
    
    func layoutActivity(content: Any?, contentView: UIView, animation: WYActivityAnimation, delay: TimeInterval, config: WYLoadingConfig) {
        
        switch animation {
        case .indicator:
            
            loadingLayout(subContro: indicator, contentView: contentView, subControSize: config.animationSize)
            
            if #available(iOS 14.0, *) {
                indicator.wy_left = indicator.wy_left + 1.5;
                indicator.wy_top = indicator.wy_top + 1.5;
            }
            
            indicator.color = config.indicatorColor
            indicator.startAnimating()
            
            break
        case .gifOrApng:
            
            loadingLayout(subContro: imageView, contentView: contentView, subControSize: config.animationSize)
            
            imageView.animationDuration = config.gifInfo.animationDuration
            imageView.animationImages = config.gifInfo.animationImages
            imageView.animationRepeatCount = 0
            imageView.startAnimating()
            
            break
        }
        
        if content != nil {
            
            let contentString: String? = (content is String) ? (content as? String) : ((content as? NSAttributedString)?.string)
            
            guard contentString?.count ?? 0 > 0 else {
                return
            }
            
            let attributedText = WYActivity.sharedContentAttributed(content: content!, textColor: config.textColor, textFont: config.textFont, alignment: .center)
            
            textlabel.numberOfLines = config.numberOfLines
            textlabel.attributedText = attributedText
            
            textlabel.sizeToFit()
            
            let textMinimux: CGFloat = frame.size.width
            var textMaximum: CGFloat = 0
            if config.numberOfLines > 0 {
                
                textMaximum = (frame.size.width * 1.5) + (CGFloat(config.numberOfLines) * textlabel.frame.size.height)
                if (textMaximum > (contentView.frame.size.width - UIDevice.wy_screenWidth(120, WYBasisKitConfig.defaultScreenPixels))) {
                    textMaximum = (contentView.frame.size.width - UIDevice.wy_screenWidth(120, WYBasisKitConfig.defaultScreenPixels))
                }
                
            }else {
                textMaximum = (contentView.frame.size.width - UIDevice.wy_screenWidth(120, WYBasisKitConfig.defaultScreenPixels))
            }
            textlabel.wy_width = WYActivity.sharedLayoutSize(contentView: contentView, contentLabel: textlabel, minimux: textMinimux, maxWidth: textMaximum, defaultFont: config.textFont).width
            
            textlabel.sizeToFit()
            
            let controWidth = textlabel.frame.size.width < textMinimux ? textMinimux : textlabel.frame.size.width
            
            var controSize = CGSize(width: controWidth + (UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels) * 2), height: frame.size.height + textlabel.frame.size.height)
            
            if controSize.width < controSize.height {
                controSize.width = controSize.height
                textlabel.wy_width = controSize.width - (UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels) * 2)
                textlabel.sizeToFit()
                controSize.height = frame.size.height + textlabel.frame.size.height
            }
            
            self.frame = CGRect(x: (contentView.frame.size.width - controSize.width) / 2, y: (contentView.frame.size.height - controSize.height - navViewHeight(contentView: contentView)) / 2, width: controSize.width, height: controSize.height)
            
            switch animation {
            case .indicator:
                textLayout(subContro: indicator, contentView: contentView)
                if #available(iOS 14.0, *) {
                    indicator.wy_left = indicator.wy_left + 1.5;
                    indicator.wy_top = indicator.wy_top + 1.5;
                }
                break
                
            case .gifOrApng:
                textLayout(subContro: imageView, contentView: contentView)
                break
            }
        }
        perform(#selector(showAnimate), with: nil, afterDelay: delay)
    }
    
    @objc func showAnimate() {
        self.isHidden = false
        self.alpha = 0.0
        UIView.animate(withDuration: 0.5) {
            self.alpha = 1.0
        }
    }
    
    class func dismissLoading(in contentView: UIView) {
        
        guard let loadingView = contentView.wy_loadingView else {
            return
        }
        UIView.animate(withDuration: 0.5) {
            loadingView.alpha = 0.0;
        } completion: { _ in
            loadingView.removeActivity()
            contentView.wy_loadingView = nil
        }
    }
    
    private func loadingLayout(subContro: UIView, contentView: UIView, subControSize: CGSize) {
        
        self.frame = CGRect(x: (contentView.frame.size.width - subControSize.width - 10) / 2, y: (contentView.frame.size.height - subControSize.height - navViewHeight(contentView: contentView) - 10) / 2, width: subControSize.width + 10, height: subControSize.height + 10)
        
        subContro.frame = CGRect(x: (frame.size.width - subControSize.width) / 2, y: (frame.size.height - subControSize.height) / 2, width: subControSize.width, height: subControSize.height)
    }
    
    private func textLayout(subContro: UIView, contentView: UIView) {
        
        subContro.frame = CGRect(x: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), y: UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels), width: frame.size.width - (UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels) * 2), height: subContro.frame.size.height)
        
        textlabel.frame = CGRect(x: (frame.size.width - textlabel.frame.size.width) / 2, y: subContro.wy_bottom, width: textlabel.frame.size.width, height: textlabel.frame.size.height)
    }
    
    func navViewHeight(contentView: UIView) -> CGFloat {
        
        var navHeight: CGFloat = 0
        let controller: UIViewController? = UIViewController.wy_currentController()
        if (contentView == controller?.view) && (controller?.navigationController != nil) {
            navHeight = UIDevice.wy_navViewHeight
        }
        return navHeight
    }
    
    func removeActivity() {
        
        var activity: WYActivityLoadingView? = self
        activity?.superview?.isUserInteractionEnabled = interactionEnabled
        activity?.removeFromSuperview()
        activity = nil
    }
}

private extension WYActivity {
    
    /// 获取加载信息提示窗口的父视图
    static func sharedContentView(_ window: UIView? = nil) -> UIView? {
        
        guard let contentView = window else {
            return UIViewController.wy_currentController()?.view ?? nil
        }
        return contentView
    }
    
    /// 获取加载信息提示窗口的父视图的默认偏移量
    static func sharedContentViewOffset(offset: CGFloat?, window: UIView?) -> CGFloat {
        guard offset == nil else {
            return offset ?? 0
        }
        guard let controller: UIViewController = UIViewController.wy_currentController() else {
            return offset ?? 0
        }
        if (window == controller.view) && (controller.navigationController != nil) {
            return UIDevice.wy_navViewHeight
        }else {
            return UIDevice.wy_statusBarHeight
        }
    }
    
    /// 根据传入的 content 和 config 动态生成一个富文本
    static func sharedContentAttributed(content: Any, textColor: UIColor, textFont: UIFont, alignment: NSTextAlignment = .left) -> NSAttributedString {
        
        var attributed: NSMutableAttributedString? = nil
        if content is String {
            
            attributed = NSMutableAttributedString(string: content as? String ?? "")
            attributed?.wy_colorsOfRanges(colorsOfRanges: [[textColor: attributed?.string as Any]])
            attributed?.wy_fontsOfRanges(fontsOfRanges: [[textFont: attributed?.string as Any]])
            attributed?.wy_wordsSpacing(wordsSpacing: 1)
            attributed?.wy_lineSpacing(lineSpacing: UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels), string: attributed?.string, alignment: alignment)
        }else {
            attributed = NSMutableAttributedString(attributedString: content as? NSAttributedString ?? NSAttributedString())
        }
        return attributed!
    }
    
    /// 计算文本控件最合适的宽度
    static func sharedLayoutSize(contentView: UIView, contentLabel: UILabel, minimux: CGFloat, maxWidth: CGFloat, defaultFont: UIFont) -> CGSize {
        
        let textHeight = contentLabel.frame.size.height
        let textWidth = contentLabel.frame.size.width
        
        var contentWidth = minimux;
        
        if textWidth > minimux {
            for line in 1..<(contentLabel.attributedText?.string.count ?? 0) {
                
                var maximum = minimux + (textHeight * CGFloat(line))
                
                if maximum > maxWidth {
                    maximum = maxWidth
                }
                
                let numberOfLines = textNumberOfLines(controlWidth: maximum, contentLabel: contentLabel, defaultFont: defaultFont)
                
                if maximum > maxWidth {
                    contentWidth = maxWidth
                    break
                }else {
                    if numberOfLines <= (line + 1) {
                        contentWidth = maximum
                        break
                    }
                }
            }
        }
        let contentHeight: CGFloat = contentLabel.attributedText?.wy_calculateHeight(controlWidth: contentWidth) ?? textHeight
        
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    /// 计算文本控件显示需要的行数
    static func textNumberOfLines(controlWidth: CGFloat = 0, contentLabel: UILabel, defaultFont: UIFont) -> NSInteger {
        
        guard contentLabel.attributedText?.string.isEmpty == false else {
            return 0
        }
        let numberOfLines: NSInteger = contentLabel.attributedText?.wy_numberOfRows(controlWidth: (controlWidth > 0 ? controlWidth : contentLabel.frame.size.width)) ?? 1
        
        return numberOfLines
    }
}

private extension UIView {
    
    var wy_scrollInfoView: WYActivityScrollInfoView? {
        
        set(newValue) {
            
            objc_setAssociatedObject(self, WYAssociatedKeys.private_wy_scrollInfoView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.private_wy_scrollInfoView) as? WYActivityScrollInfoView
        }
    }
    
    var wy_infoView: WYActivityInfoView? {
        
        set(newValue) {
            
            objc_setAssociatedObject(self, WYAssociatedKeys.private_wy_infoView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.private_wy_infoView) as? WYActivityInfoView
        }
    }
    
    var wy_loadingView: WYActivityLoadingView? {
        
        set(newValue) {
            
            objc_setAssociatedObject(self, WYAssociatedKeys.private_wy_loadingView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.private_wy_loadingView) as? WYActivityLoadingView
        }
    }
    
    private struct WYAssociatedKeys {
        
        static let private_wy_scrollInfoView = UnsafeRawPointer(bitPattern: "private_wy_scrollInfoView".hashValue)!
        static let private_wy_infoView = UnsafeRawPointer(bitPattern: "private_wy_infoView".hashValue)!
        static let private_wy_loadingView = UnsafeRawPointer(bitPattern: "private_wy_loadingView".hashValue)!
    }
}
