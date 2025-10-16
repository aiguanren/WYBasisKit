//
//  WYLocalizableManager.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

/// 国际化语言版本(目前只国际化了简体中文、繁体中文、英语、法语、德语、俄语等29种语言，其他的可以调用WYLanguage.other属性来查看并设置需要加载的自定义本地化语言读取表)
@frozen public enum WYLanguage: Int {
    
    /// 简体中文(zh-Hans)
    case zh_Hans = 0
    
    /// 繁体中文(zh-Hant)
    case zh_Hant
    
    /// 英语(en)
    case english
    
    /// 法语(fr)
    case french
    
    /// 德语(de)
    case german
    
    /// 意大利语(it)
    case italian
    
    /// 瑞典语(sv)
    case swedish
    
    /// 荷兰语(nl)
    case dutch
    
    /// 丹麦语(da)
    case danish
    
    /// 希腊语(el)
    case greek
    
    /// 土耳其语(tr)
    case turkish
    
    /// 拉丁语(la)
    case latin
    
    /// 波兰语(pl)
    case polish
    
    /// 芬兰语(fi)
    case finnish
    
    /// 匈牙利语(hu)
    case hungarian
    
    /// 挪威语(nb)
    case norwegian
    
    /// 乌克兰语(uk)
    case ukrainian
    
    /// 俄语(ru)
    case russian
    
    /// 西班牙语(es)
    case spanish
    
    /// 葡萄牙语(pt-PT)
    case portuguese
    
    /// 日语(ja)
    case japanese
    
    /// 韩语(ko)
    case korean
    
    /// 泰语(th)
    case thai
    
    /// 蒙古语(mn)
    case mongolian
    
    /// 马来语(ms)
    case malay
    
    /// 印度尼西亚语(id)
    case indonesian
    
    /// 越南语(vi)
    case vietnamese
    
    /// 印地语(hi)
    case hindi
    
    /// 高棉语(柬埔寨)(km)
    case khmer
    
    /// 其他语言(具体查看other.stringValue)
    case other
    
    /// 获取对应的rawValue
    public var stringValue: String {
        switch self {
        case .zh_Hans:
            return "zh-Hans"
        case .zh_Hant:
            return "zh-Hant"
        case .english:
            return "en"
        case .french:
            return "fr"
        case .german:
            return "de"
        case .italian:
            return "it"
        case .swedish:
            return "sv"
        case .dutch:
            return "nl"
        case .danish:
            return "da"
        case .greek:
            return "el"
        case .turkish:
            return "tr"
        case .latin:
            return "la"
        case .polish:
            return "pl"
        case .finnish:
            return "fi"
        case .hungarian:
            return "hu"
        case .norwegian:
            return "nb"
        case .ukrainian:
            return "uk"
        case .russian:
            return "ru"
        case .spanish:
            return "es"
        case .portuguese:
            return "pt-PT"
        case .japanese:
            return "ja"
        case .korean:
            return "ko"
        case .thai:
            return "th"
        case .mongolian:
            return "mn"
        case .malay:
            return "ms"
        case .indonesian:
            return "id"
        case .vietnamese:
            return "vi"
        case .hindi:
            return "hi"
        case .khmer:
            return "km"
        case .other:
            let userLanguage: String = (UserDefaults.standard.value(forKey: WYBasisKitLanguage) as? String) ?? WYLocalizableManager.currentSystemLanguage()
            return userLanguage
        }
    }
}

private let WYBasisKitLanguage = "AppleLanguages"
private let WYBasisKit_preferred_language = "preferredLocalizations"

/**
 *  根据传入的Key读取对应的本地语言
 *
 *  @param key  本地语言对应的Key
 *
 *  @param table  国际化语言读取表(如果有Bundle，则要求Bundle名与表名一致，否则会读取失败)
 *
 */
public func WYLocalized(_ key: String, table: String = WYBasisKitConfig.localizableTable) -> String {
    return WYLocalizableManager.localized(key: key, table: table)
}

public struct WYLocalizableManager {
    
    private static var bundle: Bundle? = localizableBundle(table: WYBasisKitConfig.localizableTable)
    private static var kitBundle: Bundle? = localizableBundle(table: WYBasisKitConfig.kitLocalizableTable)
    
    /// 当前正在使用的语言
    public static func currentLanguage() -> WYLanguage {
        
        var preferredLanguage: String = UserDefaults.standard.value(forKey: WYBasisKit_preferred_language) as? String ?? ""
        let currentSystemLanguage: String = currentSystemLanguage()
        if currentSystemLanguage != preferredLanguage {
            
            UserDefaults.standard.set(currentSystemLanguage, forKey: WYBasisKit_preferred_language)
            
            UserDefaults.standard.set([currentSystemLanguage], forKey: WYBasisKitLanguage)
            
            UserDefaults.standard.synchronize()
            
            preferredLanguage = currentSystemLanguage
            
        }else {
            let userSettingLanguage: String? = UserDefaults.standard.value(forKey: WYBasisKitLanguage) as? String
            preferredLanguage = userSettingLanguage ?? currentSystemLanguage
        }
        switch preferredLanguage {
        case "zh-Hans":
            return WYLanguage(rawValue: WYLanguage.zh_Hans.rawValue)!
        case "zh-Hant":
            return WYLanguage(rawValue: WYLanguage.zh_Hant.rawValue)!
        case "en":
            return WYLanguage(rawValue: WYLanguage.english.rawValue)!
        case "fr":
            return WYLanguage(rawValue: WYLanguage.french.rawValue)!
        case "de":
            return WYLanguage(rawValue: WYLanguage.german.rawValue)!
        case "it":
            return WYLanguage(rawValue: WYLanguage.italian.rawValue)!
        case "sv":
            return WYLanguage(rawValue: WYLanguage.swedish.rawValue)!
        case "nl":
            return WYLanguage(rawValue: WYLanguage.dutch.rawValue)!
        case "da":
            return WYLanguage(rawValue: WYLanguage.danish.rawValue)!
        case "el":
            return WYLanguage(rawValue: WYLanguage.greek.rawValue)!
        case "tr":
            return WYLanguage(rawValue: WYLanguage.turkish.rawValue)!
        case "la":
            return WYLanguage(rawValue: WYLanguage.latin.rawValue)!
        case "pl":
            return WYLanguage(rawValue: WYLanguage.polish.rawValue)!
        case "fi":
            return WYLanguage(rawValue: WYLanguage.finnish.rawValue)!
        case "hu":
            return WYLanguage(rawValue: WYLanguage.hungarian.rawValue)!
        case "nb":
            return WYLanguage(rawValue: WYLanguage.norwegian.rawValue)!
        case "uk":
            return WYLanguage(rawValue: WYLanguage.ukrainian.rawValue)!
        case "ru":
            return WYLanguage(rawValue: WYLanguage.russian.rawValue)!
        case "es":
            return WYLanguage(rawValue: WYLanguage.spanish.rawValue)!
        case "pt-PT":
            return WYLanguage(rawValue: WYLanguage.portuguese.rawValue)!
        case "ja":
            return WYLanguage(rawValue: WYLanguage.japanese.rawValue)!
        case "ko":
            return WYLanguage(rawValue: WYLanguage.korean.rawValue)!
        case "th":
            return WYLanguage(rawValue: WYLanguage.thai.rawValue)!
        case "mn":
            return WYLanguage(rawValue: WYLanguage.mongolian.rawValue)!
        case "ms":
            return WYLanguage(rawValue: WYLanguage.malay.rawValue)!
        case "id":
            return WYLanguage(rawValue: WYLanguage.indonesian.rawValue)!
        case "vi":
            return WYLanguage(rawValue: WYLanguage.vietnamese.rawValue)!
        case "hi":
            return WYLanguage(rawValue: WYLanguage.hindi.rawValue)!
        case "km":
            return WYLanguage(rawValue: WYLanguage.khmer.rawValue)!
        default:
            return WYLanguage(rawValue: WYLanguage.other.rawValue)!
        }
    }
    
    /// 获取当前系统语言
    public static func currentSystemLanguage() -> String {
        
        // 获取用户设置的语言列表
        let appleLanguages = UserDefaults.standard.array(forKey: WYBasisKitLanguage) as? [String] ?? []
        let countryCode = Locale.current.regionCode ?? ""

        guard var appleLanguage = appleLanguages.first else {
            return Locale.current.languageCode ?? "en"
        }
        
        // 去掉语言中的国家码
        appleLanguage = appleLanguage.replacingOccurrences(of: "-" + countryCode, with: "")
        
        // English 统一返回 "en"
        if appleLanguage.hasPrefix("en") {
            appleLanguage = "en"
        }
        
        return appleLanguage
    }
    
    /**
     *  切换本地语言
     *
     *  @param language  准备切换的目标语言
     *
     *  @param reload  是否重新加载App
     *
     *  @param name  Storyboard文件的名字，默认Main(一般不需要修改，使用默认的就好)
     *
     *  @param identifier  Storyboard文件的Identifier
     *
     */
    public static func switchLanguage(language: WYLanguage, reload: Bool = true, name: String = "Main", identifier: String = "rootViewController", handler:(() -> Void)? = nil) {
        
        guard language.stringValue != currentLanguage().stringValue else {
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
        reloadStoryboard(name: name, identifier: identifier, handler: handler)
    }
    
    /**
     *  根据传入的Key读取对应的本地语言
     *
     *  @param key  本地语言对应的Key
     *
     *  @param table  国际化语言读取表(如果有Bundle，则要求Bundle名与表名一致，否则会读取失败)
     *
     */
    public static func localized(key: String, table: String = WYBasisKitConfig.localizableTable) -> String {
        
        guard table.isEmpty == false else {
            return key
        }
        
        if table == WYBasisKitConfig.localizableTable {
            
            guard bundle != nil else {
                return WYLocalized(key)
            }
            return bundle!.localizedString(forKey: key, value: nil, table: table)
        }
        
        if table == WYBasisKitConfig.kitLocalizableTable {
            
            guard kitBundle != nil else {
                return WYLocalized(key)
            }
            return kitBundle!.localizedString(forKey: key, value: nil, table: table)
        }
        
        guard let otherBundle = localizableBundle(table: table) else {
            return WYLocalized(key)
        }
        return otherBundle.localizedString(forKey: key, value: nil, table: table)
    }
    
    /// 点击切换语言后调用该方法切换本地语言
    private static func reloadStoryboard(name: String, identifier: String, handler:(() -> Void)? = nil) {
        
        if let appdelegate = UIApplication.shared.delegate {
            
            let storyBoard = UIStoryboard(name: name, bundle: nil)
            
            let mainController = storyBoard.instantiateViewController(withIdentifier: identifier)
            
            appdelegate.window??.rootViewController = mainController
        }
        
        if handler != nil {
            
            handler!()
        }
    }
    
    /// 获取存放国际化资源的Bundle
    private static func localizableBundle(from language: WYLanguage = currentLanguage(), table: String) -> Bundle? {
        
        let bundlePath = (Bundle(for: WYLocalizableClass.self).path(forResource: table, ofType: "bundle")) ?? (Bundle.main.path(forResource: table, ofType: "bundle"))
        
        guard let resourcePath = bundlePath else {
            /// 如果没有找到存放国际化资源的Bundle文件，就直接从本地加载国际化文件
            return Bundle(path: (Bundle(for: WYLocalizableClass.self).path(forResource: language.stringValue, ofType: "lproj") ?? Bundle.main.path(forResource: language.stringValue, ofType: "lproj")) ?? "")
        }
        /// 从找到的存放国际化资源的Bundle文件中加载国际化资源
        return Bundle(path: Bundle(path: resourcePath)?.path(forResource: language.stringValue, ofType: "lproj") ?? "")
    }
}

private class WYLocalizableClass {}
