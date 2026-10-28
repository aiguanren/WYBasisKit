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

/// 标记类型(在图片上写写画画用的七种工具)
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
    /// 马赛克标记(手指涂抹或拖矩形框整块打码)
    case mosaic = 5
    /// 水印标记(单条可拖动的文字或logo组合，或整图平铺防盗图)
    case watermark = 6
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

    /// 水印整体透明度(0全透明到1不透明，单条与平铺水印的logo和文字都乘它)
    public var watermarkAlpha: CGFloat = 0.5

    /// 标记工具条背景色
    public var toolbarBackgroundColor: UIColor = UIColor(white: 0.08, alpha: 1)

    /// 工具行图标按钮常态颜色(撤销重做清除三颗纯图标按钮)
    public var iconButtonColor: UIColor = .white

    /// 工具行图标按钮按住颜色(手指按住时变色，松开回常态)
    public var iconButtonHighlightedColor: UIColor = UIColor(white: 1, alpha: 0.45)

    /// 粗细档位的提示文案(nil用本地化默认，文案含换行时上下两行显示)
    public var lineWidthHintText: String?

    /// 字号档位的提示文案(nil用本地化默认，文案含换行时上下两行显示)
    public var fontSizeHintText: String?

    /// 档位提示文本颜色(粗细与字号档位行首的两行小字)
    public var hintTextColor: UIColor = UIColor(white: 1, alpha: 0.62)

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

    /// 固定裁剪输出尺寸(单位为像素，宽高任一为0表示不固定，由用户自由拖动裁剪框决定，圆形裁剪时取宽高较小边做直径)
    public var cropSize: CGSize = .zero

    /// 是否允许裁剪(false时编辑器只有标记功能，与allowsMarking同时为false时按只裁剪处理)
    public var allowsCropping: Bool = true

    /// 是否允许在图片上做标记(false时编辑器只有裁剪功能)
    public var allowsMarking: Bool = true

    /// 标记默认颜色(选中有标记时改颜色会直接应用到它)
    public var markerColor: UIColor = .white

    /// 标记线条宽度(单位为像素，0表示按图片宽度自动配一个合适的值)
    public var markerLineWidth: CGFloat = 0

    /// 文本标记字号(单位为像素，0表示按图片宽度自动配一个合适的值)
    public var markerTextFontSize: CGFloat = 0

    /// 划线工具的默认形态(true为两点连成直线，false为跟随手指自由划线)
    public var lineDrawsStraight: Bool = false

    /// 马赛克笔刷默认宽度(单位为像素，0表示按图片宽度自动配一个合适的值，仅涂抹形态用)
    public var mosaicBrushWidth: CGFloat = 0

    /// 马赛克像素块大小(单位为像素，0表示按图片宽度自动配一个合适的值，块越大打码越糊)
    public var mosaicCellSize: CGFloat = 0

    /// 马赛克工具的默认形态(true为拖矩形框整块打码，false为手指涂抹打码)
    public var mosaicDrawsBox: Bool = false

    /// 水印logo图(调用方预置，nil时界面水印语境不显示图片钮且水印不带logo)
    public var watermarkImage: UIImage? = nil

    /// 水印默认文案(落水印时输入弹窗的预填内容，nil时预填本地化默认两字)
    public var watermarkText: String? = nil

    /// 水印默认颜色(选中有水印时改颜色会直接应用到它)
    public var watermarkColor: UIColor = .white

    /// 水印字号(单位为像素，0表示按图片宽度自动配一个合适的值)
    public var watermarkFontSize: CGFloat = 0

    /// 水印倾斜角(单位为度，单条与平铺共用，0为水平，负数为逆时针)
    public var watermarkRotation: CGFloat = -30

    /// 界面上是否显示粗细与字号选择行(false时用户只能用配置定的默认粗细字号)
    public var showsStyleOptions: Bool = true

    /// 界面上是否显示颜色选择条(false时用户只能用markerColor定的默认颜色)
    public var showsColorOptions: Bool = true

    /// 裁剪页图片是否支持捏合缩放(false时只能拖动平移图片)
    public var allowsCropZoom: Bool = true

    /// 进入裁剪页时图片的初始缩放倍数(相对适配大小的倍数，1为适配显示，超过允许范围会被钳制)
    public var initialCropZoomScale: CGFloat = 1

    /// 标记页画布是否支持捏合缩放(false时只能按适配大小查看)
    public var allowsMarkZoom: Bool = true

    /// 进入标记页时画布的初始缩放倍数(相对适配大小的倍数，1为适配显示，超过允许范围会被钳制，取景变化后复位到该倍数)
    public var initialMarkZoomScale: CGFloat = 1

    /// 界面外观(颜色线宽色板档位等UI细节都从这里改，不设置用默认外观)
    public var appearance: WYImageEditorAppearance = WYImageEditorAppearance()

    public init() {}
}

/// 编辑器完成与取消的回调
@objc public protocol WYImageEditorViewControllerDelegate {

    /**
     * 编辑完成(点完成按钮时回调，成品图已按裁剪形状与标记绘制好)
     *
     * @param editor 回调来源编辑器
     * @param image  编辑成品图(圆形裁剪时是四角透明的PNG)
     */
    @objc(wy_imageEditorViewController:didFinishEditingImage:)
    optional func wy_imageEditorViewController(_ editor: WYImageEditorViewController, didFinishEditing image: UIImage)

    /**
     * 取消编辑(点取消按钮或侧滑关闭时回调)
     *
     * @param editor 回调来源编辑器
     */
    @objc(wy_imageEditorViewControllerDidCancel:)
    optional func wy_imageEditorViewControllerDidCancel(_ editor: WYImageEditorViewController)
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
    public var onFinish: ((_ editedImage: UIImage) -> Void)?

    /// 取消编辑回调Block(与delegate同时设置时两边都会回调)
    public var onCancel: (() -> Void)?

    /// 编辑回调delegate(与Block同时设置时两边都会回调)
    public weak var editorDelegate: WYImageEditorViewControllerDelegate?

    /**
     * 便利弹出入口(一行代码从指定控制器全屏弹出编辑器)
     *   @param viewController 从哪个控制器弹出(编辑器以全屏模态方式盖在它上面)
     *   @param image 要编辑的图片
     *   @param configuration 编辑配置(不传用默认配置)
     *   @param handler 编辑结果回调(编辑成成品图回调图片，取消回调nil)
     */
    public static func present(from viewController: UIViewController, image: UIImage, configuration: WYImageEditorConfiguration = WYImageEditorConfiguration(), handler: ((_ resultImage: UIImage?) -> Void)? = nil) {
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
     *   @param image 要编辑的图片(内部会把方向不正的图片先摆正，不用提前处理)
     *   @param configuration 编辑配置(不传用默认配置)
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

    /// 顶部取消按钮(放弃编辑的出口)
    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(configuration.appearance.topBarButtonColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels))
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 顶部还原按钮(裁剪和标记全部退回原图状态)
    lazy var revertButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("还原", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(configuration.appearance.topBarButtonColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels))
        button.addTarget(self, action: #selector(revertButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 顶部完成按钮(按当前裁剪与标记出成品图并回调)
    lazy var doneButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("完成", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(configuration.appearance.topBarDoneColor, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels))
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 顶部标题按钮(常态显示编辑二字静态不可点，裁剪框调过后变蓝字裁剪，点了应用裁剪)
    lazy var titleLabel: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(configuration.appearance.accentColor, for: .disabled)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels), weight: .semibold)
        button.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 裁剪模式切换按钮(分段控件左胶囊)
    lazy var cropModeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("裁剪", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(13, WYBasisKitConfig.defaultScreenPixels), weight: .semibold)
        button.layer.cornerRadius = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels)
        button.addTarget(self, action: #selector(cropModeButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 标记模式切换按钮(分段控件右胶囊)
    lazy var markModeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("标记", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(13, WYBasisKitConfig.defaultScreenPixels), weight: .semibold)
        button.layer.cornerRadius = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels)
        button.addTarget(self, action: #selector(markModeButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 模式分段控件(两个胶囊居中悬浮，不再整条铺背景)
    lazy var modeSegmentedControl: UIView = {
        let view = UIView()
        view.backgroundColor = configuration.appearance.segmentedBackgroundColor
        view.layer.cornerRadius = UIDevice.wy_screenWidth(15, WYBasisKitConfig.defaultScreenPixels)
        view.layer.masksToBounds = true
        return view
    }()

    /// 模式切换底条(裁剪与标记两个入口并排)
    lazy var modeBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = .clear
        return bar
    }()

    /// 标记工具条(五种工具加撤销重做清除加颜色条加粗细字号档，工具行放不下时可左右滑动)
    lazy var markerToolbar: UIView = {
        let bar = UIView()
        bar.backgroundColor = configuration.appearance.toolbarBackgroundColor
        return bar
    }()

    /// 工具行横向滚动容器(按钮多到一行放不下时左右滑动查看，放得下时与颜色档位行统一左对齐)
    lazy var toolRowScrollView: UIScrollView = {
        return makeMarkerRowScrollView()
    }()

    lazy var colorRowScrollView: UIScrollView = makeMarkerRowScrollView()

    lazy var styleRowScrollView: UIScrollView = makeMarkerRowScrollView()

    /// 裁剪视图(捏合缩放拖动图片加拖拽裁剪框都在它里面完成)
    lazy var cropperView: WYImageCropperView = {
        let view = WYImageCropperView()
        view.backgroundColor = configuration.appearance.canvasBackgroundColor
        return view
    }()

    /// 标记视图(显示当前裁剪区域内的图片，在上面画标记)
    lazy var markerView: WYImageMarkerView = {
        let view = WYImageMarkerView()
        view.backgroundColor = configuration.appearance.canvasBackgroundColor
        return view
    }()

    /// 标记工具按钮数组(顺序为文本矩形圆形箭头划线马赛克水印，图文上下排列用WYBasisKit的UIButton扩展调整)
    lazy var markerToolButtons: [UIButton] = {
        let titles = [WYLocalized("文本", table: WYBasisKitConfig.kitLocalizableTable),
                      WYLocalized("矩形", table: WYBasisKitConfig.kitLocalizableTable),
                      WYLocalized("圆形", table: WYBasisKitConfig.kitLocalizableTable),
                      WYLocalized("箭头", table: WYBasisKitConfig.kitLocalizableTable),
                      WYLocalized("划线", table: WYBasisKitConfig.kitLocalizableTable),
                      WYLocalized("马赛克", table: WYBasisKitConfig.kitLocalizableTable),
                      WYLocalized("水印", table: WYBasisKitConfig.kitLocalizableTable)]
        let icons = [WYImageEditorIcon.text, WYImageEditorIcon.rectangle, WYImageEditorIcon.circle, WYImageEditorIcon.arrow, WYImageEditorIcon.line, WYImageEditorIcon.mosaic, WYImageEditorIcon.watermark]
        return titles.enumerated().map { index, title in
            let button = UIButton(type: .custom)
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.setTitleColor(configuration.appearance.accentColor, for: .selected)
            button.setTitleColor(configuration.appearance.accentColor, for: [.selected, .highlighted])
            button.setImage(icons[index], for: .normal)
            button.setImage(icons[index].withTintColor(configuration.appearance.accentColor, renderingMode: .alwaysOriginal), for: .selected)
            button.tintColor = .white
            button.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(11, WYBasisKitConfig.defaultScreenPixels))
            button.imageView?.contentMode = .scaleAspectFit
            button.addTarget(self, action: #selector(markerToolButtonTapped(_:)), for: .touchUpInside)
            button.tag = index
            return button
        }
    }()

    /// 档位提示文本(粗细档前显示画笔粗细、字号档前显示文本字号，随工具语境切换且文案可配置)
    lazy var styleHintLabel: UILabel = {
        let label = UILabel()
        label.textColor = configuration.appearance.hintTextColor
        label.font = .systemFont(ofSize: UIFont.wy_fontSize(10, WYBasisKitConfig.defaultScreenPixels))
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    /// 直线形态切换按钮(划线语境显示，与自由按钮拼成横跨两列的双段胶囊，此为左半段只有左侧外圆角，点后划线为两点连直线)
    lazy var straightChipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("直线", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.setTitleColor(.black, for: [.selected, .highlighted])
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels), weight: .semibold)
        button.layer.cornerRadius = UIDevice.wy_screenWidth(14, WYBasisKitConfig.defaultScreenPixels)
        button.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(lineShapeChipTapped(_:)), for: .touchUpInside)
        return button
    }()

    /// 自由形态切换按钮(划线语境显示，与直线按钮拼成横跨两列的双段胶囊，此为右半段只有右侧外圆角，点后划线跟随手指轨迹)
    lazy var freeChipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("自由", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.setTitleColor(.black, for: [.selected, .highlighted])
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels), weight: .semibold)
        button.layer.cornerRadius = UIDevice.wy_screenWidth(14, WYBasisKitConfig.defaultScreenPixels)
        button.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(lineShapeChipTapped(_:)), for: .touchUpInside)
        return button
    }()

    /// 框选形态切换按钮(马赛克语境显示，与涂抹按钮拼成横跨两列的双段胶囊，此为左半段只有左侧外圆角，点后新建马赛克为拖矩形框整块打码)
    lazy var mosaicBoxChipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("框选", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.setTitleColor(.black, for: [.selected, .highlighted])
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels), weight: .semibold)
        button.layer.cornerRadius = UIDevice.wy_screenWidth(14, WYBasisKitConfig.defaultScreenPixels)
        button.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(mosaicShapeChipTapped(_:)), for: .touchUpInside)
        return button
    }()

    /// 涂抹形态切换按钮(马赛克语境显示，与框选按钮拼成横跨两列的双段胶囊，此为右半段只有右侧外圆角，点后新建马赛克为手指涂抹打码)
    lazy var mosaicBrushChipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("涂抹", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.setTitleColor(.black, for: [.selected, .highlighted])
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels), weight: .semibold)
        button.layer.cornerRadius = UIDevice.wy_screenWidth(14, WYBasisKitConfig.defaultScreenPixels)
        button.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(mosaicShapeChipTapped(_:)), for: .touchUpInside)
        return button
    }()

    /// 水印图片切换按钮(水印语境且配置了watermarkImage时显示，独立开关钮，点后落的水印带上logo，可与平铺同时开)
    lazy var watermarkLogoChipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("图片", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.setTitleColor(.black, for: [.selected, .highlighted])
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels), weight: .semibold)
        button.layer.cornerRadius = UIDevice.wy_screenWidth(14, WYBasisKitConfig.defaultScreenPixels)
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(watermarkLogoChipTapped(_:)), for: .touchUpInside)
        return button
    }()

    /// 水印平铺切换按钮(水印语境显示，独立开关钮，点后落的水印为整图平铺防盗图式，可与图片同时开)
    lazy var watermarkTileChipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(WYLocalized("平铺", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.setTitleColor(.black, for: [.selected, .highlighted])
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels), weight: .semibold)
        button.layer.cornerRadius = UIDevice.wy_screenWidth(14, WYBasisKitConfig.defaultScreenPixels)
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(watermarkTileChipTapped(_:)), for: .touchUpInside)
        return button
    }()

    /// 线宽档位圆点按钮数组(矩形圆形箭头划线语境显示，按钮热区统一放大好点中，圆点只是内部视觉层示意粗细)
    lazy var lineWidthDotButtons: [UIButton] = {
        return (0..<4).map { index in
            let button = UIButton(type: .custom)
            let dotLayer = CALayer()
            dotLayer.name = "widthDot"
            dotLayer.backgroundColor = UIColor.white.cgColor
            button.layer.addSublayer(dotLayer)
            button.addTarget(self, action: #selector(lineWidthDotTapped(_:)), for: .touchUpInside)
            button.tag = index
            return button
        }
    }()

    /// 字号档位按钮数组(文本语境显示，字母A的大小示意字号)
    lazy var fontSizeButtons: [UIButton] = {
        return (0..<4).map { index in
            let button = UIButton(type: .custom)
            let fontSize = UIFont.wy_fontSize(CGFloat([12, 15, 20, 26][index]), WYBasisKitConfig.defaultScreenPixels)
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: fontSize), .foregroundColor: UIColor.white]
            button.setAttributedTitle(NSAttributedString(string: "A", attributes: attributes), for: .normal)
            button.addTarget(self, action: #selector(fontSizeButtonTapped(_:)), for: .touchUpInside)
            button.tag = index
            return button
        }
    }()

    /// 撤销按钮(撤掉最后画的那一个标记，纯图标与创造类工具区分)
    lazy var undoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(WYImageEditorIcon.undo, for: .normal)
        button.setImage(WYImageEditorIcon.undo.withTintColor(configuration.appearance.iconButtonHighlightedColor, renderingMode: .alwaysOriginal), for: .highlighted)
        button.tintColor = configuration.appearance.iconButtonColor
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 重做按钮(恢复最近一次撤销的标记，与撤销成对，iOS标记工具栏样式)
    lazy var redoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(WYImageEditorIcon.redo, for: .normal)
        button.setImage(WYImageEditorIcon.redo.withTintColor(configuration.appearance.iconButtonHighlightedColor, renderingMode: .alwaysOriginal), for: .highlighted)
        button.tintColor = configuration.appearance.iconButtonColor
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(redoButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 清除按钮(标记页面一键清掉全部标记，扫帚图标，与撤销重做同排在工具行末尾)
    lazy var clearButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(WYImageEditorIcon.clear, for: .normal)
        button.setImage(WYImageEditorIcon.clear.withTintColor(configuration.appearance.iconButtonHighlightedColor, renderingMode: .alwaysOriginal), for: .highlighted)
        button.tintColor = configuration.appearance.iconButtonColor
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(revertButtonTapped), for: .touchUpInside)
        return button
    }()

    /// 颜色圆点按钮数组(按外观色板生成，点的瞬间作用于选中的标记或之后的标记)
    lazy var colorButtons: [UIButton] = {
        return configuration.appearance.markerPalette.map { color in
            let button = UIButton(type: .custom)
            button.backgroundColor = color
            button.layer.cornerRadius = UIDevice.wy_screenWidth(13, WYBasisKitConfig.defaultScreenPixels)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(white: 1, alpha: 0.35).cgColor
            button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            return button
        }
    }()

    /// 当前是否处于标记模式(false表示裁剪模式)
    var isMarkMode = false

    /// 统一撤销栈(true为标记操作false为裁剪操作，按操作先后记录)
    var operationStack: [Bool] = []

    /// 统一重做栈(撤销时压入，重做时弹出，任何新操作清空)
    var redoOperationStack: [Bool] = []

    /// 撤销重做与一键清除的内部恢复动作不重复记入撤销栈
    var suppressOperationRecording = false

    override public func viewDidLoad() {
        super.viewDidLoad()

        // 裁剪和标记至少需要开启一项
        if !configuration.allowsCropping && !configuration.allowsMarking {
            assertionFailure("allowsCropping与allowsMarking不能同时为false，请至少开启一项编辑能力")
        }
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
        }
        refreshTitleForPendingCrop()

        markerToolbar.addSubview(toolRowScrollView)
        markerToolButtons.forEach { toolRowScrollView.addSubview($0) }
        toolRowScrollView.addSubview(undoButton)
        toolRowScrollView.addSubview(redoButton)
        toolRowScrollView.addSubview(clearButton)
        if configuration.showsColorOptions {
            markerToolbar.addSubview(colorRowScrollView)
            colorButtons.forEach { colorRowScrollView.addSubview($0) }
        }
        if configuration.showsStyleOptions {
            markerToolbar.addSubview(styleRowScrollView)
            styleRowScrollView.addSubview(styleHintLabel)
            styleRowScrollView.addSubview(straightChipButton)
            styleRowScrollView.addSubview(freeChipButton)
            styleRowScrollView.addSubview(mosaicBoxChipButton)
            styleRowScrollView.addSubview(mosaicBrushChipButton)
            styleRowScrollView.addSubview(watermarkLogoChipButton)
            styleRowScrollView.addSubview(watermarkTileChipButton)
            lineWidthDotButtons.forEach { styleRowScrollView.addSubview($0) }
            fontSizeButtons.forEach { styleRowScrollView.addSubview($0) }
        }

        cropperView.setup(image: image, shape: configuration.cropShape, fixedOutputSize: configuration.cropSize == .zero ? nil : configuration.cropSize, appearance: configuration.appearance, zoomEnabled: configuration.allowsCropZoom, initialZoomMultiplier: configuration.initialCropZoomScale)

        // 自由模式松手应用裁剪后，标记画布跟着换基准并平移全部标记坐标
        cropperView.onCropCommitted = { [weak self] croppedImage, region in
            self?.markerView.applyCroppedBase(croppedImage, region: region)
            self?.recordOperation(false)
            self?.refreshTitleForPendingCrop()
        }
        cropperView.onCropReverted = { [weak self] previousImage, region in
            self?.markerView.revertCroppedBase(previousImage, region: region)
        }
        cropperView.onCropRedone = { [weak self] croppedImage, region in
            self?.markerView.applyCroppedBase(croppedImage, region: region)
        }
        markerView.onMarkerOperation = { [weak self] in
            self?.recordOperation(true)
        }

        markerView.setup(image: image,
                         defaultColor: configuration.markerColor,
                         lineWidth: configuration.markerLineWidth,
                         textFontSize: configuration.markerTextFontSize,
                         straightLine: configuration.lineDrawsStraight,
                         mosaicBrushWidth: configuration.mosaicBrushWidth,
                         mosaicCellSize: configuration.mosaicCellSize,
                         mosaicDrawsBox: configuration.mosaicDrawsBox,
                         watermarkText: configuration.watermarkText,
                         watermarkColor: configuration.watermarkColor,
                         watermarkFontSize: configuration.watermarkFontSize,
                         watermarkRotation: configuration.watermarkRotation,
                         watermarkImage: configuration.watermarkImage,
                         appearance: configuration.appearance,
                         zoomEnabled: configuration.allowsMarkZoom,
                         initialZoomMultiplier: configuration.initialMarkZoomScale)
        markerView.onRequestTextEdit = { [weak self] text, title, completion in
            self?.showTextInputAlert(existingText: text, title: title, completion: completion)
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

        // 单模式在视图数据齐备后进入，裁剪与标记都关时按只裁剪兜底(仅标记时进标记页要读裁剪基准图定取景区域，提前到setup前调用会拿到空图)
        if !configuration.allowsCropping, configuration.allowsMarking {
            setMarkMode(true)
        }
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        let safeLeft = view.safeAreaInsets.left
        let safeRight = view.safeAreaInsets.right
        let width = view.bounds.width

        layoutEditorHeader(width: width, safeTop: safeTop, safeLeft: safeLeft, safeRight: safeRight)

        let modeBarHeight: CGFloat = modeBar.isHidden ? 0 : max(UIDevice.wy_screenHeight(43, WYBasisKitConfig.defaultScreenPixels), editorModeControlHeight + UIDevice.wy_screenHeight(13, WYBasisKitConfig.defaultScreenPixels))
        var toolbarHeight: CGFloat = markerToolRowHeight
        if configuration.showsColorOptions {
            toolbarHeight += markerColorRowHeight
        }
        if configuration.showsStyleOptions {
            toolbarHeight += markerStyleRowHeight
        }
        let bottomBarsHeight = isMarkMode ? modeBarHeight + toolbarHeight : modeBarHeight
        let canvasY = safeTop + max(UIDevice.wy_screenHeight(48, WYBasisKitConfig.defaultScreenPixels), editorHeaderHeight + UIDevice.wy_screenHeight(7, WYBasisKitConfig.defaultScreenPixels))
        let canvasHeight = view.bounds.height - canvasY - safeBottom - bottomBarsHeight
        cropperView.frame = CGRect(x: 0, y: canvasY, width: width, height: canvasHeight)
        markerView.frame = cropperView.frame

        modeBar.frame = CGRect(x: 0, y: view.bounds.height - safeBottom - bottomBarsHeight, width: width, height: modeBarHeight)
        if !modeBar.isHidden {
            layoutEditorModeControl(width: width, height: modeBarHeight, safeLeft: safeLeft, safeRight: safeRight)
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

}
