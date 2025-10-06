//
//  WYMediaPlayerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/5.
//

//import UIKit
//
//#if WYBasisKit_Supports_MediaPlayer_FS
//
//import FSPlayer
//
//@objcMembers public class WYMediaPlayerObjC: UIImageView {
//    
//    /// 播放器组件
//    public var ijkPlayer: FSPlayer? {
//        get { return  }
//        set {  }
//    }
//    
//    /// 当前正在播放的流地址
//    public private(set) var mediaUrl: String = ""
//    
//    /// 播放器配置选项 具体配置可参考 https://github.com/Bilibili/ijkplayer/blob/master/ijkmedia/ijkplayer/ff_ffplay_options.h
//    public var options: FSOptions?
//    
//    /// 播放器状态回调代理
//    public weak var delegate: WYMediaPlayerDelegate?
//    
//    /// 循环播放的次数，为0表示无限次循环(点播流有效)
//    public var looping: Int64 = 0
//    
//    /// 播放失败后重试次数，默认2次
//    public var failReplay: Int = 2
//    
//    /// 是否需要自动播放
//    public var shouldAutoplay: Bool = true
//    
//    /// 视频缩放模式
//    public var scalingStyle: FSScalingMode = .aspectFit
//    
//    /// 播放器状态
//    public private(set) var state: WYMediaPlayerState = .unknown
//    
//    /// 当前时间点的缩略图
//    public var thumbnailImageAtCurrentTime: UIImage? {
//        return ijkPlayer?.thumbnailImageAtCurrentTime()
//    }
//    
//    /**
//     * 开始播放
//     * @param url 要播放的流地址
//     * @param background 视屏背景图(支持UIImage、URL、String)
//     * @param placeholder 视屏背景图占位图
//     */
//    public func play(with url: String, placeholder: UIImage? = nil) {
//        
//    }
//    
//    /// 音量设置，为0时表示静音
//    public func playbackVolume(_ volume: CGFloat) {
//        
//    }
//    
//    /// 继续播放(仅适用于暂停后恢复播放)
//    public func play() {
//        
//    }
//    
//    /// 快进/快退
//    public func playbackTime(_ playbackTime: TimeInterval) {
//        
//    }
//    
//    /// 倍速播放
//    public func playbackRate(_ playbackRate: CGFloat) {
//        
//    }
//    
//    /// 挂载并激活字幕(本地/网络)
//    public func loadThenActiveSubtitle(_ url: URL) -> Bool {
//        return ijkPlayer?.loadThenActiveSubtitle(url) ?? false
//    }
//    
//    /// 仅挂载不激活字幕(本地/网络)
//    public func loadSubtitleOnly(_ url: URL) -> Bool {
//        return ijkPlayer?.loadSubtitleOnly(url) ?? false
//    }
//    
//    /// 批量挂载不激活字幕(本地/网络)
//    public func loadSubtitleOnly(_ urls: [URL]) -> Bool {
//        return ijkPlayer?.loadSubtitlesOnly(urls) ?? false
//    }
//    
//    /// 激活字幕(没有激活的字幕调用激活，相同路径的字幕重复挂载会失败)
//    public func exchangeSelectedStream(_ streamIndex: Int32) {
//        ijkPlayer?.exchangeSelectedStream(streamIndex)
//    }
//    
//    /// 关闭字幕(FS_VAL_TYPE__VIDEO, FS_VAL_TYPE__AUDIO, FS_VAL_TYPE__SUBTITLE)
//    public func closeCurrentStream(_ streamStyle: String) {
//        ijkPlayer?.closeCurrentStream(streamStyle)
//    }
//    
//    /// 播放画面显示模式
//    public func scalingStyle(_ scalingStyle: FSScalingMode) {
//        ijkPlayer?.scalingMode = scalingStyle
//        self.scalingStyle = scalingStyle
//    }
//    
//    /// 逐帧播放
//    public func stepToNextFrame() {
//        ijkPlayer?.stepToNextFrame()
//    }
//    
//    /// 获取缓冲进度
//    public func bufferingProgress() -> Int {
//        return ijkPlayer?.bufferingProgress ?? 0
//    }
//    
//    /// 获取视频时长
//    public func videoDuration() -> TimeInterval {
//        return ijkPlayer?.duration ?? 0
//    }
//    
//    /// 设定音频延迟(单位：s)
//    public func audioExtraDelay(_ audioExtraDelay: CGFloat) {
//        ijkPlayer?.currentAudioExtraDelay = Float(audioExtraDelay)
//    }
//    
//    /// 设定字幕延迟(单位：s)
//    public func subtitleExtraDelay(_ subtitleExtraDelay: CGFloat) {
//        ijkPlayer?.currentSubtitleExtraDelay = Float(subtitleExtraDelay)
//    }
//    
//    /// 获取预加载时长(单位：s)
//    public func playableDuration() -> TimeInterval {
//        return ijkPlayer?.playableDuration ?? 0
//    }
//    
//    /// 获取下载速度(单位：byte)
//    public func downloadSpeed() -> Int64 {
//        return ijkPlayer?.currentDownloadSpeed() ?? 0
//    }
//    
//    /// 暂停播放
//    public func pause() {
//        ijkPlayer?.pause()
//    }
//    
//    /// 截取当前显示画面
//    public func currentSnapshot() -> UIImage {
//        return ijkPlayer?.view.snapshot() ?? UIImage()
//    }
//    
//    /// 调整字幕样式(支持设置字体，字体颜色，边框颜色，背景颜色等)
//    public func subtitlePreference(_ subtitlePreference: FSSubtitlePreference) {
//        ijkPlayer?.subtitlePreference = subtitlePreference
//    }
//    
//    /// 旋转画面
//    public func rotatePreference(_ rotatePreference: FSRotatePreference) {
//        ijkPlayer?.view.rotatePreference = rotatePreference
//        if ijkPlayer?.isPlaying() ?? false {
//            ijkPlayer?.view.setNeedsRefreshCurrentPic()
//        }
//    }
//    
//    /// 修改画面色彩
//    public func colorPreference(_ colorPreference: FSColorConvertPreference) {
//        ijkPlayer?.view.colorPreference = colorPreference
//        if ijkPlayer?.isPlaying() ?? false {
//            ijkPlayer?.view.setNeedsRefreshCurrentPic()
//        }
//    }
//    
//    /// 设置画面比例
//    public func darPreference(_ darPreference: FSDARPreference) {
//        ijkPlayer?.view.darPreference = darPreference
//        if ijkPlayer?.isPlaying() ?? false {
//            ijkPlayer?.view.setNeedsRefreshCurrentPic()
//        }
//    }
//    
//    /**
//     * 停止播放(无法再次恢复播放)
//     * @param keepLast 是否要保留最后一帧图像
//     */
//    public func stop(_ keepLast: Bool = true) {
//        
//        guard let player = ijkPlayer else {
//            return
//        }
//        
//        if keepLast {
//            image = player.thumbnailImageAtCurrentTime()
//        }
//        options = nil
//        release()
//    }
//    
//    /// 释放播放器组件
//    public func release() {
//        
//        guard let player = ijkPlayer else {
//            return
//        }
//        player.stop()
//        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FSPlayerDidFinish, object: ijkPlayer)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FSPlayerPlaybackStateDidChange, object: ijkPlayer)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FSPlayerLoadStateDidChange, object: ijkPlayer)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FSPlayerFirstVideoFrameRendered, object: ijkPlayer)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FSPlayerIsPreparedToPlay, object: ijkPlayer)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FSPlayerSelectedStreamDidChange, object: ijkPlayer)
//        
//        ijkPlayer?.shutdown()
//        ijkPlayer?.view.removeFromSuperview()
//        ijkPlayer = nil
//    }
//    
//    deinit {
//        release()
//    }
//    
//    /*
//     // Only override draw() if you perform custom drawing.
//     // An empty implementation adversely affects performance during animation.
//     override func draw(_ rect: CGRect) {
//     // Drawing code
//     }
//     */
//}
//#endif
