//
//  WYTestPagingViewController.swift
//  SwiftVerify
//
//  Created by guanren on 2025/9/3.
//

import UIKit

// MARK: - 显示模式枚举
enum DisplayMode: String, CaseIterable {
    case textOnly = "仅文本"
    case imageOnly = "仅图片"
    case both = "图片+文本"
}

// MARK: - 主测试控制器
class WYTestPagingViewController: UIViewController {
    
    private var pagingView: WYPagingView?
    private var settingsButton: UIBarButtonItem!
    private var settings = PagingSettingsModel()
    
    /// 测试用的子控制器数组（固定5个）
    private let testControllers: [UIViewController] = {
        let colors: [UIColor] = [.red, .green, .blue, .yellow, .purple, .orange, .cyan, .magenta]
        return colors.prefix(5).map { color in
            let vc = UIViewController()
            vc.view.backgroundColor = color
            vc.view.layer.borderWidth = 2
            vc.view.layer.borderColor = UIColor.black.cgColor
            return vc
        }
    }()
    
    /// 测试用的标题数组
    private let testTitles = ["首页", "消息", "发现", "我的", "设置"]
    
    /// 测试用的未选中图片数组
    private let testDefaultImages: [UIImage] = [
        UIImage(systemName: "house")!,
        UIImage(systemName: "message")!,
        UIImage(systemName: "magnifyingglass")!,
        UIImage(systemName: "person")!,
        UIImage(systemName: "gearshape")!
    ]
    
    /// 测试用的选中图片数组
    private let testSelectedImages: [UIImage] = [
        UIImage(systemName: "house.fill")!,
        UIImage(systemName: "message.fill")!,
        UIImage(systemName: "magnifyingglass.circle.fill")!,
        UIImage(systemName: "person.fill")!,
        UIImage(systemName: "gearshape.fill")!
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupInitialPagingView()
    }
    
    private func setupNavigationBar() {
        title = "WYPagingView 测试"
        view.backgroundColor = .white
        
        settingsButton = UIBarButtonItem(
            title: "设置",
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
        navigationItem.rightBarButtonItem = settingsButton
        
        self.wy_navBarBackgroundColor = .orange
    }
    
    private func setupInitialPagingView() {
        pagingView?.removeFromSuperview()
        pagingView = nil
        
        let newPagingView = WYPagingView()
        view.addSubview(newPagingView)
        
        newPagingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newPagingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            newPagingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newPagingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newPagingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        applySettings(to: newPagingView)
        
        // 根据显示模式决定传入的参数
        let (titles, defaultImages, selectedImages) = resolveDisplayModeParameters()
        newPagingView.layout(
            controllers: testControllers,
            titles: titles,
            defaultImages: defaultImages,
            selectedImages: selectedImages,
            superViewController: self
        )
        
        pagingView = newPagingView
    }
    
    /// 根据显示模式返回对应的 titles 和 images 数组
    private func resolveDisplayModeParameters() -> ([String], [UIImage], [UIImage]) {
        switch settings.displayMode {
        case .textOnly:
            return (testTitles, [], [])
        case .imageOnly:
            return ([], testDefaultImages, testSelectedImages)
        case .both:
            return (testTitles, testDefaultImages, testSelectedImages)
        }
    }
    
    private func applySettings(to pagingView: WYPagingView) {
        // 基本属性
        pagingView.bar_height = settings.barHeight
        pagingView.buttonPosition = settings.buttonPosition
        pagingView.bar_originlLeftOffset = settings.originlLeftOffset
        pagingView.bar_originlRightOffset = settings.originlRightOffset
        pagingView.bar_itemTopOffset = settings.itemTopOffset
        pagingView.bar_adjustOffset = settings.adjustOffset
        pagingView.bar_dividingOffset = settings.dividingOffset
        pagingView.barButton_dividingOffset = settings.buttonDividingOffset
        
        // 颜色设置
        pagingView.bar_pagingContro_content_color = settings.pagingContentColor
        pagingView.bar_pagingContro_bg_color = settings.pagingBgColor
        pagingView.bar_bg_defaultColor = settings.barBgColor
        pagingView.bar_item_bg_defaultColor = settings.itemDefaultBgColor
        pagingView.bar_item_bg_selectedColor = settings.itemSelectedBgColor
        pagingView.bar_title_defaultColor = settings.titleDefaultColor
        pagingView.bar_title_selectedColor = settings.titleSelectedColor
        pagingView.bar_dividingStripColor = settings.dividingStripColor
        pagingView.bar_scrollLineColor = settings.scrollLineColor
        
        // 图片资源
        pagingView.bar_dividingStripImage = settings.dividingStripImage
        pagingView.bar_scrollLineImage = settings.scrollLineImage
        
        // 尺寸设置
        pagingView.bar_item_width = settings.itemWidth
        pagingView.bar_item_height = settings.itemHeight
        pagingView.bar_item_cornerRadius = settings.itemCornerRadius
        pagingView.bar_scrollLineWidth = settings.scrollLineWidth
        pagingView.bar_scrollLineBottomOffset = settings.scrollLineBottomOffset
        pagingView.bar_dividingStripHeight = settings.dividingStripHeight
        pagingView.bar_scrollLineHeight = settings.scrollLineHeight
        
        // 新增属性
        pagingView.bar_scrollLineFollowFinger = settings.scrollLineFollowFinger
        pagingView.bar_item_insideMargins = settings.itemInsideMargins
        pagingView.bar_item_imageViewSize = settings.itemImageViewSize
        
        // 字体设置
        pagingView.bar_title_defaultFont = settings.titleDefaultFont
        pagingView.bar_title_selectedFont = settings.titleSelectedFont
        
        // 其他设置
        pagingView.bar_selectedIndex = settings.selectedIndex
        pagingView.canScrollController = settings.canScrollController
        pagingView.canScrollBar = settings.canScrollBar
        pagingView.bar_pagingContro_bounce = settings.pagingBounce
        
        // 代理和闭包
        pagingView.delegate = self
        pagingView.itemDidScroll { pagingView, pagingIndex, isFirstDisplayed in
            print("分页滚动到第 \(pagingIndex) 页 - 通过闭包回调")
        }
        pagingView.itemDidLayout { pagingView in
            print("分页视图布局完成 - 闭包回调")
        }
    }
    
    @objc private func showSettings() {
        let settingsVC = PagingSettingsViewController(settings: settings)
        settingsVC.delegate = self
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    deinit {
        print("WYTestPagingViewController deinit")
    }
}

// MARK: - WYPagingViewDelegate
extension WYTestPagingViewController: WYPagingViewDelegate {
    func wy_pagingViewItemDidScroll(_ pagingView: WYPagingView, pagingIndex: Int, isFirstDisplayed: Bool) {
        print("分页滚动到第 \(pagingIndex) 页 - 通过代理回调, \(isFirstDisplayed ? "是" : "不是")第一次显示该页面")
    }
    
    func wy_pagingViewLayoutDidCompleted(_ pagingView: WYPagingView) {
        print("分页视图布局完成 - 代理回调")
    }
}

// MARK: - PagingSettingsDelegate
extension WYTestPagingViewController: PagingSettingsDelegate {
    func didSaveSettings(_ settings: PagingSettingsModel) {
        self.settings = settings
        setupInitialPagingView()
        dismiss(animated: true)
    }
    
    func didCancelSettings() {
        dismiss(animated: true)
    }
}

// MARK: - 设置数据模型
struct PagingSettingsModel {
    // 显示模式
    var displayMode: DisplayMode = .both
    
    // 基本属性
    var barHeight: CGFloat = 65
    var buttonPosition: WYButtonPosition = .imageTopTitleBottom
    var originlLeftOffset: CGFloat = 0
    var originlRightOffset: CGFloat = 0
    var itemTopOffset: CGFloat? = nil
    var adjustOffset: Bool = true
    var dividingOffset: CGFloat = 20
    var buttonDividingOffset: CGFloat = 5
    
    // 颜色
    var pagingContentColor: UIColor = .white
    var pagingBgColor: UIColor? = nil
    var barBgColor: UIColor = .white
    var itemDefaultBgColor: UIColor = .white
    var itemSelectedBgColor: UIColor = .white
    var titleDefaultColor: UIColor = .wy_hex("#7B809E")
    var titleSelectedColor: UIColor = .wy_hex("#2D3952")
    var dividingStripColor: UIColor = .wy_hex("#F2F2F2")
    var scrollLineColor: UIColor = .wy_hex("#2D3952")
    
    // 图片资源
    var dividingStripImage: UIImage? = nil
    var scrollLineImage: UIImage? = nil
    
    // 尺寸
    var itemWidth: CGFloat = 0
    var itemHeight: CGFloat = 0
    var itemCornerRadius: CGFloat = 0
    var scrollLineWidth: CGFloat = 25
    var scrollLineBottomOffset: CGFloat = 5
    var dividingStripHeight: CGFloat = 2
    var scrollLineHeight: CGFloat = 2
    
    // 新增属性
    var scrollLineFollowFinger: Bool = true
    var itemInsideMargins: UIEdgeInsets = .zero
    var itemImageViewSize: CGSize = .zero
    
    // 字体
    var titleDefaultFont: UIFont = UIFont.systemFont(ofSize: 15)
    var titleSelectedFont: UIFont = UIFont.boldSystemFont(ofSize: 15)
    
    // 其他
    var selectedIndex: Int = 0
    var canScrollController: Bool = true
    var canScrollBar: Bool = true
    var pagingBounce: Bool = true
}

// MARK: - 设置页面协议
protocol PagingSettingsDelegate: AnyObject {
    func didSaveSettings(_ settings: PagingSettingsModel)
    func didCancelSettings()
}

// MARK: - 设置页面控制器
class PagingSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var settings: PagingSettingsModel
    weak var delegate: PagingSettingsDelegate?
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    private let sections = [
        "显示模式",
        "基本属性",
        "颜色设置",
        "尺寸设置",
        "高级属性",
        "字体设置",
        "其他设置"
    ]
    
    private let items: [[(String, String)]] = [
        // 显示模式
        [("显示模式", "displayMode")],
        
        // 基本属性
        [
            ("分页栏高度", "barHeight"),
            ("按钮位置", "buttonPosition"),
            ("左偏移量", "originlLeftOffset"),
            ("右偏移量", "originlRightOffset"),
            ("Item顶部偏移", "itemTopOffset"),
            ("居中调整", "adjustOffset"),
            ("分栏间距", "dividingOffset"),
            ("按钮内间距", "buttonDividingOffset")
        ],
        
        // 颜色设置
        [
            ("页面内容颜色", "pagingContentColor"),
            ("页面背景颜色", "pagingBgColor"),
            ("分页栏背景色", "barBgColor"),
            ("Item默认背景", "itemDefaultBgColor"),
            ("Item选中背景", "itemSelectedBgColor"),
            ("标题默认颜色", "titleDefaultColor"),
            ("标题选中颜色", "titleSelectedColor"),
            ("分隔带颜色", "dividingStripColor"),
            ("滑动线颜色", "scrollLineColor")
        ],
        
        // 尺寸设置
        [
            ("Item宽度", "itemWidth"),
            ("Item高度", "itemHeight"),
            ("Item圆角", "itemCornerRadius"),
            ("滑动线宽度", "scrollLineWidth"),
            ("滑动线底部偏移", "scrollLineBottomOffset"),
            ("分隔带高度", "dividingStripHeight"),
            ("滑动线高度", "scrollLineHeight")
        ],
        
        // 高级属性
        [
            ("滑动线跟随手指", "scrollLineFollowFinger"),
            ("按钮内边距", "itemInsideMargins"),
            ("图片尺寸", "itemImageViewSize")
        ],
        
        // 字体设置
        [
            ("默认字体大小", "titleDefaultFont"),
            ("选中字体大小", "titleSelectedFont")
        ],
        
        // 其他设置
        [
            ("初始选中项", "selectedIndex"),
            ("控制器可滚动", "canScrollController"),
            ("分页栏可滚动", "canScrollBar"),
            ("弹跳效果", "pagingBounce")
        ]
    ]
    
    // 颜色选项
    private let colorOptions: [String: UIColor] = [
        "白色": .white, "黑色": .black, "红色": .red, "绿色": .green,
        "蓝色": .blue, "黄色": .yellow, "橙色": .orange, "紫色": .purple,
        "灰色": .gray, "浅灰色": .lightGray,
        "默认标题色": .wy_hex("#7B809E"), "选中标题色": .wy_hex("#2D3952"),
        "分隔带色": .wy_hex("#F2F2F2"), "滑动线色": .wy_hex("#2D3952")
    ]
    
    init(settings: PagingSettingsModel) {
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        title = "WYPagingView 设置"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelSettings))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .done, target: self, action: #selector(saveSettings))
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        let item = items[indexPath.section][indexPath.row]
        cell.textLabel?.text = item.0
        cell.detailTextLabel?.text = valueDescription(for: item.1)
        cell.accessoryType = .disclosureIndicator
        
        // 颜色预览
        if item.1.contains("Color") {
            let colorView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            colorView.layer.cornerRadius = 4
            colorView.layer.borderWidth = 1
            colorView.layer.borderColor = UIColor.lightGray.cgColor
            colorView.backgroundColor = colorValue(for: item.1)
            cell.accessoryView = colorView
        } else {
            cell.accessoryView = nil
        }
        
        return cell
    }
    
    // MARK: - 辅助方法
    private func valueDescription(for key: String) -> String {
        switch key {
        case "displayMode": return settings.displayMode.rawValue
        case "barHeight": return "\(settings.barHeight)"
        case "buttonPosition":
            switch settings.buttonPosition {
            case .imageLeftTitleRight: return "图片左文字右"
            case .imageRightTitleLeft: return "图片右文字左"
            case .imageTopTitleBottom: return "图片上文字下"
            case .imageBottomTitleTop: return "图片下文字上"
            }
        case "originlLeftOffset": return "\(settings.originlLeftOffset)"
        case "originlRightOffset": return "\(settings.originlRightOffset)"
        case "itemTopOffset": return settings.itemTopOffset?.description ?? "nil"
        case "adjustOffset": return settings.adjustOffset ? "是" : "否"
        case "dividingOffset": return "\(settings.dividingOffset)"
        case "buttonDividingOffset": return "\(settings.buttonDividingOffset)"
        case "pagingContentColor", "pagingBgColor", "barBgColor", "itemDefaultBgColor",
             "itemSelectedBgColor", "titleDefaultColor", "titleSelectedColor",
             "dividingStripColor", "scrollLineColor": return "已设置"
        case "itemWidth": return "\(settings.itemWidth)"
        case "itemHeight": return "\(settings.itemHeight)"
        case "itemCornerRadius": return "\(settings.itemCornerRadius)"
        case "scrollLineWidth": return "\(settings.scrollLineWidth)"
        case "scrollLineBottomOffset": return "\(settings.scrollLineBottomOffset)"
        case "dividingStripHeight": return "\(settings.dividingStripHeight)"
        case "scrollLineHeight": return "\(settings.scrollLineHeight)"
        case "scrollLineFollowFinger": return settings.scrollLineFollowFinger ? "是" : "否"
        case "itemInsideMargins": return "T:\(settings.itemInsideMargins.top) L:\(settings.itemInsideMargins.left) B:\(settings.itemInsideMargins.bottom) R:\(settings.itemInsideMargins.right)"
        case "itemImageViewSize": return "W:\(settings.itemImageViewSize.width) H:\(settings.itemImageViewSize.height)"
        case "titleDefaultFont": return "\(Int(settings.titleDefaultFont.pointSize))"
        case "titleSelectedFont": return "\(Int(settings.titleSelectedFont.pointSize))"
        case "selectedIndex": return "\(settings.selectedIndex)"
        case "canScrollController": return settings.canScrollController ? "是" : "否"
        case "canScrollBar": return settings.canScrollBar ? "是" : "否"
        case "pagingBounce": return settings.pagingBounce ? "是" : "否"
        default: return ""
        }
    }
    
    private func colorValue(for key: String) -> UIColor {
        switch key {
        case "pagingContentColor": return settings.pagingContentColor
        case "pagingBgColor": return settings.pagingBgColor ?? .clear
        case "barBgColor": return settings.barBgColor
        case "itemDefaultBgColor": return settings.itemDefaultBgColor
        case "itemSelectedBgColor": return settings.itemSelectedBgColor
        case "titleDefaultColor": return settings.titleDefaultColor
        case "titleSelectedColor": return settings.titleSelectedColor
        case "dividingStripColor": return settings.dividingStripColor
        case "scrollLineColor": return settings.scrollLineColor
        default: return .clear
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let key = items[indexPath.section][indexPath.row].1
        showEditor(for: key)
    }
    
    private func showEditor(for key: String) {
        switch key {
        case "displayMode":
            let alert = UIAlertController(title: "选择显示模式", message: nil, preferredStyle: .actionSheet)
            for mode in DisplayMode.allCases {
                alert.addAction(UIAlertAction(title: mode.rawValue, style: .default) { _ in
                    self.settings.displayMode = mode
                    self.tableView.reloadData()
                })
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            presentAsPopover(alert, for: key)
            
        case "buttonPosition":
            let alert = UIAlertController(title: "按钮位置", message: nil, preferredStyle: .actionSheet)
            let positions: [WYButtonPosition] = [.imageLeftTitleRight, .imageRightTitleLeft, .imageTopTitleBottom, .imageBottomTitleTop]
            let names = ["图片左文字右", "图片右文字左", "图片上文字下", "图片下文字上"]
            for (idx, name) in names.enumerated() {
                alert.addAction(UIAlertAction(title: name, style: .default) { _ in
                    self.settings.buttonPosition = positions[idx]
                    self.tableView.reloadData()
                })
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            presentAsPopover(alert, for: key)
            
        case "itemTopOffset":
            showOptionalNumberEditor(for: key)
            
        case "itemInsideMargins":
            showEdgeInsetsEditor()
            
        case "itemImageViewSize":
            showSizeEditor()
            
        case "scrollLineFollowFinger":
            let alert = UIAlertController(title: "滑动线跟随手指", message: "当前：\(settings.scrollLineFollowFinger ? "开启" : "关闭")", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "切换", style: .default) { _ in
                self.settings.scrollLineFollowFinger.toggle()
                self.tableView.reloadData()
            })
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            present(alert, animated: true)
            
        case "adjustOffset", "canScrollController", "canScrollBar", "pagingBounce":
            showBoolEditor(for: key)
            
        case "titleDefaultFont", "titleSelectedFont":
            showFontEditor(for: key)
            
        case "selectedIndex":
            showIndexEditor()
            
        default:
            if key.contains("Color") {
                showColorEditor(for: key)
            } else if ["barHeight", "originlLeftOffset", "originlRightOffset", "dividingOffset",
                       "buttonDividingOffset", "itemWidth", "itemHeight", "itemCornerRadius",
                       "scrollLineWidth", "scrollLineBottomOffset", "dividingStripHeight",
                       "scrollLineHeight"].contains(key) {
                showNumberEditor(for: key)
            } else {
                let alert = UIAlertController(title: "提示", message: "该设置项暂不支持编辑", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                present(alert, animated: true)
            }
        }
    }
    
    // MARK: - 各种编辑器
    private func showNumberEditor(for key: String) {
        let alert = UIAlertController(title: "输入数值", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.keyboardType = .decimalPad
            let current: CGFloat
            switch key {
            case "barHeight": current = self.settings.barHeight
            case "originlLeftOffset": current = self.settings.originlLeftOffset
            case "originlRightOffset": current = self.settings.originlRightOffset
            case "dividingOffset": current = self.settings.dividingOffset
            case "buttonDividingOffset": current = self.settings.buttonDividingOffset
            case "itemWidth": current = self.settings.itemWidth
            case "itemHeight": current = self.settings.itemHeight
            case "itemCornerRadius": current = self.settings.itemCornerRadius
            case "scrollLineWidth": current = self.settings.scrollLineWidth
            case "scrollLineBottomOffset": current = self.settings.scrollLineBottomOffset
            case "dividingStripHeight": current = self.settings.dividingStripHeight
            case "scrollLineHeight": current = self.settings.scrollLineHeight
            default: current = 0
            }
            tf.text = "\(current)"
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            if let text = alert.textFields?.first?.text, let val = Double(text) {
                let cgVal = CGFloat(val)
                switch key {
                case "barHeight": self.settings.barHeight = cgVal
                case "originlLeftOffset": self.settings.originlLeftOffset = cgVal
                case "originlRightOffset": self.settings.originlRightOffset = cgVal
                case "dividingOffset": self.settings.dividingOffset = cgVal
                case "buttonDividingOffset": self.settings.buttonDividingOffset = cgVal
                case "itemWidth": self.settings.itemWidth = cgVal
                case "itemHeight": self.settings.itemHeight = cgVal
                case "itemCornerRadius": self.settings.itemCornerRadius = cgVal
                case "scrollLineWidth": self.settings.scrollLineWidth = cgVal
                case "scrollLineBottomOffset": self.settings.scrollLineBottomOffset = cgVal
                case "dividingStripHeight": self.settings.dividingStripHeight = cgVal
                case "scrollLineHeight": self.settings.scrollLineHeight = cgVal
                default: break
                }
                self.tableView.reloadData()
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showOptionalNumberEditor(for key: String) {
        let alert = UIAlertController(title: "输入数值（留空则为nil）", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.keyboardType = .decimalPad
            let current: CGFloat?
            if key == "itemTopOffset" {
                current = self.settings.itemTopOffset
                if let c = current { tf.text = "\(c)" }
            }
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty, let val = Double(text) {
                if key == "itemTopOffset" { self.settings.itemTopOffset = CGFloat(val) }
            } else {
                if key == "itemTopOffset" { self.settings.itemTopOffset = nil }
            }
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showBoolEditor(for key: String) {
        let current: Bool
        switch key {
        case "adjustOffset": current = settings.adjustOffset
        case "canScrollController": current = settings.canScrollController
        case "canScrollBar": current = settings.canScrollBar
        case "pagingBounce": current = settings.pagingBounce
        default: return
        }
        let alert = UIAlertController(title: "切换状态", message: "当前：\(current ? "开启" : "关闭")", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "切换", style: .default) { _ in
            switch key {
            case "adjustOffset": self.settings.adjustOffset.toggle()
            case "canScrollController": self.settings.canScrollController.toggle()
            case "canScrollBar": self.settings.canScrollBar.toggle()
            case "pagingBounce": self.settings.pagingBounce.toggle()
            default: break
            }
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showFontEditor(for key: String) {
        let alert = UIAlertController(title: "输入字体大小", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.keyboardType = .numberPad
            let size = (key == "titleDefaultFont") ? self.settings.titleDefaultFont.pointSize : self.settings.titleSelectedFont.pointSize
            tf.text = "\(Int(size))"
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            if let text = alert.textFields?.first?.text, let size = Int(text) {
                let font = UIFont.systemFont(ofSize: CGFloat(size))
                if key == "titleDefaultFont" {
                    self.settings.titleDefaultFont = font
                } else {
                    self.settings.titleSelectedFont = UIFont.boldSystemFont(ofSize: CGFloat(size))
                }
                self.tableView.reloadData()
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showIndexEditor() {
        let alert = UIAlertController(title: "初始选中项", message: "范围 0-4", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.keyboardType = .numberPad
            tf.text = "\(self.settings.selectedIndex)"
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            if let text = alert.textFields?.first?.text, let idx = Int(text) {
                self.settings.selectedIndex = max(0, min(idx, 4))
                self.tableView.reloadData()
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showEdgeInsetsEditor() {
        let alert = UIAlertController(title: "按钮内边距 (top, left, bottom, right)", message: "当前: \(settings.itemInsideMargins)", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "top"; $0.text = "\(self.settings.itemInsideMargins.top)" }
        alert.addTextField { $0.placeholder = "left"; $0.text = "\(self.settings.itemInsideMargins.left)" }
        alert.addTextField { $0.placeholder = "bottom"; $0.text = "\(self.settings.itemInsideMargins.bottom)" }
        alert.addTextField { $0.placeholder = "right"; $0.text = "\(self.settings.itemInsideMargins.right)" }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            let t = Double(alert.textFields?[0].text ?? "0") ?? 0
            let l = Double(alert.textFields?[1].text ?? "0") ?? 0
            let b = Double(alert.textFields?[2].text ?? "0") ?? 0
            let r = Double(alert.textFields?[3].text ?? "0") ?? 0
            self.settings.itemInsideMargins = UIEdgeInsets(top: CGFloat(t), left: CGFloat(l), bottom: CGFloat(b), right: CGFloat(r))
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showSizeEditor() {
        let alert = UIAlertController(title: "图片尺寸 (width, height)", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "width"; $0.text = "\(self.settings.itemImageViewSize.width)" }
        alert.addTextField { $0.placeholder = "height"; $0.text = "\(self.settings.itemImageViewSize.height)" }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            let w = Double(alert.textFields?[0].text ?? "0") ?? 0
            let h = Double(alert.textFields?[1].text ?? "0") ?? 0
            self.settings.itemImageViewSize = CGSize(width: CGFloat(w), height: CGFloat(h))
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showColorEditor(for key: String) {
        let alert = UIAlertController(title: "选择颜色", message: nil, preferredStyle: .actionSheet)
        for (name, color) in colorOptions {
            alert.addAction(UIAlertAction(title: name, style: .default) { _ in
                self.setColor(color, for: key)
                self.tableView.reloadData()
            })
        }
        alert.addAction(UIAlertAction(title: "自定义RGB", style: .default) { _ in self.showCustomColorPicker(for: key) })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        presentAsPopover(alert, for: key)
    }
    
    private func showCustomColorPicker(for key: String) {
        let alert = UIAlertController(title: "自定义颜色", message: "输入 RGB (0-255)", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Red"; $0.keyboardType = .numberPad }
        alert.addTextField { $0.placeholder = "Green"; $0.keyboardType = .numberPad }
        alert.addTextField { $0.placeholder = "Blue"; $0.keyboardType = .numberPad }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            let r = Int(alert.textFields?[0].text ?? "0") ?? 0
            let g = Int(alert.textFields?[1].text ?? "0") ?? 0
            let b = Int(alert.textFields?[2].text ?? "0") ?? 0
            let color = UIColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
            self.setColor(color, for: key)
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func setColor(_ color: UIColor, for key: String) {
        switch key {
        case "pagingContentColor": settings.pagingContentColor = color
        case "pagingBgColor": settings.pagingBgColor = color
        case "barBgColor": settings.barBgColor = color
        case "itemDefaultBgColor": settings.itemDefaultBgColor = color
        case "itemSelectedBgColor": settings.itemSelectedBgColor = color
        case "titleDefaultColor": settings.titleDefaultColor = color
        case "titleSelectedColor": settings.titleSelectedColor = color
        case "dividingStripColor": settings.dividingStripColor = color
        case "scrollLineColor": settings.scrollLineColor = color
        default: break
        }
    }
    
    private func presentAsPopover(_ alert: UIAlertController, for key: String) {
        if let popover = alert.popoverPresentationController {
            // 找到对应 key 所在的 cell
            for section in 0..<items.count {
                for row in 0..<items[section].count {
                    if items[section][row].1 == key, let cell = tableView.cellForRow(at: IndexPath(row: row, section: section)) {
                        popover.sourceView = cell
                        popover.sourceRect = cell.bounds
                        break
                    }
                }
            }
        }
        present(alert, animated: true)
    }
    
    @objc private func saveSettings() {
        delegate?.didSaveSettings(settings)
    }
    
    @objc private func cancelSettings() {
        delegate?.didCancelSettings()
    }
}
