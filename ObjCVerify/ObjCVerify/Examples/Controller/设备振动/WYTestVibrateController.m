//
//  WYTestVibrateController.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/17.
//

#import "WYTestVibrateController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestVibrateController ()

@property (nonatomic, strong) UITextField *repeatCountField;
@property (nonatomic, strong) UITextField *intervalField;
@property (nonatomic, strong) UIStackView *stackView;

@end

@implementation WYTestVibrateController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"震动测试";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self setupUI];
}

- (void)setupUI {
    
    // 输入区
    UIStackView *inputStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.repeatCountField, self.intervalField]];
    inputStack.axis = UILayoutConstraintAxisHorizontal;
    inputStack.spacing = 10;
    inputStack.distribution = UIStackViewDistributionFillEqually;
    inputStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:inputStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [inputStack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [inputStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [inputStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [inputStack.heightAnchor constraintEqualToConstant:44]
    ]];
    
    // 按钮区
    self.stackView.axis = UILayoutConstraintAxisVertical;
    self.stackView.spacing = 12;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.stackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.topAnchor constraintEqualToAnchor:inputStack.bottomAnchor constant:20],
        [self.stackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.stackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20]
    ]];
    
    // 震动类型列表
    NSArray *vibrationTypes = @[
        @{@"name": @"系统震动", @"style": @(WYVibrationStyleSystem)},
        @{@"name": @"轻", @"style": @(WYVibrationStyleLight)},
        @{@"name": @"中", @"style": @(WYVibrationStyleMedium)},
        @{@"name": @"重", @"style": @(WYVibrationStyleHeavy)},
        @{@"name": @"柔和", @"style": @(WYVibrationStyleSoft)},
        @{@"name": @"生硬", @"style": @(WYVibrationStyleRigid)},
        @{@"name": @"成功提示", @"style": @(WYVibrationStyleSuccess)},
        @{@"name": @"警告提示", @"style": @(WYVibrationStyleWarning)},
        @{@"name": @"错误提示", @"style": @(WYVibrationStyleError)}
    ];
    
    // 添加测试按钮
    for (NSDictionary *typeInfo in vibrationTypes) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:typeInfo[@"name"] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        button.backgroundColor = [UIColor systemBlueColor];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.layer.cornerRadius = 8;
        [button.heightAnchor constraintEqualToConstant:44].active = YES;
        
        WYVibrationStyle style = [typeInfo[@"style"] integerValue];
        button.tag = style;
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.stackView addArrangedSubview:button];
    }
}

- (void)buttonTapped:(UIButton *)sender {
    WYVibrationStyle style = sender.tag;
    [self testVibration:style];
}

- (void)testVibration:(WYVibrationStyle)style {
    // 解析用户输入
    NSInteger repeatCount = [self.repeatCountField.text integerValue] ?: 1;
    double interval = [self.intervalField.text doubleValue] ?: 0.3;
    [self.view endEditing:YES];
    
    if (repeatCount <= 1) {
        [UIDevice wy_vibrateWith:style];
    } else {
        [UIDevice wy_vibrateWith:style repeatCount:repeatCount interval:interval];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - Lazy Loading

- (UITextField *)repeatCountField {
    if (!_repeatCountField) {
        _repeatCountField = [[UITextField alloc] init];
        _repeatCountField.placeholder = @"重复次数 (默认1)";
        _repeatCountField.borderStyle = UITextBorderStyleRoundedRect;
        _repeatCountField.keyboardType = UIKeyboardTypeNumberPad;
    }
    return _repeatCountField;
}

- (UITextField *)intervalField {
    if (!_intervalField) {
        _intervalField = [[UITextField alloc] init];
        _intervalField.placeholder = @"间隔秒数 (默认0.3)";
        _intervalField.borderStyle = UITextBorderStyleRoundedRect;
        _intervalField.keyboardType = UIKeyboardTypeDecimalPad;
    }
    return _intervalField;
}

- (UIStackView *)stackView {
    if (!_stackView) {
        _stackView = [[UIStackView alloc] init];
    }
    return _stackView;
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
