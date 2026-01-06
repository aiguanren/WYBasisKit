//
//  TimerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/24.
//

import Foundation
#if WYBasisKit_Supports_ObjC
import WYBasisKitSwift
#endif

@objc public extension Timer {
    
    /**
     *  开始倒计时
     *  @param alias: 计时器别名
     *  @param remainingTime: 倒计时时长，无限循环传：Int.max
     *  @param duration: 隔几秒回调一次倒计时，默认1秒
     *  @param handler: remainingTime == 0 倒计时已结束,  remainingTime > 0 倒计时正在进行中,剩余 remainingTime 秒,  remainingTime < 0 倒计时已结束，并且超时了 remainingTime 秒才回调的(例如后台返回前台)
     */
    @objc static func wy_start(alias: String, remainingTime: Int, duration: TimeInterval = 1, queue: DispatchQueue = .main, handler: @escaping (_ remainingTime: Int) -> Void) {
        wy_start(alias, remainingTime, duration, queue, handler: handler)
    }
    
    /// 更新计时器剩余时间，单位 "秒"
    @objc static func wy_updateRemainingTime(alias: String, remainingTime: Int) {
        wy_updateRemainingTime(alias, remainingTime)
    }
    
    /// 取消所有计时器
    @objc(wy_cancelAll)
    static func wy_cancelAllObjC() {
        wy_cancelAll()
    }
    
    /// 取消某一组计时器
    @objc(wy_cancelAliass:)
    static func wy_cancel(aliass: [String]) {
        wy_cancel(aliass)
    }
    
    /// 取消某一个计时器
    @objc(wy_cancelAlias:)
    static func wy_cancel(alias: String) {
        wy_cancel(alias)
    }
}
