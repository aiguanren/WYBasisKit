//
//  WYNetworkMonitorObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/19.
//

#if canImport(WYBasisKitSwift)
import Foundation
import Network
import WYBasisKitSwift

/**
 *  利用 NWPathMonitor 进行网络活动监听
 */
@objc(WYNetworkMonitor)
@objcMembers public class WYNetworkMonitorObjC: NSObject {
    
    /// 当前是否连接到网络
    @objc public static var isReachable: Bool {
        return WYNetworkMonitor.isReachable
    }
    
    /// 当前网络是否是无法连接状态(可能是飞行模式、断网或信号太差等原因)
    @objc public static var isNotReachable: Bool {
        return WYNetworkMonitor.isNotReachable
    }
    
    /// 当前网络是否是蜂窝网络(移动数据流量)
    @objc public static var isReachableOnCellular: Bool {
        return WYNetworkMonitor.isReachableOnCellular
    }
    
    /// 当前网络是否是 WiFi 网络
    @objc public static var isReachableOnWiFi: Bool {
        return WYNetworkMonitor.isReachableOnWiFi
    }
    
    /// 当前网络是否是有线网络(例如通过网线或适配器)
    @objc public static var isReachableOnWiredEthernet: Bool {
        return WYNetworkMonitor.isReachableOnWiredEthernet
    }
    
    /// 当前网络是否通过 VPN 连接
    @objc public static var isReachableOnVPN: Bool {
        return WYNetworkMonitor.isReachableOnVPN
    }
    
    /// 当前网络是否为本地回环接口(通常用于本机内部通信，如 127.0.0.1)
    @objc public static var isLoopback: Bool {
        return WYNetworkMonitor.isLoopback
    }
    
    /// 当前网络是否被系统标记为"昂贵"连接（如蜂窝数据，可能会产生流量费用）
    @objc public static var isExpensive: Bool {
        return WYNetworkMonitor.isExpensive
    }
    
    /// 当前网络是否需要额外步骤才能建立连接（如需要登录认证的网络）
    @objc public static var requiresConnection: Bool {
        return WYNetworkMonitor.requiresConnection
    }
    
    /// 当前网络是否为其他网络(未知类型，无法识别的网络接口，虚拟网络设备、未知硬件通道、Apple 特定测试接口等)
    @objc public static var isReachableOnOther: Bool {
        return WYNetworkMonitor.isReachableOnOther
    }
    
    /// 当前网络是否支持 IPv4
    @objc public static var supportsIPv4: Bool {
        return WYNetworkMonitor.supportsIPv4
    }
    
    /// 当前网络是否支持 IPv6
    @objc public static var supportsIPv6: Bool {
        return WYNetworkMonitor.supportsIPv6
    }
    
    /**
     * 当前网络状态 (因为 Objective-C 不支持 NWPath，所以使用 Int 来映射 NWPath.Status)
     * 0 = NWPath.Status.unsatisfied (无法连接)
     * 1 = NWPath.Status.requiresConnection (需要额外步骤才能连接)
     * 2 = NWPath.Status.satisfied (已连接)
     */
    @objc public static var currentNetworkStatus: Int {
        switch WYNetworkMonitor.currentNetworkStatus {
        case .unsatisfied: return 0
        case .requiresConnection: return 1
        case .satisfied: return 2
        @unknown default: return -1
        }
    }
    
    /**
     * 获取 currentPath（NWPath类型，如果还没有监听过，则主动检测一次）
     * 返回类型为 Any，因为 Objective-C 不支持 NWPath
     */
    @objc public static var currentPath: Any {
        return WYNetworkMonitor.currentPath
    }
    
    /**
     *  实时监听网络状态
     *    @param alias 监听器别名
     *    @param queue 回调队列，默认为主队列
     *    @param handler 回调 path
     *    回调参数 state 映射 NWPath.Status：
     *      0 = NWPath.Status.satisfied (已连接)
     *      1 = NWPath.Status.unsatisfied (无法连接)
     *      2 = NWPath.Status.requiresConnection (需要额外步骤才能连接)
     */
    @objc public static func listening(_ alias: String,
                                 queue: DispatchQueue? = .main,
                                 handler: @escaping (_ state: Int) -> Void) {
        WYNetworkMonitor.listening(alias, queue: queue ?? .main) { nwpath in
            let state: Int
            switch nwpath.status {
            case .satisfied: state = 0
            case .unsatisfied: state = 1
            case .requiresConnection: state = 2
            @unknown default: state = -1
            }
            handler(state)
        }
    }
    
    /**
     *  停止监听
     *    @param alias 监听器别名，如果为 nil 则停止所有监听器
     */
    @objc public static func stopListening(_ alias: String? = nil) {
        WYNetworkMonitor.stopListening(alias)
    }
    
    /// 检查指定别名的监听器是否存在
    @objc public static func isListening(_ alias: String) -> Bool {
        return WYNetworkMonitor.isListening(alias)
    }
    
    /// 获取所有活跃的监听器别名
    @objc public static var activeListeners: [String] {
        return WYNetworkMonitor.activeListeners
    }
}
#endif
