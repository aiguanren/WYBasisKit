//
//  WYChatEmojiView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/4/3.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit

/// 静态图不存在时从动图取哪一帧
@frozen public enum WYEmojiStaticFramePosition: Int {
    /// 首帧
    case first = 0
    /// 末帧(默认)
    case last
}

public struct WYEmojiViewConfig {
    
    /// 自定义Emoji控件弹起或者收回时动画持续时长
    public var animateDuration: TimeInterval = 0.25

    /// 自定义Emoji控件背景色
    public var backgroundColor: UIColor = .wy_hex("#f6f6f6")

    /// 自定义Emoji控件的高度
    public var contentHeight: CGFloat = UIDevice.wy_screenWidth(350)
    
    /// 自定义Emoji控件内collectionView底部距离Emoji控件底部的偏移量
    public var collectionViewBottomOffset: CGFloat = 0

    /// 自定义Emoji数据源(默认读WYChatView.bundle的WYChatViewEmoji.plist，资源缺失或格式不符时降级为空数组)，示例：["[玫瑰](表情图片名)","[色](表情图片名)","[嘻嘻](表情图片名)"]
    public var emojiSource: [String] = ((try? NSArray(contentsOf: URL(fileURLWithPath: emojiPath), error: ())) as? [String]) ?? []
    
    /// 自定义加载Emoji图片的Bundle
    public var emojiBundle: WYSourceBundle? = WYSourceBundle(bundleName: "WYChatView", subdirectory: "WYChatViewEmoji")

    /// 自定义表情图片加载器(传入表情名和bundle返回UIImage，返回nil时走内部加载链)，适合接入Lottie等内部不支持的格式
    public var customImageLoader: ((_ emojiName: String, _ bundle: WYSourceBundle?) -> UIImage)? = nil

    /// 静态图不存在时从动图取哪一帧当静态图(默认末帧)
    public var staticFramePosition: WYEmojiStaticFramePosition = .last

    /// 自定义Emoji控件是否需要显示最近使用的表情
    public var showRecently: Bool = true
    
    /// 最近使用表情是否需要点击发送后就立即更新
    public var instantUpdatesRecently: Bool = false

    /// 自定义Emoji控件最近使用的表情显示几个(表情默认显示7列，这里就默认设置7个)
    public var recentlyCount: Int = 7

    /// 自定义Emoji控件最近使用表情Header文本(设置后会显示一个Header, 仅限scrollDirection == .vertical时生效)
    public var recentlyHeaderText: String = "最近使用"

    /// 自定义Emoji控件所有表情Header文本(设置后会显示一个Header，仅限scrollDirection == .vertical时生效)
    public var totalHeaderText: String = "所有表情"

    /// 自定义Emoji控件Header文本字体、字号
    public var headerTextFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15))

    /// 自定义Emoji控件Header文本字体颜色
    public var headerTextColor: UIColor = .wy_hex("#1B1B1B")

    /// 自定义Emoji控件HeaderView背景色
    public var headerBackgroundColor: UIColor = .wy_hex("#f6f6f6")

    /// 自定义Emoji控件HeaderView高度
    public var headerHeight: CGFloat = UIDevice.wy_screenWidth(30)

    /// 自定义Emoji控件HeaderView中TextView的偏移量
    public var headerTextOffset: CGPoint = CGPoint(x: UIDevice.wy_screenWidth(15), y: (UIDevice.wy_screenWidth(30) - UIFont.systemFont(ofSize: UIDevice.wy_screenWidth(15)).lineHeight) / 2)

    /// 自定义Emoji控件每行显示几个表情
    public var minimumLineCount: Int = 7

    /// 自定义Emoji控件单元格的Size
    public var itemSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(32), height: UIDevice.wy_screenWidth(32))

    /// 自定义Emoji控件全部表情的sectionInset
    public var sectionInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: UIDevice.wy_screenWidth(15), bottom: UIDevice.wy_screenWidth(20), right: UIDevice.wy_screenWidth(15))

    /// 自定义Emoji控件最近使用分区的sectionInset
    public var recentlySectionInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: UIDevice.wy_screenWidth(15), bottom: UIDevice.wy_screenWidth(15), right: UIDevice.wy_screenWidth(15))

    /// 自定义Emoji控件的行间距
    public var minimumLineSpacing: CGFloat = UIDevice.wy_screenWidth(16)

    /// 自定义Emoji控件右下角功能区配置
    public var funcAreaConfig: WYEmojiFuncAreaConfig = WYEmojiFuncAreaConfig()
    
    /// Emoji表情长按预览控件配置
    public var previewConfig: WYEmojiPreviewConfig = WYEmojiPreviewConfig()
    
    /// 从动态图中获取对应的静态展示图(当表情没有对应的静态图时)
    public func staticEmojiImage(_ emojiName: String) -> UIImage {
        if let customImage = customImageLoader?(emojiName, emojiBundle) {
            return customImage
        }
        if let staticImage = emojiStaticFile(emojiName) {
            return staticImage
        }
        let frameIndex = (staticFramePosition == .first) ? 0 : -1
        for ext in ["gif", "webp"] {
            if let frameImage = emojiAnimatedFrame(emojiName, ext: ext, frameIndex: frameIndex) {
                return frameImage
            }
        }
        return UIImage.wy_find(emojiName, inBundle: emojiBundle)
    }

    public init() {}
}

/// 返回一个Bool值来判定各控件的点击或手势事件是否需要内部处理(默认返回True)
@objc public protocol WYChatEmojiViewEventsHandler {
    /// 是否需要内部处理 Emoji 点击事件
    @objc(canManagerEmojiViewClickEventsWithEmojiView:indexPath:)
    optional func canManagerEmojiViewClickEvents(_ emojiView: WYChatEmojiView, _ indexPath: IndexPath) -> Bool

    /// 是否需要内部处理 删除按钮 点击事件
    @objc(canManagerEmojiDeleteViewClickEventsWithDeleteView:)
    optional func canManagerEmojiDeleteViewClickEvents(_ deleteView: UIButton) -> Bool
    
    /// 是否需要内部处理 发送按钮 点击事件
    @objc(canManagerEmojiSendViewClickEventsWithSendView:)
    optional func canManagerEmojiSendViewClickEvents(_ sendView: UIButton) -> Bool
}

@objc public protocol WYChatEmojiViewDelegate {
    
    /// 监听Emoji点击事件
    @objc(didClickEmojiView:indexPath:)
    optional func didClick(_ emojiView: WYChatEmojiView, _ indexPath: IndexPath)

    /// 点击了发送按钮
    @objc optional func didClickEmojiSendView(_ sendView: UIButton)
    
    /// 点击了删除按钮
    @objc optional func didClickEmojiDeleteView(_ deleteView: UIButton)
}

public class WYChatEmojiView: UIView, WYEmojiFuncAreaViewDelegate {
    
    public weak var eventsHandler: WYChatEmojiViewEventsHandler? = nil
    
    /// 点击或长按事件代理
    public weak var delegate: WYChatEmojiViewDelegate?
    
    public lazy var collectionView: UICollectionView = {
        
        let minimumInteritemSpacing: CGFloat = (UIDevice.wy_screenWidth - emojiViewConfig.sectionInset.left - emojiViewConfig.sectionInset.right - (CGFloat(emojiViewConfig.minimumLineCount) * emojiViewConfig.itemSize.width)) / (CGFloat(emojiViewConfig.minimumLineCount) - 1.0)
        
        let collectionView: UICollectionView = UICollectionView.wy_shared(scrollDirection: .vertical, minimumLineSpacing: emojiViewConfig.minimumLineSpacing, minimumInteritemSpacing: minimumInteritemSpacing, itemSize: emojiViewConfig.itemSize, delegate: self, dataSource: self, superView: self)
        collectionView.register(WYEmojiViewCell.self, forCellWithReuseIdentifier: "WYEmojiViewCell")
        collectionView.register(WYEmojiHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "WYEmojiHeaderView")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "UICollectionReusableView")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "UICollectionReusableView")
        collectionView.isPagingEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-emojiViewConfig.collectionViewBottomOffset)
        }

        // 长按预览手势
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressEmoji(_:)))
        longPress.minimumPressDuration = 0.5
        collectionView.addGestureRecognizer(longPress)
        
        return collectionView
    }()
    
    public lazy var funcAreaView: WYEmojiFuncAreaView? = {
        
        guard emojiViewConfig.funcAreaConfig.show == true else {
            return nil
        }
        
        let funcAreaView: WYEmojiFuncAreaView = WYEmojiFuncAreaView()
        funcAreaView.delegate = self
        addSubview(funcAreaView)
        funcAreaView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: emojiViewConfig.funcAreaConfig.deleteViewLeftOffsetWithArea + emojiViewConfig.funcAreaConfig.deleteViewSize.width + emojiViewConfig.funcAreaConfig.sendViewLeftOffsetWithDeleteView + emojiViewConfig.funcAreaConfig.sendViewSize.width, height: emojiViewConfig.funcAreaConfig.areaHeight))
            make.right.equalToSuperview().offset(-emojiViewConfig.funcAreaConfig.areaRightOffset)
            make.bottom.equalToSuperview().offset(-emojiViewConfig.funcAreaConfig.areaBottomOffset)
        }
        return funcAreaView
    }()
    
    public lazy var recentlyEmoji: [String] = {
        
        guard emojiViewConfig.showRecently == true else {
            return []
        }
        
        var recentlyEmoji: [String] = UserDefaults.standard.array(forKey: emojiViewRecentlyCountKey) as? [String] ?? []
        if recentlyEmoji.count > emojiViewConfig.recentlyCount {
            let range: Range =  Range(NSMakeRange(emojiViewConfig.recentlyCount - 1, recentlyEmoji.count - emojiViewConfig.recentlyCount))!
            recentlyEmoji.replaceSubrange(range, with: [])
            
            UserDefaults.standard.setValue(recentlyEmoji, forKey: emojiViewRecentlyCountKey)
            UserDefaults.standard.synchronize()
        }
        return recentlyEmoji
    }()
    
    private var appendEmoji: [String] = []

    /// 长按手势当前指向的表情indexPath(拖动切换预览用，nil表示手指在表情有效区外)
    private var longPressIndexPath: IndexPath?
    
    public lazy var dataSource: [[String]] = {
        var dataSource: [[String]] = []
        if (emojiViewConfig.showRecently == true) && (recentlyEmoji.isEmpty == false) {
            dataSource.append(recentlyEmoji)
        }
        
        if (emojiViewConfig.funcAreaConfig.show == true) && (emojiViewConfig.funcAreaConfig.wrapLastLineOfEmoji == true) {
            
            let flowLayout: UICollectionViewFlowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            
            var leftx: CGFloat = emojiViewConfig.sectionInset.left
            var line: Int = 0
            for index: Int in 0..<emojiViewConfig.minimumLineCount {
                leftx += emojiViewConfig.itemSize.width
                if leftx > (self.wy_width - emojiViewConfig.funcAreaConfig.deleteViewLeftOffsetWithArea - emojiViewConfig.funcAreaConfig.areaRightOffset - emojiViewConfig.funcAreaConfig.sendViewRightOffset - emojiViewConfig.funcAreaConfig.sendViewSize.width - emojiViewConfig.funcAreaConfig.deleteViewSize.width - emojiViewConfig.funcAreaConfig.sendViewLeftOffsetWithDeleteView) {
                    break
                }
                leftx += flowLayout.minimumInteritemSpacing
                line += 1
            }
            
            var offsetCount: Int = 0
            let residual: Int = (emojiViewConfig.emojiSource.count % emojiViewConfig.minimumLineCount)
            
            if residual > line {
                offsetCount = (residual - line)
            }
            if residual == 0 {
                offsetCount = (emojiViewConfig.minimumLineCount - line)
            }
            
            var emojiSource: [String] = []
            emojiSource.append(contentsOf: emojiViewConfig.emojiSource)
            for _ in 0..<offsetCount {
                let lastEmoji: String = emojiSource.last ?? ""
                emojiSource.removeLast()
                appendEmoji.append(lastEmoji)
            }
            dataSource.append(emojiSource)
            if appendEmoji.isEmpty == false {
                dataSource.append(appendEmoji)
            }
        }else {
            dataSource.append(emojiViewConfig.emojiSource)
        }
        return dataSource
    }()
    
    public init() {
        super.init(frame: .zero)
        self.collectionView.backgroundColor = emojiViewConfig.backgroundColor
        self.funcAreaView?.backgroundColor = .clear
    }
    
    public func updateRecentlyEmoji(_ attributedText: NSAttributedString) {
        guard emojiViewConfig.showRecently == true else {
            return
        }
        
        let _: NSMutableString = NSMutableString(string: attributedText.string)
        attributedText.enumerateAttribute(NSAttributedString.Key.attachment, in: NSMakeRange(0, attributedText.string.utf16.count), options: NSAttributedString.EnumerationOptions.longestEffectiveRangeNotRequired) { value, range, stop in
            if value is WYTextAttachment {
                // 拿到文本附件
                let attachment: WYTextAttachment = value as! WYTextAttachment
                let emoji: String = String(format: "%@", attachment.imageName)
                // 更新最近使用的表情
                var recently: [String] = UserDefaults.standard.array(forKey: emojiViewRecentlyCountKey) as? [String] ?? []
                if recently.contains(emoji) {
                    recently.remove(at: recently.firstIndex(of: emoji)!)
                }
                recently.insert(emoji, at: 0)
                if recently.count > emojiViewConfig.recentlyCount {
                    recently.removeLast()
                }
                UserDefaults.standard.setValue(Array(recently), forKey: emojiViewRecentlyCountKey)
                UserDefaults.standard.synchronize()

                if recentlyEmoji.isEmpty == false {
                    dataSource[0] = Array(recently)
                }else {
                    dataSource.insert(Array(recently), at: 0)
                }

                recentlyEmoji = Array(recently)

                if range == NSMakeRange(0, 1) {
                    collectionView.reloadData()
                }
            }
        }
    }
    
    @objc public func didClickEmojiSendView(_ sendView: UIButton) {
        
        if let sendView: UIButton = funcAreaView?.sendView {
            guard (eventsHandler?.canManagerEmojiSendViewClickEvents?(sendView) ?? true) else {
                return
            }
        }
        delegate?.didClickEmojiSendView?(sendView)
    }
    
    @objc public func didClickEmojiDeleteView(_ deleteView: UIButton) {
        if let deleteView: UIButton = funcAreaView?.deleteView {
            guard (eventsHandler?.canManagerEmojiDeleteViewClickEvents?(deleteView) ?? true) else {
                return
            }
        }
        delegate?.didClickEmojiDeleteView?(deleteView)
    }
    
    private func sectionInset(_ section: Int) -> UIEdgeInsets {
        
        if appendEmoji.isEmpty == true {
            return emojiViewConfig.sectionInset
        }else {
            if section == (dataSource.count - 1) {
                return UIEdgeInsets(top: emojiViewConfig.minimumLineSpacing, left: emojiViewConfig.sectionInset.left, bottom: emojiViewConfig.sectionInset.bottom, right: emojiViewConfig.sectionInset.right)
            }else {
                
                if (emojiViewConfig.showRecently == true) && (recentlyEmoji.isEmpty == false) {
                   
                    if section == 0 {
                        return UIEdgeInsets(top: emojiViewConfig.recentlySectionInset.top, left: emojiViewConfig.recentlySectionInset.left, bottom: emojiViewConfig.recentlySectionInset.bottom, right: emojiViewConfig.recentlySectionInset.right)
                    }else {
                        return UIEdgeInsets(top: emojiViewConfig.sectionInset.top, left: emojiViewConfig.sectionInset.left, bottom: 0, right: emojiViewConfig.sectionInset.right)
                    }
                }else {
                    return UIEdgeInsets(top: emojiViewConfig.sectionInset.top, left: emojiViewConfig.sectionInset.left, bottom: 0, right: emojiViewConfig.sectionInset.right)
                }
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

extension WYChatEmojiView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        if (recentlyEmoji.isEmpty == false) && (emojiViewConfig.showRecently == true) {
            if (section == 0) {
                return emojiViewConfig.recentlySectionInset
            }else {
                return sectionInset(section)
            }
        }else {
            return sectionInset(section)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard (recentlyEmoji.isEmpty == false) && (emojiViewConfig.showRecently == true)  else {
            return CGSize.zero
        }
        return CGSize(width: wy_width, height: (section < 2) ? emojiViewConfig.headerHeight : 0)
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard (recentlyEmoji.isEmpty == false) && (emojiViewConfig.showRecently == true)  else {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "UICollectionReusableView", for: indexPath)
        }
        
        if (kind == UICollectionView.elementKindSectionHeader) && (indexPath.section < 2) {
            let headerView: WYEmojiHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "WYEmojiHeaderView", for: indexPath) as! WYEmojiHeaderView
            headerView.textView.text = [emojiViewConfig.recentlyHeaderText, emojiViewConfig.totalHeaderText][indexPath.section]
            return headerView
        }
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "UICollectionReusableView", for: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell: WYEmojiViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "WYEmojiViewCell", for: indexPath) as! WYEmojiViewCell
        cell.emoji = dataSource[indexPath.section][indexPath.item]
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard (eventsHandler?.canManagerEmojiViewClickEvents?(self, indexPath) ?? true) else {
            return
        }
        collectionView.deselectItem(at: indexPath, animated: true)
        delegate?.didClick?(self, indexPath)
    }
}

extension WYChatEmojiView {

    /// 长按表情的状态机(began弹出预览浮层，changed拖动时反查手指指向并切换预览，ended松手只收起预览不选中任何表情，滑出有效区隐藏预览)
    @objc fileprivate func didLongPressEmoji(_ sender: UILongPressGestureRecognizer) {

        let location: CGPoint = sender.location(in: collectionView)
        let indexPath: IndexPath? = collectionView.indexPathForItem(at: location)

        switch sender.state {
        case .began:

            guard let indexPath: IndexPath = indexPath else {
                return
            }

            longPressIndexPath = indexPath
            WYEmojiPreviewView.show(emoji: dataSource[indexPath.section][indexPath.item], according: emojiImageView(at: indexPath))
            break

        case .changed:

            if let indexPath: IndexPath = indexPath {
                WYEmojiPreviewView.setHidden(false)
                if indexPath != longPressIndexPath {
                    longPressIndexPath = indexPath
                    WYEmojiPreviewView.update(emoji: dataSource[indexPath.section][indexPath.item], according: emojiImageView(at: indexPath))
                }
            }else {
                // 手指滑到header、行间距、删除键、面板外等无效区域
                longPressIndexPath = nil
                WYEmojiPreviewView.setHidden(true)
            }
            break

        case .ended, .cancelled, .failed:

            longPressIndexPath = nil
            WYEmojiPreviewView.dismiss()
            break

        default:
            break
        }
    }

    /// 取indexPath对应cell的表情图(作为预览浮层的锚点)
    private func emojiImageView(at indexPath: IndexPath) -> UIImageView {
        return (collectionView.cellForItem(at: indexPath) as? WYEmojiViewCell)?.emojiView ?? UIImageView()
    }
}

private let emojiViewRecentlyCountKey: String = "emojiViewRecentlyCountKey"

private let emojiPath: String = Bundle(path: (((Bundle(for: WYChatEmojiView.self).path(forResource: "WYChatView", ofType: "bundle")) ?? (Bundle.main.path(forResource: "WYChatView", ofType: "bundle"))) ?? ""))?.path(forResource: "WYChatViewEmoji", ofType: "plist") ?? ""

/// 表情动图取帧缓存(同一路径同一帧只解码一次)
private let wy_emojiFrameCache: NSCache<NSString, UIImage> = {
    let cache = NSCache<NSString, UIImage>()
    cache.countLimit = 256
    return cache
}()

extension WYEmojiViewConfig {

    /// 查找表情的静态图文件(单帧png直接用，多帧apng按staticFramePosition取帧)
    func emojiStaticFile(_ emojiName: String) -> UIImage? {
        guard let filePath = emojiFilePath(emojiName, ext: "png") else {
            return nil
        }
        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: filePath) as CFURL, nil) else {
            return UIImage(contentsOfFile: filePath)
        }
        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 1 else {
            return UIImage(contentsOfFile: filePath)
        }
        let index = (staticFramePosition == .first) ? 0 : frameCount - 1
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
            return UIImage(contentsOfFile: filePath)
        }
        return UIImage(cgImage: cgImage)
    }

    /// 从动图文件中取指定帧(frameIndex传-1表示末帧，带缓存防滚动复用重复解码)
    func emojiAnimatedFrame(_ emojiName: String, ext: String, frameIndex: Int) -> UIImage? {
        guard let filePath = emojiFilePath(emojiName, ext: ext) else {
            return nil
        }
        let cacheKey = "\(filePath)#\(frameIndex)" as NSString
        if let cached = wy_emojiFrameCache.object(forKey: cacheKey) {
            return cached
        }
        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: filePath) as CFURL, nil) else {
            return nil
        }
        let count = CGImageSourceGetCount(source)
        let index = (frameIndex < 0) ? count - 1 : frameIndex
        guard count > 0, index >= 0, index < count,
              let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        wy_emojiFrameCache.setObject(image, forKey: cacheKey)
        return image
    }

    /// 拼接表情文件的完整路径(targetClass所在Bundle → WYChatEmojiView所在Bundle → Bundle.main)
    func emojiFilePath(_ emojiName: String, ext: String) -> String? {
        guard let config = emojiBundle, config.bundleName.isEmpty == false else {
            return nil
        }
        let searchBundles: [Bundle] = {
            if let targetClass = config.targetClass {
                return [Bundle(for: targetClass), Bundle.main]
            } else {
                return [Bundle(for: WYChatEmojiView.self), Bundle.main]
            }
        }()
        for searchBundle in searchBundles {
            if let bundlePath = searchBundle.path(forResource: config.bundleName, ofType: "bundle"),
               let resourceBundle = Bundle(path: bundlePath) {
                let subDir = config.subdirectory.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                if subDir.isEmpty {
                    if let filePath = resourceBundle.path(forResource: emojiName, ofType: ext) {
                        return filePath
                    }
                } else {
                    if let filePath = resourceBundle.path(forResource: emojiName, ofType: ext, inDirectory: subDir) {
                        return filePath
                    }
                }
            }
        }
        return nil
    }
}
