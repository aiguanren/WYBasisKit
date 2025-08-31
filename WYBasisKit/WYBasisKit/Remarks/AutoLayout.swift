//
//  AutoLayout.swift
//  AutoLayout速查表
//
//  Created by guanren on 2025/8/28.
//

import UIKit

class AutoLayout: UIViewController {
    
    let redView = UIView()
    let blueView = UIView()
    let greenView = UIView()
    let label = UILabel()
    
    // ===========================
    // ✅ 可更新的约束引用（保存引用，方便后续修改）
    // ===========================
    private var redViewWidthConstraint: NSLayoutConstraint!
    private var redViewHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        redView.backgroundColor = .red
        blueView.backgroundColor = .blue
        greenView.backgroundColor = .green
        label.text = "我是一个测试标签"
        label.numberOfLines = 0
        label.backgroundColor = .yellow
        
        // 添加子视图
        [redView, blueView, greenView, label].forEach {
            // ❗ 必须关闭 AutoresizingMask 转约束
            // 否则系统会把 autoresizingMask 自动生成约束，和我们手动添加的 Auto Layout 约束冲突
            // 具体原因：autoresizingMask 会被 UIKit 转换为一组自动生成的 NSLayoutConstraint，
            // 当我们再手动添加约束时两者会出现重复或不一致导致“约束冲突”的运行时警告/错误。
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // ===========================
        // ⚡ 名词解释（常见 Anchor）
        // ===========================
        /*
         leadingAnchor   : 左/前边（随语言方向变化）
         - 在大多数从左到右 (LTR) 的语言环境下 = left（通常是“左边”）
         - 在少数从右到左 (RTL) 的语言环境下 = right（例如阿拉伯语、希伯来语）
         - 推荐用于国际化布局（支持 RTL 的自动翻转）
        trailingAnchor  : 右/后边（与 leading 相反，也会随语言方向变化）
         leftAnchor      : 固定的左边（物理左边，**不随语言方向变化**）
         rightAnchor     : 固定的右边（物理右边，**不随语言方向变化**）
         topAnchor       : 顶部（垂直方向上的上边）
         bottomAnchor    : 底部（垂直方向上的下边）
         widthAnchor     : 宽度（NSLayoutDimension）
         heightAnchor    : 高度（NSLayoutDimension）
         centerXAnchor   : 水平方向中心点（用于水平居中）
         centerYAnchor   : 垂直方向中心点（用于垂直居中）
         firstBaselineAnchor  : 文本第一行的基线（用于 UILabel/UITextField 等文字对齐）
         lastBaselineAnchor   : 文本最后一行的基线（多行文本最后一行）
         
         safeAreaLayoutGuide      : 安全区域（避开状态栏、刘海、Home Indicator）
         layoutMarginsGuide       : 视图内部的布局边距（系统默认通常为 8~16pt，根据容器而定）
         readableContentGuide     : 可读区域（用于大屏幕时限制文本宽度，提升可读性）
         */
        
        // ===========================
        // ✅ 开始添加约束
        // ===========================
        
        // redView 宽度 = 150（固定宽度）
        redViewWidthConstraint = redView.widthAnchor.constraint(equalToConstant: 150)
        // redView 高度 = 150（固定高度）
        redViewHeightConstraint = redView.heightAnchor.constraint(equalToConstant: 150)
        
        NSLayoutConstraint.activate([
            
            // ===========================
            // ✅ 居中约束
            // ===========================
            // redView 在父视图 X 轴居中（水平中心对齐父视图中心）
            redView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // redView 在父视图 Y 轴居中（垂直中心对齐父视图中心）
            redView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // ===========================
            // ✅ 固定尺寸约束（保存引用，便于更新）
            // ===========================
            redViewWidthConstraint,
            redViewHeightConstraint,
            
            // ===========================
            // ✅ 相对于安全区
            // ===========================
            // blueView 顶部 = 安全区顶部 + 20（避免被状态栏/刘海遮挡）
            blueView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            // blueView 左边 = 安全区左边 + 20（使用 safeArea 的 leading）
            blueView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            // blueView 右边 = 安全区右边 - 20（使用 safeArea 的 trailing）
            blueView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            // blueView 高度 = 100（条状控件示例）
            blueView.heightAnchor.constraint(equalToConstant: 100),
            
            // ===========================
            // ✅ 相对其他视图
            // ===========================
            // greenView 顶部 = blueView 底部 + 12（将 green 放在 blue 下方并留 12pt 间距）
            greenView.topAnchor.constraint(equalTo: blueView.bottomAnchor, constant: 12),
            // greenView 左边对齐 blueView（确保左右边界一致）
            greenView.leadingAnchor.constraint(equalTo: blueView.leadingAnchor),
            // greenView 右边对齐 blueView（确保左右边界一致）
            greenView.trailingAnchor.constraint(equalTo: blueView.trailingAnchor),
            // greenView 高度 = 44（常见按钮/行高）
            greenView.heightAnchor.constraint(equalToConstant: 44),
            
            // ===========================
            // ✅ 宽高比
            // ===========================
            // redView 高度 = 宽度 * 0.5（将 red 设为宽高比 2:1，即宽是高的两倍）
            redView.heightAnchor.constraint(equalTo: redView.widthAnchor, multiplier: 0.5),
            
            // ===========================
            // ✅ 大于/小于等于（范围限制）
            // ===========================
            // greenView 宽度 ≥ 100（最小宽度，保证控件不会太窄）
            greenView.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            // greenView 宽度 ≤ 300（最大宽度，限制过宽）
            greenView.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            
            // ===========================
            // ✅ 系统推荐间距（iOS 11+）
            // ===========================
            // greenView.leading = redView.trailing + 系统推荐间距 × 1（使用平台推荐间距）
            greenView.leadingAnchor.constraint(equalToSystemSpacingAfter: redView.trailingAnchor, multiplier: 1.0),
            // greenView.top ≥ redView.bottom + 系统推荐间距 × 2（示例：至少跟上一个控件保持系统推荐的两倍间距）
            greenView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: redView.bottomAnchor, multiplier: 2.0),
            
            // ===========================
            // ✅ layoutMarginsGuide（使用容器内边距，使控件不紧贴屏幕边缘）
            // ===========================
            // label 左边 = 父视图 layoutMargins 左边（遵循容器内边距）
            label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            // label 右边 = 父视图 layoutMargins 右边（遵循容器内边距）
            label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            
            // ===========================
            // ✅ readableContentGuide（用于文本宽度限制，尤其在 iPad 上）
            // ===========================
            // label 左边 ≥ readableContentGuide 左边（确保在大屏上不超过可读区域左边界）
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.readableContentGuide.leadingAnchor),
            // label 右边 ≤ readableContentGuide 右边（确保在大屏上不超过可读区域右边界）
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.readableContentGuide.trailingAnchor),
            
            // ===========================
            // ✅ 文本基线（仅文本控件可用）
            // ===========================
            // label 第一行基线 与 redView 顶部对齐（示例：把标签的第一行基线对齐到 redView 顶部位置 + 20）
            label.firstBaselineAnchor.constraint(equalTo: redView.topAnchor, constant: 20),
            // label 最后一行基线 ≤ redView 底部 - 20（示例：最后一行不超过 redView 底部 - 20）
            label.lastBaselineAnchor.constraint(lessThanOrEqualTo: redView.bottomAnchor, constant: -20),
        ])
        
        // ===========================
        // ✅ 约束优先级（Priority）
        // ===========================
        // greenView 高度 = 60，优先级 750（低于默认 1000），表示系统在冲突时可以放弃它
        let flexibleHeight = greenView.heightAnchor.constraint(equalToConstant: 60)
        flexibleHeight.priority = UILayoutPriority(750) // 默认 1000（required）
        flexibleHeight.isActive = true
        
        
        // ====================================================
        // 更多设置约束的示例
        // ====================================================
        
        // 创建示例视图
        let demoA = UIView()         // 用来演示“按父视图比例宽度、固定高度”
        let demoB = UIView()         // 用来演示“系统间距、等宽等高”
        let demoText1 = UILabel()    // 用来演示基线对齐
        let demoText2 = UILabel()    // 用来演示基线对齐
        demoA.backgroundColor = .systemPurple
        demoB.backgroundColor = .systemOrange
        demoText1.text = "第一行文字"
        demoText2.text = "第二行较长的文字用于对齐"
        demoText1.backgroundColor = .clear
        demoText2.backgroundColor = .clear
        demoText1.translatesAutoresizingMaskIntoConstraints = false
        demoText2.translatesAutoresizingMaskIntoConstraints = false
        demoA.translatesAutoresizingMaskIntoConstraints = false
        demoB.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(demoA)
        view.addSubview(demoB)
        view.addSubview(demoText1)
        view.addSubview(demoText2)
        
        // 使用 UILayoutGuide 保留底部区域（示例：为底部工具条预留空间）
        let bottomGuide = UILayoutGuide()
        view.addLayoutGuide(bottomGuide)
        
        NSLayoutConstraint.activate([
            // ---------------------------
            // 演示：把 demoA 固定在 label 下方并与 layoutMargins 对齐
            // ---------------------------
            // demoA 顶部 = label 底部 + 16（把 demoA 放在 label 下方）
            demoA.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
            // demoA 左边 = 父视图 layoutMarginsGuide.left（使用容器边距，而不是直接使用 superview.left）
            demoA.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            // demoA 高度 = 60（固定高度，用于条状控件）
            demoA.heightAnchor.constraint(equalToConstant: 60),
            // demoA 宽度 = 父视图宽度 * 0.5（示例：宽度为屏幕一半）
            demoA.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            
            // ---------------------------
            // 演示：system spacing 与等宽/等高
            // ---------------------------
            // demoB.leading = demoA.trailing + 系统推荐间距 × 1（把 demoB 放在 demoA 右侧并使用系统推荐间距）
            demoB.leadingAnchor.constraint(equalToSystemSpacingAfter: demoA.trailingAnchor, multiplier: 1.0),
            // demoB.centerY = demoA.centerY（垂直居中对齐两个控件）
            demoB.centerYAnchor.constraint(equalTo: demoA.centerYAnchor),
            // demoB 宽度 = demoA 宽度（两个控件等宽）
            demoB.widthAnchor.constraint(equalTo: demoA.widthAnchor),
            // demoB 高度 = demoA 高度（两个控件等高）
            demoB.heightAnchor.constraint(equalTo: demoA.heightAnchor),
            
            // ---------------------------
            // 演示：基线对齐（适用于文本控件）
            // ---------------------------
            // demoText1 第一行基线 = demoA 顶部 + 12（示例：将文本基线放置在 demoA 内特定位置）
            // 注意：基线约束只能用于文本视图（UILabel/UITextField/UITextView），demoA 不是文本控件，
            // 这里我们只是演示基线相对“安全/示例”位置，如果要严格对齐请用两个 Label 之间的 firstBaselineAnchor。
            demoText1.topAnchor.constraint(equalTo: demoA.topAnchor, constant: 12),
            // demoText2 第一行基线 = demoText1 第一行基线（使两个 label 的首行基线对齐）
            demoText2.firstBaselineAnchor.constraint(equalTo: demoText1.firstBaselineAnchor),
            // demoText1 左对齐 demoA（文本贴近那个紫色块）
            demoText1.leadingAnchor.constraint(equalTo: demoA.leadingAnchor, constant: 8),
            // demoText2 左边放到 demoText1 的右侧并留 12 间距（演示水平排列）
            demoText2.leadingAnchor.constraint(equalToSystemSpacingAfter: demoText1.trailingAnchor, multiplier: 1.0),
            
            // ---------------------------
            // 演示：UILayoutGuide 用法（底部预留区域）
            // ---------------------------
            // bottomGuide 左右贴合父视图 layoutMargins（把 guide 放在父视图内边距范围内）
            bottomGuide.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            bottomGuide.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            // bottomGuide 底部 = safeArea 底部 - 12（距离底部安全区 12）
            bottomGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            // bottomGuide 高度 = 60（为底部工具条或菜单预留 60pt 高度）
            bottomGuide.heightAnchor.constraint(equalToConstant: 60),
            
            // ---------------------------
            // 演示：使用 readableContentGuide 限制文本最大宽度（提高可读性）
            // ---------------------------
            // demoText1 右边 ≤ readableContentGuide 右边（确保在 iPad 上文本不会过宽）
            demoText1.trailingAnchor.constraint(lessThanOrEqualTo: view.readableContentGuide.trailingAnchor),
        ])
        
        // ===========================
        // ✅ 动态更新约束示例
        // ===========================
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 修改 redView 宽高
            self.redViewWidthConstraint.constant = 220
            self.redViewHeightConstraint.constant = 120
            
            // ⚡ 使用动画更新布局（调用 layoutIfNeeded 会强制刷新布局）
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
        
        // ---------------------------
        // 激活/失活（deactivate）示例
        // ---------------------------
        // 创建一个临时高度约束并激活，然后演示如何失活（释放）
        let tempHeight = demoB.heightAnchor.constraint(equalToConstant: 40)
        tempHeight.isActive = true // 激活后 demoB 高度为 40（可能会与之前的等高约束产生冲突）
        // 为避免冲突，我们马上降级并替换（演示如何 deactivate）
        NSLayoutConstraint.deactivate([tempHeight]) // 失活：解除约束控制（示例用途）
        
        // ---------------------------
        // 说明总结（注释清晰说明目的）
        // ---------------------------
        // - demoA: 演示按父视图比例设宽 + 固定高（适合图片或响应式卡片）
        // - demoB: 演示系统间距 + 等宽等高（用于左右并排控件）
        // - demoText1/demoText2: 演示基线对齐（用于多标签文本对齐）
        // - bottomGuide: 演示 UILayoutGuide 的预留区域用法（适合底部工具条/浮层）
        // - legacy: 演示旧式 NSLayoutConstraint 构造器（历史代码兼容或复杂表达式时可用）
        // - demoAWidthConstraint 动画示例：展示如何在运行时平滑修改约束
        // - tempHeight deactivate 示例：展示如何移除不再需要的约束
    }
}
