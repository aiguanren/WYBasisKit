//
//  WYLogManager.swift
//  WYBasisKit
//
//  Created by guanren on 2025/7/26.
//

import UIKit
import Foundation
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

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
@objc(WYLogOutputMode)
@frozen public enum WYLogOutputModeObjC: Int {
    
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

@objc(WYLogManager)
@objcMembers public class WYLogManagerObjC: NSObject {
    
    /// 日志文件路径（可根据路径获取并导出显示或者上传）
    @objc public static var logFilePath: String {
        return WYLogManager.logFilePath
    }
    
    /**
     * 日志
     * - Parameters:
     *   - messages: 要输出的日志内容
     *   - outputMode: 日志输出模式
     */
    @objc public static var output: @convention(block) (Any) -> Void {
        return { messages in
            WYLogManager.output(messages)
        }
    }
    
    @objc public static var outputWithMode: @convention(block) (Any, WYLogOutputModeObjC) -> Void {
        return { messages, outputMode in
            WYLogManager.output(messages, outputMode: WYLogOutputMode(rawValue: outputMode.rawValue) ?? .debugConsoleOnly)
        }
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
    @objc public static func output(_ messages: Any, outputMode: WYLogOutputModeObjC = .debugConsoleOnly, file: String = #file, function: String = #function, line: Int = #line) {
        WYLogManager.output(messages, outputMode: WYLogOutputMode(rawValue: outputMode.rawValue) ?? .debugConsoleOnly, file: file, function: function, line: line)
    }
    
    /**
     * 清除日志文件
     * - 注意：该操作不可恢复，仅清除当前 logFilePath 下的日志文件
     */
    @objc public static func clearLogFile() {
        WYLogManager.clearLogFile()
    }
    
    /**
     * 显示预览组件
     * - Parameters:
     *   - contentView: 预览按钮的父控件，如果不传则为当前正在显示的Window
     */
    @objc public static func showPreview() {
        showPreview(UIApplication.shared.wy_keyWindow)
    }
    @objc public static func showPreview(_ contentView: UIView = UIApplication.shared.wy_keyWindow) {
        WYLogManager.showPreview(contentView)
    }
    
    /// 移除预览组件
    @objc public static func removePreview() {
        WYLogManager.removePreview()
    }
}
