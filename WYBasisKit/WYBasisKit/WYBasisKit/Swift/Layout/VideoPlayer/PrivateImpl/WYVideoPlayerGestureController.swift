//
//  WYVideoPlayerGestureController.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVFoundation
import MediaPlayer
import UIKit

/// 播放器手势控制(单击显壳、双击播停、横滑快进快退、长按临时倍速、左半竖滑音量右半竖滑亮度，只被播放器内部使用)
final class WYVideoPlayerGestureController: NSObject, UIGestureRecognizerDelegate {

    /// 手势作用其上的播放器
    private weak var player: WYVideoPlayer?

    /// 单击
    private let tapGesture = UITapGestureRecognizer()

    /// 双击
    private let doubleTapGesture = UITapGestureRecognizer()

    /// 横滑快进(带竖滑音量亮度，一个 pan 按首滑方向分流)
    private let panGesture = UIPanGestureRecognizer()

    /// 长按临时倍速
    private let longPressGesture = UILongPressGestureRecognizer()

    /// 本轮 pan 的方向(0 未定 1 横滑快进 2 左侧竖滑音量 3 右侧竖滑亮度)
    private var panDirection = 0

    /// 横滑开始时的播放位置
    private var seekBaseTime: TimeInterval = 0

    /// 音量亮度滑动开始时的值
    private var panBaseValue: CGFloat = 0

    /// 系统音量视图(滑音量时隐藏系统浮层)
    private let volumeView = MPVolumeView()

    /// 手势开始前的倍速(长按结束后恢复)
    private var rateBeforeLongPress: Float = 1.0

    init(playerHolder: WYVideoPlayer?) {
        self.player = playerHolder
        super.init()
        tapGesture.addTarget(self, action: #selector(handleTap(_:)))
        doubleTapGesture.addTarget(self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        panGesture.addTarget(self, action: #selector(handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        longPressGesture.addTarget(self, action: #selector(handleLongPress(_:)))
        tapGesture.require(toFail: doubleTapGesture)
        tapGesture.delegate = self
        doubleTapGesture.delegate = self
        panGesture.delegate = self
        longPressGesture.delegate = self
        // 系统音量浮层藏在屏外，滑动调音量时不再弹系统界面
        volumeView.frame = CGRect(x: -2000, y: -200, width: 1, height: 1)
    }

    /// 绑定播放器并挂手势(播放器先建手势器再调 super.init 后回绑)
    func bind(player: WYVideoPlayer) {
        self.player = player
        player.addGestureRecognizer(tapGesture)
        player.addGestureRecognizer(doubleTapGesture)
        player.addGestureRecognizer(panGesture)
        player.addGestureRecognizer(longPressGesture)
        player.addSubview(volumeView)
    }

    /// 把全屏旋转坐标换算回竖屏手势语义坐标(横屏内容的上下左右与竖屏是转置关系)
    private func semanticLocation(_ point: CGPoint, in player: WYVideoPlayer) -> CGPoint {
        guard player.contentRotationAngle != 0 else { return point }
        let bounds = player.bounds
        return CGPoint(x: player.contentRotationAngle > 0 ? point.y : bounds.height - point.y,
                       y: player.contentRotationAngle > 0 ? bounds.width - point.x : point.x)
    }

    /// 手势是否允许响应(壳菜单打开时不抢手势)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let player = player else { return false }
        let location = touch.location(in: player)
        // 落在壳的可点控件上不接管(按钮滑条自己响应)
        var hitView = player.hitTest(location, with: nil)
        while let view = hitView, view !== player {
            if view is UIControl || view is UITableView || (view as? UIScrollView)?.isScrollEnabled == true { return false }
            hitView = view.superview
        }
        return true
    }

    /// 手势互斥策略(自身四类手势保持互斥；外部单击类手势如键盘管理挂在窗口上的点按允许并存，避免播放器单击被挤掉；外部滑动类手势如导航侧滑返回保持互斥，防止拖进度时页面被侧滑退)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let ownGestures: [UIGestureRecognizer] = [tapGesture, doubleTapGesture, panGesture, longPressGesture]
        if ownGestures.contains(gestureRecognizer) && ownGestures.contains(otherGestureRecognizer) {
            return false
        }
        if otherGestureRecognizer is UIPanGestureRecognizer || otherGestureRecognizer is UIScreenEdgePanGestureRecognizer {
            return false
        }
        return true
    }

    /// 单击切换壳显隐
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let player = player, player.configuration.allowsTapGesture else {
            return
        }
        player.toggleShellVisibility()
        player.delegate?.wy_videoPlayerDidSingleTap?(player)
    }

    /// 双击切换播放暂停
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let player = player, player.configuration.allowsDoubleTapGesture else {
            return
        }
        if player.state == .playing {
            player.pause()
        }else {
            player.resume()
        }
        player.delegate?.wy_videoPlayerDidDoubleTap?(player)
    }

    /// 横滑快进与竖滑音量亮度(首个位移方向定型后本轮不再切)
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let player = player else { return }
        let configuration = player.configuration
        let translation = gesture.translation(in: player)
        let location = semanticLocation(gesture.location(in: player), in: player)
        switch gesture.state {
        case .began:
            panDirection = 0
            seekBaseTime = player.playbackTime
        case .changed:
            if panDirection == 0 {
                if abs(translation.x) > abs(translation.y) + 8 {
                    guard configuration.allowsSeekPanGesture else { return }
                    panDirection = 1
                }else if abs(translation.y) > abs(translation.x) + 8 {
                    guard configuration.allowsVolumeBrightnessPanGesture else { return }
                    panDirection = (location.x < player.bounds.midX) ? 2 : 3
                    panBaseValue = (panDirection == 2) ? currentSystemVolume() : (player.window?.windowScene?.screen ?? UIScreen.main).brightness
                    player.pauseShellAutoHide()
                }
            }
            switch panDirection {
            case 1:
                let delta = seekDelta(translation.x, player: player)
                let target = max(0, min(player.duration, seekBaseTime + delta))
                player.showSeekPreview(targetTime: target, delta: target - player.playbackTime)
            case 2:
                let value = max(0, min(1, panBaseValue - translation.y / (player.bounds.height / 2)))
                setSystemVolume(value)
                player.showPanIndicator(isVolume: true, value: Float(value))
            case 3:
                let value = max(0, min(1, panBaseValue - translation.y / (player.bounds.height / 2)))
                (player.window?.windowScene?.screen ?? UIScreen.main).brightness = value
                player.showPanIndicator(isVolume: false, value: Float(value))
            default:
                break
            }
        case .ended, .cancelled, .failed:
            switch panDirection {
            case 1:
                let delta = seekDelta(translation.x, player: player)
                let target = max(0, min(player.duration, seekBaseTime + delta))
                player.hideSeekPreview()
                if gesture.state == .ended {
                    player.seek(to: target, accurate: false)
                    player.delegate?.wy_videoPlayer?(player, seekPanDidEndWithTargetTime: target)
                }
            case 2, 3:
                player.hidePanIndicator()
                player.resumeShellAutoHide()
            default:
                break
            }
            panDirection = 0
        default:
            break
        }
    }

    /// 按视频时长和画面宽度换算横滑秒数
    private func seekDelta(_ translation: CGFloat, player: WYVideoPlayer) -> TimeInterval {
        guard player.duration.isFinite, player.duration > 0 else { return 0 }
        let config = player.configuration
        let minimum = max(0, config.seekPanMinimumSeconds)
        let maximum = max(minimum, config.seekPanMaximumSeconds)
        let span = min(maximum, max(minimum, player.duration * TimeInterval(max(0, config.seekPanDurationRatio))))
        return TimeInterval(translation / max(player.bounds.width, 1) * max(player.configuration.seekPanSensitivity, 0.1)) * span
    }

    /// 长按临时倍速(松手回原速)
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let player = player, player.configuration.allowsRateLongPressGesture else { return }
        switch gesture.state {
        case .began:
            rateBeforeLongPress = player.rate
            player.rate = player.configuration.longPressRate
            player.showRatePrompt(rate: player.configuration.longPressRate)
            player.delegate?.wy_videoPlayer?(player, rateLongPressBeganWithRate: player.configuration.longPressRate)
        case .ended, .cancelled, .failed:
            player.rate = rateBeforeLongPress
            player.hideRatePrompt()
            player.delegate?.wy_videoPlayerRateLongPressEnded?(player)
        default:
            break
        }
    }

    /// 当前系统音量
    private func currentSystemVolume() -> CGFloat {
        return CGFloat(AVAudioSession.sharedInstance().outputVolume)
    }

    /// 设置系统音量(经隐藏的 MPVolumeView 滑条改)
    private func setSystemVolume(_ value: CGFloat) {
        guard let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider else { return }
        slider.value = Float(value)
    }
}
