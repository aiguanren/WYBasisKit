//
//  WYTestESimController.m
//  ObjCVerify
//
//  Created by guanren on 2026/10/30.
//

#import "WYTestESimController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestESimController ()

/// LPA 串输入框(默认填一段测试值，可粘贴获取到的真实 LPA 串)
@property (strong, nonatomic) UITextField *lpaTextField;

/// 立即安装按钮
@property (strong, nonatomic) UIButton *installButton;

/// 生成二维码按钮
@property (strong, nonatomic) UIButton *qrCodeButton;

/// LPA 串二维码展示图
@property (strong, nonatomic) UIImageView *qrCodeImageView;

@end

@implementation WYTestESimController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    [self setupViews];
}

/// 布局界面并挂按钮点击事件
- (void)setupViews {

    self.lpaTextField.text = @"1$esim.test.example.com$1EXAMPLE1234567-1";
    self.lpaTextField.placeholder = @"LPA 串";
    self.lpaTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.lpaTextField.font = [UIFont systemFontOfSize:14];
    self.lpaTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:self.lpaTextField];

    [self.installButton setTitle:@"立即安装" forState:UIControlStateNormal];
    [self.installButton addTarget:self action:@selector(installClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.installButton];

    [self.qrCodeButton setTitle:@"生成二维码" forState:UIControlStateNormal];
    [self.qrCodeButton addTarget:self action:@selector(qrCodeClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.qrCodeButton];

    self.qrCodeImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.qrCodeImageView];

    [self.lpaTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuide).offset(24);
        make.left.equalTo(self.view).offset(24);
        make.right.equalTo(self.view).offset(-24);
        make.height.mas_equalTo(44);
    }];

    [self.installButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.lpaTextField.mas_bottom).offset(24);
        make.centerX.equalTo(self.view);
    }];

    [self.qrCodeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.installButton.mas_bottom).offset(24);
        make.centerX.equalTo(self.view);
    }];

    [self.qrCodeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.qrCodeButton.mas_bottom).offset(24);
        make.centerX.equalTo(self.view);
        make.width.height.mas_equalTo(240);
    }];
}

/// 点击立即安装，唤起系统 eSIM 安装页
- (void)installClicked {

    if (!WYAppleServices.isEsimSupported) {
        [self showResult:@"系统低于 iOS 17.4，没有系统 eSIM 安装页"];
        return;
    }

    if (@available(iOS 17.4, *)) {
        // 唤起失败由 WYAppleServices 自动弹自定义提示，这里不再重复弹
        WYAppleServices.install(self.lpaTextField.text, @"此设备无法安装 eSIM，请联系客服", ^(BOOL success) {
        });
    }
}

/// 点击生成二维码，把 LPA 串编成二维码展示
- (void)qrCodeClicked {

    // 按显示尺寸乘屏幕缩放比生成，保证二维码清晰
    CGFloat side = 240 * MAX(self.traitCollection.displayScale, 1);
    self.qrCodeImageView.image = WYAppleServices.qrCode(self.lpaTextField.text, CGSizeMake(side, side));
}

/// 弹出结果提示
- (void)showResult:(NSString *)message {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dealloc {
    WYLogManager.output(@"WYTestESimController release");
}

@end
