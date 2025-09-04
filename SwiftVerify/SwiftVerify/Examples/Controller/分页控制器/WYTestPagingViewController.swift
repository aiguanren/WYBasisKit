//
//  WYTestPagingViewController.swift
//  SwiftVerify
//
//  Created by guanren on 2025/9/3.
//

import UIKit

class WYTestPagingViewController: UIViewController {
    
    /// 分页视图
    private var pagingView: WYPagingView?
    
    /// 设置按钮
    private var settingsButton: UIBarButtonItem!
    
    /// 设置数据模型
    private var settings = PagingSettingsModel()
    
    /// 测试用的子控制器数组
    private let testControllers: [UIViewController] = {
        let colors: [UIColor] = [.red, .green, .blue, .yellow, .purple, .orange, .cyan, .magenta]
        return colors.prefix(5).map { color in
            let vc = UIViewController()
            vc.view.backgroundColor = .white
            vc.view.layer.borderWidth = 2
            vc.view.layer.borderColor = UIColor.black.cgColor
            return vc
        }
    }()
    
    /// 测试用的标题数组
    private let testTitles = ["首页", "消息", "发现", "我的", "设置"]
    
    /// 测试用的图片数组（使用系统图标代替）
    private let testDefaultImages: [UIImage] = {
        return [
            UIImage(systemName: "house")!,
            UIImage(systemName: "message")!,
            UIImage(systemName: "magnifyingglass")!,
            UIImage(systemName: "person")!,
            UIImage(systemName: "gearshape")!
        ]
    }()
    
    private let testSelectedImages: [UIImage] = {
        return [
            UIImage(systemName: "house.fill")!,
            UIImage(systemName: "message.fill")!,
            UIImage(systemName: "magnifyingglass.circle.fill")!,
            UIImage(systemName: "person.fill")!,
            UIImage(systemName: "gearshape.fill")!
        ]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupInitialPagingView()
    }
    
    /// 设置导航栏
    private func setupNavigationBar() {
        title = "WYPagingView 测试"
        view.backgroundColor = .white
        
        // 添加设置按钮
        settingsButton = UIBarButtonItem(
            title: "设置",
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    /// 初始化默认的分页视图
    private func setupInitialPagingView() {
        // 移除旧的视图
        pagingView?.removeFromSuperview()
        pagingView = nil
        
        // 创建新的分页视图
        let newPagingView = WYPagingView()
        view.addSubview(newPagingView)
        
        // 设置约束
        newPagingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newPagingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            newPagingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newPagingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newPagingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 应用当前设置
        applySettings(to: newPagingView)
        
        // 布局分页视图
        newPagingView.layout(
            controllerAry: testControllers,
            titleAry: testTitles,
            defaultImageAry: testDefaultImages,
            selectedImageAry: testSelectedImages,
            superViewController: self
        )
        
        pagingView = newPagingView
    }
    
    /// 显示设置界面
    @objc private func showSettings() {
        let settingsVC = PagingSettingsViewController(settings: settings)
        settingsVC.delegate = self
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    /// 将设置应用到分页视图
    private func applySettings(to pagingView: WYPagingView) {
        // 基本属性设置
        pagingView.bar_Height = settings.barHeight
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
        
        // 图片设置
        pagingView.bar_dividingStripImage = settings.dividingStripImage
        pagingView.bar_scrollLineImage = settings.scrollLineImage
        
        // 尺寸设置
        pagingView.bar_item_width = settings.itemWidth
        pagingView.bar_item_height = settings.itemHeight
        pagingView.bar_item_appendSize = settings.itemAppendSize
        pagingView.bar_item_cornerRadius = settings.itemCornerRadius
        pagingView.bar_scrollLineWidth = settings.scrollLineWidth
        pagingView.bar_scrollLineBottomOffset = settings.scrollLineBottomOffset
        pagingView.bar_dividingStripHeight = settings.dividingStripHeight
        pagingView.bar_scrollLineHeight = settings.scrollLineHeight
        
        // 字体设置
        pagingView.bar_title_defaultFont = settings.titleDefaultFont
        pagingView.bar_title_selectedFont = settings.titleSelectedFont
        
        // 其他设置
        pagingView.bar_selectedIndex = settings.selectedIndex
        pagingView.canScrollController = settings.canScrollController
        pagingView.canScrollBar = settings.canScrollBar
        pagingView.bar_pagingContro_bounce = settings.pagingBounce
        
        // 设置代理和回调
        pagingView.delegate = self
        pagingView.itemDidScroll { [weak self] index in
            guard self != nil else { return }
            print("分页滚动到第 \(index) 页 - 通过闭包回调")
        }
    }
    
    deinit {
        print("WYTestPagingViewController deinit")
    }
}

// MARK: - WYPagingViewDelegate
extension WYTestPagingViewController: WYPagingViewDelegate {
    func itemDidScroll(_ pagingIndex: Int) {
        print("分页滚动到第 \(pagingIndex) 页 - 通过代理回调")
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
    
    // 图片
    var dividingStripImage: UIImage? = nil
    var scrollLineImage: UIImage? = nil
    
    // 尺寸
    var itemWidth: CGFloat = 0
    var itemHeight: CGFloat = 0
    var itemAppendSize: CGSize = .zero
    var itemCornerRadius: CGFloat = 0
    var scrollLineWidth: CGFloat = 25
    var scrollLineBottomOffset: CGFloat = 5
    var dividingStripHeight: CGFloat = 2
    var scrollLineHeight: CGFloat = 2
    
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
    
    // 所有设置项
    private let sections = [
        "基本属性",
        "颜色设置",
        "尺寸设置",
        "字体设置",
        "其他设置"
    ]
    
    private let items = [
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
            ("Item追加尺寸", "itemAppendSize"),
            ("Item圆角", "itemCornerRadius"),
            ("滑动线宽度", "scrollLineWidth"),
            ("滑动线底部偏移", "scrollLineBottomOffset"),
            ("分隔带高度", "dividingStripHeight"),
            ("滑动线高度", "scrollLineHeight")
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
        "白色": .white,
        "黑色": .black,
        "红色": .red,
        "绿色": .green,
        "蓝色": .blue,
        "黄色": .yellow,
        "橙色": .orange,
        "紫色": .purple,
        "灰色": .gray,
        "浅灰色": .lightGray,
        "默认标题色": .wy_hex("#7B809E"),
        "选中标题色": .wy_hex("#2D3952"),
        "分隔带色": .wy_hex("#F2F2F2"),
        "滑动线色": .wy_hex("#2D3952")
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
        
        let saveButton = UIBarButtonItem(
            title: "保存",
            style: .done,
            target: self,
            action: #selector(saveSettings)
        )
        
        let cancelButton = UIBarButtonItem(
            title: "取消",
            style: .plain,
            target: self,
            action: #selector(cancelSettings)
        )
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
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
        cell.detailTextLabel?.text = getValueDescription(for: item.1)
        cell.accessoryType = .disclosureIndicator
        
        // 为颜色设置项添加颜色预览
        if item.1.contains("Color") {
            let colorView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            colorView.layer.cornerRadius = 4
            colorView.layer.borderWidth = 1
            colorView.layer.borderColor = UIColor.lightGray.cgColor
            
            switch item.1 {
            case "pagingContentColor":
                colorView.backgroundColor = settings.pagingContentColor
            case "pagingBgColor":
                colorView.backgroundColor = settings.pagingBgColor
            case "barBgColor":
                colorView.backgroundColor = settings.barBgColor
            case "itemDefaultBgColor":
                colorView.backgroundColor = settings.itemDefaultBgColor
            case "itemSelectedBgColor":
                colorView.backgroundColor = settings.itemSelectedBgColor
            case "titleDefaultColor":
                colorView.backgroundColor = settings.titleDefaultColor
            case "titleSelectedColor":
                colorView.backgroundColor = settings.titleSelectedColor
            case "dividingStripColor":
                colorView.backgroundColor = settings.dividingStripColor
            case "scrollLineColor":
                colorView.backgroundColor = settings.scrollLineColor
            default:
                break
            }
            
            cell.accessoryView = colorView
        } else {
            cell.accessoryView = nil
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = items[indexPath.section][indexPath.row]
        showDetailSetting(for: item.1)
    }
    
    private func getValueDescription(for key: String) -> String {
        switch key {
        case "barHeight":
            return "\(settings.barHeight)"
        case "buttonPosition":
            switch settings.buttonPosition {
            case .imageLeftTitleRight: return "图片左文字右"
            case .imageRightTitleLeft: return "图片右文字左"
            case .imageTopTitleBottom: return "图片上文字下"
            case .imageBottomTitleTop: return "图片下文字上"
            }
        case "originlLeftOffset":
            return "\(settings.originlLeftOffset)"
        case "originlRightOffset":
            return "\(settings.originlRightOffset)"
        case "itemTopOffset":
            return settings.itemTopOffset?.description ?? "0"
        case "adjustOffset":
            return settings.adjustOffset ? "是" : "否"
        case "dividingOffset":
            return "\(settings.dividingOffset)"
        case "buttonDividingOffset":
            return "\(settings.buttonDividingOffset)"
        case "pagingContentColor":
            return "已设置"
        case "pagingBgColor":
            return settings.pagingBgColor != nil ? "已设置" : "nil"
        case "barBgColor":
            return "已设置"
        case "itemDefaultBgColor":
            return "已设置"
        case "itemSelectedBgColor":
            return "已设置"
        case "titleDefaultColor":
            return "已设置"
        case "titleSelectedColor":
            return "已设置"
        case "dividingStripColor":
            return "已设置"
        case "scrollLineColor":
            return "已设置"
        case "itemWidth":
            return "\(settings.itemWidth)"
        case "itemHeight":
            return "\(settings.itemHeight)"
        case "itemAppendSize":
            return "\(settings.itemAppendSize.width), \(settings.itemAppendSize.height)"
        case "itemCornerRadius":
            return "\(settings.itemCornerRadius)"
        case "scrollLineWidth":
            return "\(settings.scrollLineWidth)"
        case "scrollLineBottomOffset":
            return "\(settings.scrollLineBottomOffset)"
        case "dividingStripHeight":
            return "\(settings.dividingStripHeight)"
        case "scrollLineHeight":
            return "\(settings.scrollLineHeight)"
        case "titleDefaultFont":
            return "\(Int(settings.titleDefaultFont.pointSize))"
        case "titleSelectedFont":
            return "\(Int(settings.titleSelectedFont.pointSize))"
        case "selectedIndex":
            return "\(settings.selectedIndex)"
        case "canScrollController":
            return settings.canScrollController ? "是" : "否"
        case "canScrollBar":
            return settings.canScrollBar ? "是" : "否"
        case "pagingBounce":
            return settings.pagingBounce ? "是" : "否"
        default:
            return ""
        }
    }
    
    private func showDetailSetting(for key: String) {
        let alert = UIAlertController(title: "设置 \(key)", message: nil, preferredStyle: .alert)
        
        switch key {
        case "barHeight", "originlLeftOffset", "originlRightOffset", "dividingOffset",
             "buttonDividingOffset", "itemWidth", "itemHeight", "itemCornerRadius",
             "scrollLineWidth", "scrollLineBottomOffset", "dividingStripHeight",
             "scrollLineHeight":
            
            alert.addTextField { textField in
                textField.keyboardType = .decimalPad
                textField.placeholder = "请输入数值"
                let currentValue: CGFloat
                switch key {
                case "barHeight": currentValue = self.settings.barHeight
                case "originlLeftOffset": currentValue = self.settings.originlLeftOffset
                case "originlRightOffset": currentValue = self.settings.originlRightOffset
                case "dividingOffset": currentValue = self.settings.dividingOffset
                case "buttonDividingOffset": currentValue = self.settings.buttonDividingOffset
                case "itemWidth": currentValue = self.settings.itemWidth
                case "itemHeight": currentValue = self.settings.itemHeight
                case "itemCornerRadius": currentValue = self.settings.itemCornerRadius
                case "scrollLineWidth": currentValue = self.settings.scrollLineWidth
                case "scrollLineBottomOffset": currentValue = self.settings.scrollLineBottomOffset
                case "dividingStripHeight": currentValue = self.settings.dividingStripHeight
                case "scrollLineHeight": currentValue = self.settings.scrollLineHeight
                default: currentValue = 0
                }
                textField.text = "\(currentValue)"
            }
            
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                if let text = alert.textFields?.first?.text, let value = Double(text) {
                    let cgValue = CGFloat(value)
                    switch key {
                    case "barHeight": self.settings.barHeight = cgValue
                    case "originlLeftOffset": self.settings.originlLeftOffset = cgValue
                    case "originlRightOffset": self.settings.originlRightOffset = cgValue
                    case "dividingOffset": self.settings.dividingOffset = cgValue
                    case "buttonDividingOffset": self.settings.buttonDividingOffset = cgValue
                    case "itemWidth": self.settings.itemWidth = cgValue
                    case "itemHeight": self.settings.itemHeight = cgValue
                    case "itemCornerRadius": self.settings.itemCornerRadius = cgValue
                    case "scrollLineWidth": self.settings.scrollLineWidth = cgValue
                    case "scrollLineBottomOffset": self.settings.scrollLineBottomOffset = cgValue
                    case "dividingStripHeight": self.settings.dividingStripHeight = cgValue
                    case "scrollLineHeight": self.settings.scrollLineHeight = cgValue
                    default: break
                    }
                    self.tableView.reloadData()
                }
            })
            
        case "titleDefaultFont", "titleSelectedFont":
            alert.addTextField { textField in
                textField.keyboardType = .numberPad
                textField.placeholder = "请输入字体大小"
                let currentSize: CGFloat
                if key == "titleDefaultFont" {
                    currentSize = self.settings.titleDefaultFont.pointSize
                } else {
                    currentSize = self.settings.titleSelectedFont.pointSize
                }
                textField.text = "\(Int(currentSize))"
            }
            
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                if let text = alert.textFields?.first?.text, let size = Int(text) {
                    let fontSize = CGFloat(size)
                    if key == "titleDefaultFont" {
                        self.settings.titleDefaultFont = UIFont.systemFont(ofSize: fontSize)
                    } else {
                        self.settings.titleSelectedFont = UIFont.boldSystemFont(ofSize: fontSize)
                    }
                    self.tableView.reloadData()
                }
            })
            
        case "selectedIndex":
            alert.addTextField { textField in
                textField.keyboardType = .numberPad
                textField.placeholder = "请输入选中索引 (0-4)"
                textField.text = "\(self.settings.selectedIndex)"
            }
            
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                if let text = alert.textFields?.first?.text, let index = Int(text) {
                    self.settings.selectedIndex = max(0, min(index, 4))
                    self.tableView.reloadData()
                }
            })
            
        case "itemTopOffset":
            alert.addTextField { textField in
                textField.keyboardType = .decimalPad
                textField.placeholder = "请输入数值或留空"
                if let value = self.settings.itemTopOffset {
                    textField.text = "\(value)"
                }
            }
            
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                if let text = alert.textFields?.first?.text, !text.isEmpty {
                    if let value = Double(text) {
                        self.settings.itemTopOffset = CGFloat(value)
                    }
                } else {
                    self.settings.itemTopOffset = nil
                }
                self.tableView.reloadData()
            })
            
        case "adjustOffset", "canScrollController", "canScrollBar", "pagingBounce":
            let currentValue: Bool
            switch key {
            case "adjustOffset": currentValue = self.settings.adjustOffset
            case "canScrollController": currentValue = self.settings.canScrollController
            case "canScrollBar": currentValue = self.settings.canScrollBar
            case "pagingBounce": currentValue = self.settings.pagingBounce
            default: currentValue = false
            }
            
            alert.message = currentValue ? "当前状态: 开启" : "当前状态: 关闭"
            
            alert.addAction(UIAlertAction(title: "切换", style: .default) { _ in
                switch key {
                case "adjustOffset": self.settings.adjustOffset = !currentValue
                case "canScrollController": self.settings.canScrollController = !currentValue
                case "canScrollBar": self.settings.canScrollBar = !currentValue
                case "pagingBounce": self.settings.pagingBounce = !currentValue
                default: break
                }
                self.tableView.reloadData()
            })
            
        case "buttonPosition":
            let positions: [WYButtonPosition] = [.imageLeftTitleRight, .imageRightTitleLeft, .imageTopTitleBottom, .imageBottomTitleTop]
            let positionNames = ["图片左文字右", "图片右文字左", "图片上文字下", "图片下文字上"]
            
            for (index, name) in positionNames.enumerated() {
                alert.addAction(UIAlertAction(title: name, style: .default) { _ in
                    self.settings.buttonPosition = positions[index]
                    self.tableView.reloadData()
                })
            }
            
        case "itemAppendSize":
            alert.addTextField { textField in
                textField.placeholder = "宽度,高度 (如: 10,20)"
                textField.text = "\(self.settings.itemAppendSize.width),\(self.settings.itemAppendSize.height)"
            }
            
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                if let text = alert.textFields?.first?.text {
                    let components = text.split(separator: ",").map { String($0) }
                    if components.count == 2,
                       let width = Double(components[0]),
                       let height = Double(components[1]) {
                        self.settings.itemAppendSize = CGSize(width: width, height: height)
                        self.tableView.reloadData()
                    }
                }
            })
            
        // 颜色设置项
        case "pagingContentColor", "pagingBgColor", "barBgColor", "itemDefaultBgColor",
             "itemSelectedBgColor", "titleDefaultColor", "titleSelectedColor",
             "dividingStripColor", "scrollLineColor":
            
            let colorAlert = UIAlertController(title: "选择 \(key) 颜色", message: nil, preferredStyle: .actionSheet)
            
            for (name, color) in colorOptions {
                colorAlert.addAction(UIAlertAction(title: name, style: .default) { _ in
                    self.setColor(color, for: key)
                    self.tableView.reloadData()
                })
            }
            
            // 添加自定义颜色选项
            colorAlert.addAction(UIAlertAction(title: "自定义颜色", style: .default) { _ in
                self.showCustomColorPicker(for: key)
            })
            
            colorAlert.addAction(UIAlertAction(title: "取消", style: .cancel))
            // 适配 iPad
            if let popoverController = colorAlert.popoverPresentationController {
                // 找到包含当前key的section和row
                var foundIndexPath: IndexPath?
                for section in 0..<items.count {
                    for row in 0..<items[section].count {
                        if items[section][row].1 == key {
                            foundIndexPath = IndexPath(row: row, section: section)
                            break
                        }
                    }
                    if foundIndexPath != nil {
                        break
                    }
                }
                
                if let indexPath = foundIndexPath,
                   let cell = tableView.cellForRow(at: indexPath) {
                    popoverController.sourceView = cell
                    popoverController.sourceRect = cell.bounds
                }
            }
            
            present(colorAlert, animated: true)
            
        default:
            alert.message = "该设置项暂不支持编辑"
            alert.addAction(UIAlertAction(title: "确定", style: .default))
        }
        
        if !key.contains("Color") {
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            present(alert, animated: true)
        }
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
    
    private func showCustomColorPicker(for key: String) {
        let alert = UIAlertController(title: "自定义颜色 - \(key)", message: "请输入RGB值 (0-255)", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "红色 (0-255)"
            textField.keyboardType = .numberPad
        }
        
        alert.addTextField { textField in
            textField.placeholder = "绿色 (0-255)"
            textField.keyboardType = .numberPad
        }
        
        alert.addTextField { textField in
            textField.placeholder = "蓝色 (0-255)"
            textField.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            if let redText = alert.textFields?[0].text,
               let greenText = alert.textFields?[1].text,
               let blueText = alert.textFields?[2].text,
               let red = Int(redText), let green = Int(greenText), let blue = Int(blueText) {
                
                let color = UIColor(red: CGFloat(red)/255.0,
                                  green: CGFloat(green)/255.0,
                                  blue: CGFloat(blue)/255.0,
                                  alpha: 1.0)
                self.setColor(color, for: key)
                self.tableView.reloadData()
            }
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func saveSettings() {
        delegate?.didSaveSettings(settings)
    }
    
    @objc private func cancelSettings() {
        delegate?.didCancelSettings()
    }
}
