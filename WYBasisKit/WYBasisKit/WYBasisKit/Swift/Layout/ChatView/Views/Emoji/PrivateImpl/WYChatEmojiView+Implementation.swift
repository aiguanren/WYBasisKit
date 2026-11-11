//
//  WYChatEmojiView+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit
import SnapKit

final class WYChatEmojiViewPrivateState {
    var lastWidth: CGFloat = -1
    var preview: WYEmojiPreviewView?

    var appendEmoji: [String] = []
    var longPressIndexPath: IndexPath?
}

let emojiViewRecentlyCountKey: String = "emojiViewRecentlyCountKey"

let emojiPath: String = Bundle(path: (((Bundle(for: WYChatEmojiView.self).path(forResource: "WYChatView", ofType: "bundle")) ?? (Bundle.main.path(forResource: "WYChatView", ofType: "bundle"))) ?? ""))?.path(forResource: "WYChatViewEmoji", ofType: "plist") ?? ""

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

    /// 拼接表情文件的完整路径(emojiFolders时在subdirectory后加表情名子目录)
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
        let baseSubDir = config.subdirectory.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let subDir = {
            if emojiFolders {
                let plain = emojiName.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                return baseSubDir.isEmpty ? plain : baseSubDir + "/" + plain
            }
            return baseSubDir
        }()
        for searchBundle in searchBundles {
            if let bundlePath = searchBundle.path(forResource: config.bundleName, ofType: "bundle"),
               let resourceBundle = Bundle(path: bundlePath) {
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

extension WYChatEmojiView {

    func wy_makeCollectionView() -> UICollectionView {

        let minimumInteritemSpacing: CGFloat = 0

        let collectionView: UICollectionView = UICollectionView.wy_shared(scrollDirection: .vertical, minimumLineSpacing: self.emojiViewConfig.minimumLineSpacing, minimumInteritemSpacing: minimumInteritemSpacing, itemSize: self.emojiViewConfig.itemSize, delegate: self, dataSource: self, superView: self)
        collectionView.accessibilityIdentifier = "WYChatEmoji.items"
        collectionView.register(WYEmojiViewCell.self, forCellWithReuseIdentifier: "WYEmojiViewCell")
        collectionView.register(WYEmojiHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "WYEmojiHeaderView")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "UICollectionReusableView")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "UICollectionReusableView")
        collectionView.isPagingEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-self.emojiViewConfig.collectionViewBottomOffset)
        }

        // 长按预览手势
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressEmoji(_:)))
        let duration = emojiViewConfig.previewConfig.minimumPressDuration
        let movement = emojiViewConfig.previewConfig.allowableMovement
        longPress.minimumPressDuration = duration.isFinite ? max(0, duration) : 0.5
        longPress.allowableMovement = movement.isFinite ? max(0, movement) : 0
        collectionView.addGestureRecognizer(longPress)

        return collectionView
    }

    func wy_makeFuncAreaView() -> WYEmojiFuncAreaView? {

        guard self.emojiViewConfig.funcAreaConfig.show == true else {
            return nil
        }

        let funcAreaView: WYEmojiFuncAreaView = WYEmojiFuncAreaView(config: emojiViewConfig)
        funcAreaView.delegate = self
        addSubview(funcAreaView)
        funcAreaView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: self.emojiViewConfig.funcAreaConfig.deleteViewLeftOffsetWithArea + self.emojiViewConfig.funcAreaConfig.deleteViewSize.width + self.emojiViewConfig.funcAreaConfig.sendViewLeftOffsetWithDeleteView + self.emojiViewConfig.funcAreaConfig.sendViewSize.width, height: self.emojiViewConfig.funcAreaConfig.areaHeight))
            make.right.equalToSuperview().offset(-self.emojiViewConfig.funcAreaConfig.areaRightOffset)
            make.bottom.equalToSuperview().offset(-self.emojiViewConfig.funcAreaConfig.areaBottomOffset)
        }
        return funcAreaView
    }

    func wy_makeRecentlyEmoji() -> [String] {

        guard self.emojiViewConfig.showRecently == true else {
            return []
        }

        let recentlyEmoji = UserDefaults.standard.array(forKey: emojiViewConfig.recentlyStorageKey) as? [String] ?? []
        return Array(recentlyEmoji.prefix(max(0, emojiViewConfig.recentlyCount)))
    }

    func wy_makeDataSource() -> [[String]] {
        var dataSource: [[String]] = []
        if (self.emojiViewConfig.showRecently == true) && (recentlyEmoji.isEmpty == false) {
            dataSource.append(recentlyEmoji)
        }

        if (self.emojiViewConfig.funcAreaConfig.show == true) && (self.emojiViewConfig.funcAreaConfig.wrapLastLineOfEmoji == true) {

            let flowLayout: UICollectionViewFlowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout

            var leftx: CGFloat = self.emojiViewConfig.sectionInset.left
            var line: Int = 0
            for _: Int in 0..<self.emojiViewConfig.minimumLineCount {
                leftx += self.emojiViewConfig.itemSize.width
                if leftx > (self.wy_width - self.emojiViewConfig.funcAreaConfig.deleteViewLeftOffsetWithArea - self.emojiViewConfig.funcAreaConfig.areaRightOffset - self.emojiViewConfig.funcAreaConfig.sendViewRightOffset - self.emojiViewConfig.funcAreaConfig.sendViewSize.width - self.emojiViewConfig.funcAreaConfig.deleteViewSize.width - self.emojiViewConfig.funcAreaConfig.sendViewLeftOffsetWithDeleteView) {
                    break
                }
                leftx += flowLayout.minimumInteritemSpacing
                line += 1
            }

            var offsetCount: Int = 0
            let residual: Int = (self.emojiViewConfig.emojiSource.count % self.emojiViewConfig.minimumLineCount)

            if residual > line {
                offsetCount = (residual - line)
            }
            if residual == 0 {
                offsetCount = (self.emojiViewConfig.minimumLineCount - line)
            }

            var emojiSource: [String] = []
            emojiSource.append(contentsOf: self.emojiViewConfig.emojiSource)
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
            dataSource.append(self.emojiViewConfig.emojiSource)
        }
        return dataSource
    }

    var appendEmoji: [String] {
        get { return state.appendEmoji }
        set { state.appendEmoji = newValue }
    }

    /// 长按手势当前指向的表情indexPath(拖动切换预览用，nil表示手指在表情有效区外)
    var longPressIndexPath: IndexPath? {
        get { return state.longPressIndexPath }
        set { state.longPressIndexPath = newValue }
    }

    func wy_impl_updateRecentlyEmoji(_ attributedText: NSAttributedString) {
        guard self.emojiViewConfig.showRecently == true, self.emojiViewConfig.recentlyCount > 0 else {
            return
        }
        attributedText.enumerateAttribute(NSAttributedString.Key.attachment, in: NSMakeRange(0, attributedText.string.utf16.count), options: NSAttributedString.EnumerationOptions.longestEffectiveRangeNotRequired) { value, range, stop in
            if value is WYTextAttachment {
                // 拿到文本附件
                let attachment: WYTextAttachment = value as! WYTextAttachment
                let emoji: String = String(format: "%@", attachment.imageName)
                // 更新最近使用的表情
                var recently: [String] = UserDefaults.standard.array(forKey: emojiViewConfig.recentlyStorageKey) as? [String] ?? []
                let retainedCount = max(recently.count, self.emojiViewConfig.recentlyCount)
                if recently.contains(emoji) {
                    recently.remove(at: recently.firstIndex(of: emoji)!)
                }
                recently.insert(emoji, at: 0)
                recently = Array(recently.prefix(retainedCount))
                UserDefaults.standard.setValue(recently, forKey: emojiViewConfig.recentlyStorageKey)
                recently = Array(recently.prefix(self.emojiViewConfig.recentlyCount))

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

    func wy_impl_wy_didClickEmojiSendView(_ sendView: UIButton) {

        if let sendView: UIButton = funcAreaView?.sendView {
            guard (eventsHandler?.wy_canManagerEmojiSendViewClickEvents?(sendView) ?? true) else {
                return
            }
        }
        delegate?.wy_didClickEmojiSendView?(sendView)
    }

    func wy_impl_wy_didClickEmojiDeleteView(_ deleteView: UIButton) {
        if let deleteView: UIButton = funcAreaView?.deleteView {
            guard (eventsHandler?.wy_canManagerEmojiDeleteViewClickEvents?(deleteView) ?? true) else {
                return
            }
        }
        delegate?.wy_didClickEmojiDeleteView?(deleteView)
    }

    func sectionInset(_ section: Int) -> UIEdgeInsets {

        if appendEmoji.isEmpty == true {
            return self.emojiViewConfig.sectionInset
        }else {
            if section == (dataSource.count - 1) {
                return UIEdgeInsets(top: self.emojiViewConfig.minimumLineSpacing, left: self.emojiViewConfig.sectionInset.left, bottom: self.emojiViewConfig.sectionInset.bottom, right: self.emojiViewConfig.sectionInset.right)
            }else {

                if (self.emojiViewConfig.showRecently == true) && (recentlyEmoji.isEmpty == false) {

                    if section == 0 {
                        return UIEdgeInsets(top: self.emojiViewConfig.recentlySectionInset.top, left: self.emojiViewConfig.recentlySectionInset.left, bottom: self.emojiViewConfig.recentlySectionInset.bottom, right: self.emojiViewConfig.recentlySectionInset.right)
                    }else {
                        return UIEdgeInsets(top: self.emojiViewConfig.sectionInset.top, left: self.emojiViewConfig.sectionInset.left, bottom: 0, right: self.emojiViewConfig.sectionInset.right)
                    }
                }else {
                    return UIEdgeInsets(top: self.emojiViewConfig.sectionInset.top, left: self.emojiViewConfig.sectionInset.left, bottom: 0, right: self.emojiViewConfig.sectionInset.right)
                }
            }
        }
    }

    func wy_impl_numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }

    func wy_impl_collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }

    func wy_impl_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

        if (recentlyEmoji.isEmpty == false) && (self.emojiViewConfig.showRecently == true) {
            if (section == 0) {
                return self.emojiViewConfig.recentlySectionInset
            }else {
                return sectionInset(section)
            }
        }else {
            return sectionInset(section)
        }
    }

    func wy_impl_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard (recentlyEmoji.isEmpty == false) && (self.emojiViewConfig.showRecently == true)  else {
            return CGSize.zero
        }
        return CGSize(width: wy_width, height: (section < 2) ? self.emojiViewConfig.headerHeight : 0)
    }

    func wy_impl_collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        guard (recentlyEmoji.isEmpty == false) && (self.emojiViewConfig.showRecently == true)  else {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "UICollectionReusableView", for: indexPath)
        }

        if (kind == UICollectionView.elementKindSectionHeader) && (indexPath.section < 2) {
            let headerView: WYEmojiHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "WYEmojiHeaderView", for: indexPath) as! WYEmojiHeaderView
            headerView.emojiViewConfig = emojiViewConfig
            headerView.textView.font = emojiViewConfig.headerTextFont
            headerView.textView.textColor = emojiViewConfig.headerTextColor
            headerView.backgroundColor = emojiViewConfig.headerBackgroundColor
            headerView.textView.text = [self.emojiViewConfig.recentlyHeaderText, self.emojiViewConfig.totalHeaderText][indexPath.section]
            return headerView
        }
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "UICollectionReusableView", for: indexPath)
    }

    func wy_impl_collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell: WYEmojiViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "WYEmojiViewCell", for: indexPath) as! WYEmojiViewCell
        cell.emojiViewConfig = emojiViewConfig
        cell.emoji = dataSource[indexPath.section][indexPath.item]

        return cell
    }

    func wy_impl_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }

    func wy_impl_collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard (eventsHandler?.wy_canManagerEmojiViewClickEvents?(self, indexPath: indexPath) ?? true) else {
            return
        }
        collectionView.deselectItem(at: indexPath, animated: true)
        delegate?.wy_didClickEmojiView?(self, indexPath: indexPath)
    }

    /// 长按表情的状态机(began弹出预览浮层，changed拖动时反查手指指向并切换预览，ended松手只收起预览不选中任何表情，滑出有效区隐藏预览)
    @objc func didLongPressEmoji(_ sender: UILongPressGestureRecognizer) {

        let location: CGPoint = sender.location(in: collectionView)
        let indexPath: IndexPath? = collectionView.indexPathForItem(at: location)

        switch sender.state {
        case .began:

            guard let indexPath: IndexPath = indexPath else {
                return
            }

            longPressIndexPath = indexPath
            wy_showEmojiPreview(dataSource[indexPath.section][indexPath.item], according: emojiImageView(at: indexPath))
            break

        case .changed:

            if let indexPath: IndexPath = indexPath {
                state.preview?.isHidden = false
                if indexPath != longPressIndexPath {
                    longPressIndexPath = indexPath
                    state.preview?.update(emoji: dataSource[indexPath.section][indexPath.item], according: emojiImageView(at: indexPath))
                }
            }else {
                // 手指滑到header、行间距、删除键、面板外等无效区域
                longPressIndexPath = nil
                state.preview?.isHidden = true
            }
            break

        case .ended, .cancelled, .failed:

            longPressIndexPath = nil
            state.preview?.dismiss()
            state.preview = nil
            break

        default:
            break
        }
    }

    /// 取indexPath对应cell的表情图(作为预览浮层的锚点)
    func emojiImageView(at indexPath: IndexPath) -> UIImageView {
        return (collectionView.cellForItem(at: indexPath) as? WYEmojiViewCell)?.emojiView ?? UIImageView()
    }
}

extension WYChatEmojiView {
    func wy_showEmojiPreview(_ emoji: String, according: UIView) {
        state.preview?.dismiss()
        guard emojiViewConfig.previewConfig.show, let parent = window else { return }
        let preview = WYEmojiPreviewView(config: emojiViewConfig, emoji: emoji)
        state.preview = preview
        parent.addSubview(preview)
        preview.update(emoji: emoji, according: according)
        preview.alpha = 1
    }
}

extension WYChatEmojiView {
    func wy_layoutEmoji() {
        guard bounds.width > 0, state.lastWidth != bounds.width,
              let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        state.lastWidth = bounds.width
        let columns = max(1, emojiViewConfig.minimumLineCount)
        let available = max(1, bounds.width - emojiViewConfig.sectionInset.left - emojiViewConfig.sectionInset.right)
        let width = min(max(1, emojiViewConfig.itemSize.width), available / CGFloat(columns))
        flow.itemSize = CGSize(width: width, height: max(1, emojiViewConfig.itemSize.height))
        flow.minimumInteritemSpacing = columns > 1 ? max(0, (available - CGFloat(columns) * width) / CGFloat(columns - 1)) : 0
        flow.minimumLineSpacing = max(0, emojiViewConfig.minimumLineSpacing)
        flow.invalidateLayout()
    }

    func wy_reloadEmojiConfiguration() {
        state.preview?.dismiss()
        state.preview = nil
        collectionView.removeFromSuperview()
        funcAreaView?.removeFromSuperview()
        recentlyEmoji = wy_makeRecentlyEmoji()
        dataSource = wy_makeDataSource()
        collectionView = wy_makeCollectionView()
        funcAreaView = wy_makeFuncAreaView()
        collectionView.backgroundColor = emojiViewConfig.backgroundColor
        state.lastWidth = -1
        setNeedsLayout()
    }
}
