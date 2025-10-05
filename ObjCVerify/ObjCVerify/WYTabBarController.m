//
//  WYTabBarController.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/1.
//

#import "WYTabBarController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>
#import "WYMainController.h"
#import "WYCenterController.h"
#import "WYRightController.h"

@interface WYTabBarController ()

@end

@implementation WYTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor wy_dynamicWithLight:[UIColor whiteColor] dark:[UIColor blackColor]];
    [self layoutTabBar];
}

- (void)layoutTabBar {
    
    UIViewController *leftController = [[WYMainController alloc] init];
    leftController.view.backgroundColor = [UIColor wy_dynamicWithLight:[UIColor whiteColor] dark:[UIColor blackColor]];
    [self layoutTabbrItem:leftController title:@"左" defaultImage:[UIImage wy_find:@"tabbar_left_default"] selectedImage:[UIImage wy_find:@"tabbar_left_selected"]];
    
    UIViewController *centerController = [[WYCenterController alloc] init];
    centerController.view.backgroundColor = [UIColor wy_dynamicWithLight:[UIColor whiteColor] dark:[UIColor blackColor]];
    [self layoutTabbrItem:centerController title:@"中" defaultImage:[UIImage wy_find:@"tabbar_center_default"] selectedImage:[UIImage wy_find:@"tabbar_center_selected"]];
    
    UIViewController *rightController = [[WYRightController alloc] init];
    rightController.view.backgroundColor = [UIColor wy_dynamicWithLight:[UIColor whiteColor] dark:[UIColor blackColor]];
    [self layoutTabbrItem:rightController title:@"右" defaultImage:[UIImage wy_find:@"tabbar_right_default"] selectedImage:[UIImage wy_find:@"tabbar_right_selected"]];
}

- (void)layoutTabbrItem:(UIViewController *)controller title:(NSString *)title defaultImage:(UIImage *)defaultImage selectedImage:(UIImage *)selectedImage {
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    [self layoutNavigationBar:nav];
    
    nav.tabBarItem.title = title;
    nav.tabBarItem.image = defaultImage;
    nav.tabBarItem.selectedImage = selectedImage;
    [self addChildViewController:nav];
    
    UIView *clearView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIDevice.wy_screenWidth, UIDevice.wy_tabBarHeight)];
    clearView.backgroundColor = [UIColor wy_dynamicWithLight:[UIColor whiteColor] dark:[UIColor blackColor]];
    [self.tabBar insertSubview:clearView atIndex:0];
}

- (void)layoutNavigationBar:(UINavigationController *)nav {
    
    UINavigationController.wy_navBarBackgroundColor = [UIColor wy_dynamicWithLight:[UIColor wy_hex:@"#2AACFF"] dark:[UIColor wy_hex:@"#2A7DFF"]];
    
    UINavigationController.wy_navBarTitleColor = [UIColor wy_dynamicWithLight:[UIColor blackColor] dark:[UIColor whiteColor]];
    
    UINavigationController.wy_navBarTitleFont = [UIFont boldSystemFontOfSize:18];
   
    UINavigationController.wy_navBarReturnButtonImage = [UIImage wy_find:@"back"];
    
    UINavigationController.wy_navBarReturnButtonColor = [UIColor wy_dynamicWithLight:[UIColor blackColor] dark:[UIColor whiteColor]];
    
    UINavigationController.wy_navBarReturnButtonTitle = @"";
    
    UINavigationController.wy_navBarShadowLineHidden = YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
