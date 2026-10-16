//
//  WYImageEditorIcons.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/15.
//

import UIKit

/// 编辑器工具条线条图标(纯CoreGraphics画，不依赖图片资源，按模板图使用可跟随tintColor变色)
enum WYImageEditorIcon {

    /// 文本工具图标(T字)
    static var text: UIImage {
        return drawIcon { context in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 6, y: 7))
            path.addLine(to: CGPoint(x: 18, y: 7))
            path.move(to: CGPoint(x: 12, y: 7))
            path.addLine(to: CGPoint(x: 12, y: 18))
            path.stroke()
        }
    }

    /// 矩形工具图标(方框)
    static var rectangle: UIImage {
        return drawIcon { context in
            let path = UIBezierPath(roundedRect: CGRect(x: 4, y: 6, width: 16, height: 12), cornerRadius: 2)
            path.stroke()
        }
    }

    /// 圆形工具图标(圆圈)
    static var circle: UIImage {
        return drawIcon { context in
            let path = UIBezierPath(ovalIn: CGRect(x: 4.5, y: 4.5, width: 15, height: 15))
            path.stroke()
        }
    }

    /// 箭头工具图标(指向右上)
    static var arrow: UIImage {
        return drawIcon { context in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 6, y: 18))
            path.addLine(to: CGPoint(x: 17, y: 7))
            path.move(to: CGPoint(x: 11.5, y: 7))
            path.addLine(to: CGPoint(x: 17, y: 7))
            path.addLine(to: CGPoint(x: 17, y: 12.5))
            path.stroke()
        }
    }

    /// 划线工具图标(手绘曲线)
    static var line: UIImage {
        return drawIcon { context in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 5, y: 17))
            path.addCurve(to: CGPoint(x: 19, y: 7), controlPoint1: CGPoint(x: 9, y: 5), controlPoint2: CGPoint(x: 15, y: 19))
            path.stroke()
        }
    }

    /// 撤销图标(左弯返回箭头，弯钩造型与刷新的回环箭头区分)
    static var undo: UIImage {
        return drawIcon { context in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 21, y: 8))
            path.addLine(to: CGPoint(x: 8, y: 8))
            path.addQuadCurve(to: CGPoint(x: 8, y: 18), controlPoint: CGPoint(x: 8, y: 13))
            path.stroke()
            let head = UIBezierPath()
            head.move(to: CGPoint(x: 8, y: 8))
            head.addLine(to: CGPoint(x: 13, y: 4.8))
            head.addLine(to: CGPoint(x: 13, y: 11.2))
            head.close()
            head.fill()
        }
    }

    /// 删除图标(垃圾桶)
    static var trash: UIImage {
        return drawIcon { context in
            let body = UIBezierPath(roundedRect: CGRect(x: 7, y: 9, width: 10, height: 9), cornerRadius: 1.5)
            body.stroke()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 5.5, y: 6.5))
            path.addLine(to: CGPoint(x: 18.5, y: 6.5))
            path.move(to: CGPoint(x: 10.5, y: 6.5))
            path.addLine(to: CGPoint(x: 10.5, y: 4.5))
            path.addLine(to: CGPoint(x: 13.5, y: 4.5))
            path.addLine(to: CGPoint(x: 13.5, y: 6.5))
            path.stroke()
        }
    }

    /// 图标绘制骨架(24乘24的画布按3倍清晰度画白色线条，输出模板图)
    private static func drawIcon(_ drawing: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24), format: format)
        let image = renderer.image { rendererContext in
            let context = rendererContext.cgContext
            context.setStrokeColor(UIColor.white.cgColor)
            context.setFillColor(UIColor.white.cgColor)
            context.setLineWidth(2)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            drawing(context)
        }
        return image.withRenderingMode(.alwaysTemplate)
    }
}
