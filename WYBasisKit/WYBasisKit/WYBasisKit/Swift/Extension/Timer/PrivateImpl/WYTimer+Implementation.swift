//
//  WYTimer+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit

extension Timer {

    /// 倒计时方法
    static func wy_beginTimer(_ alias: String, _ identifier: UUID) {
        wy_timerLock.lock()

        guard wy_timerContainer[alias]?.identifier == identifier else {
            wy_timerLock.unlock()
            return
        }

        if (wy_timerContainer[alias]?.enterBackground == false) {
            wy_timerContainer[alias]?.remainingTime -= 1
        }

        let handler = wy_timerContainer[alias]?.handler
        let remainingTime = wy_timerContainer[alias]?.remainingTime ?? 0
        wy_timerLock.unlock()

        handler?(remainingTime)

        wy_timerLock.lock()
        defer { wy_timerLock.unlock() }

        if wy_timerContainer[alias]?.identifier == identifier && (wy_timerContainer[alias]?.remainingTime ?? 0) <= 0 {
            wy_cancel(alias)
        }
    }

    /// 进入后台
    static func wy_timerDidEnterBackground(_ alias: String, _ identifier: UUID) {
        wy_timerLock.lock()
        defer { wy_timerLock.unlock() }

        guard wy_timerContainer[alias]?.identifier == identifier else {
            return
        }

        wy_timerContainer[alias]?.enterBackground = true
        UserDefaults.standard.set(Date(), forKey: "timer \(alias) didEnterBackground")
        UserDefaults.standard.setValue("\(wy_timerContainer[alias]?.remainingTime ?? 0)", forKey: "\(alias) timer remainingTime")
        UserDefaults.standard.synchronize()
    }

    /// 返回前台
    static func wy_timerDidBecomeActive(_ alias: String, _ identifier: UUID) {
        wy_timerLock.lock()

        guard wy_timerContainer[alias]?.identifier == identifier else {
            wy_timerLock.unlock()
            return
        }

        let date: Date? = UserDefaults.standard.value(forKey: "timer \(alias) didEnterBackground") as? Date

        guard date != nil else {
            wy_timerLock.unlock()
            return
        }

        let lastRemainingTime: Int = Int(UserDefaults.standard.value(forKey: "\(alias) timer remainingTime") as? String ?? "0") ?? 0

        let different: Int = Int(Date().timeIntervalSince(date!))

        UserDefaults.standard.removeObject(forKey: "timer \(alias) didEnterBackground")
        UserDefaults.standard.removeObject(forKey: "\(alias) timer remainingTime")
        UserDefaults.standard.synchronize()

        wy_updateRemainingTime(alias, lastRemainingTime - different)

        wy_timerContainer[alias]?.enterBackground = false
        wy_timerLock.unlock()

        wy_beginTimer(alias, identifier)
    }

    /// 检查计时器是否存在
    static func wy_existTimer(_ alias: String) ->Bool {
        wy_timerLock.lock()
        defer { wy_timerLock.unlock() }

        guard wy_timerContainer.keys.contains(alias) == true else {
            return false
        }

        guard wy_timerContainer[alias]?.timer != nil else {
            return false
        }

        return true
    }

    /// 计时器容器
    static var wy_timerContainer: [String: (timer: DispatchSourceTimer?, remainingTime: Int, enterBackground: Bool, handler: ((_ remainingTime: Int) -> Void)?, identifier: UUID)] {

        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.timerContainer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return (objc_getAssociatedObject(self, &WYAssociatedKeys.timerContainer) as? [String: (timer: DispatchSourceTimer?, remainingTime: Int, enterBackground: Bool, handler: ((_ remainingTime: Int) -> Void)?, identifier: UUID)]) ?? [:]
        }
    }

    /// 计时器通知监听token容器(与wy_timerContainer同一个alias作key,存block式通知注册返回的token,取消计时器时用它移除对应监听)
    static var wy_timerObserverContainer: [String: (enterBackground: NSObjectProtocol, becomeActive: NSObjectProtocol)] {

        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.timerObserverContainer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return (objc_getAssociatedObject(self, &WYAssociatedKeys.timerObserverContainer) as? [String: (enterBackground: NSObjectProtocol, becomeActive: NSObjectProtocol)]) ?? [:]
        }
    }

    static var wy_timerLock: NSRecursiveLock { WYAssociatedKeys.lock }

    private struct WYAssociatedKeys {
        static let lock = NSRecursiveLock()
        static var timerContainer: UInt8 = 0
        static var timerObserverContainer: UInt8 = 0
    }
}
