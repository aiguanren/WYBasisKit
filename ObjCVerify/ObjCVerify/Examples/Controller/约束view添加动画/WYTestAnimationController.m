//
//  WYTestAnimationController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/8.
//

#import "WYTestAnimationController.h"
#import <Masonry/Masonry.h>
#import "AppEventDelegate.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestAnimationController ()

@property (nonatomic, strong) UIButton *testButton;

@end

@implementation WYTestAnimationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"让约束支持动画" forState:UIControlStateNormal];
    button.titleLabel.numberOfLines = 0;
    [button wy_backgroundColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(100);
        make.size.mas_equalTo(CGSizeMake(100, 100));
    }];
    
    self.testButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.testButton.backgroundColor = [UIColor wy_random];
    [self.view addSubview:self.testButton];
    [self.testButton addTarget:self action:@selector(clickTestButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.testButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.size.equalTo(button);
    }];
}

- (void)clickButton:(UIButton *)sender {
    
    [WYEventHandler responseWithEvent:AppEventButtonDidMove data:@"按钮开始向下移动"];
    
    /// 约束控件实现动画的关键是在animate方法中调用父视图的layoutIfNeeded方法
    [UIView animateWithDuration:1 animations:^{
        [sender mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(sender.superview).offset(350);
        }];
        [sender.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        [WYEventHandler responseWithEvent:AppEventButtonDidReturn data:@"按钮开始归位"];
        [sender mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(sender.superview).offset(100);
        }];
    }];
}

- (void)clickTestButton:(UIButton *)sender {
    [self.testButton wy_temporarilyDisableForDuration:10];
    WYLog(@"clickTestButton");
}

- (void)dealloc {
    WYLog(@"WYTestAnimationController deinit");
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
