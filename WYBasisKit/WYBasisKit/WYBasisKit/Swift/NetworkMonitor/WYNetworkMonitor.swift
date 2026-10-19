//
//  WYNetworkMonitor.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation
import Network

/**
 *  利用 NWPathMonitor 进行网络活动监听
 */
public struct WYNetworkMonitor {
    
    /// 当前是否连接到网络
    public static var isReachable: Bool {
        return currentPath.status == .satisfied
    }
    
    /// 当前网络是否是无法连接状态(可能是飞行模式、断网或信号太差等原因)
    public static var isNotReachable: Bool {
        return currentPath.status == .unsatisfied
    }
    
    /// 当前网络是否是蜂窝网络(移动数据流量)
    public static var isReachableOnCellular: Bool {
        return currentPath.usesInterfaceType(.cellular)
    }
    
    /// 当前网络是否是 WiFi 网络
    public static var isReachableOnWiFi: Bool {
        return currentPath.usesInterfaceType(.wifi)
    }
    
    /// 当前网络是否是有线网络(例如通过网线或适配器)
    public static var isReachableOnWiredEthernet: Bool {
        return currentPath.usesInterfaceType(.wiredEthernet)
    }
    
    /// 当前网络是否通过 VPN 连接
    public static var isReachableOnVPN: Bool {
        #if os(macOS)
        return currentPath.usesInterfaceType(.vpn)
        #else
        let vpnPrefixes = ["utun", "ppp", "ipsec"]
        if currentPath.availableInterfaces.contains(where: { iface in
            vpnPrefixes.contains { iface.name.lowercased().hasPrefix($0) }
        }) {
            return true
        }
        return false
        #endif
    }
    
    /// 当前网络是否为本地回环接口(通常用于本机内部通信，如 127.0.0.1)
    public static var isLoopback: Bool {
        return currentPath.usesInterfaceType(.loopback)
    }
    
    /// 当前网络是否被系统标记为"昂贵"连接（如蜂窝数据，可能会产生流量费用）
    public static var isExpensive: Bool {
        return currentPath.isExpensive
    }
    
    /// 当前网络是否需要额外步骤才能建立连接（如需要登录认证的网络）
    public static var requiresConnection: Bool {
        return currentPath.status == .requiresConnection
    }
    
    /// 当前网络是否为其他网络(未知类型，无法识别的网络接口，虚拟网络设备、未知硬件通道、Apple 特定测试接口等)
    public static var isReachableOnOther: Bool {
        return currentPath.usesInterfaceType(.other)
    }
    
    /// 当前网络是否支持 IPv4
    public static var supportsIPv4: Bool {
        return currentPath.supportsIPv4
    }
    
    /// 当前网络是否支持 IPv6
    public static var supportsIPv6: Bool {
        return currentPath.supportsIPv6
    }
    
    /// 当前网络状态
    public static var currentNetworkStatus: NWPath.Status {
        return currentPath.status
    }
    
    /// 获取 currentPath（如果还没有监听过，则主动检测一次）
    public static var currentPath: NWPath {
        pathLock.lock()
        defer { pathLock.unlock() }
        
        if let existing = _currentPath {
            return existing
        }
        
        // 如果已经在初始化中，返回临时路径避免重复初始化
        if _isInitializing {
            return createTemporaryPath()
        }
        
        // 标记初始化开始
        _isInitializing = true
        
        // 异步初始化当前路径
        initializeCurrentPathAsync()
        
        // 返回临时路径，避免阻塞调用者
        return createTemporaryPath()
    }
    
    /**
     *  实时监听网络状态
     *  - Parameters:
     *    - alias: 监听器别名
     *    - queue: 回调队列，默认为主队列
     *    - handler: 回调 path
     */
    public static func listening(_ alias: String,
                                 queue: DispatchQueue = .main,
                                 handler: @escaping (_ nwpath: NWPath) -> Void) {
        
        // 如果该 alias 已存在且有 path，则立即回调
        if let existingPath = getCurrentPath(for: alias) {
            handler(existingPath)
            return
        }
        
        stopListening(alias)
        
        let monitor = NWPathMonitor()
        
        // 先保存监听器，确保强引用
        saveMonitor(monitor, for: alias)
        
        // 记录上一次的路径状态，用于去重
        var lastPath: NWPath?
        
        monitor.pathUpdateHandler = { path in
            // 检查路径是否真正发生变化
            guard hasPathChanged(from: lastPath, to: path) else {
                return
            }
            
            lastPath = path
            
            // 更新路径信息
            updateCurrentPath(path, for: alias)
            
            // 在主线程回调
            queue.async {
                handler(path)
            }
            
            // 安全检查：如果监听器已被移除，则取消
            guard isListening(alias) else {
                monitor.cancel()
                // 延迟清理闭包引用
                cleanupMonitorReferences(for: alias, after: 0.1)
                return
            }
        }
        
        let monitorQueue = DispatchQueue(label: "com.wy.networkstatus.\(alias)")
        monitor.start(queue: monitorQueue)
    }
    
    /**
     *  停止监听
     *  - Parameters:
     *    - alias: 监听器别名，如果为 nil 则停止所有监听器
     */
    public static func stopListening(_ alias: String? = nil) {
        listenerLock.lock()
        defer { listenerLock.unlock() }
        
        if let alias = alias {
            // 停止特定监听器
            if let monitor = listeningObjects[alias] {
                monitor.cancel()
                // 延迟清理闭包引用，防止内存问题
                cleanupMonitorReferences(for: alias, after: 0.1)
            }
            listeningObjects.removeValue(forKey: alias)
            lastPaths.removeValue(forKey: alias) // 清理去重缓存
            currentPaths.removeValue(forKey: alias)
        } else {
            // 停止所有监听器
            listeningObjects.values.forEach { $0.cancel() }
            
            // 延迟清理所有闭包引用
            cleanupAllMonitorReferences(after: 0.1)
            
            listeningObjects.removeAll()
            lastPaths.removeAll() // 清理所有去重缓存
            currentPaths.removeAll()
        }
        
        // 如果没有活跃的监听器，清空当前路径缓存
        if listeningObjects.isEmpty {
            pathLock.lock()
            _currentPath = nil
            pathLock.unlock()
        }
    }
    
    /// 检查指定别名的监听器是否存在
    public static func isListening(_ alias: String) -> Bool {
        listenerLock.lock()
        defer { listenerLock.unlock() }
        return listeningObjects[alias] != nil
    }
    
    /// 获取所有活跃的监听器别名
    public static var activeListeners: [String] {
        listenerLock.lock()
        defer { listenerLock.unlock() }
        return Array(listeningObjects.keys)
    }
    
    /// 保护 _currentPath 的线程锁
    private static let pathLock = NSLock()
    
    /// 保护监听器相关容器的线程锁
    private static let listenerLock = NSLock()
    
    /// 当前网络路径缓存（线程安全访问）
    private static var _currentPath: NWPath?
    
    /// 是否正在异步初始化当前路径
    private static var _isInitializing: Bool = false
    
    /// 网络监听器容器
    private static var listeningObjects: [String: NWPathMonitor] = [:]
    
    /// 每个 alias 对应的最新 NWPath
    private static var currentPaths: [String: NWPath] = [:]
    
    /// 每个 alias 对应的上一次 NWPath（用于去重）
    private static var lastPaths: [String: NWPath] = [:]
    
    /// 用于一次性路径检测的共享队列（使用 utility QoS 平衡性能和能效）
    private static let detectionQueue = DispatchQueue(label: "com.wy.networkstatus.detection", qos: .utility)
    
    /// 异步初始化当前路径
    private static func initializeCurrentPathAsync() {
        detectionQueue.async {
            let path = getCurrentPathSynchronously()
            
            pathLock.lock()
            _currentPath = path
            _isInitializing = false
            pathLock.unlock()
        }
    }
    
    /// 创建临时路径（用于异步初始化期间）
    private static func createTemporaryPath() -> NWPath {
        // 使用快速同步方式获取临时路径
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var tempPath: NWPath?
        
        monitor.pathUpdateHandler = { path in
            tempPath = path
            semaphore.signal()
            monitor.cancel()
        }
        
        let tempQueue = DispatchQueue(label: "com.wy.networkstatus.temp")
        monitor.start(queue: tempQueue)
        
        // 短暂等待，避免阻塞
        _ = semaphore.wait(timeout: .now() + 0.1)
        
        return tempPath ?? createFallbackPath()
    }
    
    /// 创建回退路径
    private static func createFallbackPath() -> NWPath {
        let monitor = NWPathMonitor()
        var fallbackPath: NWPath?
        let semaphore = DispatchSemaphore(value: 0)
        
        monitor.pathUpdateHandler = { path in
            fallbackPath = path
            semaphore.signal()
            monitor.cancel()
        }
        
        monitor.start(queue: detectionQueue)
        _ = semaphore.wait(timeout: .now() + 0.05)
        
        // 如果仍然失败，返回系统默认状态
        return fallbackPath ?? createFinalFallbackPath()
    }
    
    /// 创建最终回退路径
    private static func createFinalFallbackPath() -> NWPath {
        let monitor = NWPathMonitor()
        var finalPath: NWPath?
        let semaphore = DispatchSemaphore(value: 0)
        
        monitor.pathUpdateHandler = { path in
            finalPath = path
            semaphore.signal()
            monitor.cancel()
        }
        
        monitor.start(queue: detectionQueue)
        _ = semaphore.wait(timeout: .now() + 0.5)
        
        // 最终保障：如果仍然失败，创建新的 monitor 获取路径
        return finalPath ?? NWPathMonitor().currentPath
    }
    
    /// 同步获取当前网络路径
    private static func getCurrentPathSynchronously() -> NWPath {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var detectedPath: NWPath?
        
        monitor.pathUpdateHandler = { path in
            detectedPath = path
            semaphore.signal()
            monitor.cancel()
        }
        
        // 在共享队列启动监听，避免创建过多队列
        monitor.start(queue: detectionQueue)
        
        // 最多等待 1.0 秒，给系统足够时间检测
        _ = semaphore.wait(timeout: .now() + 1.0)
        
        // 如果检测失败，使用备选方案
        if let path = detectedPath {
            return path
        } else {
            // 创建 unsatisfied 状态的路径
            return createUnsatisfiedPathWithoutRecursion()
        }
    }
    
    /// 创建 unsatisfied 路径
    private static func createUnsatisfiedPathWithoutRecursion() -> NWPath {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var unsatisfiedPath: NWPath?
        
        monitor.pathUpdateHandler = { path in
            unsatisfiedPath = path
            semaphore.signal()
            monitor.cancel()
        }
        
        monitor.start(queue: detectionQueue)
        
        // 短暂等待获取路径
        _ = semaphore.wait(timeout: .now() + 0.3)
        
        // 如果仍然无法获取，使用默认的 unsatisfied 状态
        return unsatisfiedPath ?? createFallbackPath()
    }
    
    /// 延迟清理监听器引用
    private static func cleanupMonitorReferences(for alias: String, after delay: TimeInterval) {
        Task.wy_delayForTask(delay) {
            detectionQueue.async {
                listenerLock.lock()
                // 确保监听器已经被移除后再清理相关引用
                if listeningObjects[alias] == nil {
                    lastPaths.removeValue(forKey: alias)
                    currentPaths.removeValue(forKey: alias)
                }
                listenerLock.unlock()
            }
        }
    }
    
    /// 延迟清理所有监听器引用
    private static func cleanupAllMonitorReferences(after delay: TimeInterval) {
        Task.wy_delayForTask(delay) {
            detectionQueue.async {
                listenerLock.lock()
                // 清理所有相关引用
                lastPaths.removeAll()
                currentPaths.removeAll()
                listenerLock.unlock()
            }
        }
    }
    
    /// 检查路径是否真正发生变化
    private static func hasPathChanged(from oldPath: NWPath?, to newPath: NWPath) -> Bool {
        guard let oldPath = oldPath else {
            return true // 第一次回调，总是视为变化
        }
        
        // 比较关键属性是否发生变化
        return oldPath.status != newPath.status ||
        oldPath.isExpensive != newPath.isExpensive ||
        oldPath.supportsIPv4 != newPath.supportsIPv4 ||
        oldPath.supportsIPv6 != newPath.supportsIPv6 ||
        oldPath.availableInterfaces.count != newPath.availableInterfaces.count
    }
    
    /// 保存监听器
    private static func saveMonitor(_ monitor: NWPathMonitor, for alias: String) {
        listenerLock.lock()
        defer { listenerLock.unlock() }
        listeningObjects[alias] = monitor
    }
    
    /// 获取指定别名的当前路径
    private static func getCurrentPath(for alias: String) -> NWPath? {
        listenerLock.lock()
        defer { listenerLock.unlock() }
        return currentPaths[alias]
    }
    
    /// 更新路径信息
    private static func updateCurrentPath(_ path: NWPath, for alias: String) {
        // 更新全局当前路径
        pathLock.lock()
        _currentPath = path
        pathLock.unlock()
        
        // 更新别名对应的路径
        listenerLock.lock()
        currentPaths[alias] = path
        listenerLock.unlock()
    }
}

