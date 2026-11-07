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

    /// 表情资源是否放在同名子文件夹中(如WYChatViewEmoji/微笑/[微笑].png + [微笑].gif)
    public var emojiFolders: Bool = false

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

    /// 获取某个表情对应的加载Bundle(emojiFolders为true时subdirectory包含表情名子目录，供wy_animatedParse等需要WYSourceBundle的场景使用)
    public func emojiSourceBundle(for emojiName: String) -> WYSourceBundle? {
        guard emojiFolders, let original = emojiBundle else {
            return emojiBundle
        }
        let base = original.subdirectory.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let plain = emojiName.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        let newSub = base.isEmpty ? plain : base + "/" + plain
        return WYSourceBundle(targetClass: original.targetClass, bundleName: original.bundleName, subdirectory: newSub)
    }

    public init() {}
}

/// 返回一个Bool值来判定各控件的点击或手势事件是否需要内部处理(默认返回true)
@objc public protocol WYChatEmojiViewEventsHandler {
    /// 是否需要内部处理 Emoji 点击事件
    @objc(wy_canManagerEmojiViewClickEvents:indexPath:)
    optional func wy_canManagerEmojiViewClickEvents(_ emojiView: WYChatEmojiView, indexPath: IndexPath) -> Bool

    /// 是否需要内部处理 删除按钮 点击事件
    @objc(wy_canManagerEmojiDeleteViewClickEvents:)
    optional func wy_canManagerEmojiDeleteViewClickEvents(_ deleteView: UIButton) -> Bool
    
    /// 是否需要内部处理 发送按钮 点击事件
    @objc(wy_canManagerEmojiSendViewClickEvents:)
    optional func wy_canManagerEmojiSendViewClickEvents(_ sendView: UIButton) -> Bool
}

@objc public protocol WYChatEmojiViewDelegate {
    
    /// 监听Emoji点击事件
    @objc(wy_didClickEmojiView:indexPath:)
    optional func wy_didClickEmojiView(_ emojiView: WYChatEmojiView, indexPath: IndexPath)

    /// 点击了发送按钮
    @objc(wy_didClickEmojiSendView:)
    optional func wy_didClickEmojiSendView(_ sendView: UIButton)
    
    /// 点击了删除按钮
    @objc(wy_didClickEmojiDeleteView:)
    optional func wy_didClickEmojiDeleteView(_ deleteView: UIButton)
}

public class WYChatEmojiView: UIView, WYEmojiFuncAreaViewDelegate {
    
    public weak var eventsHandler: WYChatEmojiViewEventsHandler? = nil
    
    /// 点击或长按事件代理
    public weak var delegate: WYChatEmojiViewDelegate?
    
    public lazy var collectionView: UICollectionView = wy_makeCollectionView()
    
    public lazy var funcAreaView: WYEmojiFuncAreaView? = wy_makeFuncAreaView()
    
    public lazy var recentlyEmoji: [String] = wy_makeRecentlyEmoji()

    public lazy var dataSource: [[String]] = wy_makeDataSource()
    
    public init() {
        super.init(frame: .zero)
        self.collectionView.backgroundColor = emojiViewConfig.backgroundColor
        self.funcAreaView?.backgroundColor = .clear
    }
    
    public func updateRecentlyEmoji(_ attributedText: NSAttributedString) {
        wy_impl_updateRecentlyEmoji(attributedText)
    }
    
    @objc public func wy_didClickEmojiSendView(_ sendView: UIButton) {
        wy_impl_wy_didClickEmojiSendView(sendView)
    }
    
    @objc public func wy_didClickEmojiDeleteView(_ deleteView: UIButton) {
        wy_impl_wy_didClickEmojiDeleteView(deleteView)
    }

    internal let state = WYChatEmojiViewPrivateState()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension WYChatEmojiView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return wy_impl_numberOfSections(in: collectionView)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return wy_impl_collectionView(collectionView, numberOfItemsInSection: section)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return wy_impl_collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: section)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return wy_impl_collectionView(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section)
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return wy_impl_collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return wy_impl_collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return wy_impl_collectionView(collectionView, layout: collectionViewLayout, referenceSizeForFooterInSection: section)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        wy_impl_collectionView(collectionView, didSelectItemAt: indexPath)
    }
}

extension WYChatEmojiView {

}
