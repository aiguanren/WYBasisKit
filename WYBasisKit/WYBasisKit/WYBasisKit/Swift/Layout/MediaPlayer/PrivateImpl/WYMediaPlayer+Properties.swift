//
//  WYMediaPlayer+Properties.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/1.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

#if canImport(IJKPlayerKit)

/// WYMediaPlayer 私有实现：私有属性集中管理(extension里不能声明存储属性，只能用关联对象把值挂到实例上)
extension WYMediaPlayer {

    /// 当前已重试失败次数
    var failReplayNumber: Int {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.failReplayNumber, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.failReplayNumber) as? Int ?? 0 }
    }

    /// 本次加载完成后要不要自动播放(play(with:)看shouldAutoplay、prepare(with:)固定为false)
    var loadAutoplayIntent: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.loadAutoplayIntent, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.loadAutoplayIntent) as? Bool ?? true }
    }

    /// 加载代号(每次load加1；延迟执行的失败重试回来时先核对它，发现变了说明期间发起了新加载，放弃本次重试，防止迟到的重试覆盖新加载)
    var loadGeneration: Int {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.loadGeneration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.loadGeneration) as? Int ?? 0 }
    }

    /// 当前实例是否已prepare完成(供play()判断能否立即起播)
    var isPreparedToPlay: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isPreparedToPlay, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.isPreparedToPlay) as? Bool ?? false }
    }

    /// 挂起的播放请求(play()在prepare完成前被调用时先记true，等prepare完成回调再补执行；pause()与releaseAll会取消)
    var isPlayPending: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isPlayPending, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.isPlayPending) as? Bool ?? false }
    }

    /// prepare期间收到的暂停请求：prepare完成时内核会自动起播，由完成回调补一次pause把它压住
    var isPausedWhilePreparing: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isPausedWhilePreparing, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.isPausedWhilePreparing) as? Bool ?? false }
    }

    /// 本次加载是否已渲染出第一帧(供海报截取判断)
    var hasRenderedFirstFrame: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.hasRenderedFirstFrame, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.hasRenderedFirstFrame) as? Bool ?? false }
    }

    /// 是否正处于海报(首帧)探测中(预加载不自动播时底层根本不渲染第一帧、首帧通知也不来；所谓探测就是先静音播放，等第一帧画面出来立刻暂停回到准备好状态，全程靠这个标记收尾)
    var isPosterProbing: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isPosterProbing, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.isPosterProbing) as? Bool ?? false }
    }

    /// 本次加载是否真正播放过：没真正播过的实例收到.paused只默默记下不通知业务(这类暂停只是初始化或收尾的内部动静，不是用户暂停)
    var hasReallyPlayed: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.hasReallyPlayed, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.hasReallyPlayed) as? Bool ?? false }
    }

    /// 用户设置的音量(0~1)；实际下发音量统一走applyVolume
    var userVolume: Float {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.userVolume, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.userVolume) as? Float ?? 1 }
    }

    /// 当前使用的URL打开转发代理(第一次用到才创建并绑定self；四个闭包全空时不会挂到player上)
    var urlOpenProxy: WYMediaUrlOpenProxy {
        if let proxy = objc_getAssociatedObject(self, &WYAssociatedKeys.urlOpenProxy) as? WYMediaUrlOpenProxy {
            return proxy
        }
        let proxy = WYMediaUrlOpenProxy()
        proxy.target = self
        objc_setAssociatedObject(self, &WYAssociatedKeys.urlOpenProxy, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return proxy
    }
}

/// 私有属性的关联对象键
private struct WYAssociatedKeys {
    static var failReplayNumber: UInt8 = 0
    static var loadAutoplayIntent: UInt8 = 0
    static var loadGeneration: UInt8 = 0
    static var isPreparedToPlay: UInt8 = 0
    static var isPlayPending: UInt8 = 0
    static var isPausedWhilePreparing: UInt8 = 0
    static var hasRenderedFirstFrame: UInt8 = 0
    static var isPosterProbing: UInt8 = 0
    static var hasReallyPlayed: UInt8 = 0
    static var userVolume: UInt8 = 0
    static var urlOpenProxy: UInt8 = 0
}

#endif
