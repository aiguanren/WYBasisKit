//
//  AppDelegate.m
//  ObjCVerify
//
//  Created by guanren on 2025/8/18.
//

#import "AppDelegate.h"
#import <WYBasisKitObjC-Swift.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    WYBasisKitConfig.defaultScreenPixels = [[WYScreenPixels alloc] initWithWidth:375 height:812];
    
    // 屏蔽控制台约束输出
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    
    return YES;
}

+ (AppDelegate *)shared {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

@end
