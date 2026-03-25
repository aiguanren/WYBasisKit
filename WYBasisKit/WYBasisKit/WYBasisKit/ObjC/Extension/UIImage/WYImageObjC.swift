//
//  UIImageObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import Foundation
import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

/// 动图格式类型
@objc(WYAnimatedImageStyle)
@frozen public enum WYAnimatedImageStyleObjC: Int {
    
    /// 普通 GIF 图片
    case GIF = 0
    
    /// APNG 图片
    case APNG
}

@objc(WYSourceBundle)
@objcMembers public class WYSourceBundleObjC: NSObject {
    
    /// 从哪个bundle文件内查找，如果bundleName对应的bundle不存在，则直接在本地路径下查找
    @objc public let bundleName: String
    
    /// bundleName.bundle下面的子文件夹路径，如果子文件夹有多层，就用/隔开(如果要获取资源是放在bundle文件下面的子文件夹中，则需要传入该路径，例如ImageSource.bundle下面有个叫apple的子文件夹，则subdirectory应该传入 apple)
    @objc public let subdirectory: String
    
    @objc public init(bundleName: String = "", subdirectory: String = "") {
        self.bundleName = bundleName
        self.subdirectory = subdirectory
    }
    
    // 转换WYSourceBundleObjC为WYSourceBundle(内部使用)
    public func wy_convertToSwift() -> WYSourceBundle? {
        return WYSourceBundle(bundleName: self.bundleName, subdirectory: self.subdirectory)
    }
}

/// 图片拼接(组合)配置
@objcMembers public class WYCombineImagesConfig: NSObject {
    
    /**
     *  重叠控制参数，默认0（无重叠）
     *    - 0: 精确对齐，无重叠无间隙
     *    - 正值: 拼接图片向基准图片方向偏移，产生重叠效果
     *    - 负值: 拼接图片远离基准图片，产生间隙效果
     */
    @objc public var overlapControl: CGFloat = 0
    
    /// 拼接图片的透明度，默认1.0（不透明）
    @objc public var alpha: CGFloat = 1.0
    
    /// 混合模式，默认.normal（正常叠加）
    @objc public var blendMode: CGBlendMode = .normal
    
    /// 合成图片的背景颜色，默认透明
    @objc public var backgroundColor: UIColor = .clear
    
    /// 拼接图片的圆角半径，默认0（直角）
    @objc public var cornerRadius: CGFloat = 0
    
    /// 拼接图片的旋转角度（弧度制），默认0（不旋转）
    @objc public var rotationAngle: CGFloat = 0
    
    /// 是否水平翻转拼接图片，默认false
    @objc public var flipHorizontal: Bool = false
    
    /// 是否垂直翻转拼接图片，默认false
    @objc public var flipVertical: Bool = false
    
    /// 输出图片的质量缩放因子，默认使用基准图片的scale， 默认 0(等于0时会强制转为nil传给swift)，如需传入0则传入0.01等具体值
    @objc public var qualityScale: CGFloat = 0
    
    /// 拼接图片的缩放比例，默认1.0（原始大小）
    @objc public var scale: CGFloat = 1.0
    
    /// 阴影颜色，默认无阴影(透明)
    @objc public var shadowColor: UIColor = .clear
    
    /// 阴影模糊半径， 默认0
    @objc public var shadowBlur: CGFloat = 0
         
    /// 阴影偏移，默认.zero
    @objc public var shadowOffset: CGSize = .zero
    
    /// 描边颜色，默认无描边(透明)
    @objc public var strokeColor: UIColor = .clear
    
    /// 描边宽度， 默认0
    @objc public var strokeWidth: CGFloat = 0
    
    /// 蒙版图片（使用其 alpha 作为遮罩）， 默认nil
    @objc public var maskImage: UIImage? = nil
    
    /// 获取默认配置项
    @objc public static func sharedDefaultConfig() -> WYCombineImagesConfig {
        return WYCombineImagesConfig()
    }
    
    /// 初始化方法
    @objc public init(overlapControl: CGFloat = 0,
                      alpha: CGFloat = 1.0,
                      blendMode: CGBlendMode = .normal,
                      backgroundColor: UIColor = .clear,
                      cornerRadius: CGFloat = 0,
                      rotationAngle: CGFloat = 0,
                      flipHorizontal: Bool = false,
                      flipVertical: Bool = false,
                      qualityScale: CGFloat = 0,
                      scale: CGFloat = 1.0,
                      shadowColor: UIColor = .clear,
                      shadowBlur: CGFloat = 0,
                      shadowOffset: CGSize = .zero,
                      strokeColor: UIColor = .clear,
                      strokeWidth: CGFloat = 0,
                      maskImage: UIImage? = nil) {
        self.overlapControl = overlapControl
        self.alpha = alpha
        self.blendMode = blendMode
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.rotationAngle = rotationAngle
        self.flipHorizontal = flipHorizontal
        self.flipVertical = flipVertical
        self.qualityScale = qualityScale
        self.scale = scale
        self.shadowColor = shadowColor
        self.shadowBlur = shadowBlur
        self.shadowOffset = shadowOffset
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.maskImage = maskImage
    }
}

@objc public extension UIImage {
    
    /**
     * 根据传入的高度获取图片的等比宽度
     */
    @objc(wy_widthFromHeight:)
    func wy_widthObjC(forHeight height: CGFloat) -> CGFloat {
        return wy_width(fromHeight: height)
    }
    
    /**
     * 根据传入的宽度获取图片的等比高度
     */
    @objc(wy_heightFromWidth:)
    func wy_heightObjC(forWidth width: CGFloat) -> CGFloat {
        return wy_height(fromWidth: width)
    }
    
    /**
     *  图片翻转(旋转)
     *  orientation: 图片翻转(旋转)的方向
     *    case up // 默认方向
     *    case upMirrored // 默认方向镜像翻转
     *    case down // 顺时针旋转180°
     *    case downMirrored // 顺时针旋转180°后镜像翻转
     *    case left // 逆时针旋转90°
     *    case leftMirrored // 逆时针旋转90°后镜像翻转
     *    case right // 顺时针旋转90°
     *    case rightMirrored // 顺针旋转90°后镜像翻转
     */
    @objc(wy_flips:)
    func wy_flips(with orientation: UIImage.Orientation) -> UIImage {
        return wy_flips(orientation)
    }
    
    /**
     图片合成(拼接) ，支持重叠控制、缩放、透明度、混合模式等多种效果
     - standardImage: 基准图片
     - stitchingImage: 要拼接的图片，将叠加在基准图片上
     - stitchingCenterPoint: 拼接图片的中心点在基准图片坐标系中的位置
     - config: 图片拼接(组合)配置选项
     - return: 拼接后的图片，失败返回nil
     */
    @objc(wy_combineImagesWithStandardImage:stitchingImage:stitchingCenterPoint:config:)
    static func wy_combineImagesObjC(standardImage: UIImage,
                                     stitchingImage: UIImage,
                                     stitchingCenterPoint: CGPoint,
                                     config: WYCombineImagesConfig? = nil) -> UIImage? {
        let combineConfig: WYCombineImagesConfig = (config == nil) ? WYCombineImagesConfig.sharedDefaultConfig() : config!
        
        return wy_combineImages(standardImage: standardImage,
                                stitchingImage: stitchingImage,
                                stitchingCenterPoint: stitchingCenterPoint,
                                overlapControl: combineConfig.overlapControl,
                                alpha: combineConfig.alpha,
                                blendMode: combineConfig.blendMode,
                                backgroundColor: combineConfig.backgroundColor,
                                cornerRadius: combineConfig.cornerRadius,
                                rotationAngle: combineConfig.rotationAngle,
                                flipHorizontal: combineConfig.flipHorizontal,
                                flipVertical: combineConfig.flipVertical,
                                qualityScale: (combineConfig.qualityScale == 0) ? nil : combineConfig.qualityScale,
                                scale: combineConfig.scale,
                                shadowColor: combineConfig.shadowColor,
                                shadowBlur: combineConfig.shadowBlur,
                                shadowOffset: combineConfig.shadowOffset,
                                strokeColor: combineConfig.strokeColor,
                                strokeWidth: combineConfig.strokeWidth,
                                maskImage: combineConfig.maskImage)
    }
    
    /// 截取指定View快照
    @objc(wy_screenshot:)
    static func wy_screenshot(with view: UIView) -> UIImage {
        return wy_screenshot(view)
    }
    
    /// 根据颜色创建图片
    @objc(wy_createImageFromColor:)
    static func wy_createImageObjC(from color: UIColor) -> UIImage {
        return wy_createImageObjC(from: color, size: CGSize(width: 1, height: 1))
    }
    @objc(wy_createImageFromColor:size:)
    static func wy_createImageObjC(from color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return wy_createImage(from: color, size: size)
    }
    
    /// 生成渐变图片
    @objc(wy_gradientFrom:direction:size:)
    static func wy_gradientObjC(from colors: [UIColor], direction: WYGradientDirectionObjC, size: CGSize) -> UIImage {
        return wy_gradient(from: colors, direction: WYGradientDirection(rawValue: direction.rawValue) ?? .topToBottom, size: size)
    }
    
    /// 判断图片是否有 Alpha 通道
    @objc(wy_hasAlphaChannel)
    func wy_hasAlphaChannelObjC() -> Bool {
        return wy_hasAlphaChannel()
    }
    
    /**
     渲染图片至指定颜色（同步）
     ⚠️ 注意：
     - 该方法为同步执行，会在当前线程完成图像渲染，不建议在主线程高频调用，可能导致卡顿或掉帧，适用于调用次数较少的场景，例如：
       - 非滚动场景（如页面初始化、静态展示）
       - 单次或少量图片处理（如按钮状态图、占位图生成）
       - 若在列表滚动、频繁刷新或大量图片处理等场景中使用，建议改用异步方法
     - Parameter color: 需要渲染的目标颜色
     - Returns: 渲染后的新图片
     */
    @objc(wy_renderingColor:)
    func wy_renderingObjC(color: UIColor) -> UIImage {
        return wy_rendering(color: color)
    }
    
    /**
     渲染图片至指定颜色（异步）
     
     在后台线程执行图片着色处理，避免阻塞主线程，适用于高频或性能敏感场景。
     内部会自动切换至主线程回调处理结果，确保可直接用于 UI 更新。

     适用场景：
       - 列表滚动（如 UITableView / UICollectionView）
       - 网络图片加载后的二次处理（如统一着色）
       - 图片频繁刷新或批量处理
       - 对性能要求较高的界面（避免掉帧、卡顿）

     ⚠️ 缓存建议（推荐结合 SDWebImage 使用）：
     - 可将“渲染后的图片”进行缓存，避免重复处理
     - 推荐缓存 key：url + color（或其他唯一标识）
       例如：NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", url, @(color.hash)];
     - 使用方式建议：
       1. 先根据 key 查询缓存（命中则直接使用）
       2. 未命中时再进行渲染
       3. 渲染完成后写入缓存

     ⚠️ 防止 cell 错图（建议处理）：
     - 异步回调存在“返回顺序不确定”的问题，在 cell 复用场景下可能导致错图
     - 必须在调用方做“任务标识校验”，只允许最后一次请求生效

     示例（SDWebImage）：

     NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", url, @(color.hash)];
     SDImageCache *cache = [SDImageCache sharedImageCache];

     NSString *taskId = [[NSUUID UUID] UUIDString];
     imageView.accessibilityIdentifier = taskId;

     UIImage *sourceImage = image;

     // 查询缓存
     [cache queryImageForKey:cacheKey
                     options:SDImageCacheQueryMemoryDataSync | SDImageCacheQueryDiskDataSync
                     context:nil
                   cacheType:SDImageCacheTypeAll
                  completion:^(UIImage * _Nullable cacheImage,
                               NSData * _Nullable data,
                               SDImageCacheType cacheType) {

         // 执行渲染操作
         void (^render)(void) = ^{
             [sourceImage wy_renderingObjCWithColor:color completion:^(UIImage * _Nonnull tintedImage) {

                 // 校验任务
                 if (![imageView.accessibilityIdentifier isEqualToString:taskId]) {
                     return;
                 }

                 // 写入缓存并更新显示图片
                 [cache storeImage:tintedImage forKey:cacheKey completion:nil];
                 imageView.image = tintedImage;
             }];
         };

         if (cacheImage && [imageView.accessibilityIdentifier isEqualToString:taskId]) {
             // 命中缓存 + 校验任务
             imageView.image = cacheImage;
         } else {
             // 未命中 or 查询失败
             render();
         }
     }];

     - Parameter color: 需要渲染的目标颜色
     - Parameter completion: 渲染完成回调（主线程，返回处理后的图片）
     */
    @objc(wy_renderingColor:completion:)
    func wy_renderingObjC(color: UIColor, completion: @escaping @MainActor (_ tintedImage: UIImage) -> Void) {
        wy_rendering(color: color, completion: completion)
    }
    
    /**
     *  生成一个二维码图片
     *
     *  @param info         二维码中需要包含的信息
     *  @param size         二维码的size
     *  @param waterImage   水印图片(选传，传入后水印在二维码中央，注意，此图片最大不能超过二维码图片size的30%，否则会扫码失败)
     *
     *  @return 二维码图片
     */
    @objc(wy_createQrCodeWith:size:waterImage:)
    static func wy_createQrCodeObjC(with info: Data, size: CGSize, waterImage: UIImage? = nil) -> UIImage {
        return wy_createQrCode(with: info, size: size, waterImage: waterImage)
    }
    
    /**
     *  获取二维码信息(必须要真机环境才能获取到相关信息)
     */
    @objc(wy_recognitionQRCode)
    func wy_recognitionQRCodeObjC() -> [String] {
        return wy_recognitionQRCode()
    }
    
    /**
     *  图片镶嵌
     *
     *  @param image  需要镶嵌到原图中央的图片
     *  @return 镶嵌好的图片
     */
    @objc(wy_mosaicImage:)
    func wy_mosaicObjC(image: UIImage) -> UIImage {
        return wy_mosaic(image: image)
    }

    /**
     *  将图片切割成圆形(可同时添加边框)
     *
     *  @param borderWidth   边框宽度
     *  @param borderColor   边框颜色
     *
     *  @return 切割好的图片
     */
    @objc(wy_cuttingRoundWithBorderWidth:borderColor:)
    func wy_cuttingRoundObjC(borderWidth: CGFloat = 0, borderColor: UIColor = .clear) -> UIImage {
        return wy_cuttingRound(borderWidth: borderWidth, borderColor: borderColor)
    }
    
    /**
     *  给图片添加圆角、边框
     *
     *  @param cornerRadius  圆角半径
     *  @param borderWidth   边框宽度
     *  @param borderColor   边框颜色
     *  @param corners       圆角位置
     *
     *  @return 切割好的图片
     */
    @objc(wy_drawingCornerRadius:borderWidth:borderColor:corners:)
    func wy_drawingObjC(cornerRadius: CGFloat, borderWidth: CGFloat = 0, borderColor: UIColor = .clear, corners: UIRectCorner = .allCorners) -> UIImage {
        return wy_drawing(cornerRadius: cornerRadius, borderWidth: borderWidth, borderColor: borderColor, corners: corners)
    }
    
    /**
     *  给图片加上高斯模糊效果
     *  @param blurLevel   模糊半径值（越大越模糊）
     *  @return 高斯模糊好的图片
     */
    @objc(wy_blurWithLevel:)
    func wy_blurObjC(_ blurLevel: CGFloat) -> UIImage {
        return wy_blur(blurLevel)
    }
    
    /** 图片上绘制文字 */
    @objc(wy_addText:font:color:rect:lineSpacing:wordsSpacing:)
    func wy_addTextObjC(text: String, font: UIFont, color: UIColor, rect: CGRect, lineSpacing: CGFloat = 0, wordsSpacing: CGFloat = 0) -> UIImage {
        
        return wy_addText(text: text, font: font, color: color, rect: rect, lineSpacing: lineSpacing, wordsSpacing: wordsSpacing)
    }
    
    /**
     *  加载本地图片
     *
     *  @param imageName             要加载的图片名
     *
     *  @param bundle                从哪个bundle文件内查找，如果为空，则直接在本地路径下查找
     *
     */
    @objc(wy_find:)
    static func wy_findObjC(_ imageName: String) -> UIImage {
        return wy_findObjC(imageName, bundle: nil)
    }
    @objc(wy_find:bundle:)
    static func wy_findObjC(_ imageName: String, bundle: WYSourceBundleObjC? = nil) -> UIImage {
        return wy_find(imageName, inBundle: bundle?.wy_convertToSwift())
    }
    
    /**
     *  解析 Gif 或者 APNG 图片
     *
     *  @param style      要解析的图片的格式(仅支持 Gif 或者 APNG 格式)
     *
     *  @param imageName  要解析的 Gif 或者 APNG 图
     *
     *  @param bundle     从哪个bundle文件内查找，如果为空，则直接在本地路径下查找
     *
     *  @return Gif       图片解析结果
     */
    @objc(wy_animatedParse:imageName:)
    static func wy_animatedParse(_ style: WYAnimatedImageStyleObjC = .GIF, imageName: String) -> WYGifInfoObjC? {
        return wy_animatedParse(style, imageName: imageName, bundle: nil)
    }
    @objc(wy_animatedParse:imageName:bundle:)
    static func wy_animatedParse(_ style: WYAnimatedImageStyleObjC = .GIF, imageName: String, bundle: WYSourceBundleObjC? = nil) -> WYGifInfoObjC? {
        
        guard let gifInfo: WYGifInfo = wy_animatedParse(WYAnimatedImageStyle(rawValue: style.rawValue) ?? .GIF, name: imageName, inBundle: bundle?.wy_convertToSwift()) else {
            return nil
        }
        return WYGifInfoObjC(animationImages: gifInfo.animationImages, animationDuration: gifInfo.animationDuration, animatedImage: gifInfo.animatedImage)
    }
}

/// Gif图片解析结果
@objc(WYGifInfo)
@objcMembers public class WYGifInfoObjC: NSObject {
    
    /// 解析后得到的图片数组
    @objc public var animationImages: [UIImage]? = nil
    
    /// 轮询时长
    @objc public var animationDuration: CGFloat = 0.0
    
    /// 可以直接显示的动图
    @objc public var animatedImage: UIImage? = nil
    
    @objc public init(animationImages: [UIImage]? = nil, animationDuration: CGFloat, animatedImage: UIImage? = nil) {
        self.animationImages = animationImages
        self.animationDuration = animationDuration
        self.animatedImage = animatedImage
    }
}

private class WYLocalizableClass {}
