//
//  WYLogController.swift
//  WYBasisKitVerify
//
//  Created by guanren on 2025/7/26.
//

import UIKit

class WYLogController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        //WYLogManager.clearLogFile()
        
        WYLogManager.output("不保存日志，仅在 DEBUG 模式下输出到控制台（默认）")
        
        WYLogManager.output("不保存日志，DEBUG 和 RELEASE 都输出到控制台", outputMode: .alwaysConsoleOnly)
        
        WYLogManager.output("保存日志，仅在 DEBUG 模式下输出到控制台", outputMode: .debugConsoleAndFile)
        
        WYLogManager.output("保存日志，DEBUG 和 RELEASE 都输出到控制台", outputMode: .alwaysConsoleAndFile)
        
        WYLogManager.output("仅保存日志，DEBUG 和 RELEASE 均不输出到控制台", outputMode: .onlySaveToFile)
        
        WYLogManager.output("状态栏高度 = \(UIDevice.wy_statusBarHeight)\n导航栏安全区域高度 = \(UIDevice.wy_navBarSafetyZone)\n导航栏高度 = \(UIDevice.wy_navBarHeight)\n导航视图高度（状态栏+导航栏） = \(UIDevice.wy_navViewHeight)\ntabBar安全区域高度 = \(UIDevice.wy_tabbarSafetyZone)\ntabBar高度(含安全区域高度) = \(UIDevice.wy_tabBarHeight)\n是否是全屏手机 = \(UIDevice.current.wy_isFullScreen)", outputMode: .alwaysConsoleAndFile)
        
        WYLogManager.output(String.wy_random(minimux: 20, maximum: 100), outputMode: .debugConsoleAndFile)
        
        WYLogManager.showPreview()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
