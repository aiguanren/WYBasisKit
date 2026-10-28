//
//  WYTestSideslipCellController.swift
//  SwiftVerify
//
//  Created by guanren on 2025/11/15.
//

import UIKit

class WYTestSideslipCellController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var dataSource: [String] = []
    
    // 控制开关
    private var enableLongPull = true
    private var currentGesturePriority: WYSideslipGesturePriority = .autoSelection
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        title = "侧滑功能验证"
        view.backgroundColor = .magenta
        
        setupNavigationBar()
        setupTableView()
        setupData()
        
        // 启用自动关闭侧滑功能（只需要调用一次）
        UITableView.wy_enableAutoCloseSideslip()
    }
    
    private func setupNavigationBar() {
        // 添加长拉功能开关
        let longPullButton = UIBarButtonItem(
            title: enableLongPull ? "长拉:开" : "长拉:关",
            style: .plain,
            target: self,
            action: #selector(toggleLongPull)
        )
        
        // 添加手势优先级切换
        let gesturePriorityButton = UIBarButtonItem(
            title: gesturePriorityTitle(),
            style: .plain,
            target: self,
            action: #selector(switchGesturePriority)
        )
        
        navigationItem.rightBarButtonItems = [longPullButton, gesturePriorityButton]
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
        
        view.addSubview(tableView)
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let inset = UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: inset),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -inset),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupData() {
        dataSource.removeAll()
        for i in 1...20 {
            dataSource.append("测试单元格 \(i)")
        }
        tableView.reloadData()
    }
    
    @objc private func toggleLongPull() {
        enableLongPull.toggle()
        navigationItem.rightBarButtonItems?[0].title = enableLongPull ? "长拉:开" : "长拉:关"
        
        // 使用封装的方法重置所有cell状态
        tableView.wy_resetAllVisibleCellsSideslipState()
        tableView.reloadData()
        
        WYLogManager.output("长拉功能: \(enableLongPull ? "开启" : "关闭")")
    }
    
    @objc private func switchGesturePriority() {
        switch currentGesturePriority {
        case .autoSelection:
            currentGesturePriority = .sideslipFirst
        case .sideslipFirst:
            currentGesturePriority = .navigationBackFirst
        case .navigationBackFirst:
            currentGesturePriority = .autoSelection
        }
        
        navigationItem.rightBarButtonItems?[1].title = gesturePriorityTitle()
        
        // 使用封装的方法重置所有cell状态
        tableView.wy_resetAllVisibleCellsSideslipState()
        tableView.reloadData()
        
        WYLogManager.output("手势优先级: \(gesturePriorityTitle())")
    }
    
    private func gesturePriorityTitle() -> String {
        switch currentGesturePriority {
        case .autoSelection:
            return "手势:自动"
        case .sideslipFirst:
            return "手势:侧滑优先"
        case .navigationBackFirst:
            return "手势:返回优先"
        }
    }
    
    deinit {
        WYLogManager.output("WYTestSideslipCellController release")
    }
    
    /*
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension WYTestSideslipCellController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.selectionStyle = .none
        
        // 重置cell状态，防止重用问题
        cell.wy_resetSideslipState()
        
        // 配置侧滑功能
        let direction: String = configureSideslipForCell(cell, at: indexPath)
        
        // 显示功能状态
        let longPullStatus = enableLongPull ? "+长拉" : ""
        let gestureStatus = gestureStatusText()
        
        cell.textLabel?.text = dataSource[indexPath.row] + "(\(direction)\(longPullStatus)\(gestureStatus))"
        
        let btn = UIButton(type: .custom)
        btn.backgroundColor = UIColor.magenta.withAlphaComponent(0.25)
        btn.frame = CGRect(x: (tableView.wy_width - 100)/2, y: 0, width: 100, height: 50)
        btn.addTarget(self, action: #selector(didClickCellButton), for: .touchUpInside)
        cell.contentView .addSubview(btn)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        WYLogManager.output("点击了第\(indexPath.row+1)个cell")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 滑动tableView时关闭已侧滑的cell
        if let tableView = scrollView as? UITableView {
            tableView.wy_closeCurrentOpenedSideslipCellIfNeeded()
        }
    }
    
    private func configureSideslipForCell(_ cell: UITableViewCell, at indexPath: IndexPath) -> String {
        // 启用侧滑功能
        cell.wy_enableSideslip()
        
        // 设置手势优先级
        cell.wy_gesturePriority = currentGesturePriority
        
        var direction: String = ""
        
        var leftSideslipWidth: CGFloat = 0
        var rightSideslipWidth: CGFloat = 0
        
        // 设置侧滑方向（可以根据需要调整）
        if indexPath.row % 3 == 0 {
            cell.wy_sideslipDirection = .left
            direction = "左侧侧滑"
            leftSideslipWidth = 80
        } else if indexPath.row % 3 == 1 {
            cell.wy_sideslipDirection = .right
            direction = "右侧侧滑"
            rightSideslipWidth = 120
        } else {
            cell.wy_sideslipDirection = .both
            direction = "两侧侧滑"
            leftSideslipWidth = 80
            rightSideslipWidth = 120
        }
        
        // 设置侧滑区域宽度
        cell.wy_leftSideslipWidth = leftSideslipWidth
        cell.wy_rightSideslipWidth = rightSideslipWidth
        
        // 配置长拉功能
        configureLongPullForCell(cell, at: indexPath)
        
        // 设置自定义侧滑视图
        setupCustomSideslipView(for: cell, at: indexPath)
        
        cell.wy_sideslipEventHandler { event, direction in
            WYLogManager.output("event = \(event), direction = \(direction)")
        }
        
        return direction
    }
    
    private func configureLongPullForCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        if enableLongPull {
            cell.wy_enableLongPullAction = true
            cell.wy_longPullThreshold = 1.5
            cell.wy_longPullHapticFeedback = true
            
            // 使用弱引用避免循环引用
            cell.wy_sideslipLongPullHandler(
                progress: { [weak self] progress, direction in
                    guard let self = self else { return }
                    if progress > 0 {
                        // 通过tableView获取cell的当前indexPath
                        if let currentIndexPath = self.tableView.indexPath(for: cell) {
                            let directionText = direction == .left ? "左侧" : "右侧"
                            WYLogManager.output("第\(currentIndexPath.row + 1)行\(directionText)长拉进度: \(String(format: "%.2f", progress))")
                        }
                    }
                },
                completion: { [weak self] direction in
                    guard let self = self else { return }
                    
                    // 通过tableView获取cell的当前indexPath（最可靠的方式）
                    guard let currentIndexPath = self.tableView.indexPath(for: cell) else {
                        WYLogManager.output("❌ 无法获取cell的当前索引")
                        return
                    }
                    
                    let directionText = direction == .left ? "左侧" : "右侧"
                    WYLogManager.output("🎉 第\(currentIndexPath.row + 1)行\(directionText)长拉完成，执行对应事件！")
                    
                    // 长拉完成后删除对应cell
                    self.deleteCell(at: currentIndexPath, direction: direction)
                }
            )
        } else {
            cell.wy_enableLongPullAction = false
        }
    }
    
    private func setupCustomSideslipView(for cell: UITableViewCell, at indexPath: IndexPath) {
        // 左侧滑视图配置
        let leftButton = createSideslipButton(title: "(左)删除", color: .systemRed, indexPath: indexPath, isLeft: true)
        cell.wy_setSideslipView(leftButton, for: .left)
        
        // 右侧滑视图配置
        let rightButton = createSideslipButton(title: "(右)删除", color: .systemBlue, indexPath: indexPath, isLeft: false)
        cell.wy_setSideslipView(rightButton, for: .right)
    }
    
    private func createSideslipButton(title: String, color: UIColor, indexPath: IndexPath, isLeft: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.backgroundColor = color
        
        // 使用更复杂的tag编码来区分左右按钮和行索引
        let buttonTag = indexPath.row * 100 + (isLeft ? 1 : 2)
        button.tag = buttonTag
        
        button.addTarget(self, action: #selector(handleButtonTap(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func gestureStatusText() -> String {
        switch currentGesturePriority {
        case .autoSelection:
            return ""
        case .sideslipFirst:
            return "+侧滑优先"
        case .navigationBackFirst:
            return "+返回优先"
        }
    }
    
    @objc private func handleButtonTap(_ sender: UIButton) {
        let buttonTag = sender.tag
        let originalRowIndex = buttonTag / 100
        let isLeftButton = (buttonTag % 100) == 1
        
        let buttonType = isLeftButton ? "左侧" : "右侧"
        WYLogManager.output("点击了原始第 \(originalRowIndex + 1) 行的\(buttonType)滑动区域按钮")
        
        // 通过按钮的superview找到对应的cell
        if let cell = findCell(for: sender) {
            // 通过tableView获取cell的当前indexPath（最可靠的方式）
            if let currentIndexPath = tableView.indexPath(for: cell) {
                deleteCell(at: currentIndexPath, direction: isLeftButton ? .left : .right)
            } else {
                WYLogManager.output("❌ 无法找到按钮对应的cell当前索引")
            }
        }
    }
    
    // 通过按钮找到对应的cell
    private func findCell(for button: UIButton) -> UITableViewCell? {
        var view: UIView? = button
        while view != nil {
            if let cell = view as? UITableViewCell {
                return cell
            }
            view = view?.superview
        }
        return nil
    }
    
    private func deleteCell(at indexPath: IndexPath, direction: WYTableViewSideslipDirection) {
        guard indexPath.row < dataSource.count else {
            WYLogManager.output("❌ 索引越界: \(indexPath.row)，数据源数量: \(dataSource.count)")
            return
        }
        
        let cellText = dataSource[indexPath.row]
        let directionText = direction == .left ? "左侧" : "右侧"
        
        WYLogManager.output("🗑️ 删除第\(indexPath.row + 1)行 (\(directionText)): \(cellText)")
        
        // 先关闭侧滑
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.wy_closeSideslip(animated: false)
        }
        
        // 执行删除动画
        tableView.performBatchUpdates({
            dataSource.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            
            WYLogManager.output("✅ 删除完成，剩余\(self.dataSource.count)个cell")
        })
    }
    
    @objc func didClickCellButton() {
        WYLogManager.output("didClickCellButton")
    }
}
