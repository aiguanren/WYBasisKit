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

    /// 撤销图标(向左箭头，右端尾巴向下弯)
    static var undo: UIImage {
        return drawIcon { context in
            svgPath("M609.206 396.656h-415.702l201.87-199.152c17.787-17.787 17.787-43.185 0-60.973s-41.555-18.641-59.42-0.778l-273.097 266.804c-17.787 17.787-17.787 41.399 0 59.186l273.173 267.115c17.787 17.787 41.555 17.787 59.42-0.078 17.787-17.787 17.787-41.166 0-58.953l-201.948-195.501h415.702c166.219 0 311.155 129.712 311.155 290.029v41.555c0 23.769 15.069 41.555 38.836 41.555s38.836-17.787 38.836-41.555v-41.555c0-207.852-175.073-367.7-388.828-367.7z", design: 1024).fill()
        }
    }

    /// 重做图标(向右箭头，左端尾巴向下弯)
    static var redo: UIImage {
        return drawIcon { context in
            svgPath("M412.081 346.3h443.415l-215.328-212.429c-18.973-18.973-18.973-46.064 0-65.038s44.325-19.884 63.381-0.83l291.385 284.591c18.973 18.973 18.973 44.159 0 63.132l-291.385 284.923c-18.973 18.973-44.325 18.973-63.381-0.083-18.973-18.973-18.973-43.91 0-62.883l215.328-208.534h-443.415c-177.3 0-314.335 138.359-314.335 309.364v44.325c0 25.354-16.074 44.325-41.425 44.325s-41.425-18.973-41.425-44.325v-44.325c0-221.709 169.181-392.213 397.185-392.213z", design: 1024).fill()
        }
    }

    /// 清除图标(斜置橡皮擦加底部横线)
    static var clear: UIImage {
        return drawIcon { context in
            svgPath("M912 767.8H579.1l309.5-309.5c19-19 29.4-44.2 29.4-71.1 0-26.8-10.5-52.1-29.5-71.1l-185-185c-39.2-39.2-103-39.2-142.2 0L150.1 542.2c-19 19-29.4 44.2-29.4 71.1 0 26.8 10.5 52.1 29.5 71.1l83.4 83.4H114c-8.8 0-16 7.2-16 16v32c0 8.8 7.2 16 16 16h798c8.8 0 16-7.2 16-16v-32c0-8.9-7.2-16-16-16zM195.4 639.1c-6.9-6.9-10.7-16.1-10.7-25.9 0-9.8 3.8-18.9 10.7-25.8l341.1-341.1 236.8 236.8-284.8 284.7H324.1L195.4 639.1z", design: 1024).fill()
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

    /// SVG路径数据字符串转UIBezierPath(支持M/L/H/V/C/S两大小写指令与Z闭合，1024设计稿按design等比缩进24画布，SVG的y轴与UIKit同向无需翻转)
    private static func svgPath(_ d: String, design: CGFloat, evenOdd: Bool = false) -> UIBezierPath {

        // 先分词(命令字母与数字，负号在数字之间时兼作分隔符)
        var tokens: [String] = []
        var token = ""
        for character in d {
            if character.isLetter {
                if !token.isEmpty { tokens.append(token); token = "" }
                tokens.append(String(character))
            } else if character.isNumber || character == "." || character == "e" || character == "E" || ((character == "-" || character == "+") && !token.isEmpty && (token.last == "e" || token.last == "E")) {
                token.append(character)
            } else if character == "-" || character == "+" {
                if !token.isEmpty { tokens.append(token) }
                token = String(character)
            } else {
                if !token.isEmpty { tokens.append(token); token = "" }
            }
        }
        if !token.isEmpty { tokens.append(token) }

        // 数字抽成一列，命令记录自己 consume 的数字起始下标
        var numbers: [CGFloat] = []
        var commands: [(Int, Character)] = []
        for token in tokens {
            if token.count == 1, let letter = token.first, letter.isLetter {
                commands.append((numbers.count, letter))
            } else if let value = Double(token) {
                numbers.append(CGFloat(value))
            }
        }

        let scale = 24 / design
        let path = UIBezierPath()
        path.usesEvenOddFillRule = evenOdd
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastControl: CGPoint?
        for (commandIndex, (begin, command)) in commands.enumerated() {
            let upper = Character(command.uppercased())
            let relative = command.isLowercase
            let arity: Int
            switch upper {
            case "M", "L": arity = 2
            case "H", "V": arity = 1
            case "C": arity = 6
            case "S": arity = 4
            default: arity = 0
            }
            if upper == "Z" {
                path.close()
                current = subpathStart
                lastControl = nil
                continue
            }
            var index = begin
            var pairIndex = 0
            let end = commandIndex + 1 < commands.count ? commands[commandIndex + 1].0 : numbers.count
            while index + arity <= end {
                let n = { (offset: Int) -> CGFloat in numbers[index + offset] }
                let absolute = { (dx: CGFloat, dy: CGFloat) -> CGPoint in CGPoint(x: dx * scale, y: dy * scale) }
                let relativeTo = { (dx: CGFloat, dy: CGFloat) -> CGPoint in CGPoint(x: current.x + dx * scale, y: current.y + dy * scale) }
                let target: CGPoint
                switch upper {
                case "M":
                    target = relative ? relativeTo(n(0), n(1)) : absolute(n(0), n(1))
                    if pairIndex == 0 {
                        path.move(to: target)
                        subpathStart = target
                    } else {
                        path.addLine(to: target)
                    }
                    lastControl = nil
                case "L":
                    target = relative ? relativeTo(n(0), n(1)) : absolute(n(0), n(1))
                    path.addLine(to: target)
                    lastControl = nil
                case "H":
                    target = CGPoint(x: relative ? current.x + n(0) * scale : n(0) * scale, y: current.y)
                    path.addLine(to: target)
                    lastControl = nil
                case "V":
                    target = CGPoint(x: current.x, y: relative ? current.y + n(0) * scale : n(0) * scale)
                    path.addLine(to: target)
                    lastControl = nil
                case "C":
                    let control1 = relative ? relativeTo(n(0), n(1)) : absolute(n(0), n(1))
                    let control2 = relative ? relativeTo(n(2), n(3)) : absolute(n(2), n(3))
                    target = relative ? relativeTo(n(4), n(5)) : absolute(n(4), n(5))
                    path.addCurve(to: target, controlPoint1: control1, controlPoint2: control2)
                    lastControl = control2
                default:
                    let control1: CGPoint
                    if let last = lastControl {
                        control1 = CGPoint(x: current.x * 2 - last.x, y: current.y * 2 - last.y)
                    } else {
                        control1 = current
                    }
                    let control2 = relative ? relativeTo(n(0), n(1)) : absolute(n(0), n(1))
                    target = relative ? relativeTo(n(2), n(3)) : absolute(n(2), n(3))
                    path.addCurve(to: target, controlPoint1: control1, controlPoint2: control2)
                    lastControl = control2
                }
                current = target
                index += arity
                pairIndex += 1
            }
        }
        return path
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
