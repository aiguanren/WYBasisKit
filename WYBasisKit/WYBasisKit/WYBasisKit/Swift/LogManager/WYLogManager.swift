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
 *   @param messages 要输出的日志内容
 *   @param outputMode 日志输出模式
 *   @param file 文件名(自动捕获)
 *   @param function 函数名(自动捕获)
 *   @param line 代码行号(自动捕获)
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

    /// 自定义日志文件名(不含扩展名，不设置时默认名=本地化App名+本地化"日志"词，如中文名"语音工坊"生成"语音工坊日志"、英文名"VoiceFactory"生成"VoiceFactoryLog")
    nonisolated(unsafe) public static var logFileName: String?

    /// 日志加密模式(默认aesGCM，加密后文件内容与导出附件均为密文，只能通过decryptedLogText()或配套解密脚本阅读)
    nonisolated(unsafe) public static var encryptionMode: WYLogEncryptionMode = .aesGCM

    /// 日志加密密钥(xor与aesGCM使用，不设置时按包名派生，接入方建议在首次写日志前设置)
    nonisolated(unsafe) public static var encryptionKey: Data?

    /**
     * 读取整个日志文件并解密成明文
     * @return 解密后的完整日志文本(历史明文条目原样保留，解密失败的条目自动跳过，文件不存在时返回空串)
     */
    public static func decryptedLogText() -> String {
        guard let text = try? String(contentsOfFile: logFilePath, encoding: .utf8) else { return "" }
        let entries = text.split(separator: "\n", omittingEmptySubsequences: true).compactMap { decryptLine(String($0)) }
        return entries.joined(separator: logEntrySeparator)
    }

    /**
     * 同步加密写入一条日志
     @param content 要写入的完整日志内容(崩溃捕获等进程即将退出的场景用，不走异步队列确保落盘)
     */
    public static func writeEncryptedSynchronously(_ content: String) {
        appendLine(encryptEntry(content))
    }
    
    /**
     * 日志打印
     *   @param messages 要输出的日志内容
     *   @param outputMode 日志输出模式
     *   @param file 文件名(自动捕获)
     *   @param function 函数名(自动捕获)
     *   @param line 代码行号(自动捕获)
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
        let path = logFilePath
        logQueue.async {
            let fileManager = FileManager.default
            
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
     *   @param contentView 预览按钮的父控件，如果不传则为当前正在显示的Window
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
    
    /// 悬浮按钮
    internal static var floatingButton: WYLogFloatingButton?
}

