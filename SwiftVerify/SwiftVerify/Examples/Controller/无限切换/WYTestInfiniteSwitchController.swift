//
//  WYTestInfiniteSwitchController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/7/20.
//

import UIKit
import SnapKit

// MARK: - 测试控制器
class WYTestInfiniteSwitchController: UIViewController {

    // MARK: - UI Components
    private let scrollView = WYContentScrollView()
    private let logTextView = UITextView()
    private let controlStack = UIStackView()
    
    // 配置控件
    private let directionSeg = UISegmentedControl(items: ["左右", "上下", "全向"])
    private let hCountSeg = UISegmentedControl(items: ["0", "1", "2", "3", "5", "∞"])
    private let vCountSeg = UISegmentedControl(items: ["0", "1", "2", "3", "5", "∞"])
    private let unlimitedSwitch = UISwitch()
    private let autoSwitch = UISwitch()
    private let standingSlider = UISlider()
    private let hSingleSwitch = UISwitch()
    private let vSingleSwitch = UISwitch()
    private let hMultiSwitch = UISwitch()
    private let vMultiSwitch = UISwitch()
    private let prioritySeg = UISegmentedControl(items: ["优先水平", "优先垂直"])
    
    // 手动操作
    private let nextBtn = UIButton(type: .system)
    private let lastBtn = UIButton(type: .system)
    private let jumpBtn = UIButton(type: .system)
    private let jumpTextField = UITextField()
    
    // 缓存视图
    private var horizontalViews: [UIView] = []
    private var verticalViews: [UIView] = []
    
    // 当前状态
    private var currentDirection: WYContentSlidingDirection = .leftOrRight
    private var horizontalCount: Int = 3
    private var verticalCount: Int = 3
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupControls()
        layoutViews()
        setupScrollView()
        updateScrollViewConfiguration()
    }
    
    // MARK: - Setup Controls
    private func setupControls() {
        // 方向
        directionSeg.addTarget(self, action: #selector(directionChanged), for: .valueChanged)
        directionSeg.selectedSegmentIndex = 0
        
        // 页数（默认选 "3"，即索引3）
        hCountSeg.addTarget(self, action: #selector(countChanged), for: .valueChanged)
        hCountSeg.selectedSegmentIndex = 3  // "3"
        vCountSeg.addTarget(self, action: #selector(countChanged), for: .valueChanged)
        vCountSeg.selectedSegmentIndex = 3  // "3"
        
        // 开关
        unlimitedSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        unlimitedSwitch.isOn = true
        autoSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        autoSwitch.isOn = true
        hSingleSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        hSingleSwitch.isOn = false
        vSingleSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        vSingleSwitch.isOn = false
        hMultiSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        hMultiSwitch.isOn = true
        vMultiSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        vMultiSwitch.isOn = true
        
        // 停留时间
        standingSlider.minimumValue = 1
        standingSlider.maximumValue = 10
        standingSlider.value = 3
        standingSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        
        // 优先级
        prioritySeg.addTarget(self, action: #selector(priorityChanged), for: .valueChanged)
        prioritySeg.selectedSegmentIndex = 0
        
        // 手动操作按钮
        nextBtn.setTitle("下一页", for: .normal)
        nextBtn.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        lastBtn.setTitle("上一页", for: .normal)
        lastBtn.addTarget(self, action: #selector(lastTapped), for: .touchUpInside)
        jumpBtn.setTitle("跳转", for: .normal)
        jumpBtn.addTarget(self, action: #selector(jumpTapped), for: .touchUpInside)
        jumpTextField.borderStyle = .roundedRect
        jumpTextField.placeholder = "索引"
        jumpTextField.keyboardType = .numberPad
        
        // 构建 controlStack
        controlStack.axis = .vertical
        controlStack.spacing = 8
        controlStack.alignment = .fill
        controlStack.distribution = .fill
        
        let rows = [
            createRow(label: "方向", control: directionSeg),
            createRow(label: "水平页数", control: hCountSeg),
            createRow(label: "垂直页数", control: vCountSeg),
            createRow(label: "无限轮播", control: unlimitedSwitch),
            createRow(label: "自动轮播", control: autoSwitch),
            createRow(label: "停留时间", control: standingSlider),
            createRow(label: "水平单页滑动", control: hSingleSwitch),
            createRow(label: "垂直单页滑动", control: vSingleSwitch),
            createRow(label: "水平多页滑动", control: hMultiSwitch),
            createRow(label: "垂直多页滑动", control: vMultiSwitch),
            createRow(label: "全向优先级", control: prioritySeg),
        ]
        rows.forEach { controlStack.addArrangedSubview($0) }
        
        // 动作行
        let actionRow = UIStackView()
        actionRow.axis = .horizontal
        actionRow.spacing = 10
        actionRow.distribution = .fillEqually
        actionRow.addArrangedSubview(nextBtn)
        actionRow.addArrangedSubview(lastBtn)
        actionRow.addArrangedSubview(jumpBtn)
        actionRow.addArrangedSubview(jumpTextField)
        controlStack.addArrangedSubview(actionRow)
    }
    
    private func createRow(label: String, control: UIView) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 14)
        labelView.setContentHuggingPriority(.required, for: .horizontal)
        labelView.setContentCompressionResistancePriority(.required, for: .horizontal)
        stack.addArrangedSubview(labelView)
        stack.addArrangedSubview(control)
        return stack
    }
    
    // MARK: - Layout
    private func layoutViews() {
        // 1. 内容滚动视图
        scrollView.backgroundColor = .lightGray
        scrollView.layer.borderWidth = 1
        scrollView.layer.borderColor = UIColor.blue.cgColor
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(400)
        }
        
        // 2. 日志视图
        logTextView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        logTextView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        logTextView.isEditable = false
        logTextView.text = "日志输出：\n"
        view.addSubview(logTextView)
        logTextView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview().inset(20)
            make.height.equalTo(150)
        }
        
        // 3. 控制面板容器（可滚动）
        let scrollContainer = UIScrollView()
        scrollContainer.showsVerticalScrollIndicator = true
        view.addSubview(scrollContainer)
        scrollContainer.snp.makeConstraints { make in
            make.top.equalTo(scrollView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalTo(logTextView.snp.top).offset(-20)
        }
        
        // 将 controlStack 添加到容器
        scrollContainer.addSubview(controlStack)
        controlStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
    
    // MARK: - ScrollView Configuration
    private func setupScrollView() {
        scrollView.contentDelegate = self
        // 其他属性在 update 中设置
    }
    
    private func updateScrollViewConfiguration() {
        // 读取 UI 配置
        currentDirection = WYContentSlidingDirection(rawValue: directionSeg.selectedSegmentIndex) ?? .leftOrRight
        
        // ✅ 页数映射：索引0->0, 1->1, 2->2, 3->3, 4->5, 5->Int.max
        let hIndex = hCountSeg.selectedSegmentIndex
        horizontalCount = [0, 1, 2, 3, 5, Int.max][hIndex]
        let vIndex = vCountSeg.selectedSegmentIndex
        verticalCount = [0, 1, 2, 3, 5, Int.max][vIndex]
        
        scrollView.contentSlidingDirection = currentDirection
        scrollView.numberOfHorizontalContent = horizontalCount
        scrollView.numberOfVerticalContent = verticalCount
        scrollView.unlimitedCarousel = unlimitedSwitch.isOn
        scrollView.automaticCarousel = autoSwitch.isOn
        scrollView.horizontalSliderForSinglePage = hSingleSwitch.isOn
        scrollView.verticalSliderForSinglePage = vSingleSwitch.isOn
        scrollView.horizontalSliderForMultiPage = hMultiSwitch.isOn
        scrollView.verticalSliderForMultiPage = vMultiSwitch.isOn
        scrollView.standingTime = TimeInterval(standingSlider.value)
        scrollView.prioritySlidingDirection = prioritySeg.selectedSegmentIndex == 0 ? .leftOrRight : .topOrBottom
        
        // 生成内容视图
        generateContentViews()
        
        // 根据方向设置内容
        switch currentDirection {
        case .leftOrRight:
            // 当水平页数为0时，不添加任何视图，直接返回
            guard horizontalCount > 0, horizontalViews.count >= 2 else { return }
            scrollView.horizontalOrVerticalDisplay(currentView: horizontalViews[0], reserveView: horizontalViews[1])
        case .topOrBottom:
            guard verticalCount > 0, verticalViews.count >= 2 else { return }
            scrollView.horizontalOrVerticalDisplay(currentView: verticalViews[0], reserveView: verticalViews[1])
        case .omnidirectional:
            guard horizontalCount > 0, verticalCount > 0,
                  horizontalViews.count >= 2, verticalViews.count >= 2 else { return }
            scrollView.omnidirectionalDisplay(
                currentHorizontalView: horizontalViews[0],
                reserveHorizontalView: horizontalViews[1],
                currentVerticalView: verticalViews[0],
                reserveVerticalView: verticalViews[1]
            )
        }
        
        // 启动或停止定时器
        if scrollView.automaticCarousel {
            scrollView.startTimer()
        } else {
            scrollView.stopTimer()
        }
        
        appendLog("配置已更新：方向=\(currentDirection), 水平页数=\(horizontalCount), 垂直页数=\(verticalCount)")
    }
    
    private func generateContentViews() {
        // 水平视图
        horizontalViews.removeAll()
        let hCount = (horizontalCount == Int.max) ? 5 : horizontalCount // 展示最多5个
        for i in 0..<hCount {
            let view = UIView()
            view.backgroundColor = UIColor(hue: CGFloat(i) / CGFloat(max(1, hCount)), saturation: 0.8, brightness: 0.8, alpha: 1)
            let label = UILabel()
            label.text = "H\(i)"
            label.textColor = .white
            label.font = UIFont.boldSystemFont(ofSize: 30)
            label.textAlignment = .center
            view.addSubview(label)
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
            view.addGestureRecognizer(tap)
            view.isUserInteractionEnabled = true
            horizontalViews.append(view)
        }
        
        // 垂直视图
        verticalViews.removeAll()
        let vCount = (verticalCount == Int.max) ? 5 : verticalCount
        for i in 0..<vCount {
            let view = UIView()
            view.backgroundColor = UIColor(hue: CGFloat(i) / CGFloat(max(1, vCount)), saturation: 0.6, brightness: 0.9, alpha: 1)
            let label = UILabel()
            label.text = "V\(i)"
            label.textColor = .white
            label.font = UIFont.boldSystemFont(ofSize: 30)
            label.textAlignment = .center
            view.addSubview(label)
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
            view.addGestureRecognizer(tap)
            view.isUserInteractionEnabled = true
            verticalViews.append(view)
        }
    }
    
    // MARK: - Actions
    @objc private func directionChanged() {
        updateScrollViewConfiguration()
    }
    
    @objc private func countChanged() {
        updateScrollViewConfiguration()
    }
    
    @objc private func switchChanged() {
        updateScrollViewConfiguration()
    }
    
    @objc private func sliderChanged() {
        scrollView.standingTime = TimeInterval(standingSlider.value)
        if scrollView.automaticCarousel {
            scrollView.startTimer()
        }
        appendLog("停留时间设为: \(Int(standingSlider.value))s")
    }
    
    @objc private func priorityChanged() {
        updateScrollViewConfiguration()
    }
    
    @objc private func nextTapped() {
        scrollView.nextContent(currentDirection)
        appendLog("手动下一页")
    }
    
    @objc private func lastTapped() {
        scrollView.lastContent(currentDirection)
        appendLog("手动上一页")
    }
    
    @objc private func jumpTapped() {
        guard let text = jumpTextField.text, let index = Int(text) else {
            appendLog("请输入有效索引")
            return
        }
        var idx = index
        scrollView.switchContent(currentDirection, index: &idx)
        appendLog("跳转到索引: \(idx)")
        jumpTextField.resignFirstResponder()
    }
    
    @objc private func viewTapped(_ gesture: UITapGestureRecognizer) {
        if let view = gesture.view,
           let label = view.subviews.first(where: { $0 is UILabel }) as? UILabel,
           let text = label.text {
            appendLog("点击了视图: \(text)")
        } else {
            appendLog("点击了某个视图")
        }
    }
    
    // MARK: - Logging
    private func appendLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        let log = "[\(timestamp)] \(message)\n"
        logTextView.text += log
        logTextView.scrollRangeToVisible(NSRange(location: logTextView.text.count - 1, length: 1))
    }
}

// MARK: - WYContentScrollViewDelegate
extension WYTestInfiniteSwitchController: WYContentScrollViewDelegate {
    
    func wy_contentScrollViewDidScroll(_ contentScrollView: WYContentScrollView, offset: CGPoint, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int) {
        let directionStr = String(describing: direction)
        appendLog("DidScroll: offset(\(offset.x), \(offset.y)), dir=\(directionStr), index=\(index)")
    }
    
    func wy_contentScrollViewDidClick(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int) {
        let directionStr = String(describing: direction)
        appendLog("DidClick: dir=\(directionStr), index=\(index)")
    }
    
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView) {
        let directionStr = String(describing: direction)
        appendLog("WillSwitch(非全向): dir=\(directionStr)")
    }
    
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView) {
        let directionStr = String(describing: direction)
        appendLog("DidSwitch(非全向): dir=\(directionStr)")
    }
    
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView, reserveHorizontalView: UIView, currentVerticalView: UIView, reserveVerticalView: UIView) {
        let directionStr = String(describing: direction)
        appendLog("WillSwitch(全向): dir=\(directionStr)")
    }
    
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView, reserveHorizontalView: UIView, currentVerticalView: UIView, reserveVerticalView: UIView) {
        let directionStr = String(describing: direction)
        appendLog("DidSwitch(全向): dir=\(directionStr)")
    }
}
