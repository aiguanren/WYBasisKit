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

    /// 撤销图标(iconfont撤销搜索页第5个原图路径复刻，向左箭头右端尾巴向下弯)
    static var undo: UIImage {
        return drawIcon { context in
            svgPath("M609.206 396.656h-415.702l201.87-199.152c17.787-17.787 17.787-43.185 0-60.973s-41.555-18.641-59.42-0.778l-273.097 266.804c-17.787 17.787-17.787 41.399 0 59.186l273.173 267.115c17.787 17.787 41.555 17.787 59.42-0.078 17.787-17.787 17.787-41.166 0-58.953l-201.948-195.501h415.702c166.219 0 311.155 129.712 311.155 290.029v41.555c0 23.769 15.069 41.555 38.836 41.555s38.836-17.787 38.836-41.555v-41.555c0-207.852-175.073-367.7-388.828-367.7z", design: 1024).fill()
        }
    }

    /// 重做图标(iconfont反撤销原图路径复刻，向右箭头左端尾巴向下弯)
    static var redo: UIImage {
        return drawIcon { context in
            svgPath("M412.081 346.3h443.415l-215.328-212.429c-18.973-18.973-18.973-46.064 0-65.038s44.325-19.884 63.381-0.83l291.385 284.591c18.973 18.973 18.973 44.159 0 63.132l-291.385 284.923c-18.973 18.973-44.325 18.973-63.381-0.083-18.973-18.973-18.973-43.91 0-62.883l215.328-208.534h-443.415c-177.3 0-314.335 138.359-314.335 309.364v44.325c0 25.354-16.074 44.325-41.425 44.325s-41.425-18.973-41.425-44.325v-44.325c0-221.709 169.181-392.213 397.185-392.213z", design: 1024).fill()
        }
    }

    /// 清除图标(iconfont清除搜索页第3页第4个原图路径复刻，左下向右上的清洁擦加圆头与散落圆点，多路径统一单色填充)
    static var clear: UIImage {
        return drawIcon { context in
            let paths = [
                "M454.72 906.89c7.14-43.65 38.94-190.14 101.15-267.78a10.55 10.55 0 0 0-0.64-14.15L339.94 403.43a10.55 10.55 0 0 0-14.15-0.64C249 464.27 119.05 481.89 73.71 489.4a10.56 10.56 0 0 0-7.48 15.6l55 90.71a10.59 10.59 0 0 0 12.71 4.87l152.45-35.62c11.28-3.9 19.39 10.94 10 18.32l-122.23 96.2a10.58 10.58 0 0 0-1.85 14.76l69.28 90.37a10.57 10.57 0 0 0 14.92 1.9l110.94-86.87c9-7 21.19 3.14 15.91 13.24l-72.63 139.59a10.58 10.58 0 0 0 5.27 14.64l124.17 47.75a10.53 10.53 0 0 0 14.55-7.97z",
                "M707.75 550.62l-234.06-234 31.76-19.29c71.49-43.4 157.17-38 208.38 13.21s56.63 136.9 13.2 208.38zM571.09 331.47l121.75 121.76c11.17-38.42 4.25-77-20.25-101.5s-63.07-31.42-101.5-20.26z",
                "M714.13 340.14a29.17 29.17 0 0 1-20.66-49.75L877 106.23a29.16 29.16 0 0 1 41.31 41.17L734.78 331.56a29 29 0 0 1-20.65 8.58zM527.8 918.77a39.65 39.65 0 0 1-13.87-2.51l-142.09-44.58a39.75 39.75 0 0 1-19.69-55l28-53.49L337 797a39.74 39.74 0 0 1-56.06-7.12l-69.32-90.38a39.84 39.84 0 0 1 7-55.41L275 599.66l-71 16.59a39.65 39.65 0 0 1-45.85-18.86l-54.42-89.76c-6.84-12.27-7.21-25.95-1.6-37.59a39.79 39.79 0 0 1 29.25-21.88c39.72-6.59 174.9-32.52 246.74-90.07a39.78 39.78 0 0 1 53 2.74l223.35 223.38a39.7 39.7 0 0 1 2.78 53c-57.93 72.32-83.76 208.27-90.25 248.24a39.74 39.74 0 0 1-39.14 33.31zM509.39 876z m-95.21-52l98.92 30.93c11.34-60.48 37.44-168.2 88.68-240.89L401.35 413.56c-70 49.31-172.53 75.35-233.54 87.28l34 56 139.35-32.54a39.75 39.75 0 0 1 35.71 69.39l-107.8 84.89 46.7 60.92 96.16-75.29a39.75 39.75 0 0 1 59.74 49.71z m-156.3-160zM208 567.09l0.62 1c-0.22-0.33-0.42-0.67-0.62-1z",
                "M756 758.26m-90.81 0a90.81 90.81 0 1 0 181.62 0 90.81 90.81 0 1 0-181.62 0Z",
                "M873.16 486.5m-80.63 0a80.63 80.63 0 1 0 161.26 0 80.63 80.63 0 1 0-161.26 0Z",
                "M359.85 211.23m-80.63 0a80.63 80.63 0 1 0 161.26 0 80.63 80.63 0 1 0-161.26 0Z",
                "M756 860.45a102.19 102.19 0 1 1 102.2-102.19A102.3 102.3 0 0 1 756 860.45z m0-146a43.86 43.86 0 1 0 43.87 43.85A43.9 43.9 0 0 0 756 714.41zM359.85 296.7a85.47 85.47 0 1 1 85.48-85.47 85.55 85.55 0 0 1-85.48 85.47z m0-112.61A27.14 27.14 0 1 0 387 211.23a27.17 27.17 0 0 0-27.15-27.14zM873.17 572a85.47 85.47 0 1 1 85.47-85.46A85.56 85.56 0 0 1 873.17 572z m0-112.61a27.14 27.14 0 1 0 27.14 27.15 27.18 27.18 0 0 0-27.14-27.18z",
            ]
            for d in paths {
                svgPath(d, design: 1024).fill()
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

    /// SVG路径数据字符串转UIBezierPath(支持M/L/H/V/C/S两大小写指令与Z闭合，iconfont导出的1024设计稿按design等比缩进24画布，SVG的y轴与UIKit同向无需翻转)
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
        for (begin, command) in commands {
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
            let index = begin
            if index + arity <= numbers.count {
                let n = { (offset: Int) -> CGFloat in numbers[index + offset] }
                let absolute = { (dx: CGFloat, dy: CGFloat) -> CGPoint in CGPoint(x: dx * scale, y: dy * scale) }
                let relativeTo = { (dx: CGFloat, dy: CGFloat) -> CGPoint in CGPoint(x: current.x + dx * scale, y: current.y + dy * scale) }
                let target: CGPoint
                switch upper {
                case "M":
                    target = relative ? relativeTo(n(0), n(1)) : absolute(n(0), n(1))
                    path.move(to: target)
                    subpathStart = target
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
