//
//  WYNavigationController+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit

extension UIViewController {

    static func wy_installViewWillAppearHook() {
        wy_swizzlerViewWillAppear(for: UIViewController.self, after: { currentController, animated in
            // 在页面显示前更新导航栏样式
            if let navController = currentController.navigationController {
                navController.updateNavigationBarAppearance(for: currentController)
            }
        })
    }


}

extension UINavigationController {

    // 返回按钮拦截处理
    fileprivate static let wy_swizzlePopOnce: Void = {

        wy_swizzlerPopViewController(for: UINavigationController.self, intercept: { currentNavigationController, animated in
            // 获取当前正在显示的控制器
            guard let topVC = currentNavigationController.topViewController else {
                return .proceed
            }

            // 调用拦截协议
            if topVC.responds(to: #selector(WYViewControllerHandlerProtocol.wy_navigationBarWillReturn)) {
                let allowed = topVC.wy_navigationBarWillReturn()
                if !allowed {
                    // 不允许返回，拦截：直接返回 nil，不再执行原始 pop
                    return .result(nil)
                }
            }
            // 允许返回，继续执行原始 pop
            return .proceed
        })
    }()

    /// 更新指定控制器的导航栏样式
    func updateNavigationBarAppearance(for viewController: UIViewController) {

        // 创建外观配置
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()

        // 设置背景
        if let backgroundImage = viewController.wy_navBarBackgroundImage {
            navBarAppearance.backgroundImage = backgroundImage
        } else if let backgroundColor = viewController.wy_navBarBackgroundColor {
            navBarAppearance.backgroundColor = backgroundColor
        }

        // 设置标题
        navBarAppearance.titleTextAttributes = [
            .font: viewController.wy_navBarTitleFont,
            .foregroundColor: viewController.wy_navBarTitleColor
        ]

        // 设置阴影
        if viewController.wy_navBarShadowLineHidden {
            navBarAppearance.shadowColor = .clear
            navBarAppearance.shadowImage = UIImage()
        } else {
            navBarAppearance.shadowColor = viewController.wy_navBarShadowLineColor
            navBarAppearance.shadowImage = nil
        }

        // 设置返回按钮
        let backButtonAppearance = UIBarButtonItemAppearance(style: .plain)
        backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: viewController.wy_navBarReturnButtonColor
        ]
        navBarAppearance.backButtonAppearance = backButtonAppearance

        // 应用配置
        navigationBar.standardAppearance = navBarAppearance
        navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationBar.compactAppearance = navBarAppearance

        // 单独设置返回按钮
        navigationBar.tintColor = viewController.wy_navBarReturnButtonColor
        if let backImage = viewController.wy_navBarReturnButtonImage {
            navigationBar.backIndicatorImage = backImage
            navigationBar.backIndicatorTransitionMaskImage = backImage
        }

        // 设置返回按钮文本
        viewController.navigationItem.backBarButtonItem = UIBarButtonItem(
            title: viewController.wy_navBarReturnButtonTitle,
            style: .plain,
            target: nil,
            action: nil
        )
    }

}

/// 导航扩展初始化
@objc(WYNavigationBootstrapInstaller)
final class WYNavigationBootstrapInstaller: NSObject {

    /// 安装导航样式与返回拦截
    @objc static func install() {
        _ = installation
    }

    /// 导航交换只执行一次
    private static let installation: Void = {
        _ = UINavigationController.wy_swizzlePopOnce
        _ = UIViewController.wy_swizzleViewWillAppearOnce
    }()
}
