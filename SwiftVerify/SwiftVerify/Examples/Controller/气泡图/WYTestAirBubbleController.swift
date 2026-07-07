//
//  WYTestAirBubbleController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/7/2.
//

import UIKit

class WYTestAirBubbleController: UIViewController {

    // MARK: - 交互气泡
    private var interactiveBubble: WYAirBubbleView!
    private var bubbleDescriptionLabel: UILabel!
    private var bubbleWidthConstraint: NSLayoutConstraint!
    private var bubbleHeightConstraint: NSLayoutConstraint!

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

    // 边框颜色选择按钮组
    private var borderColorButtons: [UIButton] = []
    private var selectedBorderColorIndex = 0

    // 存储滑块与其数值标签的映射
    private var valueLabelMap: [UISlider: UILabel] = [:]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupScrollView()
        setupStaticExamples()
        setupInteractiveBubble()
        setupControls()
    }

    // MARK: - 滚动容器

    private var scrollView: UIScrollView!
    private var contentView: UIView!

    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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

    // MARK: - 静态示例（使用 StackView 管理，避免重叠）

    private func setupStaticExamples() {
        typealias BubbleConfig = (WYAirBubbleView) -> Void
        typealias DescBuilder = (WYAirBubbleView) -> String

        // 生成单个示例的水平 StackView（气泡 + 描述）
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

        // 辅助函数：生成描述文本（不再重复尖端圆角等默认项）
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
            // 1. 默认底部箭头，蓝色
            ({ $0.fillColor = .systemBlue },
             { bubble in desc(for: bubble, direction: .bottom, cornerDesc: "全部") }),

            // 2. 顶部箭头，红色填充，黑色边框
            ({
                $0.arrowDirection = .top
                $0.fillColor = .systemRed
                $0.borderColor = .black
                $0.borderWidth = 2
             },
             { bubble in desc(for: bubble, direction: .top, cornerDesc: "全部", extra: "边框颜色: 黑色") }),

            // 3. 左侧箭头，绿色填充
            ({
                $0.arrowDirection = .left
                $0.fillColor = .systemGreen
             },
             { bubble in desc(for: bubble, direction: .left, cornerDesc: "全部") }),

            // 4. 右侧箭头，紫色填充，无圆角，箭头尖圆角（6）
            ({
                $0.arrowDirection = .right
                $0.fillColor = .systemPurple
                $0.cornerRadius = 0
                $0.arrowTipRadius = 6
             },
             { bubble in desc(for: bubble, direction: .right, cornerDesc: "无", extra: "") }), // 尖端圆角已在默认描述中

            // 5. 底部箭头，橙色，偏移+30，箭头放大
            ({
                $0.arrowDirection = .bottom
                $0.fillColor = .systemOrange
                $0.arrowOffset = 30
                $0.arrowSize = CGSize(width: 20, height: 12)
             },
             { bubble in desc(for: bubble, direction: .bottom, cornerDesc: "全部", extra: "偏移: +30, 箭头: 20x12") }),

            // 6. 无箭头，粉色，仅左上/右下圆角
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

            // 7. 新增：底部箭头，棕色，边框蓝色，边距15，展示 arrowEdgePadding
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

        // 垂直 StackView 管理所有示例
        let verticalStack = UIStackView()
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        verticalStack.axis = .vertical
        verticalStack.spacing = 20
        verticalStack.alignment = .fill
        contentView.addSubview(verticalStack)

        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            verticalStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            verticalStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        for (config, descBuilder) in examples {
            let stack = makeExampleStack(with: config, descBuilder: descBuilder)
            verticalStack.addArrangedSubview(stack)
        }

        if let last = verticalStack.arrangedSubviews.last {
            last.accessibilityIdentifier = "lastStaticExample"
        }
    }

    // MARK: - 交互气泡（动态调整属性）

    private func setupInteractiveBubble() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        let lastStatic = contentView.viewWithAccessibilityIdentifier("lastStaticExample")

        interactiveBubble = WYAirBubbleView()
        interactiveBubble.translatesAutoresizingMaskIntoConstraints = false
        interactiveBubble.fillColor = .systemTeal
        interactiveBubble.arrowDirection = .bottom
        interactiveBubble.showsArrow = true
        container.addSubview(interactiveBubble)

        bubbleWidthConstraint = interactiveBubble.widthAnchor.constraint(equalToConstant: 200)
        bubbleHeightConstraint = interactiveBubble.heightAnchor.constraint(equalToConstant: 120)
        bubbleWidthConstraint.isActive = true
        bubbleHeightConstraint.isActive = true

        bubbleDescriptionLabel = UILabel()
        bubbleDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleDescriptionLabel.text = "⬇️ 下方操作区域可动态调整此气泡 ⬇️"
        bubbleDescriptionLabel.font = .systemFont(ofSize: 13, weight: .medium)
        bubbleDescriptionLabel.textColor = .systemBlue
        bubbleDescriptionLabel.textAlignment = .center
        bubbleDescriptionLabel.numberOfLines = 0
        container.addSubview(bubbleDescriptionLabel)

        let statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "拖动下方滑块查看实时变化"
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textColor = .gray
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.tag = 999
        container.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            interactiveBubble.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            interactiveBubble.topAnchor.constraint(equalTo: container.topAnchor),

            bubbleDescriptionLabel.topAnchor.constraint(equalTo: interactiveBubble.bottomAnchor, constant: 8),
            bubbleDescriptionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            bubbleDescriptionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),

            statusLabel.topAnchor.constraint(equalTo: bubbleDescriptionLabel.bottomAnchor, constant: 2),
            statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            statusLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        if let last = lastStatic {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: last.bottomAnchor, constant: 30),
                container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
                container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
        }
    }

    // MARK: - 控制控件（全部水平布局：描述左侧，控件右侧）

    private func setupControls() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: interactiveBubble.superview!.bottomAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        // 辅助：创建水平控件行（描述固定宽度，控件填充剩余）
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

        // 1. 箭头方向
        directionSegmented = UISegmentedControl(items: ["上", "下", "左", "右"])
        directionSegmented.selectedSegmentIndex = 1
        directionSegmented.addTarget(self, action: #selector(directionChanged), for: .valueChanged)
        stack.addArrangedSubview(makeControlRow(label: "箭头方向", control: directionSegmented))

        // 2. 显示箭头
        showArrowSwitch = UISwitch()
        showArrowSwitch.isOn = true
        showArrowSwitch.addTarget(self, action: #selector(showArrowToggled), for: .valueChanged)
        stack.addArrangedSubview(makeControlRow(label: "显示箭头", control: showArrowSwitch))

        // 3. 圆角半径
        let radiusRow = makeSliderRow(label: "圆角半径", min: 0, max: 30, value: 12, action: #selector(radiusChanged))
        radiusSlider = radiusRow.slider
        stack.addArrangedSubview(radiusRow.view)

        // 4. 圆角位置
        cornersSegmented = UISegmentedControl(items: ["全部", "左上+右下", "右上+左下", "仅左上", "仅右下"])
        cornersSegmented.selectedSegmentIndex = 0
        cornersSegmented.addTarget(self, action: #selector(cornersChanged), for: .valueChanged)
        stack.addArrangedSubview(makeControlRow(label: "圆角位置", control: cornersSegmented))

        // 5. 箭头宽度
        let widthRow = makeSliderRow(label: "箭头宽度", min: 6, max: 30, value: 12, action: #selector(arrowWidthChanged))
        arrowWidthSlider = widthRow.slider
        stack.addArrangedSubview(widthRow.view)

        // 6. 箭头高度
        let heightRow = makeSliderRow(label: "箭头高度", min: 4, max: 20, value: 8, action: #selector(arrowHeightChanged))
        arrowHeightSlider = heightRow.slider
        stack.addArrangedSubview(heightRow.view)

        // 7. 箭头偏移
        let offsetRow = makeSliderRow(label: "箭头偏移", min: -100, max: 100, value: 0, action: #selector(offsetChanged))
        offsetSlider = offsetRow.slider
        stack.addArrangedSubview(offsetRow.view)

        // 8. 箭头边距
        let edgeRow = makeSliderRow(label: "箭头边距", min: 0, max: 30, value: 0, action: #selector(edgePaddingChanged))
        edgePaddingSlider = edgeRow.slider
        stack.addArrangedSubview(edgeRow.view)

        // 9. 尖端圆角
        let tipRow = makeSliderRow(label: "尖端圆角", min: 0, max: 30, value: 0, action: #selector(tipRadiusChanged))
        tipRadiusSlider = tipRow.slider
        stack.addArrangedSubview(tipRow.view)

        // 10. 边框宽度
        let borderRow = makeSliderRow(label: "边框宽度", min: 0, max: 5, value: 0, action: #selector(borderWidthChanged))
        borderWidthSlider = borderRow.slider
        stack.addArrangedSubview(borderRow.view)

        // 11. 边框颜色（使用颜色按钮组）
        let borderColorStack = UIStackView()
        borderColorStack.axis = .horizontal
        borderColorStack.spacing = 6
        borderColorStack.alignment = .center

        let borderColorLabel = UILabel()
        borderColorLabel.text = "边框颜色"
        borderColorLabel.font = .systemFont(ofSize: 14, weight: .medium)
        borderColorLabel.setContentHuggingPriority(.required, for: .horizontal)
        borderColorLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        borderColorStack.addArrangedSubview(borderColorLabel)

        let colors: [(UIColor, String)] = [
            (.clear, "清除"),
            (.red, "红"),
            (.green, "绿"),
            (.blue, "蓝"),
            (.black, "黑"),
            (.orange, "橙")
        ]

        for (color, title) in colors {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12)
            btn.backgroundColor = color == .clear ? .lightGray : color
            btn.setTitleColor(color == .clear ? .darkGray : .white, for: .normal)
            btn.layer.cornerRadius = 4
            btn.clipsToBounds = true
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
            btn.tag = borderColorButtons.count
            btn.addTarget(self, action: #selector(borderColorButtonTapped(_:)), for: .touchUpInside)
            borderColorButtons.append(btn)
            borderColorStack.addArrangedSubview(btn)
        }

        // 默认选中“清除”
        borderColorButtons[0].layer.borderWidth = 2
        borderColorButtons[0].layer.borderColor = UIColor.gray.cgColor
        selectedBorderColorIndex = 0

        stack.addArrangedSubview(borderColorStack)

        // 12. 气泡宽度
        let widthSizeRow = makeSliderRow(label: "气泡宽度", min: 100, max: 300, value: 200, action: #selector(widthChanged))
        widthSlider = widthSizeRow.slider
        stack.addArrangedSubview(widthSizeRow.view)

        // 13. 气泡高度
        let heightSizeRow = makeSliderRow(label: "气泡高度", min: 60, max: 200, value: 120, action: #selector(heightChanged))
        heightSlider = heightSizeRow.slider
        stack.addArrangedSubview(heightSizeRow.view)

        // 14. 填充颜色切换按钮
        let colorButton = UIButton(type: .system)
        colorButton.setTitle("随机填充颜色", for: .normal)
        colorButton.addTarget(self, action: #selector(colorButtonTapped), for: .touchUpInside)
        stack.addArrangedSubview(makeControlRow(label: "填充颜色", control: colorButton))

        // 15. 重置按钮
        let resetButton = UIButton(type: .system)
        resetButton.setTitle("重置所有属性", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        resetButton.backgroundColor = .systemGray5
        resetButton.layer.cornerRadius = 8
        resetButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        stack.addArrangedSubview(resetButton)
    }

    // MARK: - 辅助：滑块行（含数值标签）

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
        valueLabel.text = "\(Int(value))"
        valueLabel.font = .systemFont(ofSize: 12)
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        stack.addArrangedSubview(valueLabel)

        valueLabelMap[slider] = valueLabel

        return (stack, slider)
    }

    private func updateLabel(for slider: UISlider) {
        guard let label = valueLabelMap[slider] else { return }
        label.text = "\(Int(slider.value))"
    }

    // MARK: - 控件响应

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
        // 取消之前选中样式
        if selectedBorderColorIndex < borderColorButtons.count {
            borderColorButtons[selectedBorderColorIndex].layer.borderWidth = 0
        }
        // 选中新按钮
        sender.layer.borderWidth = 2
        sender.layer.borderColor = UIColor.gray.cgColor
        selectedBorderColorIndex = index

        let colors: [UIColor] = [.clear, .red, .green, .blue, .black, .orange]
        interactiveBubble.borderColor = colors[index]
        updateStatusLabel()
    }

    @objc private func widthChanged(_ sender: UISlider) {
        bubbleWidthConstraint.constant = CGFloat(sender.value)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func heightChanged(_ sender: UISlider) {
        bubbleHeightConstraint.constant = CGFloat(sender.value)
        updateLabel(for: sender)
        updateStatusLabel()
    }

    @objc private func colorButtonTapped() {
        let colors: [UIColor] = [.systemBlue, .systemRed, .systemGreen, .systemOrange, .systemPink, .systemTeal, .systemPurple, .systemIndigo]
        interactiveBubble.fillColor = colors.randomElement() ?? .systemBlue
        updateStatusLabel()
    }

    @objc private func resetButtonTapped() {
        // 重置所有控件到默认值
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

        // 重置边框颜色为清除
        if selectedBorderColorIndex < borderColorButtons.count {
            borderColorButtons[selectedBorderColorIndex].layer.borderWidth = 0
        }
        borderColorButtons[0].layer.borderWidth = 2
        borderColorButtons[0].layer.borderColor = UIColor.gray.cgColor
        selectedBorderColorIndex = 0
        interactiveBubble.borderColor = .clear

        widthSlider.value = 200
        heightSlider.value = 120
        bubbleWidthConstraint.constant = 200
        bubbleHeightConstraint.constant = 120
        updateLabel(for: widthSlider)
        updateLabel(for: heightSlider)

        interactiveBubble.fillColor = .systemTeal

        updateStatusLabel()
    }

    // MARK: - 状态更新（显示所有当前属性）

    private func updateStatusLabel() {
        guard let container = interactiveBubble.superview,
              let statusLabel = container.viewWithTag(999) as? UILabel else { return }

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

        statusLabel.text = """
        方向: \(dir) | 箭头: \(showArrowSwitch.isOn ? "显示" : "隐藏")
        圆角: \(corner) 半径\(Int(interactiveBubble.cornerRadius))
        箭头尺寸: \(Int(size.width))x\(Int(size.height)) | 偏移: \(Int(offset)) | 边距: \(Int(edgePad))
        尖端圆角: \(Int(tipR)) | 边框: \(Int(borderW))pt (\(borderColorName))
        气泡尺寸: \(w)x\(h)
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
