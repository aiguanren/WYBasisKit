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

    /// 水印组合的logo图(nil为纯文字水印，单条与平铺都支持)
    var watermarkImage: UIImage? = nil

    /// 是否平铺水印(true为整图网格平铺防盗图式，false为单条可拖动水印)
    var isTiledWatermark: Bool = false

    /// 马赛克是否框选形态(true为矩形框整块打码，false为手指涂抹打码)
    var isBoxedMosaic: Bool = false

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

    /// 标记的有效边界(文本矩形圆形水印单条用frame，箭头划线马赛克用轨迹边界，平铺水印返回null不参与命中与选中)
    var effectiveFrame: CGRect {
        if type == .arrow {
            return arrowFrame
        }
        if type == .line || type == .mosaic {
            return lineFrame
        }
        if type == .watermark, isTiledWatermark {
            return .null
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

/// 标记视图(显示裁剪框取景范围内的图片，在上面写字画框画圈画箭头划线打马赛克盖水印，标记可选中拖动缩放删除)
class WYImageMarkerView: UIView {

    /// 文本输入请求回调(参数依次为已有文本可为nil、弹窗标题，回调参数为用户输入，取消时回调nil)
    var onRequestTextEdit: ((_ existingText: String?, _ title: String, _ completion: @escaping (String?) -> Void) -> Void)?

    /// 选中状态变化回调(点选新建删除撤销后触发，编辑器用它刷新粗细字号颜色选择行)
    var onSelectionChanged: (() -> Void)?

    /// 标记操作上报回调(用户新建删除编辑改样式时触发，编辑器记入统一撤销栈，撤销重做自身不重复上报)
    var onMarkerOperation: (() -> Void)?

    /// 当前选中的标记类型(选中后点画布空白处拖动即生成对应标记，文本与水印工具点空白处弹输入)
    var activeTool: WYImageMarkerType = .text

    /// 划线的默认形态(true为两点连直线，false为跟随手指自由划线，选中划线时可单独转换)
    var lineDrawsStraight = false

    /// 马赛克的默认形态(true为拖矩形框整块打码，false为手指涂抹打码，只影响之后新建的马赛克)
    var mosaicDrawsBox = false

    /// 水印是否带上logo(编辑器水印语境图片钮的开关态，配置了watermarkImage才有意义)
    var watermarkUsesLogo = true

    /// 水印是否平铺模式(编辑器水印语境平铺钮的开关态，true时点画布生成整图平铺水印，false为单条)
    var watermarkTiled = false

    /// 当前默认颜色(改色时没有选中标记就改它，影响之后新建的标记)
    private var currentColor: UIColor = .white

    /// 默认线条宽度(图片坐标，配置传0时按图片宽度自动取值)
    private var defaultLineWidth: CGFloat = 5

    /// 默认文本字号(图片坐标，配置传0时按图片宽度自动取值)
    private var defaultFontSize: CGFloat = 32

    /// 水印默认颜色(改色时水印语境没有选中标记就改它，影响之后新建的水印)
    private var currentWatermarkColor: UIColor = .white

    /// 水印默认字号(图片坐标，配置传0时按图片宽度自动取值)
    private var defaultWatermarkFontSize: CGFloat = 30

    /// 水印倾斜角(单位为度，单条与平铺共用，0为水平)
    private var watermarkRotation: CGFloat = -30

    /// 落水印时输入弹窗的预填文案(nil用本地化默认)
    private var watermarkDefaultText: String?

    /// 调用方预置的水印logo图(nil时水印不带logo)
    private var watermarkLogoImage: UIImage?

    /// 界面外观(选中态虚线删除钮把手与档位倍率都从这里取)
    private var appearance = WYImageEditorAppearance()

    /// 线宽档位的固定基准(进入编辑器时解析一次，点档位只改当前选择不改基准，防档位值滚雪球漂移)
    private var baseLineWidth: CGFloat = 5

    /// 字号档位的固定基准(同线宽基准的理由)
    private var baseFontSize: CGFloat = 32

    /// 马赛克笔刷默认宽度(图片坐标，配置传0时按图片宽度自动取值)
    private var defaultMosaicBrushWidth: CGFloat = 12

    /// 马赛克笔刷档位的固定基准(同线宽基准的理由)
    private var baseMosaicBrushWidth: CGFloat = 12

    /// 马赛克像素块大小(图片坐标，配置传0时按图片宽度自动取值)
    private var mosaicCellSize: CGFloat = 18

    /// 水印字号档位的固定基准(同线宽基准的理由)
    private var baseWatermarkFontSize: CGFloat = 30

    /// 像素化整图缓存(第一次画马赛克时生成，基准图或像素块大小变化时清空重生成)
    private var cachedMosaicImage: UIImage?

    /// 要标记的原图
    private var sourceImage: UIImage = UIImage()

    /// 当前显示的图片区域(原图坐标，跟随裁剪框变化)
    private var displayRegion: CGRect = .zero

    /// 查看缩放系数(双指捏合放大画布看细节，只影响显示与命中，不影响标记存储坐标与导出)
    private var userZoom: CGFloat = 1

    /// 查看平移分量(放大后画布可拖，与查看缩放系数同属查看变换)
    private var userPan: CGPoint = .zero

    /// 配置的初始查看倍数(取景变化复位时回到它而不是1)
    private var initialZoomMultiplier: CGFloat = 1

    /// 上一次捏合倍率(按增量换算查看缩放，捏合结束后重捏不跳变)
    private var lastPinchScale: CGFloat = 1

    /// 画标记的拖动手势(只认单指，第二指落下不干扰正在画的线)
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        gesture.maximumNumberOfTouches = 1
        return gesture
    }()

    /// 双指捏合查看手势(缩放平移画布，与画线手势互斥交接)
    private lazy var pinchGesture: UIPinchGestureRecognizer = {
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        gesture.delegate = self
        return gesture
    }()

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
        /// 新建涂抹马赛克(框选形态复用createShape)
        case createMosaic
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
     *   - mosaicBrushWidth: 马赛克笔刷默认宽度(传0按图片宽度自动)
     *   - mosaicCellSize: 马赛克像素块大小(传0按图片宽度自动)
     *   - mosaicDrawsBox: 马赛克默认形态(true为框选)
     *   - watermarkText: 落水印时输入弹窗的预填文案(传nil用本地化默认)
     *   - watermarkColor: 水印默认颜色
     *   - watermarkFontSize: 水印默认字号(传0按图片宽度自动)
     *   - watermarkRotation: 水印倾斜角(单位为度，0为水平)
     *   - watermarkImage: 调用方预置的水印logo图(传nil水印不带logo)
     *   - appearance: 界面外观
     */
    func setup(image: UIImage, defaultColor: UIColor, lineWidth: CGFloat, textFontSize: CGFloat, straightLine: Bool, mosaicBrushWidth: CGFloat, mosaicCellSize: CGFloat, mosaicDrawsBox: Bool, watermarkText: String?, watermarkColor: UIColor, watermarkFontSize: CGFloat, watermarkRotation: CGFloat, watermarkImage: UIImage?, appearance: WYImageEditorAppearance, zoomEnabled: Bool = true, initialZoomMultiplier: CGFloat = 1) {
        sourceImage = image
        currentColor = defaultColor
        lineDrawsStraight = straightLine
        self.mosaicDrawsBox = mosaicDrawsBox
        watermarkDefaultText = watermarkText
        currentWatermarkColor = watermarkColor
        self.watermarkRotation = watermarkRotation
        watermarkLogoImage = watermarkImage
        self.appearance = appearance
        pinchGesture.isEnabled = zoomEnabled
        self.initialZoomMultiplier = min(max(initialZoomMultiplier, 1), 8)
        userZoom = self.initialZoomMultiplier
        userPan = .zero
        let baseWidth = max(image.size.width, 1)
        defaultLineWidth = lineWidth > 0 ? lineWidth : min(max(baseWidth / 160, 3), 48)
        defaultFontSize = textFontSize > 0 ? textFontSize : min(max(baseWidth / 18, 16), 220)
        defaultMosaicBrushWidth = mosaicBrushWidth > 0 ? mosaicBrushWidth : min(max(baseWidth / 45, 6), 160)
        self.mosaicCellSize = mosaicCellSize > 0 ? mosaicCellSize : min(max(baseWidth / 64, 8), 120)
        defaultWatermarkFontSize = watermarkFontSize > 0 ? watermarkFontSize : min(max(baseWidth / 26, 14), 180)
        baseLineWidth = defaultLineWidth
        baseFontSize = defaultFontSize
        baseMosaicBrushWidth = defaultMosaicBrushWidth
        baseWatermarkFontSize = defaultWatermarkFontSize
    }

    /// 更新显示区域(切到标记模式或裁剪框变化时按裁剪框取景，取景变了查看缩放与平移复位到初始倍数)
    func updateDisplayRegion(_ region: CGRect) {
        if region.size != displayRegion.size {
            userZoom = initialZoomMultiplier
            userPan = .zero
        }
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
        cachedMosaicImage = nil
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
        cachedMosaicImage = nil
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

    /// 应用颜色(有选中标记改它自己的颜色，没有就按工具语境改水印或标记的默认颜色影响之后的标记，马赛克语境不响应)
    func applyColor(_ color: UIColor) {
        if let index = selectedIndex, items.indices.contains(index), items[index].type != .mosaic {
            items[index].color = color
        } else if activeTool == .watermark {
            currentWatermarkColor = color
        } else if activeTool != .mosaic {
            currentColor = color
        }
        setNeedsDisplay()
    }

    /// 应用线条宽度(涂抹马赛克语境改笔刷宽度，其余语境改标记线宽，选中文本与框选马赛克时不生效)
    func applyLineWidth(_ width: CGFloat) {
        guard width > 0 else { return }
        if let index = selectedIndex, items.indices.contains(index), items[index].type != .text {
            if items[index].type == .mosaic, items[index].isBoxedMosaic { return }
            items[index].lineWidth = width
        } else if activeTool == .mosaic {
            defaultMosaicBrushWidth = width
        } else {
            defaultLineWidth = width
        }
        setNeedsDisplay()
    }

    /// 应用文本字号(选中文本或水印改它自己的字号并重排版，没有就按工具语境改水印或文本的默认字号影响之后的标记)
    func applyFontSize(_ fontSize: CGFloat) {
        guard fontSize > 0 else { return }
        if let index = selectedIndex, items.indices.contains(index), items[index].type == .text {
            items[index].fontSize = fontSize
            let textSize = (items[index].text as NSString).size(withAttributes: items[index].textAttributes)
            items[index].frame.size = CGSize(width: textSize.width, height: ceil(textSize.height))
        } else if let index = selectedIndex, items.indices.contains(index), items[index].type == .watermark {
            items[index].fontSize = fontSize
            items[index].frame.size = watermarkBoundsSize(contentSize: watermarkContentSize(text: items[index].text, logo: items[index].watermarkImage, fontSize: fontSize))
        } else if activeTool == .watermark {
            defaultWatermarkFontSize = fontSize
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

    /// 切换马赛克默认形态(框选与涂抹互换，只影响之后新建的马赛克，不改已画的)
    func toggleMosaicShape() {
        mosaicDrawsBox.toggle()
        onSelectionChanged?()
    }

    /// 当前马赛克新建形态(true为框选，false为涂抹，编辑器胶囊的显示与切换都按它)
    func activeMosaicBoxed() -> Bool {
        return mosaicDrawsBox
    }

    /// 界面线宽档位(马赛克语境按笔刷基准，其余按标记线宽基准，倍率序列共用外观配置)
    func presetLineWidths() -> [CGFloat] {
        let base = contextIsMosaicTool() ? baseMosaicBrushWidth : baseLineWidth
        return appearance.lineWidthRatios.map { base * $0 }
    }

    /// 界面字号档位(水印语境按水印字号基准，其余按文本字号基准，倍率序列共用外观配置)
    func presetFontSizes() -> [CGFloat] {
        let base = contextIsWatermarkText() ? baseWatermarkFontSize : baseFontSize
        return appearance.fontSizeRatios.map { base * $0 }
    }

    /// 当前生效线宽在档位中的下标(选中文本或框选马赛克或没有精确命中时返回nil)
    func activeLineWidthIndex() -> Int? {
        let width: CGFloat
        if let index = selectedIndex, items.indices.contains(index), items[index].type != .text {
            if items[index].type == .mosaic, items[index].isBoxedMosaic { return nil }
            width = items[index].lineWidth
        } else if activeTool == .mosaic {
            width = defaultMosaicBrushWidth
        } else {
            width = defaultLineWidth
        }
        let base = contextIsMosaicTool() ? baseMosaicBrushWidth : baseLineWidth
        return presetLineWidths().firstIndex(where: { abs($0 - width) < max(0.5, base * 0.05) })
    }

    /// 当前生效字号在档位中的下标(选中的不是文本或水印且对应工具没激活时返回nil)
    func activeFontSizeIndex() -> Int? {
        let fontSize: CGFloat
        if let index = selectedIndex, items.indices.contains(index), items[index].type == .text {
            fontSize = items[index].fontSize
        } else if let index = selectedIndex, items.indices.contains(index), items[index].type == .watermark {
            fontSize = items[index].fontSize
        } else if activeTool == .text {
            fontSize = defaultFontSize
        } else if activeTool == .watermark {
            fontSize = defaultWatermarkFontSize
        } else {
            return nil
        }
        let base = contextIsWatermarkText() ? baseWatermarkFontSize : baseFontSize
        return presetFontSizes().firstIndex(where: { abs($0 - fontSize) < max(0.5, base * 0.05) })
    }

    /// 当前生效颜色(有选中标记取它的颜色，水印语境没有选中取水印默认颜色，其余取标记默认颜色)
    func activeColor() -> UIColor {
        if let index = selectedIndex, items.indices.contains(index), items[index].type != .mosaic {
            return items[index].color
        }
        if activeTool == .watermark {
            return currentWatermarkColor
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

    /// 当前语境是否水印(选中水印标记或水印工具激活且无选中)
    func contextIsWatermarkText() -> Bool {
        if let index = selectedIndex, items.indices.contains(index) {
            return items[index].type == .watermark
        }
        return activeTool == .watermark
    }

    /// 当前语境是否划线(选中划线标记或划线工具激活且无选中)
    func contextIsLineTool() -> Bool {
        if let index = selectedIndex, items.indices.contains(index) {
            return items[index].type == .line
        }
        return activeTool == .line
    }

    /// 当前语境是否马赛克(选中马赛克标记或马赛克工具激活且无选中)
    func contextIsMosaicTool() -> Bool {
        if let index = selectedIndex, items.indices.contains(index) {
            return items[index].type == .mosaic
        }
        return activeTool == .mosaic
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

    /// 显示区到画布的映射(等比缩放加平移，图片区域完整显示在画布内居中，查看缩放与平移叠加其上)
    private func displayTransform() -> (scale: CGFloat, origin: CGPoint) {
        guard displayRegion.width > 0, displayRegion.height > 0, bounds.width > 0, bounds.height > 0 else { return (1, .zero) }
        let scale = min(bounds.width / displayRegion.width, bounds.height / displayRegion.height) * userZoom
        let originX = (bounds.width - displayRegion.width * scale) / 2 + userPan.x
        let originY = (bounds.height - displayRegion.height * scale) / 2 + userPan.y
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

    /// 命中的标记下标(后画的优先，触点按图片坐标判断，划线与涂抹马赛克按轨迹距离命中平铺水印跳过其余按边界命中)
    private func markerIndex(atImagePoint point: CGPoint) -> Int? {
        let scale = displayTransform().scale
        let padding = 12 / max(scale, 0.001)
        for index in items.indices.reversed() {
            let item = items[index]
            if item.type == .watermark, item.isTiledWatermark { continue }
            if item.type == .line || (item.type == .mosaic && !item.isBoxedMosaic) {
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
        onRequestTextEdit?(nil, WYLocalized("输入文本", table: WYBasisKitConfig.kitLocalizableTable)) { [weak self] input in
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

    /// 编辑选中的文本或水印标记(重新弹输入改字)
    private func requestEditText(itemIndex: Int) {
        let originalText = items[itemIndex].text
        let isWatermark = items[itemIndex].type == .watermark
        let title = isWatermark ? WYLocalized("输入水印", table: WYBasisKitConfig.kitLocalizableTable) : WYLocalized("输入文本", table: WYBasisKitConfig.kitLocalizableTable)
        onRequestTextEdit?(originalText, title) { [weak self] input in
            guard let self = self, let text = input, !text.isEmpty, self.items.indices.contains(itemIndex) else { return }
            self.items[itemIndex].text = text
            if self.items[itemIndex].type == .watermark {
                self.items[itemIndex].frame.size = self.watermarkBoundsSize(contentSize: self.watermarkContentSize(text: text, logo: self.items[itemIndex].watermarkImage, fontSize: self.items[itemIndex].fontSize))
            } else {
                let textSize = (text as NSString).size(withAttributes: self.items[itemIndex].textAttributes)
                self.items[itemIndex].frame.size = CGSize(width: textSize.width, height: ceil(textSize.height))
            }
            self.setNeedsDisplay()
            self.onMarkerOperation?()
        }
    }

    /// 点画布落水印(平铺模式新建或原地更新整图平铺层，单条模式在点击处落一条可拖动的组合水印，取消输入或既无字又无logo时不生成)
    private func requestNewWatermark(atImagePoint point: CGPoint) {
        let presetText = watermarkDefaultText ?? WYLocalized("水印", table: WYBasisKitConfig.kitLocalizableTable)
        let logo = watermarkUsesLogo ? watermarkLogoImage : nil
        onRequestTextEdit?(presetText, WYLocalized("输入水印", table: WYBasisKitConfig.kitLocalizableTable)) { [weak self] input in
            guard let self = self, let text = input else { return }
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty || logo != nil else { return }
            if self.watermarkTiled {
                if let tiledIndex = self.items.firstIndex(where: { $0.type == .watermark && $0.isTiledWatermark }) {
                    self.items[tiledIndex].text = trimmedText
                    self.items[tiledIndex].watermarkImage = logo
                } else {
                    var item = WYImageMarkerItem()
                    item.type = .watermark
                    item.isTiledWatermark = true
                    item.text = trimmedText
                    item.watermarkImage = logo
                    item.color = self.currentWatermarkColor
                    item.fontSize = self.defaultWatermarkFontSize
                    self.items.append(item)
                }
            } else {
                var item = WYImageMarkerItem()
                item.type = .watermark
                item.text = trimmedText
                item.watermarkImage = logo
                item.color = self.currentWatermarkColor
                item.fontSize = self.defaultWatermarkFontSize
                let boundsSize = self.watermarkBoundsSize(contentSize: self.watermarkContentSize(text: trimmedText, logo: logo, fontSize: item.fontSize))
                item.frame = CGRect(x: point.x - boundsSize.width / 2, y: point.y - boundsSize.height / 2, width: boundsSize.width, height: boundsSize.height)
                self.items.append(item)
                self.selectedIndex = self.items.count - 1
            }
            self.redoItems.removeAll()
            self.setNeedsDisplay()
            self.onMarkerOperation?()
            self.onSelectionChanged?()
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
        if dragMode == .createMosaic, let index = selectedIndex, items.indices.contains(index) {
            let item = items[index]
            let frame = item.lineFrame
            let screenDiagonal = hypot(frame.width, frame.height) * displayTransform().scale
            if screenDiagonal < 12 {
                items.remove(at: index)
                selectedIndex = nil
            } else {
                createdNewMarker = true
                selectedIndex = nil
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

        // 选中态的虚线框与操作把手按画布坐标画，保证任何缩放下大小一致，涂抹马赛克创建过程中不画(画框跟手碍涂抹)
        if let index = selectedIndex, items.indices.contains(index), dragMode != .createMosaic {
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
        case .mosaic:
            let mosaicImage = mosaicImageForDrawing()
            context.saveGState()
            if item.isBoxedMosaic {
                context.clip(to: item.frame)
            } else {
                let brushPath = UIBezierPath()
                brushPath.lineWidth = item.lineWidth
                brushPath.lineCapStyle = .round
                brushPath.lineJoinStyle = .round
                if let first = item.linePoints.first {
                    brushPath.move(to: first)
                    brushPath.addLine(to: item.linePoints.count > 1 ? item.linePoints[1] : first)
                    for index in 2..<max(item.linePoints.count, 2) {
                        brushPath.addLine(to: item.linePoints[index])
                    }
                }
                context.addPath(brushPath.cgPath)
                context.replacePathWithStrokedPath()
                context.clip()
            }
            mosaicImage.draw(in: CGRect(origin: .zero, size: sourceImage.size))
            context.restoreGState()
        case .watermark:
            drawWatermarkContent(item, in: context)
        }
    }

    /// 像素化整图(最近邻采样缩小到像素块网格再关插值放大回来，每块是纯色块马赛克感更强，缓存到基准图或块大小变化为止)
    private func mosaicImageForDrawing() -> UIImage {
        if let cached = cachedMosaicImage { return cached }
        let cell = max(mosaicCellSize, 2)
        let size = sourceImage.size
        let tinySize = CGSize(width: max(size.width / cell, 1), height: max(size.height / cell, 1))

        let tinyFormat = UIGraphicsImageRendererFormat.default()
        tinyFormat.scale = 1
        let tinyRenderer = UIGraphicsImageRenderer(size: tinySize, format: tinyFormat)
        let tinyImage = tinyRenderer.image { rendererContext in
            rendererContext.cgContext.interpolationQuality = .none
            sourceImage.draw(in: CGRect(origin: .zero, size: tinySize))
        }

        let fullFormat = UIGraphicsImageRendererFormat.default()
        fullFormat.scale = sourceImage.scale
        let fullRenderer = UIGraphicsImageRenderer(size: size, format: fullFormat)
        let mosaicImage = fullRenderer.image { rendererContext in
            rendererContext.cgContext.interpolationQuality = .none
            tinyImage.draw(in: CGRect(origin: .zero, size: size))
        }
        cachedMosaicImage = mosaicImage
        return mosaicImage
    }

    /// 水印内容的排版尺寸(logo与文字横排组合，图片坐标，带字时logo高为字号的1.3倍，纯logo单条时高为图短边的六分之一，纯logo平铺时高同字号1.3倍保持小而密)
    private func watermarkContentSize(text: String, logo: UIImage?, fontSize: CGFloat, tiled: Bool = false) -> CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        if !text.isEmpty {
            let textSize = (text as NSString).size(withAttributes: watermarkTextAttributes(color: .white, fontSize: fontSize))
            width += textSize.width
            height = max(height, ceil(textSize.height))
        }
        if let logo = logo {
            let logoHeight = text.isEmpty && !tiled ? min(min(sourceImage.size.width, sourceImage.size.height) / 6, max(logo.size.height, 1)) : fontSize * 1.3
            let logoWidth = max(logoHeight * logo.size.width / max(logo.size.height, 1), 1)
            if !text.isEmpty { width += fontSize * 0.4 }
            width += logoWidth
            height = max(height, logoHeight)
        }
        return CGSize(width: max(width, 1), height: max(height, 1))
    }

    /// 水印标记的边界尺寸(排版尺寸按倾斜角旋转后的外接矩形，标记的frame与选中框命中都按它算，旋转后内容才不出框)
    private func watermarkBoundsSize(contentSize: CGSize) -> CGSize {
        let radians = abs(watermarkRotation) * .pi / 180
        return CGSize(width: contentSize.width * cos(radians) + contentSize.height * sin(radians),
                      height: contentSize.width * sin(radians) + contentSize.height * cos(radians))
    }

    /// 水印文字排版属性(颜色按传入色乘外观透明度)
    private func watermarkTextAttributes(color: UIColor, fontSize: CGFloat) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byClipping
        return [.font: UIFont.boldSystemFont(ofSize: fontSize), .foregroundColor: color.withAlphaComponent(appearance.watermarkAlpha), .paragraphStyle: paragraph]
    }

    /// 画水印内容(单条以标记中心旋转绘制，平铺先裁剪到图片区域再旋转按网格交错铺满，每组都是logo与文字的组合)
    private func drawWatermarkContent(_ item: WYImageMarkerItem, in context: CGContext) {
        let contentSize = watermarkContentSize(text: item.text, logo: item.watermarkImage, fontSize: item.fontSize)
        context.saveGState()
        if item.isTiledWatermark {
            let diagonal = hypot(sourceImage.size.width, sourceImage.size.height)
            let rowSpacing = contentSize.height * 1.9
            let columnSpacing = contentSize.width + contentSize.height * 1.1

            // 网格覆盖范围按对角线算，边缘格子的内容会伸出图片，先裁剪到图片区域保证只铺在照片上
            context.clip(to: CGRect(origin: .zero, size: sourceImage.size))
            context.translateBy(x: sourceImage.size.width / 2, y: sourceImage.size.height / 2)
            context.rotate(by: watermarkRotation * .pi / 180)
            let rowCount = Int(ceil(diagonal / max(rowSpacing, 1))) / 2 + 1
            let columnCount = Int(ceil(diagonal / max(columnSpacing, 1))) / 2 + 1
            for row in -rowCount...rowCount {
                let rowOffset = (row % 2 == 0) ? 0 : columnSpacing / 2
                for column in -columnCount...columnCount {
                    let center = CGPoint(x: CGFloat(column) * columnSpacing + rowOffset, y: CGFloat(row) * rowSpacing)
                    drawWatermarkUnit(text: item.text, logo: item.watermarkImage, fontSize: item.fontSize, color: item.color, contentSize: contentSize, center: center, tiled: true, in: context)
                }
            }
        } else {
            context.translateBy(x: item.frame.midX, y: item.frame.midY)
            context.rotate(by: watermarkRotation * .pi / 180)
            drawWatermarkUnit(text: item.text, logo: item.watermarkImage, fontSize: item.fontSize, color: item.color, contentSize: contentSize, center: .zero, tiled: false, in: context)
        }
        context.restoreGState()
    }

    /// 画一组水印内容(logo与文字横排，以center为内容中心，上下文已旋转到位)
    private func drawWatermarkUnit(text: String, logo: UIImage?, fontSize: CGFloat, color: UIColor, contentSize: CGSize, center: CGPoint, tiled: Bool, in context: CGContext) {
        let originX = center.x - contentSize.width / 2
        var cursorX = originX
        if let logo = logo {
            let logoHeight = text.isEmpty && !tiled ? min(min(sourceImage.size.width, sourceImage.size.height) / 6, max(logo.size.height, 1)) : fontSize * 1.3
            let logoWidth = max(logoHeight * logo.size.width / max(logo.size.height, 1), 1)
            let logoRect = CGRect(x: cursorX, y: center.y - logoHeight / 2, width: logoWidth, height: logoHeight)
            context.saveGState()
            context.setAlpha(appearance.watermarkAlpha)
            logo.draw(in: logoRect)
            context.restoreGState()
            cursorX += logoWidth + fontSize * 0.4
        }
        if !text.isEmpty {
            let attributes = watermarkTextAttributes(color: color, fontSize: fontSize)
            let textSize = (text as NSString).size(withAttributes: attributes)
            (text as NSString).draw(at: CGPoint(x: cursorX, y: center.y - textSize.height / 2), withAttributes: attributes)
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
        isMultipleTouchEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:))))
        addGestureRecognizer(panGesture)
        addGestureRecognizer(pinchGesture)
    }

    /// 画布尺寸变化时强制重画(切模式画布高度跳变时旧位图会被系统拉伸铺满新尺寸显示成图片变大变形)
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 点画布(点标记选中它，再点选中的文本或水印重新编辑，点空白处文本水印工具落字其余取消选中)
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
            if selectedIndex == hitIndex, items[hitIndex].type == .text || items[hitIndex].type == .watermark {
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
        } else if activeTool == .watermark {
            requestNewWatermark(atImagePoint: imageLocation)
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

    /// 双指捏合查看(增量缩放画布，锚点跟在两指中点且缩放平移一体，只影响显示与命中不影响标记存储坐标与导出)
    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:

            // 画标记拖拽中转捏合，先强制结束拖拽再把触摸让给捏合
            if panGesture.state == .began || panGesture.state == .changed {
                if panGesture.isEnabled {
                    panGesture.isEnabled = false
                    panGesture.isEnabled = true
                }
            }
            lastPinchScale = gesture.scale
        case .changed:
            let incremental = gesture.scale / lastPinchScale
            lastPinchScale = gesture.scale
            let old = displayTransform()
            let anchor = gesture.location(in: self)
            let newZoom = min(max(userZoom * incremental, 1), 8)
            let newScale = old.scale * newZoom / userZoom

            // 锚点跟手(两指中点下的内容保持不动)反解出缩放后的显示原点
            let anchoredOriginX = anchor.x - (anchor.x - old.origin.x) * newScale / old.scale
            let anchoredOriginY = anchor.y - (anchor.y - old.origin.y) * newScale / old.scale
            userZoom = newZoom

            // 平移钳制(内容不大于画布时归零保持居中，大于画布时不许把内容拖出画布边缘)
            let contentWidth = validRegion.width * newScale
            let contentHeight = validRegion.height * newScale
            var panX = anchoredOriginX - (bounds.width - contentWidth) / 2
            var panY = anchoredOriginY - (bounds.height - contentHeight) / 2
            if contentWidth <= bounds.width {
                panX = 0
            } else {
                panX = min(max(panX, -(contentWidth - bounds.width) / 2), (contentWidth - bounds.width) / 2)
            }
            if contentHeight <= bounds.height {
                panY = 0
            } else {
                panY = min(max(panY, -(contentHeight - bounds.height) / 2), (contentHeight - bounds.height) / 2)
            }
            userPan = CGPoint(x: panX, y: panY)
            setNeedsDisplay()
        default:
            break
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

        // 涂抹马赛克工具下拖到未选中的标记上不选中它，当作空白处新建涂抹(连续涂抹不被旧涂抹挡住，编辑旧涂抹靠点按选中)
        let brushPainting = activeTool == .mosaic && !mosaicDrawsBox
        if let hitIndex = markerIndex(atImagePoint: imageLocation), !(brushPainting && hitIndex != selectedIndex) {
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
        case .mosaic:
            item.type = .mosaic
            item.lineWidth = defaultMosaicBrushWidth
            if mosaicDrawsBox {
                item.isBoxedMosaic = true
                item.frame = CGRect(origin: imageLocation, size: .zero)
                items.append(item)
                selectedIndex = items.count - 1
                dragStartItem = item
                dragStartImagePoint = imageLocation
                dragMode = .createShape
            } else {
                item.linePoints = [imageLocation]
                items.append(item)
                selectedIndex = items.count - 1
                dragStartItem = item
                dragStartImagePoint = imageLocation
                dragMode = .createMosaic
            }
            setNeedsDisplay()
        case .watermark:
            dragMode = .none
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
            } else if item.type == .line || (item.type == .mosaic && !item.isBoxedMosaic) {
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
            } else if item.type == .watermark {

                // 水印拖右下角按宽度比例缩放字号，logo与整体排版跟着重算
                let oldWidth = max(item.frame.width, 1)
                let newWidth = max(imageLocation.x - item.frame.origin.x, item.fontSize)
                let ratio = newWidth / oldWidth
                item.fontSize = min(max(item.fontSize * ratio, 8), 600)
                item.frame.size = watermarkBoundsSize(contentSize: watermarkContentSize(text: item.text, logo: item.watermarkImage, fontSize: item.fontSize))
            } else if item.type == .mosaic, !item.isBoxedMosaic {

                // 涂抹马赛克拖右下角按新旧宽高比例等比缩放全部轨迹点与笔刷宽度
                let oldFrame = item.effectiveFrame
                let newWidth = max(imageLocation.x - item.frame.origin.x, item.lineWidth * 2)
                let newHeight = max(imageLocation.y - item.frame.origin.y, item.lineWidth * 2)
                let ratioX = newWidth / max(oldFrame.width, 1)
                let ratioY = newHeight / max(oldFrame.height, 1)
                for pointIndex in item.linePoints.indices {
                    item.linePoints[pointIndex].x = oldFrame.origin.x + (item.linePoints[pointIndex].x - oldFrame.origin.x) * ratioX
                    item.linePoints[pointIndex].y = oldFrame.origin.y + (item.linePoints[pointIndex].y - oldFrame.origin.y) * ratioY
                }
                item.lineWidth = max(item.lineWidth * sqrt(ratioX * ratioY), 2)
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
        case .createLine, .createMosaic:
            guard dragStartItem != nil else { return }
            if items[index].isStraightLine {

                // 直线形态只保留首尾两个点
                if items[index].linePoints.count == 1 {
                    items[index].linePoints.append(imageLocation)
                } else {
                    items[index].linePoints[items[index].linePoints.count - 1] = imageLocation
                }
            } else {

                // 自由划线与涂抹马赛克记录手指轨迹，离上一个点太近就不记，控制点的数量
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

extension WYImageMarkerView: UIGestureRecognizerDelegate {

    /// 捏合与画标记拖动允许同时识别(画线中第二指落下可无缝转捏合，捏合开始时手动结束拖拽)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return (gestureRecognizer === pinchGesture && otherGestureRecognizer === panGesture) || (gestureRecognizer === panGesture && otherGestureRecognizer === pinchGesture)
    }
}
