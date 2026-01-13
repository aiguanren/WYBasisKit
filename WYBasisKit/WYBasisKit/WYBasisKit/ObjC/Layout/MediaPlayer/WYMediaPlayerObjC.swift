//
//  WYMediaPlayerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/5.
//

import UIKit

#if canImport(WYBasisKitSwift) && canImport(FSPlayer)

import FSPlayer
import WYBasisKitSwift

@objc public extension WYMediaPlayer {
    
    /// 播放器组件
    @objc(ijkPlayer)
    public var ijkPlayerObjC: FSPlayer? {
        get { return ijkPlayer }
        set { ijkPlayer = newValue }
    }
    
    /// 当前正在播放的流地址
    @objc(mediaUrl)
    public var mediaUrlObjC: String {
        return mediaUrl
    }
    
    /// 播放器配置选项 具体配置可参考 https://github.com/Bilibili/ijkplayer/blob/master/ijkmedia/ijkplayer/ff_ffplay_options.h
    @objc(options)
    public var optionsObjC: FSOptions? {
        get { return options }
        set { options = newValue }
    }
    
    /// 播放器状态回调代理
    @objc(delegate)
    public weak var delegateObjC: WYMediaPlayerDelegate? {
        get { return delegate }
        set { delegate = newValue }
    }
    
    /// 循环播放的次数，为0表示无限次循环(点播流有效)
    @objc(looping)
    public var loopingObjC: Int64 {
        get { return looping }
        set { looping = newValue }
    }
    
    /// 播放失败后重试次数，默认2次
    @objc(failReplay)
    public var failReplayObjC: Int {
        get { return failReplay }
        set { failReplay = newValue }
    }
    
    /// 是否需要自动播放
    @objc(shouldAutoplay)
    public var shouldAutoplayObjC: Bool {
        get { return shouldAutoplay }
        set { shouldAutoplay = newValue }
    }
    
    /// 视频缩放模式
    @objc(scalingStyle)
    public var scalingStyleObjC: FSScalingMode {
        get { return scalingStyle }
        set { scalingStyle = newValue }
    }
    
    /// 播放器状态
    @objc(state)
    public var stateObjC: WYMediaPlayerState {
        return state
    }
    
    /// 当前时间点的缩略图
    @objc(thumbnailImageAtCurrentTime)
    public var thumbnailImageAtCurrentTimeObjC: UIImage? {
        return thumbnailImageAtCurrentTimeObjC
    }
    
    /**
     * 开始播放
     * @param url 要播放的流地址
     * @param background 视屏背景图(支持UIImage、URL、String)
     * @param placeholder 视屏背景图占位图
     */
    @objc(playWithUrl:)
    public func playObjC(with url: String) {
        playObjC(with: url, placeholder: nil)
    }
    @objc(playWithUrl:placeholder:)
    public func playObjC(with url: String, placeholder: UIImage? = nil) {
        play(with: url, placeholder: placeholder)
    }
    
    /// 音量设置，为0时表示静音
    @objc(playbackVolume:)
    public func playbackVolumeObjC(_ volume: CGFloat) {
        playbackVolume(volume)
    }
    
    /// 继续播放(仅适用于暂停后恢复播放)
    @objc(play)
    public func playObjC() {
        play()
    }
    
    /// 快进/快退
    @objc(playbackTime:)
    public func playbackTimeObjC(_ time: TimeInterval) {
        playbackTime(time)
    }
    
    /// 倍速播放
    @objc(playbackRate:)
    public func playbackRateObjC(_ rate: CGFloat) {
        playbackRate(rate)
    }
    
    /// 挂载并激活字幕(本地/网络)
    @objc(loadThenActiveSubtitleWithUrl:)
    @discardableResult
    public func loadThenActiveSubtitleObjC(_ url: URL) -> Bool {
        return loadThenActiveSubtitle(url)
    }
    
    /// 仅挂载不激活字幕(本地/网络)
    @objc(loadSubtitleOnlyWithUrl:)
    @discardableResult
    public func loadSubtitleOnlyObjC(_ url: URL) -> Bool {
        return loadSubtitleOnly(url)
    }
    
    /// 批量挂载不激活字幕(本地/网络)
    @objc(loadSubtitleOnlyWithUrls:)
    @discardableResult
    public func loadSubtitleOnlyObjC(_ urls: [URL]) -> Bool {
        return loadSubtitleOnly(urls)
    }
    
    /// 激活字幕(没有激活的字幕调用激活，相同路径的字幕重复挂载会失败)
    @objc(exchangeSelectedStreamWithIndex:)
    public func exchangeSelectedStreamObjC(_ streamIndex: Int32) {
        exchangeSelectedStream(streamIndex)
    }
    
    /// 关闭字幕(FS_VAL_TYPE__VIDEO, FS_VAL_TYPE__AUDIO, FS_VAL_TYPE__SUBTITLE)
    @objc(closeCurrentStreamWithStyle:)
    public func closeCurrentStreamObjC(_ streamStyle: String) {
        closeCurrentStream(streamStyle)
    }
    
    /// 播放画面显示模式
    @objc(scalingStyle:)
    public func scalingStyleObjC(_ style: FSScalingMode) {
        scalingStyle(style)
    }
    
    /// 逐帧播放
    @objc(stepToNextFrame)
    public func stepToNextFrameObjC() {
        stepToNextFrame()
    }
    
    /// 获取缓冲进度
    @objc(bufferingProgress)
    public func bufferingProgressObjC() -> Int {
        return bufferingProgress()
    }
    
    /// 获取视频时长
    @objc(videoDuration)
    public func videoDurationObjC() -> TimeInterval {
        return videoDuration()
    }
    
    /// 设定音频延迟(单位：s)
    @objc(audioExtraDelay:)
    public func audioExtraDelayObjC(_ delay: CGFloat) {
        audioExtraDelay(delay)
    }
    
    /// 设定字幕延迟(单位：s)
    @objc(subtitleExtraDelay:)
    public func subtitleExtraDelayObjC(_ delay: CGFloat) {
        subtitleExtraDelay(delay)
    }
    
    /// 获取预加载时长(单位：s)
    @objc(playableDuration)
    public func playableDurationObjC() -> TimeInterval {
        return playableDuration()
    }
    
    /// 获取下载速度(单位：byte)
    @objc(downloadSpeed)
    public func downloadSpeedObjC() -> Int64 {
        return downloadSpeed()
    }
    
    /// 暂停播放
    @objc(pause)
    public func pauseObjC() {
        pause()
    }
    
    /// 截取当前显示画面
    @objc(currentSnapshot)
    public func currentSnapshotObjC() -> UIImage {
        return currentSnapshot()
    }
    
    /// 调整字幕样式(支持设置字体，字体颜色，边框颜色，背景颜色等)
    @objc(subtitlePreference:)
    public func subtitlePreferenceObjC(_ preference: FSSubtitlePreference) {
        subtitlePreference(preference)
    }
    
    /// 旋转画面
    @objc(rotatePreference:)
    public func rotatePreferenceObjC(_ preference: FSRotatePreference) {
        rotatePreference(preference)
    }
    
    /// 修改画面色彩
    @objc(colorPreference:)
    public func colorPreferenceObjC(_ preference: FSColorConvertPreference) {
        colorPreference(preference)
    }
    
    /// 设置画面比例
    @objc(darPreference:)
    public func darPreferenceObjC(_ preference: FSDARPreference) {
        darPreference(preference)
    }
    
    /**
     * 停止播放(无法再次恢复播放)
     * @param keepLast 是否要保留最后一帧图像
     */
    @objc(stopWithKeepLast:)
    public func stopObjC(_ keepLast: Bool = true) {
        stop(keepLast)
    }
    
    /// 释放播放器组件
    @objc(releaseAll)
    public func releaseAllObjC() {
        releaseAll()
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
}
#endif
