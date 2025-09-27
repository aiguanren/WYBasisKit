//
//  WYTabBarController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/3.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

class WYTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.backgroundColor = .wy_dynamic(.white, .black)
        layoutTabBar()
    }
    
    func layoutTabBar() {
        
        let leftController = WYMainController()
        leftController.view.backgroundColor = .wy_dynamic(.white, .black)
        
        layoutTabbrItem(controller: leftController, title: "左", defaultImage: UIImage(named: "tabbar_left_default")!, selectedImage: UIImage(named: "tabbar_left_selected")!)
        
        let centerController = WYCenterController()
        centerController.view.backgroundColor = .wy_dynamic(.white, .black)
        layoutTabbrItem(controller: centerController, title: "中", defaultImage: UIImage(named: "tabbar_center_default")!, selectedImage: UIImage(named: "tabbar_center_selected")!)
        
        let rightController = WYRightController()
        rightController.view.backgroundColor = .wy_dynamic(.white, .black)
        layoutTabbrItem(controller: rightController, title: "右", defaultImage: UIImage(named: "tabbar_right_default")!, selectedImage: UIImage(named: "tabbar_right_selected")!)
    }
    
    func layoutTabbrItem(controller: UIViewController, title: String, defaultImage: UIImage, selectedImage: UIImage) {
        
        let nav = UINavigationController(rootViewController: controller)
        layoutNavigationBar(nav: nav)
        
        nav.tabBarItem.title = title
        nav.tabBarItem.image = defaultImage.withRenderingMode(.alwaysOriginal)
        nav.tabBarItem.selectedImage = selectedImage.withRenderingMode(.alwaysOriginal)
        self.addChild(nav)
        
        let appearance = tabBar.standardAppearance.copy()
        
        //appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.font: UIFont.ly_tabbar_title_font, NSAttributedString.Key.foregroundColor: UIColor.ly_tabbar_title_defaultColor]
        
        //appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.font: UIFont.ly_tabbar_title_font, NSAttributedString.Key.foregroundColor: UIColor.ly_tabbar_title_highlightColor]
        
        tabBar.standardAppearance = appearance
        
        let clearView = UIView(frame: CGRect(x: 0, y: 0, width: UIDevice.wy_screenWidth, height: UIDevice.wy_tabBarHeight))
        clearView.backgroundColor = .wy_dynamic(.white, .black)
        tabBar.insertSubview(clearView, at: 0)
    }
    
    func layoutNavigationBar(nav: UINavigationController) {
        
        UINavigationController.wy_navBarBackgroundColor = .wy_dynamic(.wy_hex(string: "#2AACFF"), .wy_hex(string: "#2A7DFF"))
        
        UINavigationController.wy_navBarTitleColor = .wy_dynamic(.black, .white)
        
        UINavigationController.wy_navBarTitleFont = .boldSystemFont(ofSize: 18)
        
        UINavigationController.wy_navBarReturnButtonImage = UIImage.wy_find("back");
        
        UINavigationController.wy_navBarReturnButtonColor = .wy_dynamic(.black, .white)
        
        UINavigationController.wy_navBarReturnButtonTitle = ""
        
        UINavigationController.wy_navBarShadowLineHidden = true
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
