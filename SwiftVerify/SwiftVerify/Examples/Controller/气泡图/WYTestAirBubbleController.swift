//
//  WYTestAirBubbleController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/7/2.
//

import UIKit

class WYTestAirBubbleController: UIViewController {

    // 交互用气泡（用于动态调整）
    private var interactiveBubble: WYAirBubbleView!
    private var directionSegmented: UISegmentedControl!
    private var showArrowSwitch: UISwitch!
    private var radiusSlider: UISlider!
    private var arrowWidthSlider: UISlider!
    private var arrowHeightSlider: UISlider!
    private var offsetSlider: UISlider!
    private var tipRadiusSlider: UISlider!
    // 新增：边框宽度滑块
    private var borderWidthSlider: UISlider!

    // 存储滑块与其数值标签的映射
    private var valueLabelMap: [UISlider: UILabel] = [:]

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

    // MARK: - 静态示例（展示不同属性组合）

    private func setupStaticExamples() {
        // 辅助方法：创建带标签的气泡
        func makeBubble(with config: (WYAirBubbleView) -> Void, labelText: String) -> UIView {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false

            let bubble = WYAirBubbleView()
            bubble.translatesAutoresizingMaskIntoConstraints = false
            config(bubble)
            container.addSubview(bubble)

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = labelText
            label.font = .systemFont(ofSize: 12)
            label.textColor = .darkGray
            label.numberOfLines = 0
            container.addSubview(label)

            NSLayoutConstraint.activate([
                bubble.topAnchor.constraint(equalTo: container.topAnchor),
                bubble.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                bubble.widthAnchor.constraint(equalToConstant: 160),
                bubble.heightAnchor.constraint(equalToConstant: 100),

                label.topAnchor.constraint(equalTo: bubble.bottomAnchor, constant: 8),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            return container
        }

        // 示例1：默认底部箭头，蓝色
        let ex1 = makeBubble(
            with: { $0.fillColor = .systemBlue },
            labelText: "默认底部箭头\n蓝色填充"
        )

        // 示例2：顶部箭头，红色填充，黑色边框，边框宽2
        let ex2 = makeBubble(
            with: {
                $0.arrowDirection = .top
                $0.fillColor = .systemRed
                $0.borderColor = .black
                $0.borderWidth = 2
            },
            labelText: "顶部箭头\n红色填充 + 黑边框"
        )

        // 示例3：左侧箭头，绿色填充，箭头颜色为黄色
        let ex3 = makeBubble(
            with: {
                $0.arrowDirection = .left
                $0.fillColor = .systemGreen
                $0.arrowColor = .yellow
            },
            labelText: "左侧箭头\n绿色填充，黄色箭头"
        )

        // 示例4：右侧箭头，紫色填充，无圆角（矩形），箭头尖角半径 6
        let ex4 = makeBubble(
            with: {
                $0.arrowDirection = .right
                $0.fillColor = .systemPurple
                $0.cornerRadius = 0
                $0.arrowTipRadius = 6
            },
            labelText: "右侧箭头\n无圆角，箭头尖圆角"
        )

        // 示例5：底部箭头，橙色，箭头偏移 +30，箭头尺寸放大
        let ex5 = makeBubble(
            with: {
                $0.arrowDirection = .bottom
                $0.fillColor = .systemOrange
                $0.arrowOffset = 30
                $0.arrowSize = CGSize(width: 20, height: 12)
            },
            labelText: "底部箭头\n偏移 +30，箭头更大"
        )

        // 示例6：无箭头，粉色填充，只保留左上和右下圆角
        let ex6 = makeBubble(
            with: {
                $0.showsArrow = false
                $0.fillColor = .systemPink
                $0.cornersPosition = [.topLeft, .bottomRight]
                $0.cornerRadius = 20
            },
            labelText: "无箭头\n仅左上/右下圆角"
        )

        // 将所有示例添加到 contentView，垂直排列
        let examples = [ex1, ex2, ex3, ex4, ex5, ex6]
        var previous: UIView?
        for view in examples {
            contentView.addSubview(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
            if let prev = previous {
                view.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 20).isActive = true
            } else {
                view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
            }
            previous = view
        }
        // 记录最后一个静态示例的底部，供后续布局使用
        if let last = previous {
            last.accessibilityIdentifier = "lastStaticExample"
        }
    }

    // MARK: - 交互气泡（动态调整属性）

    private func setupInteractiveBubble() {
        interactiveBubble = WYAirBubbleView()
        interactiveBubble.translatesAutoresizingMaskIntoConstraints = false
        interactiveBubble.fillColor = .systemTeal
        interactiveBubble.arrowDirection = .bottom
        interactiveBubble.showsArrow = true
        contentView.addSubview(interactiveBubble)

        // 找到最后一个静态示例
        guard let lastStatic = contentView.viewWithAccessibilityIdentifier("lastStaticExample") else {
            // 若未找到，则直接相对于 contentView 顶部
            NSLayoutConstraint.activate([
                interactiveBubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
                interactiveBubble.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                interactiveBubble.widthAnchor.constraint(equalToConstant: 200),
                interactiveBubble.heightAnchor.constraint(equalToConstant: 120)
            ])
            return
        }

        NSLayoutConstraint.activate([
            interactiveBubble.topAnchor.constraint(equalTo: lastStatic.bottomAnchor, constant: 30),
            interactiveBubble.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            interactiveBubble.widthAnchor.constraint(equalToConstant: 200),
            interactiveBubble.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    // MARK: - 控制控件（方向、显示、滑块）

    private func setupControls() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .fill
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: interactiveBubble.bottomAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20) // 撑开 contentView
        ])

        // 1. 方向分段
        let dirLabel = UILabel()
        dirLabel.text = "箭头方向："
        dirLabel.font = .systemFont(ofSize: 14)
        stack.addArrangedSubview(dirLabel)

        directionSegmented = UISegmentedControl(items: ["上", "下", "左", "右"])
        directionSegmented.selectedSegmentIndex = 1
        directionSegmented.addTarget(self, action: #selector(directionChanged), for: .valueChanged)
        stack.addArrangedSubview(directionSegmented)

        // 2. 显示箭头开关
        let showRow = UIStackView()
        showRow.axis = .horizontal
        showRow.spacing = 10
        let showLabel = UILabel()
        showLabel.text = "显示箭头"
        showLabel.font = .systemFont(ofSize: 14)
        showArrowSwitch = UISwitch()
        showArrowSwitch.isOn = true
        showArrowSwitch.addTarget(self, action: #selector(showArrowToggled), for: .valueChanged)
        showRow.addArrangedSubview(showLabel)
        showRow.addArrangedSubview(showArrowSwitch)
        showRow.addArrangedSubview(UIView()) // 撑开
        stack.addArrangedSubview(showRow)

        // 3. 圆角半径滑块
        let radiusRow = makeSliderRow(label: "圆角半径", min: 0, max: 30, value: 12, action: #selector(radiusChanged))
        radiusSlider = radiusRow.slider
        stack.addArrangedSubview(radiusRow.view)

        // 4. 箭头宽度滑块
        let widthRow = makeSliderRow(label: "箭头宽度", min: 6, max: 30, value: 12, action: #selector(arrowWidthChanged))
        arrowWidthSlider = widthRow.slider
        stack.addArrangedSubview(widthRow.view)

        // 5. 箭头高度滑块
        let heightRow = makeSliderRow(label: "箭头高度", min: 4, max: 20, value: 8, action: #selector(arrowHeightChanged))
        arrowHeightSlider = heightRow.slider
        stack.addArrangedSubview(heightRow.view)

        // 6. 箭头偏移滑块
        let offsetRow = makeSliderRow(label: "偏移量", min: -50, max: 50, value: 0, action: #selector(offsetChanged))
        offsetSlider = offsetRow.slider
        stack.addArrangedSubview(offsetRow.view)

        // 7. 箭头尖端圆角滑块
        let tipRow = makeSliderRow(label: "尖端圆角", min: 0, max: 12, value: 0, action: #selector(tipRadiusChanged))
        tipRadiusSlider = tipRow.slider
        stack.addArrangedSubview(tipRow.view)

        // ---- 新增：边框相关控件 ----
        // 8. 边框宽度滑块
        let borderWidthRow = makeSliderRow(label: "边框宽度", min: 0, max: 5, value: 0, action: #selector(borderWidthChanged))
        borderWidthSlider = borderWidthRow.slider
        stack.addArrangedSubview(borderWidthRow.view)

        // 9. 边框颜色切换按钮
        let borderColorButton = UIButton(type: .system)
        borderColorButton.setTitle("切换边框颜色", for: .normal)
        borderColorButton.addTarget(self, action: #selector(borderColorButtonTapped), for: .touchUpInside)
        stack.addArrangedSubview(borderColorButton)

        // ---- 原有颜色按钮 ----
        let colorButton = UIButton(type: .system)
        colorButton.setTitle("切换填充颜色", for: .normal)
        colorButton.addTarget(self, action: #selector(colorButtonTapped), for: .touchUpInside)
        stack.addArrangedSubview(colorButton)

        let arrowColorButton = UIButton(type: .system)
        arrowColorButton.setTitle("切换箭头颜色", for: .normal)
        arrowColorButton.addTarget(self, action: #selector(arrowColorButtonTapped), for: .touchUpInside)
        stack.addArrangedSubview(arrowColorButton)
    }

    // 辅助：创建带标签的滑块行，并记录数值标签
    private func makeSliderRow(label: String, min: Float, max: Float, value: Float, action: Selector) -> (view: UIStackView, slider: UISlider) {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center

        let lbl = UILabel()
        lbl.text = label
        lbl.font = .systemFont(ofSize: 13)
        lbl.setContentHuggingPriority(.required, for: .horizontal)
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
        stack.addArrangedSubview(valueLabel)

        // 存储映射关系
        valueLabelMap[slider] = valueLabel

        return (stack, slider)
    }

    // MARK: - 控件响应

    @objc private func directionChanged(_ sender: UISegmentedControl) {
        let directions: [WYArrowDirection] = [.top, .bottom, .left, .right]
        interactiveBubble.arrowDirection = directions[sender.selectedSegmentIndex]
    }

    @objc private func showArrowToggled(_ sender: UISwitch) {
        interactiveBubble.showsArrow = sender.isOn
    }

    @objc private func radiusChanged(_ sender: UISlider) {
        interactiveBubble.cornerRadius = CGFloat(sender.value)
        updateLabel(for: sender)
    }

    @objc private func arrowWidthChanged(_ sender: UISlider) {
        let w = CGFloat(sender.value)
        let h = interactiveBubble.arrowSize.height
        interactiveBubble.arrowSize = CGSize(width: w, height: h)
        updateLabel(for: sender)
    }

    @objc private func arrowHeightChanged(_ sender: UISlider) {
        let w = interactiveBubble.arrowSize.width
        let h = CGFloat(sender.value)
        interactiveBubble.arrowSize = CGSize(width: w, height: h)
        updateLabel(for: sender)
    }

    @objc private func offsetChanged(_ sender: UISlider) {
        interactiveBubble.arrowOffset = CGFloat(sender.value)
        updateLabel(for: sender)
    }

    @objc private func tipRadiusChanged(_ sender: UISlider) {
        interactiveBubble.arrowTipRadius = CGFloat(sender.value)
        updateLabel(for: sender)
    }

    @objc private func borderWidthChanged(_ sender: UISlider) {
        interactiveBubble.borderWidth = CGFloat(sender.value)
        updateLabel(for: sender)
    }

    // 边框颜色切换（循环）
    private var borderColorIndex = 0
    private let borderColors: [UIColor] = [.clear, .red, .green, .blue, .black, .orange]
    @objc private func borderColorButtonTapped() {
        borderColorIndex = (borderColorIndex + 1) % borderColors.count
        let color = borderColors[borderColorIndex]
        interactiveBubble.borderColor = color
        // 可打印提示，无需UI更新
    }

    private func updateLabel(for slider: UISlider) {
        // 直接从映射中获取对应的数值标签
        guard let label = valueLabelMap[slider] else { return }
        label.text = "\(Int(slider.value))"
    }

    @objc private func colorButtonTapped() {
        let colors: [UIColor] = [.systemBlue, .systemRed, .systemGreen, .systemOrange, .systemPink, .systemTeal]
        interactiveBubble.fillColor = colors.randomElement() ?? .systemBlue
    }

    @objc private func arrowColorButtonTapped() {
        let colors: [UIColor] = [.yellow, .white, .black, .cyan, .magenta, .brown]
        interactiveBubble.arrowColor = colors.randomElement()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

// 辅助扩展，方便通过 accessibilityIdentifier 查找视图
extension UIView {
    func viewWithAccessibilityIdentifier(_ identifier: String) -> UIView? {
        if self.accessibilityIdentifier == identifier { return self }
        return subviews.compactMap { $0.viewWithAccessibilityIdentifier(identifier) }.first
    }
}
