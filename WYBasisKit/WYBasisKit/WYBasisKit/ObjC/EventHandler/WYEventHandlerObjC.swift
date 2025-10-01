//
//  WYEventHandlerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/1.
//

import Foundation

/// 跨页面/多对象的事件监听工具，无需手动解绑(对象释放后自动解绑)，支持代理和闭包，可用于回调、通知、事件分发等场景
@objc(WYEventHandler)
@objcMembers public final class WYEventHandlerObjC: NSObject {
    
    /// 当前所有事件及其监听器数组（只读属性，外部可用于调试或状态查询）
    @objc public static var eventHandlers: [String: [KitEventHandlerObjC]] {
        let convertedHandlers: [String: [KitEventHandlerObjC]] = WYEventHandler.shared.eventHandlers.mapValues {
            $0.map { KitEventHandlerObjC.wy_convertFrom(eventHandler: $0) }
        }
        return convertedHandlers
    }
    
    /**
     *  注册事件监听器
     *  @param event     事件标识符（建议使用常量或枚举）
     *  @param target    可选的绑定对象，监听对象释放后将自动移除对应监听器
     *  @param handler   事件回调闭包（参数为触发事件时传入的数据）
     */
    @objc public func register(event: String, target: AnyObject? = nil, handler: @escaping (Any?) -> Void) {
        WYEventHandler.shared.register(event: event, target: target, handler: handler)
    }
    
    /**
     *  触发(通知)事件回调（按监听器注册顺序依次调用）
     *  @param event     事件标识符（建议使用常量或枚举）
     *  @param data      可选数据，将传入监听器的回调中
     */
    @objc public func response(event: String, data: Any? = nil) {
        WYEventHandler.shared.response(event: event, data: data)
    }
    
    /**
     *  移除事件监听（支持按事件、按目标对象过滤）
     *
     *  根据 event 和 target 的组合不同，执行不同的移除策略：
     *
     *  1. event == nil 且 target == nil：
     *     ➤ 移除所有事件的所有监听对象，等价于 removeAll 方法
     *
     *  2. event == nil 且 target != nil：
     *     ➤ 移除target对象绑定的所有监听事件
     *
     *  3. event != nil 且 target == nil：
     *     ➤ 移除event事件的所有监听对象
     *
     *  4. event != nil 且 target != nil：
     *     ➤ 移除target对象对event事件的监听
     *
     *  @param event   事件标识符，可为 nil（表示所有事件）
     *  @param target  目标对象，可为 nil（表示所有对象）
     */
    @objc public func remove(event: String? = nil, target: AnyObject? = nil) {
        WYEventHandler.shared.remove(event: event, target: target)
    }
    
    /**
     *  移除target对象相关的所有监听事件
     *  @param target 要移除的监听事件的target对象
     */
    @objc public func remove(target: AnyObject) {
        WYEventHandler.shared.remove(target: target)
    }
    
    /// 移除所有监听对象及所有事件监听
    @objc public func removeAll() {
        WYEventHandler.shared.removeAll()
    }
}

/// 事件处理器
@objc(KitEventHandler)
@objcMembers public class KitEventHandlerObjC: NSObject {
    
    /// 绑定的目标对象
    @objc weak var target: AnyObject?
    
    /// 事件回调闭包
    @objc let handler: (Any?) -> Void
    
    /// 是否为永久监听器（target为nil表示永久）
    @objc let isPermanent: Bool
    
    /// 当前监听器是否有效
    @objc var isValid: Bool {
        return isPermanent || target != nil
    }
    
    @objc init(target: AnyObject?, handler: @escaping (Any?) -> Void) {
        self.target = target
        self.handler = handler
        self.isPermanent = (target == nil)
    }
    
    static func wy_convertFrom(eventHandler: KitEventHandler) ->KitEventHandlerObjC {
        return KitEventHandlerObjC(target: eventHandler.target, handler: eventHandler.handler)
    }
}
