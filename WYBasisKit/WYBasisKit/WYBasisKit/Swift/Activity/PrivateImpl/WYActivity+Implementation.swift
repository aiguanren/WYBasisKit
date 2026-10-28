//
//  WYActivity+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit

class WYActivityScrollInfoView: UIView {
    
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
        
        guard attributedText.string.isEmpty == false else {
            return
        }
        
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

class WYActivityInfoView: UIView {
    
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
        
        guard attributedText.string.isEmpty == false else {
            return
        }
        
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
                
            } completion: { [weak self] _ in
                guard let self = self else { return }
                weak let weakSelf = self
                self.activityTimer = Timer.scheduledTimer(withTimeInterval: self.sharedTimeInterval(config: config), repeats: false, block: { _ in
                    weakSelf?.dismissActivity(direction: .up, isHandleSwipe: false)
                    weakSelf?.superview?.wy_infoView = nil
                })
            }
            break
        default:
            
            contentLabel.textAlignment = .center
            
            let contentSize = WYActivity.sharedLayoutSize(contentView: contentView, contentLabel: contentLabel, minimum: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels), maxWidth: (contentView.frame.size.width - UIDevice.wy_screenWidth(120, WYBasisKitConfig.defaultScreenPixels)), defaultFont: config.textFont)
            
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
            } completion: { [weak self] _ in
                guard let self = self else { return }
                weak let weakSelf = self
                self.activityTimer = Timer.scheduledTimer(withTimeInterval: self.sharedTimeInterval(config: config), repeats: false, block: { _ in
                    weakSelf?.dismissActivity(direction: .right, isHandleSwipe: false)
                    weakSelf?.superview?.wy_infoView = nil
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

class WYActivityLoadingView: UIView {

    var interactionEnabled: Bool = true
    let panel = UIView()
    let textlabel = UILabel()
    let imageView = UIImageView()
    let indicator = UIActivityIndicatorView(style: .large)
    var loadingConfig: WYLoadingConfig?
    var loadingAnimation: WYActivityAnimation = .indicator

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        addSubview(panel)
        panel.addSubview(indicator)
        panel.addSubview(imageView)
        panel.addSubview(textlabel)
        textlabel.textAlignment = .center
        textlabel.lineBreakMode = .byTruncatingTail
        imageView.contentMode = .scaleAspectFit
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func showContent(_ content: Any?, in contentView: UIView, userInteraction: Bool = true, animation: WYActivityAnimation, delay: TimeInterval, config: WYLoadingConfig) {
        contentView.wy_loadingView?.removeActivity()
        let loadingView = WYActivityLoadingView()
        loadingView.isHidden = true
        loadingView.interactionEnabled = contentView.isUserInteractionEnabled
        contentView.isUserInteractionEnabled = userInteraction
        contentView.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
            loadingView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor)
        ])
        loadingView.panel.backgroundColor = config.backgroundColor
        loadingView.panel.wy_makeVisual { make in
            make.wy_rectCorner(.allCorners)
            make.wy_cornerRadius(config.cornerRadius.isFinite ? max(0, config.cornerRadius) : 0)
        }
        contentView.wy_loadingView = loadingView
        loadingView.layoutActivity(content: content, contentView: contentView, animation: animation, delay: delay, config: config)
    }

    func layoutActivity(content: Any?, contentView: UIView, animation: WYActivityAnimation, delay: TimeInterval, config: WYLoadingConfig) {
        loadingConfig = config
        loadingAnimation = animation
        indicator.isHidden = animation != .indicator
        imageView.isHidden = animation != .gifOrApng
        if animation == .indicator {
            indicator.color = config.indicatorColor
            indicator.startAnimating()
        } else {
            imageView.animationDuration = config.gifInfo.animationDuration
            imageView.animationImages = config.gifInfo.animationImages
            imageView.animationRepeatCount = 0
            imageView.startAnimating()
        }
        let value = content as? String ?? (content as? NSAttributedString)?.string ?? ""
        textlabel.isHidden = value.isEmpty
        textlabel.numberOfLines = max(0, config.numberOfLines)
        if !value.isEmpty, let content {
            textlabel.attributedText = WYActivity.sharedContentAttributed(content: content, textColor: config.textColor, textFont: config.textFont, alignment: .center)
        }
        contentView.layoutIfNeeded()
        setNeedsLayout()
        layoutIfNeeded()
        Task { [weak self] in
            try? await Task.wy_delay(delay, cancelThrows: false) {
                self?.showAnimate()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let config = loadingConfig, bounds.width > 0, bounds.height > 0 else { return }
        func dimension(_ value: CGFloat) -> CGFloat { value.isFinite ? max(0, value) : 0 }
        let widthRatio = config.maximumWidthRatio.isFinite && config.maximumWidthRatio > 0 ? min(1, config.maximumWidthRatio) : 0.8
        let ratio = config.targetAspectRatio.isFinite && config.targetAspectRatio > 0 ? config.targetAspectRatio : 1
        let maximumWidth = bounds.width * widthRatio
        let left = min(dimension(config.contentInsets.left), maximumWidth / 4)
        let right = min(dimension(config.contentInsets.right), maximumWidth / 4)
        let top = min(dimension(config.contentInsets.top), bounds.height / 4)
        let bottom = min(dimension(textlabel.isHidden ? config.contentInsets.bottom : config.textBottomOffset), bounds.height / 4)
        let spacing = textlabel.isHidden ? 0 : dimension(config.animationTextSpacing)
        var animationSize = CGSize(width: dimension(config.animationSize.width), height: dimension(config.animationSize.height))
        let scale = min(1, (maximumWidth - left - right) / max(animationSize.width, 1), (bounds.height - top - bottom) / max(animationSize.height, 1))
        animationSize.width *= scale
        animationSize.height *= scale
        let naturalText = textlabel.isHidden ? .zero : textlabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        var baseHeight = top + animationSize.height + bottom + (textlabel.isHidden ? 0 : spacing + naturalText.height)
        baseHeight = max(baseHeight, (animationSize.width + left + right) / ratio)
        let targetWidth = baseHeight * ratio
        let width = min(maximumWidth, max(animationSize.width + left + right, targetWidth, naturalText.width + left + right))
        let textWidth = max(0, width - left - right)
        let measuredText = textlabel.isHidden ? .zero : textlabel.sizeThatFits(CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude))
        let requiredHeight = top + animationSize.height + bottom + (textlabel.isHidden ? 0 : spacing + measuredText.height)
        let height = min(bounds.height, max(baseHeight, requiredHeight))
        let textHeight = min(measuredText.height, max(0, height - top - bottom - spacing))
        animationSize.height = min(animationSize.height, max(0, height - top - bottom - spacing - textHeight))
        let stackHeight = animationSize.height + (textlabel.isHidden ? 0 : spacing + textHeight)
        let startY = top + max(0, height - top - bottom - stackHeight) / 2
        panel.frame = CGRect(x: bounds.midX - width / 2, y: bounds.midY - height / 2, width: width, height: height)
        let animationView: UIView = loadingAnimation == .indicator ? indicator : imageView
        animationView.frame = CGRect(x: (width - animationSize.width) / 2, y: startY, width: animationSize.width, height: animationSize.height)
        textlabel.frame = CGRect(x: left, y: startY + animationSize.height + spacing, width: textWidth, height: textHeight)
    }

    func showAnimate() {
        guard superview?.wy_loadingView === self else { return }
        isHidden = false
        alpha = 0
        UIView.animate(withDuration: 0.5) { self.alpha = 1 }
    }

    static func dismissLoading(in contentView: UIView, animate: Bool) {
        guard let loadingView = contentView.wy_loadingView else { return }
        contentView.isUserInteractionEnabled = loadingView.interactionEnabled
        contentView.wy_loadingView = nil
        if animate {
            UIView.animate(withDuration: 0.5) { loadingView.alpha = 0 } completion: { _ in
                loadingView.removeActivity()
            }
        } else {
            loadingView.removeActivity()
        }
    }

    func removeActivity() {
        if let host = superview, host.wy_loadingView == nil || host.wy_loadingView === self {
            host.isUserInteractionEnabled = interactionEnabled
        }
        indicator.stopAnimating()
        imageView.stopAnimating()
        removeFromSuperview()
    }
}

extension WYActivity {
    
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
        if (window == controller.view) && (controller.navigationController?.navigationBar.isHidden == false) {
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
            attributed?.wy_setColor([textColor: attributed?.string as Any])
            attributed?.wy_setFont([textFont: attributed?.string as Any])
            attributed?.wy_wordsSpacing(1)
            attributed?.wy_lineSpacing(UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels), rangeValue: attributed?.string, alignment: alignment)
        }else {
            attributed = NSMutableAttributedString(attributedString: content as? NSAttributedString ?? NSAttributedString())
        }
        return attributed!
    }
    
    /// 计算文本控件最合适的宽度
    static func sharedLayoutSize(contentView: UIView, contentLabel: UILabel, minimum: CGFloat, maxWidth: CGFloat, defaultFont: UIFont) -> CGSize {
        
        let textHeight = contentLabel.frame.size.height
        let textWidth = contentLabel.frame.size.width
        
        var contentWidth = minimum;
        
        if textWidth > minimum {
            for line in 1..<(contentLabel.attributedText?.string.count ?? 0) {
                
                var maximum = minimum + (textHeight * CGFloat(line))
                
                if maximum > maxWidth {
                    maximum = maxWidth
                }
                
                if maximum > maxWidth {
                    contentWidth = maxWidth
                    break
                }else {
                    
                    let numberOfLines = textNumberOfLines(controlWidth: maximum, contentLabel: contentLabel, defaultFont: defaultFont)
                    
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
    static func textNumberOfLines(controlWidth: CGFloat = 0, contentLabel: UILabel, defaultFont: UIFont) -> Int {
        
        guard contentLabel.attributedText?.string.isEmpty == false else {
            return 0
        }
        
        let contentWidth: CGFloat = controlWidth > 0 ? controlWidth : contentLabel.frame.size.width
        
        let contentHeight: CGFloat = contentLabel.attributedText?.wy_calculateHeight(controlWidth: contentWidth) ?? 0
        
        let numberOfLines: Int = Int(contentHeight / defaultFont.lineHeight)
        
        return numberOfLines
    }
}

private extension UIView {
    
    var wy_scrollInfoView: WYActivityScrollInfoView? {
        
        set(newValue) {
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.private_wy_scrollInfoView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.private_wy_scrollInfoView) as? WYActivityScrollInfoView
        }
    }
    
    var wy_infoView: WYActivityInfoView? {
        
        set(newValue) {
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.private_wy_infoView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.private_wy_infoView) as? WYActivityInfoView
        }
    }
    
    var wy_loadingView: WYActivityLoadingView? {
        
        set(newValue) {
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.private_wy_loadingView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.private_wy_loadingView) as? WYActivityLoadingView
        }
    }
    
    private struct WYAssociatedKeys {
        static var private_wy_scrollInfoView: UInt8 = 0
        static var private_wy_infoView: UInt8 = 0
        static var private_wy_loadingView: UInt8 = 0
    }
}

extension WYLoadingConfig {
    /// 获取Loading提示窗口默认Gif图
    static func defaultGifInfo() -> WYGifInfo {
        
        var defaultImages: [UIImage] = []
        for index in 0..<8 {
            defaultImages.append(UIImage.wy_find("indicator0" + "\(index + 1)", inBundle: WYSourceBundle(bundleName: "WYActivity", subdirectory: "Indicator")))
        }
        return WYGifInfo(animationImages: defaultImages, animationDuration: 0.8)
    }
    
}
