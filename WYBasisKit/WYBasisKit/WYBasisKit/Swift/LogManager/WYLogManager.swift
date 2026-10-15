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

/**
 * 日志加密模式(写进文件的日志内容默认加密，直接打开文件或导出附件都看不到明文)
 *
 * 说明：
 * 1. 默认aesGCM，接入方零配置即开启加密，导出的日志只能通过decryptedLogText()或配套解密脚本阅读
 * 2. xor与aesGCM未设置encryptionKey时按包名派生密钥，建议接入方在首次写日志前设置自己的密钥
 * 3. 每条日志独立加密成文件里的一行，历史明文条目不解密原样保留，新旧内容可共存
 */
@frozen public enum WYLogEncryptionMode: Int {

    /// 不加密，文件内容为明文(仅排查极端场景时临时使用)
    case none = 0

    /// Base64编码，无密钥，仅让文件内容无法被直接阅读和搜索
    case base64 = 1

    /// XOR流加密，防随手打开阅读，强度弱于aesGCM
    case xor = 2

    /// AES-256-GCM加密，逐条独立加解密并带完整性校验(默认)
    case aesGCM = 3
}

/**
 * 日志打印
 * - Parameters:
 *   - messages: 要输出的日志内容
 *   - outputMode: 日志输出模式
 *   - file: 文件名(自动捕获)
 *   - function: 函数名(自动捕获)
 *   - line: 代码行号(自动捕获)
 */
public func wy_print(_ messages: Any..., outputMode: WYLogOutputMode = .debugConsoleOnly, file: String = #file, function: String = #function, line: Int = #line) {
    WYLogManager.output(messages, outputMode: outputMode, file: file, function: function, line: line)
}

public struct WYLogManager {
    
    /// 日志文件路径（可根据路径获取并导出显示或者上传）
    public static var logFilePath: String {
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docURL.appendingPathComponent("\(resolvedFileName()).log").path
    }

    /// 自定义日志文件名(不含扩展名；不设置时默认名=本地化App名+本地化"日志"词，如中文名"语音工坊"生成"语音工坊日志"、英文名"VoiceFactory"生成"VoiceFactoryLog"；启动期主线程一次写入、之后各线程只读)
    nonisolated(unsafe) public static var logFileName: String?

    /// 日志加密模式(默认aesGCM，加密后文件内容与导出附件均为密文，只能通过decryptedLogText()或配套解密脚本阅读；启动期主线程一次写入、之后各线程只读)
    nonisolated(unsafe) public static var encryptionMode: WYLogEncryptionMode = .aesGCM

    /// 日志加密密钥(xor与aesGCM使用；不设置时按包名派生，接入方建议在首次写日志前设置；启动期主线程一次写入、之后各线程只读)
    nonisolated(unsafe) public static var encryptionKey: Data?

    /**
     * 读取整个日志文件并解密成明文
     * - Returns: 解密后的完整日志文本(历史明文条目原样保留，解密失败的条目自动跳过；文件不存在时返回空串)
     */
    public static func decryptedLogText() -> String {
        guard let text = try? String(contentsOfFile: logFilePath, encoding: .utf8) else { return "" }
        let entries = text.split(separator: "\n", omittingEmptySubsequences: true).compactMap { decryptLine(String($0)) }
        return entries.joined(separator: logEntrySeparator)
    }

    /**
     * 同步加密写入一条日志
     * - Parameter content: 要写入的完整日志内容(崩溃捕获等进程即将退出的场景用，不走异步队列确保落盘)
     */
    public static func writeEncryptedSynchronously(_ content: String) {
        appendLine(encryptEntry(content))
    }
    
    /**
     * 日志打印
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
            appendLine(encryptEntry(log))
        }
    }
    
    /// 悬浮按钮
    fileprivate static var floatingButton: WYLogFloatingButton?
    
    /// 写文件使用串行队列，避免并发冲突
    private static let logQueue = DispatchQueue(label: "com.WYBasisKit.WYLogManager.queue")
    
    /// 日志分隔符（用于日志条目之间的换行与逻辑隔断）
    internal static let logEntrySeparator = "\n\n\n"

    /// 加密条目行前缀(带版本号，文件里每行一条密文，解密端据此识别格式)
    private static let encryptedLinePrefix = "WYLOG1:"

    /// 默认密钥派生盐(接入方未设置encryptionKey时与包名一起喂PBKDF2派生日志密钥；发版时随机换新值可让照旧默认派生写的解密脚本失效，设了自定义密钥的接入方不受影响)
    private static let internalSeedValue = "c079b05228d588a6"

    /// 实际生效的密钥(接入方设置过就用接入方的，否则按包名与内部常量派生32字节)
    private static var activeKey: Data {
        if let key = encryptionKey, key.isEmpty == false {
            return key
        }
        let bundleId = Bundle.main.bundleIdentifier ?? "WYBasisKit"
        return WYCryptor.pbkdf2(password: bundleId, salt: internalSeedValue, rounds: 4096, length: 32) ?? Data((bundleId + internalSeedValue).utf8)
    }

    /// 解析日志文件名(自定义名优先；默认名=本地化App名+本地化"日志"词，App名缺失或清洗为空回落到包名末段)
    private static func resolvedFileName() -> String {
        let fallbackName = Bundle.main.bundleIdentifier?.components(separatedBy: ".").last ?? "App"

        if let custom = logFileName?.trimmingCharacters(in: .whitespacesAndNewlines), custom.isEmpty == false {
            let sanitized = sanitizeFileName(custom)
            return sanitized.isEmpty == false ? sanitized : fallbackName
        }

        let displayName = (Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String)
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String

        let sanitizedName = sanitizeFileName(displayName ?? "")
        let baseName = sanitizedName.isEmpty == false ? sanitizedName : fallbackName
        return baseName + WYLocalized("日志")
    }

    /// 清洗文件名(只去掉路径不友好字符与换行控制符，各语言文字与数字都保留)
    private static func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:?%*|\"<>").union(.newlines).union(.controlCharacters)
        let cleaned = name.components(separatedBy: invalidCharacters).joined(separator: "_")
        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    /**
     * 加密一条日志成单行密文
     * - Parameter entry: 要加密的完整日志条目
     * - Returns: 带格式前缀的单行密文(加密失败时回落明文，保证日志不丢)
     */
    private static func encryptEntry(_ entry: String) -> String {
        let mode = encryptionMode
        if mode == .none { return entry }

        let plainData = Data(entry.utf8)
        let payload: String
        switch mode {
        case .none:
            return entry
        case .base64:
            payload = WYCryptor.base64Encode(plainData)
        case .xor:
            payload = WYCryptor.base64Encode(WYCryptor.xor(plainData, key: activeKey))
        case .aesGCM:
            guard let combined = WYCryptor.aesGCMEncrypt(plainData, key: activeKey) else { return entry }
            payload = WYCryptor.base64Encode(combined)
        }
        return encryptedLinePrefix + "\(mode.rawValue):" + payload
    }

    /**
     * 解密一行日志内容
     * - Parameter line: 日志文件里的一行
     * - Returns: 解密后的明文条目(不带加密前缀的历史明文原样返回，格式损坏或解密失败的行返回nil由调用方丢弃)
     */
    private static func decryptLine(_ line: String) -> String? {
        guard line.hasPrefix(encryptedLinePrefix) else { return line }

        let rest = String(line.dropFirst(encryptedLinePrefix.count))
        guard let colonIndex = rest.firstIndex(of: ":"),
              let modeRaw = Int(rest[..<colonIndex]),
              let mode = WYLogEncryptionMode(rawValue: modeRaw),
              let payload = Data(base64Encoded: String(rest[rest.index(after: colonIndex)...])) else { return nil }

        switch mode {
        case .none, .base64:
            return String(decoding: payload, as: UTF8.self)
        case .xor:
            return String(decoding: WYCryptor.xor(payload, key: activeKey), as: UTF8.self)
        case .aesGCM:
            guard let clear = WYCryptor.aesGCMDecrypt(payload, key: activeKey) else { return nil }
            return String(decoding: clear, as: UTF8.self)
        }
    }

    /// 把一行内容追加进日志文件(不存在时先创建文件与目录)
    private static func appendLine(_ line: String) {
        let path = logFilePath
        let fileManager = FileManager.default

        let directory = URL(fileURLWithPath: path).deletingLastPathComponent().path
        if !fileManager.fileExists(atPath: directory) {
            try? fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }

        if !fileManager.fileExists(atPath: path) {
            fileManager.createFile(atPath: path, contents: nil)
        }

        guard let fileHandle = FileHandle(forWritingAtPath: path) else { return }
        defer { fileHandle.closeFile() }
        fileHandle.seekToEndOfFile()

        if let data = (line + "\n").data(using: .utf8) {
            fileHandle.write(data)
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
