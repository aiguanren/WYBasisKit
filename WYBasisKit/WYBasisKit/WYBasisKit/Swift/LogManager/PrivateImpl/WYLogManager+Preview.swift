//
//  WYLogManager+Preview.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/21.
//

import UIKit
import QuickLook

/// 按钮触发行为封装为类，便于 @objc 调用
final class WYLogAction {
    @objc static func showLogPreview() {
        let vc = WYLogPreviewViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        guard var presenter = WYLogManager.floatingButton?.window?.rootViewController else { return }
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        presenter.present(nav, animated: true)
    }
}

/// 可拖动悬浮按钮（支持边界判断）
final class WYLogFloatingButton: UIButton {
    private var startPoint: CGPoint = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        let translation = gesture.translation(in: superview)
        
        if gesture.state == .began {
            startPoint = center
        }
        
        var newCenter = CGPoint(x: startPoint.x + translation.x, y: startPoint.y + translation.y)
        
        // 边界判断，防止按钮超出屏幕
        let halfWidth = frame.width / 2
        let halfHeight = frame.height / 2
        let superWidth = superview.bounds.width
        let superHeight = superview.bounds.height
        
        newCenter.x = max(halfWidth, min(superWidth - halfWidth, newCenter.x))
        newCenter.y = max(halfHeight, min(superHeight - halfHeight, newCenter.y))
        
        center = newCenter
    }
}

/// 自定义日志 Cell，右侧带有复制按钮
final class WYLogCell: UITableViewCell {
    private let label = UILabel()
    private let copyButton = UIButton(type: .system)
    var copyAction: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        label.numberOfLines = 0
        label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        copyButton.setTitle("复制", for: .normal)
        copyButton.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(13, WYBasisKitConfig.defaultScreenPixels), weight: .medium)
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        copyButton.layer.cornerRadius = 5
        copyButton.layer.borderWidth = 1
        copyButton.layer.masksToBounds = true
        copyButton.addTarget(self, action: #selector(handleCopy), for: .touchUpInside)
        
        contentView.addSubview(label)
        contentView.addSubview(copyButton)
        
        NSLayoutConstraint.activate([
            copyButton.topAnchor.constraint(equalTo: label.topAnchor, constant: 2),
            copyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            copyButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(lessThanOrEqualTo: copyButton.leadingAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(text: String, keyword: String?, canCopy: Bool = true) {
        if let keyword = keyword, !keyword.isEmpty {
            let attributed = NSMutableAttributedString(string: text)
            
            if let range = text.range(of: keyword, options: .caseInsensitive) {
                let nsRange = NSRange(range, in: text)
                attributed.addAttribute(.backgroundColor, value: UIColor.yellow, range: nsRange)
            }
            label.attributedText = attributed
        } else {
            label.text = text
        }
        
        copyButton.isEnabled = canCopy
        copyButton.layer.borderColor = copyButton.isEnabled
            ? copyButton.titleLabel?.textColor.cgColor
            : UIColor.lightGray.cgColor
    }
    
    @objc private func handleCopy() {
        copyAction?()
    }
}

/// 日志预览控制器
final class WYLogPreviewViewController: UIViewController {
    private var logs: String = ""
    private var logChunks: [String] = [] // 每条日志记录
    private var filteredLogChunks: [String] = [] // 当前搜索后的日志列表
    private var currentSearchText: String = "" // 当前搜索关键词
    private let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clear)),
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
        ]
        
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "搜索日志关键字"
        searchBar.searchBarStyle = .minimal
        let container = UIView()
        let width = UIApplication.shared.wy_keyWindow.screen.bounds.width - 120
        let height: CGFloat = 36
        container.frame = CGRect(x: 0, y: 0, width: width, height: height)
        searchBar.frame = container.bounds
        searchBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(searchBar)
        navigationItem.titleView = container
        navigationItem.largeTitleDisplayMode = .never
        
        tableView.register(WYLogCell.self, forCellReuseIdentifier: "WYLogCell")
        tableView.dataSource = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .onDrag // 滑动收起键盘
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        loadLogs()
        
        // 收起键盘的点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // 允许点击事件继续传递到 tableView 等
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func loadLogs() {
        logs = WYLogManager.decryptedLogText()
        if logs.isEmpty {
            logs = "暂无日志"
        }
        logChunks = logs
            .components(separatedBy: WYLogManager.logEntrySeparator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        filteredLogChunks = logChunks
        tableView.reloadData()
    }
    
    @objc private func close() {
        dismiss(animated: true)
    }
    
    @objc private func clear() {
        // 若日志内容本身已经为空或是提示文本，无需重复清除
        guard logs != "暂无日志", logs != "日志已清除", logs.isEmpty == false else {
            return
        }
        WYLogManager.clearLogFile()
        logs = ""
        logChunks = []
        filteredLogChunks = []
        tableView.reloadData()
    }
    
    @objc private func share() {
        let logPath = WYLogManager.logFilePath
        let url = URL(fileURLWithPath: logPath)
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.last
        present(activityVC, animated: true)
    }
}

extension WYLogPreviewViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        currentSearchText = ""
        filteredLogChunks = logChunks
        tableView.reloadData()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        currentSearchText = searchText
        if searchText.isEmpty {
            filteredLogChunks = logChunks
        } else {
            filteredLogChunks = logChunks.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }
        }
        tableView.reloadData()
    }
}

extension WYLogPreviewViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredLogChunks.isEmpty {
            return 1
        }
        return filteredLogChunks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "WYLogCell", for: indexPath) as! WYLogCell
        
        if filteredLogChunks.isEmpty ||
            filteredLogChunks.first == "暂无日志" ||
            filteredLogChunks.first == "日志已清除" {
            let message = logs.isEmpty || logs == "日志已清除" ? "日志已清除" : "未找到匹配的日志内容"
            cell.configure(text: message, keyword: nil, canCopy: false)
            cell.copyAction = nil
        } else {
            let logText = filteredLogChunks[indexPath.row]
            cell.configure(text: logText, keyword: currentSearchText)
            cell.copyAction = {
                UIPasteboard.general.string = logText
                let alert = UIAlertController(title: "复制成功", message: "日志已复制到剪贴板", preferredStyle: .alert)
                self.present(alert, animated: true) {
                    Task {
                        try? await Task.wy_delay(1, cancelThrows: false, onMain: {
                            alert.dismiss(animated: true)
                        })
                    }
                }
            }
        }
        return cell
    }
}
