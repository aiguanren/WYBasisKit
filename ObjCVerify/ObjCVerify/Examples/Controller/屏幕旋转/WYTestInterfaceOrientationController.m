//
//  WYTestInterfaceOrientationController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/12.
//

#import "WYTestInterfaceOrientationController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestInterfaceOrientationController ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation WYTestInterfaceOrientationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.title = @"设置屏幕旋转方向";
    
    /*
     *  实现屏幕旋转步骤
     
     *  1.在AppDelegate中重写屏幕旋转代理方法，即：
     - (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
         return UIDevice.wy_currentInterfaceOrientation;
     }
     
     *  2.在需要旋转操作的时候，动态设置 UIDevice.wy_setInterfaceOrientation 属性为需要支持的旋转方向
     
     *  3.在旋转结束时，恢复 UIDevice.wy_interfaceOrientation 属性为默认方向(看具体需求，也可以不用恢复为默认方向)
     */
    
    self.label = [[UILabel alloc] init];
    self.label.textColor = [UIColor wy_dynamicWithLight:[UIColor blackColor] dark:[UIColor whiteColor]];
    self.label.backgroundColor = [UIColor purpleColor];
    self.label.font = [UIFont systemFontOfSize:15];
    self.label.text = [self sharedInterfaceOrientationString];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.numberOfLines = 0;
    [self.view addSubview:self.label];
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(layoutInterfaceOrientation)];
    self.label.userInteractionEnabled = YES;
    [self.label addGestureRecognizer:tap];
}

- (void)layoutInterfaceOrientation {
    
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:nil message:@"设置屏幕方向" actions:@[@"竖向", @"横向-左", @"横向-右", @"竖向-颠倒", @"横向", @"竖向 / 横向", @"竖向 / 横向 /  竖向-颠倒"] handler:^(NSString * _Nonnull actionStr, NSArray<NSString *> * _Nonnull textFieldTexts) {
            
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (![actionStr isEqualToString:self.label.text]) {
                
                if ([actionStr isEqualToString:@"竖向"]) {
                    UIDevice.wy_setInterfaceOrientation = UIInterfaceOrientationMaskPortrait;
                    
                } else if ([actionStr isEqualToString:@"横向-左"]) {
                    UIDevice.wy_setInterfaceOrientation = UIInterfaceOrientationMaskLandscapeLeft;
                    
                } else if ([actionStr isEqualToString:@"横向-右"]) {
                    UIDevice.wy_setInterfaceOrientation = UIInterfaceOrientationMaskLandscapeRight;
                    
                } else if ([actionStr isEqualToString:@"竖向-颠倒"]) {
                    UIDevice.wy_setInterfaceOrientation = UIInterfaceOrientationMaskPortraitUpsideDown;
                    
                } else if ([actionStr isEqualToString:@"横向"]) {
                    UIDevice.wy_setInterfaceOrientation = UIInterfaceOrientationMaskLandscape;
                    
                } else if ([actionStr isEqualToString:@"竖向 / 横向"]) {
                    UIDevice.wy_setInterfaceOrientation = UIInterfaceOrientationMaskAllButUpsideDown;
                    
                } else if ([actionStr isEqualToString:@"竖向 / 横向 /  竖向-颠倒"]) {
                    UIDevice.wy_setInterfaceOrientation = UIInterfaceOrientationMaskAll;
                }
                self.label.text = [self sharedInterfaceOrientationString];
            }
            [self performSelector:@selector(outputScreenOrientationInfo) withObject:nil afterDelay:0.5];
        });
    }];
}

- (void)outputScreenOrientationInfo {
    if ([UIDevice wy_verticalScreen]) {
        WYLog(@"当前是竖屏模式");
        WYLog(@"screenWidth = %f", UIDevice.wy_screenWidth);
    }
    
    if ([UIDevice wy_horizontalScreen]) {
        WYLog(@"当前是横屏模式");
        WYLog(@"screenWidth = %f", UIDevice.wy_screenWidth);
    }
}

- (NSString *)sharedInterfaceOrientationString {
    
    NSString *string = @"";
    UIInterfaceOrientationMask orientation = [UIDevice wy_setInterfaceOrientation];
    
    if (orientation == UIInterfaceOrientationMaskPortrait) {
        string = [NSString stringWithFormat:@"竖向\n%@", [self sharedScreenResolution]];
    } else if (orientation == UIInterfaceOrientationMaskLandscapeLeft) {
        string = [NSString stringWithFormat:@"横向-左\n%@", [self sharedScreenResolution]];
    } else if (orientation == UIInterfaceOrientationMaskLandscapeRight) {
        string = [NSString stringWithFormat:@"横向-右\n%@", [self sharedScreenResolution]];
    } else if (orientation == UIInterfaceOrientationMaskPortraitUpsideDown) {
        string = [NSString stringWithFormat:@"竖向-颠倒\n%@", [self sharedScreenResolution]];
    } else if (orientation == UIInterfaceOrientationMaskLandscape) {
        string = [NSString stringWithFormat:@"横向\n%@", [self sharedScreenResolution]];
    } else if (orientation == UIInterfaceOrientationMaskAllButUpsideDown) {
        string = [NSString stringWithFormat:@"竖向 / 横向\n%@", [self sharedScreenResolution]];
    } else if (orientation == UIInterfaceOrientationMaskAll) {
        string = [NSString stringWithFormat:@"竖向 / 横向 /  竖向-颠倒\n%@", [self sharedScreenResolution]];
    } else {
        string = [NSString stringWithFormat:@"未知\n%@", [self sharedScreenResolution]];
    }
    return string;
}

- (NSString *)sharedScreenResolution {
    
    UIScreen *screen = [UIScreen mainScreen];
    CGFloat scale = screen.scale;
    CGRect bounds = screen.bounds;
    CGFloat width = bounds.size.width * scale;
    CGFloat height = bounds.size.height * scale;
    
    return [NSString stringWithFormat:@"宽%.0f 高%.0f", width, height];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    UIDevice.wy_setInterfaceOrientation = UIInterfaceOrientationMaskPortrait;
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
