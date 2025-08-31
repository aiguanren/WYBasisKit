//
//  UIImage.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import Foundation
import UIKit

/// 动图格式类型
@frozen public enum WYAnimatedImageStyle {
    
    /// 普通 GIF 图片
    case GIF
    
    /// APNG 图片
    case APNG
}

public struct WYSourceBundle {
    
    /// 从哪个bundle文件内查找，如果bundleName对应的bundle不存在，则直接在本地路径下查找
    public let bundleName: String
    
    /// bundleName.bundle下面的子文件夹路径，如果子文件夹有多层，就用/隔开(如果要获取资源是放在bundle文件下面的子文件夹中，则需要传入该路径，例如ImageSource.bundle下面有个叫apple的子文件夹，则subdirectory应该传入 apple)
    public let subdirectory: String
    
    public init(bundleName: String = "", subdirectory: String = "") {
        self.bundleName = bundleName
        self.subdirectory = subdirectory
    }
}

public extension UIImage {
    
    /**
     * 根据传入的宽度获取图片的等比高度
     */
    func wy_height(forWidth width: CGFloat) -> CGFloat {
        guard width > 0, size.width > 0 else { return 0 }
        return size.height * (width / size.width)
    }
    
    /**
     * 根据传入的高度获取图片的等比宽度
     */
    func wy_width(forHeight height: CGFloat) -> CGFloat {
        guard height > 0, size.height > 0 else { return 0 }
        return size.width * (height / size.height)
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
    func wy_flips(_ orientation: UIImage.Orientation) -> UIImage {
        return UIImage(cgImage: cgImage!, scale: scale, orientation:orientation)
    }
    
    /// 截取指定View快照
    static func wy_screenshot(_ view: UIView) -> UIImage {
        
        // 设置屏幕倍率可以保证截图的质量
        let scale: CGFloat = UIScreen.main.scale
        
        UIGraphicsBeginImageContextWithOptions(view.frame.size, true, scale)
        
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    /// 根据颜色创建图片
    static func wy_createImage(from color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    /// 生成渐变图片
    static func wy_gradient(from colors: [UIColor], direction: WYGradientDirection, size: CGSize) -> UIImage {
        
        var array: [CGColor] = []
        for color in colors {
            array.append(color.cgColor)
        }
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: array as CFArray, locations: nil)
        
        var start: CGPoint
        var end: CGPoint
        switch direction {
        case .topToBottom:
            start = CGPoint.zero
            end = CGPoint(x: 0, y: size.height)
            break
        case .leftToRight:
            start = CGPoint.zero
            end = CGPoint(x: size.width, y: 0)
            break
        case .leftToLowRight:
            start = CGPoint.zero
            end = CGPoint(x: size.width, y: size.height)
            break
        case .rightToLowLeft:
            start = CGPoint(x: size.width, y: 0)
            end = CGPoint(x: 0, y: size.height)
            break
        }
        
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.translateBy(x: 0, y: -size.height)
        context?.drawLinearGradient(gradient!, start: start, end: end, options: .init())
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        context?.restoreGState()
        UIGraphicsEndImageContext()
        
        return image!
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
    static func wy_createQrCode(with info: Data, size: CGSize, waterImage: UIImage? = nil) -> UIImage {
        
        // CIFilter
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setDefaults()
        
        // Add Data
        filter?.setValue(info, forKeyPath: "inputMessage")
        
        // Out Put
        let outputImage = filter?.outputImage
        //  QRCode
        let extent = outputImage!.extent.integral
        let scale = min(size.width / extent.width, size.height / extent.height)
        
        // Create bitmap
        let width: size_t = size_t(extent.width * scale)
        let height: size_t = size_t(extent.height * scale)
        let cs: CGColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmap: CGContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: 1)!
        let context = CIContext()
        let bitmapImage = context.createCGImage(outputImage!, from: extent)
        bitmap.interpolationQuality = .none
        bitmap.scaleBy(x: scale, y: scale)
        bitmap.draw(bitmapImage!, in: extent)
        
        let scaledImage = bitmap.makeImage()
        let originalImage = UIImage(cgImage: scaledImage!)
        if waterImage == nil {
            return originalImage
        }else {
            // 把logo镶嵌到生成的二维码图片上，注意尺寸不要太大（最大不超过二维码图片的%30），太大会造成扫不出来
            return originalImage.wy_mosaic(image: waterImage!)
        }
    }
    
    /**
     *  获取二维码信息(必须要真机环境才能获取到相关信息)
     */
    func wy_recognitionQRCode() -> [String] {
        
        // 创建过滤器
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil)
        
        // 获取CIImage
        guard let ciImage = CIImage(image: self) else { return [] }
        
        // 识别二维码
        guard let features = detector?.features(in: ciImage) else { return [] }
        
        // 获取二维码信息
        let resultArr: [String] = features.compactMap { (($0) as! CIQRCodeFeature).messageString ?? "" }
        
        return resultArr
    }
    
    /**
     *  图片镶嵌
     *
     *  @param image  需要镶嵌到原图中央的图片
     *  @return 镶嵌好的图片
     */
    func wy_mosaic(image: UIImage) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image.draw(in: CGRect(x: (size.width - image.size.width) / 2, y: (size.height - image.size.height) / 2, width: image.size.width, height: image.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? UIImage.wy_createImage(from: .white)
    }
    
    /**
     *  将图片切割成圆形(可同时添加边框)
     *
     *  @param borderWidth   边框宽度
     *  @param borderColor   边框颜色
     *
     *  @return 切割好的图片
     */
    func wy_cuttingRound(borderWidth: CGFloat = 0, borderColor: UIColor = .clear) -> UIImage {
        return wy_drawing(cornerRadius: size.width / 2, borderWidth: borderWidth, borderColor: borderColor)
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
    func wy_drawing(cornerRadius: CGFloat, borderWidth: CGFloat = 0, borderColor: UIColor = .clear, corners: UIRectCorner = .allCorners) -> UIImage {
        
        // 创建一个新的图片上下文
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        // 设置边框颜色
        borderColor.setFill()
        
        // 设置边框
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        // 绘制圆角
        let path = UIBezierPath(roundedRect: CGRect(x: borderWidth, y: borderWidth, width: size.width - borderWidth * 2, height: size.height - borderWidth * 2), byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        path.addClip()
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        // 获取带有圆角和边框的图片
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return roundedImage!
    }
    
    /**
     *  给图片加上高斯模糊效果
     *  @param blurLevel   模糊半径值（越大越模糊）
     *  @return 高斯模糊好的图片
     */
    func wy_blur(_ blurLevel: CGFloat) -> UIImage {
        let context = CIContext (options:  nil )
        let  inputImage = CIImage (image: self)
        // 使用高斯模糊滤镜
        let  filter  =  CIFilter (name:  "CIGaussianBlur" )!
        filter.setValue(inputImage, forKey:kCIInputImageKey)
        // 设置模糊半径值（越大越模糊）
        filter.setValue(blurLevel, forKey: kCIInputRadiusKey)
        let  outputCIImage =  filter.outputImage!
        let  rect =  CGRect (origin:  CGPoint .zero, size: self.size)
        let  cgImage = context.createCGImage(outputCIImage, from: rect)
        // 显示生成的模糊图片
        let newImage =  UIImage (cgImage: cgImage!)
        return newImage
    }
    
    /** 图片上绘制文字 */
    func wy_addText(text: String, font: UIFont, color: UIColor, titlePoint: CGPoint, lineSpacing: CGFloat = 0, wordsSpacing: CGFloat = 0) -> UIImage {
        
        let size = self.size
        
        // 创建基于位图的图形上下文
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() } // 确保上下文结束
        
        self.draw(at: .zero)
        
        // 段落样式
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = lineSpacing
        
        // 文字属性
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
            .kern: wordsSpacing
        ]
        
        // 计算文字绘制大小
        let stringRect = text.boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine],
            attributes: attributes,
            context: nil
        )
        
        let textRect = CGRect(
            x: titlePoint.x,
            y: titlePoint.y,
            width: ceil(stringRect.width),
            height: ceil(stringRect.height)
        )
        
        // 绘制文字
        text.draw(in: textRect, withAttributes: attributes)
        
        // 获取绘制后的图片
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
    
    /**
     *  加载本地图片
     *
     *  @param imageName             要加载的图片名
     *
     *  @param bundle                从哪个bundle文件内查找，如果为空，则直接在本地路径下查找
     *
     */
    static func wy_find(_ imageName: String, inBundle bundle: WYSourceBundle? = nil) -> UIImage {
        
        if imageName.isEmpty {
            
            WYLogManager.output("没有找到相关图片，因为传入的 imageName 为空， 已默认创建一张随机颜色图片供您使用")
            return wy_createImage(from: UIColor(red: CGFloat(arc4random()%256)/255.0, green: CGFloat(arc4random()%256)/255.0, blue: CGFloat(arc4random()%256)/255.0, alpha: 1.0))
        }
        
        if let imageBundle: WYSourceBundle = bundle {
            
            var subdirectoryPath = imageBundle.subdirectory
            if  (imageBundle.subdirectory.isEmpty == false) && (imageBundle.subdirectory.hasPrefix("/") == false) {
                subdirectoryPath = "/" + imageBundle.subdirectory
            }
            
            let resourcePath = (((Bundle(for: WYLocalizableClass.self).path(forResource: imageBundle.bundleName, ofType: "bundle")) ?? (Bundle.main.path(forResource: imageBundle.bundleName, ofType: "bundle"))) ?? "").appending(subdirectoryPath)
            
            guard let contentImage = UIImage(named: imageName, in: Bundle(path: resourcePath), compatibleWith: nil) else {
                
                WYLogManager.output("在 \(imageBundle.bundleName).bundle/\(imageBundle.subdirectory) 中没有找到 \(imageName) 这张图片，已默认创建一张随机颜色图片供您使用")
                return wy_createImage(from: UIColor(red: CGFloat(arc4random()%256)/255.0, green: CGFloat(arc4random()%256)/255.0, blue: CGFloat(arc4random()%256)/255.0, alpha: 1.0))
            }
            return contentImage
        }else {
            
            guard let image = UIImage(named: imageName) else {
                
                let resourcePath = ((Bundle(for: WYLocalizableClass.self).path(forResource: imageName, ofType: nil)) ?? (Bundle.main.path(forResource: imageName, ofType: nil))) ?? ""
                
                guard let contentImage = UIImage(named: imageName, in: Bundle(path: resourcePath), compatibleWith: nil) else {
                    
                    WYLogManager.output("在项目路径或Assets下面，没有找到 \(imageName) 这张图片，已默认创建一张随机颜色图片供您使用")
                    
                    return wy_createImage(from: UIColor(red: CGFloat(arc4random()%256)/255.0, green: CGFloat(arc4random()%256)/255.0, blue: CGFloat(arc4random()%256)/255.0, alpha: 1.0))
                }
                return contentImage
            }
            return image
        }
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
    
    static func wy_animatedParse(_ style: WYAnimatedImageStyle = .GIF, name imageName: String, inBundle bundle: WYSourceBundle? = nil) -> WYGifInfo? {
        
        guard imageName.isEmpty == false else {
            return nil
        }
        
        let suffix: String = (style == .GIF) ? ".gif" : ".png"
        
        let animatedImageName: String = imageName.hasSuffix(suffix) ? imageName : (imageName + suffix)
        
        var contentPath: String = ""
        
        if let sourceBundle: WYSourceBundle = bundle {
            
            var subdirectoryPath = sourceBundle.subdirectory
            if  (sourceBundle.subdirectory.isEmpty == false) && (sourceBundle.subdirectory.hasPrefix("/") == false) {
                subdirectoryPath = "/" + sourceBundle.subdirectory
            }
            
            contentPath = ((((Bundle(for: WYLocalizableClass.self).path(forResource: sourceBundle.bundleName, ofType: "bundle")) ?? (Bundle.main.path(forResource: sourceBundle.bundleName, ofType: "bundle"))) ?? "").appending(subdirectoryPath)) + "/" + animatedImageName
            
        }else {
            contentPath = ((Bundle(for: WYLocalizableClass.self).path(forResource: animatedImageName, ofType: nil)) ?? (Bundle.main.path(forResource: animatedImageName, ofType: nil))) ?? ""
        }
        
        guard let contentData = try? Data(contentsOf: URL(fileURLWithPath: contentPath)) else {
            return nil
        }
        
        guard let imageSource: CGImageSource = CGImageSourceCreateWithData(contentData as CFData, nil) else {
            return nil
        }
        
        let imageCount = CGImageSourceGetCount(imageSource)
        
        var images = [UIImage]()
        var totalDuration: TimeInterval = 0
        for i in 0...imageCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else {
                continue
            }
            guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) as? [CFString: Any] else {
                continue
            }

            var pngDic: [CFString: Any]? = nil

            if let gifDic = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                pngDic = gifDic
            }

            if pngDic == nil {
                pngDic = properties[kCGImagePropertyPNGDictionary] as? [CFString: Any]
            }
            
            guard let animatedDic = pngDic else {
                continue
            }
            
            guard let duration = animatedDic[kCGImagePropertyGIFDelayTime] as? NSNumber else {
                continue
            }
            
            // 将播放时间累加
            totalDuration += duration.doubleValue
            // 获取到所有的image
            let image = UIImage(cgImage: cgImage)
            images.append(image)
        }
        
        return WYGifInfo(animationImages: images, animationDuration: totalDuration, animatedImage: UIImage.animatedImage(with: images, duration: totalDuration))
    }
}

/// Gif图片解析结果
public struct WYGifInfo {
    
    /// 解析后得到的图片数组
    public var animationImages: [UIImage]? = nil
    
    /// 轮询时长
    public var animationDuration: CGFloat = 0.0
    
    /// 可以直接显示的动图
    public var animatedImage: UIImage? = nil
    
    public init(animationImages: [UIImage]? = nil, animationDuration: CGFloat, animatedImage: UIImage? = nil) {
        self.animationImages = animationImages
        self.animationDuration = animationDuration
        self.animatedImage = animatedImage
    }
}

private class WYLocalizableClass {}
