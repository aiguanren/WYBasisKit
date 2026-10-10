//
//  SceneDelegate.m
//  ObjCVerify
//
//  Created by 官人 on 2026/10/2.
//

#import "SceneDelegate.h"
#import "AppDelegate.h"
#import <WYBasisKitObjC-Swift.h>

@implementation SceneDelegate

/// 场景建立时创建主窗口并加载Main.storyboard
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateInitialViewController];
    [self.window makeKeyAndVisible];
    
    // 同步给AppDelegate
    AppDelegate.shared.window = self.window;
}

/// 场景变的活跃了(依据当前语言切换深浅色主题，原AppDelegate的applicationDidBecomeActive场景化后不再回调故迁到这里)
- (void)sceneDidBecomeActive:(UIScene *)scene {
    [UIApplication.sharedApplication wy_switchAppDisplayBrightness:WYLocalizableManager.currentLanguage == WYLanguageEnglish ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight];
}

@end
