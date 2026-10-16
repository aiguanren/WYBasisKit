//
//  WYImageMarkerView.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/15.
//

import UIKit

/// 单个标记的数据(坐标全部存原图坐标系，裁剪框变化后标记仍锚定在图片内容上)
struct WYImageMarkerItem {

    /// 标记类型
    var type: WYImageMarkerType = .rectangle

    /// 标记边界(文本矩形圆形用，箭头与划线用各自起终点)
    var frame: CGRect = .zero

    /// 箭头起点(图片坐标)
    var startPoint: CGPoint = .zero

    /// 箭头终点(图片坐标)
    var endPoint: CGPoint = .zero

    /// 划线轨迹点(图片坐标，直线形态只有首尾两个点，自由划线为手指经过的全部点)
    var linePoints: [CGPoint] = []

    /// 划线是否为直线形态(直线为首尾两点连线，false为自由划线轨迹)
    var isStraightLine: Bool = false

    /// 文本内容
    var text: String = ""

    /// 标记颜色
    var color: UIColor = .white

    /// 线条宽度(图片坐标)
    var lineWidth: CGFloat = 5

    /// 文本字号(图片坐标)
    var fontSize: CGFloat = 32

    /// 箭头整体边界(起点终点围成的矩形往外扩两个线宽)
    var arrowFrame: CGRect {
        let minX = min(startPoint.x, endPoint.x) - lineWidth * 2
        let minY = min(startPoint.y, endPoint.y) - lineWidth * 2
        let maxX = max(startPoint.x, endPoint.x) + lineWidth * 2
        let maxY = max(startPoint.y, endPoint.y) + lineWidth * 2
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// 划线整体边界(全部轨迹点围成的矩形往外扩两个线宽)
    var lineFrame: CGRect {
        guard let first = linePoints.first else { return .zero }
        var minX = first.x, minY = first.y, maxX = first.x, maxY = first.y
        for point in linePoints {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }
        minX -= lineWidth * 2
        minY -= lineWidth * 2
        maxX += lineWidth * 2
        maxY += lineWidth * 2
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// 标记的有效边界(文本矩形圆形用frame，箭头划线用各自的起终点边界，选中框与命中都用它)
    var effectiveFrame: CGRect {
        if type == .arrow {
            return arrowFrame
        }
        if type == .line {
            return lineFrame
        }
        return frame
    }

    /// 文本排版属性(按标记自身的字号与颜色生成)
    var textAttributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byClipping
        return [.font: UIFont.boldSystemFont(ofSize: fontSize), .foregroundColor: color, .paragraphStyle: paragraph]
    }
}

/// 标记视图(显示裁剪框取景范围内的图片，在上面写字画框画圈画箭头划线，标记可选中拖动缩放删除)
class WYImageMarkerView: UIView {

    /// 文本输入请求回调(参数为已有文本可为nil，回调参数为用户输入，取消时回调nil)
    var onRequestTextEdit: ((String?, @escaping (String?) -> Void) -> Void)?

    /// 选中状态变化回调(点选新建删除撤销后触发，编辑器用它刷新粗细字号颜色选择行)
    var onSelectionChanged: (() -> Void)?

    /// 标记操作上报回调(用户新建删除编辑改样式时触发，编辑器记入统一撤销栈，撤销重做自身不重复上报)
    var onMarkerOperation: (() -> Void)?

    /// 当前选中的标记类型(选中后点画布空白处拖动即生成对应标记，文本工具点空白处弹输入)
    var activeTool: WYImageMarkerType = .text

    /// 划线的默认形态(true为两点连直线，false为跟随手指自由划线，选中划线时可单独转换)
    var lineDrawsStraight = false

    /// 当前默认颜色(改色时没有选中标记就改它，影响之后新建的标记)
    private var currentColor: UIColor = .white

    /// 默认线条宽度(图片坐标，配置传0时按图片宽度自动取值)
    private var defaultLineWidth: CGFloat = 5

    /// 默认文本字号(图片坐标，配置传0时按图片宽度自动取值)
    private var defaultFontSize: CGFloat = 32

    /// 界面外观(选中态虚线删除钮把手与档位倍率都从这里取)
    private var appearance = WYImageEditorAppearance()

    /// 线宽档位的固定基准(进入编辑器时解析一次，点档位只改当前选择不改基准，防档位值滚雪球漂移)
    private var baseLineWidth: CGFloat = 5

    /// 字号档位的固定基准(同线宽基准的理由)
    private var baseFontSize: CGFloat = 32

    /// 要标记的原图
    private var sourceImage: UIImage = UIImage()

    /// 当前显示的图片区域(原图坐标，跟随裁剪框变化)
    private var displayRegion: CGRect = .zero

    /// 全部标记(按绘制顺序排列，后画的盖在前面)
    private var items: [WYImageMarkerItem] = []

    /// 重做栈(撤销时压入，重做时弹出，任何新编辑清空)
    private var redoItems: [WYImageMarkerItem] = []

    /// 当前选中标记的下标(nil表示没有选中)
    private var selectedIndex: Int?

    /// 拖拽模式(把手操作还是移动标记还是新建标记)
    private enum DragMode {
        /// 无动作
        case none
        /// 拖删除把手(直接删掉)
        case deleteMarker
        /// 拖缩放把手(矩形圆形文本调整大小，文本按宽度比例缩放字号，自由划线等比缩放轨迹)
        case resizeMarker
        /// 拖起点把手(箭头与直线划线共用)
        case endpointStart
        /// 拖终点把手(箭头与直线划线共用)
        case endpointEnd
        /// 移动整个标记
        case moveMarker
        /// 新建矩形或圆形
        case createShape
        /// 新建箭头
        case createArrow
        /// 新建划线(直线还是自由由lineDrawsStraight决定)
        case createLine
    }

    /// 当前拖拽模式
    private var dragMode: DragMode = .none

    /// 拖拽开始时的标记数据(移动与缩放基于它算，避免误差累积)
    private var dragStartItem: WYImageMarkerItem?

    /// 拖拽开始的触点(图片坐标，新建与缩放用)
    private var dragStartImagePoint: CGPoint = .zero

    /// 移动标记时触点相对标记左上角的偏移(图片坐标)
    private var moveGrabOffset: CGPoint = .zero

    /**
     * 初始化标记视图内容
     * - Parameters:
     *   - image: 要标记的原图
     *   - defaultColor: 标记默认颜色
     *   - lineWidth: 默认线条宽度(传0按图片宽度自动)
     *   - textFontSize: 默认文本字号(传0按图片宽度自动)
     *   - straightLine: 划线默认形态(true为直线)
     *   - appearance: 界面外观
     */
    func setup(image: UIImage, defaultColor: UIColor, lineWidth: CGFloat, textFontSize: CGFloat, straightLine: Bool, appearance: WYImageEditorAppearance) {
        sourceImage = image
        currentColor = defaultColor
        lineDrawsStraight = straightLine
        self.appearance = appearance
        let baseWidth = max(image.size.width, 1)
        defaultLineWidth = lineWidth > 0 ? lineWidth : min(max(baseWidth / 160, 3), 48)
        defaultFontSize = textFontSize > 0 ? textFontSize : min(max(baseWidth / 18, 16), 220)
        baseLineWidth = defaultLineWidth
        baseFontSize = defaultFontSize
    }

    /// 更新显示区域(切到标记模式或裁剪框变化时按裁剪框取景)
    func updateDisplayRegion(_ region: CGRect) {
        displayRegion = region
        setNeedsDisplay()
    }

    /// 是否还有标记(编辑器逐步还原时先撤标记)
    var hasMarkers: Bool {
        return !items.isEmpty
    }

    /// 回退基准图(逐步还原裁剪时调用，region为当初裁掉的区域，全部标记坐标反向平移回旧基准图坐标)
    func revertCroppedBase(_ previousImage: UIImage, region: CGRect) {
        sourceImage = previousImage
        displayRegion.origin.x += region.origin.x
        displayRegion.origin.y += region.origin.y
        for index in items.indices {
            items[index].frame.origin.x += region.origin.x
            items[index].frame.origin.y += region.origin.y
            items[index].startPoint.x += region.origin.x
            items[index].startPoint.y += region.origin.y
            items[index].endPoint.x += region.origin.x
            items[index].endPoint.y += region.origin.y
            for pointIndex in items[index].linePoints.indices {
                items[index].linePoints[pointIndex].x += region.origin.x
                items[index].linePoints[pointIndex].y += region.origin.y
            }
        }
        setNeedsDisplay()
    }

    /// 换基准图(裁剪视图松手应用裁剪后调用，region为本次裁掉区域在旧基准图中的坐标，全部标记坐标平移保持锚定图片内容)
    func applyCroppedBase(_ croppedImage: UIImage, region: CGRect) {
        sourceImage = croppedImage
        displayRegion.origin.x -= region.origin.x
        displayRegion.origin.y -= region.origin.y
        for index in items.indices {
            items[index].frame.origin.x -= region.origin.x
            items[index].frame.origin.y -= region.origin.y
            items[index].startPoint.x -= region.origin.x
            items[index].startPoint.y -= region.origin.y
            items[index].endPoint.x -= region.origin.x
            items[index].endPoint.y -= region.origin.y
            for pointIndex in items[index].linePoints.indices {
                items[index].linePoints[pointIndex].x -= region.origin.x
                items[index].linePoints[pointIndex].y -= region.origin.y
            }
        }
        setNeedsDisplay()
    }

    /// 取消选中(切工具或切模式时调用)
    func deselectMarker() {
        selectedIndex = nil
        setNeedsDisplay()
        onSelectionChanged?()
    }

    /// 撤销最后一个标记(压入重做栈，重做可恢复)
    func undoLastMarker() {
        guard !items.isEmpty else { return }
        let removed = items.removeLast()
        redoItems.append(removed)
        if selectedIndex == items.count {
            selectedIndex = nil
        }
        setNeedsDisplay()
        onSelectionChanged?()
    }

    /// 重做最近一次撤销的标记(没有可重做的时不生效)
    func redoLastMarker() {
        guard let restored = redoItems.popLast() else { return }
        items.append(restored)
        selectedIndex = items.count - 1
        setNeedsDisplay()
        onSelectionChanged?()
    }

    /// 删除当前选中的标记
    func removeSelectedMarker() {
        guard let index = selectedIndex, items.indices.contains(index) else { return }
        items.remove(at: index)
        selectedIndex = nil
        redoItems.removeAll()
        setNeedsDisplay()
        onMarkerOperation?()
        onSelectionChanged?()
    }

    /// 清空全部标记(编辑器点还原时调用)
    func removeAllMarkers() {
        items.removeAll()
        redoItems.removeAll()
        selectedIndex = nil
        setNeedsDisplay()
        onSelectionChanged?()
    }

    /// 应用颜色(有选中标记改它自己的颜色，没有就改默认颜色影响之后的标记)
    func applyColor(_ color: UIColor) {
        if let index = selectedIndex, items.indices.contains(index) {
            items[index].color = color
        } else {
            currentColor = color
        }
        setNeedsDisplay()
    }

    /// 应用线条宽度(有选中标记改它自己的线宽，没有就改默认线宽影响之后的标记，选中文本时不生效)
    func applyLineWidth(_ width: CGFloat) {
        guard width > 0 else { return }
        if let index = selectedIndex, items.indices.contains(index), items[index].type != .text {
            items[index].lineWidth = width
        } else {
            defaultLineWidth = width
        }
        setNeedsDisplay()
    }

    /// 应用文本字号(有选中文本标记改它自己的字号并重排版，没有就改默认字号影响之后的文本)
    func applyFontSize(_ fontSize: CGFloat) {
        guard fontSize > 0 else { return }
        if let index = selectedIndex, items.indices.contains(index), items[index].type == .text {
            items[index].fontSize = fontSize
            let textSize = (items[index].text as NSString).size(withAttributes: items[index].textAttributes)
            items[index].frame.size = CGSize(width: textSize.width, height: ceil(textSize.height))
        } else {
            defaultFontSize = fontSize
        }
        setNeedsDisplay()
    }

    /// 切换划线形态(选中划线时转换它自己的直线自由形态，没选中就切默认形态影响之后的划线)
    func toggleStraightLine() {
        if let index = selectedIndex, items.indices.contains(index), items[index].type == .line {
            items[index].isStraightLine.toggle()
            if items[index].isStraightLine, items[index].linePoints.count > 2 {

                // 转直线时轨迹收成首尾两点
                let first = items[index].linePoints.first!
                let last = items[index].linePoints.last!
                items[index].linePoints = [first, last]
            }
        } else {
            lineDrawsStraight.toggle()
        }
        setNeedsDisplay()
        onSelectionChanged?()
    }

    /// 界面线宽档位(按外观倍率序列乘固定基准，点档位不会改变基准防止档位值滚雪球)
    func presetLineWidths() -> [CGFloat] {
        return appearance.lineWidthRatios.map { baseLineWidth * $0 }
    }

    /// 界面字号档位(按外观倍率序列乘固定基准，点档位不会改变基准防止档位值滚雪球)
    func presetFontSizes() -> [CGFloat] {
        return appearance.fontSizeRatios.map { baseFontSize * $0 }
    }

    /// 当前生效线宽在档位中的下标(选中文本或没有精确命中时返回nil)
    func activeLineWidthIndex() -> Int? {
        let width: CGFloat
        if let index = selectedIndex, items.indices.contains(index), items[index].type != .text {
            width = items[index].lineWidth
        } else {
            width = defaultLineWidth
        }
        return presetLineWidths().firstIndex(where: { abs($0 - width) < max(0.5, baseLineWidth * 0.05) })
    }

    /// 当前生效字号在档位中的下标(选中的不是文本且文本工具没激活时返回nil)
    func activeFontSizeIndex() -> Int? {
        let fontSize: CGFloat
        if let index = selectedIndex, items.indices.contains(index), items[index].type == .text {
            fontSize = items[index].fontSize
        } else if activeTool == .text {
            fontSize = defaultFontSize
        } else {
            return nil
        }
        return presetFontSizes().firstIndex(where: { abs($0 - fontSize) < max(0.5, baseFontSize * 0.05) })
    }

    /// 当前生效颜色(有选中标记取它的颜色，没有取默认颜色)
    func activeColor() -> UIColor {
        if let index = selectedIndex, items.indices.contains(index) {
            return items[index].color
        }
        return currentColor
    }

    /// 当前生效的划线形态(选中划线取它自己的形态，没有取默认形态)
    func activeStraightLine() -> Bool {
        if let index = selectedIndex, items.indices.contains(index), items[index].type == .line {
            return items[index].isStraightLine
        }
        return lineDrawsStraight
    }

    /// 粗细字号行是否该按文本语境展示(选中文本标记或文本工具激活且无选中)
    func contextIsText() -> Bool {
        if let index = selectedIndex, items.indices.contains(index) {
            return items[index].type == .text
        }
        return activeTool == .text
    }

    /// 当前语境是否划线(选中划线标记或划线工具激活且无选中)
    func contextIsLineTool() -> Bool {
        if let index = selectedIndex, items.indices.contains(index) {
            return items[index].type == .line
        }
        return activeTool == .line
    }

    /// 画布触点转图片坐标(映射含取景区域原点，与标记绘制的变换完全一致)
    private func imagePoint(fromViewPoint viewPoint: CGPoint) -> CGPoint {
        let transform = displayTransform()
        return CGPoint(x: (viewPoint.x - transform.origin.x) / transform.scale + validRegion.origin.x, y: (viewPoint.y - transform.origin.y) / transform.scale + validRegion.origin.y)
    }

    /// 图片坐标转画布触点(映射含取景区域原点，选中框与把手都靠它对齐标记内容)
    private func viewPoint(fromImagePoint imageCoordinate: CGPoint) -> CGPoint {
        let transform = displayTransform()
        return CGPoint(x: (imageCoordinate.x - validRegion.origin.x) * transform.scale + transform.origin.x, y: (imageCoordinate.y - validRegion.origin.y) * transform.scale + transform.origin.y)
    }

    /// 显示区到画布的映射(等比缩放加平移，图片区域完整显示在画布内居中)
    private func displayTransform() -> (scale: CGFloat, origin: CGPoint) {
        guard displayRegion.width > 0, displayRegion.height > 0, bounds.width > 0, bounds.height > 0 else { return (1, .zero) }
        let scale = min(bounds.width / displayRegion.width, bounds.height / displayRegion.height)
        let originX = (bounds.width - displayRegion.width * scale) / 2
        let originY = (bounds.height - displayRegion.height * scale) / 2
        return (scale, CGPoint(x: originX, y: originY))
    }

    /// 标记边界转画布坐标矩形
    private func viewFrame(of item: WYImageMarkerItem) -> CGRect {
        let frame = item.effectiveFrame
        let origin = viewPoint(fromImagePoint: frame.origin)
        let scale = displayTransform().scale
        return CGRect(x: origin.x, y: origin.y, width: frame.width * scale, height: frame.height * scale)
    }

    /// 图片区域(去掉零区域保护后的合法显示范围)
    private var validRegion: CGRect {
        var region = displayRegion
        region.size.width = max(region.width, 1)
        region.size.height = max(region.height, 1)
        return region
    }

    /// 点到线段的距离(划线命中判断用)
    private func distance(from point: CGPoint, toSegment start: CGPoint, end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy
        if lengthSquared == 0 {
            return hypot(point.x - start.x, point.y - start.y)
        }
        let ratio = max(0, min(1, ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared))
        let projected = CGPoint(x: start.x + ratio * dx, y: start.y + ratio * dy)
        return hypot(point.x - projected.x, point.y - projected.y)
    }

    /// 划线轨迹上离触点最近的距离(逐段算取最小)
    private func lineDistance(atImagePoint point: CGPoint, linePoints: [CGPoint]) -> CGFloat {
        guard linePoints.count >= 2 else {
            guard let only = linePoints.first else { return .greatestFiniteMagnitude }
            return hypot(point.x - only.x, point.y - only.y)
        }
        var minimum: CGFloat = .greatestFiniteMagnitude
        for index in 0..<(linePoints.count - 1) {
            minimum = min(minimum, distance(from: point, toSegment: linePoints[index], end: linePoints[index + 1]))
        }
        return minimum
    }

    /// 命中的标记下标(后画的优先，触点按图片坐标判断，划线按轨迹距离命中其余按边界命中)
    private func markerIndex(atImagePoint point: CGPoint) -> Int? {
        let scale = displayTransform().scale
        let padding = 12 / max(scale, 0.001)
        for index in items.indices.reversed() {
            let item = items[index]
            if item.type == .line {
                if lineDistance(atImagePoint: point, linePoints: item.linePoints) <= padding + item.lineWidth {
                    return index
                }
            } else {
                let frame = item.effectiveFrame.insetBy(dx: -padding, dy: -padding)
                if frame.contains(point) { return index }
            }
        }
        return nil
    }

    /// 触点命中的操作把手(删除缩放端点，按画布坐标判断，箭头与直线划线用两端点把手)
    private func handleAtViewPoint(_ point: CGPoint) -> DragMode? {
        guard let index = selectedIndex, items.indices.contains(index) else { return nil }
        let item = items[index]
        let frame = viewFrame(of: item)

        // 左上角删除把手
        let deleteCenter = CGPoint(x: frame.minX, y: frame.minY)
        if hypot(point.x - deleteCenter.x, point.y - deleteCenter.y) <= 22 { return .deleteMarker }

        let usesEndpoints = item.type == .arrow || (item.type == .line && item.isStraightLine)
        if usesEndpoints {
            let startPoint = item.type == .arrow ? item.startPoint : (item.linePoints.first ?? .zero)
            let endPoint = item.type == .arrow ? item.endPoint : (item.linePoints.last ?? .zero)
            let startCenter = viewPoint(fromImagePoint: startPoint)
            let endCenter = viewPoint(fromImagePoint: endPoint)
            let endpointHitRadius = UIDevice.wy_screenWidth(21, WYBasisKitConfig.defaultScreenPixels)
            if hypot(point.x - startCenter.x, point.y - startCenter.y) <= endpointHitRadius { return .endpointStart }
            if hypot(point.x - endCenter.x, point.y - endCenter.y) <= endpointHitRadius { return .endpointEnd }
        } else {

            // 右下角缩放把手
            let resizeCenter = CGPoint(x: frame.maxX, y: frame.maxY)
            if hypot(point.x - resizeCenter.x, point.y - resizeCenter.y) <= UIDevice.wy_screenWidth(21, WYBasisKitConfig.defaultScreenPixels) { return .resizeMarker }
        }
        return nil
    }

    /// 新建文本标记(在指定图片坐标处落字，取消输入时不生成)
    private func requestNewText(atImagePoint point: CGPoint) {
        onRequestTextEdit?(nil) { [weak self] input in
            guard let self = self, let text = input, !text.isEmpty else { return }
            var item = WYImageMarkerItem()
            item.type = .text
            item.text = text
            item.color = self.currentColor
            item.lineWidth = self.defaultLineWidth
            item.fontSize = self.defaultFontSize
            let textSize = (text as NSString).size(withAttributes: item.textAttributes)
            item.frame = CGRect(x: point.x - textSize.width / 2, y: point.y - textSize.height / 2, width: textSize.width, height: ceil(textSize.height))
            self.items.append(item)
            self.selectedIndex = self.items.count - 1
            self.redoItems.removeAll()
            self.setNeedsDisplay()
            self.onMarkerOperation?()
            self.onSelectionChanged?()
        }
    }

    /// 编辑选中的文本标记(重新弹输入改字)
    private func requestEditText(itemIndex: Int) {
        let originalText = items[itemIndex].text
        onRequestTextEdit?(originalText) { [weak self] input in
            guard let self = self, let text = input, !text.isEmpty, self.items.indices.contains(itemIndex) else { return }
            self.items[itemIndex].text = text
            let textSize = (text as NSString).size(withAttributes: self.items[itemIndex].textAttributes)
            self.items[itemIndex].frame.size = CGSize(width: textSize.width, height: ceil(textSize.height))
            self.setNeedsDisplay()
            self.onMarkerOperation?()
        }
    }

    /// 拖拽结束收尾(尺寸太小的标记直接丢弃，避免误触留下小点)
    private func finishDragging() {
        var createdNewMarker = false
        if dragMode == .createShape, let index = selectedIndex, items.indices.contains(index) {
            let scale = displayTransform().scale
            if items[index].frame.width * scale < 10 || items[index].frame.height * scale < 10 {
                items.remove(at: index)
                selectedIndex = nil
            } else {
                createdNewMarker = true
            }
        }
        if dragMode == .createArrow, let index = selectedIndex, items.indices.contains(index) {
            let item = items[index]
            if hypot(item.endPoint.x - item.startPoint.x, item.endPoint.y - item.startPoint.y) * displayTransform().scale < 14 {
                items.remove(at: index)
                selectedIndex = nil
            } else {
                createdNewMarker = true
            }
        }
        if dragMode == .createLine, let index = selectedIndex, items.indices.contains(index) {
            let item = items[index]
            let frame = item.lineFrame
            let screenDiagonal = hypot(frame.width, frame.height) * displayTransform().scale
            if screenDiagonal < 12 {
                items.remove(at: index)
                selectedIndex = nil
            } else {
                createdNewMarker = true
            }
        }
        if createdNewMarker {
            redoItems.removeAll()
            onMarkerOperation?()
        }
        dragMode = .none
        dragStartItem = nil
        setNeedsDisplay()
        onSelectionChanged?()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), displayRegion.width > 0 else { return }

        let transform = displayTransform()
        let region = validRegion

        // 图片与标记都按显示区域映射画(先平移缩放进图片坐标系)
        context.saveGState()
        context.translateBy(x: transform.origin.x, y: transform.origin.y)
        context.scaleBy(x: transform.scale, y: transform.scale)
        context.translateBy(x: -region.origin.x, y: -region.origin.y)
        sourceImage.draw(in: CGRect(origin: .zero, size: sourceImage.size))
        for item in items {
            drawMarkerItem(item, in: context)
        }
        context.restoreGState()

        // 选中态的虚线框与操作把手按画布坐标画，保证任何缩放下大小一致
        if let index = selectedIndex, items.indices.contains(index) {
            drawSelectionChrome(for: items[index], in: context)
        }
    }

    /// 画单个标记(在图片坐标系里画，划线直线两点连线自由划线轨迹平滑连曲线)
    private func drawMarkerItem(_ item: WYImageMarkerItem, in context: CGContext) {
        context.setStrokeColor(item.color.cgColor)
        context.setFillColor(item.color.cgColor)
        context.setLineWidth(item.lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        switch item.type {
        case .text:
            (item.text as NSString).draw(at: CGPoint(x: item.frame.origin.x, y: item.frame.origin.y + (item.frame.height - ((item.text as NSString).size(withAttributes: item.textAttributes).height)) / 2), withAttributes: item.textAttributes)
        case .rectangle:
            let inset = item.lineWidth / 2
            let path = UIBezierPath(roundedRect: item.frame.insetBy(dx: inset, dy: inset), cornerRadius: item.lineWidth * 0.5)
            path.lineWidth = item.lineWidth
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
        case .circle:
            let inset = item.lineWidth / 2
            let path = UIBezierPath(ovalIn: item.frame.insetBy(dx: inset, dy: inset))
            path.lineWidth = item.lineWidth
            path.stroke()
        case .arrow:
            let startPoint = item.startPoint
            let endPoint = item.endPoint
            let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
            let headLength = item.lineWidth * 3.5

            // 箭身画到头底，避免线头从三角里冒出来
            let bodyEnd = CGPoint(x: endPoint.x - cos(angle) * headLength * 0.7, y: endPoint.y - sin(angle) * headLength * 0.7)
            let bodyPath = UIBezierPath()
            bodyPath.move(to: startPoint)
            bodyPath.addLine(to: bodyEnd)
            bodyPath.lineWidth = item.lineWidth
            bodyPath.lineCapStyle = .round
            bodyPath.stroke()

            let headPath = UIBezierPath()
            headPath.move(to: endPoint)
            headPath.addLine(to: CGPoint(x: endPoint.x - cos(angle - 0.4) * headLength, y: endPoint.y - sin(angle - 0.4) * headLength))
            headPath.addLine(to: CGPoint(x: endPoint.x - cos(angle + 0.4) * headLength, y: endPoint.y - sin(angle + 0.4) * headLength))
            headPath.close()
            headPath.fill()
        case .line:
            guard item.linePoints.count >= 2 else { break }
            let path = UIBezierPath()
            path.lineWidth = item.lineWidth
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.move(to: item.linePoints[0])
            if item.isStraightLine {
                path.addLine(to: item.linePoints[item.linePoints.count - 1])
            } else {

                // 自由划线按相邻点中点走二次曲线，线条圆滑跟手
                var previous = item.linePoints[0]
                for index in 1..<(item.linePoints.count - 1) {
                    let midPoint = CGPoint(x: (item.linePoints[index].x + item.linePoints[index + 1].x) / 2, y: (item.linePoints[index].y + item.linePoints[index + 1].y) / 2)
                    path.addQuadCurve(to: midPoint, controlPoint: previous)
                    previous = item.linePoints[index]
                }
                path.addLine(to: item.linePoints[item.linePoints.count - 1])
            }
            path.stroke()
        }
    }

    /// 画选中态样式(虚线框加左上删除把手加右下缩放把手或箭头直线划线的两端把手)
    private func drawSelectionChrome(for item: WYImageMarkerItem, in context: CGContext) {

        let frame = viewFrame(of: item)
        let chromeFrame = frame.insetBy(dx: -appearance.selectionInset, dy: -appearance.selectionInset)

        // 一深一浅两圈虚线，浅色背景上也能看清
        context.setLineWidth(appearance.selectionDashWidth + 1.5)
        context.setStrokeColor(UIColor(white: 0, alpha: 0.55).cgColor)
        let darkPath = UIBezierPath(rect: chromeFrame)
        darkPath.setLineDash([4, 3], count: 2, phase: 0)
        darkPath.stroke()
        context.setLineWidth(appearance.selectionDashWidth)
        context.setStrokeColor(appearance.selectionDashColor.cgColor)
        let lightPath = UIBezierPath(rect: chromeFrame)
        lightPath.setLineDash([4, 3], count: 2, phase: 0)
        lightPath.stroke()

        // 左上角删除圆钮带叉
        let deleteCenter = CGPoint(x: chromeFrame.minX, y: chromeFrame.minY)
        let deletePath = UIBezierPath(arcCenter: deleteCenter, radius: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), startAngle: 0, endAngle: .pi * 2, clockwise: true)
        appearance.deleteButtonColor.setFill()
        deletePath.fill()
        context.setStrokeColor(appearance.selectionDashColor.cgColor)
        context.setLineWidth(1.8)
        let crossPath = UIBezierPath()
        crossPath.move(to: CGPoint(x: deleteCenter.x - 4.5, y: deleteCenter.y - 4.5))
        crossPath.addLine(to: CGPoint(x: deleteCenter.x + 4.5, y: deleteCenter.y + 4.5))
        crossPath.move(to: CGPoint(x: deleteCenter.x + 4.5, y: deleteCenter.y - 4.5))
        crossPath.addLine(to: CGPoint(x: deleteCenter.x - 4.5, y: deleteCenter.y + 4.5))
        crossPath.stroke()

        // 白圈小圆点把手(箭头与直线划线在两端，其余在右下角)
        func drawHandleDot(_ center: CGPoint) {
            let dotPath = UIBezierPath(arcCenter: center, radius: 7, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            appearance.resizeDotColor.setFill()
            dotPath.fill()
            context.setLineWidth(1.5)
            context.setStrokeColor(UIColor(white: 0, alpha: 0.4).cgColor)
            let ringPath = UIBezierPath(arcCenter: center, radius: 6, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            ringPath.stroke()
        }
        let usesEndpoints = item.type == .arrow || (item.type == .line && item.isStraightLine)
        if usesEndpoints {
            let startPoint = item.type == .arrow ? item.startPoint : (item.linePoints.first ?? .zero)
            let endPoint = item.type == .arrow ? item.endPoint : (item.linePoints.last ?? .zero)
            drawHandleDot(viewPoint(fromImagePoint: startPoint))
            drawHandleDot(viewPoint(fromImagePoint: endPoint))
        } else {
            drawHandleDot(CGPoint(x: chromeFrame.maxX, y: chromeFrame.maxY))
        }
    }

    /// 把全部标记画进指定图形上下文(编辑器出成品图时用，上下文已带图片坐标到成品的映射)
    func drawMarkers(in context: CGContext) {
        for item in items {
            context.saveGState()
            drawMarkerItem(item, in: context)
            context.restoreGState()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        isOpaque = false
        isMultipleTouchEnabled = false
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:))))
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:))))
    }

    /// 画布尺寸变化时强制重画(切模式画布高度跳变时旧位图会被系统拉伸铺满新尺寸显示成图片变大变形)
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 点画布(点标记选中它，再点选中的文本重新编辑，点空白处文本工具落字其余取消选中)
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let viewLocation = gesture.location(in: self)
        let imageLocation = imagePoint(fromViewPoint: viewLocation)

        if let handle = handleAtViewPoint(viewLocation) {
            if handle == .deleteMarker {
                removeSelectedMarker()
            }
            return
        }

        if let hitIndex = markerIndex(atImagePoint: imageLocation) {
            if selectedIndex == hitIndex, items[hitIndex].type == .text {
                requestEditText(itemIndex: hitIndex)
            } else {
                selectedIndex = hitIndex
                setNeedsDisplay()
                onSelectionChanged?()
            }
            return
        }

        if activeTool == .text {
            requestNewText(atImagePoint: imageLocation)
        } else {
            deselectMarker()
        }
    }

    /// 拖画布(把手拖拽操作选中标记，点在标记上拖着走，点空白处按工具生成新标记)
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let viewLocation = gesture.location(in: self)
        let imageLocation = imagePoint(fromViewPoint: viewLocation)

        switch gesture.state {
        case .began:
            beginDragging(atViewLocation: viewLocation, imageLocation: imageLocation)
        case .changed:
            updateDragging(toViewLocation: viewLocation, imageLocation: imageLocation)
        default:
            finishDragging()
        }
    }

    /// 拖拽开始(判定拖拽模式)
    private func beginDragging(atViewLocation viewLocation: CGPoint, imageLocation: CGPoint) {

        if let handle = handleAtViewPoint(viewLocation) {
            dragMode = handle
            if handle == .deleteMarker {
                removeSelectedMarker()
                dragMode = .none
                return
            }
            if let index = selectedIndex {
                dragStartItem = items[index]
            }
            return
        }

        if let hitIndex = markerIndex(atImagePoint: imageLocation) {
            selectedIndex = hitIndex
            dragMode = .moveMarker
            dragStartItem = items[hitIndex]
            moveGrabOffset = CGPoint(x: imageLocation.x - items[hitIndex].effectiveFrame.origin.x, y: imageLocation.y - items[hitIndex].effectiveFrame.origin.y)
            setNeedsDisplay()
            onSelectionChanged?()
            return
        }

        // 空白处按当前工具新建(文本工具靠点按落字，拖动不生成)
        var item = WYImageMarkerItem()
        item.color = currentColor
        item.lineWidth = defaultLineWidth
        switch activeTool {
        case .text:
            dragMode = .none
        case .rectangle, .circle:
            item.type = activeTool
            item.frame = CGRect(origin: imageLocation, size: .zero)
            items.append(item)
            selectedIndex = items.count - 1
            dragStartItem = item
            dragStartImagePoint = imageLocation
            dragMode = .createShape
            setNeedsDisplay()
        case .arrow:
            item.type = .arrow
            item.startPoint = imageLocation
            item.endPoint = imageLocation
            items.append(item)
            selectedIndex = items.count - 1
            dragStartItem = item
            dragStartImagePoint = imageLocation
            dragMode = .createArrow
            setNeedsDisplay()
        case .line:
            item.type = .line
            item.isStraightLine = lineDrawsStraight
            item.linePoints = [imageLocation]
            items.append(item)
            selectedIndex = items.count - 1
            dragStartItem = item
            dragStartImagePoint = imageLocation
            dragMode = .createLine
            setNeedsDisplay()
        }
    }

    /// 拖拽进行中(按模式更新标记数据)
    private func updateDragging(toViewLocation viewLocation: CGPoint, imageLocation: CGPoint) {
        guard let index = selectedIndex, items.indices.contains(index) else { return }

        switch dragMode {
        case .moveMarker:
            guard var item = dragStartItem else { return }
            let origin = item.effectiveFrame.origin
            let deltaX = imageLocation.x - moveGrabOffset.x - origin.x
            let deltaY = imageLocation.y - moveGrabOffset.y - origin.y
            if item.type == .arrow {
                item.startPoint.x += deltaX
                item.startPoint.y += deltaY
                item.endPoint.x += deltaX
                item.endPoint.y += deltaY
            } else if item.type == .line {
                for pointIndex in item.linePoints.indices {
                    item.linePoints[pointIndex].x += deltaX
                    item.linePoints[pointIndex].y += deltaY
                }
            } else {
                item.frame.origin.x += deltaX
                item.frame.origin.y += deltaY
            }
            items[index] = item
        case .resizeMarker:
            guard var item = dragStartItem else { return }
            if item.type == .text {

                // 文本拖右下角按宽度比例缩放字号
                let oldWidth = max(item.frame.width, 1)
                let newWidth = max(imageLocation.x - item.frame.origin.x, item.fontSize)
                let ratio = newWidth / oldWidth
                item.fontSize = min(max(item.fontSize * ratio, 12), 400)
                let textSize = (item.text as NSString).size(withAttributes: item.textAttributes)
                item.frame.size = CGSize(width: textSize.width, height: ceil(textSize.height))
            } else if item.type == .line {

                // 自由划线拖右下角按新旧宽高比例等比缩放全部轨迹点
                let oldFrame = item.effectiveFrame
                let newWidth = max(imageLocation.x - item.frame.origin.x, item.lineWidth * 2)
                let newHeight = max(imageLocation.y - item.frame.origin.y, item.lineWidth * 2)
                let ratioX = newWidth / max(oldFrame.width, 1)
                let ratioY = newHeight / max(oldFrame.height, 1)
                for pointIndex in item.linePoints.indices {
                    item.linePoints[pointIndex].x = oldFrame.origin.x + (item.linePoints[pointIndex].x - oldFrame.origin.x) * ratioX
                    item.linePoints[pointIndex].y = oldFrame.origin.y + (item.linePoints[pointIndex].y - oldFrame.origin.y) * ratioY
                }
            } else {
                item.frame.size.width = max(imageLocation.x - item.frame.origin.x, defaultLineWidth * 2)
                item.frame.size.height = max(imageLocation.y - item.frame.origin.y, defaultLineWidth * 2)
            }
            items[index] = item
        case .endpointStart:
            guard var item = dragStartItem else { return }
            if item.type == .arrow {
                item.startPoint = imageLocation
            } else if item.type == .line, !item.linePoints.isEmpty {
                item.linePoints[0] = imageLocation
            }
            items[index] = item
        case .endpointEnd:
            guard var item = dragStartItem else { return }
            if item.type == .arrow {
                item.endPoint = imageLocation
            } else if item.type == .line, !item.linePoints.isEmpty {
                item.linePoints[item.linePoints.count - 1] = imageLocation
            }
            items[index] = item
        case .createShape:
            guard dragStartItem != nil else { return }
            let origin = dragStartImagePoint
            items[index].frame = CGRect(x: min(origin.x, imageLocation.x), y: min(origin.y, imageLocation.y), width: abs(imageLocation.x - origin.x), height: abs(imageLocation.y - origin.y))
        case .createArrow:
            guard dragStartItem != nil else { return }
            items[index].endPoint = imageLocation
        case .createLine:
            guard dragStartItem != nil else { return }
            if items[index].isStraightLine {

                // 直线形态只保留首尾两个点
                if items[index].linePoints.count == 1 {
                    items[index].linePoints.append(imageLocation)
                } else {
                    items[index].linePoints[items[index].linePoints.count - 1] = imageLocation
                }
            } else {

                // 自由划线记录手指轨迹，离上一个点太近就不记，控制点的数量
                let minimumStep = 2 / max(displayTransform().scale, 0.001)
                let lastPoint = items[index].linePoints[items[index].linePoints.count - 1]
                if hypot(imageLocation.x - lastPoint.x, imageLocation.y - lastPoint.y) >= minimumStep {
                    items[index].linePoints.append(imageLocation)
                }
            }
        case .deleteMarker, .none:
            return
        }
        setNeedsDisplay()
    }
}
