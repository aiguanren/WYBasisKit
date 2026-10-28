//
//  WYDevice+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit
import CoreMotion

extension UIDevice {
    static var privateVisibleNavigationBar: UINavigationBar? {
        let controller = UIViewController.wy_currentController()
        guard let navigation = (controller as? UINavigationController) ?? controller?.navigationController,
              navigation.isViewLoaded, !navigation.isNavigationBarHidden,
              navigation.navigationBar.window != nil else { return nil }
        return navigation.navigationBar
    }

    
    // 旋转屏幕到指定方向
    static func wy_rotateScreenTo(_ orientation: UIInterfaceOrientation) {
        if #available(iOS 16.0, *) {
            UIViewController.wy_currentController()?.setNeedsUpdateOfSupportedInterfaceOrientations()
            UIApplication.shared.wy_keyWindowScene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: self.wy_currentInterfaceOrientation)) { error in
                WYLogManager.output("旋转屏幕方向出错啦： \(error.localizedDescription)")
            }
        }else {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    static func rotateScreenOrientationDynamically(_ orientation: UIInterfaceOrientationMask) {
        
        if motionManager == nil {
            motionManager = CMMotionManager()
            motionManager?.accelerometerUpdateInterval = 0.75
        }
        if motionManager!.isAccelerometerAvailable {
            
            motionManager!.startAccelerometerUpdates(to: OperationQueue.current!) { (accelerometerData, error) in
                if error != nil {
                    stopMotionManager()
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
                            
                            wy_currentInterfaceOrientation = .portraitUpsideDown
                            UIDevice.wy_rotateScreenTo(.portraitUpsideDown)
                            
                        } else {
                            
                            wy_currentInterfaceOrientation = .portrait
                            UIDevice.wy_rotateScreenTo(.portrait)
                        }
                        
                    }else {
                        
                        if x >= 0 {
                            
                            wy_currentInterfaceOrientation = .landscapeLeft
                            UIDevice.wy_rotateScreenTo(.landscapeLeft)
                            
                        } else{
                            
                            wy_currentInterfaceOrientation = .landscapeRight
                            UIDevice.wy_rotateScreenTo(.landscapeRight)
                        }
                    }
                }
            }
        }else {
            WYLogManager.output("当前设备不支持加速传感器")
        }
    }
    
    static func stopMotionManager() {
        
        guard motionManager != nil else {
            return
        }
        
        if motionManager!.isAccelerometerActive {
            motionManager?.stopAccelerometerUpdates()
        }
        motionManager = nil
    }
    
    static var motionManager: CMMotionManager? {
        
        set(newValue) {
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.privateMotionManager, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.privateMotionManager) as? CMMotionManager
        }
    }
    
    static let privateNavigationBar: UINavigationBar = UINavigationBar()
    
    static let privateTabBar: UITabBar = UITabBar()
    
    struct WYAssociatedKeys {
        
        static var privateMotionManager: UInt8 = 0
        
        static var privateInterfaceOrientation: UInt8 = 0
        
        static var privateCurrentInterfaceOrientation: UInt8 = 0
    }
}
