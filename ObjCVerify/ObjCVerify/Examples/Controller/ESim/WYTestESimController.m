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

/// 能力查询按钮
@property (strong, nonatomic) UIButton *capabilityButton;

@end

@implementation WYTestESimController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    [self setupViews];
}

/// 布局界面并挂按钮点击事件
- (void)setupViews {

    self.lpaTextField = [[UITextField alloc] init];
    self.installButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.qrCodeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.capabilityButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.qrCodeImageView = [[UIImageView alloc] init];
    self.lpaTextField.text = @"1$esim.test.example.com$1EXAMPLE1234567-1";
    self.lpaTextField.placeholder = @"LPA 串";
    self.lpaTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.lpaTextField.font = [UIFont systemFontOfSize:[UIFont wy_fontSize:14 pixels:WYBasisKitConfig.defaultScreenPixels]];
    self.lpaTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:self.lpaTextField];

    [self.installButton setTitle:@"请求打开安装入口" forState:UIControlStateNormal];
    [self.installButton addTarget:self action:@selector(installClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.installButton];

    [self.qrCodeButton setTitle:@"生成二维码" forState:UIControlStateNormal];
    [self.qrCodeButton addTarget:self action:@selector(qrCodeClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.qrCodeButton];

    [self.capabilityButton setTitle:@"查看 eSIM 能力" forState:UIControlStateNormal];
    [self.capabilityButton addTarget:self action:@selector(capabilityClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.capabilityButton];

    self.qrCodeImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.qrCodeImageView];

    [self.lpaTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([UIDevice wy_screenHeight:24 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.left.equalTo(self.view).offset([UIDevice wy_screenWidth:24 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.right.equalTo(self.view).offset(-[UIDevice wy_screenWidth:24 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.height.mas_equalTo([UIDevice wy_screenHeight:44 pixels:WYBasisKitConfig.defaultScreenPixels]);
    }];

    [self.capabilityButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.lpaTextField.mas_bottom).offset([UIDevice wy_screenHeight:16 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.centerX.equalTo(self.view);
    }];

    [self.installButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.capabilityButton.mas_bottom).offset([UIDevice wy_screenHeight:24 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.centerX.equalTo(self.view);
    }];

    [self.qrCodeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.installButton.mas_bottom).offset([UIDevice wy_screenHeight:24 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.centerX.equalTo(self.view);
    }];

    [self.qrCodeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.qrCodeButton.mas_bottom).offset([UIDevice wy_screenHeight:24 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.centerX.equalTo(self.view);
        make.width.height.mas_equalTo([UIDevice wy_screenWidth:240 pixels:WYBasisKitConfig.defaultScreenPixels]);
    }];
}

/// 请求打开 eSIM 安装入口
- (void)installClicked {

    __weak typeof(self) weakSelf = self;
    WYAppleServices.requestEsimInstallation(self.lpaTextField.text ?: @"", ^(WYEsimRequestResult result) {
        switch (result) {
            case WYEsimRequestResultInvalidLpa: [weakSelf showResult:@"LPA 格式不合法"]; break;
            case WYEsimRequestResultLinkUnavailable: [weakSelf showResult:@"系统版本没有 eSIM 通用链接入口，请使用二维码或运营商提供的方式"]; break;
            case WYEsimRequestResultRequestRejected: [weakSelf showResult:@"系统未接受 eSIM 安装链接，不能据此判断设备不支持"]; break;
            case WYEsimRequestResultRequestAccepted: [weakSelf showResult:@"系统已接受链接，请在系统设置中确认安装与激活结果"]; break;
        }
    });
}

/// 查询 eSIM 能力
- (void)capabilityClicked {
    WYEsimRegionSupport capability = WYAppleServices.esimCapability;
    NSString *hardware = capability == WYEsimRegionSupportUnknown ? @"无法确定" : capability == WYEsimRegionSupportUnsupported ? @"已确认不支持" : @"已确认支持";
    NSString *link = WYAppleServices.isEsimInstallationLinkAvailable ? @"系统版本提供入口" : @"系统版本没有入口";
    [self showResult:[NSString stringWithFormat:@"eSIM 硬件：%@\n大陆与境外运营商适用范围：无法确定\n链接入口：%@\n可在设置的蜂窝网络中检查添加 eSIM，并由运营商核对设备与套餐资格", hardware, link]];
}

/// 点击生成二维码，把 LPA 串编成二维码展示
- (void)qrCodeClicked {

    // 按显示尺寸乘屏幕缩放比生成，保证二维码清晰
    CGFloat side = [UIDevice wy_screenWidth:240 pixels:WYBasisKitConfig.defaultScreenPixels] * MAX(self.traitCollection.displayScale, 1);
    self.qrCodeImageView.image = WYAppleServices.qrCode(self.lpaTextField.text ?: @"", CGSizeMake(side, side));
    if (self.qrCodeImageView.image == nil) [self showResult:@"LPA 格式不合法或无法生成二维码"];
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
