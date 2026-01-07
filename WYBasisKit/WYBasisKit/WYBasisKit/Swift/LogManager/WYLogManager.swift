//
//  WYLogManager.swift
//  WYBasisKit
//
//  Created by guanren on 2025/7/26.
//

import Foundation
import UIKit
import QuickLook

/**
 * 日志输出模式
 *
 * 重要提示：
 * 1. 若选择包含文件存储的模式
 *    需要在 Info.plist 中配置以下键值，否则无法直接通过设备“文件”App 查看日志：
 *    <key>UIFileSharingEnabled</key>
 *    <true/>
 *    <key>LSSupportsOpeningDocumentsInPlace</key>
 *    <true/>
 *
 * 2. 若在Info.plist中配置上述键值会导致整个 Documents 目录暴露在”文件“App 中，用户将能直接看到 Documents 下的所有文件（包括敏感数据）
 *
 * 3. 若只需共享日志文件，建议通过预览界面的分享功能导出日志（无需配置 Info.plist，不会暴露 Documents 目录），具体可通过以下方式查看日志：
 *    - 调用 showPreview() 显示悬浮按钮
 *    - 点击按钮进入日志预览界面
 *    - 使用右上角分享功能导出日志文件
 */
@frozen public enum WYLogOutputMode: Int {
    
    /// 不保存日志，仅在 DEBUG 模式下输出到控制台（默认）
    case debugConsoleOnly = 0
    
    /// 不保存日志，DEBUG 和 RELEASE 都输出到控制台
    case alwaysConsoleOnly
    
    /// 保存日志，仅在 DEBUG 模式下输出到控制台
    case debugConsoleAndFile
    
    /// 保存日志，DEBUG 和 RELEASE 都输出到控制台
    case alwaysConsoleAndFile
    
    /// 仅保存日志，DEBUG 和 RELEASE 均不输出到控制台
    case onlySaveToFile
}

public struct WYLogManager {
    
    /// 写文件使用串行队列，避免并发冲突
    private static let logQueue = DispatchQueue(label: "com.WYBasisKit.WYLogManager.queue")
    
    /// 日志分隔符（用于日志条目之间的换行与逻辑隔断）
    internal static let logEntrySeparator = "\n\n\n"
    
    /// 日志文件路径（可根据路径获取并导出显示或者上传）
    public static var logFilePath: String {
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "App"
        
        let sanitizedName = appName.replacingOccurrences(of: "[^a-zA-Z0-9_\\-]", with: "_", options: .regularExpression)
        
        return docURL.appendingPathComponent("\(sanitizedName).log").path
    }
    
    /**
     * 日志
     * - Parameters:
     *   - messages: 要输出的日志内容
     *   - outputMode: 日志输出模式
     *   - file: 文件名(自动捕获)
     *   - function: 函数名(自动捕获)
     *   - line: 代码行号(自动捕获)
     */
    public static func output(_ messages: Any..., outputMode: WYLogOutputMode = .debugConsoleOnly, file: String = #file, function: String = #function, line: Int = #line) {
        
        let timestamp: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return formatter.string(from: Date())
        }()
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let message = messages.map { "\($0)" }.joined(separator: " ")
        
        // 日志内容
        let fullLog = "\(timestamp) ——> \(fileName) ——> \(function) ——> line:\(line)\n\n\(message)\(logEntrySeparator)"
        
        switch outputMode {
        case .debugConsoleOnly:
#if DEBUG
            print(fullLog)
#endif
        case .alwaysConsoleOnly:
            print(fullLog)
        case .debugConsoleAndFile:
#if DEBUG
            print(fullLog)
#endif
            saveLogToFile(fullLog)
        case .alwaysConsoleAndFile:
            print(fullLog)
            saveLogToFile(fullLog)
        case .onlySaveToFile:
            saveLogToFile(fullLog)
        }
    }
    
    /**
     * 清除日志文件
     * - 注意：该操作不可恢复，仅清除当前 logFilePath 下的日志文件
     */
    public static func clearLogFile() {
        logQueue.async {
            let fileManager = FileManager.default
            let path = logFilePath
            
            guard fileManager.fileExists(atPath: path) else {
                // 日志文件不存在，无需删除
                return
            }
            
            do {
                try fileManager.removeItem(atPath: path)
            } catch {
                output("[WYLogManager] 删除日志文件失败: \(error)")
            }
        }
    }
    
    /// 悬浮按钮
    fileprivate static var floatingButton: WYLogFloatingButton?
    
    /**
     * 显示预览组件
     * - Parameters:
     *   - contentView: 预览按钮的父控件，如果不传则为当前正在显示的Window
     */
    public static func showPreview(_ contentView: UIView = UIApplication.shared.wy_keyWindow) {
        if floatingButton != nil { return } // 防止重复创建预览组件和页面
        
        let button = WYLogFloatingButton()
        button.setTitle("日志", for: .normal)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.frame = CGRect(x: contentView.bounds.width - 70, y: contentView.bounds.height - 150, width: 50, height: 50)
        button.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowRadius = 4
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.addTarget(WYLogAction.self, action: #selector(WYLogAction.showLogPreview), for: .touchUpInside)
        
        contentView.addSubview(button)
        floatingButton = button
    }
    
    /// 移除预览组件
    public static func removePreview() {
        floatingButton?.removeFromSuperview()
        floatingButton = nil
    }
    
    /// 写入日志文件
    private static func saveLogToFile(_ log: String) {
        logQueue.async {
            
            let path = logFilePath
            let fileManager = FileManager.default
            
            // 确保目录存在
            let directory = URL(fileURLWithPath: path).deletingLastPathComponent().path
            if !fileManager.fileExists(atPath: directory) {
                try? fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
            }
            
            // 确保文件存在
            if !fileManager.fileExists(atPath: path) {
                fileManager.createFile(atPath: path, contents: nil)
            }
            
            // 使用 FileHandle 追加写入（UTF-8编码）
            guard let fileHandle = FileHandle(forWritingAtPath: path) else {
                output("[WYLogManager] 打开日志文件失败，可能是路径无效或没有写入权限")
                return
            }
            
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            
            // 添加 UTF-8 BOM 头（仅首次写入）
            if fileHandle.offsetInFile == 0 {
                let bomData = Data([0xEF, 0xBB, 0xBF])
                fileHandle.write(bomData)
            }
            
            // 写入日志数据（确保使用 UTF-8）
            guard let logData = (log + "\n").data(using: .utf8) else {
                output("[WYLogManager] 日志内容无法转换为 UTF-8 数据")
                return
            }
            fileHandle.write(logData)
        }
    }
}

/// 按钮触发行为封装为类，便于 @objc 调用
private class WYLogAction {
    @objc static func showLogPreview() {
        let vc = WYLogPreviewViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        WYLogManager.floatingButton?.window?.rootViewController?.present(nav, animated: true)
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
        copyButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
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
    
    func configure(text: String, keyword: String?, canCopyed: Bool = true) {
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
        
        copyButton.isEnabled = canCopyed
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
        logs = (try? String(contentsOfFile: WYLogManager.logFilePath, encoding: .utf8)) ?? "暂无日志"
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
            cell.configure(text: message, keyword: nil, canCopyed: false)
            cell.copyAction = nil
        } else {
            let logText = filteredLogChunks[indexPath.row]
            cell.configure(text: logText, keyword: currentSearchText)
            cell.copyAction = {
                UIPasteboard.general.string = logText
                let alert = UIAlertController(title: "复制成功", message: "日志已复制到剪贴板", preferredStyle: .alert)
                self.present(alert, animated: true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        alert.dismiss(animated: true)
                    }
                }
            }
        }
        return cell
    }
}
