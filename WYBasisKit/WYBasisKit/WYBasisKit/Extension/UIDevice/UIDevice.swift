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

public extension UIDevice {
    
    /// 状态栏高度
    class var wy_statusBarHeight: CGFloat {
        get {
            if #available(iOS 13.0, *) {
                let window = UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).first?.windows.first
                return window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0
            } else {
                return UIApplication.shared.statusBarFrame.height
            }
        }
    }

    /// 导航栏安全区域
    class var wy_navBarSafetyZone: CGFloat {
        get {
            if #available(iOS 13.0, *) {
                let window = UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).first?.windows.first
                return window?.safeAreaInsets.top ?? 0.0
            } else {
                let window = UIApplication.shared.windows.first
                return window?.safeAreaInsets.top ?? 0.0
            }
        }
    }

    /// 导航栏高度
    class var wy_navBarHeight: CGFloat {
        // 使用系统默认导航栏获取标准高度
        return UINavigationBar().intrinsicContentSize.height
    }

    /// 导航视图高度（状态栏+导航栏）
    class var wy_navViewHeight: CGFloat {
        return wy_statusBarHeight + wy_navBarHeight
    }

    /// tabBar安全区域
    class var wy_tabbarSafetyZone: CGFloat {
        get {
            if #available(iOS 13.0, *) {
                let window = UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).first?.windows.first
                return window?.safeAreaInsets.bottom ?? 0.0
            } else {
                let window = UIApplication.shared.windows.first
                return window?.safeAreaInsets.bottom ?? 0.0
            }
        }
    }

    /// tabBar高度(含安全区域高度)
    class var wy_tabBarHeight: CGFloat {
        return UITabBar().sizeThatFits(.zero).height + wy_tabbarSafetyZone
    }

    /// 屏幕宽
    class var wy_screenWidth: CGFloat {
        return UIScreen.main.bounds.size.width
    }

    /// 屏幕高
    class var wy_screenHeight: CGFloat {
        return UIScreen.main.bounds.size.height
    }

    /// 屏幕宽度比率
    class func wy_screenWidthRatio(_ pixels: WYScreenPixels = WYBasisKitConfig.defaultScreenPixels) -> CGFloat {
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
    class func wy_screenHeightRatio(_ pixels: WYScreenPixels = WYBasisKitConfig.defaultScreenPixels) -> CGFloat {
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
    class func wy_screenWidth(_ ratioValue: CGFloat, _ pixels: WYScreenPixels = WYBasisKitConfig.defaultScreenPixels) -> CGFloat {
        return round(ratioValue*wy_screenWidthRatio(pixels))
    }

    /// 屏幕高度比率转换
    class func wy_screenHeight(_ ratioValue: CGFloat, _ pixels: WYScreenPixels = WYBasisKitConfig.defaultScreenPixels) -> CGFloat {
        return round(ratioValue*wy_screenHeightRatio(pixels))
    }
    
    /// 设备型号
    var wy_deviceName: String {
        return name
    }
    
    /// 系统名称
    var wy_systemName: String {
        return systemName
    }
    
    /// 系统版本号
    var wy_systemVersion: String {
        return systemVersion
    }
    
    /// 是否是iPhone系列
    var wy_iPhoneSeries: Bool {
        return userInterfaceIdiom == .phone
    }
    
    /// 是否是iPad系列
    var wy_iPadSeries: Bool {
        return userInterfaceIdiom == .pad
    }
    
    /// 是否是模拟器
    var wy_simulatorSeries: Bool {
#if targetEnvironment(simulator)
        return true
#else
        return false
#endif
    }
    
    ///获取CPU核心数
    var wy_numberOfCpuCores: Int {
        var ncpu: UInt = UInt(0)
        var len: size_t = MemoryLayout.size(ofValue: ncpu)
        sysctlbyname("hw.ncpu", &ncpu, &len, nil, 0)
        return Int(ncpu)
    }
    
    ///获取CPU类型
    var wy_cpuType: String {
        
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
    var wy_uuid: String {
        return identifierForVendor?.uuidString ?? ""
    }
    
    
    /// 是否是全屏手机
    var wy_isFullScreen: Bool {
        if #available(iOS 15.0, *) {
            let window = UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).first?.windows.first
            return (window?.safeAreaInsets ?? UIEdgeInsets.zero).bottom != 0
        } else {
            return (UIApplication.shared.windows.first?.safeAreaInsets)?.bottom != 0
        }
    }
    
    /// 是否是传入的分辨率
    func wy_resolutionRatio(horizontal: CGFloat, vertical: CGFloat) -> Bool {
        return (UIScreen.instancesRespond(to: #selector(getter: UIScreen.main.currentMode)) ? CGSize(width: horizontal, height: vertical).equalTo((UIScreen.main.currentMode?.size)!) && !wy_iPadSeries : false)
    }
    
    /// 是否是竖屏模式
    var wy_verticalScreen: Bool {
        
        var orientation: UIInterfaceOrientation = .portrait
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).first?.windows.first
            orientation = (window?.windowScene?.interfaceOrientation) ?? .portrait
        }else {
            orientation = UIApplication.shared.statusBarOrientation
        }
        
        if (orientation == UIInterfaceOrientation.portrait) ||
            (orientation == UIInterfaceOrientation.portraitUpsideDown) {
            return true
        } else {
            return false
        }
    }
    
    /// 是否是横屏模式
    var wy_horizontalScreen: Bool {
        
        var orientation: UIInterfaceOrientation = .portrait
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).first?.windows.first
            orientation = (window?.windowScene?.interfaceOrientation) ?? .portrait
        }else {
            orientation = UIApplication.shared.statusBarOrientation
        }
        
        if (orientation == UIInterfaceOrientation.landscapeLeft) ||
            (orientation == UIInterfaceOrientation.landscapeRight) {
            return true
        } else {
            return false
        }
    }
    
    /// 获取运营商IP地址
    var wy_carrierIP: String {
        
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
    
    /// 获取 Wifi IP地址
    var wy_wifiIP: String {
        
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
    var wy_batteryLevel: CGFloat {
        return 100.0 + CGFloat(self.batteryLevel)
    }
    
    /// 磁盘总大小
    var wy_totalDiskSize: String {
        
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
              let totalDiskSpaceInBytes = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else { return "0" }
        
        return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    /// 磁盘可用大小
    var wy_availableDiskSize: String {
        
        var freeDiskSpaceInBytes: Int64 = 0
        if #available(iOS 11.0, *) {
            if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                freeDiskSpaceInBytes = space
            }
        } else {
            if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
               let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
                freeDiskSpaceInBytes = freeSpace
            }
        }
        return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    /// 磁盘已使用大小
    var wy_usedDiskSize: String {
        
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
              let totalDiskSpaceInBytes = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else { return "0" }
        
        var freeDiskSpaceInBytes: Int64 = 0
        if #available(iOS 11.0, *) {
            if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                freeDiskSpaceInBytes = space
            }
        } else {
            if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
               let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
                freeDiskSpaceInBytes = freeSpace
            }
        }
        
        return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes - freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    /// 旋转屏幕，设置界面方向，支持重力感应切换(默认竖屏)
    var wy_interfaceOrientation: UIInterfaceOrientationMask {
        
        set(newValue) {
            
            objc_setAssociatedObject(self, WYAssociatedKeys.privateInterfaceOrientation, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
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
            return objc_getAssociatedObject(self, WYAssociatedKeys.privateInterfaceOrientation) as? UIInterfaceOrientationMask ?? .portrait
        }
    }
    
    /// 获取当前设备屏幕方向(只会出现 portrait、landscapeLeft、landscapeRight、portraitUpsideDown 四种情况)
    private(set) var wy_currentInterfaceOrientation: UIInterfaceOrientationMask {
        set(newValue) {
            
            objc_setAssociatedObject(self, WYAssociatedKeys.privateCurrentInterfaceOrientation, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.privateCurrentInterfaceOrientation) as? UIInterfaceOrientationMask ?? .portrait
        }
    }
}

private extension UIDevice {
    
    // 旋转屏幕到指定方向
    private func wy_rotateScreenTo(_ orientation: UIInterfaceOrientation) {
        if #available(iOS 16.0, *) {
            
            let window = UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).first?.windows.first
            
            if let windowScene: UIWindowScene = window?.windowScene {
                UIViewController.wy_currentController()?.setNeedsUpdateOfSupportedInterfaceOrientations()
                windowScene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: wy_currentInterfaceOrientation)) { error in
                    WYLogManager.output("旋转屏幕方向出错啦： \(error.localizedDescription)")
                }
                
            }else {
                WYLogManager.output("旋转屏幕方向出错啦")
            }
        }else {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    func rotateScreenOrientationDynamically(_ orientation: UIInterfaceOrientationMask) {
        
        if motionManager == nil {
            motionManager = CMMotionManager()
            motionManager?.accelerometerUpdateInterval = 0.75
        }
        if motionManager!.isAccelerometerAvailable {
            
            motionManager!.startAccelerometerUpdates(to: OperationQueue.current!) { [weak self] (accelerometerData, error) in
                if error != nil {
                    self?.stopMotionManager()
                    WYLogManager.output("启用加速传感器出错：\(error!.localizedDescription)")
                }else {
                    
                    let x: Double = accelerometerData!.acceleration.x
                    let y: Double = accelerometerData!.acceleration.y
                    
                    if (fabs(y) >= fabs(x)) {
                        
                        if orientation == .landscape {
                            return
                        }
                        
                        if y >= 0 {
                            if orientation == .allButUpsideDown {
                                return
                            }
                            
                            self?.wy_currentInterfaceOrientation = .portraitUpsideDown
                            UIDevice.current.wy_rotateScreenTo(.portraitUpsideDown)
                            
                        } else {
                            
                            self?.wy_currentInterfaceOrientation = .portrait
                            UIDevice.current.wy_rotateScreenTo(.portrait)
                        }
                        
                    }else {
                        
                        if x >= 0 {
                            
                            self?.wy_currentInterfaceOrientation = .landscapeLeft
                            UIDevice.current.wy_rotateScreenTo(.landscapeLeft)
                            
                        } else{
                            
                            self?.wy_currentInterfaceOrientation = .landscapeRight
                            UIDevice.current.wy_rotateScreenTo(.landscapeRight)
                        }
                    }
                }
            }
        }else {
            WYLogManager.output("当前设备不支持加速传感器")
        }
    }
    
    func stopMotionManager() {
        
        guard motionManager != nil else {
            return
        }
        
        if motionManager!.isAccelerometerActive {
            motionManager?.stopAccelerometerUpdates()
        }
        motionManager = nil
    }
    
    var motionManager: CMMotionManager? {
        
        set(newValue) {
            
            objc_setAssociatedObject(self, WYAssociatedKeys.privateMotionManager, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.privateMotionManager) as? CMMotionManager
        }
    }
    
    struct WYAssociatedKeys {
        
        static let privateMotionManager = UnsafeRawPointer(bitPattern: "privateMotionManager".hashValue)!
        
        static let privateInterfaceOrientation = UnsafeRawPointer(bitPattern: "privateInterfaceOrientation".hashValue)!
        
        static let privateCurrentInterfaceOrientation = UnsafeRawPointer(bitPattern: "privateCurrentInterfaceOrientation".hashValue)!
    }
}
