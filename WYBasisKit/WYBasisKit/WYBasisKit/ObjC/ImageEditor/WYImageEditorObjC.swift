//
//  WYImageEditorObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/15.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

/// 界面外观配置(全部属性都有默认值，按需覆盖，不设置时与默认外观一致，颜色对象传nil、数值传负数表示该项用默认值，markerPalette传空数组时界面不显示颜色行)
@objcMembers public class WYImageEditorAppearanceObjC: NSObject {

    /// 画布背景色(裁剪与标记画布的底色)
    public var canvasBackgroundColor: UIColor?

    /// 裁剪遮罩暗度(0全透明到1全黑，框外区域的压暗程度)
    public var maskDimmingAmount: CGFloat = -1

    /// 裁剪框边线颜色
    public var cropBorderColor: UIColor?

    /// 裁剪框边线宽度(单位为点)
    public var cropBorderWidth: CGFloat = -1

    /// 九宫格辅助线颜色(仅矩形裁剪画)
    public var gridLineColor: UIColor?

    /// 裁剪把手颜色(四角L形把手与四边短把手)
    public var handleColor: UIColor?

    /// 四角L形把手的臂长(单位为点)
    public var handleArmLength: CGFloat = -1

    /// 标记选中态虚线颜色(主虚线，底下自动垫一圈半透明黑描边保证浅色背景上可读)
    public var selectionDashColor: UIColor?

    /// 标记选中态虚线线宽(单位为点)
    public var selectionDashWidth: CGFloat = -1

    /// 标记选中态虚线外扩边距(单位为点，虚线框相对标记边界四围的留白)
    public var selectionInset: CGFloat = -1

    /// 选中态删除按钮底色(左上角带叉圆钮)
    public var deleteButtonColor: UIColor?

    /// 选中态缩放与端点把手圆点颜色
    public var resizeDotColor: UIColor?

    /// 颜色选择条色板(按顺序展示，传空数组时界面不显示颜色行)
    public var markerPalette: [UIColor]?

    /// 线宽档位倍率(相对默认线宽的倍数序列)
    public var lineWidthRatios: [CGFloat]?

    /// 字号档位倍率(相对默认字号的倍数序列)
    public var fontSizeRatios: [CGFloat]?

    /// 水印整体透明度(0全透明到1不透明，负数表示用默认值)
    public var watermarkAlpha: CGFloat = -1

    /// 标记工具条背景色
    public var toolbarBackgroundColor: UIColor?

    /// 工具行图标按钮常态颜色(撤销重做清除三颗纯图标按钮)
    public var iconButtonColor: UIColor?

    /// 工具行图标按钮按住颜色(手指按住时变色，松开回常态)
    public var iconButtonHighlightedColor: UIColor?

    /// 粗细档位的提示文案(nil用本地化默认，文案含换行时上下两行显示)
    public var lineWidthHintText: String?

    /// 字号档位的提示文案(nil用本地化默认，文案含换行时上下两行显示)
    public var fontSizeHintText: String?

    /// 档位提示文本颜色(粗细与字号档位行首的两行小字)
    public var hintTextColor: UIColor?

    /// 模式分段控件底色(裁剪标记两个胶囊所在的圆角容器)
    public var segmentedBackgroundColor: UIColor?

    /// 模式分段控件选中胶囊底色
    public var segmentedSelectedBackgroundColor: UIColor?

    /// 模式分段控件选中胶囊文字颜色
    public var segmentedSelectedTextColor: UIColor?

    /// 模式分段控件未选中胶囊文字颜色
    public var segmentedTextColor: UIColor?

    /// 顶部栏普通按钮文字颜色(取消与还原)
    public var topBarButtonColor: UIColor?

    /// 顶部栏裁剪按钮文字颜色(默认与还原按钮一致)
    public var topBarCropButtonColor: UIColor?

    /// 顶部栏完成按钮文字颜色
    public var topBarDoneColor: UIColor?

    /// 选中态强调色(当前模式按钮、当前工具、生效档位圆点与字号的点亮色)
    public var accentColor: UIColor?

}

/// 编辑器配置(全部属性都有默认值，按需改，宽高任一为0表示不固定尺寸)
@objcMembers public class WYImageEditorConfigurationObjC: NSObject {

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

    /// 界面外观(传nil用默认外观)
    public var appearance: WYImageEditorAppearanceObjC?
}

/// 相片编辑器OC入口(封装WYImageEditorViewController的弹出与回调，delegate方式用实例方法，Block方式用静态方法)
@objc(WYImageEditor)
@objcMembers public class WYImageEditorObjC: NSObject {

    /// 编辑回调delegate(Swift与OC共用的WYImageEditorViewControllerDelegate，与editHandler同时设置时两边都会回调)
    public weak var delegate: WYImageEditorViewControllerDelegate?

    /// 编辑结果Block(编辑成成品图回调图片，取消回调nil，与delegate同时设置时两边都会回调)
    public var editHandler: ((UIImage?) -> Void)?

    /**
     * 弹出编辑器(delegate回调方式，回调走本对象的delegate与editHandler)
     * - Parameters:
     *   - image: 要编辑的图片
     *   - viewController: 从哪个控制器弹出
     *   - configuration: 编辑配置(传nil用默认配置)
     */
    @objc(showEditorWithImage:from:configuration:)
    public func showEditor(withImage image: UIImage, from viewController: UIViewController, configuration: WYImageEditorConfigurationObjC?) {
        let editor = WYImageEditorViewController(image: image, configuration: WYImageEditorObjC.convertConfiguration(configuration))

        // delegate直接桥接到编辑器共用协议(编辑器回调原生送达)，editHandler走Block路
        editor.editorDelegate = delegate
        editor.onFinish = { resultImage in
            self.editHandler?(resultImage)
        }
        editor.onCancel = {
            self.editHandler?(nil)
        }
        editor.modalPresentationStyle = .fullScreen
        viewController.present(editor, animated: true)
    }

    /**
     * 弹出编辑器(Block回调方式，一行调用不用持有对象)
     * - Parameters:
     *   - image: 要编辑的图片
     *   - viewController: 从哪个控制器弹出
     *   - configuration: 编辑配置(传nil用默认配置)
     *   - handler: 编辑结果回调(编辑成成品图回调图片，取消回调nil)
     */
    @objc(showEditorWithImage:from:configuration:handler:)
    public static func showEditor(withImage image: UIImage, from viewController: UIViewController, configuration: WYImageEditorConfigurationObjC?, handler: ((UIImage?) -> Void)?) {
        let editor = WYImageEditorViewController(image: image, configuration: WYImageEditorObjC.convertConfiguration(configuration))
        editor.onFinish = { resultImage in
            handler?(resultImage)
        }
        editor.onCancel = {
            handler?(nil)
        }
        editor.modalPresentationStyle = .fullScreen
        viewController.present(editor, animated: true)
    }

    /**
     * OC配置转Swift配置
     * - Parameter bridgeConfiguration: 编辑配置(传nil用默认配置)
     * - Returns: Swift编辑器用的配置
     */
    private static func convertConfiguration(_ bridgeConfiguration: WYImageEditorConfigurationObjC?) -> WYImageEditorConfiguration {
        var configuration = WYImageEditorConfiguration()
        if let bridgeConfiguration = bridgeConfiguration {
            configuration.cropShape = bridgeConfiguration.cropShape
            configuration.cropSize = bridgeConfiguration.cropSize
            configuration.allowsCropping = bridgeConfiguration.allowsCropping
            configuration.allowsMarking = bridgeConfiguration.allowsMarking
            configuration.markerColor = bridgeConfiguration.markerColor
            configuration.markerLineWidth = bridgeConfiguration.markerLineWidth
            configuration.markerTextFontSize = bridgeConfiguration.markerTextFontSize
            configuration.lineDrawsStraight = bridgeConfiguration.lineDrawsStraight
            configuration.mosaicBrushWidth = bridgeConfiguration.mosaicBrushWidth
            configuration.mosaicCellSize = bridgeConfiguration.mosaicCellSize
            configuration.mosaicDrawsBox = bridgeConfiguration.mosaicDrawsBox
            configuration.watermarkImage = bridgeConfiguration.watermarkImage
            configuration.watermarkText = bridgeConfiguration.watermarkText
            configuration.watermarkColor = bridgeConfiguration.watermarkColor
            configuration.watermarkFontSize = bridgeConfiguration.watermarkFontSize
            configuration.watermarkRotation = bridgeConfiguration.watermarkRotation
            configuration.showsStyleOptions = bridgeConfiguration.showsStyleOptions
            configuration.showsColorOptions = bridgeConfiguration.showsColorOptions
            configuration.allowsCropZoom = bridgeConfiguration.allowsCropZoom
            configuration.initialCropZoomScale = bridgeConfiguration.initialCropZoomScale
            configuration.allowsMarkZoom = bridgeConfiguration.allowsMarkZoom
            configuration.initialMarkZoomScale = bridgeConfiguration.initialMarkZoomScale
            if let bridgeAppearance = bridgeConfiguration.appearance {
                var appearance = WYImageEditorAppearance()
                if let color = bridgeAppearance.canvasBackgroundColor { appearance.canvasBackgroundColor = color }
                if bridgeAppearance.maskDimmingAmount >= 0 { appearance.maskDimmingAmount = bridgeAppearance.maskDimmingAmount }
                if let color = bridgeAppearance.cropBorderColor { appearance.cropBorderColor = color }
                if bridgeAppearance.cropBorderWidth >= 0 { appearance.cropBorderWidth = bridgeAppearance.cropBorderWidth }
                if let color = bridgeAppearance.gridLineColor { appearance.gridLineColor = color }
                if let color = bridgeAppearance.handleColor { appearance.handleColor = color }
                if bridgeAppearance.handleArmLength >= 0 { appearance.handleArmLength = bridgeAppearance.handleArmLength }
                if let color = bridgeAppearance.selectionDashColor { appearance.selectionDashColor = color }
                if bridgeAppearance.selectionDashWidth >= 0 { appearance.selectionDashWidth = bridgeAppearance.selectionDashWidth }
                if bridgeAppearance.selectionInset >= 0 { appearance.selectionInset = bridgeAppearance.selectionInset }
                if let color = bridgeAppearance.deleteButtonColor { appearance.deleteButtonColor = color }
                if let color = bridgeAppearance.resizeDotColor { appearance.resizeDotColor = color }
                if let palette = bridgeAppearance.markerPalette, !palette.isEmpty { appearance.markerPalette = palette }
                if let ratios = bridgeAppearance.lineWidthRatios, !ratios.isEmpty { appearance.lineWidthRatios = ratios }
                if let ratios = bridgeAppearance.fontSizeRatios, !ratios.isEmpty { appearance.fontSizeRatios = ratios }
                if bridgeAppearance.watermarkAlpha >= 0 { appearance.watermarkAlpha = bridgeAppearance.watermarkAlpha }
                if let color = bridgeAppearance.toolbarBackgroundColor { appearance.toolbarBackgroundColor = color }
                if let color = bridgeAppearance.iconButtonColor { appearance.iconButtonColor = color }
                if let color = bridgeAppearance.iconButtonHighlightedColor { appearance.iconButtonHighlightedColor = color }
                if let text = bridgeAppearance.lineWidthHintText, !text.isEmpty { appearance.lineWidthHintText = text }
                if let text = bridgeAppearance.fontSizeHintText, !text.isEmpty { appearance.fontSizeHintText = text }
                if let color = bridgeAppearance.hintTextColor { appearance.hintTextColor = color }
                if let color = bridgeAppearance.segmentedBackgroundColor { appearance.segmentedBackgroundColor = color }
                if let color = bridgeAppearance.segmentedSelectedBackgroundColor { appearance.segmentedSelectedBackgroundColor = color }
                if let color = bridgeAppearance.segmentedSelectedTextColor { appearance.segmentedSelectedTextColor = color }
                if let color = bridgeAppearance.segmentedTextColor { appearance.segmentedTextColor = color }
                if let color = bridgeAppearance.topBarButtonColor { appearance.topBarButtonColor = color }
                if let color = bridgeAppearance.topBarCropButtonColor { appearance.topBarCropButtonColor = color }
                if let color = bridgeAppearance.topBarDoneColor { appearance.topBarDoneColor = color }
                if let color = bridgeAppearance.accentColor { appearance.accentColor = color }
                configuration.appearance = appearance
            }
        }
        return configuration
    }
}
#endif
