//
//  WYAudioKit+Setup.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/21.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation
import AVFoundation

/// WYAudioKit 初始化辅助，音频会话配置、下载会话按需创建、存储目录创建
extension WYAudioKit {
    
    /// 配置音频会话（AVAudioSession）
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            if #available(iOS 13.0, *) {
                try session.setCategory(.playAndRecord, mode: .default, options: [AVAudioSession.CategoryOptions.allowBluetoothHFP, .defaultToSpeaker, .allowAirPlay])
            } else {
                try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
            }
            try session.setActive(true)
        } catch {
            delegate?.wy_audioTaskDidFailed?(audioKit: self,
                                             url: URL(fileURLWithPath: ""),
                                             error: .sessionConfigurationFailed,
                                             description: error.localizedDescription)
        }
    }
    
    /// 按需创建并返回下载会话(releaseAll会把会话作废置nil，之后再次下载时靠这里重建，旧版置nil后继续下载会拿到死会话直接崩)
    @discardableResult
    func ensureDownloadSession() -> URLSession {
        if let downloadSession = state.downloadSession {
            return downloadSession
        }
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 600
        // delegate必须走弱引用代理(会话强持有delegate，直接传self就形成自持，不调releaseAll永远释放不了)
        let session = URLSession(configuration: config,
                                 delegate: WYWeakSessionDelegate(kit: self),
                                 delegateQueue: OperationQueue.main)
        state.downloadSession = session
        return session
    }
    
    /**
     根据目录类型和子目录名称创建目录 URL，如果目录不存在则创建
     - Parameters:
       - type: 存储目录类型
       - subdirectory: 子目录名称（可选）
     - Returns: 目标目录 URL
     */
    func createDirectory(for type: WYAudioStorageDirectory, subdirectory: String?) -> URL {
        let fileManager = FileManager.default
        var baseURL: URL
        switch type {
        case .temporary:
            baseURL = fileManager.temporaryDirectory
        case .documents:
            baseURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        case .caches:
            baseURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        }
        let targetURL = subdirectory.map { baseURL.appendingPathComponent($0) } ?? baseURL
        if !fileManager.fileExists(atPath: targetURL.path) {
            do {
                try fileManager.createDirectory(at: targetURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            } catch {
                delegate?.wy_audioTaskDidFailed?(audioKit: self,
                                                 url: targetURL,
                                                 error: .directoryCreationFailed,
                                                 description: error.localizedDescription)
            }
        }
        return targetURL
    }
}
