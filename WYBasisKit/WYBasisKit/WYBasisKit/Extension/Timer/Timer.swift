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
    class func wy_start(_ alias: String, _ remainingTime: Int, _ duration: TimeInterval = 1, _ queue: DispatchQueue = .main, handler: @escaping (_ remainingTime: Int) -> Void) {
        
        wy_cancel(alias)
        
        guard remainingTime > 0 else {
            wy_print("计时器倒计时时长必须大于0")
            return
        }
        
        guard alias.isEmpty == false else {
            wy_print("计时器别名不能为空")
            return
        }
        
        wy_timerContainer[alias] = (timer: DispatchSource.makeTimerSource(queue: queue), remainingTime: remainingTime, enterBackground: false, handler: handler)
        
        wy_timerContainer[alias]?.timer?.schedule(deadline: .now(), repeating: duration)
        wy_timerContainer[alias]?.timer?.setEventHandler(handler: {
            DispatchQueue.main.async {
                self.wy_beginTimer(alias)
            }
        })
        wy_timerContainer[alias]?.timer?.resume()
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                wy_timerDidEnterBackground(alias)
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                wy_timerDidBecomeActive(alias)
            }
        }
    }
    
    /// 更新计时器剩余时间，单位 "秒"
    class func wy_updateRemainingTime(_ alias: String, _ remainingTime: Int) {

        guard wy_existTimer(alias) == true else {
            return
        }
        wy_timerContainer[alias]?.remainingTime = remainingTime
    }
    
    /// 取消所有计时器
    class func wy_cancel() {
        for alias in wy_timerContainer.keys {
            wy_cancel(alias)
        }
    }
    
    /// 取消某一组计时器
    class func wy_cancel(_ alias: [String]) {
        for index in 0..<alias.count {
            wy_cancel(alias[index])
        }
    }
    
    /// 取消某一个计时器
    class func wy_cancel(_ alias: String) {
        
        if wy_timerContainer.keys.contains(alias) == true {
            wy_timerContainer[alias]?.timer?.cancel()
            wy_timerContainer[alias]?.timer = nil
            wy_timerContainer[alias]?.handler = nil
            wy_timerContainer.removeValue(forKey: alias)
        }
        
        if wy_timerContainer.keys.isEmpty == true {
            NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }
}

private extension Timer {
    
    /// 倒计时方法
    private class func wy_beginTimer(_ alias: String) {
        
        guard wy_timerContainer.keys.contains(alias) == true else {
            return
        }
        
        if (wy_timerContainer[alias]?.enterBackground == false) {
            wy_timerContainer[alias]?.remainingTime -= 1
        }
        
        if wy_timerContainer[alias]?.handler != nil {
            wy_timerContainer[alias]?.handler!(wy_timerContainer[alias]?.remainingTime ?? 0)
        }
        
        if (wy_timerContainer[alias]?.remainingTime ?? 0) <= 0 {
            wy_cancel(alias)
        }
    }
    
    /// 进入后台
    private class func wy_timerDidEnterBackground(_ alias: String) {
        guard wy_existTimer(alias) == true else {
            return
        }
        
        wy_timerContainer[alias]?.enterBackground = true
        UserDefaults.standard.set(Date(), forKey: "timer \(alias) didEnterBackground")
        UserDefaults.standard.setValue("\(wy_timerContainer[alias]?.remainingTime ?? 0)", forKey: "\(alias) timer remainingTime")
        UserDefaults.standard.synchronize()
    }
    
    /// 返回前台
    private class func wy_timerDidBecomeActive(_ alias: String) {
        guard wy_existTimer(alias) == true else {
            return
        }
        
        let date: Date? = UserDefaults.standard.value(forKey: "timer \(alias) didEnterBackground") as? Date
        
        guard date != nil else {
            return
        }
        
        let lastRemainingTime: Int = NSInteger(UserDefaults.standard.value(forKey: "\(alias) timer remainingTime") as? String ?? "0") ?? 0
        
        let different: Int = Int(Date().timeIntervalSince(date!))
        
        UserDefaults.standard.removeObject(forKey: "timer \(alias) didEnterBackground")
        UserDefaults.standard.removeObject(forKey: "\(alias) timer remainingTime")
        UserDefaults.standard.synchronize()
        
        wy_updateRemainingTime(alias, lastRemainingTime - different)
        
        wy_timerContainer[alias]?.enterBackground = false
        
        wy_beginTimer(alias)
    }
    
    /// 检查计时器是否存在
    private class func wy_existTimer(_ alias: String) ->Bool {
        
        guard wy_timerContainer.keys.contains(alias) == true else {
            return false
        }
        
        guard wy_timerContainer[alias]?.timer != nil else {
            return false
        }
        
        return true
    }
    
    /// 计时器容器
    private class var wy_timerContainer: [String: (timer: DispatchSourceTimer?, remainingTime: Int, enterBackground: Bool, handler: ((_ remainingTime: Int) -> Void)?)] {
        
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.timerContainer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return (objc_getAssociatedObject(self, WYAssociatedKeys.timerContainer) as? [String: (timer: DispatchSourceTimer?, remainingTime: Int, enterBackground: Bool, handler: ((_ remainingTime: Int) -> Void)?)]) ?? [:]
        }
    }
    
    private struct WYAssociatedKeys {
        static let timerContainer = UnsafeRawPointer(bitPattern: "timerContainer".hashValue)!
    }
}
