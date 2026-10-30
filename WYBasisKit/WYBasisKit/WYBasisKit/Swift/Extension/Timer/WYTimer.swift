//
//  Timer.swift
//  WYBasisKit
//
//  Created by 官人 on 2022/4/14.
//  Copyright © 2022 官人. All rights reserved.
//

import UIKit

public extension Timer {
    
    /**
     *  开始倒计时
     *  @param alias: 计时器别名
     *  @param remainingTime: 倒计时时长，无限循环传：Int.max
     *  @param duration: 隔几秒回调一次倒计时，默认1秒
     *  @param handler: remainingTime == 0 倒计时已结束,  remainingTime > 0 倒计时正在进行中,剩余 remainingTime 秒,  remainingTime < 0 倒计时已结束，并且超时了 remainingTime 秒才回调的(例如后台返回前台)
     */
    static func wy_start(_ alias: String, _ remainingTime: Int, _ duration: TimeInterval = 1, _ queue: DispatchQueue = .main, handler: @escaping (_ remainingTime: Int) -> Void) {
        wy_timerLock.lock()
        defer { wy_timerLock.unlock() }
        
        wy_cancel(alias)
        
        guard remainingTime > 0 else {
            WYLogManager.output("计时器倒计时时长必须大于0")
            return
        }
        
        guard alias.isEmpty == false else {
            WYLogManager.output("计时器别名不能为空")
            return
        }
        
        let identifier = UUID()
        wy_timerContainer[alias] = (timer: DispatchSource.makeTimerSource(queue: queue), remainingTime: remainingTime, enterBackground: false, handler: handler, identifier: identifier)
        
        wy_timerContainer[alias]?.timer?.schedule(deadline: .now(), repeating: duration)
        wy_timerContainer[alias]?.timer?.setEventHandler(handler: {
            Task { @MainActor in
                self.wy_beginTimer(alias, identifier)
            }
        })
        wy_timerContainer[alias]?.timer?.resume()
        
        // 防通知监听越积越多，block方式注册的通知只能拿返回的token移除,原先的removeObserver(self)对它无效,每次wy_start都会多挂一对监听
        let enterBackgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            Task { @MainActor in
                wy_timerDidEnterBackground(alias, identifier)
            }
        }
        
        let becomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            Task { @MainActor in
                wy_timerDidBecomeActive(alias, identifier)
            }
        }
        wy_timerObserverContainer[alias] = (enterBackgroundObserver, becomeActiveObserver)
    }
    
    /// 更新计时器剩余时间，单位 "秒"
    static func wy_updateRemainingTime(_ alias: String, _ remainingTime: Int) {
        wy_timerLock.lock()
        defer { wy_timerLock.unlock() }

        guard wy_existTimer(alias) == true else {
            return
        }
        wy_timerContainer[alias]?.remainingTime = remainingTime
    }
    
    /// 取消所有计时器
    static func wy_cancelAll() {
        wy_timerLock.lock()
        defer { wy_timerLock.unlock() }

        for alias in Array(wy_timerContainer.keys) {
            wy_cancel(alias)
        }
    }
    
    /// 取消某一组计时器
    static func wy_cancel(_ aliases: [String]) {
        wy_timerLock.lock()
        defer { wy_timerLock.unlock() }

        for index in 0..<aliases.count {
            wy_cancel(aliases[index])
        }
    }
    
    /// 取消某一个计时器
    static func wy_cancel(_ alias: String) {
        wy_timerLock.lock()
        defer { wy_timerLock.unlock() }
        
        if wy_timerContainer.keys.contains(alias) == true {
            wy_timerContainer[alias]?.timer?.cancel()
            wy_timerContainer[alias]?.timer = nil
            wy_timerContainer[alias]?.handler = nil
            wy_timerContainer.removeValue(forKey: alias)
        }
        
        if let observers = wy_timerObserverContainer[alias] {
            NotificationCenter.default.removeObserver(observers.enterBackground)
            NotificationCenter.default.removeObserver(observers.becomeActive)
            wy_timerObserverContainer.removeValue(forKey: alias)
        }
        UserDefaults.standard.removeObject(forKey: "timer \(alias) didEnterBackground")
        UserDefaults.standard.removeObject(forKey: "\(alias) timer remainingTime")
    }
}
