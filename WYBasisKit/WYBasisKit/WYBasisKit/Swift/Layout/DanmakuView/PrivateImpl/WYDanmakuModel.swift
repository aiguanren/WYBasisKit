//
//  WYDanmakuModel.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// 引擎内部的一条弹幕条目(记录内容、类型、轨道与运动参数，负责按引擎时间算出自己当前的位置)
final class WYDanmakuItem {

    /// 展示内容(已套好配置里的字体颜色与描边)
    let attributedText: NSAttributedString

    /// 弹幕类型
    let type: WYDanmakuType

    /// 进入弹幕区的引擎时间
    let startTime: TimeInterval

    /// 从进入到走完弹幕区的总时长，单位为秒(滚动型随内容宽度变长，固定型为停留时长)
    let duration: TimeInterval

    /// 占用的轨道下标
    let trackIndex: Int

    /// 内容测量尺寸
    let size: CGSize

    /// 滚动型匀速移动速度，单位为pt每秒(全场恒定，先发与后发同速不会追尾)
    let speed: CGFloat

    /// 展示视图(从复用池取，条目结束后归还)
    var itemView: WYDanmakuItemView?

    init(attributedText: NSAttributedString, type: WYDanmakuType, startTime: TimeInterval, duration: TimeInterval, trackIndex: Int, size: CGSize, speed: CGFloat) {
        self.attributedText = attributedText
        self.type = type
        self.startTime = startTime
        self.duration = duration
        self.trackIndex = trackIndex
        self.size = size
        self.speed = speed
    }

    /// 条目是否已经走完或停留超时可以回收
    func isFinished(at time: TimeInterval) -> Bool {
        return time - startTime >= duration
    }

    /// 算条目在弹幕区里的当前帧位置(滚动型从右缘进入匀速左移到完全走出，顶部型在轨道正序位置居中，底部型在显示区最下轨往上数居中)
    func frame(in bounds: CGRect, displayOriginY: CGFloat, displayHeight: CGFloat, trackCount: Int, trackHeight: CGFloat, at time: TimeInterval) -> CGRect {
        let y: CGFloat
        if type == .bottom {
            y = displayOriginY + displayHeight - CGFloat(trackCount - trackIndex) * trackHeight
        }else {
            y = displayOriginY + CGFloat(trackIndex) * trackHeight
        }
        let elapsed = CGFloat(time - startTime)
        if type == .scroll {
            let x = bounds.width - speed * elapsed
            return CGRect(x: x, y: y, width: size.width, height: trackHeight)
        }
        let x = (bounds.width - size.width) / 2
        return CGRect(x: x, y: y, width: size.width, height: trackHeight)
    }
}

/// 一条轨道的占用状态(滚动型记最后一条的进入时间内容宽与速度，固定型记占用截止时间)
struct WYDanmakuTrackState {

    /// 滚动型最后一条的进入引擎时间(没有发过滚动弹幕时为 nil)
    var lastScrollStartTime: TimeInterval?

    /// 滚动型最后一条的内容宽
    var lastScrollWidth: CGFloat = 0

    /// 滚动型最后一条的移动速度
    var lastScrollSpeed: CGFloat = 0

    /// 顶部与底部型占用到哪个引擎时间(没有占用时为 nil)
    var fixedEndTime: TimeInterval?
}
