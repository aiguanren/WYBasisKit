//
//  WYAudioKitProperty.swift
//  WYBasisKit
//
//  Created by guanren on 2026/3/23.
//

import Foundation
import AVFoundation

// 使用 fileprivate extension，让同一个模块内的主类能可靠访问
internal extension WYAudioKit {
//    
//    // 当前正在使用的 AVPlayer（公开属性中已通过 player.isPlaying 暴露）
//    var audioPlayer: AVPlayer? {
//        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_audioPlayer) as? AVPlayer }
//        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_audioPlayer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
//    }
//    
//    var recorder: WYAudioRecorder {
//        get {
//            if let obj = objc_getAssociatedObject(self, &WYAssociatedKeys.wy_recorder) as? WYAudioRecorder {
//                return obj
//            }
//            let newRecorder = WYAudioRecorder()
//            newRecorder.kit = self
//            self.recorder = newRecorder   // 通过 setter 存储
//            return newRecorder
//        }
//        set {
//            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_recorder, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    var player: WYAudioPlayer {
//        get {
//            if let obj = objc_getAssociatedObject(self, &WYAssociatedKeys.wy_player) as? WYAudioPlayer {
//                return obj
//            }
//            let newPlayer = WYAudioPlayer()
//            newPlayer.kit = self
//            self.player = newPlayer
//            return newPlayer
//        }
//        set {
//            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_player, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    var downloader: WYAudioDownloader {
//        get {
//            if let obj = objc_getAssociatedObject(self, &WYAssociatedKeys.wy_downloader) as? WYAudioDownloader {
//                return obj
//            }
//            let newDownloader = WYAudioDownloader()
//            newDownloader.kit = self
//            self.downloader = newDownloader
//            return newDownloader
//        }
//        set {
//            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_downloader, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    var converter: WYAudioConverter {
//        get {
//            if let obj = objc_getAssociatedObject(self, &WYAssociatedKeys.wy_converter) as? WYAudioConverter {
//                return obj
//            }
//            let newConverter = WYAudioConverter()
//            newConverter.kit = self
//            self.converter = newConverter
//            return newConverter
//        }
//        set {
//            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_converter, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    var fileManager: WYAudioFileManager {
//        get {
//            if let obj = objc_getAssociatedObject(self, &WYAssociatedKeys.wy_fileManager) as? WYAudioFileManager {
//                return obj
//            }
//            let newFileManager = WYAudioFileManager()
//            newFileManager.kit = self
//            self.fileManager = newFileManager
//            return newFileManager
//        }
//        set {
//            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_fileManager, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    // 波形数据（如果需要公开可再暴露）
//    var recordingWaveform: [Float] {
//        get {
//            objc_getAssociatedObject(self, &WYAssociatedKeys.wy_recordingWaveform) as? [Float] ?? []
//        }
//        set {
//            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_recordingWaveform, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
    private struct WYAssociatedKeys {
        static var wy_audioPlayer: UInt8 = 0
        static var wy_recorder: UInt8 = 0
        static var wy_player: UInt8 = 0
        static var wy_downloader: UInt8 = 0
        static var wy_converter: UInt8 = 0
        static var wy_fileManager: UInt8 = 0
        static var wy_recordingWaveform: UInt8 = 0
    }
}
