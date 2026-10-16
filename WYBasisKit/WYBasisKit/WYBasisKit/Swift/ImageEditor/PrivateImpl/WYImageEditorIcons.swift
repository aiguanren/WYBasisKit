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

    /// 撤销图标(照官人撤销.png，扁长回复箭头，向左横线右端小弯钩上翘，左端开口V形箭头)
    static var undo: UIImage {
        return drawIcon { context in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 4.2, y: 12.7))
            path.addLine(to: CGPoint(x: 16.2, y: 12.7))
            path.addArc(withCenter: CGPoint(x: 16.2, y: 10.1), radius: 2.6, startAngle: .pi / 2, endAngle: 0, clockwise: false)
            path.addLine(to: CGPoint(x: 18.8, y: 7.9))
            path.stroke()
            let head = UIBezierPath()
            head.move(to: CGPoint(x: 8.2, y: 8.7))
            head.addLine(to: CGPoint(x: 4.2, y: 12.7))
            head.addLine(to: CGPoint(x: 8.6, y: 16.5))
            head.stroke()
        }
    }

    /// 重做图标(撤销的水平镜像，扁长回复箭头，向右横线左端小弯钩上翘，右端开口V形箭头)
    static var redo: UIImage {
        return drawIcon { context in
            context.translateBy(x: 24, y: 0)
            context.scaleBy(x: -1, y: 1)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 4.2, y: 12.7))
            path.addLine(to: CGPoint(x: 16.2, y: 12.7))
            path.addArc(withCenter: CGPoint(x: 16.2, y: 10.1), radius: 2.6, startAngle: .pi / 2, endAngle: 0, clockwise: false)
            path.addLine(to: CGPoint(x: 18.8, y: 7.9))
            path.stroke()
            let head = UIBezierPath()
            head.move(to: CGPoint(x: 8.2, y: 8.7))
            head.addLine(to: CGPoint(x: 4.2, y: 12.7))
            head.addLine(to: CGPoint(x: 8.6, y: 16.5))
            head.stroke()
        }
    }

    /// 清除图标(照官人清除.png，扁平左扫的扫帚，右端枢纽向左展开成束毛刷，柄向右下伸，散落圆点)
    static var clear: UIImage {
        return drawIcon { context in
            let handle = UIBezierPath()
            handle.move(to: CGPoint(x: 17.2, y: 7.2))
            handle.addLine(to: CGPoint(x: 22.6, y: 10.2))
            handle.stroke()
            let binding = UIBezierPath()
            binding.move(to: CGPoint(x: 16.4, y: 8.6))
            binding.addLine(to: CGPoint(x: 18.0, y: 5.8))
            binding.stroke()
            let bristles = UIBezierPath()
            bristles.lineWidth = 1.8
            bristles.move(to: CGPoint(x: 16.6, y: 8.0))
            bristles.addLine(to: CGPoint(x: 1.6, y: 11.2))
            bristles.move(to: CGPoint(x: 16.4, y: 9.0))
            bristles.addLine(to: CGPoint(x: 1.2, y: 13.4))
            bristles.move(to: CGPoint(x: 16.2, y: 10.0))
            bristles.addLine(to: CGPoint(x: 2.2, y: 15.4))
            bristles.move(to: CGPoint(x: 15.9, y: 11.0))
            bristles.addLine(to: CGPoint(x: 4.0, y: 17.2))
            bristles.stroke()
            let ring = UIBezierPath(ovalIn: CGRect(x: 14.6 - 1.6, y: 14.4 - 1.6, width: 3.2, height: 3.2))
            ring.lineWidth = 1.4
            ring.stroke()
            for (center, radius) in [(CGPoint(x: 20.8, y: 13.0), 1.0), (CGPoint(x: 18.6, y: 14.8), 0.9), (CGPoint(x: 7.6, y: 13.6), 1.0)] {
                UIBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()
            }
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
