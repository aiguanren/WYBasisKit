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
        return wy_currentPath()
    }
    
    /**
     *  实时监听网络状态
     *    @param alias 监听器别名
     *    @param queue 回调队列，默认为主队列
     *    @param handler 回调 path
     */
    public static func listening(_ alias: String,
                                 queue: DispatchQueue = .main,
                                 handler: @escaping (_ nwpath: NWPath) -> Void) {
        wy_startListening(alias, queue: queue, handler: handler)
    }
    
    /**
     *  停止监听
     *    @param alias 监听器别名，如果为 nil 则停止所有监听器
     */
    public static func stopListening(_ alias: String? = nil) {
        wy_stopListening(alias)
    }
    
    /// 检查指定别名的监听器是否存在
    public static func isListening(_ alias: String) -> Bool {
        return wy_isListening(alias)
    }
    
    /// 获取所有活跃的监听器别名
    public static var activeListeners: [String] {
        return wy_activeListeners()
    }
    
}
