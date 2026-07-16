//
//  WYTestAirBubbleController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/7/2.
//

import UIKit

class WYTestAirBubbleController: UIViewController {

    // MARK: - 交互气泡（悬浮于顶部）
    private var bubbleContainer: UIView!
    private var interactiveBubble: WYAirBubbleView!
    private var bubbleDescriptionLabel: UILabel!
    private var bubbleStatusLabel: UILabel!
    private var bubbleWidthConstraint: NSLayoutConstraint!
    private var bubbleHeightConstraint: NSLayoutConstraint!
    private var bubbleCenterXConstraint: NSLayoutConstraint!
    private var bubbleTopConstraint: NSLayoutConstraint!
    private var containerHeightConstraint: NSLayoutConstraint!

    // MARK: - 滚动容器
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var staticVerticalStack: UIStackView!

    // MARK: - 控件
    private var directionSegmented: UISegmentedControl!
    private var showArrowSwitch: UISwitch!
    private var radiusSlider: UISlider!
    private var arrowWidthSlider: UISlider!
    private var arrowHeightSlider: UISlider!
    private var offsetSlider: UISlider!
    private var tipRadiusSlider: UISlider!
    private var borderWidthSlider: UISlider!
    private var cornersSegmented: UISegmentedControl!
    private var widthSlider: UISlider!
    private var heightSlider: UISlider!
    private var edgePaddingSlider: UISlider!

    // 边框颜色按钮组
    private var borderColorButtons: [UIButton] = []
    private var selectedBorderColorIndex = 0

    // 渐变相关
    private var gradientSegmented: UISegmentedControl!
    private var gradientDirectionSegmented: UISegmentedControl!

    // 阴影相关
    private var shadowEnableSwitch: UISwitch!
    private var shadowColorButtons: [UIButton] = []
    private var selectedShadowColorIndex = 0
    private var shadowOffsetXSlider: UISlider!
    private var shadowOffsetYSlider: UISlider!
    private var shadowRadiusSlider: UISlider!
    private var shadowOpacitySlider: UISlider!

    // ===== 动画状态管理 =====
    private var initialState: (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) = (0, 0, 160, 100)
    private var finalState: (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) = (80, 0, 200, 100)
    private var isAtInitial = true
    private var hasAppliedInitialState = false

    // ===== 动画控制滑块 =====
    private var initialXSlider: UISlider!
    private var initialYSlider: UISlider!
    private var initialWidthSlider: UISlider!
    private var initialHeightSlider: UISlider!
    private var finalXSlider: UISlider!
    private var finalYSlider: UISlider!
    private var finalWidthSlider: UISlider!
    private var finalHeightSlider: UISlider!
    private var animationDurationSlider: UISlider!

    // 存储滑块与数值标签的映射
    private var valueLabelMap: [UISlider: UILabel] = [:]

    // 预估描述标签高度（用于边界计算）
    private let estimatedDescriptionHeight: CGFloat = 80

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupScrollView()
        setupStaticExamples()
        setupInteractiveBubble()
        // 初始化状态变量（但暂不应用，等布局完成）
        initialState.width = bubbleWidthConstraint.constant
        initialState.height = bubbleHeightConstraint.constant
        initialState.x = 0
        initialState.y = 0
        setupControls()
        // 注意：不在此处调用 applyState，因为容器尺寸未确定
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 仅在容器尺寸有效且尚未应用初始状态时，应用一次
        if !hasAppliedInitialState && bubbleContainer.bounds.width > 0 && bubbleContainer.bounds.height > 0 {
            applyState(initialState, animated: false, duration: 0)
            hasAppliedInitialState = true
        }
    }

    // MARK: - 滚动容器

    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - 静态示例（使用 StackView 管理）

    private func setupStaticExamples() {
        typealias BubbleConfig = (WYAirBubbleView) -> Void
        typealias DescBuilder = (WYAirBubbleView) -> String

        func makeExampleStack(with config: BubbleConfig, descBuilder: @escaping DescBuilder) -> UIStackView {
            let bubble = WYAirBubbleView()
            bubble.translatesAutoresizingMaskIntoConstraints = false
            config(bubble)

            NSLayoutConstraint.activate([
                bubble.widthAnchor.constraint(equalToConstant: 160),
                bubble.heightAnchor.constraint(equalToConstant: 100)
            ])

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .systemFont(ofSize: 11)
            label.textColor = .darkGray
            label.numberOfLines = 0
            label.textAlignment = .left
            label.text = descBuilder(bubble)
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

            let stack = UIStackView(arrangedSubviews: [bubble, label])
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.axis = .horizontal
            stack.spacing = 12
            stack.alignment = .center
            stack.distribution = .fill

            return stack
        }

        func desc(for bubble: WYAirBubbleView, direction: WYArrowDirection, cornerDesc: String, extra: String = "") -> String {
            let dirStr: String
            switch direction {
            case .top: dirStr = "上"
            case .bottom: dirStr = "下"
            case .left: dirStr = "左"
            case .right: dirStr = "右"
            }
            let arrowSize = bubble.arrowSize
            let tipR = bubble.arrowTipRadius
            let offset = bubble.arrowOffset
            let borderW = bubble.borderWidth
            let borderColor = bubble.borderColor == .clear ? "无" : "有"
            let fillColorDesc = bubble.fillColor.accessibilityName ?? "自定义"
            let edgePad = bubble.arrowEdgePadding
            return """
            方向: \(dirStr)
            圆角: \(cornerDesc) 半径\(Int(bubble.cornerRadius))
            箭头: 宽\(Int(arrowSize.width))高\(Int(arrowSize.height))
            偏移: \(Int(offset)) | 边距: \(Int(edgePad))
            尖端圆角: \(Int(tipR))
            边框: \(borderW)pt (\(borderColor))
            填充色: \(fillColorDesc)
            \(extra)
            """
        }

        func cornerPositionDesc(_ corners: UIRectCorner) -> String {
            if corners == .allCorners { return "全部" }
            var parts: [String] = []
            if corners.contains(.topLeft) { parts.append("左上") }
            if corners.contains(.topRight) { parts.append("右上") }
            if corners.contains(.bottomLeft) { parts.append("左下") }
            if corners.contains(.bottomRight) { parts.append("右下") }
            return parts.joined(separator: "+")
        }

        let examples: [(BubbleConfig, DescBuilder)] = [
            ({ $0.fillColor = .systemBlue },
             { bubble in desc(for: bubble, direction: .bottom, cornerDesc: "全部") }),

            ({
                $0.arrowDirection = .top
                $0.fillColor = .systemRed
                $0.borderColor = .black
                $0.borderWidth = 2
             },
             { bubble in desc(for: bubble, direction: .top, cornerDesc: "全部", extra: "边框颜色: 黑色") }),

            ({
                $0.arrowDirection = .left
                $0.fillColor = .systemGreen
             },
             { bubble in desc(for: bubble, direction: .left, cornerDesc: "全部") }),

            ({
                $0.arrowDirection = .right
                $0.fillColor = .systemPurple
                $0.cornerRadius = 0
                $0.arrowTipRadius = 6
             },
             { bubble in desc(for: bubble, direction: .right, cornerDesc: "无", extra: "") }),

            ({
                $0.arrowDirection = .bottom
                $0.fillColor = .systemOrange
                $0.arrowOffset = 30
                $0.arrowSize = CGSize(width: 20, height: 12)
             },
             { bubble in desc(for: bubble, direction: .bottom, cornerDesc: "全部", extra: "偏移: +30, 箭头: 20x12") }),

            ({
                $0.showsArrow = false
                $0.fillColor = .systemPink
                $0.cornersPosition = [.topLeft, .bottomRight]
                $0.cornerRadius = 20
             },
             { bubble in
                 let cornerDesc = cornerPositionDesc(bubble.cornersPosition)
                 return """
                 无箭头
                 圆角: \(cornerDesc) 半径\(Int(bubble.cornerRadius))
                 填充色: 粉色
                 """
             }),

            ({
                $0.arrowDirection = .bottom
                $0.fillColor = .systemBrown
                $0.borderColor = .blue
                $0.borderWidth = 2
                $0.arrowEdgePadding = 15
                $0.cornerRadius = 12
             },
             { bubble in desc(for: bubble, direction: .bottom, cornerDesc: "全部", extra: "边框颜色: 蓝色，边距: 15") })
        ]

        staticVerticalStack = UIStackView()
        staticVerticalStack.translatesAutoresizingMaskIntoConstraints = false
        staticVerticalStack.axis = .vertical
        staticVerticalStack.spacing = 20
        staticVerticalStack.alignment = .fill
        contentView.addSubview(staticVerticalStack)

        NSLayoutConstraint.activate([
            staticVerticalStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            staticVerticalStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            staticVerticalStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        for (config, descBuilder) in examples {
            let stack = makeExampleStack(with: config, descBuilder: descBuilder)
            staticVerticalStack.addArrangedSubview(stack)
        }
    }

    // MARK: - 交互气泡（悬浮于顶部）

    private func setupInteractiveBubble() {
        bubbleContainer = UIView()
        bubbleContainer.translatesAutoresizingMaskIntoConstraints = false
        bubbleContainer.backgroundColor = .systemGray6 // 调试用，可注释
        view.addSubview(bubbleContainer)

        // 容器高度为屏幕高度的 2/5
        containerHeightConstraint = bubbleContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 2/5.0)
        NSLayoutConstraint.activate([
            bubbleContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            bubbleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            bubbleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            containerHeightConstraint
        ])

        interactiveBubble = WYAirBubbleView()
        interactiveBubble.translatesAutoresizingMaskIntoConstraints = false
        interactiveBubble.fillColor = .systemTeal
        interactiveBubble.arrowDirection = .bottom
        interactiveBubble.showsArrow = true
        bubbleContainer.addSubview(interactiveBubble)

        // 初始尺寸 160x100
        bubbleWidthConstraint = interactiveBubble.widthAnchor.constraint(equalToConstant: 160)
        bubbleHeightConstraint = interactiveBubble.heightAnchor.constraint(equalToConstant: 100)
        // 位置约束
        bubbleCenterXConstraint = interactiveBubble.centerXAnchor.constraint(equalTo: bubbleContainer.centerXAnchor, constant: 0)
        bubbleTopConstraint = interactiveBubble.topAnchor.constraint(equalTo: bubbleContainer.topAnchor, constant: 0)
        NSLayoutConstraint.activate([
            bubbleCenterXConstraint,
            bubbleTopConstraint,
            bubbleWidthConstraint,
            bubbleHeightConstraint
        ])

        bubbleDescriptionLabel = UILabel()
        bubbleDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleDescriptionLabel.text = "⬇️ 下方操作区域可动态调整此气泡 ⬇️"
        bubbleDescriptionLabel.font = .systemFont(ofSize: 13, weight: .medium)
        bubbleDescriptionLabel.textColor = .systemBlue
        bubbleDescriptionLabel.textAlignment = .center
        bubbleDescriptionLabel.numberOfLines = 0
        bubbleContainer.addSubview(bubbleDescriptionLabel)

        bubbleStatusLabel = UILabel()
        bubbleStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleStatusLabel.text = "拖动下方滑块查看实时变化"
        bubbleStatusLabel.font = .systemFont(ofSize: 11)
        bubbleStatusLabel.textColor = .gray
        bubbleStatusLabel.textAlignment = .center
        bubbleStatusLabel.numberOfLines = 0
        bubbleContainer.addSubview(bubbleStatusLabel)

        // 描述标签在气泡下方，状态标签在描述下方
        NSLayoutConstraint.activate([
            bubbleDescriptionLabel.topAnchor.constraint(equalTo: interactiveBubble.bottomAnchor, constant: 8),
            bubbleDescriptionLabel.leadingAnchor.constraint(equalTo: bubbleContainer.leadingAnchor, constant: 8),
            bubbleDescriptionLabel.trailingAnchor.constraint(equalTo: bubbleContainer.trailingAnchor, constant: -8),

            bubbleStatusLabel.topAnchor.constraint(equalTo: bubbleDescriptionLabel.bottomAnchor, constant: 2),
            bubbleStatusLabel.leadingAnchor.constraint(equalTo: bubbleContainer.leadingAnchor, constant: 8),
            bubbleStatusLabel.trailingAnchor.constraint(equalTo: bubbleContainer.trailingAnchor, constant: -8),
            bubbleStatusLabel.bottomAnchor.constraint(equalTo: bubbleContainer.bottomAnchor, constant: -4)
        ])

        // 滚动视图顶部约束到容器底部
        if let scrollView = scrollView {
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: bubbleContainer.bottomAnchor, constant: 12)
            ])
        }
    }

    // MARK: - 控制控件

    private func setupControls() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: staticVerticalStack.bottomAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        func makeControlRow(label: String, control: UIView, labelWidth: CGFloat = 80) -> UIStackView {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 10
            row.alignment = .center

            let lbl = UILabel()
            lbl.text = label
            lbl.font = .systemFont(ofSize: 14, weight: .medium)
            lbl.setContentHuggingPriority(.required, for: .horizontal)
            lbl.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
            row.addArrangedSubview(lbl)

            row.addArrangedSubview(control)
            return row
        }

        // ---- 原有控件 ----
        directionSegmented = UISegmentedControl(items: ["上", "下", "左", "右"])
        directionSegmented.selectedSegmentIndex = 1
        directionSegmented.addTarget(self, action: #selector(directionChanged), for: .valueChanged)
        stack.addArrangedSubview(makeControlRow(label: "箭头方向", control: directionSegmented))

        showArrowSwitch = UISwitch()
        showArrowSwitch.isOn = true
        showArrowSwitch.addTarget(self, action: #selector(showArrowToggled), for: .valueChanged)
        stack.addArrangedSubview(makeControlRow(label: "显示箭头", control: showArrowSwitch))

        let radiusRow = makeSliderRow(label: "圆角半径", min: 0, max: 30, value: 12, action: #selector(radiusChanged))
        radiusSlider = radiusRow.slider
        stack.addArrangedSubview(radiusRow.view)

        cornersSegmented = UISegmentedControl(items: ["全部", "左上+右下", "右上+左下", "仅左上", "仅右下"])
        cornersSegmented.selectedSegmentIndex = 0
        cornersSegmented.addTarget(self, action: #selector(cornersChanged), for: .valueChanged)
        stack.addArrangedSubview(makeControlRow(label: "圆角位置", control: cornersSegmented))

        let widthRow = makeSliderRow(label: "箭头宽度", min: 6, max: 30, value: 12, action: #selector(arrowWidthChanged))
        arrowWidthSlider = widthRow.slider
        stack.addArrangedSubview(widthRow.view)

        let heightRow = makeSliderRow(label: "箭头高度", min: 4, max: 20, value: 8, action: #selector(arrowHeightChanged))
        arrowHeightSlider = heightRow.slider
        stack.addArrangedSubview(heightRow.view)

        let offsetRow = makeSliderRow(label: "箭头偏移", min: -100, max: 100, value: 0, action: #selector(offsetChanged))
        offsetSlider = offsetRow.slider
        stack.addArrangedSubview(offsetRow.view)

        let edgeRow = makeSliderRow(label: "箭头边距", min: 0, max: 30, value: 0, action: #selector(edgePaddingChanged))
        edgePaddingSlider = edgeRow.slider
        stack.addArrangedSubview(edgeRow.view)

        let tipRow = makeSliderRow(label: "尖端圆角", min: 0, max: 30, value: 0, action: #selector(tipRadiusChanged))
        tipRadiusSlider = tipRow.slider
        stack.addArrangedSubview(tipRow.view)

        let borderRow = makeSliderRow(label: "边框宽度", min: 0, max: 5, value: 0, action: #selector(borderWidthChanged))
        borderWidthSlider = borderRow.slider
        stack.addArrangedSubview(borderRow.view)

        let borderColorStack = makeColorButtonRow(label: "边框颜色", colors: [(.clear, "清除"), (.red, "红"), (.green, "绿"), (.blue, "蓝"), (.black, "黑"), (.orange, "橙")],
                                                  target: self, action: #selector(borderColorButtonTapped(_:)))
        borderColorButtons = borderColorStack.buttons
        selectedBorderColorIndex = 0
        borderColorButtons[0].layer.borderWidth = 2
        borderColorButtons[0].layer.borderColor = UIColor.gray.cgColor
        stack.addArrangedSubview(borderColorStack.view)

        gradientSegmented = UISegmentedControl(items: ["无", "蓝→紫", "红→黄", "绿→青"])
        gradientSegmented.selectedSegmentIndex = 0
        gradientSegmented.addTarget(self, action: #selector(gradientChanged), for: .valueChanged)
        stack.addArrangedSubview(makeControlRow(label: "渐变色", control: gradientSegmented))

        gradientDirectionSegmented = UISegmentedControl(items: ["左→右", "上→下", "左上→右下", "右上→左下"])
        gradientDirectionSegmented.selectedSegmentIndex = 0
        gradientDirectionSegmented.addTarget(self, action: #selector(gradientDirectionChanged), for: .valueChanged)
        stack.addArrangedSubview(makeControlRow(label: "渐变方向", control: gradientDirectionSegmented))

        shadowEnableSwitch = UISwitch()
        shadowEnableSwitch.isOn = false
        shadowEnableSwitch.addTarget(self, action: #selector(shadowEnableToggled), for: .valueChanged)
        stack.addArrangedSubview(makeControlRow(label: "阴影启用", control: shadowEnableSwitch))

        let shadowColorStack = makeColorButtonRow(label: "阴影颜色", colors: [(.black, "黑"), (.gray, "灰"), (.red, "红"), (.blue, "蓝")],
                                                  target: self, action: #selector(shadowColorButtonTapped(_:)))
        shadowColorButtons = shadowColorStack.buttons
        selectedShadowColorIndex = 0
        shadowColorButtons[0].layer.borderWidth = 2
        shadowColorButtons[0].layer.borderColor = UIColor.gray.cgColor
        stack.addArrangedSubview(shadowColorStack.view)

        let offsetXRow = makeSliderRow(label: "阴影偏移X", min: -20, max: 20, value: 0, action: #selector(shadowOffsetXChanged))
        shadowOffsetXSlider = offsetXRow.slider
        stack.addArrangedSubview(offsetXRow.view)

        let offsetYRow = makeSliderRow(label: "阴影偏移Y", min: -20, max: 20, value: 0, action: #selector(shadowOffsetYChanged))
        shadowOffsetYSlider = offsetYRow.slider
        stack.addArrangedSubview(offsetYRow.view)

        let shadowRadiusRow = makeSliderRow(label: "阴影半径", min: 0, max: 20, value: 0, action: #selector(shadowRadiusChanged))
        shadowRadiusSlider = shadowRadiusRow.slider
        stack.addArrangedSubview(shadowRadiusRow.view)

        let shadowOpacityRow = makeSliderRow(label: "阴影模糊度", min: 0, max: 1, value: 0.5, action: #selector(shadowOpacityChanged))
        shadowOpacitySlider = shadowOpacityRow.slider
        stack.addArrangedSubview(shadowOpacityRow.view)

        // 气泡尺寸滑块（直接调整当前状态）
        let widthSizeRow = makeSliderRow(label: "气泡宽度", min: 20, max: 300, value: 160, action: #selector(widthChanged))
        widthSlider = widthSizeRow.slider
        stack.addArrangedSubview(widthSizeRow.view)

        let heightSizeRow = makeSliderRow(label: "气泡高度", min: 20, max: 200, value: 100, action: #selector(heightChanged))
        heightSlider = heightSizeRow.slider
        stack.addArrangedSubview(heightSizeRow.view)

        let colorButton = UIButton(type: .system)
        colorButton.setTitle("随机填充颜色", for: .normal)
        colorButton.addTarget(self, action: #selector(colorButtonTapped), for: .touchUpInside)
        stack.addArrangedSubview(makeControlRow(label: "填充颜色", control: colorButton))

        // ===== 自定义动画控制面板 =====
        let panelTitle = UILabel()
        panelTitle.text = "--- 自定义动画控制 ---"
        panelTitle.font = .systemFont(ofSize: 16, weight: .bold)
        panelTitle.textAlignment = .center
        stack.addArrangedSubview(panelTitle)

        // 初始状态分组
        let initialGroupLabel = UILabel()
        initialGroupLabel.text = "初始状态"
        initialGroupLabel.font = .systemFont(ofSize: 14, weight: .medium)
        initialGroupLabel.textColor = .systemBlue
        stack.addArrangedSubview(initialGroupLabel)

        let initXRow = makeSliderRow(label: "X偏移", min: -150, max: 150, value: Float(initialState.x), action: #selector(initialXChanged))
        initialXSlider = initXRow.slider
        stack.addArrangedSubview(initXRow.view)

        let initYRow = makeSliderRow(label: "Y偏移", min: -100, max: 100, value: Float(initialState.y), action: #selector(initialYChanged))
        initialYSlider = initYRow.slider
        stack.addArrangedSubview(initYRow.view)

        let initWRow = makeSliderRow(label: "宽度", min: 20, max: 300, value: Float(initialState.width), action: #selector(initialWidthChanged))
        initialWidthSlider = initWRow.slider
        stack.addArrangedSubview(initWRow.view)

        let initHRow = makeSliderRow(label: "高度", min: 20, max: 200, value: Float(initialState.height), action: #selector(initialHeightChanged))
        initialHeightSlider = initHRow.slider
        stack.addArrangedSubview(initHRow.view)

        // 最终状态分组
        let finalGroupLabel = UILabel()
        finalGroupLabel.text = "最终状态"
        finalGroupLabel.font = .systemFont(ofSize: 14, weight: .medium)
        finalGroupLabel.textColor = .systemGreen
        stack.addArrangedSubview(finalGroupLabel)

        let finXRow = makeSliderRow(label: "X偏移", min: -150, max: 150, value: Float(finalState.x), action: #selector(finalXChanged))
        finalXSlider = finXRow.slider
        stack.addArrangedSubview(finXRow.view)

        let finYRow = makeSliderRow(label: "Y偏移", min: -100, max: 100, value: Float(finalState.y), action: #selector(finalYChanged))
        finalYSlider = finYRow.slider
        stack.addArrangedSubview(finYRow.view)

        let finWRow = makeSliderRow(label: "宽度", min: 20, max: 300, value: Float(finalState.width), action: #selector(finalWidthChanged))
        finalWidthSlider = finWRow.slider
        stack.addArrangedSubview(finWRow.view)

        let finHRow = makeSliderRow(label: "高度", min: 20, max: 200, value: Float(finalState.height), action: #selector(finalHeightChanged))
        finalHeightSlider = finHRow.slider
        stack.addArrangedSubview(finHRow.view)

        // 动画时长
        let durationRow = makeSliderRow(label: "动画时长(s)", min: 0, max: 10, value: 1.0, action: #selector(animationDurationChanged))
        animationDurationSlider = durationRow.slider
        stack.addArrangedSubview(durationRow.view)

        // 操作按钮
        let actionStack = UIStackView()
        actionStack.axis = .horizontal
        actionStack.spacing = 12
        actionStack.distribution = .fillEqually

        let startBtn = UIButton(type: .system)
        startBtn.setTitle("开始动画", for: .normal)
        startBtn.addTarget(self, action: #selector(startAnimation), for: .touchUpInside)
        startBtn.backgroundColor = .systemGray5
        startBtn.layer.cornerRadius = 6
        actionStack.addArrangedSubview(startBtn)

        let resetBtn = UIButton(type: .system)
        resetBtn.setTitle("重置到初始", for: .normal)
        resetBtn.addTarget(self, action: #selector(resetToInitial), for: .touchUpInside)
        resetBtn.backgroundColor = .systemGray5
        resetBtn.layer.cornerRadius = 6
        actionStack.addArrangedSubview(resetBtn)

        stack.addArrangedSubview(actionStack)

        // 重置所有属性
        let resetAllButton = UIButton(type: .system)
        resetAllButton.setTitle("重置所有属性", for: .normal)
        resetAllButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        resetAllButton.backgroundColor = .systemGray5
        resetAllButton.layer.cornerRadius = 8
        resetAllButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        resetAllButton.addTarget(self, action: #selector(resetAllTapped), for: .touchUpInside)
        stack.addArrangedSubview(resetAllButton)
    }

    // MARK: - 辅助：滑块行

    private func makeSliderRow(label: String, min: Float, max: Float, value: Float, action: Selector) -> (view: UIStackView, slider: UISlider) {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center

        let lbl = UILabel()
        lbl.text = label
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        lbl.setContentHuggingPriority(.required, for: .horizontal)
        lbl.widthAnchor.constraint(equalToConstant: 80).isActive = true
        stack.addArrangedSubview(lbl)

        let slider = UISlider()
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = value
        slider.addTarget(self, action: action, for: .valueChanged)
        stack.addArrangedSubview(slider)

        let valueLabel = UILabel()
        valueLabel.text = String(format: "%.1f", value)
        valueLabel.font = .systemFont(ofSize: 12)
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        stack.addArrangedSubview(valueLabel)

        valueLabelMap[slider] = valueLabel

        return (stack, slider)
    }

    private func updateLabel(for slider: UISlider) {
        guard let label = valueLabelMap[slider] else { return }
        let value = slider.value
        if slider == animationDurationSlider {
            label.text = String(format: "%.1f", value)
        } else {
            label.text = "\(Int(value))"
        }
    }

    // MARK: - 辅助：颜色按钮行

    private func makeColorButtonRow(label: String, colors: [(UIColor, String)], target: Any?, action: Selector) -> (view: UIStackView, buttons: [UIButton]) {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center

        let lbl = UILabel()
        lbl.text = label
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        lbl.setContentHuggingPriority(.required, for: .horizontal)
        lbl.widthAnchor.constraint(equalToConstant: 80).isActive = true
        stack.addArrangedSubview(lbl)

        var buttons: [UIButton] = []
        for (color, title) in colors {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12)
            btn.backgroundColor = color == .clear ? .lightGray : color
            btn.setTitleColor(color == .clear ? .darkGray : .white, for: .normal)
            btn.layer.cornerRadius = 4
            btn.clipsToBounds = true
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
            btn.tag = buttons.count
            btn.addTarget(target, action: action, for: .touchUpInside)
            buttons.append(btn)
            stack.addArrangedSubview(btn)
        }

        return (stack, buttons)
    }

    // MARK: - 边界限制函数

    /// 根据当前容器尺寸和气泡尺寸，将状态值限制在有效范围内，防止超出容器
    private func clampState(_ state: (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)) -> (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        guard let container = bubbleContainer else { return state }
        let containerWidth = container.bounds.width
        let containerHeight = container.bounds.height

        // 如果容器尺寸为0，则无法计算有效范围，直接返回原状态（避免裁剪错误）
        guard containerWidth > 0 && containerHeight > 0 else {
            return state
        }

        // 有效宽度：气泡宽度不能超过容器宽度减去边距（左右各10）
        let margin: CGFloat = 10
        let maxWidth = containerWidth - margin * 2
        let clampedWidth = min(max(state.width, 20), maxWidth)

        // 有效高度：气泡高度不能超过容器高度减去描述区域（预估）和边距
        let maxHeight = containerHeight - estimatedDescriptionHeight - margin * 2
        let clampedHeight = min(max(state.height, 20), maxHeight)

        // 有效X偏移：确保气泡在水平方向不超出容器
        let halfWidth = clampedWidth / 2
        let minX = -containerWidth / 2 + halfWidth + margin
        let maxX = containerWidth / 2 - halfWidth - margin
        let clampedX = min(max(state.x, minX), maxX)

        // 有效Y偏移：确保气泡顶部不超出容器顶部，底部不超出描述标签区域
        let minY = margin
        let maxY = containerHeight - clampedHeight - margin - estimatedDescriptionHeight
        let clampedY = min(max(state.y, minY), maxY)

        return (clampedX, clampedY, clampedWidth, clampedHeight)
    }

    // MARK: - 状态应用方法（使用约束，并应用边界限制）

    private func applyState(_ state: (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat),
                            animated: Bool,
                            duration: TimeInterval) {
        // 先限制状态值
        let clamped = clampState(state)

        // 更新约束常量
        bubbleCenterXConstraint.constant = clamped.x
        bubbleTopConstraint.constant = clamped.y
        bubbleWidthConstraint.constant = clamped.width
        bubbleHeightConstraint.constant = clamped.height

        let applyBlock = {
            self.view.layoutIfNeeded()
        }

        if animated && duration > 0.01 {
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: applyBlock)
        } else {
            UIView.performWithoutAnimation(applyBlock)
        }
    }

    // MARK: - 滑块回调

    @objc private func initialXChanged(_ sender: UISlider) {
        initialState.x = CGFloat(sender.value)
        updateLabel(for: sender)
        if isAtInitial {
            applyState(initialState, animated: false, duration: 0)
        }
    }

    @objc private func initialYChanged(_ sender: UISlider) {
        initialState.y = CGFloat(sender.value)
        updateLabel(for: sender)
        if isAtInitial {
            applyState(initialState, animated: false, duration: 0)
        }
    }

    @objc private func initialWidthChanged(_ sender: UISlider) {
        initialState.width = CGFloat(sender.value)
        updateLabel(for: sender)
        if isAtInitial {
            applyState(initialState, animated: false, duration: 0)
        }
    }

    @objc private func initialHeightChanged(_ sender: UISlider) {
        initialState.height = CGFloat(sender.value)
        updateLabel(for: sender)
        if isAtInitial {
            applyState(initialState, animated: false, duration: 0)
        }
    }

    @objc private func finalXChanged(_ sender: UISlider) {
        finalState.x = CGFloat(sender.value)
        updateLabel(for: sender)
        if !isAtInitial {
            applyState(finalState, animated: false, duration: 0)
        }
    }

    @objc private func finalYChanged(_ sender: UISlider) {
        finalState.y = CGFloat(sender.value)
        updateLabel(for: sender)
        if !isAtInitial {
            applyState(finalState, animated: false, duration: 0)
        }
    }

    @objc private func finalWidthChanged(_ sender: UISlider) {
        finalState.width = CGFloat(sender.value)
        updateLabel(for: sender)
        if !isAtInitial {
            applyState(finalState, animated: false, duration: 0)
        }
    }

    @objc private func finalHeightChanged(_ sender: UISlider) {
        finalState.height = CGFloat(sender.value)
        updateLabel(for: sender)
        if !isAtInitial {
            applyState(finalState, animated: false, duration: 0)
        }
    }

    @objc private func animationDurationChanged(_ sender: UISlider) {
        updateLabel(for: sender)
    }

    // MARK: - 动画操作

    @objc private func startAnimation() {
        // 取消当前动画
        interactiveBubble.layer.removeAllAnimations()
        view.layer.removeAllAnimations()

        let duration = TimeInterval(animationDurationSlider.value)

        if isAtInitial {
            applyState(finalState, animated: true, duration: duration)
            isAtInitial = false
        } else {
            applyState(initialState, animated: true, duration: duration)
            isAtInitial = true
        }
        updateStatusLabel()
    }

    @objc private func resetToInitial() {
        interactiveBubble.layer.removeAllAnimations()
        view.layer.removeAllAnimations()
        applyState(initialState, animated: false, duration: 0)
        isAtInitial = true
        // 同步初始滑块
        initialXSlider.value = Float(initialState.x)
        initialYSlider.value = Float(initialState.y)
        initialWidthSlider.value = Float(initialState.width)
        initialHeightSlider.value = Float(initialState.height)
        for slider in [initialXSlider, initialYSlider, initialWidthSlider, initialHeightSlider] {
            updateLabel(for: slider!)
        }
        updateStatusLabel()
    }

    // MARK: - 原有控件响应

    @objc private func directionChanged(_ sender: UISegmentedControl) {
        let directions: [WYArrowDirection] = [.top, .bottom, .left, .right]
        interactiveBubble.arrowDirection = directions[sender.selectedSegmentIndex]
        updateStatusLabel()
    }

    @objc private func showArrowToggled(_ sender: UISwitch) {
        interactiveBubble.showsArrow = sender.isOn
        updateStatusLabel()
    }

    @objc private func radiusChanged(_ sender: UISlider) {
        interactiveBubble.cornerRadius = CGFloat(sender.value)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func cornersChanged(_ sender: UISegmentedControl) {
        let corners: [UIRectCorner] = [
            .allCorners,
            [.topLeft, .bottomRight],
            [.topRight, .bottomLeft],
            .topLeft,
            .bottomRight
        ]
        interactiveBubble.cornersPosition = corners[sender.selectedSegmentIndex]
        updateStatusLabel()
    }

    @objc private func arrowWidthChanged(_ sender: UISlider) {
        let w = CGFloat(sender.value)
        let h = interactiveBubble.arrowSize.height
        interactiveBubble.arrowSize = CGSize(width: w, height: h)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func arrowHeightChanged(_ sender: UISlider) {
        let w = interactiveBubble.arrowSize.width
        let h = CGFloat(sender.value)
        interactiveBubble.arrowSize = CGSize(width: w, height: h)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func offsetChanged(_ sender: UISlider) {
        interactiveBubble.arrowOffset = CGFloat(sender.value)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func edgePaddingChanged(_ sender: UISlider) {
        interactiveBubble.arrowEdgePadding = CGFloat(sender.value)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func tipRadiusChanged(_ sender: UISlider) {
        interactiveBubble.arrowTipRadius = CGFloat(sender.value)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func borderWidthChanged(_ sender: UISlider) {
        interactiveBubble.borderWidth = CGFloat(sender.value)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func borderColorButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        borderColorButtons[selectedBorderColorIndex].layer.borderWidth = 0
        sender.layer.borderWidth = 2
        sender.layer.borderColor = UIColor.gray.cgColor
        selectedBorderColorIndex = index

        let colors: [UIColor] = [.clear, .red, .green, .blue, .black, .orange]
        interactiveBubble.borderColor = colors[index]
        updateStatusLabel()
    }

    @objc private func gradientChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            interactiveBubble.gradientColors = []
        case 1:
            interactiveBubble.gradientColors = [.systemBlue, .systemPurple]
        case 2:
            interactiveBubble.gradientColors = [.systemRed, .systemYellow]
        case 3:
            interactiveBubble.gradientColors = [.systemGreen, .systemTeal]
        default:
            break
        }
        updateStatusLabel()
    }

    @objc private func gradientDirectionChanged(_ sender: UISegmentedControl) {
        let directions: [WYGradientDirection] = [.leftToRight, .topToBottom, .leftToLowRight, .rightToLowLeft]
        interactiveBubble.gradientDirection = directions[sender.selectedSegmentIndex]
        updateStatusLabel()
    }

    @objc private func shadowEnableToggled(_ sender: UISwitch) {
        if sender.isOn {
            let colors: [UIColor] = [.black, .gray, .red, .blue]
            interactiveBubble.shadowColor = colors[selectedShadowColorIndex]
        } else {
            interactiveBubble.shadowColor = nil
        }
        updateStatusLabel()
    }

    @objc private func shadowColorButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        shadowColorButtons[selectedShadowColorIndex].layer.borderWidth = 0
        sender.layer.borderWidth = 2
        sender.layer.borderColor = UIColor.gray.cgColor
        selectedShadowColorIndex = index

        if shadowEnableSwitch.isOn {
            let colors: [UIColor] = [.black, .gray, .red, .blue]
            interactiveBubble.shadowColor = colors[index]
        }
        updateStatusLabel()
    }

    @objc private func shadowOffsetXChanged(_ sender: UISlider) {
        let x = CGFloat(sender.value)
        let y = interactiveBubble.shadowOffset.height
        interactiveBubble.shadowOffset = CGSize(width: x, height: y)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func shadowOffsetYChanged(_ sender: UISlider) {
        let x = interactiveBubble.shadowOffset.width
        let y = CGFloat(sender.value)
        interactiveBubble.shadowOffset = CGSize(width: x, height: y)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func shadowRadiusChanged(_ sender: UISlider) {
        interactiveBubble.shadowRadius = CGFloat(sender.value)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func shadowOpacityChanged(_ sender: UISlider) {
        interactiveBubble.shadowOpacity = CGFloat(sender.value)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func widthChanged(_ sender: UISlider) {
        let newWidth = CGFloat(sender.value)
        if isAtInitial {
            initialState.width = newWidth
            applyState(initialState, animated: false, duration: 0)
        } else {
            finalState.width = newWidth
            applyState(finalState, animated: false, duration: 0)
        }
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func heightChanged(_ sender: UISlider) {
        let newHeight = CGFloat(sender.value)
        if isAtInitial {
            initialState.height = newHeight
            applyState(initialState, animated: false, duration: 0)
        } else {
            finalState.height = newHeight
            applyState(finalState, animated: false, duration: 0)
        }
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func colorButtonTapped() {
        let colors: [UIColor] = [.systemBlue, .systemRed, .systemGreen, .systemOrange, .systemPink, .systemTeal, .systemPurple, .systemIndigo]
        interactiveBubble.fillColor = colors.randomElement() ?? .systemBlue
        updateStatusLabel()
    }

    // MARK: - 重置所有

    @objc private func resetAllTapped() {
        interactiveBubble.layer.removeAllAnimations()
        view.layer.removeAllAnimations()

        // 重置所有原有控件
        directionSegmented.selectedSegmentIndex = 1
        interactiveBubble.arrowDirection = .bottom

        showArrowSwitch.isOn = true
        interactiveBubble.showsArrow = true

        radiusSlider.value = 12
        interactiveBubble.cornerRadius = 12
        updateLabel(for: radiusSlider)

        cornersSegmented.selectedSegmentIndex = 0
        interactiveBubble.cornersPosition = .allCorners

        arrowWidthSlider.value = 12
        arrowHeightSlider.value = 8
        interactiveBubble.arrowSize = CGSize(width: 12, height: 8)
        updateLabel(for: arrowWidthSlider)
        updateLabel(for: arrowHeightSlider)

        offsetSlider.value = 0
        interactiveBubble.arrowOffset = 0
        updateLabel(for: offsetSlider)

        edgePaddingSlider.value = 0
        interactiveBubble.arrowEdgePadding = 0
        updateLabel(for: edgePaddingSlider)

        tipRadiusSlider.value = 0
        interactiveBubble.arrowTipRadius = 0
        updateLabel(for: tipRadiusSlider)

        borderWidthSlider.value = 0
        interactiveBubble.borderWidth = 0
        updateLabel(for: borderWidthSlider)

        borderColorButtons[selectedBorderColorIndex].layer.borderWidth = 0
        borderColorButtons[0].layer.borderWidth = 2
        borderColorButtons[0].layer.borderColor = UIColor.gray.cgColor
        selectedBorderColorIndex = 0
        interactiveBubble.borderColor = .clear

        gradientSegmented.selectedSegmentIndex = 0
        interactiveBubble.gradientColors = []

        gradientDirectionSegmented.selectedSegmentIndex = 0
        interactiveBubble.gradientDirection = .leftToRight

        shadowEnableSwitch.isOn = false
        interactiveBubble.shadowColor = nil

        shadowColorButtons[selectedShadowColorIndex].layer.borderWidth = 0
        shadowColorButtons[0].layer.borderWidth = 2
        shadowColorButtons[0].layer.borderColor = UIColor.gray.cgColor
        selectedShadowColorIndex = 0

        shadowOffsetXSlider.value = 0
        shadowOffsetYSlider.value = 0
        interactiveBubble.shadowOffset = .zero
        updateLabel(for: shadowOffsetXSlider)
        updateLabel(for: shadowOffsetYSlider)

        shadowRadiusSlider.value = 0
        interactiveBubble.shadowRadius = 0
        updateLabel(for: shadowRadiusSlider)

        shadowOpacitySlider.value = 0.5
        interactiveBubble.shadowOpacity = 0.5
        updateLabel(for: shadowOpacitySlider)

        // 重置动画状态
        initialState = (0, 0, 160, 100)
        finalState = (80, 0, 200, 100)
        isAtInitial = true
        hasAppliedInitialState = false  // 重置标志，以便在下次布局时重新应用（但后续会立即应用）

        // 同步滑块
        initialXSlider.value = 0
        initialYSlider.value = 0
        initialWidthSlider.value = 160
        initialHeightSlider.value = 100
        finalXSlider.value = 80
        finalYSlider.value = 0
        finalWidthSlider.value = 200
        finalHeightSlider.value = 100
        animationDurationSlider.value = 1.0
        for slider in [initialXSlider, initialYSlider, initialWidthSlider, initialHeightSlider,
                       finalXSlider, finalYSlider, finalWidthSlider, finalHeightSlider,
                       animationDurationSlider] {
            updateLabel(for: slider!)
        }

        // 应用初始状态（无动画）
        applyState(initialState, animated: false, duration: 0)
        hasAppliedInitialState = true

        // 填充颜色
        interactiveBubble.fillColor = .systemTeal

        view.layoutIfNeeded()
        updateStatusLabel()
    }

    // MARK: - 状态更新

    private func updateStatusLabel() {
        let dirNames = ["上", "下", "左", "右"]
        let dir = dirNames[directionSegmented.selectedSegmentIndex]
        let cornerNames = ["全部", "左上+右下", "右上+左下", "仅左上", "仅右下"]
        let corner = cornerNames[cornersSegmented.selectedSegmentIndex]

        let size = interactiveBubble.arrowSize
        let offset = interactiveBubble.arrowOffset
        let tipR = interactiveBubble.arrowTipRadius
        let borderW = interactiveBubble.borderWidth
        let w = Int(bubbleWidthConstraint.constant)
        let h = Int(bubbleHeightConstraint.constant)
        let edgePad = interactiveBubble.arrowEdgePadding

        let borderColorName: String
        let borderColor = interactiveBubble.borderColor
        if borderColor == .clear {
            borderColorName = "清除"
        } else if borderColor == .red {
            borderColorName = "红"
        } else if borderColor == .green {
            borderColorName = "绿"
        } else if borderColor == .blue {
            borderColorName = "蓝"
        } else if borderColor == .black {
            borderColorName = "黑"
        } else if borderColor == .orange {
            borderColorName = "橙"
        } else {
            borderColorName = "自定义"
        }

        let gradientDesc: String
        switch gradientSegmented.selectedSegmentIndex {
        case 0: gradientDesc = "无"
        case 1: gradientDesc = "蓝→紫"
        case 2: gradientDesc = "红→黄"
        case 3: gradientDesc = "绿→青"
        default: gradientDesc = "无"
        }

        let gradientDirDesc = ["左→右", "上→下", "左上→右下", "右上→左下"][gradientDirectionSegmented.selectedSegmentIndex]

        let shadowEnabled = shadowEnableSwitch.isOn
        let shadowColorName: String
        if let color = interactiveBubble.shadowColor {
            if color == .black { shadowColorName = "黑" }
            else if color == .gray { shadowColorName = "灰" }
            else if color == .red { shadowColorName = "红" }
            else if color == .blue { shadowColorName = "蓝" }
            else { shadowColorName = "自定义" }
        } else {
            shadowColorName = "关闭"
        }
        let offsetX = Int(interactiveBubble.shadowOffset.width)
        let offsetY = Int(interactiveBubble.shadowOffset.height)
        let radius = Int(interactiveBubble.shadowRadius)
        let opacity = String(format: "%.1f", interactiveBubble.shadowOpacity)

        let currentState = isAtInitial ? "初始" : "最终"
        let tx = bubbleCenterXConstraint.constant
        let ty = bubbleTopConstraint.constant
        let duration = animationDurationSlider.value

        bubbleStatusLabel.text = """
        方向: \(dir) | 箭头: \(showArrowSwitch.isOn ? "显示" : "隐藏")
        圆角: \(corner) 半径\(Int(interactiveBubble.cornerRadius))
        箭头尺寸: \(Int(size.width))x\(Int(size.height)) | 偏移: \(Int(offset)) | 边距: \(Int(edgePad))
        尖端圆角: \(Int(tipR)) | 边框: \(Int(borderW))pt (\(borderColorName))
        气泡尺寸: \(w)x\(h) | 位置偏移(tx,ty): (\(Int(tx)),\(Int(ty)))
        渐变: \(gradientDesc) (\(gradientDirDesc)) | 阴影: \(shadowEnabled ? "开启" : "关闭") 颜色\(shadowColorName) 偏移(\(offsetX),\(offsetY)) 半径\(radius) 模糊\(opacity)
        状态: \(currentState) | 动画时长: \(String(format: "%.1f", duration))s
        """
    }
}

// MARK: - 辅助扩展

extension UIView {
    func viewWithAccessibilityIdentifier(_ identifier: String) -> UIView? {
        if self.accessibilityIdentifier == identifier { return self }
        return subviews.compactMap { $0.viewWithAccessibilityIdentifier(identifier) }.first
    }
}

extension UIColor {
    var accessibilityName: String? {
        if self == .systemBlue { return "蓝色" }
        if self == .systemRed { return "红色" }
        if self == .systemGreen { return "绿色" }
        if self == .systemOrange { return "橙色" }
        if self == .systemPink { return "粉色" }
        if self == .systemTeal { return "青色" }
        if self == .systemPurple { return "紫色" }
        if self == .systemBrown { return "棕色" }
        if self == .systemIndigo { return "靛蓝" }
        if self == .black { return "黑色" }
        if self == .clear { return "透明" }
        return nil
    }
}
