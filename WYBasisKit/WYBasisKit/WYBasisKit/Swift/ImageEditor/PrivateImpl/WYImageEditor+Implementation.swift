//
//  WYImageEditor+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/21.
//

import UIKit

/// 图片编辑器的工具条、编辑操作与结果生成
extension WYImageEditorViewController {

    var editorHeaderHeight: CGFloat {
        let textHeight = [cancelButton, revertButton, doneButton, titleLabel].compactMap { $0.titleLabel?.font.lineHeight }.max() ?? 0
        return max(UIDevice.wy_screenHeight(41, WYBasisKitConfig.defaultScreenPixels), textHeight + UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels))
    }

    var editorModeControlHeight: CGFloat {
        let textHeight = max(cropModeButton.titleLabel?.font.lineHeight ?? 0, markModeButton.titleLabel?.font.lineHeight ?? 0)
        return max(UIDevice.wy_screenHeight(30, WYBasisKitConfig.defaultScreenPixels), ceil(textHeight) + UIDevice.wy_screenHeight(3, WYBasisKitConfig.defaultScreenPixels) * 2)
    }

    func layoutEditorHeader(width: CGFloat, safeTop: CGFloat, safeLeft: CGFloat, safeRight: CGFloat) {
        let gap = UIDevice.wy_screenWidth(11, WYBasisKitConfig.defaultScreenPixels)
        let y = safeTop + UIDevice.wy_screenHeight(4, WYBasisKitConfig.defaultScreenPixels)
        let buttonWidth = UIDevice.wy_screenWidth(56, WYBasisKitConfig.defaultScreenPixels)
        let height = editorHeaderHeight
        cancelButton.frame = CGRect(x: safeLeft + gap, y: y, width: buttonWidth, height: height)
        doneButton.frame = CGRect(x: width - safeRight - UIDevice.wy_screenWidth(75, WYBasisKitConfig.defaultScreenPixels), y: y, width: UIDevice.wy_screenWidth(63, WYBasisKitConfig.defaultScreenPixels), height: height)
        revertButton.frame = CGRect(x: doneButton.frame.minX - gap - buttonWidth, y: y, width: buttonWidth, height: height)
        let leading = cancelButton.frame.maxX + gap
        let trailing = (revertButton.isHidden ? doneButton.frame.minX : revertButton.frame.minX) - gap
        let titleWidth = min(UIDevice.wy_screenWidth(149, WYBasisKitConfig.defaultScreenPixels), max(trailing - leading, 0))
        titleLabel.frame = CGRect(x: leading + max(trailing - leading - titleWidth, 0) / 2, y: y, width: titleWidth, height: height)
        titleLabel.titleLabel?.adjustsFontSizeToFitWidth = true
    }

    func layoutEditorModeControl(width: CGFloat, height: CGFloat, safeLeft: CGFloat, safeRight: CGFloat) {
        let availableWidth = max(width - safeLeft - safeRight, 0)
        let controlWidth = min(UIDevice.wy_screenWidth(186, WYBasisKitConfig.defaultScreenPixels), availableWidth)
        let controlHeight = editorModeControlHeight
        let inset = UIDevice.wy_screenHeight(3, WYBasisKitConfig.defaultScreenPixels)
        let horizontalInset = UIDevice.wy_screenWidth(3, WYBasisKitConfig.defaultScreenPixels)
        modeSegmentedControl.frame = CGRect(x: safeLeft + (availableWidth - controlWidth) / 2, y: (height - controlHeight) / 2, width: controlWidth, height: controlHeight)
        modeSegmentedControl.layer.cornerRadius = controlHeight / 2
        cropModeButton.frame = CGRect(x: horizontalInset, y: inset, width: max(controlWidth / 2 - horizontalInset * 2, 0), height: max(controlHeight - inset * 2, 0))
        markModeButton.frame = CGRect(x: controlWidth / 2 + horizontalInset, y: inset, width: cropModeButton.frame.width, height: cropModeButton.frame.height)
        cropModeButton.layer.cornerRadius = cropModeButton.frame.height / 2
        markModeButton.layer.cornerRadius = markModeButton.frame.height / 2
    }

    func makeMarkerRowScrollView() -> UIScrollView {
        let scrollView = WYImageEditorToolRowScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.delaysContentTouches = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.isDirectionalLockEnabled = true
        return scrollView
    }

    var markerToolRowHeight: CGFloat {
        max(UIDevice.wy_screenHeight(54, WYBasisKitConfig.defaultScreenPixels), UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels) + UIDevice.wy_screenHeight(14, WYBasisKitConfig.defaultScreenPixels))
    }

    var markerColorRowHeight: CGFloat {
        max(UIDevice.wy_screenHeight(37, WYBasisKitConfig.defaultScreenPixels), UIDevice.wy_screenWidth(25, WYBasisKitConfig.defaultScreenPixels) + UIDevice.wy_screenHeight(12, WYBasisKitConfig.defaultScreenPixels))
    }

    var markerStyleRowHeight: CGFloat {
        let contentHeight = max(UIDevice.wy_screenWidth(29, WYBasisKitConfig.defaultScreenPixels), UIFont.boldSystemFont(ofSize: UIFont.wy_fontSize(26, WYBasisKitConfig.defaultScreenPixels)).lineHeight)
        return max(UIDevice.wy_screenHeight(39, WYBasisKitConfig.defaultScreenPixels), contentHeight + UIDevice.wy_screenHeight(10, WYBasisKitConfig.defaultScreenPixels))
    }

    /// 布局标记工具条(第一行五种工具加撤销重做清除放横向滚动容器，第二行颜色圆点，第三行粗细字号档位，后两行可按配置隐藏)
    func layoutMarkerToolbar(width: CGFloat, height: CGFloat, safeLeft: CGFloat, safeRight: CGFloat) {

        let toolCount = markerToolButtons.count + 3
        let itemSize = UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels)
        let rowHeight = markerToolRowHeight
        let itemTop = (rowHeight - itemSize) / 2
        let edgePadding = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels)
        let preferredGap = UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)
        // 按钮间距在最小值到期望值之间弹性收缩，屏宽够时整行放得下不滚动，放不下才贴边排开靠左右滑动查看
        let availableWidth = width - safeLeft - safeRight
        let flexGap = (availableWidth - edgePadding * 2 - CGFloat(toolCount) * itemSize) / CGFloat(toolCount - 1)
        let minimumGap = UIDevice.wy_screenWidth(4, WYBasisKitConfig.defaultScreenPixels)
        let fitsInRow = flexGap >= minimumGap
        let itemGap = fitsInRow ? min(flexGap, preferredGap) : preferredGap
        let contentWidth = CGFloat(toolCount) * itemSize + CGFloat(toolCount - 1) * itemGap
        let rowLeading = edgePadding
        let startX = rowLeading
        toolRowScrollView.frame = CGRect(x: safeLeft, y: 0, width: max(availableWidth, 0), height: rowHeight)
        let scrollContentWidth = max(startX + contentWidth + edgePadding, availableWidth)
        var x = startX
        for button in markerToolButtons {
            button.frame = CGRect(x: x, y: itemTop, width: itemSize, height: itemSize)
            x += itemSize + itemGap
        }
        undoButton.frame = CGRect(x: x, y: itemTop, width: itemSize, height: itemSize)
        x += itemSize + itemGap
        redoButton.frame = CGRect(x: x, y: itemTop, width: itemSize, height: itemSize)
        x += itemSize + itemGap
        clearButton.frame = CGRect(x: x, y: itemTop, width: itemSize, height: itemSize)

        var nextRowY: CGFloat = rowHeight
        // 全区列对齐基准(列中心=第一行工具按钮内图标的中心，列距与工具行同算式，任何屏宽都一致)
        let columnPitch = itemSize + itemGap
        let firstColumnCenter = startX + itemSize / 2
        if configuration.showsColorOptions {
            let colorRowHeight = markerColorRowHeight
            let colorDiameter = UIDevice.wy_screenWidth(25, WYBasisKitConfig.defaultScreenPixels)
            colorRowScrollView.frame = CGRect(x: safeLeft, y: nextRowY, width: max(availableWidth, 0), height: colorRowHeight)
            for (index, button) in colorButtons.enumerated() {
                let columnCenter = firstColumnCenter + CGFloat(index) * columnPitch
                button.frame = CGRect(x: columnCenter - colorDiameter / 2, y: (colorRowHeight - colorDiameter) / 2, width: colorDiameter, height: colorDiameter)
            }
            nextRowY += colorRowHeight
        }
        if configuration.showsStyleOptions {
            styleRowScrollView.frame = CGRect(x: safeLeft, y: nextRowY, width: max(availableWidth, 0), height: markerStyleRowHeight)
            layoutStyleRow(width: scrollContentWidth, y: 0, safeLeft: 0, safeRight: 0, firstColumnCenter: firstColumnCenter, columnPitch: columnPitch)
        }

        for scrollView in [toolRowScrollView, colorRowScrollView, styleRowScrollView] where scrollView.superview != nil {
            let trailingEdge = scrollView.subviews.filter { !$0.isHidden && ($0 is UIButton || $0 is UILabel) }.map { $0.frame.maxX }.max() ?? 0
            scrollView.contentSize = CGSize(width: max(scrollView.bounds.width, trailingEdge + edgePadding), height: scrollView.bounds.height)
            scrollView.contentOffset.x = min(max(scrollView.contentOffset.x, 0), max(scrollView.contentSize.width - scrollView.bounds.width, 0))
            scrollView.isScrollEnabled = scrollView.contentSize.width > scrollView.bounds.width
        }

        // 工具按钮图标在上文字在下(用WYBasisKit的UIButton扩展排版，需在frame落定后调用)
        for button in markerToolButtons {
            button.wy_adjust(position: .imageTopTitleBottom, spacing: 2)
        }
    }

    /// 布局粗细字号档位行(划线语境多两个形态切换按钮，圆点大小示意粗细，字母A大小示意字号)
    func layoutStyleRow(width: CGFloat, y: CGFloat, safeLeft: CGFloat, safeRight: CGFloat, firstColumnCenter: CGFloat, columnPitch: CGFloat) {

        let chipWidth = UIDevice.wy_screenWidth(52, WYBasisKitConfig.defaultScreenPixels)
        let chipHeight = max(UIDevice.wy_screenHeight(27, WYBasisKitConfig.defaultScreenPixels), UIFont.boldSystemFont(ofSize: UIFont.wy_fontSize(26, WYBasisKitConfig.defaultScreenPixels)).lineHeight)
        let buttonWidth = UIDevice.wy_screenWidth(39, WYBasisKitConfig.defaultScreenPixels)
        let buttonHeight = max(UIDevice.wy_screenHeight(29, WYBasisKitConfig.defaultScreenPixels), UIDevice.wy_screenWidth(29, WYBasisKitConfig.defaultScreenPixels))
        let buttonTop = y + (markerStyleRowHeight - buttonHeight) / 2
        // 提示占第1列、档位控件占第2-5列、直线自由胶囊占第6-7列，全部以列中心对齐第一行图标
        let hintWidth = UIDevice.wy_screenWidth(30, WYBasisKitConfig.defaultScreenPixels)
        styleHintLabel.frame = CGRect(x: firstColumnCenter - hintWidth / 2, y: buttonTop, width: hintWidth, height: buttonHeight)
        let dotSizes = [10, 15, 21, 29].map { UIDevice.wy_screenWidth(CGFloat($0), WYBasisKitConfig.defaultScreenPixels) }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, button) in lineWidthDotButtons.enumerated() {
            let columnCenter = firstColumnCenter + CGFloat(index + 1) * columnPitch
            button.frame = CGRect(x: columnCenter - buttonWidth / 2, y: buttonTop, width: buttonWidth, height: buttonHeight)
            if let dotLayer = button.layer.sublayers?.first(where: { $0.name == "widthDot" }) {
                dotLayer.frame = CGRect(x: (buttonWidth - dotSizes[index]) / 2, y: (buttonHeight - dotSizes[index]) / 2, width: dotSizes[index], height: dotSizes[index])
                dotLayer.cornerRadius = dotSizes[index] / 2
                dotLayer.masksToBounds = true
            }
        }
        CATransaction.commit()
        for (index, button) in fontSizeButtons.enumerated() {
            let columnCenter = firstColumnCenter + CGFloat(index + 1) * columnPitch
            button.frame = CGRect(x: columnCenter - buttonWidth / 2, y: y + (markerStyleRowHeight - chipHeight) / 2, width: buttonWidth, height: chipHeight)
        }
        let pairTop = y + (markerStyleRowHeight - UIDevice.wy_screenWidth(29, WYBasisKitConfig.defaultScreenPixels)) / 2
        if !straightChipButton.isHidden {
            layoutChipPair(leadingChip: straightChipButton, trailingChip: freeChipButton, width: width, safeRight: safeRight, firstColumnCenter: firstColumnCenter, columnPitch: columnPitch, chipWidth: chipWidth, top: pairTop)
        }
        if !mosaicBoxChipButton.isHidden {
            layoutChipPair(leadingChip: mosaicBoxChipButton, trailingChip: mosaicBrushChipButton, width: width, safeRight: safeRight, firstColumnCenter: firstColumnCenter, columnPitch: columnPitch, chipWidth: chipWidth, top: pairTop)
        }
        if !watermarkLogoChipButton.isHidden {

            // 图片与平铺是两个独立开关，两颗全圆角小钮并排，左缘固定锚定第6列，右缘超屏时整体左移钳制
            let pairHeight = UIDevice.wy_screenWidth(29, WYBasisKitConfig.defaultScreenPixels)
            let colorDiameter = UIDevice.wy_screenWidth(25, WYBasisKitConfig.defaultScreenPixels)
            let anchorDotLeft = firstColumnCenter + CGFloat(5) * columnPitch - colorDiameter / 2
            let chipGap = UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels)
            let pairWidth = chipWidth * 2 + chipGap
            let pairLeft = min(anchorDotLeft, width - safeRight - UIDevice.wy_screenWidth(4, WYBasisKitConfig.defaultScreenPixels) - pairWidth)
            watermarkLogoChipButton.frame = CGRect(x: pairLeft, y: pairTop, width: chipWidth, height: pairHeight)
            watermarkTileChipButton.frame = CGRect(x: pairLeft + chipWidth + chipGap, y: pairTop, width: chipWidth, height: pairHeight)
        } else if !watermarkTileChipButton.isHidden {

            // 只开平铺没配logo图时平铺钮单独成颗，左缘仍固定锚定第6列
            let pairHeight = UIDevice.wy_screenWidth(29, WYBasisKitConfig.defaultScreenPixels)
            let colorDiameter = UIDevice.wy_screenWidth(25, WYBasisKitConfig.defaultScreenPixels)
            let anchorDotLeft = firstColumnCenter + CGFloat(5) * columnPitch - colorDiameter / 2
            let chipLeft = min(anchorDotLeft, width - safeRight - UIDevice.wy_screenWidth(4, WYBasisKitConfig.defaultScreenPixels) - chipWidth)
            watermarkTileChipButton.layer.cornerRadius = pairHeight / 2
            watermarkTileChipButton.frame = CGRect(x: chipLeft, y: pairTop, width: chipWidth, height: pairHeight)
        }
    }

    /// 布局横跨两列的双段胶囊对(高度与最大粗细圆点同高且圆角取半高成胶囊形，左缘固定对齐第6列圆点的左缘，锚点固定在第6列不随色板增减漂移，右缘超屏时整体左移钳制)
    func layoutChipPair(leadingChip: UIButton, trailingChip: UIButton, width: CGFloat, safeRight: CGFloat, firstColumnCenter: CGFloat, columnPitch: CGFloat, chipWidth: CGFloat, top: CGFloat) {
        let pairHeight = UIDevice.wy_screenWidth(29, WYBasisKitConfig.defaultScreenPixels)
        let pairWidth = columnPitch + chipWidth
        let colorDiameter = UIDevice.wy_screenWidth(25, WYBasisKitConfig.defaultScreenPixels)
        let anchorDotLeft = firstColumnCenter + CGFloat(5) * columnPitch - colorDiameter / 2
        let pairLeft = min(anchorDotLeft, width - safeRight - UIDevice.wy_screenWidth(4, WYBasisKitConfig.defaultScreenPixels) - pairWidth)
        leadingChip.layer.cornerRadius = pairHeight / 2
        trailingChip.layer.cornerRadius = pairHeight / 2
        leadingChip.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        trailingChip.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        leadingChip.frame = CGRect(x: pairLeft, y: top, width: pairWidth / 2, height: pairHeight)
        trailingChip.frame = CGRect(x: pairLeft + pairWidth / 2, y: top, width: pairWidth / 2, height: pairHeight)
    }

    /// 刷新粗细字号档位行(按当前选中与工具语境切换显示内容并点亮生效档位)
    func refreshStyleRow() {
        guard configuration.showsStyleOptions else { return }

        let isTextContext = markerView.contextIsText()
        let isWatermarkContext = markerView.contextIsWatermarkText()
        let isLineContext = markerView.contextIsLineTool()
        let isMosaicContext = markerView.contextIsMosaicTool()
        if isWatermarkContext {
            styleHintLabel.text = configuration.appearance.fontSizeHintText ?? WYLocalized("水印字号", table: WYBasisKitConfig.kitLocalizableTable)
        } else if isTextContext {
            styleHintLabel.text = configuration.appearance.fontSizeHintText ?? WYLocalized("文本字号", table: WYBasisKitConfig.kitLocalizableTable)
        } else {
            styleHintLabel.text = configuration.appearance.lineWidthHintText ?? WYLocalized("画笔粗细", table: WYBasisKitConfig.kitLocalizableTable)
        }
        straightChipButton.isHidden = !isLineContext
        freeChipButton.isHidden = !isLineContext
        mosaicBoxChipButton.isHidden = !isMosaicContext
        mosaicBrushChipButton.isHidden = !isMosaicContext
        watermarkLogoChipButton.isHidden = !isWatermarkContext || configuration.watermarkImage == nil
        watermarkTileChipButton.isHidden = !isWatermarkContext
        lineWidthDotButtons.forEach { $0.isHidden = isTextContext || isWatermarkContext }
        fontSizeButtons.forEach { $0.isHidden = !(isTextContext || isWatermarkContext) }

        let straightActive = markerView.activeStraightLine()
        straightChipButton.isSelected = straightActive
        freeChipButton.isSelected = !straightActive
        straightChipButton.backgroundColor = straightActive ? .white : UIColor(white: 0.22, alpha: 1)
        freeChipButton.backgroundColor = straightActive ? UIColor(white: 0.22, alpha: 1) : .white

        let boxActive = markerView.activeMosaicBoxed()
        mosaicBoxChipButton.isSelected = boxActive
        mosaicBrushChipButton.isSelected = !boxActive
        mosaicBoxChipButton.backgroundColor = boxActive ? .white : UIColor(white: 0.22, alpha: 1)
        mosaicBrushChipButton.backgroundColor = boxActive ? UIColor(white: 0.22, alpha: 1) : .white

        watermarkLogoChipButton.isSelected = markerView.watermarkUsesLogo
        watermarkLogoChipButton.backgroundColor = markerView.watermarkUsesLogo ? .white : UIColor(white: 0.22, alpha: 1)
        watermarkTileChipButton.isSelected = markerView.watermarkTiled
        watermarkTileChipButton.backgroundColor = markerView.watermarkTiled ? .white : UIColor(white: 0.22, alpha: 1)

        let widthIndex = markerView.activeLineWidthIndex()
        for (index, button) in lineWidthDotButtons.enumerated() {
            let dotColor = index == widthIndex ? configuration.appearance.accentColor : UIColor.white
            button.layer.sublayers?.first(where: { $0.name == "widthDot" })?.backgroundColor = dotColor.cgColor
        }
        let fontIndex = markerView.activeFontSizeIndex()
        let fontSizes = [12, 15, 20, 26].map { UIFont.wy_fontSize(CGFloat($0), WYBasisKitConfig.defaultScreenPixels) }
        for (index, button) in fontSizeButtons.enumerated() {
            let color: UIColor = index == fontIndex ? configuration.appearance.accentColor : UIColor.white
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: fontSizes[index]), .foregroundColor: color]
            button.setAttributedTitle(NSAttributedString(string: "A", attributes: attributes), for: .normal)
        }
        view.setNeedsLayout()
    }

    /// 弹出文本输入弹窗(新建文本或水印、修改选中的文本或水印时用，标题按语境传)
    func showTextInputAlert(existingText: String?, title: String, completion: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = existingText
            textField.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable), style: .cancel) { _ in
            completion(nil)
        })
        alert.addAction(UIAlertAction(title: WYLocalized("完成", table: WYBasisKitConfig.kitLocalizableTable), style: .default) { [weak alert] _ in
            completion(alert?.textFields?.first?.text)
        })
        present(alert, animated: true)
    }

    /// 点取消(直接丢弃编辑并回调取消)
    @objc func cancelButtonTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.onCancel?()
            self.editorDelegate?.wy_imageEditorViewControllerDidCancel?(self)
        }
    }

    /// 点还原或清除(按页面区分语义，裁剪页面恢复图片至裁剪前、全部裁剪回退且标记保留，标记页面清除全部标记且裁剪保留)
    @objc func revertButtonTapped() {
        suppressOperationRecording = true
        if isMarkMode {
            markerView.removeAllMarkers()
        } else {
            _ = cropperView.undoAllCrops()
        }
        operationStack.removeAll()
        redoOperationStack.removeAll()
        suppressOperationRecording = false
    }

    /// 点完成(按当前裁剪范围与标记合成成品图，回调后关闭编辑器)
    @objc func doneButtonTapped() {
        let result = renderEditedImage()
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.onFinish?(result)
            self.editorDelegate?.wy_imageEditorViewController?(self, didFinishEditing: result)
        }
    }

    /// 切到裁剪模式(显示裁剪视图，标记先记在图上不丢)
    @objc func cropModeButtonTapped() {
        guard isMarkMode else { return }
        setMarkMode(false)
    }

    /// 切到标记模式(按当前裁剪框取景显示，标记画在图上跟着内容走)
    @objc func markModeButtonTapped() {
        guard !isMarkMode else { return }
        setMarkMode(true)
    }

    /// 记录一步用户操作进统一撤销栈(内部恢复动作不记录)
    func recordOperation(_ isMarkerOperation: Bool) {
        guard !suppressOperationRecording else { return }
        operationStack.append(isMarkerOperation)
        redoOperationStack.removeAll()
    }

    /// 刷新顶部标题按钮(仅裁剪模式显示裁剪确认按钮，标记模式整颗隐藏不占位)
    func refreshTitleForPendingCrop() {
        let showCropButton = !isMarkMode && configuration.allowsCropping
        titleLabel.isHidden = !showCropButton
        if showCropButton {
            titleLabel.setTitle(WYLocalized("裁剪", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
            titleLabel.setTitleColor(configuration.appearance.topBarCropButtonColor, for: .normal)
        }
    }

    /// 点顶部裁剪按钮(按当前框立即真裁，页面只显示裁剪后的图，与还原互逆)
    @objc func titleButtonTapped() {
        guard !isMarkMode, configuration.allowsCropping else { return }
        cropperView.commitCrop(force: true)
    }

    /// 刷新模式分段控件的胶囊选中样式(选中的铺底色配文字色，未选中透明)
    func refreshModeSegmented() {
        let selectedBackground = configuration.appearance.segmentedSelectedBackgroundColor
        let selectedText = configuration.appearance.segmentedSelectedTextColor
        let normalText = configuration.appearance.segmentedTextColor
        cropModeButton.backgroundColor = cropModeButton.isSelected ? selectedBackground : .clear
        cropModeButton.setTitleColor(cropModeButton.isSelected ? selectedText : normalText, for: .normal)
        markModeButton.backgroundColor = markModeButton.isSelected ? selectedBackground : .clear
        markModeButton.setTitleColor(markModeButton.isSelected ? selectedText : normalText, for: .normal)
    }

    /// 切换裁剪与标记模式(带淡入淡出，进标记前先把用户调过的裁剪框应用掉)
    func setMarkMode(_ marking: Bool) {
        if marking, configuration.allowsCropping {
            cropperView.commitCrop()
        }
        isMarkMode = marking
        cropModeButton.isSelected = !marking
        markModeButton.isSelected = marking
        // 顶部标题固定显示编辑二字，当前模式由底部分段胶囊表达(标题随模式变会像可点按钮造成误解)
        refreshTitleForPendingCrop()

        // 标记模式清除入口在底部工具行故顶栏隐藏，裁剪模式保留(一键回退全部裁剪用)
        revertButton.isHidden = marking
        refreshModeSegmented()
        markerToolbar.isHidden = !marking

        if marking {
            refreshMarkerDisplayRegion()
            self.markerView.alpha = 0
            self.markerView.isHidden = false
            self.cropperView.isHidden = true
            UIView.animate(withDuration: 0.2, animations: {
                self.markerView.alpha = 1
            })
        } else {
            self.cropperView.alpha = 0
            self.cropperView.isHidden = false
            self.markerView.isHidden = true
            UIView.animate(withDuration: 0.2, animations: {
                self.cropperView.alpha = 1
            })
        }
        view.setNeedsLayout()
    }

    /// 当前取景区域(允许裁剪时为裁剪框映射，纯标记模式为整张基准图)
    func currentCropRegion() -> CGRect {
        if !configuration.allowsCropping {
            let size = cropperView.currentBaseImage.size
            return CGRect(origin: .zero, size: size)
        }
        return cropperView.cropRectInImageCoordinates()
    }

    /// 让标记视图取景(自由模式进标记前已应用裁剪，显示整张基准图，固定尺寸模式按取景框显示)
    func refreshMarkerDisplayRegion() {
        if configuration.cropSize == .zero {
            let size = cropperView.currentBaseImage.size
            markerView.updateDisplayRegion(CGRect(origin: .zero, size: size))
        } else {
            markerView.updateDisplayRegion(currentCropRegion())
        }
    }

    /// 点标记工具(选中后拖动画布生成对应标记，文本工具点画布弹输入)
    @objc func markerToolButtonTapped(_ sender: UIControl) {
        guard let type = WYImageMarkerType(rawValue: sender.tag) else { return }
        markerToolButtons.forEach { $0.isSelected = ($0 == sender) }
        markerView.activeTool = type
        markerView.deselectMarker()
    }

    /// 点撤销(统一时间线逐步回退，标记与裁剪按操作先后撤销)
    @objc func undoButtonTapped() {
        guard let isMarkerOperation = operationStack.popLast() else { return }
        redoOperationStack.append(isMarkerOperation)
        suppressOperationRecording = true
        if isMarkerOperation {
            markerView.undoLastMarker()
        } else {
            _ = cropperView.undoLastCrop()
        }
        suppressOperationRecording = false
    }

    /// 点重做(统一时间线逐步恢复，与撤销对称)
    @objc func redoButtonTapped() {
        guard let isMarkerOperation = redoOperationStack.popLast() else { return }
        operationStack.append(isMarkerOperation)
        suppressOperationRecording = true
        if isMarkerOperation {
            markerView.redoLastMarker()
        } else {
            _ = cropperView.redoCrop()
        }
        suppressOperationRecording = false
    }

    /// 点直线或自由按钮(把划线形态切到点的那边，选中的划线也会跟着转换)
    @objc func lineShapeChipTapped(_ sender: UIControl) {
        let wantStraight = sender === straightChipButton
        if markerView.activeStraightLine() != wantStraight {
            markerView.toggleStraightLine()
        }
        refreshStyleRow()
    }

    /// 点框选或涂抹按钮(把马赛克默认形态切到点的那边，只影响之后新建的马赛克)
    @objc func mosaicShapeChipTapped(_ sender: UIControl) {
        let wantBox = sender === mosaicBoxChipButton
        if markerView.activeMosaicBoxed() != wantBox {
            markerView.toggleMosaicShape()
        }
        refreshStyleRow()
    }

    /// 点水印图片按钮(切换之后落的水印是否带上logo)
    @objc func watermarkLogoChipTapped(_ sender: UIControl) {
        markerView.watermarkUsesLogo.toggle()
        refreshStyleRow()
    }

    /// 点水印平铺按钮(切换之后落的水印是整图平铺还是单条)
    @objc func watermarkTileChipTapped(_ sender: UIControl) {
        markerView.watermarkTiled.toggle()
        refreshStyleRow()
    }

    /// 点线宽圆点(有选中标记改它的线宽，没有就改默认线宽影响之后的标记)
    @objc func lineWidthDotTapped(_ sender: UIControl) {
        let presets = markerView.presetLineWidths()
        guard sender.tag < presets.count else { return }
        markerView.applyLineWidth(presets[sender.tag])
        refreshStyleRow()
    }

    /// 点字号按钮(有选中文本标记改它的字号，没有就改默认字号影响之后的文本)
    @objc func fontSizeButtonTapped(_ sender: UIControl) {
        let presets = markerView.presetFontSizes()
        guard sender.tag < presets.count else { return }
        markerView.applyFontSize(presets[sender.tag])
        refreshStyleRow()
    }

    /// 点颜色圆点(有选中标记直接改它，没有就当作之后标记的颜色)
    @objc func colorButtonTapped(_ sender: UIButton) {
        guard let index = colorButtons.firstIndex(of: sender), configuration.appearance.markerPalette.indices.contains(index) else { return }
        markerView.applyColor(configuration.appearance.markerPalette[index])
        refreshColorSelection(color: configuration.appearance.markerPalette[index])
    }

    /// 刷新颜色圆点选中态(选中的颜色加一圈白描边)
    func refreshColorSelection(color: UIColor) {
        let values = configuration.appearance.markerPalette
        for (index, button) in colorButtons.enumerated() {
            button.layer.borderWidth = values[index] == color ? 3 : 1
            button.layer.borderColor = values[index] == color ? UIColor.white.cgColor : UIColor(white: 1, alpha: 0.35).cgColor
        }
    }

    /// 合成成品图(先按裁剪框裁出区域再叠加标记，圆形裁剪时四角抠成透明)
    func renderEditedImage() -> UIImage {
        let baseImage = cropperView.currentBaseImage
        var region = currentCropRegion()
        region.size.width = max(region.size.width, 1)
        region.size.height = max(region.size.height, 1)

        let isCircle = configuration.cropShape == .circle
        let outputSize: CGSize
        if configuration.cropSize != .zero {
            if isCircle {
                let diameter = min(configuration.cropSize.width, configuration.cropSize.height)
                outputSize = CGSize(width: diameter, height: diameter)
            } else {
                outputSize = configuration.cropSize
            }
        } else if isCircle {
            let diameter = min(region.width, region.height)
            outputSize = CGSize(width: diameter, height: diameter)
        } else {
            outputSize = region.size
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = configuration.cropSize == .zero ? baseImage.scale : 1
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        return renderer.image { rendererContext in

            let context = rendererContext.cgContext
            if isCircle {
                context.saveGState()
                let circleRect = CGRect(origin: .zero, size: outputSize).insetBy(dx: 0.5, dy: 0.5)
                context.addEllipse(in: circleRect)
                context.clip()
            }

            let scaleX = outputSize.width / region.width
            let scaleY = outputSize.height / region.height
            context.translateBy(x: -region.origin.x * scaleX, y: -region.origin.y * scaleY)
            context.scaleBy(x: scaleX, y: scaleY)
            baseImage.draw(in: CGRect(origin: .zero, size: baseImage.size))

            markerView.drawMarkers(in: context)

            if isCircle {
                context.restoreGState()
            }
        }
    }
}

/// 工具行滚动容器(手指落在工具按钮上拖动时取消按钮触摸转成滚动，任何位置都能左右滑，点按不受触摸延时)
class WYImageEditorToolRowScrollView: UIScrollView {

    /// 触摸落在按钮上开始拖动时允许取消按钮触摸接管滚动(系统默认对UIControl不取消，按住按钮就拖不动列表)
    override func touchesShouldCancel(in view: UIView) -> Bool {
        return view is UIControl
    }
}
