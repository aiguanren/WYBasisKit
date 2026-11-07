//
//  WYEventHandler+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import Foundation

final class WYEventHandlerPrivateState {
    /// 保证线程安全的互斥锁
    let lock = NSRecursiveLock()
    var handlers: [String: [KitEventHandler]] = [:]
}

extension WYEventHandler {

    func wy_eventHandlersSnapshot() -> [String: [KitEventHandler]] {
        state.lock.lock()
        defer { state.lock.unlock() }
        return state.handlers
    }

    func wy_replaceEventHandlers(_ handlers: [String: [KitEventHandler]]) {
        state.lock.lock()
        let retainedHandlers = state.handlers
        defer {
            state.lock.unlock()
            withExtendedLifetime(retainedHandlers) {}
        }
        state.handlers = handlers
    }

    func wy_register(event: String, target: AnyObject?, handler: @escaping (Any?) -> Void) {
        state.lock.lock()
        defer { state.lock.unlock() }
        state.handlers[event, default: []].append(KitEventHandler(target: target, handler: handler))
        if let target = target, objc_getAssociatedObject(target, &WYAssociatedKeys.deallocWatcherKey) == nil {
            let watcher = KitDeallocWatcher { [weak self] in
                self?.wy_removeInvalidHandlers()
            }
            objc_setAssociatedObject(target, &WYAssociatedKeys.deallocWatcherKey, watcher, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    func wy_response(event: String, data: Any?) {
        let handlers: [KitEventHandler] = {
            state.lock.lock()
            let retainedHandlers = state.handlers
            defer {
                state.lock.unlock()
                withExtendedLifetime(retainedHandlers) {}
            }
            guard let registered = state.handlers[event] else { return [] }
            let handlers = registered.filter { $0.isValid }
            state.handlers[event] = handlers.isEmpty ? nil : handlers
            return handlers
        }()
        handlers.forEach { $0.handler(data) }
    }

    func wy_remove(event: String?, target: AnyObject?) {
        state.lock.lock()
        let retainedHandlers = state.handlers
        defer {
            state.lock.unlock()
            withExtendedLifetime(retainedHandlers) {}
        }
        let events = event.map { [$0] } ?? Array(state.handlers.keys)
        for event in events {
            guard let registered = state.handlers[event] else { continue }
            let handlers = target.map { target in registered.filter { $0.isPermanent || $0.target !== target } } ?? []
            state.handlers[event] = handlers.isEmpty ? nil : handlers
        }
    }

    func wy_removeAll() {
        state.lock.lock()
        let retainedHandlers = state.handlers
        defer {
            state.lock.unlock()
            withExtendedLifetime(retainedHandlers) {}
        }
        state.handlers.removeAll()
    }

    private func wy_removeInvalidHandlers() {
        state.lock.lock()
        let retainedHandlers = state.handlers
        defer {
            state.lock.unlock()
            withExtendedLifetime(retainedHandlers) {}
        }
        for event in Array(state.handlers.keys) {
            let handlers = state.handlers[event]?.filter { $0.isValid } ?? []
            state.handlers[event] = handlers.isEmpty ? nil : handlers
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

    /// 用于关联对象的 Key
    private struct WYAssociatedKeys {
        static var deallocWatcherKey: UInt8 = 0
    }
}
