//
//  WYLocalizableManagerMacro.h
//  WYBasisKit
//
//  Created by guanren on 2025/10/5.
//

#ifndef WYLocalizableManagerMacro_h
#define WYLocalizableManagerMacro_h

#if __has_include("WYBasisKitSwift-Swift.h")
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
 *
 *  @param table  国际化语言读取表(如果有Bundle，则要求Bundle名与表名一致，否则会读取失败)
 *
 */
#define WYLocalizedFromTable(key, tableKey) \
    [WYLocalizableManager localizedWithKey:(key) table:(tableKey)]

#endif /* WYLocalizableManagerMacro_h */
