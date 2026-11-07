//
//  WYNetworkMonitor+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import Foundation

import Network

private final class WYNetworkMonitorListener {
    let monitor = NWPathMonitor()
    let queue: DispatchQueue
    let handler: (_ path: NWPath) -> Void
    var lastPath: NWPath?

    init(queue: DispatchQueue, handler: @escaping (_ path: NWPath) -> Void) {
        self.queue = queue
        self.handler = handler
    }
}

private final class WYNetworkMonitorPrivateState {
    let lock = NSLock()
    let initialPathWait: DispatchTimeInterval = .milliseconds(100)
    let detectionQueue = DispatchQueue(label: "com.wy.networkstatus.detection", qos: .utility)
    var currentPath: NWPath?
    var detector: NWPathMonitor?
    var detectionReady: DispatchGroup?
    var listeners: [String: WYNetworkMonitorListener] = [:]
}

extension WYNetworkMonitor {

    private static let state = WYNetworkMonitorPrivateState()

    static func wy_currentPath() -> NWPath {
        state.lock.lock()
        if let path = state.currentPath {
            state.lock.unlock()
            return path
        }
        if let detector = state.detector, let ready = state.detectionReady {
            state.lock.unlock()
            _ = ready.wait(timeout: .now() + state.initialPathWait)
            state.lock.lock()
            let path = state.currentPath ?? detector.currentPath
            state.lock.unlock()
            return path
        }
        let detector = NWPathMonitor()
        let ready = DispatchGroup()
        ready.enter()
        state.detector = detector
        state.detectionReady = ready
        detector.pathUpdateHandler = { [weak detector] path in
            guard let detector = detector else { return }
            state.lock.lock()
            guard state.detector === detector else {
                state.lock.unlock()
                return
            }
            state.currentPath = path
            state.detector = nil
            state.detectionReady = nil
            state.lock.unlock()
            ready.leave()
            detector.pathUpdateHandler = nil
            detector.cancel()
        }
        state.lock.unlock()
        detector.start(queue: state.detectionQueue)
        _ = ready.wait(timeout: .now() + state.initialPathWait)
        state.lock.lock()
        let path = state.currentPath ?? detector.currentPath
        state.lock.unlock()
        return path
    }

    static func wy_startListening(_ alias: String, queue: DispatchQueue, handler: @escaping (_ path: NWPath) -> Void) {
        state.lock.lock()
        if let path = state.listeners[alias]?.lastPath {
            state.lock.unlock()
            handler(path)
            return
        }
        let previous = state.listeners.removeValue(forKey: alias)
        let listener = WYNetworkMonitorListener(queue: queue, handler: handler)
        state.listeners[alias] = listener
        listener.monitor.pathUpdateHandler = { [weak listener] path in
            guard let listener = listener else { return }
            state.lock.lock()
            guard state.listeners[alias] === listener else {
                state.lock.unlock()
                return
            }
            guard wy_hasPathChanged(from: listener.lastPath, to: path) else {
                state.lock.unlock()
                return
            }
            listener.lastPath = path
            state.currentPath = path
            state.lock.unlock()
            listener.queue.async { [weak listener] in
                guard let listener = listener else { return }
                state.lock.lock()
                let isCurrent = state.listeners[alias] === listener
                state.lock.unlock()
                if isCurrent { listener.handler(path) }
            }
        }
        state.lock.unlock()
        previous?.monitor.pathUpdateHandler = nil
        previous?.monitor.cancel()
        listener.monitor.start(queue: state.detectionQueue)
    }

    static func wy_stopListening(_ alias: String?) {
        state.lock.lock()
        let removed: [WYNetworkMonitorListener]
        if let alias = alias {
            removed = state.listeners.removeValue(forKey: alias).map { [$0] } ?? []
        } else {
            removed = Array(state.listeners.values)
            state.listeners.removeAll()
        }
        let detector: NWPathMonitor?
        let ready: DispatchGroup?
        if state.listeners.isEmpty {
            state.currentPath = nil
            detector = state.detector
            ready = state.detectionReady
            state.detector = nil
            state.detectionReady = nil
        } else {
            detector = nil
            ready = nil
        }
        state.lock.unlock()
        ready?.leave()
        detector?.pathUpdateHandler = nil
        detector?.cancel()
        for listener in removed {
            listener.monitor.pathUpdateHandler = nil
            listener.monitor.cancel()
        }
    }

    static func wy_isListening(_ alias: String) -> Bool {
        state.lock.lock()
        defer { state.lock.unlock() }
        return state.listeners[alias] != nil
    }

    static func wy_activeListeners() -> [String] {
        state.lock.lock()
        defer { state.lock.unlock() }
        return Array(state.listeners.keys)
    }

    private static func wy_hasPathChanged(from oldPath: NWPath?, to newPath: NWPath) -> Bool {
        guard let oldPath = oldPath else { return true }
        let oldInterfaces = oldPath.availableInterfaces.sorted { $0.index < $1.index }
        let newInterfaces = newPath.availableInterfaces.sorted { $0.index < $1.index }
        return oldPath.status != newPath.status ||
            oldPath.isExpensive != newPath.isExpensive ||
            oldPath.isConstrained != newPath.isConstrained ||
            oldPath.supportsIPv4 != newPath.supportsIPv4 ||
            oldPath.supportsIPv6 != newPath.supportsIPv6 ||
            oldPath.supportsDNS != newPath.supportsDNS ||
            !oldInterfaces.elementsEqual(newInterfaces, by: { $0.index == $1.index && $0.name == $1.name && $0.type == $1.type })
    }
}
