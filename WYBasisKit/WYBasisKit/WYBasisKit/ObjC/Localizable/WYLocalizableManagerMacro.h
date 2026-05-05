//
//  WYLocalizableManagerMacro.h
//  WYBasisKit
//
//  Created by guanren on 2025/10/5.
//

#ifndef WYLocalizableManagerMacro_h
#define WYLocalizableManagerMacro_h

#if __has_include(<WYBasisKitSwift-Swift.h>)
#import <WYBasisKitSwift-Swift.h>
#elif __has_include("WYBasisKitSwift-Swift.h")
#import "WYBasisKitSwift-Swift.h"
#endif

/**
 *  根据传入的Key读取对应的本地语言
 *
 *  @param key  本地语言对应的Key
 *
 */
#define WYLocalized(key) \
    [WYLocalizableManager localizedWithKey:(key)]

/**
 *  根据传入的Key读取对应的本地语言
 *
 *  @param key  本地语言对应的Key
 *  @param tableKey  国际化语言读取表(如果有Bundle，则要求Bundle名与表名一致，否则会读取失败)
 *
 */
#define WYLocalizedFromTable(key, tableKey) \
    [WYLocalizableManager localizedWithKey:(key) table:(tableKey)]


/**
 *  根据传入的Key读取对应的本地语言
 *
 *  @param key      本地语言对应的Key
 *  @param tableKey 国际化语言读取表
 *  @param source   资源定位对象（⚠️ 必须传入实例对象，不能直接传入类方法调用，否则编译报错）
 *
 *  @note 正确用法示例：
 *        WYLocalizableSource *source = [WYLocalizableSource bundleForName:@"YourBundleName"];
 *        WYLocalizedFromTableAndSource(@"your_key", @"your_table", source);
 *
 *  @warning 请勿直接写成 WYLocalizedFromTableAndSource(@"key", @"table", [WYLocalizableSource bundleForName:@""])，此写法会导致编译错误。
 */
#define WYLocalizedFromTableAndSource(key, tableKey, source) \
    [WYLocalizableManager localizedWithKey:(key) table:(tableKey) source:(source)]


#endif /* WYLocalizableManagerMacro_h */
