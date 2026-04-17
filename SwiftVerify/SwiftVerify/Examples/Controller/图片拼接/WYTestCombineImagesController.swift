//
// WYTestCombineImagesController.swift
// SwiftVerify
//
// Created by guanren on 2026/2/11.
//
import UIKit
import SnapKit

@available(iOS 14.0, *)
class WYTestCombineImagesController: UIViewController {
    
    // MARK: - Associated Object Keys
    private static var valueChangedKey: Void?
    private static var valueLabelKey: Void?
    private static var valueFormatKey: Void?
    private static var colorViewKey: Void?
    private static var pickerValueChangedKey: Void?
    private static var pickerColorViewKey: Void?
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let resultImageView = UIImageView()
    
    // 默认图片
    private let standardImage = UIImage.wy_createImage(from: .purple, size: CGSize(width: UIDevice.wy_screenWidth - 40, height: 200))
    private let stitchingImage = UIImage(named: "test_stitching") ?? UIImage(systemName: "star.fill")!
    
    // 参数值
    private var stitchingCenterPoint = CGPoint(x: 150, y: 150)
    private var overlapControl: CGFloat = 0
    private var alpha: CGFloat = 1.0
    private var blendMode: CGBlendMode = .normal
    private var backgroundColor: UIColor = .clear
    private var cornerRadius: CGFloat = 0
    private var rotationAngle: CGFloat = 0
    private var flipHorizontal = false
    private var flipVertical = false
    private var qualityScale: CGFloat? = nil
    private var scale: CGFloat = 1.0
    private var shadowColor: UIColor = .clear
    private var shadowBlur: CGFloat = 0
    private var shadowOffset = CGSize.zero
    private var strokeColor: UIColor = .clear
    private var strokeWidth: CGFloat = 0
    private var maskImage: UIImage? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupParametersUI()
        combineImages()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        title = "图片合成测试"
        view.backgroundColor = .systemGroupedBackground
        
        // 设置导航栏
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "合成",
            style: .done,
            target: self,
            action: #selector(combineImages)
        )
        
        // 结果图片显示（固定在顶部）
        resultImageView.contentMode = .scaleAspectFit
        resultImageView.backgroundColor = .secondarySystemBackground
        resultImageView.layer.borderWidth = 1
        resultImageView.layer.borderColor = UIColor.separator.cgColor
        resultImageView.layer.cornerRadius = 8
        resultImageView.clipsToBounds = true
        view.addSubview(resultImageView)
        resultImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(300)
        }
        
        // ScrollView（参数部分）
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(resultImageView.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        // ContentView
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
    
    // MARK: - 创建参数输入控件
    private func setupParametersUI() {
        var lastView: UIView?
        
        // 1. stitchingCenterPoint
        let pointGroup = createPointControl(
            title: "拼接中心点",
            xValue: stitchingCenterPoint.x,
            yValue: stitchingCenterPoint.y,
            xMin: 0,
            xMax: 300,
            yMin: 0,
            yMax: 300,
            xChanged: { [weak self] value in
                self?.stitchingCenterPoint.x = value
                self?.combineImages()
            },
            yChanged: { [weak self] value in
                self?.stitchingCenterPoint.y = value
                self?.combineImages()
            }
        )
        contentView.addSubview(pointGroup)
        pointGroup.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = pointGroup
        
        // 2. overlapControl
        let overlapSlider = createSliderControl(
            title: "重叠控制",
            value: Float(overlapControl),
            min: -50,
            max: 50,
            valueChanged: { [weak self] value in
                self?.overlapControl = CGFloat(value)
                self?.combineImages()
            }
        )
        contentView.addSubview(overlapSlider)
        overlapSlider.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = overlapSlider
        
        // 3. alpha
        let alphaSlider = createSliderControl(
            title: "透明度",
            value: Float(alpha),
            min: 0,
            max: 1,
            valueChanged: { [weak self] value in
                self?.alpha = CGFloat(value)
                self?.combineImages()
            }
        )
        contentView.addSubview(alphaSlider)
        alphaSlider.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = alphaSlider
        
        // 4. blendMode
        let blendModeControl = createSegmentedControl(
            title: "混合模式",
            items: ["Normal", "Multiply", "Screen", "Overlay", "Darken", "Lighten", "ColorDodge", "ColorBurn"],
            selectedIndex: 0,
            valueChanged: { [weak self] index in
                let modes: [CGBlendMode] = [.normal, .multiply, .screen, .overlay, .darken, .lighten, .colorDodge, .colorBurn]
                self?.blendMode = modes[index]
                self?.combineImages()
            }
        )
        contentView.addSubview(blendModeControl)
        blendModeControl.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = blendModeControl
        
        // 5. backgroundColor
        let colorControl = createColorControl(
            title: "背景颜色",
            color: backgroundColor,
            valueChanged: { [weak self] color in
                self?.backgroundColor = color
                self?.combineImages()
            }
        )
        contentView.addSubview(colorControl)
        colorControl.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        lastView = colorControl
        
        // 6. cornerRadius
        let cornerSlider = createSliderControl(
            title: "圆角半径",
            value: Float(cornerRadius),
            min: 0,
            max: 50,
            valueChanged: { [weak self] value in
                self?.cornerRadius = CGFloat(value)
                self?.combineImages()
            }
        )
        contentView.addSubview(cornerSlider)
        cornerSlider.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = cornerSlider
        
        // 7. rotationAngle
        let rotationSlider = createSliderControl(
            title: "旋转角度",
            value: Float(rotationAngle),
            min: 0,
            max: Float(2 * CGFloat.pi),
            valueFormat: "%.2f rad",
            valueChanged: { [weak self] value in
                self?.rotationAngle = CGFloat(value)
                self?.combineImages()
            }
        )
        contentView.addSubview(rotationSlider)
        rotationSlider.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = rotationSlider
        
        // 8. flipHorizontal & flipVertical
        let flipControl = createSwitchGroupControl(
            title: "翻转控制",
            switches: [
                ("水平翻转", flipHorizontal, { [weak self] isOn in
                    self?.flipHorizontal = isOn
                    self?.combineImages()
                }),
                ("垂直翻转", flipVertical, { [weak self] isOn in
                    self?.flipVertical = isOn
                    self?.combineImages()
                })
            ]
        )
        contentView.addSubview(flipControl)
        flipControl.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = flipControl
        
        // 9. scale
        let scaleSlider = createSliderControl(
            title: "缩放比例",
            value: Float(scale),
            min: 0.1,
            max: 3.0,
            valueChanged: { [weak self] value in
                self?.scale = CGFloat(value)
                self?.combineImages()
            }
        )
        contentView.addSubview(scaleSlider)
        scaleSlider.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = scaleSlider
        
        // 10. shadowColor
        let shadowColorControl = createColorControl(
            title: "阴影颜色",
            color: shadowColor,
            valueChanged: { [weak self] color in
                self?.shadowColor = color
                self?.combineImages()
            }
        )
        contentView.addSubview(shadowColorControl)
        shadowColorControl.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        lastView = shadowColorControl
        
        // 11. shadowBlur
        let shadowBlurSlider = createSliderControl(
            title: "阴影模糊",
            value: Float(shadowBlur),
            min: 0,
            max: 20,
            valueChanged: { [weak self] value in
                self?.shadowBlur = CGFloat(value)
                self?.combineImages()
            }
        )
        contentView.addSubview(shadowBlurSlider)
        shadowBlurSlider.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = shadowBlurSlider
        
        // 12. shadowOffset
        let shadowOffsetGroup = createPointControl(
            title: "阴影偏移",
            xValue: shadowOffset.width,
            yValue: shadowOffset.height,
            xMin: -20,
            xMax: 20,
            yMin: -20,
            yMax: 20,
            xChanged: { [weak self] value in
                self?.shadowOffset.width = value
                self?.combineImages()
            },
            yChanged: { [weak self] value in
                self?.shadowOffset.height = value
                self?.combineImages()
            }
        )
        contentView.addSubview(shadowOffsetGroup)
        shadowOffsetGroup.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = shadowOffsetGroup
        
        // 13. strokeColor
        let strokeColorControl = createColorControl(
            title: "描边颜色",
            color: strokeColor,
            valueChanged: { [weak self] color in
                self?.strokeColor = color
                self?.combineImages()
            }
        )
        contentView.addSubview(strokeColorControl)
        strokeColorControl.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        lastView = strokeColorControl
        
        // 14. strokeWidth
        let strokeWidthSlider = createSliderControl(
            title: "描边宽度",
            value: Float(strokeWidth),
            min: 0,
            max: 10,
            valueChanged: { [weak self] value in
                self?.strokeWidth = CGFloat(value)
                self?.combineImages()
            }
        )
        contentView.addSubview(strokeWidthSlider)
        strokeWidthSlider.snp.makeConstraints { make in
            make.top.equalTo(lastView!.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = strokeWidthSlider
        
        // 设置contentView底部约束
        contentView.snp.makeConstraints { make in
            make.bottom.equalTo(lastView!.snp.bottom).offset(30)
        }
    }
    
    // MARK: - UI Creation Helpers
    
    private func createLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }
    
    private func createValueLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        return label
    }
    
    private func createPointControl(title: String, xValue: CGFloat, yValue: CGFloat,
                                    xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat,
                                    xChanged: @escaping (CGFloat) -> Void,
                                    yChanged: @escaping (CGFloat) -> Void) -> UIView {
        let container = UIView()
        
        let titleLabel = createLabel(title)
        container.addSubview(titleLabel)
        
        let xLabel = createLabel("X:")
        let xValueLabel = createValueLabel(String(format: "%.1f", xValue))
        let xSlider = UISlider()
        xSlider.minimumValue = Float(xMin)
        xSlider.maximumValue = Float(xMax)
        xSlider.value = Float(xValue)
        
        let yLabel = createLabel("Y:")
        let yValueLabel = createValueLabel(String(format: "%.1f", yValue))
        let ySlider = UISlider()
        ySlider.minimumValue = Float(yMin)
        ySlider.maximumValue = Float(yMax)
        ySlider.value = Float(yValue)
        
        // 存储闭包引用
        objc_setAssociatedObject(xSlider, &Self.valueChangedKey, xChanged, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(ySlider, &Self.valueChangedKey, yChanged, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(xSlider, &Self.valueLabelKey, xValueLabel, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(ySlider, &Self.valueLabelKey, yValueLabel, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        xSlider.addTarget(self, action: #selector(pointSliderChanged(_:)), for: .valueChanged)
        ySlider.addTarget(self, action: #selector(pointSliderChanged(_:)), for: .valueChanged)
        
        let xStack = UIStackView(arrangedSubviews: [xLabel, xValueLabel, xSlider])
        xStack.axis = .horizontal
        xStack.spacing = 10
        xStack.alignment = .center
        
        let yStack = UIStackView(arrangedSubviews: [yLabel, yValueLabel, ySlider])
        yStack.axis = .horizontal
        yStack.spacing = 10
        yStack.alignment = .center
        
        let vStack = UIStackView(arrangedSubviews: [titleLabel, xStack, yStack])
        vStack.axis = .vertical
        vStack.spacing = 8
        
        container.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        xSlider.snp.makeConstraints { make in
            make.width.equalTo(150)
        }
        
        return container
    }
    
    private func createSliderControl(title: String, value: Float, min: Float, max: Float,
                                     valueFormat: String = "%.2f",
                                     valueChanged: @escaping (Float) -> Void) -> UIView {
        let container = UIView()
        
        let titleLabel = createLabel(title)
        let valueLabel = createValueLabel(String(format: valueFormat, value))
        
        let slider = UISlider()
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = value
        
        // 存储闭包引用
        objc_setAssociatedObject(slider, &Self.valueChangedKey, valueChanged, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(slider, &Self.valueLabelKey, valueLabel, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(slider, &Self.valueFormatKey, valueFormat, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        slider.addTarget(self, action: #selector(simpleSliderChanged(_:)), for: .valueChanged)
        
        let topStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        topStack.axis = .horizontal
        topStack.distribution = .fill
        topStack.alignment = .center
        
        container.addSubview(topStack)
        container.addSubview(slider)
        
        topStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        slider.snp.makeConstraints { make in
            make.top.equalTo(topStack.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        return container
    }
    
    private func createSegmentedControl(title: String, items: [String], selectedIndex: Int,
                                        valueChanged: @escaping (Int) -> Void) -> UIView {
        let container = UIView()
        
        let titleLabel = createLabel(title)
        
        // 为了优化显示不完整，将SegmentedControl放入横向ScrollView中
        let scrollContainer = UIScrollView()
        scrollContainer.showsHorizontalScrollIndicator = false
        
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = selectedIndex
        segmentedControl.apportionsSegmentWidthsByContent = true  // 根据内容调整宽度
        
        // 存储闭包引用
        objc_setAssociatedObject(segmentedControl, &Self.valueChangedKey, valueChanged, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged(_:)), for: .valueChanged)
        
        scrollContainer.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(32)  // 标准高度
        }
        
        container.addSubview(titleLabel)
        container.addSubview(scrollContainer)
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        scrollContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(32)
        }
        
        return container
    }
    
    private func createColorControl(title: String, color: UIColor,
                                    valueChanged: @escaping (UIColor) -> Void) -> UIView {
        let container = UIView()
        
        let titleLabel = createLabel(title)
        let colorView = UIView()
        colorView.backgroundColor = color
        colorView.layer.borderWidth = 1
        colorView.layer.borderColor = UIColor.separator.cgColor
        colorView.layer.cornerRadius = 4
        
        let colorButton = UIButton(type: .system)
        colorButton.setTitle("选择颜色", for: .normal)
        
        // 存储闭包引用
        objc_setAssociatedObject(colorButton, &Self.colorViewKey, colorView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(colorButton, &Self.valueChangedKey, valueChanged, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        colorButton.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
        
        container.addSubview(titleLabel)
        container.addSubview(colorView)
        container.addSubview(colorButton)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        colorView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        colorButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        
        return container
    }
    
    private func createSwitchGroupControl(title: String, switches: [(String, Bool, (Bool) -> Void)]) -> UIView {
        let container = UIView()
        
        let titleLabel = createLabel(title)
        container.addSubview(titleLabel)
        
        var lastView: UIView = titleLabel
        
        for (switchTitle, isOn, changed) in switches {
            let switchControl = UISwitch()
            switchControl.isOn = isOn
            
            let label = createLabel(switchTitle)
            
            // 存储闭包引用
            objc_setAssociatedObject(switchControl, &Self.valueChangedKey, changed, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            switchControl.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            
            container.addSubview(switchControl)
            container.addSubview(label)
            
            switchControl.snp.makeConstraints { make in
                make.top.equalTo(lastView.snp.bottom).offset(10)
                make.leading.equalToSuperview()
            }
            
            label.snp.makeConstraints { make in
                make.leading.equalTo(switchControl.snp.trailing).offset(10)
                make.centerY.equalTo(switchControl)
            }
            
            lastView = switchControl
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        container.snp.makeConstraints { make in
            make.bottom.equalTo(lastView.snp.bottom)
        }
        
        return container
    }
    
    // MARK: - Control Actions
    
    @objc private func pointSliderChanged(_ slider: UISlider) {
        if let valueLabel = objc_getAssociatedObject(slider, &Self.valueLabelKey) as? UILabel {
            valueLabel.text = String(format: "%.1f", slider.value)
        }
        
        if let valueChanged = objc_getAssociatedObject(slider, &Self.valueChangedKey) as? (CGFloat) -> Void {
            valueChanged(CGFloat(slider.value))
        }
    }
    
    @objc private func simpleSliderChanged(_ slider: UISlider) {
        if let valueLabel = objc_getAssociatedObject(slider, &Self.valueLabelKey) as? UILabel,
           let format = objc_getAssociatedObject(slider, &Self.valueFormatKey) as? String {
            valueLabel.text = String(format: format, slider.value)
        }
        
        if let valueChanged = objc_getAssociatedObject(slider, &Self.valueChangedKey) as? (Float) -> Void {
            valueChanged(slider.value)
        }
    }
    
    @objc private func segmentedControlChanged(_ control: UISegmentedControl) {
        if let valueChanged = objc_getAssociatedObject(control, &Self.valueChangedKey) as? (Int) -> Void {
            valueChanged(control.selectedSegmentIndex)
        }
    }
    
    @objc private func colorButtonTapped(_ button: UIButton) {
        guard let colorView = objc_getAssociatedObject(button, &Self.colorViewKey) as? UIView,
              let valueChanged = objc_getAssociatedObject(button, &Self.valueChangedKey) as? (UIColor) -> Void else {
            return
        }
        
        let colorPicker = UIColorPickerViewController()
        colorPicker.supportsAlpha = true
        colorPicker.selectedColor = colorView.backgroundColor ?? .clear
        colorPicker.delegate = self
        
        // 存储引用
        objc_setAssociatedObject(colorPicker, &Self.pickerColorViewKey, colorView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(colorPicker, &Self.pickerValueChangedKey, valueChanged, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        present(colorPicker, animated: true)
    }
    
    @objc private func switchChanged(_ switchControl: UISwitch) {
        if let valueChanged = objc_getAssociatedObject(switchControl, &Self.valueChangedKey) as? (Bool) -> Void {
            valueChanged(switchControl.isOn)
        }
    }
    
    // MARK: - Image Combination
    
    @objc private func combineImages() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let result = UIImage.wy_combineImages(
                standardImage: self.standardImage,
                stitchingImage: self.stitchingImage,
                stitchingCenterPoint: self.stitchingCenterPoint,
                overlapControl: self.overlapControl,
                alpha: self.alpha,
                blendMode: self.blendMode,
                backgroundColor: self.backgroundColor,
                cornerRadius: self.cornerRadius,
                rotationAngle: self.rotationAngle,
                flipHorizontal: self.flipHorizontal,
                flipVertical: self.flipVertical,
                qualityScale: self.qualityScale,
                scale: self.scale,
                shadowColor: self.shadowColor,
                shadowBlur: self.shadowBlur,
                shadowOffset: self.shadowOffset,
                strokeColor: self.strokeColor,
                strokeWidth: self.strokeWidth,
                maskImage: self.maskImage
            )
            
            DispatchQueue.main.async {
                if let result = result {
                    self.resultImageView.image = result
                    print("图片合成成功，尺寸: \(result.size)")
                } else {
                    self.resultImageView.image = nil
                    let alert = UIAlertController(
                        title: "合成失败",
                        message: "参数错误或图片处理失败",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "确定", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - UIColorPickerViewControllerDelegate
@available(iOS 14.0, *)
extension WYTestCombineImagesController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        if let colorView = objc_getAssociatedObject(viewController, &Self.pickerColorViewKey) as? UIView {
            colorView.backgroundColor = color
        }
        
        if !continuously {
            if let valueChanged = objc_getAssociatedObject(viewController, &Self.pickerValueChangedKey) as? (UIColor) -> Void {
                valueChanged(color)
            }
        }
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        dismiss(animated: true) {
            if let colorView = objc_getAssociatedObject(viewController, &Self.pickerColorViewKey) as? UIView,
               let color = colorView.backgroundColor,
               let valueChanged = objc_getAssociatedObject(viewController, &Self.pickerValueChangedKey) as? (UIColor) -> Void {
                valueChanged(color)
            }
        }
    }
}
