//
//  WYVideoPlayerSubtitleParser.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVFoundation
import UIKit

/// SRT 解析结果条目
struct WYVideoPlayerSubtitleCue {

    /// 起始时间，单位为秒
    let startTime: TimeInterval

    /// 结束时间，单位为秒
    let endTime: TimeInterval

    /// 字幕文本(多行已合并，内嵌换行保留)
    let text: String
}

/// SRT 字幕解析器与轨管理(内嵌轨交给系统渲染，外挂 SRT 自解析自渲染，只被播放器内部使用)
final class WYVideoPlayerSubtitleParser: NSObject {

    /// 字幕渲染标签(左下角跟随播放时间刷新)
    let subtitleLabel = UILabel()

    /// 字幕文字绘制属性
    private var textAttributes: [NSAttributedString.Key: Any] = [:]

    /// 字幕布局边距
    private var subtitleInsets = UIEdgeInsets.zero

    /// 当前解析出的外挂字幕条目
    private var cues: [WYVideoPlayerSubtitleCue] = []

    /// 全部可选字幕轨(内嵌轨在条目装载后收集，外挂轨由宿主追加，首项恒为 关闭 占位由播放器拼)
    private(set) var tracks: [WYVideoPlayerSubtitleTrack] = []

    /// 当前轨下标(-1 关闭)
    private(set) var selectedIndex = -1

    /// 渲染容器(标签加到播放器上)
    private weak var hostView: UIView?

    /**
     *  挂到播放器上并按配置摆字幕外观
     *
     *  @param player        播放器
     *  @param superview     字幕标签的父视图
     *
     */
    func attach(to superview: UIView) {
        hostView = superview
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        superview.addSubview(subtitleLabel)
        relayout()
    }

    /// 按配置刷新字幕外观与位置
    func applyConfiguration(_ configuration: WYVideoPlayerConfig) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .center
        subtitleInsets = UIEdgeInsets(top: 0, left: configuration.subtitleHorizontalInset, bottom: configuration.subtitleBottomInset, right: configuration.subtitleHorizontalInset)
        textAttributes = [.font: configuration.subtitleFont, .foregroundColor: configuration.subtitleTextColor, .strokeColor: configuration.subtitleStrokeColor, .strokeWidth: configuration.subtitleStrokeWidth, .paragraphStyle: paragraphStyle]
        subtitleLabel.font = configuration.subtitleFont
        // 描边用富文本属性画，普通 label 文字色保持可读
        subtitleLabel.textColor = configuration.subtitleTextColor
        subtitleLabel.shadowColor = nil
        subtitleLabel.shadowOffset = .zero
        if let text = subtitleLabel.text {
            subtitleLabel.attributedText = NSAttributedString(string: text, attributes: textAttributes)
        }
        relayout()
    }

    /// 布局字幕标签(底部居中)
    func relayout() {
        guard let hostView = hostView else { return }
        let width = max(0, hostView.bounds.width - subtitleInsets.left - subtitleInsets.right)
        let height = max(0, subtitleLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height)
        subtitleLabel.frame = CGRect(x: subtitleInsets.left, y: hostView.bounds.height - subtitleInsets.bottom - height, width: width, height: height)
    }

    /// 收集内嵌字幕轨(条目装载完成后调，收集前清掉旧的内嵌轨保留外挂轨)
    func collectNativeTracks(from item: AVPlayerItem) {
        tracks.removeAll { (track) in
            track.type == .native
        }
        guard let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else { return }
        for option in group.options {
            let name = option.displayName.isEmpty ? WYLocalized("字幕", table: WYBasisKitConfig.kitLocalizableTable) : option.displayName
            tracks.append(WYVideoPlayerSubtitleTrack(name: name, nativeOption: option))
        }
    }

    /// 追加一条外挂轨(不自动选中)
    func appendExternalTrack(_ track: WYVideoPlayerSubtitleTrack) {
        tracks.append(track)
    }

    /// 全部轨名(首项拼 关闭)
    var trackNames: [String] {
        return [WYLocalized("关闭", table: WYBasisKitConfig.kitLocalizableTable)] + tracks.map { $0.name }
    }

    /**
     *  选中字幕轨并渲染
     *
     *  @param index    轨下标(-1 关闭)，越界按关闭处理
     *  @param item     当前播放条目(内嵌轨要在它身上启停)
     *
     */
    func selectTrack(at index: Int, item: AVPlayerItem?) {
        selectedIndex = (index >= 0 && index < tracks.count) ? index : -1
        if let item = item,
           let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            if selectedIndex >= 0, tracks[selectedIndex].type == .native {
                item.select(tracks[selectedIndex].nativeOption, in: group)
            }else {
                item.select(nil, in: group)
            }
        }
        cues = []
        if selectedIndex >= 0 {
            let track = tracks[selectedIndex]
            if track.type == .externalSRT {
                if let srtURL = track.srtURL {
                    if let content = try? String(contentsOf: srtURL, encoding: .utf8) {
                        cues = Self.parse(content)
                    }
                }else if let srtText = track.srtText {
                    cues = Self.parse(srtText)
                }
            }
        }
        if selectedIndex >= 0 && tracks[selectedIndex].type == .native {
            // 内嵌轨由系统画面层直接渲染，标签层隐藏
            subtitleLabel.isHidden = true
        }else {
            subtitleLabel.isHidden = (selectedIndex < 0)
            subtitleLabel.text = nil
        }
    }

    /// 按播放时间刷新外挂字幕显示
    func update(time: TimeInterval) {
        guard tracks.indices.contains(selectedIndex), tracks[selectedIndex].type == .externalSRT else { return }
        let current = cues.first { time >= $0.startTime && time <= $0.endTime }
        if subtitleLabel.text != current?.text {
            subtitleLabel.attributedText = current.map { NSAttributedString(string: $0.text, attributes: textAttributes) }
            relayout()
        }
    }

    /// 解析 SRT 文本
    static func parse(_ content: String) -> [WYVideoPlayerSubtitleCue] {
        var result: [WYVideoPlayerSubtitleCue] = []
        // SRT 段以空行分隔，段内首行序号可省，时间行形如 00:00:01,000 --> 00:00:03,000
        let blocks = content.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n\n")
        for block in blocks {
            let lines = block.components(separatedBy: "\n").filter { $0.isEmpty == false }
            guard lines.count >= 2 else { continue }
            var timeLineIndex = 0
            if lines[0].contains("-->") == false {
                timeLineIndex = 1
            }
            guard lines.indices.contains(timeLineIndex), lines[timeLineIndex].contains("-->") else { continue }
            let parts = lines[timeLineIndex].components(separatedBy: "-->")
            guard parts.count == 2 else { continue }
            guard let start = Self.timeInterval(from: parts[0]), let end = Self.timeInterval(from: parts[1]) else { continue }
            let textLines = lines[(timeLineIndex + 1)...]
            let text = textLines.joined(separator: "\n")
            if text.isEmpty == false {
                result.append(WYVideoPlayerSubtitleCue(startTime: start, endTime: end, text: text))
            }
        }
        return result.sorted { $0.startTime < $1.startTime }
    }

    /// 时间串 00:00:01,000 转秒
    static func timeInterval(from text: String) -> TimeInterval? {
        let normalized = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        let parts = normalized.components(separatedBy: ":")
        guard parts.count == 3,
              let hours = Double(parts[0]),
              let minutes = Double(parts[1]),
              let seconds = Double(parts[2]) else { return nil }
        return hours * 3600 + minutes * 60 + seconds
    }
}
