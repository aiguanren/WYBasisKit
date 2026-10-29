//
//  WYLogManager+Implementation.swift
//  WYBasisKit
//

import Foundation

extension WYLogManager {

    /// 写入日志文件
    static func saveLogToFile(_ log: String) {
        let path = logFilePath
        let entry = encryptEntry(log)
        logQueue.async {
            appendLine(entry, filePath: path)
        }
    }

    /// 写文件使用串行队列，避免并发冲突
    static let logQueue = DispatchQueue(label: "com.WYBasisKit.WYLogManager.queue")

    private static let appendLock = NSLock()

    /// 日志分隔符（用于日志条目之间的换行与逻辑隔断）
    internal static let logEntrySeparator = "\n\n\n"

    /// 加密条目行前缀(带版本号，文件里每行一条密文，解密端据此识别格式)
    private static let encryptedLinePrefix = "WYLOG1:"

    /// 默认密钥派生盐(接入方未设置encryptionKey时与包名一起喂PBKDF2派生日志密钥，发版时随机换新值可让照旧默认派生写的解密脚本失效，设了自定义密钥的接入方不受影响)
    private static let internalSeedValue = "c079b05228d588a6"

    /// 实际生效的密钥(接入方设置过就用接入方的，否则按包名与内部常量派生32字节)
    private static var activeKey: Data {
        if let key = encryptionKey, key.isEmpty == false {
            return key
        }
        let bundleId = WYProjectInfo.appIdentifier.isEmpty ? "WYBasisKit" : WYProjectInfo.appIdentifier
        return WYCryptor.pbkdf2(password: bundleId, salt: internalSeedValue, rounds: 4096, length: 32) ?? Data((bundleId + internalSeedValue).utf8)
    }

    /// 解析日志文件名(自定义名优先，默认名=本地化App名+本地化"日志"词，App名缺失或清洗为空回落到包名末段)
    static func resolvedFileName() -> String {
        let fallbackName = WYProjectInfo.appIdentifier.isEmpty ? "App" : WYProjectInfo.appIdentifier.components(separatedBy: ".").last ?? "App"

        if let custom = logFileName?.trimmingCharacters(in: .whitespacesAndNewlines), custom.isEmpty == false {
            let sanitized = sanitizeFileName(custom)
            let suffix = ".log"
            let name = sanitized.lowercased().hasSuffix(suffix) ? String(sanitized.dropLast(suffix.count)) : sanitized
            return name.isEmpty == false ? name : fallbackName
        }

        let displayName = WYProjectInfo.appStoreName.isEmpty ? WYProjectInfo.projectName : WYProjectInfo.appStoreName

        let sanitizedName = sanitizeFileName(displayName)
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
     @param entry 要加密的完整日志条目
     * @return 带格式前缀的单行密文(加密失败时回落明文，保证日志不丢)
     */
    static func encryptEntry(_ entry: String) -> String {
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
     @param line 日志文件里的一行
     * @return 解密后的明文条目(不带加密前缀的历史明文原样返回，格式损坏或解密失败的行返回nil由调用方丢弃)
     */
    static func decryptLine(_ line: String) -> String? {
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

    static func decryptText(_ text: String) -> String {
        var entries: [String] = []
        var plainText = ""
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix(encryptedLinePrefix) {
                if plainText.isEmpty == false {
                    entries.append(plainText)
                    plainText = ""
                }
                if let entry = decryptLine(String(line)) {
                    entries.append(entry)
                }
            } else {
                let endIndex = line.endIndex < text.endIndex ? text.index(after: line.endIndex) : line.endIndex
                plainText += text[line.startIndex..<endIndex]
            }
        }
        if plainText.isEmpty == false {
            entries.append(plainText)
        }
        return entries.joined(separator: logEntrySeparator)
    }

    /// 把一行内容追加进日志文件(不存在时先创建文件与目录)
    static func appendLine(_ line: String, filePath: String? = nil) {
        appendLock.lock()
        defer { appendLock.unlock() }
        let path = filePath ?? logFilePath
        let fileManager = FileManager.default

        let directory = URL(fileURLWithPath: path).deletingLastPathComponent().path
        if !fileManager.fileExists(atPath: directory) {
            try? fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }

        if !fileManager.fileExists(atPath: path) {
            fileManager.createFile(atPath: path, contents: nil)
        }

        guard let fileHandle = FileHandle(forUpdatingAtPath: path) else { return }
        defer { fileHandle.closeFile() }
        let offset = fileHandle.seekToEndOfFile()
        var needsLineBreak = false
        if offset > 0 {
            fileHandle.seek(toFileOffset: offset - 1)
            needsLineBreak = fileHandle.readData(ofLength: 1).last != 10
            fileHandle.seekToEndOfFile()
        }

        if let data = ((needsLineBreak ? "\n" : "") + line + "\n").data(using: .utf8) {
            fileHandle.write(data)
        }
    }
}
