//
//  WYVideoPlayerSubtitle.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVFoundation
import Foundation

/// 字幕轨来源
@objc public enum WYVideoPlayerSubtitleTrackType: Int {

    /// 视频文件内嵌的字幕轨(如 WebVTT、CC、tx3g)
    case native = 0

    /// 外挂 SRT 字幕(系统不认 SRT，由播放器自解析自渲染)
    case externalSRT
}

/// 一条可选字幕轨
public struct WYVideoPlayerSubtitleTrack: Equatable {

    /// 展示名，如 中文字幕、关闭
    public let name: String

    /// 字幕来源
    public let type: WYVideoPlayerSubtitleTrackType

    /// 外挂 SRT 的文件地址(来源是内嵌轨时为 nil)
    public let srtURL: URL?

    /// 外挂 SRT 的文本内容(与 srtURL 二选一，都有时优先地址)
    public let srtText: String?

    /// 内嵌轨对应的系统选项(来源是外挂 SRT 时为 nil)
    let nativeOption: AVMediaSelectionOption?

    /**
     *  建一条内嵌字幕轨
     *
     *  @param name     展示名
     *  @param option   系统取到的字幕轨选项
     *
     */
    public init(name: String, nativeOption: AVMediaSelectionOption) {
        self.name = name
        self.type = .native
        self.nativeOption = nativeOption
        self.srtURL = nil
        self.srtText = nil
    }

    /**
     *  建一条外挂 SRT 字幕轨
     *
     *  @param name     展示名
     *  @param srtURL   SRT 文件地址
     *
     */
    public init(name: String, srtURL: URL) {
        self.name = name
        self.type = .externalSRT
        self.nativeOption = nil
        self.srtURL = srtURL
        self.srtText = nil
    }

    /**
     *  建一条内联 SRT 文本字幕轨
     *
     *  @param name     展示名
     *  @param srtText  SRT 格式的文本内容
     *
     */
    public init(name: String, srtText: String) {
        self.name = name
        self.type = .externalSRT
        self.nativeOption = nil
        self.srtURL = nil
        self.srtText = srtText
    }
}
