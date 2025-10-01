//
//  AppEventDelegate.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/1.
//

#import "AppEventDelegate.h"

// 事件枚举实现
AppEvent const AppEventButtonDidMove = @"button starts to move downwards";
AppEvent const AppEventButtonDidReturn = @"button starts to return to its original position";
AppEvent const AppEventDidShowBannerView = @"didShowBannerView";

// 常量实现
NSString *const kCityName = @"CityName";
NSString *const kCityCode = @"CityCode";

@implementation AppEventDelegate

@end
