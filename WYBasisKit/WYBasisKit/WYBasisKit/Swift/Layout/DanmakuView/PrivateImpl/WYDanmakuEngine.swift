//
//  WYDanmakuEngine.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import QuartzCore
import UIKit

/// 弹幕运动引擎(管时钟推进、轨道分配、条目生命周期与视图复用，只被 WYDanmakuView 内部使用)
final class WYDanmakuEngine {

    /// 所属弹幕视图
    private weak var danmakuView: WYDanmakuView?

    /// 自驱时钟(没有注入播放时间时按屏幕刷新推进引擎时间)
    private var displayLink: CADisplayLink?

    /// 上一次系统时间戳(算两帧之间的增量用)
    private var lastLinkTimestamp: CFTimeInterval = 0

    /// 引擎时间，单位为秒(自驱时按帧累加，注入时由宿主给的播放时间驱动)
    private(set) var currentTime: TimeInterval = 0

    /// 在屏条目
    private var activeItems: [WYDanmakuItem] = []

    /// 轨道占用状态(下标即轨道号)
    private var trackStates: [WYDanmakuTrackState] = []

    /// 展示区顶部的 y 偏移(按显示区域比例算出)
    private var displayOriginY: CGFloat = 0

    /// 轨道条数(配置为 0 时按显示高度自适应)
    private var trackCount: Int = 0

    /// 满轨时等待发送的条目(丢弃策略下不用)
    private var pendingItems: [(attributedText: NSAttributedString, avatar: UIImage?, type: WYDanmakuType)] = []

    /// 展示视图复用池
    private var itemViewPool: [WYDanmakuItemView] = []

    init(danmakuView: WYDanmakuView?) {
        self.danmakuView = danmakuView
    }

    /// 绑定所属弹幕视图(主视图先建引擎再调 super.init 后回绑)
    func setup(danmakuView: WYDanmakuView) {
        self.danmakuView = danmakuView
    }

    deinit {
        displayLink?.invalidate()
    }

    /// 弹幕视图布局变化时重算轨道(配置或尺寸变了都走这里)
    func layoutTracks() {
        guard let danmakuView = danmakuView else { return }
        let configuration = danmakuView.configuration
        let bounds = danmakuView.bounds
        guard bounds.width > 0, bounds.height > 0, configuration.trackHeight > 0 else { return }
        let displayHeight = bounds.height * configuration.displayAreaRatio
        let trackStride = configuration.trackHeight + configuration.trackSpacing
        var count = configuration.trackCount
        if count <= 0 {
            count = max(1, Int(displayHeight / trackStride))
        }
        count = min(count, max(1, Int(displayHeight / trackStride)))
        trackCount = count
        displayOriginY = 0
        if trackStates.count != count {
            trackStates = Array(repeating: WYDanmakuTrackState(), count: count)
            // 轨道数变化后在屏条目的轨道可能越界，直接清屏重来
            clear()
        }
    }

    /**
     *  发一条弹幕
     *
     *  @param attributedText    已套好外观属性的内容
     *  @param avatar            头像图片(配置关闭头像显示或传 nil 时不显示)
     *  @param type              弹幕类型
     *
     */
    func send(_ attributedText: NSAttributedString, avatar: UIImage?, type: WYDanmakuType) {
        if trackCount <= 0 {
            // 视图还没有尺寸时先补算一次轨道，仍没有就丢弃这条
            layoutTracks()
            guard self.danmakuView != nil, trackCount > 0 else { return }
        }
        guard let danmakuView = self.danmakuView else { return }
        let configuration = danmakuView.configuration
        let showsAvatar = avatar != nil && configuration.showsAvatar
        let avatarWidth: CGFloat = showsAvatar ? configuration.avatarSize + configuration.avatarSpacing : 0
        let size = attributedText.size()
        let itemHeight = max(1, configuration.trackHeight - configuration.itemVerticalPadding * 2)
        let measureSize = CGSize(width: ceil(size.width) + avatarWidth + configuration.itemHorizontalPadding * 2, height: itemHeight)
        guard let trackIndex = availableTrackIndex(for: type, itemWidth: measureSize.width) else {
            if danmakuView.configuration.overflowPolicy == .queue {
                pendingItems.append((attributedText, avatar, type))
            }
            return
        }
        let trackStride = configuration.trackHeight + configuration.trackSpacing
        let speed = danmakuView.bounds.width / configuration.scrollDuration
        let duration: TimeInterval
        if type == .scroll {
            duration = TimeInterval((danmakuView.bounds.width + measureSize.width) / speed)
        }else {
            duration = configuration.fixedDuration
        }
        if trackStates.indices.contains(trackIndex) {
            let index = trackIndex
            if type == .scroll {
                trackStates[index].lastScrollStartTime = currentTime
                trackStates[index].lastScrollWidth = measureSize.width
                trackStates[index].lastScrollSpeed = speed
            }else {
                trackStates[index].fixedEndTime = currentTime + duration
            }
        }
        let item = WYDanmakuItem(attributedText: attributedText, type: type, startTime: currentTime, duration: duration, trackIndex: trackIndex, size: measureSize, speed: speed)
        let itemView = dequeueReusableItemView()
        itemView.prepare(attributedText: attributedText, avatar: avatar, configuration: configuration)
        item.itemView = itemView
        danmakuView.addSubview(itemView)
        itemView.frame = item.frame(in: danmakuView.bounds, displayOriginY: displayOriginY, displayHeight: danmakuView.bounds.height * configuration.displayAreaRatio, trackCount: trackCount, trackStride: trackStride, itemHeight: itemHeight, at: currentTime)
        activeItems.append(item)
    }

    /// 推进引擎时间并刷新在屏条目位置(自驱与注入最终都走这里)
    func tick(delta: TimeInterval) {
        currentTime += delta
        relayoutActiveItems()
        recycleFinishedItems()
        drainPendingItems()
    }

    /// 注入播放时间推进(注入时间比引擎时间倒退超过 0.5 秒按定位清屏处理，小幅度倒退只把引擎时间对齐到注入值，防止自驱时钟把引擎时间推到注入时间前面时被误判成定位)
    func play(at time: TimeInterval) {
        if time + 0.5 < currentTime {
        }
        if displayLink != nil {
        }
        lastInjectionDate = Date()
        stopAutoClock()
        if time + 0.5 < currentTime {
            seek(to: time)
            return
        }
        if time > currentTime {
            tick(delta: time - currentTime)
        }else {
            currentTime = time
            relayoutActiveItems()
        }
    }

    /// 停自驱时钟(暂停时冻结全部在屏弹幕)
    func pause() {
        stopAutoClock()
    }

    /// 自驱恢复计时
    func resumeAutoClock() {
        startAutoClockIfNeeded()
    }

    /// 时间定位(清掉在屏与排队的弹幕后把引擎时间对到目标位置)
    func seek(to time: TimeInterval) {
        clear()
        currentTime = time
    }

    /// 清屏(在屏条目回收，排队的清空，轨道状态复位)
    func clear() {
        guard let danmakuView = danmakuView else { return }
        for item in activeItems {
            if let itemView = item.itemView {
                itemView.removeFromSuperview()
                itemViewPool.append(itemView)
            }
        }
        activeItems.removeAll()
        pendingItems.removeAll()
        trackStates = Array(repeating: WYDanmakuTrackState(), count: trackCount)
        danmakuView.setNeedsLayout()
    }

    /// 释放时钟等资源(弹幕视图销毁时调用)
    func invalidate() {
        displayLink?.invalidate()
        displayLink = nil
    }

    /// 找一条能放这条弹幕的轨道(滚动型要求前一条已完全进入弹幕区，顶部型从上往下找到期轨道，底部型从下往上找，找不到返回 nil)
    private func availableTrackIndex(for type: WYDanmakuType, itemWidth: CGFloat) -> Int? {
        guard let danmakuView = danmakuView else { return nil }
        let width = itemWidth
        let searchOrder: [Int] = (type == .bottom) ? Array(trackStates.indices.reversed()) : Array(trackStates.indices)
        for index in searchOrder {
            if type == .scroll {
                guard let lastStart = trackStates[index].lastScrollStartTime else {
                    return index
                }
                let lastWidth = trackStates[index].lastScrollWidth
                let lastSpeed = trackStates[index].lastScrollSpeed
                let elapsed = CGFloat(currentTime - lastStart)
                // 前一条左缘要让出自身宽加新条宽再加配置的最小间距后才可同轨再进
                if lastSpeed * elapsed >= lastWidth + width + danmakuView.configuration.itemSpacing {
                    return index
                }
            }else {
                guard let fixedEnd = trackStates[index].fixedEndTime else {
                    return index
                }
                if currentTime >= fixedEnd {
                    return index
                }
            }
        }
        return nil
    }

    /// 刷新全部在屏条目这一帧的位置
    private func relayoutActiveItems() {
        guard let danmakuView = danmakuView else { return }
        let configuration = danmakuView.configuration
        let displayHeight = danmakuView.bounds.height * configuration.displayAreaRatio
        let trackStride = configuration.trackHeight + configuration.trackSpacing
        let itemHeight = max(1, configuration.trackHeight - configuration.itemVerticalPadding * 2)
        for item in activeItems {
            item.itemView?.frame = item.frame(in: danmakuView.bounds, displayOriginY: displayOriginY, displayHeight: displayHeight, trackCount: trackCount, trackStride: trackStride, itemHeight: itemHeight, at: currentTime)
        }
    }

    /// 回收到期的条目并归还视图
    private func recycleFinishedItems() {
        guard danmakuView != nil else { return }
        var keptItems: [WYDanmakuItem] = []
        for item in activeItems {
            if item.isFinished(at: currentTime) {
                if let itemView = item.itemView {
                    itemView.removeFromSuperview()
                    itemViewPool.append(itemView)
                }
            }else {
                keptItems.append(item)
            }
        }
        activeItems = keptItems
    }

    /// 有空轨后把排队等待的弹幕依次发出
    private func drainPendingItems() {
        guard pendingItems.isEmpty == false else { return }
        let waiting = pendingItems
        pendingItems.removeAll()
        for entry in waiting {
            send(entry.attributedText, avatar: entry.avatar, type: entry.type)
        }
    }

    /// 取复用视图(池空时新建)
    private func dequeueReusableItemView() -> WYDanmakuItemView {
        if let itemView = itemViewPool.last {
            itemViewPool.removeLast()
            return itemView
        }
        return WYDanmakuItemView(frame: .zero)
    }

    /// 最近一次注入时间(注入驱动场景下发弹幕不再起自驱时钟，防止反复起停在出帧间隙掉帧)
    private var lastInjectionDate: Date?

    /// 开自驱时钟(已开时不重复开，注入时钟活跃时也不起)
    func startAutoClockIfNeeded() {
        if let last = lastInjectionDate, Date().timeIntervalSince(last) < 1 {
            return
        }
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(handleLink(_:)))
        link.add(to: .main, forMode: .common)
        lastLinkTimestamp = 0
        displayLink = link
    }

    /// 停自驱时钟
    private func stopAutoClock() {
        displayLink?.invalidate()
        displayLink = nil
    }

    /// 自驱计时(按两帧系统时间差推进)
    @objc private func handleLink(_ link: CADisplayLink) {
        if lastLinkTimestamp == 0 {
            lastLinkTimestamp = link.timestamp
            return
        }
        let delta = link.timestamp - lastLinkTimestamp
        lastLinkTimestamp = link.timestamp
        tick(delta: TimeInterval(delta))
    }
}

extension WYDanmakuEngine {

    /// 自驱时钟是否在运行
    var isAutoClockRunning: Bool {
        return displayLink != nil
    }
}
