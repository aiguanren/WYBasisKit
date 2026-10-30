//
//  WYTestAppleServicesController.m
//  ObjCVerify
//
//  Created by guanren on 2026/10/30.
//

#import "WYTestAppleServicesController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestAppleServicesController ()

/// 内容滚动区(字段与按钮较多，小屏也放得下)
@property (strong, nonatomic) UIScrollView *scrollView;

/// 字段与按钮竖排容器
@property (strong, nonatomic) UIStackView *stackView;

/// 收件人邮箱输入框(默认填一段测试值，可换成真实邮箱)
@property (strong, nonatomic) UITextField *mailToField;

/// 邮件主题输入框
@property (strong, nonatomic) UITextField *mailSubjectField;

/// 邮件正文输入框
@property (strong, nonatomic) UITextField *mailBodyField;

/// 收件人手机号输入框(短信与电话共用)
@property (strong, nonatomic) UITextField *phoneField;

/// 短信内容输入框
@property (strong, nonatomic) UITextField *smsBodyField;

/// App Store 数字 id 输入框(默认填一段测试值，可换成真实 App 的 id)
@property (strong, nonatomic) UITextField *appIdField;

@end

@implementation WYTestAppleServicesController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    [self setupViews];
}

/// 布局界面并挂按钮点击事件
- (void)setupViews {

    self.stackView.axis = UILayoutConstraintAxisVertical;
    self.stackView.spacing = 16;
    [self.scrollView addSubview:self.stackView];
    [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView).offset(-32);
    }];

    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuide).offset(16);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuide).offset(-16);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
    }];

    [self configField:self.mailToField text:@"test@example.com" placeholder:@"收件人邮箱"];
    [self configField:self.mailSubjectField text:@"主题测试" placeholder:@"邮件主题"];
    [self configField:self.mailBodyField text:@"正文测试" placeholder:@"邮件正文"];
    [self configField:self.phoneField text:@"10086" placeholder:@"手机号(短信与电话共用)"];
    [self configField:self.smsBodyField text:@"短信内容测试" placeholder:@"短信内容"];
    [self configField:self.appIdField text:@"310633997" placeholder:@"App Store 数字 id"];

    [self addButtonWithTitle:@"发邮件" action:@selector(sendMailClicked)];
    [self addButtonWithTitle:@"发短信" action:@selector(sendSmsClicked)];
    [self addButtonWithTitle:@"打电话" action:@selector(callClicked)];
    [self addButtonWithTitle:@"跳App设置页" action:@selector(openSettingsClicked)];
    [self addButtonWithTitle:@"App Store 详情页" action:@selector(openAppStoreClicked)];
    [self addButtonWithTitle:@"去评分" action:@selector(writeReviewClicked)];
}

/// 配置一个圆角输入框并加入竖排容器
- (void)configField:(UITextField *)field text:(NSString *)text placeholder:(NSString *)placeholder {

    field.text = text;
    field.placeholder = placeholder;
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.font = [UIFont systemFontOfSize:14];
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.stackView addArrangedSubview:field];
    [field mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(44);
    }];
}

/// 造一个动作按钮并加入竖排容器
- (void)addButtonWithTitle:(NSString *)title action:(SEL)action {

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.stackView addArrangedSubview:button];
}

/// 点击发邮件
- (void)sendMailClicked {

    wy_weakify(self);
    [WYAppleServices sendMailTo:@[self.mailToField.text]
                          cc:@[]
                         bcc:@[]
                       subject:self.mailSubjectField.text
                          body:self.mailBodyField.text
                    completion:^(BOOL success) {
        wy_strongify(self);
        if (!self) return;
        if (!success) {
            [self showResult:@"唤起失败，设备可能没有可用邮件应用"];
        }
    }];
}

/// 点击发短信
- (void)sendSmsClicked {

    wy_weakify(self);
    [WYAppleServices sendSmsTo:@[self.phoneField.text]
                          body:self.smsBodyField.text
                    completion:^(BOOL success) {
        wy_strongify(self);
        if (!self) return;
        if (!success) {
            [self showResult:@"唤起失败，设备可能不支持发短信"];
        }
    }];
}

/// 点击打电话
- (void)callClicked {

    wy_weakify(self);
    WYAppleServices.call(self.phoneField.text, ^(BOOL success) {
        // 模拟器没有电话应用也会走这里
        wy_strongify(self);
        if (!self) return;
        if (!success) {
            [self showResult:@"唤起失败，设备可能不支持拨号"];
        }
    });
}

/// 点击跳系统设置里当前 App 的设置页
- (void)openSettingsClicked {

    wy_weakify(self);
    WYAppleServices.openAppSettings(^(BOOL success) {
        wy_strongify(self);
        if (!self) return;
        if (!success) {
            [self showResult:@"唤起失败，系统无法打开设置页"];
        }
    });
}

/// 点击打开 App Store 详情页
- (void)openAppStoreClicked {

    wy_weakify(self);
    WYAppleServices.openAppPage(self.appIdField.text, ^(BOOL success) {
        wy_strongify(self);
        if (!self) return;
        if (!success) {
            [self showResult:@"唤起失败，系统无法打开 App Store"];
        }
    });
}

/// 点击打开 App Store 评分页
- (void)writeReviewClicked {

    wy_weakify(self);
    WYAppleServices.writeReview(self.appIdField.text, ^(BOOL success) {
        wy_strongify(self);
        if (!self) return;
        if (!success) {
            [self showResult:@"唤起失败，系统无法打开 App Store"];
        }
    });
}

/// 弹出结果提示
- (void)showResult:(NSString *)message {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dealloc {
    WYLogManager.output(@"WYTestAppleServicesController release");
}

@end
