//
//  WYTestVisualController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/12.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit
import SnapKit

class WYTestVisualController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    /// 每个静态组合的标题和链式配置(标题显示在视觉区下方的外部标签上，不会被边框、圆角、阴影挡住)
    private let visualItems: [(title: String, make: (UIView) -> Void)] = [
        ("radius 10", { $0.wy_cornerRadius(10) }),
        ("radius 15 topRight", { $0.wy_cornerRadius(15).wy_rectCorner([.topRight]) }),
        ("border 5", { $0.wy_borderWidth(5).wy_borderColor(.black) }),
        ("radius 10 + border 5", { $0.wy_cornerRadius(10).wy_borderWidth(5).wy_borderColor(.black) }),
        ("radius 10 + border 20 (宽边框吃圆角场景)", { $0.wy_cornerRadius(10).wy_borderWidth(20).wy_borderColor(.systemRed) }),
        ("radius 30 + border 10 topLeft", { $0.wy_cornerRadius(30).wy_borderWidth(10).wy_rectCorner([.topLeft]).wy_borderColor(.systemBlue) }),
        ("渐变→", { $0.wy_gradualColors([.orange, .red]) }),
        ("渐变↓", { $0.wy_gradualColors([.orange, .red]).wy_gradientDirection(.topToBottom) }),
        ("渐变↘", { $0.wy_gradualColors([.orange, .red]).wy_gradientDirection(.leftToLowRight) }),
        ("渐变↙", { $0.wy_gradualColors([.orange, .red]).wy_gradientDirection(.rightToLowLeft) }),
        ("渐变 + radius 15", { $0.wy_gradualColors([.orange, .red]).wy_cornerRadius(15) }),
        ("渐变 + radius 15 + border 5", { $0.wy_gradualColors([.orange, .red]).wy_cornerRadius(15).wy_borderWidth(5).wy_borderColor(.black) }),
        ("阴影(无路径)", { $0.wy_shadowColor(.black).wy_shadowRadius(8).wy_shadowOpacity(0.6) }),
        ("阴影 + radius 15", { $0.wy_shadowColor(.black).wy_shadowRadius(8).wy_shadowOpacity(0.6).wy_cornerRadius(15) }),
        ("阴影 + radius + border", { $0.wy_shadowColor(.black).wy_shadowRadius(8).wy_shadowOpacity(0.6).wy_cornerRadius(15).wy_borderWidth(5).wy_borderColor(.black) }),
        ("全叠加(渐变+圆角+边框+阴影)", { $0.wy_gradualColors([.orange, .red]).wy_cornerRadius(15).wy_borderWidth(5).wy_borderColor(.black).wy_shadowColor(.black).wy_shadowRadius(8).wy_shadowOpacity(0.6) }),
        ("椭圆路径 + border 5 + 阴影", { $0.wy_bezierPath(UIBezierPath(ovalIn: CGRect(x: 8, y: 5, width: 155, height: 100))).wy_borderWidth(5).wy_borderColor(.purple).wy_shadowColor(.black).wy_shadowRadius(8).wy_shadowOpacity(0.6) }),
        ("指定位置边框 all 8", { $0.backgroundColor = UIColor.systemTeal }),
        ("阴影+半透明背景(保持轮廓)", { $0.backgroundColor = UIColor(white: 0.92, alpha: 0.5); $0.wy_shadowColor(.black).wy_shadowRadius(8).wy_shadowOpacity(0.6) }),
        ("阴影+子视图(轮廓随子视图)", { $0.backgroundColor = UIColor.clear; let icon = UIView(frame: CGRect(x: 25, y: 25, width: 100, height: 60)); icon.backgroundColor = UIColor.systemTeal; $0.addSubview(icon); $0.wy_shadowColor(.black).wy_shadowRadius(8).wy_shadowOpacity(0.6) }),
        ("阴影+不透明渐变(无圆角)", { $0.wy_gradualColors([.orange, .red]).wy_shadowColor(.black).wy_shadowRadius(8).wy_shadowOpacity(0.6) }),
        ("阴影+半透明渐变(保持轮廓)", { $0.backgroundColor = UIColor.clear; $0.wy_gradualColors([UIColor.orange.withAlphaComponent(0.5), .red]).wy_shadowColor(.black).wy_shadowRadius(8).wy_shadowOpacity(0.6) }),
        ("阴影opacity 5(钳到1)", { $0.wy_shadowColor(.black).wy_shadowRadius(8).wy_shadowOpacity(5) }),
        ("radius 500(钳到半短边)", { $0.wy_cornerRadius(500) }),
        ("radius -20(按0处理)", { $0.wy_cornerRadius(-20).wy_borderWidth(4).wy_borderColor(.black) }),
        ("border 80超宽(内缩钳制)", { $0.backgroundColor = UIColor.systemTeal; $0.wy_borderWidth(80).wy_borderColor(.systemPurple) }),
        ("圆角裁图片", { $0.backgroundColor = UIColor.clear; let renderer = UIGraphicsImageRenderer(size: CGSize(width: 150, height: 90)); let image = renderer.image { context in UIColor.systemRed.setFill(); context.fill(CGRect(x: 0, y: 0, width: 75, height: 90)); UIColor.systemBlue.setFill(); context.fill(CGRect(x: 75, y: 0, width: 75, height: 90)) }; let imageView = UIImageView(image: image); imageView.frame = CGRect(x: 0, y: 0, width: 150, height: 90); imageView.contentMode = .scaleToFill; imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]; $0.addSubview(imageView); $0.wy_cornerRadius(24) }),
        ("圆角裁子视图(左上角被裁圆)", { $0.backgroundColor = UIColor(white: 0.92, alpha: 1.0); let cornerSquare = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44)); cornerSquare.backgroundColor = UIColor.systemRed; $0.addSubview(cornerSquare); let centerLabel = UILabel(); centerLabel.text = "内容"; centerLabel.textAlignment = .center; centerLabel.frame = CGRect(x: 30, y: 40, width: 100, height: 30); $0.addSubview(centerLabel); $0.wy_cornerRadius(20) }),
        ("椭圆路径+渐变+阴影", { $0.wy_bezierPath(UIBezierPath(ovalIn: CGRect(x: 8, y: 5, width: 155, height: 100))).wy_gradualColors([.orange, .red]).wy_shadowColor(.black).wy_shadowRadius(8).wy_shadowOpacity(0.6) }),
        ("渐变+部分圆角", { $0.wy_gradualColors([.orange, .red]).wy_cornerRadius(18).wy_rectCorner([.topLeft, .bottomRight]) }),
        ("单色渐变数组(不启用)", { $0.wy_gradualColors([.purple]) }),
        ("透明底+边框条+阴影(空心轮廓)", { $0.backgroundColor = UIColor.clear; $0.wy_addBorder(edges: .all, color: .black, thickness: 6); $0.wy_shadowColor(.black).wy_shadowRadius(8).wy_shadowOpacity(0.6) }),
        ("border -10(按0处理)", { $0.wy_borderWidth(-10).wy_borderColor(.black) }),
        ("阴影opacity 0+透明色(无阴影)", { $0.wy_shadowColor(.clear).wy_shadowOpacity(0).wy_shadowRadius(8) }),
    ]

    private let scrollView = UIScrollView()
    private let bigButton = UIButton(type: .custom)
    private let statusLabel = UILabel()
    private let shadowBlock = UIView()
    private var applyCount: Int = 0
    private var borderIndex: Int = 0
    private var edgeBorderRemoved: Bool = false
    private var isBigSize: Bool = false
    private var isOffset: Bool = false
    private var isRotated: Bool = false
    private var isScaled: Bool = false
    private var isNarrow: Bool = false
    private var shadowBlockHasRadius: Bool = false
    private var shadowBlockBig: Bool = false
    private var extremeIndex: Int = 0
    private let extremeRadii: [CGFloat] = [-20, 8, 500]
    private var sameFrameThick: Bool = false
    private var shadowBlockHasChild: Bool = false
    private var midFlightThick: Bool = true
    private let shadowBlockChild = UIView(frame: CGRect(x: -24, y: 20, width: 60, height: 60))
    private let lateMountSlot = UIView()
    private let edgeThicknesses: [CGFloat] = [6, 14]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "边框、圆角、阴影、渐变"

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 16
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 30, right: 16))
            make.width.equalTo(scrollView).offset(-32)
        }

        contentStack.addArrangedSubview(makeHintLabel())

        // 静态组合矩阵，两个一行，每项固定半列宽(防fillEqually把奇数行压扁导致固定路径的椭圆等视觉溢出越界)
        var rowItems: [(container: UIView, demoView: UIView, item: (title: String, make: (UIView) -> Void))] = []
        for item in visualItems {
            let demoItem = makeDemoItem(title: item.title)
            rowItems.append((container: demoItem.container, demoView: demoItem.demoView, item: item))
            if rowItems.count == 2 {
                contentStack.addArrangedSubview(makeRow(rowItems))
                rowItems = []
            }
        }
        if rowItems.isEmpty == false {
            contentStack.addArrangedSubview(makeRow(rowItems))
        }

        // viewBounds场景：控件还没布局(bounds为0)时先应用视觉，靠传入的固定bounds出效果
        let viewBoundsItem = makeDemoItem(title: "viewBounds(100x70)优先")
        contentStack.addArrangedSubview(makeRow([(container: viewBoundsItem.container, demoView: viewBoundsItem.demoView, item: (title: "viewBounds", make: { _ in }))]))
        viewBoundsItem.demoView.wy_cornerRadius(18).wy_borderWidth(4).wy_borderColor(.systemGreen).wy_gradualColors([.yellow, .purple]).wy_viewBounds(CGRect(x: 0, y: 0, width: 100, height: 70)).wy_showVisual()

        contentStack.addArrangedSubview(makeDynamicArea())
        applyBigButtonVisual()
        applyShadowBlockVisual()
        bigButton.wy_addBorder(edges: .all, color: .magenta, thickness: edgeThicknesses[borderIndex])
        refreshStatus()
    }

    /// 把一至两个演示项摆成一行，每项显式半列宽
    private func makeRow(_ items: [(container: UIView, demoView: UIView, item: (title: String, make: (UIView) -> Void))]) -> UIStackView {
        let rowStack = UIStackView(arrangedSubviews: items.map { $0.container })
        rowStack.axis = .horizontal
        rowStack.spacing = 16
        for current in items {
            current.container.snp.makeConstraints { make in
                make.width.equalTo(rowStack).multipliedBy(0.5).offset(items.count > 1 ? -8 : 0)
            }

            // 指定位置边框走单独API，viewBounds场景由调用方自行应用，其余走链式
            if current.item.title.hasPrefix("指定位置") {
                current.demoView.wy_addBorder(edges: .all, color: .magenta, thickness: 8)
            }else if current.item.title.hasPrefix("viewBounds") == false {
                current.demoView.wy_makeVisual(current.item.make)
            }
        }
        return rowStack
    }

    /// 顶部说明
    private func makeHintLabel() -> UILabel {
        let hintLabel = UILabel()
        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.textColor = .darkGray
        hintLabel.numberOfLines = 0
        hintLabel.text = "静态矩阵看几何与组合：'radius 10 + border 20'可见圆角必须仍是10(不能被宽边框吃成直角)；全叠加里紫色边框在最上层、渐变在最底层；'阴影(无路径)'和'阴影+不透明渐变'走矩形shadowPath，外观必须和轮廓阴影完全一致；'半透明背景/半透明渐变/子视图'三项必须保持轮廓阴影(阴影随实际内容形状变小变淡)；'圆角裁图片/圆角裁子视图'的圆角mask本职场景，子内容必须真的被裁住；'透明底+边框条+阴影'的轮廓阴影必须是空心边框条形状(不是实心矩形)；radius 500/-20、opacity 5、border 80/-10等极端值必须被钳制住不畸形；'单色渐变/opacity 0'必须等于没设置。动态区：点大按钮只改约束不改视觉，圆角/边框/渐变/阴影应自动跟随新尺寸不变形；'重复应用'连点多次应无任何闪烁；位移/旋转/缩放/改宽同样要同步跟随；'直切尺寸'应一步到位不闪帧；'慢动画2秒'途中再点应无缝反向。阴影块：'±圆角'来回切阴影在自身和背景视图间迁移，不能出双影残影；'改尺寸'阴影应同拍伸缩；'极端半径'轮换不畸形；'±子视图'阴影应在矩形shadowPath和轮廓阴影间自动迁移；'清除后立刻重建'应完整恢复；'慢动画+中途改配置'各图层应从当前屏显位置无缝接力到新配置；'同帧连设四边'四条边各自厚度颜色应一次到位无闪烁；'纯清除不重建'应回到裸视图；'先应用后上树'视觉应完整生效且不闪原始方块。"
        return hintLabel
    }

    /// 造一个"视觉区+外部标签"的演示项，标签在视觉区下方不会被任何视觉挡住
    private func makeDemoItem(title: String) -> (container: UIView, demoView: UIView) {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 4

        let demoView = UIView()
        demoView.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        demoView.snp.makeConstraints { make in
            make.height.equalTo(110)
        }
        container.addArrangedSubview(demoView)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 9)
        titleLabel.textColor = .darkGray
        titleLabel.numberOfLines = 2
        container.addArrangedSubview(titleLabel)

        return (container, demoView)
    }

    /// 动态验证区(重复应用/清除重建/同边替换/尺寸跟随/位移/旋转/缩放/改宽/直切/慢动画中断/阴影块挂载迁移与极端值/同帧清除重建/动画中重应用)
    private func makeDynamicArea() -> UIView {
        let container = UIView()

        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textColor = .darkGray
        statusLabel.numberOfLines = 0
        container.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        bigButton.setTitle("约束控件(点击只改约束尺寸)", for: .normal)
        bigButton.setTitleColor(.black, for: .normal)
        bigButton.titleLabel?.font = .systemFont(ofSize: 12)
        bigButton.titleLabel?.numberOfLines = 0
        bigButton.addTarget(self, action: #selector(toggleSize), for: .touchUpInside)
        container.addSubview(bigButton)
        bigButton.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(12)
            // 约束用宽度+中心点定位(初始和leading/trailing等价)，后面位移、改宽都能用updateConstraints只动常量
            make.width.centerX.equalToSuperview()
            make.height.equalTo(110)
        }

        let shadowCaption = UILabel()
        shadowCaption.font = .systemFont(ofSize: 11)
        shadowCaption.textColor = .darkGray
        shadowCaption.numberOfLines = 0
        shadowCaption.text = "阴影块(无圆角，阴影走自身矩形shadowPath，外观应和轮廓阴影完全一致；±圆角来回切不能出双影残影)"
        container.addSubview(shadowCaption)
        shadowCaption.snp.makeConstraints { make in
            make.top.equalTo(bigButton.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
        }

        shadowBlock.backgroundColor = UIColor.systemTeal
        shadowBlockChild.backgroundColor = UIColor.systemPurple
        container.addSubview(shadowBlock)
        shadowBlock.snp.makeConstraints { make in
            make.top.equalTo(shadowCaption.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(100)
        }

        let actionTitles = ["重复应用视觉", "清除后0.6秒重建", "指定边框换厚度", "移除指定边框", "移动位置", "旋转45度", "缩放0.7", "宽度减120", "直切尺寸", "慢动画2秒", "阴影块±圆角", "阴影块改尺寸", "阴影块极端半径", "清除后立刻重建", "慢动画+中途改配置", "同帧连设四边", "纯清除不重建", "阴影块±子视图", "先应用后上树"]
        let actionSelectors = [#selector(reapplyVisual), #selector(clearAndReapply), #selector(cycleEdgeBorder), #selector(removeEdgeBorder), #selector(togglePosition), #selector(toggleRotation), #selector(toggleScale), #selector(toggleWidth), #selector(snapSize), #selector(slowToggleSize), #selector(toggleShadowBlockRadius), #selector(toggleShadowBlockSize), #selector(cycleShadowBlockRadius), #selector(clearAndReapplyNow), #selector(slowToggleAndReapply), #selector(sameFrameEdgeBorders), #selector(clearOnly), #selector(toggleShadowBlockChild), #selector(applyThenMount)]
        let actionStack = UIStackView()
        actionStack.backgroundColor = .clear
        actionStack.axis = .vertical
        actionStack.spacing = 8
        container.addSubview(actionStack)
        actionStack.snp.makeConstraints { make in
            make.top.equalTo(shadowBlock.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
        }

        // 两个一行摆动作按钮
        for index in stride(from: 0, to: actionTitles.count, by: 2) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.distribution = .fillEqually
            actionStack.addArrangedSubview(rowStack)

            for subIndex in index...min(index + 1, actionTitles.count - 1) {
                let actionButton = UIButton(type: .system)
                actionButton.setTitle(actionTitles[subIndex], for: .normal)
                actionButton.titleLabel?.font = .systemFont(ofSize: 12)
                actionButton.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
                actionButton.layer.cornerRadius = 6
                actionButton.addTarget(self, action: actionSelectors[subIndex], for: .touchUpInside)
                rowStack.addArrangedSubview(actionButton)
                actionButton.snp.makeConstraints { make in
                    make.height.equalTo(36)
                }
            }
        }

        let lateCaption = UILabel()
        lateCaption.font = .systemFont(ofSize: 11)
        lateCaption.textColor = .darkGray
        lateCaption.numberOfLines = 0
        lateCaption.text = "先应用后上树槽位(点'先应用后上树'，视图在没加到父视图前就调了wy_showVisual，之后才加进来，全套视觉应完整生效)"
        container.addSubview(lateCaption)
        lateCaption.snp.makeConstraints { make in
            make.top.equalTo(actionStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
        }

        lateMountSlot.layer.borderWidth = 1
        lateMountSlot.layer.borderColor = UIColor.lightGray.cgColor
        lateMountSlot.layer.cornerRadius = 8
        lateMountSlot.clipsToBounds = true
        container.addSubview(lateMountSlot)
        lateMountSlot.snp.makeConstraints { make in
            make.top.equalTo(lateCaption.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(70)
            make.bottom.equalToSuperview()
        }
        return container
    }

    /// 大按钮的完整链式视觉
    private func applyBigButtonVisual() {
        bigButton.wy_gradualColors([.orange, .red]).wy_gradientDirection(.topToBottom).wy_cornerRadius(20).wy_borderWidth(8).wy_borderColor(.purple).wy_rectCorner(.allCorners).wy_shadowColor(.black).wy_shadowRadius(10).wy_shadowOpacity(0.5).wy_showVisual()
    }

    /// 阴影块的初始视觉(特意不带圆角，验证阴影挂在自身矩形shadowPath上的场景)
    private func applyShadowBlockVisual() {
        shadowBlock.wy_shadowColor(.black).wy_shadowRadius(10).wy_shadowOpacity(0.6).wy_showVisual()
    }

    private func refreshStatus() {
        let edgeText = edgeBorderRemoved ? "已移除" : "厚度\(Int(edgeThicknesses[borderIndex]))"
        let transformText = isRotated ? "旋转45度" : (isScaled ? "缩放0.7" : "无形变")
        let shadowText = "阴影块\(shadowBlockHasRadius ? "圆角" : "直角")x\(shadowBlockBig ? 150 : 100)\(shadowBlockHasChild ? "+子视图" : "")(极端半径\(Int(extremeRadii[extremeIndex])))"
        statusLabel.text = "已应用\(applyCount)次 · 指定边框\(edgeText) · 当前尺寸\(isNarrow ? "减宽" : "全宽")x\(isBigSize ? 150 : 110) · \(transformText) · \(isOffset ? "位移80" : "未位移") · \(shadowText)"
    }

    @objc private func toggleSize() {
        isBigSize = !isBigSize
        // 验证动画同步:动画上下文里改约束并强制布局，view本体和圆角、边框、渐变、阴影应以相同时长一起过渡
        UIView.animate(withDuration: 0.25) {
            self.bigButton.snp.updateConstraints { make in
                make.height.equalTo(self.isBigSize ? 150 : 110)
            }
            self.view.layoutIfNeeded()
        }
        refreshStatus()
    }

    @objc private func togglePosition() {
        isOffset = !isOffset
        // 验证位移同步:动画上下文里只改水平位置不改尺寸，渐变、边框、阴影背景视图应整体一起平移
        UIView.animate(withDuration: 0.4) {
            self.bigButton.snp.updateConstraints { make in
                make.centerX.equalToSuperview().offset(self.isOffset ? 80 : 0)
            }
            self.view.layoutIfNeeded()
        }
        refreshStatus()
    }

    @objc private func toggleRotation() {
        isRotated = !isRotated
        isScaled = false
        // 验证形变同步:transform旋转45度，圆角、边框、渐变是子图层天然跟着转，阴影背景视图靠库内部同步transform跟转
        UIView.animate(withDuration: 0.4) {
            self.bigButton.transform = self.isRotated ? CGAffineTransform(rotationAngle: .pi / 4) : .identity
        }
        refreshStatus()
    }

    @objc private func toggleScale() {
        isScaled = !isScaled
        isRotated = false
        // 验证形变同步:transform整体缩放0.7，全部视觉图层应一起缩放不变形
        UIView.animate(withDuration: 0.4) {
            self.bigButton.transform = self.isScaled ? CGAffineTransform(scaleX: 0.7, y: 0.7) : .identity
        }
        refreshStatus()
    }

    @objc private func toggleWidth() {
        isNarrow = !isNarrow
        // 验证宽度跟随:动画上下文里只改宽度，左右边框、渐变、阴影路径应同时收缩不拉伸
        UIView.animate(withDuration: 0.25) {
            self.bigButton.snp.updateConstraints { make in
                make.width.equalToSuperview().offset(self.isNarrow ? -120 : 0)
            }
            self.view.layoutIfNeeded()
        }
        refreshStatus()
    }

    @objc private func snapSize() {
        // 验证无动画直切:不在动画上下文里改尺寸，视觉图层应一步到位且不闪帧
        isBigSize = !isBigSize
        bigButton.snp.updateConstraints { make in
            make.height.equalTo(isBigSize ? 150 : 110)
        }
        view.layoutIfNeeded()
        refreshStatus()
    }

    @objc private func slowToggleSize() {
        // 验证动画中断接力:2秒慢动画途中再点会反向，视觉图层应从当前屏显位置无缝接上不跳变
        isBigSize = !isBigSize
        UIView.animate(withDuration: 2.0) {
            self.bigButton.snp.updateConstraints { make in
                make.height.equalTo(self.isBigSize ? 150 : 110)
            }
            self.view.layoutIfNeeded()
        }
        refreshStatus()
    }

    @objc private func toggleShadowBlockRadius() {
        shadowBlockHasRadius = !shadowBlockHasRadius
        // 验证阴影挂载迁移:无圆角(阴影挂自身矩形shadowPath)和有圆角(阴影挂背景视图)来回切，不应出现双阴影、残影或闪烁
        shadowBlock.wy_cornerRadius(shadowBlockHasRadius ? 20 : 0).wy_showVisual()
        refreshStatus()
    }

    @objc private func toggleShadowBlockSize() {
        shadowBlockBig = !shadowBlockBig
        // 验证自身矩形shadowPath的动画同步:动画上下文里改高度，阴影应和本体同拍伸缩不跳变
        UIView.animate(withDuration: 0.45) {
            self.shadowBlock.snp.updateConstraints { make in
                make.height.equalTo(self.shadowBlockBig ? 150 : 100)
            }
            self.view.layoutIfNeeded()
        }
        refreshStatus()
    }

    @objc private func cycleShadowBlockRadius() {
        // 验证极端值钳制:负数、常规、超过短边一半的半径轮换，路径不畸形不崩溃，阴影挂载也跟着正确迁移
        extremeIndex = (extremeIndex + 1) % extremeRadii.count
        shadowBlock.wy_cornerRadius(extremeRadii[extremeIndex]).wy_showVisual()
        shadowBlockHasRadius = extremeRadii[extremeIndex] > 0
        refreshStatus()
    }

    @objc private func clearAndReapplyNow() {
        // 验证同帧清除重建(骚操作):清除后立刻重新应用，排队任务合并执行后效果应完整恢复不缺项(含指定位置边框，防重建后边框缺失被误判成库的问题)
        bigButton.wy_clearVisual()
        bigButton.wy_removeBorder(edges: .all)
        applyBigButtonVisual()
        bigButton.wy_addBorder(edges: .all, color: .magenta, thickness: edgeThicknesses[borderIndex])
        edgeBorderRemoved = false
        applyCount += 1
        refreshStatus()
    }

    @objc private func sameFrameEdgeBorders() {
        // 验证同帧连设四条边(骚操作):四次调用应合并成一个任务、同一条边原地复用图层，最终四边各自厚度颜色正确且无闪烁
        sameFrameThick.toggle()
        let color: UIColor = sameFrameThick ? .systemBlue : .magenta
        let thickness: CGFloat = sameFrameThick ? 10 : 6
        bigButton.wy_addBorder(edges: .top, color: color, thickness: thickness)
        bigButton.wy_addBorder(edges: .left, color: color, thickness: thickness + 2)
        bigButton.wy_addBorder(edges: .right, color: color, thickness: thickness + 4)
        bigButton.wy_addBorder(edges: .bottom, color: color, thickness: thickness + 6)
        edgeBorderRemoved = false
        refreshStatus()
    }

    @objc private func slowToggleAndReapply() {
        // 验证动画中改配置重应用:2秒慢动画进行到一半时换边框宽度和渐变色再重新应用，各图层应从当前屏显位置无缝接力到新配置，不跳变不多出短动画
        slowToggleSize()
        Task {
            try? await Task.wy_delay(0.7, cancelThrows: false, onMain: { [weak self] in
                guard let self = self else { return }
                self.midFlightThick.toggle()
                self.bigButton.wy_borderWidth(self.midFlightThick ? 8 : 3).wy_gradualColors(self.midFlightThick ? [.orange, .red] : [.purple, .blue]).wy_showVisual()
                self.applyCount += 1
                self.refreshStatus()
            })
        }
    }

    @objc private func clearOnly() {
        // 验证纯清除:清除后不重建，视觉应完全回到裸视图(无mask无图层无阴影背景视图)，再点其它应用按钮能从零完整重建
        bigButton.wy_clearVisual()
        bigButton.wy_removeBorder(edges: .all)
        edgeBorderRemoved = true
        refreshStatus()
    }

    @objc private func toggleShadowBlockChild() {
        // 验证矩形shadowPath和轮廓阴影的自动迁移:加子视图后重应用，内容不再铺满矩形应切回轮廓阴影(子视图伸出左边界，阴影形状跟着变宽)；移除后重应用应切回矩形shadowPath，来回无残留
        shadowBlockHasChild.toggle()
        if shadowBlockHasChild {
            shadowBlock.addSubview(shadowBlockChild)
        }else {
            shadowBlockChild.removeFromSuperview()
        }
        shadowBlock.wy_showVisual()
        refreshStatus()
    }

    @objc private func applyThenMount() {
        // 验证先应用后上树(骚操作):视图还没加到父视图就调wy_showVisual，之后才加进槽位，全套视觉应完整生效(任务延后一拍取尺寸的设计)，且上树第一帧不应闪过无圆角的原始方块(同步预应用会先用空路径mask把原始背景藏住)
        lateMountSlot.subviews.forEach { $0.removeFromSuperview() }
        let lateView = UIView()
        lateView.backgroundColor = UIColor.systemIndigo
        lateView.wy_cornerRadius(16).wy_borderWidth(4).wy_borderColor(.white).wy_shadowColor(.black).wy_shadowRadius(6).wy_shadowOpacity(0.5).wy_gradualColors([.yellow, .systemPink]).wy_showVisual()
        lateMountSlot.addSubview(lateView)
        lateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.7)
            make.height.equalTo(44)
        }
    }

    @objc private func reapplyVisual() {
        applyBigButtonVisual()
        applyCount += 1
        refreshStatus()
    }

    @objc private func clearAndReapply() {
        bigButton.wy_clearVisual()
        bigButton.wy_removeBorder(edges: .all)
        Task {
            try? await Task.wy_delay(0.6, cancelThrows: false, onMain: { [weak self] in
                guard let self = self else { return }
                self.applyBigButtonVisual()
                self.edgeBorderRemoved = false
                self.bigButton.wy_addBorder(edges: .all, color: .magenta, thickness: self.edgeThicknesses[self.borderIndex])
                self.applyCount += 1
                self.refreshStatus()
            })
        }
    }

    @objc private func cycleEdgeBorder() {
        borderIndex = (borderIndex + 1) % edgeThicknesses.count
        edgeBorderRemoved = false
        bigButton.wy_addBorder(edges: .all, color: .magenta, thickness: edgeThicknesses[borderIndex])
        refreshStatus()
    }

    @objc private func removeEdgeBorder() {
        edgeBorderRemoved = true
        bigButton.wy_removeBorder(edges: .all)
        refreshStatus()
    }
}
