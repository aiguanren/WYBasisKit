//
//  WYLogManager.swift
//  WYBasisKit
//
//  Created by guanren on 2025/7/26.
//

import Foundation
import UIKit
import QuickLook

public struct WYLogManager {
    
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
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = timeFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let message = messages.compactMap { "\($0)" }.joined(separator: " ")
        
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
     *   - contentView: 预览按钮的父控件，如果不传则为UIApplication.shared.keyWindow
     */
    public static func showPreview(_ contentView: UIView = UIApplication.shared.keyWindow ?? UIView()) {
        if floatingButton != nil { return }
        
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
            let directory = (path as NSString).deletingLastPathComponent
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

/// 日志预览控制器
final class WYLogPreviewViewController: UIViewController {
    private var logs: String = ""
    private let textView = UITextView()
    
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
        navigationItem.titleView = searchBar
        
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        loadLogs()
    }
    
    private func loadLogs() {
        logs = (try? String(contentsOfFile: WYLogManager.logFilePath, encoding: .utf8)) ?? "暂无日志"
        textView.text = logs
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
        textView.text = "日志已清除"
    }
    
    @objc private func share() {
        let logPath = WYLogManager.logFilePath
        let url = URL(fileURLWithPath: logPath)
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}

extension WYLogPreviewViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            textView.text = logs
        } else {
            // 用logEntrySeparator属性分割日志
            let logChunks = logs.components(separatedBy: WYLogManager.logEntrySeparator)
            
            // 匹配包含搜索词的完整日志
            let matchedLogs = logChunks
                .filter { $0.localizedCaseInsensitiveContains(searchText) }
                .joined(separator: WYLogManager.logEntrySeparator)
            
            textView.text = matchedLogs.isEmpty ? "未找到匹配的日志内容" : matchedLogs
        }
    }
}
