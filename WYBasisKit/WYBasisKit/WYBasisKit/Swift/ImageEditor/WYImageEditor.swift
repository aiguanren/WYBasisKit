//
//  WYImageEditor.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/15.
//

import UIKit

/// 裁剪形状(矩形按四边形输出，圆形输出正方形图片且四角透明)
@objc public enum WYImageCropShape: Int {
    /// 矩形裁剪
    case rectangle = 0
    /// 圆形裁剪
    case circle = 1
}

/// 标记类型(在图片上写写画画用的五种工具)
@objc public enum WYImageMarkerType: Int {
    /// 文本标记(写一段字到指定位置)
    case text = 0
    /// 矩形标记(画一个方框圈出重点)
    case rectangle = 1
    /// 圆形标记(画一个圈圈出重点)
    case circle = 2
    /// 箭头标记(画一支箭头指向重点)
    case arrow = 3
    /// 划线标记(两点连直线或跟随手指自由划线)
    case line = 4
}

/// 编辑器界面外观配置(全部属性都有默认值，按需覆盖，不设置时与默认外观一致)
public struct WYImageEditorAppearance {

    /// 画布背景色(裁剪与标记画布的底色)
    public var canvasBackgroundColor: UIColor = .black

    /// 裁剪遮罩暗度(0全透明到1全黑，框外区域的压暗程度)
    public var maskDimmingAmount: CGFloat = 0.62

    /// 裁剪框边线颜色
    public var cropBorderColor: UIColor = .white

    /// 裁剪框边线宽度(单位为点)
    public var cropBorderWidth: CGFloat = 1.5

    /// 九宫格辅助线颜色(仅矩形裁剪画)
    public var gridLineColor: UIColor = UIColor(white: 1, alpha: 0.4)

    /// 裁剪把手颜色(四角L形把手与四边短把手)
    public var handleColor: UIColor = .white

    /// 四角L形把手的臂长(单位为点)
    public var handleArmLength: CGFloat = 18

    /// 标记选中态虚线颜色(主虚线，底下自动垫一圈半透明黑描边保证浅色背景上可读)
    public var selectionDashColor: UIColor = .white

    /// 标记选中态虚线线宽(单位为点)
    public var selectionDashWidth: CGFloat = 1.5

    /// 标记选中态虚线外扩边距(单位为点，虚线框相对标记边界四围的留白)
    public var selectionInset: CGFloat = 6

    /// 选中态删除按钮底色(左上角带叉圆钮)
    public var deleteButtonColor: UIColor = UIColor.black.withAlphaComponent(0.75)

    /// 选中态缩放与端点把手圆点颜色
    public var resizeDotColor: UIColor = .white

    /// 颜色选择条色板(按顺序展示，传空数组时界面不显示颜色行)
    public var markerPalette: [UIColor] = [UIColor.white, UIColor.black, UIColor(red: 1, green: 0.84, blue: 0.03, alpha: 1), UIColor(red: 1, green: 0.27, blue: 0.23, alpha: 1), UIColor(red: 0.22, green: 0.8, blue: 0.35, alpha: 1), UIColor(red: 0.04, green: 0.52, blue: 1, alpha: 1), UIColor(red: 0.69, green: 0.33, blue: 0.87, alpha: 1)]

    /// 线宽档位倍率(相对默认线宽的倍数序列，界面按序展示圆点)
    public var lineWidthRatios: [CGFloat] = [0.5, 1, 2, 3.5]

    /// 字号档位倍率(相对默认字号的倍数序列，界面按序展示字母A)
    public var fontSizeRatios: [CGFloat] = [0.6, 1, 1.6, 2.4]

    /// 标记工具条背景色
    public var toolbarBackgroundColor: UIColor = UIColor(white: 0.08, alpha: 1)

    /// 模式分段控件底色(裁剪标记两个胶囊所在的圆角容器)
    public var segmentedBackgroundColor: UIColor = UIColor(white: 1, alpha: 0.12)

    /// 模式分段控件选中胶囊底色
    public var segmentedSelectedBackgroundColor: UIColor = .white

    /// 模式分段控件选中胶囊文字颜色
    public var segmentedSelectedTextColor: UIColor = .black

    /// 模式分段控件未选中胶囊文字颜色
    public var segmentedTextColor: UIColor = .white

    /// 顶部栏普通按钮文字颜色(取消与还原)
    public var topBarButtonColor: UIColor = .white

    /// 顶部栏裁剪按钮文字颜色(默认与还原按钮一致)
    public var topBarCropButtonColor: UIColor = .white

    /// 顶部栏完成按钮文字颜色
    public var topBarDoneColor: UIColor = .systemBlue

    /// 选中态强调色(当前模式按钮、当前工具、生效档位圆点与字号的点亮色)
    public var accentColor: UIColor = .systemBlue

    public init() {}
}

/// 编辑器配置(全部属性都有默认值，按需改)
public struct WYImageEditorConfiguration {

    /// 裁剪形状(默认矩形)
    public var cropShape: WYImageCropShape = .rectangle

    /// 固定裁剪输出尺寸(单位为像素；宽高任一为0表示不固定，由用户自由拖动裁剪框决定；圆形裁剪时取宽高较小边做直径)
    public var cropSize: CGSize = .zero

    /// 是否允许裁剪(false时编辑器只有标记功能；与allowsMarking同时为false时按只裁剪处理)
    public var allowsCropping: Bool = true

    /// 是否允许在图片上做标记(false时编辑器只有裁剪功能)
    public var allowsMarking: Bool = true

    /// 标记默认颜色(选中有标记时改颜色会直接应用到它)
    public var markerColor: UIColor = .white

    /// 标记线条宽度(单位为像素；0表示按图片宽度自动配一个合适的值)
    public var markerLineWidth: CGFloat = 0

    /// 文本标记字号(单位为像素；0表示按图片宽度自动配一个合适的值)
    public var markerTextFontSize: CGFloat = 0

    /// 划线工具的默认形态(true为两点连成直线，false为跟随手指自由划线)
    public var lineDrawsStraight: Bool = false

    /// 界面上是否显示粗细与字号选择行(false时用户只能用配置定的默认粗细字号)
    public var showsStyleOptions: Bool = true

    /// 界面上是否显示颜色选择条(false时用户只能用markerColor定的默认颜色)
    public var showsColorOptions: Bool = true

    /// 编辑时图片是否支持捏合缩放(false时只能拖动平移图片)
    public var allowsImageZoom: Bool = true

    /// 界面外观(颜色线宽色板档位等UI细节都从这里改，不设置用默认外观)
    public var appearance: WYImageEditorAppearance = WYImageEditorAppearance()

    public init() {}
}

/// 编辑器完成与取消的回调(delegate方式，与Block回调二选一或同时使用)
public protocol WYImageEditorViewControllerDelegate: AnyObject {

    /**
     * 编辑完成(点完成按钮时回调，成品图已按裁剪形状与标记绘制好)
     * - Parameters:
     *   - editor: 回调来源编辑器
     *   - image: 编辑成品图(圆形裁剪时是四角透明的PNG)
     */
    func imageEditorViewController(_ editor: WYImageEditorViewController, didFinishEditing image: UIImage)

    /**
     * 取消编辑(点取消按钮或侧滑关闭时回调)
     * - Parameter editor: 回调来源编辑器
     */
    func imageEditorViewControllerDidCancel(_ editor: WYImageEditorViewController)
}

/**
 * 相片编辑器(相册选图或拍照后拿UIImage进来，裁剪加标记一次完成)
 * 用法示例：
 * let editor = WYImageEditorViewController(image: image)
 * editor.onFinish = { result in ... }
 * present(editor, animated: true)
 */
public class WYImageEditorViewController: UIViewController {

    /// 进入编辑器的原始图片(内部已把方向摆正，宽高直接可用)
    public let image: UIImage

    /// 编辑配置(present前设置生效，present后改配置不保证即时反映)
    public var configuration: WYImageEditorConfiguration

    /// 编辑完成回调Block(与delegate同时设置时两边都会回调)
    public var onFinish: ((UIImage) -> Void)?

    /// 取消编辑回调Block(与delegate同时设置时两边都会回调)
    public var onCancel: (() -> Void)?

    /// 编辑回调delegate(与Block同时设置时两边都会回调)
    public weak var editorDelegate: WYImageEditorViewControllerDelegate?

    /**
     * 便利弹出入口(一行代码从指定控制器全屏弹出编辑器)
     * - Parameters:
     *   - viewController: 从哪个控制器弹出(编辑器以全屏模态方式盖在它上面)
     *   - image: 要编辑的图片
     *   - configuration: 编辑配置(不传用默认配置)
     *   - handler: 编辑结果回调(编辑成成品图回调图片，取消回调nil)
     */
    public static func present(from viewController: UIViewController, image: UIImage, configuration: WYImageEditorConfiguration = WYImageEditorConfiguration(), handler: ((UIImage?) -> Void)? = nil) {
        let editor = WYImageEditorViewController(image: image, configuration: configuration)
        editor.onFinish = { resultImage in
            handler?(resultImage)
        }
        editor.onCancel = {
            handler?(nil)
        }
        editor.modalPresentationStyle = .fullScreen
        editor.modalTransitionStyle = .coverVertical
        viewController.present(editor, animated: true)
    }

    /**
     * 编辑器初始化
     * - Parameters:
     *   - image: 要编辑的图片(内部会把方向不正的图片先摆正，不用提前处理)
     *   - configuration: 编辑配置(不传用默认配置)
     */
    public init(image: UIImage, configuration: WYImageEditorConfiguration = WYImageEditorConfiguration()) {

        // 方向不UP的图片先重画摆正，后面所有坐标计算都按方向向上的图处理
        if image.imageOrientation == .up {
            self.image = image
        } else {
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = image.scale
            let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
            self.image = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: image.size))
            }
        }
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 顶部取消按钮(编辑 discard 出口)
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(configuration.appearance.topBarButtonColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 顶部还原按钮(裁剪和标记全部退回原图状态)
    private lazy var revertButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("还原", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(configuration.appearance.topBarButtonColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.addTarget(self, action: #selector(revertButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 顶部完成按钮(按当前裁剪与标记出成品图并回调)
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("完成", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(configuration.appearance.topBarDoneColor, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 顶部标题按钮(常态显示编辑二字静态不可点，裁剪框调过后变蓝字裁剪，点了应用裁剪)
    private lazy var titleLabel: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(configuration.appearance.accentColor, for: .disabled)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 裁剪模式切换按钮(分段控件左胶囊)
    private lazy var cropModeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("裁剪", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 13
        button.addTarget(self, action: #selector(cropModeButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 标记模式切换按钮(分段控件右胶囊)
    private lazy var markModeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("标记", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 13
        button.addTarget(self, action: #selector(markModeButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 模式分段控件(两个胶囊居中悬浮，不再整条铺背景)
    private lazy var modeSegmentedControl: UIView = {
        let view = UIView()
        view.backgroundColor = configuration.appearance.segmentedBackgroundColor
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()

    /// 模式切换底条(裁剪与标记两个入口并排)
    private lazy var modeBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = .clear
        return bar
    }()

    /// 标记工具条(五种工具加撤销删除加颜色条加粗细字号档)
    private lazy var markerToolbar: UIView = {
        let bar = UIView()
        bar.backgroundColor = configuration.appearance.toolbarBackgroundColor
        return bar
    }()

    /// 裁剪视图(捏合缩放拖动图片加拖拽裁剪框都在它里面完成)
    private lazy var cropperView: WYImageCropperView = {
        let view = WYImageCropperView()
        view.backgroundColor = configuration.appearance.canvasBackgroundColor
        return view
    }()

    /// 标记视图(显示当前裁剪区域内的图片，在上面画标记)
    private lazy var markerView: WYImageMarkerView = {
        let view = WYImageMarkerView()
        view.backgroundColor = configuration.appearance.canvasBackgroundColor
        return view
    }()

    /// 标记工具按钮数组(顺序为文本矩形圆形箭头划线，图文上下排列用WYBasisKit的UIButton扩展调整)
    private lazy var markerToolButtons: [UIButton] = {
        let titles = [WYLocalized("文本", table: WYBasisKitConfig.kitLocalizableTable),
                      WYLocalized("矩形", table: WYBasisKitConfig.kitLocalizableTable),
                      WYLocalized("圆形", table: WYBasisKitConfig.kitLocalizableTable),
                      WYLocalized("箭头", table: WYBasisKitConfig.kitLocalizableTable),
                      WYLocalized("划线", table: WYBasisKitConfig.kitLocalizableTable)]
        let icons = [WYImageEditorIcon.text, WYImageEditorIcon.rectangle, WYImageEditorIcon.circle, WYImageEditorIcon.arrow, WYImageEditorIcon.line]
        return titles.enumerated().map { index, title in
            let button = UIButton(type: .custom)
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.setTitleColor(configuration.appearance.accentColor, for: .selected)
            button.setTitleColor(configuration.appearance.accentColor, for: [.selected, .highlighted])
            button.setImage(icons[index], for: .normal)
            button.setImage(icons[index].withTintColor(configuration.appearance.accentColor, renderingMode: .alwaysOriginal), for: .selected)
            button.tintColor = .white
            button.titleLabel?.font = .systemFont(ofSize: 11)
            button.imageView?.contentMode = .scaleAspectFit
            button.addTarget(self, action: #selector(markerToolButtonTapped(_:)), for: .touchUpInside)
            button.tag = index
            return button
        }
    }()

    /// 直线形态切换按钮(划线语境显示，点后划线为两点连直线)
    private lazy var straightChipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("直线", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.setTitleColor(.black, for: [.selected, .highlighted])
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(lineShapeChipTapped(_:)), for: .touchUpInside)
        return button
    }()

    /// 自由形态切换按钮(划线语境显示，点后划线跟随手指轨迹)
    private lazy var freeChipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("自由", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.setTitleColor(.black, for: [.selected, .highlighted])
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(lineShapeChipTapped(_:)), for: .touchUpInside)
        return button
    }()

    /// 线宽档位圆点按钮数组(矩形圆形箭头划线语境显示，圆点大小示意粗细)
    private lazy var lineWidthDotButtons: [UIButton] = {
        return (0..<4).map { index in
            let button = UIButton(type: .custom)
            button.backgroundColor = .white
            button.addTarget(self, action: #selector(lineWidthDotTapped(_:)), for: .touchUpInside)
            button.tag = index
            return button
        }
    }()

    /// 字号档位按钮数组(文本语境显示，字母A的大小示意字号)
    private lazy var fontSizeButtons: [UIButton] = {
        return (0..<4).map { index in
            let button = UIButton(type: .custom)
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: CGFloat([12, 16, 21, 27][index])), .foregroundColor: UIColor.white]
            button.setAttributedTitle(NSAttributedString(string: "A", attributes: attributes), for: .normal)
            button.addTarget(self, action: #selector(fontSizeButtonTapped(_:)), for: .touchUpInside)
            button.tag = index
            return button
        }
    }()

    /// 撤销按钮(撤掉最后画的那一个标记)
    private lazy var undoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(WYImageEditorIcon.undo, for: .normal)
        button.tintColor = .white
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 删除按钮(删掉当前选中的标记，没选中时按下没效果)
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(WYImageEditorIcon.trash, for: .normal)
        button.tintColor = .white
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 颜色圆点按钮数组(按外观色板生成，点的瞬间作用于选中的标记或之后的标记)
    private lazy var colorButtons: [UIButton] = {
        return configuration.appearance.markerPalette.map { color in
            let button = UIButton(type: .custom)
            button.backgroundColor = color
            button.layer.cornerRadius = 13
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(white: 1, alpha: 0.35).cgColor
            button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            return button
        }
    }()

    /// 当前是否处于标记模式(false表示裁剪模式)
    private var isMarkMode = false

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.canvasBackgroundColor

        view.addSubview(cropperView)
        view.addSubview(markerView)
        view.addSubview(modeBar)
        markerToolbar.isHidden = true
        view.addSubview(markerToolbar)
        view.addSubview(cancelButton)
        view.addSubview(titleLabel)
        view.addSubview(revertButton)
        view.addSubview(doneButton)

        let bothModesEnabled = configuration.allowsCropping && configuration.allowsMarking
        if bothModesEnabled {
            modeBar.addSubview(modeSegmentedControl)
            modeSegmentedControl.addSubview(cropModeButton)
            modeSegmentedControl.addSubview(markModeButton)
            cropModeButton.isSelected = true
            refreshModeSegmented()
        } else {
            modeBar.isHidden = true

            // 单模式直接进入对应模式，裁剪与标记都关时按只裁剪兜底
            if !configuration.allowsCropping, configuration.allowsMarking {
                setMarkMode(true)
            }
        }
        refreshTitleForPendingCrop()

        markerToolButtons.forEach { markerToolbar.addSubview($0) }
        markerToolbar.addSubview(undoButton)
        markerToolbar.addSubview(deleteButton)
        if configuration.showsColorOptions {
            colorButtons.forEach { markerToolbar.addSubview($0) }
        }
        if configuration.showsStyleOptions {
            markerToolbar.addSubview(straightChipButton)
            markerToolbar.addSubview(freeChipButton)
            lineWidthDotButtons.forEach { markerToolbar.addSubview($0) }
            fontSizeButtons.forEach { markerToolbar.addSubview($0) }
        }

        cropperView.setup(image: image, shape: configuration.cropShape, fixedOutputSize: configuration.cropSize == .zero ? nil : configuration.cropSize, appearance: configuration.appearance, zoomEnabled: configuration.allowsImageZoom)

        // 自由模式松手应用裁剪后，标记画布跟着换基准并平移全部标记坐标
        cropperView.onCropCommitted = { [weak self] croppedImage, region in
            self?.markerView.applyCroppedBase(croppedImage, region: region)
            self?.refreshTitleForPendingCrop()
        }

        markerView.setup(image: image,
                         defaultColor: configuration.markerColor,
                         lineWidth: configuration.markerLineWidth,
                         textFontSize: configuration.markerTextFontSize,
                         straightLine: configuration.lineDrawsStraight,
                         appearance: configuration.appearance)
        markerView.onRequestTextEdit = { [weak self] text, completion in
            self?.showTextInputAlert(existingText: text, completion: completion)
        }
        markerView.onSelectionChanged = { [weak self] in
            guard let self = self else { return }
            self.refreshStyleRow()
            self.refreshColorSelection(color: self.markerView.activeColor())
        }
        markerView.isHidden = true

        // 默认文本工具选中，颜色圆点与字号档位带上选中态
        markerToolButtons.first?.isSelected = true
        markerView.activeTool = .text
        refreshColorSelection(color: configuration.markerColor)
        refreshStyleRow()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        let safeLeft = view.safeAreaInsets.left
        let safeRight = view.safeAreaInsets.right
        let width = view.bounds.width

        cancelButton.frame = CGRect(x: safeLeft + 12, y: safeTop + 4, width: 60, height: 44)
        revertButton.frame = CGRect(x: width - safeRight - 152, y: safeTop + 4, width: 60, height: 44)
        doneButton.frame = CGRect(x: width - safeRight - 80, y: safeTop + 4, width: 68, height: 44)
        titleLabel.frame = CGRect(x: (width - 160) / 2, y: safeTop + 4, width: 160, height: 44)

        let modeBarHeight: CGFloat = modeBar.isHidden ? 0 : 46
        var toolbarHeight: CGFloat = 56
        if configuration.showsColorOptions {
            toolbarHeight += 38
        }
        if configuration.showsStyleOptions {
            toolbarHeight += 40
        }
        let bottomBarsHeight = isMarkMode ? modeBarHeight + toolbarHeight : modeBarHeight
        let canvasY = safeTop + 52
        let canvasHeight = view.bounds.height - canvasY - safeBottom - bottomBarsHeight
        cropperView.frame = CGRect(x: 0, y: canvasY, width: width, height: canvasHeight)
        markerView.frame = cropperView.frame

        modeBar.frame = CGRect(x: 0, y: view.bounds.height - safeBottom - bottomBarsHeight, width: width, height: modeBarHeight)
        if !modeBar.isHidden {
            let controlWidth: CGFloat = 200
            let controlHeight: CGFloat = 32
            modeSegmentedControl.frame = CGRect(x: (width - controlWidth) / 2, y: (modeBarHeight - controlHeight) / 2, width: controlWidth, height: controlHeight)
            cropModeButton.frame = CGRect(x: 3, y: 3, width: controlWidth / 2 - 5, height: controlHeight - 6)
            markModeButton.frame = CGRect(x: controlWidth / 2 + 2, y: 3, width: controlWidth / 2 - 5, height: controlHeight - 6)
        }

        if isMarkMode {
            markerToolbar.frame = CGRect(x: 0, y: modeBar.frame.maxY, width: width, height: toolbarHeight)
            layoutMarkerToolbar(width: width, height: toolbarHeight, safeLeft: safeLeft, safeRight: safeRight)
        }

        // 画布尺寸或位置变化时让裁剪视图重新适配图片(旋转屏幕或首次布局都会走到)
        if cropperView.needsRelayoutAfterBoundsChange {
            cropperView.relayoutForNewBounds()
        }
    }

    /// 布局标记工具条(第一行五个工具加撤销删除，第二行颜色圆点，第三行粗细字号档位，后两行可按配置隐藏)
    private func layoutMarkerToolbar(width: CGFloat, height: CGFloat, safeLeft: CGFloat, safeRight: CGFloat) {

        let toolCount = markerToolButtons.count + 2
        let itemSize: CGFloat = 44
        let spacing = (width - safeLeft - safeRight - CGFloat(toolCount) * itemSize) / CGFloat(toolCount + 1)
        var x = safeLeft + spacing
        for button in markerToolButtons {
            button.frame = CGRect(x: x, y: 6, width: itemSize, height: itemSize)
            x += itemSize + spacing
        }
        undoButton.frame = CGRect(x: x, y: 6, width: itemSize, height: itemSize)
        x += itemSize + spacing
        deleteButton.frame = CGRect(x: x, y: 6, width: itemSize, height: itemSize)

        var nextRowY: CGFloat = 56
        if configuration.showsColorOptions {
            let colorDiameter: CGFloat = 26
            let colorSpacing = (width - safeLeft - safeRight - CGFloat(colorButtons.count) * colorDiameter) / CGFloat(colorButtons.count + 1)
            var colorX = safeLeft + colorSpacing
            for button in colorButtons {
                button.frame = CGRect(x: colorX, y: nextRowY, width: colorDiameter, height: colorDiameter)
                colorX += colorDiameter + colorSpacing
            }
            nextRowY += 38
        }
        if configuration.showsStyleOptions {
            layoutStyleRow(width: width, y: nextRowY, safeLeft: safeLeft, safeRight: safeRight)
        }

        // 工具按钮图标在上文字在下(用WYBasisKit的UIButton扩展排版，需在frame落定后调用)
        for button in markerToolButtons {
            button.wy_adjust(position: .imageTopTitleBottom, spacing: 2)
        }
    }

    /// 布局粗细字号档位行(划线语境多两个形态切换按钮，圆点大小示意粗细，字母A大小示意字号)
    private func layoutStyleRow(width: CGFloat, y: CGFloat, safeLeft: CGFloat, safeRight: CGFloat) {

        var x = safeLeft + 10
        if !straightChipButton.isHidden {
            straightChipButton.frame = CGRect(x: x, y: y + 1, width: 54, height: 28)
            freeChipButton.frame = CGRect(x: x + 58, y: y + 1, width: 54, height: 28)
            x += 130
        }

        let dotSizes: [CGFloat] = [10, 16, 22, 30]
        if lineWidthDotButtons.first?.isHidden == false {
            var dotX = x + 14
            for (index, button) in lineWidthDotButtons.enumerated() {
                button.frame = CGRect(x: dotX, y: y + 15 - dotSizes[index] / 2, width: dotSizes[index], height: dotSizes[index])
                button.layer.cornerRadius = dotSizes[index] / 2
                dotX += dotSizes[index] + 24
            }
        }
        if fontSizeButtons.first?.isHidden == false {
            var fontX = x + 14
            for button in fontSizeButtons {
                button.frame = CGRect(x: fontX, y: y + 1, width: 40, height: 28)
                fontX += 44
            }
        }
    }

    /// 刷新粗细字号档位行(按当前选中与工具语境切换显示内容并点亮生效档位)
    private func refreshStyleRow() {
        guard configuration.showsStyleOptions else { return }

        let isTextContext = markerView.contextIsText()
        let isLineContext = markerView.contextIsLineTool()
        straightChipButton.isHidden = !isLineContext
        freeChipButton.isHidden = !isLineContext
        lineWidthDotButtons.forEach { $0.isHidden = isTextContext }
        fontSizeButtons.forEach { $0.isHidden = !isTextContext }

        let straightActive = markerView.activeStraightLine()
        straightChipButton.isSelected = straightActive
        freeChipButton.isSelected = !straightActive
        straightChipButton.backgroundColor = straightActive ? .white : UIColor(white: 0.22, alpha: 1)
        freeChipButton.backgroundColor = straightActive ? UIColor(white: 0.22, alpha: 1) : .white

        let widthIndex = markerView.activeLineWidthIndex()
        for (index, button) in lineWidthDotButtons.enumerated() {
            button.backgroundColor = index == widthIndex ? configuration.appearance.accentColor : .white
        }
        let fontIndex = markerView.activeFontSizeIndex()
        let fontSizes: [CGFloat] = [12, 16, 21, 27]
        for (index, button) in fontSizeButtons.enumerated() {
            let color: UIColor = index == fontIndex ? configuration.appearance.accentColor : .white
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: fontSizes[index]), .foregroundColor: color]
            button.setAttributedTitle(NSAttributedString(string: "A", attributes: attributes), for: .normal)
        }
        view.setNeedsLayout()
    }

    /// 弹出文本输入弹窗(新建文本标记或修改选中文本时用)
    private func showTextInputAlert(existingText: String?, completion: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: WYLocalized("输入文本", table: WYBasisKitConfig.kitLocalizableTable), message: nil, preferredStyle: .alert)
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
    @objc private func cancelButtonTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.onCancel?()
            self.editorDelegate?.imageEditorViewControllerDidCancel(self)
        }
    }

    /// 点还原(裁剪状态与全部标记退回刚进编辑器时的样子)
    @objc private func revertButtonTapped() {
        cropperView.reset()
        markerView.setup(image: image,
                         defaultColor: configuration.markerColor,
                         lineWidth: configuration.markerLineWidth,
                         textFontSize: configuration.markerTextFontSize,
                         straightLine: configuration.lineDrawsStraight,
                         appearance: configuration.appearance)
        markerView.removeAllMarkers()
        if isMarkMode {
            refreshMarkerDisplayRegion()
        }
        refreshTitleForPendingCrop()
    }

    /// 点完成(按当前裁剪范围与标记合成成品图，回调后关闭编辑器)
    @objc private func doneButtonTapped() {
        let result = renderEditedImage()
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.onFinish?(result)
            self.editorDelegate?.imageEditorViewController(self, didFinishEditing: result)
        }
    }

    /// 切到裁剪模式(显示裁剪视图，标记先记在图上不丢)
    @objc private func cropModeButtonTapped() {
        guard isMarkMode else { return }
        setMarkMode(false)
    }

    /// 切到标记模式(按当前裁剪框取景显示，标记画在图上跟着内容走)
    @objc private func markModeButtonTapped() {
        guard !isMarkMode else { return }
        setMarkMode(true)
    }

    /// 刷新顶部标题按钮(裁剪模式恒显裁剪二字与还原成对可点，标记模式显示编辑)
    private func refreshTitleForPendingCrop() {
        if !isMarkMode, configuration.allowsCropping {
            titleLabel.setTitle(WYLocalized("裁剪", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
            titleLabel.setTitleColor(configuration.appearance.topBarCropButtonColor, for: .normal)
        } else {
            titleLabel.setTitle(WYLocalized("编辑", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
            titleLabel.setTitleColor(configuration.appearance.topBarButtonColor, for: .normal)
        }
    }

    /// 点顶部裁剪按钮(按当前框立即真裁，页面只显示裁剪后的图，与还原互逆)
    @objc private func titleButtonTapped() {
        guard !isMarkMode, configuration.allowsCropping else { return }
        cropperView.commitCrop(force: true)
    }

    /// 刷新模式分段控件的胶囊选中样式(选中的铺底色配文字色，未选中透明)
    private func refreshModeSegmented() {
        let selectedBackground = configuration.appearance.segmentedSelectedBackgroundColor
        let selectedText = configuration.appearance.segmentedSelectedTextColor
        let normalText = configuration.appearance.segmentedTextColor
        cropModeButton.backgroundColor = cropModeButton.isSelected ? selectedBackground : .clear
        cropModeButton.setTitleColor(cropModeButton.isSelected ? selectedText : normalText, for: .normal)
        markModeButton.backgroundColor = markModeButton.isSelected ? selectedBackground : .clear
        markModeButton.setTitleColor(markModeButton.isSelected ? selectedText : normalText, for: .normal)
    }

    /// 切换裁剪与标记模式(带淡入淡出，进标记前先把用户调过的裁剪框应用掉)
    private func setMarkMode(_ marking: Bool) {
        print("[WYDBG2] setMarkMode(\(marking)) markerView.bounds=\(markerView.bounds.size) frame=\(markerView.frame)")
        if marking, configuration.allowsCropping {
            cropperView.commitCrop()
        }
        isMarkMode = marking
        cropModeButton.isSelected = !marking
        markModeButton.isSelected = marking
        // 顶部标题固定显示编辑二字，当前模式由底部分段胶囊表达(标题随模式变会像可点按钮造成误解)
        refreshTitleForPendingCrop()
        refreshModeSegmented()
        markerToolbar.isHidden = !marking

        if marking {
            refreshMarkerDisplayRegion()
            self.markerView.alpha = 0
            self.markerView.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.markerView.alpha = 1
            })
        } else {
            self.cropperView.alpha = 0
            self.cropperView.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.cropperView.alpha = 1
            }, completion: { _ in
                self.markerView.isHidden = true
            })
        }
        view.setNeedsLayout()
    }

    /// 当前取景区域(允许裁剪时为裁剪框映射，纯标记模式为整张基准图)
    private func currentCropRegion() -> CGRect {
        if !configuration.allowsCropping {
            let size = cropperView.currentBaseImage.size
            return CGRect(origin: .zero, size: size)
        }
        return cropperView.cropRectInImageCoordinates()
    }

    /// 让标记视图取景(自由模式进标记前已应用裁剪，显示整张基准图；固定尺寸模式按取景框显示)
    private func refreshMarkerDisplayRegion() {
        if configuration.cropSize == .zero {
            let size = cropperView.currentBaseImage.size
            markerView.updateDisplayRegion(CGRect(origin: .zero, size: size))
        } else {
            markerView.updateDisplayRegion(currentCropRegion())
        }
    }

    /// 点标记工具(选中后拖动画布生成对应标记，文本工具点画布弹输入)
    @objc private func markerToolButtonTapped(_ sender: UIControl) {
        guard let type = WYImageMarkerType(rawValue: sender.tag) else { return }
        markerToolButtons.forEach { $0.isSelected = ($0 == sender) }
        markerView.activeTool = type
        markerView.deselectMarker()
    }

    /// 点撤销(撤掉最后画的那一个标记)
    @objc private func undoButtonTapped() {
        markerView.undoLastMarker()
    }

    /// 点删除(删掉当前选中的标记)
    @objc private func deleteButtonTapped() {
        markerView.removeSelectedMarker()
    }

    /// 点直线或自由按钮(把划线形态切到点的那边，选中的划线也会跟着转换)
    @objc private func lineShapeChipTapped(_ sender: UIControl) {
        let wantStraight = sender === straightChipButton
        if markerView.activeStraightLine() != wantStraight {
            markerView.toggleStraightLine()
        }
        refreshStyleRow()
    }

    /// 点线宽圆点(有选中标记改它的线宽，没有就改默认线宽影响之后的标记)
    @objc private func lineWidthDotTapped(_ sender: UIControl) {
        let presets = markerView.presetLineWidths()
        guard sender.tag < presets.count else { return }
        markerView.applyLineWidth(presets[sender.tag])
        refreshStyleRow()
    }

    /// 点字号按钮(有选中文本标记改它的字号，没有就改默认字号影响之后的文本)
    @objc private func fontSizeButtonTapped(_ sender: UIControl) {
        let presets = markerView.presetFontSizes()
        guard sender.tag < presets.count else { return }
        markerView.applyFontSize(presets[sender.tag])
        refreshStyleRow()
    }

    /// 点颜色圆点(有选中标记直接改它，没有就当作之后标记的颜色)
    @objc private func colorButtonTapped(_ sender: UIButton) {
        guard let index = colorButtons.firstIndex(of: sender), configuration.appearance.markerPalette.indices.contains(index) else { return }
        markerView.applyColor(configuration.appearance.markerPalette[index])
        refreshColorSelection(color: configuration.appearance.markerPalette[index])
    }

    /// 刷新颜色圆点选中态(选中的颜色加一圈白描边)
    private func refreshColorSelection(color: UIColor) {
        let values = configuration.appearance.markerPalette
        for (index, button) in colorButtons.enumerated() {
            button.layer.borderWidth = values[index] == color ? 3 : 1
            button.layer.borderColor = values[index] == color ? UIColor.white.cgColor : UIColor(white: 1, alpha: 0.35).cgColor
        }
    }

    /// 合成成品图(先按裁剪框裁出区域再叠加标记，圆形裁剪时四角抠成透明)
    private func renderEditedImage() -> UIImage {
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
