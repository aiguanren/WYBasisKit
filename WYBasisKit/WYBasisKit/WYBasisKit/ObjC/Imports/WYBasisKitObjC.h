//
//  WYBasisKitObjC.h
//  WYBasisKit
//
//  Created by guanren on 2025/9/28.
//

#import <Foundation/Foundation.h>

#if __has_include(<WYBasisKitSwift/WYBasisKitSwift-Swift.h>)
@import WYBasisKitSwift;
#elif __has_include(<WYBasisKitSwift-Swift.h>)
#import "WYBasisKitSwift-Swift.h"
#endif

#if __has_include(<WYBasisKitObjC/WYBasisKitObjC-Swift.h>)
#import <WYBasisKitObjC/WYBasisKitObjC-Swift.h>
#elif __has_include(<WYBasisKitObjC-Swift.h>)
#import "WYBasisKitObjC-Swift.h"
#endif

#if __has_include(<WYSingletonMacro.h>)
#import "WYSingletonMacro.h"
#endif

#if __has_include(<WYWeakStrongMacros.h>)
#import "WYWeakStrongMacros.h"
#endif

#if __has_include(<WYLogManagerMacro.h>)
#import "WYLogManagerMacro.h"
#endif

#if __has_include(<WYLocalizableManagerMacro.h>)
#import "WYLocalizableManagerMacro.h"
#endif
