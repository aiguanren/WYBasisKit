//
//  AppEventDelegate.h
//  ObjCVerify
//
//  Created by guanren on 2025/10/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AppEventDelegate <NSObject>

- (void)didShowBannerViewWithData:(NSString *)data;

@end

// 事件枚举定义
typedef NSString * AppEvent NS_STRING_ENUM;

FOUNDATION_EXPORT AppEvent const AppEventButtonDidMove;
FOUNDATION_EXPORT AppEvent const AppEventButtonDidReturn;
FOUNDATION_EXPORT AppEvent const AppEventDidShowBannerView;

// 常量定义
FOUNDATION_EXPORT NSString *const kCityName;
FOUNDATION_EXPORT NSString *const kCityCode;

@interface AppEventDelegate : NSObject

@end

NS_ASSUME_NONNULL_END
