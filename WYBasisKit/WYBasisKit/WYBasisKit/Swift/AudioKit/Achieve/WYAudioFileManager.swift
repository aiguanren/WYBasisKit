//
//  WYAudioFileManager.swift
//  WYBasisKit
//
//  Created by guanren on 2026/3/23.
//

import Foundation
import AVFoundation

internal final class WYAudioFileManager: NSObject {
    weak var kit: WYAudioKit?
    
    private let queue = DispatchQueue(label: "com.wy.audio.filemanager")
    var recordingsDirectory: WYAudioStorageDirectory = .temporary
    var downloadsDirectory: WYAudioStorageDirectory = .temporary
    var recordingsSubdirectory: String? = "Recordings"
    var downloadsSubdirectory: String? = "Downloads"
    
    private var downloadMapping: [String: URL] = [:] // remote.path -> local
    
    var recordingsDirectoryURL: URL {
        baseURL(for: recordingsDirectory).appendingPathComponent(recordingsSubdirectory ?? "")
    }
    
    var downloadsDirectoryURL: URL {
        baseURL(for: downloadsDirectory).appendingPathComponent(downloadsSubdirectory ?? "")
    }
    
    private func baseURL(for dir: WYAudioStorageDirectory) -> URL {
        switch dir {
        case .temporary: return FileManager.default.temporaryDirectory
        case .documents: return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        case .caches: return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        }
    }
    
    func ensureDirectoryExists() {
        queue.async {
            for url in [self.recordingsDirectoryURL, self.downloadsDirectoryURL] {
                try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            }
        }
    }
    
    func localURLForRemote(_ remote: URL) -> URL {
        let name = remote.lastPathComponent
        return downloadsDirectoryURL.appendingPathComponent(name)
    }
    
    func getAllRecordingsFiles() -> [URL] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: recordingsDirectoryURL, includingPropertiesForKeys: [.creationDateKey])) ?? []
        return urls.sorted { ($0.creationDate ?? Date()) > ($1.creationDate ?? Date()) }
    }
    
    func deleteRecordingFile(_ localUrl: URL?) {
        queue.async {
            if let url = localUrl {
                try? FileManager.default.removeItem(at: url)
            } else {
                try? FileManager.default.removeItem(at: self.recordingsDirectoryURL)
            }
        }
    }
    
    func getAllDownloads() -> [WYAudioDownloadInfo] {
        let files = (try? FileManager.default.contentsOfDirectory(at: downloadsDirectoryURL, includingPropertiesForKeys: nil)) ?? []
        return files.map { WYAudioDownloadInfo(remote: URL(string: "https://placeholder.com")!, local: $0) } // 实际可从mapping加载
    }
    
    func deleteDownloadFile(_ info: WYAudioDownloadInfo?) {
        queue.async {
            if let local = info?.local {
                try? FileManager.default.removeItem(at: local)
            } else {
                try? FileManager.default.removeItem(at: self.downloadsDirectoryURL)
            }
        }
    }
    
    func saveRecording(_ source: URL?, to destination: URL) {
        guard let source else { return }
        queue.async {
            try? FileManager.default.copyItem(at: source, to: destination)
        }
    }
    
    func getAudioDuration(for url: URL) -> TimeInterval {
        let asset = AVAsset(url: url)
        return asset.duration.seconds
    }
    
    func releaseResources() { }
    
    // init时确保目录
    override init() {
        super.init()
        ensureDirectoryExists()
    }
}
