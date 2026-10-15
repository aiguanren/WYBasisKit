//
//  WYTestImageEditorController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/10/15.
//

import UIKit

class WYTestImageEditorController: UIViewController, WYImageEditorViewControllerDelegate {

    /// 裁剪形状(矩形或圆形)
    var cropShape: WYImageCropShape = .rectangle

    /// 固定裁剪尺寸(nil表示自由裁剪)
    var fixedCropSize: CGSize? = nil

    /// 是否允许标记
    var allowsMarking: Bool = true

    /// 是否允许裁剪
    var allowsCropping: Bool = true

    /// 是否用自定义外观(一组覆盖多项外观属性的示例值)
    var useCustomAppearance: Bool = false

    /// 编辑时图片是否支持捏合缩放
    var allowsImageZoom: Bool = true

    /// 标记颜色
    var markerColor: UIColor = .white

    /// 标记线宽(0表示自动)
    var markerLineWidth: CGFloat = 0

    /// 文本字号(0表示自动)
    var markerTextFontSize: CGFloat = 0

    /// 划线默认形态(true为直线)
    var lineDrawsStraight: Bool = false

    /// 界面是否显示粗细字号选择行
    var showsStyleOptions: Bool = true

    /// 界面是否显示颜色选择条
    var showsColorOptions: Bool = true

    /// 测试图片名字(nil表示用生成的标尺图)
    var testImageName: String? = nil

    /// 标尺图下标(0横图 1竖图 2方图，testImageName为nil时生效)
    var rulerImageIndex: Int = 0

    /// 编辑成品图(三种打开方式的回调里更新并刷表)
    var resultImage: UIImage? = nil

    /// 结果来源说明(记录哪条路回调回来的)
    var resultSource: String = "暂无结果"

    var tableView: UITableView? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        let contentView: UIView = UIView()
        contentView.backgroundColor = .white
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view).offset(UIDevice.wy_navViewHeight + 20)
            make.centerX.equalTo(view)
        }

        let shapeButton: UIButton = createButton(title: "裁剪形状(矩形)", selector: #selector(shapeButtonTapped(sender:)), superView: contentView, leftView: nil, topView: nil)
        shapeButton.setTitle("裁剪形状(圆形)", for: .selected)

        let sizeButton: UIButton = createButton(title: "裁剪尺寸(自由)", selector: #selector(sizeButtonTapped(sender:)), superView: contentView, leftView: shapeButton, topView: nil)

        let markingButton: UIButton = createButton(title: "(已允许)标记", selector: #selector(markingButtonTapped(sender:)), superView: contentView, leftView: sizeButton, topView: nil, isRight: true)
        markingButton.setTitle("(已关闭)标记", for: .selected)

        let croppingButton: UIButton = createButton(title: "(已允许)裁剪", selector: #selector(croppingButtonTapped(sender:)), superView: contentView, leftView: nil, topView: shapeButton)
        croppingButton.setTitle("(已关闭)裁剪", for: .selected)

        let colorButton: UIButton = createButton(title: "标记颜色(白)", selector: #selector(colorButtonTapped(sender:)), superView: contentView, leftView: croppingButton, topView: shapeButton)

        createButton(title: "线条宽度(自动)", selector: #selector(lineWidthButtonTapped(sender:)), superView: contentView, leftView: colorButton, topView: shapeButton, isRight: true)

        let fontSizeButton: UIButton = createButton(title: "文本字号(自动)", selector: #selector(fontSizeButtonTapped(sender:)), superView: contentView, leftView: nil, topView: croppingButton)

        let lineShapeButton: UIButton = createButton(title: "划线形态(自由)", selector: #selector(lineShapeButtonTapped(sender:)), superView: contentView, leftView: fontSizeButton, topView: croppingButton)
        lineShapeButton.setTitle("划线形态(直线)", for: .selected)

        createButton(title: "(显示)粗细字号行", selector: #selector(styleRowButtonTapped(sender:)), superView: contentView, leftView: lineShapeButton, topView: croppingButton, isRight: true)

        let colorRowButton: UIButton = createButton(title: "(显示)颜色条", selector: #selector(colorRowButtonTapped(sender:)), superView: contentView, leftView: nil, topView: fontSizeButton)
        colorRowButton.setTitle("(隐藏)颜色条", for: .selected)

        let imageButton: UIButton = createButton(title: "测试图片(标尺横图)", selector: #selector(imageButtonTapped(sender:)), superView: contentView, leftView: colorRowButton, topView: fontSizeButton)

        let appearanceButton: UIButton = createButton(title: "外观(默认)", selector: #selector(appearanceButtonTapped(sender:)), superView: contentView, leftView: imageButton, topView: fontSizeButton, isRight: true)
        appearanceButton.setTitle("外观(自定义)", for: .selected)

        let blockButton: UIButton = createButton(title: "Block方式\n打开编辑器", selector: #selector(blockButtonTapped), superView: contentView, leftView: nil, topView: colorRowButton)

        let delegateButton: UIButton = createButton(title: "Delegate方式\n打开编辑器", selector: #selector(delegateButtonTapped), superView: contentView, leftView: blockButton, topView: colorRowButton)

        createButton(title: "静态方法\n一行打开", selector: #selector(staticButtonTapped), superView: contentView, leftView: delegateButton, topView: colorRowButton, isRight: true)

        let clearButton: UIButton = createButton(title: "清除结果", selector: #selector(clearButtonTapped), superView: contentView, leftView: nil, topView: blockButton, isLast: true)

        let zoomButton: UIButton = createButton(title: "(可缩放)图片", selector: #selector(zoomButtonTapped(sender:)), superView: contentView, leftView: clearButton, topView: blockButton)
        zoomButton.setTitle("(禁用)缩放", for: .selected)

        tableView = UITableView.wy_shared(delegate: self, dataSource: self, superView: view)
        tableView?.wy_register(WYTestImageEditorResultCell.self, .cell)
        tableView?.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }

    }

    @discardableResult func createButton(title: String, selector: Selector, superView: UIView, leftView: UIView?, topView: UIView?, isRight: Bool = false, isLast: Bool = false) -> UIButton {
        let button: UIButton = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.setTitleColor(.wy_random, for: .normal)
        button.wy_addBorder(edges: .all, color: .wy_random, thickness: 1)
        button.addTarget(self, action: selector, for: .touchUpInside)
        button.titleLabel?.textAlignment = .center
        superView.addSubview(button)
        button.snp.makeConstraints { make in

            if let leftView = leftView {
                make.left.equalTo(leftView.snp.right).offset(15)
            }else {
                make.left.equalToSuperview()
            }

            if (isRight) {
                make.right.equalToSuperview()
            }

            if let topView = topView {
                make.top.equalTo(topView.snp.bottom).offset(20)
            }else {
                make.top.equalToSuperview()
            }

            if (isLast) {
                make.bottom.equalToSuperview()
            }

            make.size.equalTo(CGSize(width: (UIDevice.wy_screenWidth - 60) / 3, height: 50))
        }

        return button
    }

    /// 生成当前配置的编辑器配置对象
    func buildConfiguration() -> WYImageEditorConfiguration {
        var configuration = WYImageEditorConfiguration()
        configuration.cropShape = cropShape
        configuration.cropSize = fixedCropSize ?? .zero
        configuration.allowsCropping = allowsCropping
        configuration.allowsMarking = allowsMarking
        if useCustomAppearance {
            var appearance = WYImageEditorAppearance()
            appearance.topBarCropButtonColor = .systemYellow
            appearance.selectionDashColor = .systemRed
            appearance.selectionDashWidth = 2.5
            appearance.selectionInset = 10
            appearance.handleColor = .systemYellow
            appearance.maskDimmingAmount = 0.8
            appearance.accentColor = .systemGreen
            appearance.segmentedSelectedBackgroundColor = .systemGreen
            appearance.segmentedSelectedTextColor = .white
            appearance.markerPalette = [.white, .red, .yellow]
            appearance.lineWidthRatios = [0.5, 2, 4]
            appearance.canvasBackgroundColor = UIColor(white: 0.15, alpha: 1)
            configuration.appearance = appearance
        }
        configuration.allowsImageZoom = allowsImageZoom
        configuration.markerColor = markerColor
        configuration.markerLineWidth = markerLineWidth
        configuration.markerTextFontSize = markerTextFontSize
        configuration.lineDrawsStraight = lineDrawsStraight
        configuration.showsStyleOptions = showsStyleOptions
        configuration.showsColorOptions = showsColorOptions
        return configuration
    }

    /// 生成当前选中的测试图(真实图片直接取Resource目录，标尺图现场绘制)
    func buildTestImage() -> UIImage {
        if let imageName = testImageName, let loaded = UIImage(named: imageName) {
            return loaded
        }
        let sizes = [CGSize(width: 800, height: 600), CGSize(width: 600, height: 800), CGSize(width: 700, height: 700)]
        let imageSize = sizes[rulerImageIndex]
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        return renderer.image { rendererContext in
            let context = rendererContext.cgContext

            // 蓝到黄渐变底
            let colors = [UIColor(red: 0.25, green: 0.5, blue: 0.92, alpha: 1).cgColor, UIColor(red: 0.98, green: 0.78, blue: 0.18, alpha: 1).cgColor]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
                context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: imageSize.width, y: imageSize.height), options: [])
            }

            // 四角色块(红绿蓝紫，肉眼快速认方向)
            let cornerColors = [UIColor.red, UIColor.green, UIColor.blue, UIColor.purple]
            let cornerLength: CGFloat = 60
            let cornerRects = [CGRect(x: 0, y: 0, width: cornerLength, height: cornerLength),
                               CGRect(x: imageSize.width - cornerLength, y: 0, width: cornerLength, height: cornerLength),
                               CGRect(x: 0, y: imageSize.height - cornerLength, width: cornerLength, height: cornerLength),
                               CGRect(x: imageSize.width - cornerLength, y: imageSize.height - cornerLength, width: cornerLength, height: cornerLength)]
            for (index, rect) in cornerRects.enumerated() {
                context.setFillColor(cornerColors[index].withAlphaComponent(0.75).cgColor)
                context.fill(rect)
            }

            // 每百像素白色网格线
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.7).cgColor)
            context.setLineWidth(1)
            var position: CGFloat = 100
            while position < imageSize.width {
                context.move(to: CGPoint(x: position, y: 0))
                context.addLine(to: CGPoint(x: position, y: imageSize.height))
                position += 100
            }
            position = 100
            while position < imageSize.height {
                context.move(to: CGPoint(x: 0, y: position))
                context.addLine(to: CGPoint(x: imageSize.width, y: position))
                position += 100
            }
            context.strokePath()

            // 网格线标尺数字(横轴纵轴都标)
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: UIColor.white]
            var xLabel: CGFloat = 0
            while xLabel < imageSize.width {
                let label = "\(Int(xLabel))"
                (label as NSString).draw(at: CGPoint(x: xLabel + 3, y: 3), withAttributes: attributes)
                xLabel += 100
            }
            var yLabel: CGFloat = 100
            while yLabel < imageSize.height {
                let label = "\(Int(yLabel))"
                (label as NSString).draw(at: CGPoint(x: 3, y: yLabel + 3), withAttributes: attributes)
                yLabel += 100
            }
        }
    }

    /// 打开前打印一遍当前配置与原图信息(三种打开方式共用)
    func printOpenLog(source: String, image: UIImage) {
        let shapeText = cropShape == .circle ? "圆形" : "矩形"
        let sizeText = fixedCropSize == nil ? "自由" : String(format: "固定%.0f×%.0f", fixedCropSize!.width, fixedCropSize!.height)
        let markingText = allowsMarking ? "允许" : "关闭"
        let lineWidthText = markerLineWidth == 0 ? "自动" : String(format: "%.0f", markerLineWidth)
        let fontSizeText = markerTextFontSize == 0 ? "自动" : String(format: "%.0f", markerTextFontSize)
        let lineShapeText = lineDrawsStraight ? "直线" : "自由"
        let styleRowText = showsStyleOptions ? "显示" : "隐藏"
        let colorRowText = showsColorOptions ? "显示" : "隐藏"
        let imageSourceText = testImageName ?? "标尺图"
        let croppingText = allowsCropping ? "允许" : "关闭"
        let appearanceText = useCustomAppearance ? "自定义" : "默认"
        let zoomText = allowsImageZoom ? "可缩放" : "禁缩放"
        wy_print("[\(source)] 打开编辑器 图片=\(imageSourceText) 原图\(Int(image.size.width))×\(Int(image.size.height)) 配置=形状\(shapeText) 尺寸\(sizeText) 裁剪\(croppingText) 标记\(markingText) 线宽\(lineWidthText) 字号\(fontSizeText) 划线\(lineShapeText) 粗细字号行\(styleRowText) 颜色条\(colorRowText) 外观\(appearanceText) 缩放\(zoomText)")
    }

    /// 记录编辑结果并刷新表格(三种打开方式共用)
    func handleResult(_ image: UIImage?, source: String) {
        if let image = image {
            resultImage = image
            resultSource = source
            wy_print("[\(source)] 编辑完成 成品图\(Int(image.size.width))×\(Int(image.size.height)) scale=\(image.scale)")
        } else {
            resultSource = "\(source)(取消了)"
            wy_print("[\(source)] 已取消编辑")
        }
        tableView?.reloadData()
    }

    @objc func shapeButtonTapped(sender: UIButton) {
        UIAlertController.wy_show(title: "裁剪形状", actions: ["矩形", "圆形"]) { [weak self] action, _ in
            guard let self = self else { return }
            self.cropShape = action == "圆形" ? .circle : .rectangle
            sender.isSelected = self.cropShape == .circle
            sender.setTitle("裁剪形状(\(action))", for: .normal)
        }
    }

    @objc func sizeButtonTapped(sender: UIButton) {
        UIAlertController.wy_show(title: "裁剪尺寸(留空两项为自由裁剪)", textFieldPlaceholders: ["宽(像素)", "高(像素)"], actions: ["确定"]) { [weak self] action, inputTexts in
            guard let self = self, action == "确定" else { return }
            let width = Double(inputTexts.first ?? "")
            let height = Double(inputTexts.last ?? "")
            if let width = width, let height = height, width > 0, height > 0 {
                self.fixedCropSize = CGSize(width: width, height: height)
                sender.setTitle(String(format: "裁剪尺寸(固定%.0f×%.0f)", width, height), for: .normal)
            } else {
                self.fixedCropSize = nil
                sender.setTitle("裁剪尺寸(自由)", for: .normal)
            }
        }
    }

    @objc func markingButtonTapped(sender: UIButton) {
        allowsMarking.toggle()
        sender.isSelected = !allowsMarking
    }

    /// 允许裁剪开关(关掉后编辑器只有标记功能)
    @objc func croppingButtonTapped(sender: UIButton) {
        allowsCropping.toggle()
        sender.isSelected = !allowsCropping
    }

    /// 外观样式切换(自定义为覆盖多项外观属性的示例值)
    @objc func appearanceButtonTapped(sender: UIButton) {
        useCustomAppearance.toggle()
        sender.isSelected = useCustomAppearance
    }

    /// 编辑时图片缩放开关(关掉后编辑器里不能捏合缩放)
    @objc func zoomButtonTapped(sender: UIButton) {
        allowsImageZoom.toggle()
        sender.isSelected = !allowsImageZoom
    }

    @objc func colorButtonTapped(sender: UIButton) {
        let colorNames = ["白", "黑", "黄", "红", "绿", "蓝", "紫"]
        UIAlertController.wy_show(title: "标记颜色", actions: colorNames) { [weak self] action, _ in
            guard let self = self, let index = colorNames.firstIndex(of: action) else { return }
            let colors = [UIColor.white, UIColor.black, UIColor(red: 1, green: 0.84, blue: 0.03, alpha: 1), UIColor(red: 1, green: 0.27, blue: 0.23, alpha: 1), UIColor(red: 0.22, green: 0.8, blue: 0.35, alpha: 1), UIColor(red: 0.04, green: 0.52, blue: 1, alpha: 1), UIColor(red: 0.69, green: 0.33, blue: 0.87, alpha: 1)]
            self.markerColor = colors[index]
            sender.setTitle("标记颜色(\(action))", for: .normal)
        }
    }

    @objc func lineWidthButtonTapped(sender: UIButton) {
        UIAlertController.wy_show(title: "标记线条宽度(0为按图片宽度自动)", textFieldPlaceholders: ["线宽(像素)"], actions: ["确定"]) { [weak self] action, inputTexts in
            guard let self = self, action == "确定" else { return }
            let width = Double(inputTexts.first ?? "")
            self.markerLineWidth = width == nil ? 0 : CGFloat(width!)
            sender.setTitle(self.markerLineWidth == 0 ? "线条宽度(自动)" : String(format: "线条宽度(%.0f)", self.markerLineWidth), for: .normal)
        }
    }

    @objc func fontSizeButtonTapped(sender: UIButton) {
        UIAlertController.wy_show(title: "文本字号(0为按图片宽度自动)", textFieldPlaceholders: ["字号(像素)"], actions: ["确定"]) { [weak self] action, inputTexts in
            guard let self = self, action == "确定" else { return }
            let fontSize = Double(inputTexts.first ?? "")
            self.markerTextFontSize = fontSize == nil ? 0 : CGFloat(fontSize!)
            sender.setTitle(self.markerTextFontSize == 0 ? "文本字号(自动)" : String(format: "文本字号(%.0f)", self.markerTextFontSize), for: .normal)
        }
    }

    @objc func imageButtonTapped(sender: UIButton) {
        let realImageNames = ["窗花", "帆船", "红色爱心", "红色花", "蓝色小屋", "蓝天下的红色花", "蓝天下的花", "啤酒"]
        let actionTitles = realImageNames + ["标尺横图(800×600)", "标尺竖图(600×800)", "标尺方图(700×700)"]
        UIAlertController.wy_show(title: "测试图片(前八项为Resource里的真实图片)", actions: actionTitles) { [weak self] action, _ in
            guard let self = self else { return }
            if let realIndex = realImageNames.firstIndex(of: action) {
                self.testImageName = realImageNames[realIndex]
                sender.setTitle("测试图片(\(realImageNames[realIndex]))", for: .normal)
            } else if let rulerIndex = ["标尺横图(800×600)", "标尺竖图(600×800)", "标尺方图(700×700)"].firstIndex(of: action) {
                self.testImageName = nil
                self.rulerImageIndex = rulerIndex
                sender.setTitle("测试图片(标尺\(["横图", "竖图", "方图"][rulerIndex]))", for: .normal)
            }
        }
    }

    /// 划线默认形态切换(自由与直线两态)
    @objc func lineShapeButtonTapped(sender: UIButton) {
        lineDrawsStraight.toggle()
        sender.isSelected = lineDrawsStraight
    }

    /// 界面粗细字号选择行显示开关
    @objc func styleRowButtonTapped(sender: UIButton) {
        showsStyleOptions.toggle()
        sender.isSelected = !showsStyleOptions
    }

    /// 界面颜色选择条显示开关
    @objc func colorRowButtonTapped(sender: UIButton) {
        showsColorOptions.toggle()
        sender.isSelected = !showsColorOptions
    }

    /// Block回调方式(直接构造编辑器设onFinish与onCancel)
    @objc func blockButtonTapped() {
        let image = buildTestImage()
        printOpenLog(source: "Block方式", image: image)

        let editor = WYImageEditorViewController(image: image, configuration: buildConfiguration())
        editor.onFinish = { [weak self] resultImage in
            self?.handleResult(resultImage, source: "Block方式")
        }
        editor.onCancel = { [weak self] in
            self?.handleResult(nil, source: "Block方式")
        }
        editor.modalPresentationStyle = .fullScreen
        present(editor, animated: true)
    }

    /// Delegate回调方式(直接构造编辑器设editorDelegate)
    @objc func delegateButtonTapped() {
        let image = buildTestImage()
        printOpenLog(source: "Delegate方式", image: image)

        let editor = WYImageEditorViewController(image: image, configuration: buildConfiguration())
        editor.editorDelegate = self
        editor.modalPresentationStyle = .fullScreen
        present(editor, animated: true)
    }

    /// 静态方法一行打开(handler方式，取消回调nil)
    @objc func staticButtonTapped() {
        let image = buildTestImage()
        printOpenLog(source: "静态方法", image: image)
        WYImageEditorViewController.present(from: self, image: image, configuration: buildConfiguration()) { [weak self] resultImage in
            self?.handleResult(resultImage, source: "静态方法")
        }
    }

    @objc func clearButtonTapped() {
        resultImage = nil
        resultSource = "暂无结果"
        wy_print("已清除结果")
        tableView?.reloadData()
    }

    func wy_imageEditorViewController(_ editor: WYImageEditorViewController, didFinishEditing image: UIImage) {
        handleResult(image, source: "Delegate方式")
    }

    func wy_imageEditorViewControllerDidCancel(_ editor: WYImageEditorViewController) {
        handleResult(nil, source: "Delegate方式")
    }
}

extension WYTestImageEditorController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WYTestImageEditorResultCell", for: indexPath) as! WYTestImageEditorResultCell
        if indexPath.row == 0 {
            cell.configure(title: "原图信息", detail: "宽×高见打开日志(渐变标尺图)", image: nil)
        } else if indexPath.row == 1 {
            cell.configure(title: "结果来源", detail: resultSource, image: nil)
        } else {
            cell.configure(title: "结果预览", detail: nil, image: resultImage)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 2, let image = resultImage {
            let maxWidth = tableView.bounds.width - 32
            return max(44, min(320, image.size.height * maxWidth / max(image.size.width, 1)) + 30)
        }
        return 60
    }
}

/// 结果展示cell(标题加说明加结果图预览)
class WYTestImageEditorResultCell: UITableViewCell {

    /// 标题标签
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        return label
    }()

    /// 说明标签
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .gray
        label.numberOfLines = 0
        return label
    }()

    /// 结果图(圆形裁剪的透明四角放黑底上看得分明)
    private let resultImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .black
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(resultImageView)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(10)
        }
        detailLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
        }
        resultImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 填充内容(有图显图没图隐藏)
    func configure(title: String, detail: String?, image: UIImage?) {
        titleLabel.text = title
        detailLabel.text = detail
        detailLabel.isHidden = detail == nil
        resultImageView.image = image
        resultImageView.isHidden = image == nil
    }
}
