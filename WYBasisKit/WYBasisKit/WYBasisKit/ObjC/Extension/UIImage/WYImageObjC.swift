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
