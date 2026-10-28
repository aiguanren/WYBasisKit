//
//  WYLocalizableManager+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit

extension WYLocalizableManager {

    @MainActor static func internalSwitchLanguage(language: WYLanguage, reload: Bool = true, name: String = "Main", identifier: String = "rootViewController", rootViewControllerProvider: (() -> UIViewController)? = nil, handler:(() -> Void)? = nil) {
        
        guard language.stringValue != currentLanguage().stringValue else {
            // 目标语言与当前一致：缓存的读取表可能还停在别的语言(默认值被外部改过)，此时补一次对齐并重建界面
            if bundle?.bundlePath.contains("/\(language.stringValue).lproj") != true || kitBundle?.bundlePath.contains("/\(language.stringValue).lproj") != true {
                if WYBasisKitConfig.localizableTable.isEmpty == false, let appBundle = localizableBundle(from: language, table: WYBasisKitConfig.localizableTable) {
                    bundle = appBundle
                }
                if let appKitBundle = localizableBundle(from: language, table: WYBasisKitConfig.kitLocalizableTable) {
                    kitBundle = appKitBundle
                }
                if reload == true {
                    if let provider = rootViewControllerProvider {
                        reloadWithProvider(provider: provider, handler: handler)
                    }else {
                        reloadStoryboard(name: name, identifier: identifier, handler: handler)
                    }
                    return
                }
            }
            if handler != nil {
                handler!()
            }
            return
        }
        
        if WYBasisKitConfig.localizableTable.isEmpty == false {
            guard let languageBundle = localizableBundle(from: language, table: WYBasisKitConfig.localizableTable) else {
                return
            }
            bundle = languageBundle
        }
        
        guard let KitLanguageBundle = localizableBundle(from: language, table: WYBasisKitConfig.kitLocalizableTable) else {
            return
        }
        kitBundle = KitLanguageBundle
        
        UserDefaults.standard.setValue([language.stringValue], forKey: WYBasisKitLanguage)
        UserDefaults.standard.synchronize()
        
        guard reload == true else {
            if handler != nil {
                handler!()
            }
            return
        }

        if let provider = rootViewControllerProvider {
            reloadWithProvider(provider: provider, handler: handler)
            return
        }
        reloadStoryboard(name: name, identifier: identifier, handler: handler)
    }
    
    static func internalLocalized(key: String, table: String = WYBasisKitConfig.localizableTable, source: WYLocalizableSource? = nil) -> String {
        
        guard table.isEmpty == false else {
            return key
        }
        
        // 如果未提供 source，且 table 是默认表，使用缓存的 bundle
        if source == nil && table == WYBasisKitConfig.localizableTable {
            guard bundle != nil else {
                return key
            }
            return bundle!.localizedString(forKey: key, value: nil, table: table)
        }
        
        if source == nil && table == WYBasisKitConfig.kitLocalizableTable {
            guard kitBundle != nil else {
                return key
            }
            return kitBundle!.localizedString(forKey: key, value: nil, table: table)
        }
        
        // 根据 source 动态获取 Bundle
        guard let languageBundle = localizableBundle(from: currentLanguage(), table: table, source: source) else {
            return key
        }
        return languageBundle.localizedString(forKey: key, value: nil, table: table)
    }
    
    /// App当前语言的国际化语言包(App语言表的国际化文案从它读取，切换语言后自动更新)
    private static var bundle: Bundle? = localizableBundle(table: WYBasisKitConfig.localizableTable)
    
    /// WYBasisKit内置文案的国际化语言包(与App语言包分开维护，切换语言后自动更新)
    private static var kitBundle: Bundle? = localizableBundle(table: WYBasisKitConfig.kitLocalizableTable)
    
    /// 用注册的根控制器构建闭包重建界面(纯代码+SceneDelegate工程走这里)
    @MainActor private static func reloadWithProvider(provider: () -> UIViewController, handler:(() -> Void)? = nil) {

        // 优先找前台活跃场景的keyWindow，找不到再回落AppDelegate.window
        var targetWindow: UIWindow?
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            targetWindow = scene.keyWindow
            if targetWindow == nil {
                targetWindow = scene.windows.first
            }
        }
        if targetWindow == nil {
            targetWindow = UIApplication.shared.delegate?.window ?? nil
        }

        if let window = targetWindow {
            window.rootViewController = provider()
            window.makeKeyAndVisible()
        }

        if handler != nil {
            handler!()
        }
    }
    
    /// 点击切换语言后调用该方法切换本地语言
    @MainActor private static func reloadStoryboard(name: String, identifier: String, handler:(() -> Void)? = nil) {
        
        reloadWithProvider(provider: {
            UIStoryboard(name: name, bundle: nil).instantiateViewController(withIdentifier: identifier)
        }, handler: handler)
    }
    
    /// 获取存放国际化资源的Bundle
    private static func localizableBundle(from language: WYLanguage = currentLanguage(), table: String, source: WYLocalizableSource? = nil) -> Bundle? {
        
        // 确定 Bundle
        let containerBundles: [Bundle] = {
            if let targetClass = source?.targetClass {
                return [Bundle(for: targetClass), Bundle.main]
            } else {
                return [Bundle(for: WYLocalizableClass.self), Bundle.main]
            }
        }()
        
        // 确定要查找的 bundle 名称（优先使用 source 指定的，否则使用 table）
        let bundleName = source?.bundleName ?? table
        
        // 遍历容器，查找 .bundle 文件
        for container in containerBundles {
            if let bundlePath = container.path(forResource: bundleName, ofType: "bundle"),
               let resourceBundle = Bundle(path: bundlePath) {
                // 在 .bundle 内查找对应语言的 lproj 目录
                if let lprojPath = resourceBundle.path(forResource: language.stringValue, ofType: "lproj"),
                   let lprojBundle = Bundle(path: lprojPath) {
                    return lprojBundle
                }
            }
        }
        
        // 没有找到 .bundle，则直接从容器 Bundle 中查找 lproj 目录
        for container in containerBundles {
            if let lprojPath = container.path(forResource: language.stringValue, ofType: "lproj"),
               let lprojBundle = Bundle(path: lprojPath) {
                return lprojBundle
            }
        }
        
        return nil
    }
}


let WYBasisKitLanguage = "AppleLanguages"
let WYBasisKit_preferred_language = "preferredLocalizations"
private class WYLocalizableClass {}
