//
//  WYMediaPlayer+Properties.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/1.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

#if canImport(IJKPlayerKit)

/// WYMediaPlayer 私有实现：私有属性集中管理(extension不能声明存储属性，经关联对象寄存到实例)
extension WYMediaPlayer {

    /// 当前已重试失败次数
    var failReplayNumber: Int {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.failReplayNumber, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.failReplayNumber) as? Int ?? 0 }
    }

    /// 本次加载的起播意图(play(with:)走shouldAutoplay、prepare(with:)恒为false；驱动start-on-prepared、实例autoplay、海报探测条件与缓冲上限)
    var loadAutoplayIntent: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.loadAutoplayIntent, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.loadAutoplayIntent) as? Bool ?? true }
    }

    /// 加载代号(每次load推进，供延迟重试校验期间是否又发起了新加载，防止迟到的重试覆盖新加载)
    var loadGeneration: Int {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.loadGeneration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.loadGeneration) as? Int ?? 0 }
    }

    /// 当前实例是否已prepare完成(IJKPlayerIsPreparedToPlay回调处置true、releaseAll换实例时重置，供play()判断能否立即起播)
    var isPreparedToPlay: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isPreparedToPlay, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.isPreparedToPlay) as? Bool ?? false }
    }

    /// 挂起的播放意图(play()在prepare完成前被调用时置true，prepare完成回调补执行；pause()与releaseAll会取消)
    var isPlayPending: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isPlayPending, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.isPlayPending) as? Bool ?? false }
    }

    /// prepare期间收到的暂停意图(pause()在prepare未完成时置true，play()挂起或load()/releaseAll时清除)：内核的start-on-prepared自动起播发生在prepare完成内部，未就绪时的pause()拦不住它，只能记下意图由prepare完成回调补压——保证pause之后prepare完成的最终状态是就绪暂停而非自动起播
    var isPausedWhilePreparing: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isPausedWhilePreparing, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.isPausedWhilePreparing) as? Bool ?? false }
    }

    /// 本次加载是否已渲染出第一帧(首帧渲染回调处置true、releaseAll时重置，供开关didSet补截与渲染时截取判断)
    var hasRenderedFirstFrame: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.hasRenderedFirstFrame, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.hasRenderedFirstFrame) as? Bool ?? false }
    }

    /// 是否正处于海报(首帧)探测中(预加载不起播时管线不渲染首帧、首帧通知不触发，探测=静音起播直到首帧渲染后立即暂停回预备态，期间靠该标记收尾)
    var isPosterProbing: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isPosterProbing, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.isPosterProbing) as? Bool ?? false }
    }

    /// 本次加载是否真正播放过(非探测的.playing通知出现过即置位，releaseAll/重新load时复位)
    /// 说明：IJKPlayer在实例初始化与海报探测收尾都会自发.paused，与用户主动暂停同用一种状态无法区分——未真播放过的实例一切.paused只静默不通知，只有真播放之后的暂停才是业务关心的
    var hasReallyPlayed: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.hasReallyPlayed, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.hasReallyPlayed) as? Bool ?? false }
    }

    /// 用户设置的音量(0~1，经playbackVolume(_:)记录；实际下发音量统一走applyVolume：muted或海报探测期间为0)
    var userVolume: Float {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.userVolume, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.userVolume) as? Float ?? 1 }
    }

    /// 当前使用的URL打开转发代理(懒加载语义：首次访问时创建并绑定self，四个闭包全空时不挂到player)
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
