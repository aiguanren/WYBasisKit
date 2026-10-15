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

    /// 标记边界(文本矩形圆形用，箭头用起点终点)
    var frame: CGRect = .zero

    /// 箭头起点(图片坐标)
    var startPoint: CGPoint = .zero

    /// 箭头终点(图片坐标)
    var endPoint: CGPoint = .zero

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

    /// 文本排版属性(按标记自身的字号与颜色生成)
    var textAttributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byClipping
        return [.font: UIFont.boldSystemFont(ofSize: fontSize), .foregroundColor: color, .paragraphStyle: paragraph]
    }
}

/// 标记视图(显示裁剪框取景范围内的图片，在上面写字画框画圈画箭头，标记可选中拖动缩放删除)
class WYImageMarkerView: UIView {

    /// 文本输入请求回调(参数为已有文本可为nil，回调参数为用户输入，取消时回调nil)
    var onRequestTextEdit: ((String?, @escaping (String?) -> Void) -> Void)?

    /// 当前选中的标记类型(选中后点画布空白处拖动即生成对应标记，文本工具点空白处弹输入)
    var activeTool: WYImageMarkerType = .text

    /// 当前默认颜色(改色时没有选中标记就改它，影响之后新建的标记)
    private var currentColor: UIColor = .white

    /// 默认线条宽度(图片坐标，配置传0时按图片宽度自动取值)
    private var defaultLineWidth: CGFloat = 5

    /// 默认文本字号(图片坐标，配置传0时按图片宽度自动取值)
    private var defaultFontSize: CGFloat = 32

    /// 要标记的原图
    private var sourceImage: UIImage = UIImage()

    /// 当前显示的图片区域(原图坐标，跟随裁剪框变化)
    private var displayRegion: CGRect = .zero

    /// 全部标记(按绘制顺序排列，后画的盖在前面)
    private var items: [WYImageMarkerItem] = []

    /// 当前选中标记的下标(nil表示没有选中)
    private var selectedIndex: Int?

    /// 拖拽模式(把手操作还是移动标记还是新建标记)
    private enum DragMode {
        /// 无动作
        case none
        /// 拖删除把手(直接删掉)
        case deleteMarker
        /// 拖缩放把手(矩形圆形文本调整大小，文本按宽度比例缩放字号)
        case resizeMarker
        /// 拖箭头起点把手
        case arrowStart
        /// 拖箭头终点把手
        case arrowEnd
        /// 移动整个标记
        case moveMarker
        /// 新建矩形或圆形
        case createShape
        /// 新建箭头
        case createArrow
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
     */
    func setup(image: UIImage, defaultColor: UIColor, lineWidth: CGFloat, textFontSize: CGFloat) {
        sourceImage = image
        currentColor = defaultColor
        let baseWidth = max(image.size.width, 1)
        defaultLineWidth = lineWidth > 0 ? lineWidth : min(max(baseWidth / 160, 3), 48)
        defaultFontSize = textFontSize > 0 ? textFontSize : min(max(baseWidth / 18, 16), 220)
    }

    /// 更新显示区域(切到标记模式或裁剪框变化时按裁剪框取景)
    func updateDisplayRegion(_ region: CGRect) {
        displayRegion = region
        setNeedsDisplay()
    }

    /// 取消选中(切工具或切模式时调用)
    func deselectMarker() {
        selectedIndex = nil
        setNeedsDisplay()
    }

    /// 撤销最后一个标记
    func undoLastMarker() {
        guard !items.isEmpty else { return }
        items.removeLast()
        if selectedIndex == items.count {
            selectedIndex = nil
        }
        setNeedsDisplay()
    }

    /// 删除当前选中的标记
    func removeSelectedMarker() {
        guard let index = selectedIndex, items.indices.contains(index) else { return }
        items.remove(at: index)
        selectedIndex = nil
        setNeedsDisplay()
    }

    /// 清空全部标记(编辑器点还原时调用)
    func removeAllMarkers() {
        items.removeAll()
        selectedIndex = nil
        setNeedsDisplay()
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

    /// 画布触点转图片坐标
    private func imagePoint(fromViewPoint viewPoint: CGPoint) -> CGPoint {
        let transform = displayTransform()
        return CGPoint(x: (viewPoint.x - transform.origin.x) / transform.scale, y: (viewPoint.y - transform.origin.y) / transform.scale)
    }

    /// 图片坐标转画布触点
    private func viewPoint(fromImagePoint imageCoordinate: CGPoint) -> CGPoint {
        let transform = displayTransform()
        return CGPoint(x: imageCoordinate.x * transform.scale + transform.origin.x, y: imageCoordinate.y * transform.scale + transform.origin.y)
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
        let frame = item.type == .arrow ? item.arrowFrame : item.frame
        let origin = viewPoint(fromImagePoint: frame.origin)
        return CGRect(x: origin.x, y: origin.y, width: frame.width * displayTransform().scale, height: frame.height * displayTransform().scale)
    }

    /// 图片区域(去掉零区域保护后的合法显示范围)
    private var validRegion: CGRect {
        var region = displayRegion
        region.size.width = max(region.width, 1)
        region.size.height = max(region.height, 1)
        return region
    }

    /// 命中的标记下标(后画的优先，触点按图片坐标判断，命中范围向外扩一点方便点中)
    private func markerIndex(atImagePoint point: CGPoint) -> Int? {
        let scale = displayTransform().scale
        let padding = 12 / max(scale, 0.001)
        for index in items.indices.reversed() {
            let item = items[index]
            if item.type == .arrow {
                let frame = item.arrowFrame.insetBy(dx: -padding, dy: -padding)
                if frame.contains(point) { return index }
            } else {
                let frame = item.frame.insetBy(dx: -padding, dy: -padding)
                if frame.contains(point) { return index }
            }
        }
        return nil
    }

    /// 触点命中的操作把手(删除缩放或箭头端点，按画布坐标判断)
    private func handleAtViewPoint(_ point: CGPoint) -> DragMode? {
        guard let index = selectedIndex, items.indices.contains(index) else { return nil }
        let item = items[index]
        let frame = viewFrame(of: item)

        // 左上角删除把手
        let deleteCenter = CGPoint(x: frame.minX, y: frame.minY)
        if hypot(point.x - deleteCenter.x, point.y - deleteCenter.y) <= 22 { return .deleteMarker }

        if item.type == .arrow {
            let startCenter = viewPoint(fromImagePoint: item.startPoint)
            let endCenter = viewPoint(fromImagePoint: item.endPoint)
            if hypot(point.x - startCenter.x, point.y - startCenter.y) <= 22 { return .arrowStart }
            if hypot(point.x - endCenter.x, point.y - endCenter.y) <= 22 { return .arrowEnd }
        } else {
            // 右下角缩放把手
            let resizeCenter = CGPoint(x: frame.maxX, y: frame.maxY)
            if hypot(point.x - resizeCenter.x, point.y - resizeCenter.y) <= 22 { return .resizeMarker }
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
            self.setNeedsDisplay()
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
        }
    }

    /// 拖拽结束收尾(尺寸太小的标记直接丢弃，避免误触留下小点)
    private func finishDragging() {
        if dragMode == .createShape, let index = selectedIndex, items.indices.contains(index) {
            let scale = displayTransform().scale
            if items[index].frame.width * scale < 10 || items[index].frame.height * scale < 10 {
                items.remove(at: index)
                selectedIndex = nil
            }
        }
        if dragMode == .createArrow, let index = selectedIndex, items.indices.contains(index) {
            let item = items[index]
            if hypot(item.endPoint.x - item.startPoint.x, item.endPoint.y - item.startPoint.y) * displayTransform().scale < 14 {
                items.remove(at: index)
                selectedIndex = nil
            }
        }
        dragMode = .none
        dragStartItem = nil
        setNeedsDisplay()
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
        context.clip(to: [bounds]) 
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

    /// 画单个标记(在图片坐标系里画，箭头画线加实心三角头)
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
        }
    }

    /// 画选中态样式(虚线框加左上删除把手加右下缩放把手或箭头两端把手)
    private func drawSelectionChrome(for item: WYImageMarkerItem, in context: CGContext) {

        let frame = viewFrame(of: item)
        let chromeFrame = frame.insetBy(dx: -6, dy: -6)

        // 一深一浅两圈虚线，浅色背景上也能看清
        context.setLineWidth(3)
        context.setStrokeColor(UIColor(white: 0, alpha: 0.55).cgColor)
        let darkPath = UIBezierPath(rect: chromeFrame)
        darkPath.setLineDash([4, 3], count: 2, phase: 0)
        darkPath.stroke()
        context.setLineWidth(1.5)
        context.setStrokeColor(UIColor.white.cgColor)
        let lightPath = UIBezierPath(rect: chromeFrame)
        lightPath.setLineDash([4, 3], count: 2, phase: 0)
        lightPath.stroke()

        // 左上角删除圆钮带叉
        let deleteCenter = CGPoint(x: chromeFrame.minX, y: chromeFrame.minY)
        let deletePath = UIBezierPath(arcCenter: deleteCenter, radius: 11, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        UIColor.black.withAlphaComponent(0.75).setFill()
        deletePath.fill()
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(1.8)
        let crossPath = UIBezierPath()
        crossPath.move(to: CGPoint(x: deleteCenter.x - 4.5, y: deleteCenter.y - 4.5))
        crossPath.addLine(to: CGPoint(x: deleteCenter.x + 4.5, y: deleteCenter.y + 4.5))
        crossPath.move(to: CGPoint(x: deleteCenter.x + 4.5, y: deleteCenter.y - 4.5))
        crossPath.addLine(to: CGPoint(x: deleteCenter.x - 4.5, y: deleteCenter.y + 4.5))
        crossPath.stroke()

        // 白圈小圆点把手(矩形圆形文本在右下角，箭头在两端)
        func drawHandleDot(_ center: CGPoint) {
            let dotPath = UIBezierPath(arcCenter: center, radius: 7, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            UIColor.white.setFill()
            dotPath.fill()
            context.setLineWidth(1.5)
            context.setStrokeColor(UIColor(white: 0, alpha: 0.4).cgColor)
            let ringPath = UIBezierPath(arcCenter: center, radius: 6, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            ringPath.stroke()
        }
        if item.type == .arrow {
            drawHandleDot(viewPoint(fromImagePoint: item.startPoint))
            drawHandleDot(viewPoint(fromImagePoint: item.endPoint))
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
            }
            setNeedsDisplay()
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
                if handle == .moveMarker {
                    moveGrabOffset = CGPoint(x: imageLocation.x - (items[index].type == .arrow ? items[index].arrowFrame.origin.x : items[index].frame.origin.x), y: imageLocation.y - (items[index].type == .arrow ? items[index].arrowFrame.origin.y : items[index].frame.origin.y))
                }
            }
            return
        }

        if let hitIndex = markerIndex(atImagePoint: imageLocation) {
            selectedIndex = hitIndex
            dragMode = .moveMarker
            dragStartItem = items[hitIndex]
            let item = items[hitIndex]
            let origin = item.type == .arrow ? item.arrowFrame.origin : item.frame.origin
            moveGrabOffset = CGPoint(x: imageLocation.x - origin.x, y: imageLocation.y - origin.y)
            setNeedsDisplay()
            return
        }

        // 空白处按当前工具新建(文本工具靠点按落字，拖动不生成)
        switch activeTool {
        case .text:
            dragMode = .none
        case .rectangle, .circle:
            var item = WYImageMarkerItem()
            item.type = activeTool
            item.color = currentColor
            item.lineWidth = defaultLineWidth
            item.frame = CGRect(origin: imageLocation, size: .zero)
            items.append(item)
            selectedIndex = items.count - 1
            dragStartItem = item
            dragStartImagePoint = imageLocation
            dragMode = .createShape
            setNeedsDisplay()
        case .arrow:
            var item = WYImageMarkerItem()
            item.type = .arrow
            item.color = currentColor
            item.lineWidth = defaultLineWidth
            item.startPoint = imageLocation
            item.endPoint = imageLocation
            items.append(item)
            selectedIndex = items.count - 1
            dragStartItem = item
            dragStartImagePoint = imageLocation
            dragMode = .createArrow
            setNeedsDisplay()
        }
    }

    /// 拖拽进行中(按模式更新标记数据)
    private func updateDragging(toViewLocation viewLocation: CGPoint, imageLocation: CGPoint) {
        guard let index = selectedIndex, items.indices.contains(index) else { return }

        switch dragMode {
        case .moveMarker:
            guard var item = dragStartItem else { return }
            let origin = item.type == .arrow ? item.arrowFrame.origin : item.frame.origin
            let deltaX = imageLocation.x - moveGrabOffset.x - origin.x
            let deltaY = imageLocation.y - moveGrabOffset.y - origin.y
            if item.type == .arrow {
                item.startPoint.x += deltaX
                item.startPoint.y += deltaY
                item.endPoint.x += deltaX
                item.endPoint.y += deltaY
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
            } else {
                item.frame.size.width = max(imageLocation.x - item.frame.origin.x, defaultLineWidth * 2)
                item.frame.size.height = max(imageLocation.y - item.frame.origin.y, defaultLineWidth * 2)
            }
            items[index] = item
        case .arrowStart:
            guard var item = dragStartItem else { return }
            item.startPoint = imageLocation
            items[index] = item
        case .arrowEnd:
            guard var item = dragStartItem else { return }
            item.endPoint = imageLocation
            items[index] = item
        case .createShape:
            guard dragStartItem != nil else { return }
            let origin = dragStartImagePoint
            items[index].frame = CGRect(x: min(origin.x, imageLocation.x), y: min(origin.y, imageLocation.y), width: abs(imageLocation.x - origin.x), height: abs(imageLocation.y - origin.y))
        case .createArrow:
            guard dragStartItem != nil else { return }
            items[index].endPoint = imageLocation
        case .deleteMarker, .none:
            return
        }
        setNeedsDisplay()
    }
}
