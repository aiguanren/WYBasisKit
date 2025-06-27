//
//  WYEventHandler.swift
//  WYBasisKit
//
//  Created by 官人 on 2025/6/26.
//

import Foundation

/// 跨页面/多对象的事件监听工具，无需手动解绑(对象释放后自动解绑)，支持代理和闭包，可用于回调、通知、事件分发等场景
public final class WYEventHandler {
    
    /// 单例对象
    public static let shared = WYEventHandler()
    
    /// 当前所有事件及其监听器数组（只读属性，外部可用于调试或状态查询）
    public private(set) var eventHandlers: [String: [KitEventHandler]] = [:]
    
    /**
     *  注册事件监听器
     *  @param event     事件标识符（建议使用常量或枚举）
     *  @param target    可选的绑定对象，监听对象释放后将自动移除对应监听器
     *  @param handler   事件回调闭包（参数为触发事件时传入的数据）
     */
    public func register(event: String, target: AnyObject? = nil, handler: @escaping (Any?) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        
        let wrapper = KitEventHandler(target: target, handler: handler)
        eventHandlers[event, default: []].append(wrapper)
        
        // 设置自动释放监听器
        if let target = target, !hasDeallocWatcher(for: target) {
            setupDeallocWatcher(for: target)
        }
    }
    
    /**
     *  触发(通知)事件回调（按监听器注册顺序依次调用）
     *  @param event     事件标识符（建议使用常量或枚举）
     *  @param data      可选数据，将传入监听器的回调中
     */
    public func response(event: String, data: Any? = nil) {
        let handlers: [KitEventHandler] = {
            lock.lock()
            defer { lock.unlock() }
            
            guard var handlers = eventHandlers[event] else { return [] }
            
            // 过滤掉失效的监听器（target 已释放）
            handlers = handlers.filter { $0.isValid }
            eventHandlers[event] = handlers.isEmpty ? nil : handlers
            return handlers
        }()
        
        // 执行回调
        handlers.forEach { handler in
            KitHandlerContext(handler: handler, data: data).execute()
        }
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
    public func remove(event: String? = nil, target: AnyObject? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        if let event = event {
            updateHandlers(for: event, target: target)
        } else {
            eventHandlers.keys.forEach { updateHandlers(for: $0, target: target) }
        }
    }
    
    /**
     *  移除target对象相关的所有监听事件
     *  @param target 要移除的监听事件的target对象
     */
    public func remove(target: AnyObject) {
        remove(event: nil, target: target)
    }
    
    /// 移除所有监听对象及所有事件监听
    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        eventHandlers.removeAll()
    }
    
    // MARK: - 以下为私有
    
    /// 保证线程安全的互斥锁
    private let lock = NSLock()
    
    /// 更新某个事件对应的监听器列表
    private func updateHandlers(for event: String, target: AnyObject?) {
        guard var handlers = eventHandlers[event] else { return }
        
        if let target = target {
            // 保留永久监听器或非该目标对象的监听器
            handlers = handlers.filter { $0.isPermanent || $0.target !== target }
        } else {
            // 全部移除
            handlers = []
        }
        
        eventHandlers[event] = handlers.isEmpty ? nil : handlers
    }
    
    /// 判断某对象是否已设置自动释放监听器
    private func hasDeallocWatcher(for target: AnyObject) -> Bool {
        return objc_getAssociatedObject(target, &Self.deallocWatcherKey) != nil
    }
    
    /// 为对象设置释放监听器，用于自动移除绑定的事件监听
    private func setupDeallocWatcher(for target: AnyObject) {
        let watcher = KitDeallocWatcher { [weak self] in
            self?.remove(target: target)
        }
        objc_setAssociatedObject(target, &Self.deallocWatcherKey, watcher, .OBJC_ASSOCIATION_RETAIN)
    }
    
    /// 事件处理器
    public class KitEventHandler {
        
        /// 绑定的目标对象
        weak var target: AnyObject?
        
        /// 事件回调闭包
        let handler: (Any?) -> Void
        
        /// 是否为永久监听器（target为nil表示永久）
        let isPermanent: Bool
        
        /// 当前监听器是否有效
        var isValid: Bool {
            return isPermanent || target != nil
        }
        
        init(target: AnyObject?, handler: @escaping (Any?) -> Void) {
            self.target = target
            self.handler = handler
            self.isPermanent = (target == nil)
        }
    }
    
    /// 对象释放时执行回调（用于自动解绑）
    private class KitDeallocWatcher {
        let callback: () -> Void
        
        init(callback: @escaping () -> Void) {
            self.callback = callback
        }
        
        deinit {
            callback()
        }
    }
    
    /// 安全执行事件回调的上下文
    private struct KitHandlerContext {
        let handler: KitEventHandler
        let data: Any?
        
        func execute() {
            handler.handler(data)
        }
    }
    
    /// 用于关联对象的 Key
    private static var deallocWatcherKey: UInt8 = 0
    
    /// 构造函数私有化，防止外部初始化
    private init() {}
}
