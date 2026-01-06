//
//  WYLocalizableManagerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/5.
//

import UIKit
#if WYBasisKit_Supports_ObjC
import WYBasisKitSwift
#endif

/// 国际化语言版本(目前只国际化了简体中文、繁体中文、英语、法语、德语、俄语等29种语言，其他的可以调用WYLanguage.other属性来查看并设置需要加载的自定义本地化语言读取表)
@objc(WYLanguage)
@frozen public enum WYLanguageObjC: Int {
    
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
}

@objc(WYLocalizableManager)
@objcMembers public class WYLocalizableManagerObjC: NSObject {
    
    /// 当前正在使用的语言
    @objc public static func currentLanguage() -> WYLanguageObjC {
        let language: WYLanguage = WYLocalizableManager.currentLanguage()
        return WYLanguageObjC(rawValue: language.rawValue) ?? .zh_Hans
    }
    
    /// 获取当前系统语言
    @objc public static func currentSystemLanguage() -> String {
        return WYLocalizableManager.currentSystemLanguage()
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
    @objc public static func switchLanguage(language: WYLanguageObjC, reload: Bool = true, name: String? = nil, identifier: String? = nil, handler:(() -> Void)? = nil) {
        
        let switchLanguage: WYLanguage = WYLanguage(rawValue: language.rawValue) ?? .zh_Hans
        
        let storyboardName: String = name ?? "Main"
        
        let storyboardIdentifier: String = identifier ?? "rootViewController"
        
        WYLocalizableManager.switchLanguage(language: switchLanguage, reload: reload, name: storyboardName, identifier: storyboardIdentifier, handler: handler)
    }
    
    /**
     *  根据传入的Key读取对应的本地语言
     *
     *  @param key  本地语言对应的Key
     *
     */
    @objc public static func localized(key: String) -> String {
        return WYLocalizableManager.localized(key: key, table: WYBasisKitConfig.localizableTable)
    }
    
    /**
     *  根据传入的Key读取对应的本地语言
     *
     *  @param key  本地语言对应的Key
     *
     *  @param table  国际化语言读取表(如果有Bundle，则要求Bundle名与表名一致，否则会读取失败)
     *
     */
    @objc public static func localized(key: String, table: String = WYBasisKitConfig.localizableTable) -> String {
        return WYLocalizableManager.localized(key: key, table: table)
    }
}
