//
//  UIDevice.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit
import CoreMotion
import CoreTelephony
import AudioToolbox

/// 设备折叠状态
@available(iOS 27.1, *)
@objc public enum WYDeviceFoldableState: Int {
    /// 无可用铰链信息
    case unavailable = -1
    /// 状态未知
    case unknown = 0
    /// 折叠
    case closed = 1
    /// 半折叠
    case partiallyOpen = 2
    /// 展开
    case fullyOpen = 3
}

/// 设备振动模式
@frozen public enum WYVibrationStyle: Int {
    /// 系统震动（强烈）
    case system = 0
    /// 轻
    case light
    /// 中
    case medium
    /// 重
    case heavy
    /// 柔和
    case soft
    /// 生硬
    case rigid
    /// 成功提示
    case success
    /// 警告提示
    case warning
    /// 错误提示
    case error
}

public extension UIDevice {
    
    /// 状态栏高度
    static var wy_statusBarHeight: CGFloat {
        return UIApplication.shared.wy_keyWindow
            .windowScene?
            .statusBarManager?
            .statusBarFrame
            .height ?? 0.0
    }
    
    /// 导航栏安全区域高度
    static var wy_navBarSafetyZone: CGFloat {
        if let bar = privateVisibleNavigationBar {
            return max(0, bar.convert(bar.bounds, to: UIApplication.shared.wy_keyWindow).minY)
        }
        return UIApplication.shared.wy_keyWindow.safeAreaInsets.top
    }
    
    /**
     导航栏高度
     - Note: iOS 26 引入“液态玻璃”（Liquid Glass）设计后，其高度由系统动态计算。
             iOS26以前默认是44像素
     */
    static var wy_navBarHeight: CGFloat {
        if let bar = privateVisibleNavigationBar, bar.bounds.height > 0 { return bar.bounds.height }
        return max(0, privateNavigationBar.intrinsicContentSize.height)
    }
    
    /// 导航视图高度（导航栏安全区域+导航栏）
    static var wy_navViewHeight: CGFloat {
        return wy_navBarSafetyZone + wy_navBarHeight
    }
    
    /// tabBar安全区域高度
    static var wy_tabbarSafetyZone: CGFloat {
        return UIApplication.shared.wy_keyWindow.safeAreaInsets.bottom
    }
    
    /**
     tabBar高度(含安全区域高度)
     - Note: iOS 26 引入“液态玻璃”（Liquid Glass）设计后，系统会根据设备
             和上下文动态调整 TabBar 的高度，iOS26以前默认是49像素
     */
    static var wy_tabBarHeight: CGFloat {
        return wy_tabBarContentInsets.bottom
    }
    
    /// 当前窗口的安全区域边距
    static var wy_windowSafeAreaInsets: UIEdgeInsets {
        return UIApplication.shared.wy_keyWindow.safeAreaInsets
    }

    /// TabBar 容器的内容边距(包含安全区，支持底部、顶部和侧边布局)
    static var wy_tabBarContentInsets: UIEdgeInsets {
        let window = UIApplication.shared.wy_keyWindow
        let controller = UIViewController.wy_currentController()
        guard let tabs = (controller as? UITabBarController) ?? controller?.tabBarController,
              tabs.isViewLoaded else { return window.safeAreaInsets }
        if #available(iOS 26.0, *) {
            let bounds = tabs.view.bounds
            let frame = tabs.contentLayoutGuide.layoutFrame
            if bounds.width > 0, bounds.height > 0, !frame.isEmpty {
                return UIEdgeInsets(top: max(0, frame.minY - bounds.minY), left: max(0, frame.minX - bounds.minX),
                                    bottom: max(0, bounds.maxY - frame.maxY), right: max(0, bounds.maxX - frame.maxX))
            }
        }
        let bar = tabs.tabBar
        guard !bar.isHidden, bar.window != nil else { return window.safeAreaInsets }
        let frame = bar.convert(bar.bounds, to: window).intersection(window.bounds)
        guard !frame.isNull, frame.width > frame.height else { return window.safeAreaInsets }
        return UIEdgeInsets(top: window.safeAreaInsets.top, left: window.safeAreaInsets.left,
                            bottom: max(window.safeAreaInsets.bottom, window.bounds.maxY - frame.minY), right: window.safeAreaInsets.right)
    }

    /// 屏幕宽
    static var wy_screenWidth: CGFloat {
        return UIApplication.shared.wy_keyWindow.bounds.size.width
    }
    
    /// 屏幕高
    static var wy_screenHeight: CGFloat {
        return UIApplication.shared.wy_keyWindow.bounds.size.height
    }
    
    /// 屏幕宽度比率
    static func wy_screenWidthRatio(_ pixels: WYScreenPixels = WYBasisKitConfig.defaultScreenPixels) -> CGFloat {
        let widthRatio = (wy_screenWidth / pixels.width)
        if widthRatio < WYBasisKitConfig.screenWidthRatio.min {
            return WYBasisKitConfig.screenWidthRatio.min
        }else if widthRatio > WYBasisKitConfig.screenWidthRatio.max {
            return WYBasisKitConfig.screenWidthRatio.max
        }else {
            return widthRatio
        }
    }
    
    /// 屏幕高度比率
    static func wy_screenHeightRatio(_ pixels: WYScreenPixels = WYBasisKitConfig.defaultScreenPixels) -> CGFloat {
        let heightRatio = (wy_screenHeight / pixels.height)
        if heightRatio < WYBasisKitConfig.screenHeightRatio.min {
            return WYBasisKitConfig.screenHeightRatio.min
        }else if heightRatio > WYBasisKitConfig.screenHeightRatio.max {
            return WYBasisKitConfig.screenHeightRatio.max
        }else {
            return heightRatio
        }
    }
    
    /// 屏幕宽度比率转换
    static func wy_screenWidth(_ ratioValue: CGFloat, _ pixels: WYScreenPixels = WYBasisKitConfig.defaultScreenPixels) -> CGFloat {
        return round(ratioValue*wy_screenWidthRatio(pixels))
    }
    
    /// 屏幕高度比率转换
    static func wy_screenHeight(_ ratioValue: CGFloat, _ pixels: WYScreenPixels = WYBasisKitConfig.defaultScreenPixels) -> CGFloat {
        return round(ratioValue*wy_screenHeightRatio(pixels))
    }
    
    /// 设备型号
    static var wy_deviceName: String {
        return current.name
    }
    
    /// 系统名称
    static var wy_systemName: String {
        return current.systemName
    }
    
    /// 系统版本号
    static var wy_systemVersion: String {
        return current.systemVersion
    }
    
    /// 是否是iPhone系列
    static var wy_iPhoneSeries: Bool {
        return current.userInterfaceIdiom == .phone
    }
    
    /// 是否是iPhone折叠屏系列(尚未取得系统铰链信息时为nil)
    @available(iOS 27.1, *)
    static var wy_iPhoneFoldableSeries: Bool? {
        guard wy_iPhoneSeries else { return false }
        if WYDeviceFoldableContext.hasObservedFoldablePhone { return true }
        guard let context = WYDeviceFoldableContext.context(in: UIApplication.shared.wy_keyWindow),
              context.hasReceivedUpdate else { return nil }
        return context.hinge != nil
    }

    /// 是否是iPad系列
    static var wy_iPadSeries: Bool {
        return current.userInterfaceIdiom == .pad
    }
    
    /// iPhone折叠屏系列(当前)窗口的折叠状态
    @available(iOS 27.1, *)
    static var wy_foldableState: WYDeviceFoldableState {
        guard let context = WYDeviceFoldableContext.context(in: UIApplication.shared.wy_keyWindow) else { return .unknown }
        return WYDeviceFoldableContext.state(for: context.hinge, hasReceivedUpdate: context.hasReceivedUpdate)
    }

    /// iPhone折叠屏系列(当前)窗口的铰链角度(单位为弧度，无可用铰链信息时为nil)
    @available(iOS 27.1, *)
    static var wy_foldableAngle: CGFloat? {
        return WYDeviceFoldableContext.context(in: UIApplication.shared.wy_keyWindow)?.hinge?.angle
    }

    /// 是否是模拟器
    static var wy_simulatorSeries: Bool {
#if targetEnvironment(simulator)
        return true
#else
        return false
#endif
    }
    
    ///获取CPU核心数
    static var wy_numberOfCPUCores: Int {
        var ncpu: UInt = UInt(0)
        var len: size_t = MemoryLayout.size(ofValue: ncpu)
        sysctlbyname("hw.ncpu", &ncpu, &len, nil, 0)
        return Int(ncpu)
    }
    
    ///获取CPU类型
    static var wy_cpuType: String {
        
        let HOST_BASIC_INFO_COUNT = MemoryLayout<host_basic_info>.stride/MemoryLayout<integer_t>.stride
        var size = mach_msg_type_number_t(HOST_BASIC_INFO_COUNT)
        var hostInfo = host_basic_info()
        _ = withUnsafeMutablePointer(to: &hostInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity:Int(size)){
                host_info(mach_host_self(), Int32(HOST_BASIC_INFO), $0, &size)
            }
        }
        switch hostInfo.cpu_type {
        case CPU_TYPE_ARM:
            return "ARM"
        case CPU_TYPE_ARM64:
            return "ARM64"
        case CPU_TYPE_ARM64_32:
            return"ARM64_32"
        case CPU_TYPE_X86:
            return "X86"
        case CPU_TYPE_X86_64:
            return"X86_64"
        case CPU_TYPE_ANY:
            return"ANY"
        case CPU_TYPE_VAX:
            return"VAX"
        case CPU_TYPE_MC680x0:
            return"MC680x0"
        case CPU_TYPE_I386:
            return"I386"
        case CPU_TYPE_MC98000:
            return"MC98000"
        case CPU_TYPE_HPPA:
            return"HPPA"
        case CPU_TYPE_MC88000:
            return"MC88000"
        case CPU_TYPE_SPARC:
            return"SPARC"
        case CPU_TYPE_I860:
            return"I860"
        case CPU_TYPE_POWERPC:
            return"POWERPC"
        case CPU_TYPE_POWERPC64:
            return"POWERPC64"
        default:
            return ""
        }
    }
    
    /// UUID (注意：UUID并不是唯一不变的)
    static var wy_uuid: String {
        return current.identifierForVendor?.uuidString ?? ""
    }
    
    /// 是否是全屏手机
    static var wy_isFullScreen: Bool {
        return UIApplication.shared.wy_keyWindow.safeAreaInsets.bottom > 0
    }
    
    /// 是否是传入的分辨率
    static func wy_resolutionRatio(horizontal: CGFloat, vertical: CGFloat) -> Bool {
        if let modeSize = UIApplication.shared.wy_keyWindow.screen.currentMode?.size {
            return CGSize(width: horizontal, height: vertical).equalTo(modeSize) && !wy_iPadSeries
        }
        return false
    }
    
    /// 是否是竖屏模式
    static var wy_verticalScreen: Bool {
        
        let window = UIApplication.shared.wy_keyWindow
        var interfaceOrientation: UIInterfaceOrientation? = nil
        if #available(iOS 26.0, *) {
            interfaceOrientation = window.windowScene?.effectiveGeometry.interfaceOrientation
        } else {
            interfaceOrientation = window.windowScene?.interfaceOrientation ?? .unknown
        }
        return interfaceOrientation == .portrait || interfaceOrientation == .portraitUpsideDown
    }
    
    /// 是否是横屏模式
    static var wy_horizontalScreen: Bool {
        
        let window = UIApplication.shared.wy_keyWindow
        var interfaceOrientation: UIInterfaceOrientation? = nil
        if #available(iOS 26.0, *) {
            interfaceOrientation = window.windowScene?.effectiveGeometry.interfaceOrientation
        } else {
            interfaceOrientation = window.windowScene?.interfaceOrientation ?? .unknown
        }
        return interfaceOrientation == .landscapeLeft || interfaceOrientation == .landscapeRight
    }
    
    /// 设置屏幕亮度
    static var wy_screenBrightness: CGFloat {
        get {
            return UIApplication.shared.wy_keyWindowScene.screen.brightness
        }
        set {
            UIApplication.shared.wy_keyWindowScene.screen.brightness = max(0.0, min(1.0, newValue))
        }
    }
    
    /// 获取运营商IP地址
    static var wy_carrierIP: String {
        
        var addresses = [String]()
        var ifaddr : UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while (ptr != nil) {
                let flags = Int32(ptr!.pointee.ifa_flags)
                var addr = ptr!.pointee.ifa_addr.pointee
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                            if let address = String(validatingUTF8:hostname) {
                                addresses.append(address)
                            }
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return addresses.first ?? "0.0.0.0"
    }
    
    /// 获取 Wi-Fi IP地址
    static var wy_wifiIP: String {
        
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0 else {
            return "0.0.0.0"
        }
        guard let firstAddr = ifaddr else {
            return "0.0.0.0"
        }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            // Check for IPV4 or IPV6 interface
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                // Check interface name
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    // Convert interface address to a human readable string
                    var addr = interface.ifa_addr.pointee
                    var hostName = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr,socklen_t(interface.ifa_addr.pointee.sa_len), &hostName, socklen_t(hostName.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostName)
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return address ?? "0.0.0.0"
    }
    
    /// 当前电池健康度
    static var wy_batteryLevel: CGFloat {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        return CGFloat(level >= 0 ? (level * 100) : -1)
    }
    
    /// 磁盘总大小
    static var wy_totalDiskSize: String {
        
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
              let totalDiskSpaceInBytes = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else { return "0" }
        
        return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    /// 磁盘可用大小
    static var wy_availableDiskSize: String {
        
        var freeDiskSpaceInBytes: Int64 = 0
        if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
            freeDiskSpaceInBytes = space
        }
        return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    /// 磁盘已使用大小
    static var wy_usedDiskSize: String {
        
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
              let totalDiskSpaceInBytes = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else { return "0" }
        
        var freeDiskSpaceInBytes: Int64 = 0
        if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
            freeDiskSpaceInBytes = space
        }
        
        return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes - freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    /// 旋转屏幕，设置界面方向，支持重力感应切换(默认竖屏)
    static var wy_setInterfaceOrientation: UIInterfaceOrientationMask {
        
        set(newValue) {
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.privateInterfaceOrientation, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            switch newValue {
            case .portrait:
                stopMotionManager()
                wy_currentInterfaceOrientation = .portrait
                wy_rotateScreenTo(.portrait)
                break
            case .landscapeLeft:
                stopMotionManager()
                wy_currentInterfaceOrientation = .landscapeLeft
                wy_rotateScreenTo(.landscapeLeft)
                break
            case .landscapeRight:
                stopMotionManager()
                wy_currentInterfaceOrientation = .landscapeRight
                wy_rotateScreenTo(.landscapeRight)
                break
            case .portraitUpsideDown:
                stopMotionManager()
                wy_currentInterfaceOrientation = .portraitUpsideDown
                wy_rotateScreenTo(.portraitUpsideDown)
                break
            default:
                rotateScreenOrientationDynamically(newValue)
                break
            }
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.privateInterfaceOrientation) as? UIInterfaceOrientationMask ?? .portrait
        }
    }
    
    /// 获取当前设备屏幕方向(只会出现 portrait、landscapeLeft、landscapeRight、portraitUpsideDown 四种情况)
    static internal(set) var wy_currentInterfaceOrientation: UIInterfaceOrientationMask {
        set(newValue) {
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.privateCurrentInterfaceOrientation, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.privateCurrentInterfaceOrientation) as? UIInterfaceOrientationMask ?? .portrait
        }
    }
    
    /**
     *  设备震动一次
     *  @param style   震动风格
     */
    static func wy_vibrate(_ style: WYVibrationStyle) {
        switch style {
        case .system:
            // 系统震动 (需要导入 AudioToolbox)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .soft:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .rigid:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    /**
     *  设备连续震动
     *  @param style         震动风格
     *  @param repeatCount   重复次数
     *  @param interval      间隔（秒）
     */
    static func wy_vibrate(_ style: WYVibrationStyle, repeatCount: Int, interval: TimeInterval) {
        guard repeatCount > 0 else { return }
        
        for i in 0..<repeatCount {
            Task {
                try? await Task.wy_delay(interval * Double(i), cancelThrows: false, onMain: {
                    self.wy_vibrate(style)
                })
            }
        }
    }

    /**
     观察视图所在窗口的折叠状态
     @param view 接收系统铰链更新的视图
     @param handler 状态回调，state为当前折叠状态
     @return 已加入view的交互对象，停止观察时调用view.removeInteraction移除
     */
    @available(iOS 27.1, *)
    static func wy_observeFoldableState(in view: UIView, handler: @escaping (_ state: WYDeviceFoldableState) -> Void) -> UIHingeInteraction {
        return WYDeviceFoldableContext.observe(in: view, handler: handler)
    }
}
