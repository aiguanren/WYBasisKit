//
//  WYAudioConverter.swift
//  WYBasisKit
//
//  Created by guanren on 2026/3/23.
//

import Foundation
import AVFoundation

internal final class WYAudioConverter: NSObject {
    weak var kit: WYAudioKit?
    private let queue = DispatchQueue(label: "com.wy.audio.converter")
    private var exportSessions: [URL: AVAssetExportSession] = [:]
    
    func convertAudioFormat(sourceUrls: [URL], target: WYAudioFormat, success: @escaping ([URL]) -> Void, failed: @escaping (Error?) -> Void) {
        var outputs: [URL] = []
        let group = DispatchGroup()
        
        for source in sourceUrls {
            group.enter()
            queue.async {
                let asset = AVAsset(url: source)
                guard let export = AVAssetExportSession(asset: asset, presetName: target == .m4a ? AVAssetExportPresetAppleM4A : AVAssetExportPresetPassthrough) else {
                    group.leave()
                    return
                }
                let outputURL = source.deletingPathExtension().appendingPathExtension(target.extensionName)
                export.outputURL = outputURL
                export.outputFileType = target.avFileType
                export.exportAsynchronously {
                    if export.status == .completed {
                        outputs.append(outputURL)
                    }
                    group.leave()
                }
                self.exportSessions[source] = export
            }
        }
        
        group.notify(queue: .main) {
            success(outputs)
        }
    }
    
    func stopAudioFormatConvert(_ localUrls: [URL]?) {
        let urls = localUrls ?? Array(exportSessions.keys)
        for u in urls {
            exportSessions[u]?.cancelExport()
        }
    }
    
    func releaseResources() {
        stopAudioFormatConvert(nil)
    }
}
