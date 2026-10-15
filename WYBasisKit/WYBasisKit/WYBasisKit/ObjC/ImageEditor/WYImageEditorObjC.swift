//
//  WYImageEditorObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/15.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

/// 编辑器回调delegate(与Block回调二选一或同时使用)
@objc public protocol WYImageEditorDelegate: NSObjectProtocol {

    /**
     * 编辑完成(点完成按钮时回调，成品图已按裁剪形状与标记绘制好)
     * - Parameters:
     *   - editor: 回调来源编辑器
     *   - image: 编辑成品图(圆形裁剪时是四角透明的PNG)
     */
    @objc optional func imageEditor(_ editor: WYImageEditorObjC, didFinishEditing image: UIImage)

    /**
     * 取消编辑(点取消按钮时回调)
     * - Parameter editor: 回调来源编辑器
     */
    @objc optional func imageEditorDidCancel(_ editor: WYImageEditorObjC)
}

/// OC侧编辑器配置(属性含义与WYImageEditorConfiguration一字不差，宽高任一为0表示不固定尺寸)
@objcMembers public class WYImageEditorConfigurationObjC: NSObject {

    /// 裁剪形状(默认矩形)
    public var cropShape: WYImageCropShape = .rectangle

    /// 固定裁剪输出尺寸(单位为像素；宽高任一为0表示不固定，由用户自由拖动裁剪框决定；圆形裁剪时取宽高较小边做直径)
    public var cropSize: CGSize = .zero

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
}

/// 相片编辑器OC入口(封装WYImageEditorViewController的弹出与回调，delegate方式用实例方法，Block方式用静态方法)
@objc(WYImageEditor)
@objcMembers public class WYImageEditorObjC: NSObject {

    /// 编辑回调delegate(与editHandler同时设置时两边都会回调)
    public weak var delegate: WYImageEditorDelegate?

    /// 编辑结果Block(编辑成成品图回调图片，取消回调nil；与delegate同时设置时两边都会回调)
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

        // 强持有自身到编辑器关闭为止，中途不会被释放掉导致回调丢失
        editor.onFinish = { resultImage in
            self.delegate?.imageEditor?(self, didFinishEditing: resultImage)
            self.editHandler?(resultImage)
        }
        editor.onCancel = {
            self.delegate?.imageEditorDidCancel?(self)
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
     * - Parameter bridgeConfiguration: OC侧配置(传nil用默认配置)
     * - Returns: Swift编辑器用的配置
     */
    private static func convertConfiguration(_ bridgeConfiguration: WYImageEditorConfigurationObjC?) -> WYImageEditorConfiguration {
        var configuration = WYImageEditorConfiguration()
        if let bridgeConfiguration = bridgeConfiguration {
            configuration.cropShape = bridgeConfiguration.cropShape
            configuration.cropSize = bridgeConfiguration.cropSize
            configuration.allowsMarking = bridgeConfiguration.allowsMarking
            configuration.markerColor = bridgeConfiguration.markerColor
            configuration.markerLineWidth = bridgeConfiguration.markerLineWidth
            configuration.markerTextFontSize = bridgeConfiguration.markerTextFontSize
            configuration.lineDrawsStraight = bridgeConfiguration.lineDrawsStraight
            configuration.showsStyleOptions = bridgeConfiguration.showsStyleOptions
            configuration.showsColorOptions = bridgeConfiguration.showsColorOptions
        }
        return configuration
    }
}
#endif
