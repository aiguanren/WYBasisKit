//
//  WYTestScrollTextController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/13.
//

#import "WYTestScrollTextController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestScrollTextController () <WYScrollTextDelegate>

/// 滚动文本视图
@property (nonatomic, strong) WYScrollText *scrollText;

/// 测试按钮
@property (nonatomic, strong) UIButton *testButton;

/// 属性控制开关
@property (nonatomic, strong) UISwitch *placeholderSwitch;
@property (nonatomic, strong) UISwitch *textColorSwitch;
@property (nonatomic, strong) UISwitch *textFontSwitch;
@property (nonatomic, strong) UISwitch *intervalSwitch;
@property (nonatomic, strong) UISwitch *contentColorSwitch;

/// 测试数据数组
@property (nonatomic, strong) NSArray<NSString *> *testTexts;

@end

@implementation WYTestScrollTextController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 设置视图背景色
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 设置标题
    self.title = @"WYScrollText 测试";
    
    // 初始化测试数据
    self.testTexts = @[
        @"这是第一条滚动文本",
        @"这是第二条滚动文本，内容稍长一些",
        @"第三条文本",
        @"第四条文本，用于测试不同的文本长度",
        @"第五条文本"
    ];
    
    // 初始化UI
    [self setupUI];
    
    // 配置滚动文本
    [self configureScrollText];
}

// MARK: - UI设置

/// 初始化UI
- (void)setupUI {
    // 创建滚动文本视图
    self.scrollText = [[WYScrollText alloc] init];
    [self.view addSubview:self.scrollText];
    
    // 创建测试按钮
    self.testButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.testButton setTitle:@"更改文本数组" forState:UIControlStateNormal];
    [self.testButton addTarget:self action:@selector(changeTextArray) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.testButton];
    
    // 创建属性控制开关和标签
    [self createControlSwitches];
    
    // 设置约束
    [self setupConstraints];
}

/// 创建属性控制开关
- (void)createControlSwitches {
    // 占位文本开关
    UILabel *placeholderLabel = [self createLabelWithText:@"显示占位文本:"];
    self.placeholderSwitch = [self createSwitchWithAction:@selector(togglePlaceholder:)];
    
    // 文本颜色开关
    UILabel *textColorLabel = [self createLabelWithText:@"切换文本颜色:"];
    self.textColorSwitch = [self createSwitchWithAction:@selector(toggleTextColor:)];
    
    // 文本字体开关
    UILabel *textFontLabel = [self createLabelWithText:@"切换文本字体:"];
    self.textFontSwitch = [self createSwitchWithAction:@selector(toggleTextFont:)];
    
    // 轮播间隔开关
    UILabel *intervalLabel = [self createLabelWithText:@"切换轮播间隔:"];
    self.intervalSwitch = [self createSwitchWithAction:@selector(toggleInterval:)];
    
    // 背景色开关
    UILabel *contentColorLabel = [self createLabelWithText:@"切换背景颜色:"];
    self.contentColorSwitch = [self createSwitchWithAction:@selector(toggleContentColor:)];
    
    // 添加到视图
    NSArray *controls = @[
        @[placeholderLabel, self.placeholderSwitch],
        @[textColorLabel, self.textColorSwitch],
        @[textFontLabel, self.textFontSwitch],
        @[intervalLabel, self.intervalSwitch],
        @[contentColorLabel, self.contentColorSwitch]
    ];
    
    UIView *previousView = self.testButton;
    for (NSArray *controlPair in controls) {
        UILabel *label = controlPair[0];
        UISwitch *switchControl = controlPair[1];
        
        [self.view addSubview:label];
        [self.view addSubview:switchControl];
        
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view).offset(20);
            make.top.equalTo(previousView.mas_bottom).offset(20);
        }];
        
        [switchControl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.view).offset(-20);
            make.centerY.equalTo(label);
        }];
        
        previousView = label;
    }
}

/// 创建标签
- (UILabel *)createLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    return label;
}

/// 创建开关
- (UISwitch *)createSwitchWithAction:(SEL)action {
    UISwitch *switchControl = [[UISwitch alloc] init];
    [switchControl addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    return switchControl;
}

/// 设置约束
- (void)setupConstraints {
    [self.scrollText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.height.equalTo(@40);
    }];
    
    [self.testButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scrollText.mas_bottom).offset(30);
        make.centerX.equalTo(self.view);
    }];
}

// MARK: - 配置滚动文本

/// 配置滚动文本属性
- (void)configureScrollText {
    // 设置文本数组
    self.scrollText.textArray = self.testTexts;
    
    // 设置占位文本
    self.scrollText.placeholder = @"这是占位文本";
    
    // 设置文本颜色
    self.scrollText.textColor = [UIColor blackColor];
    
    // 设置文本字体
    self.scrollText.textFont = [UIFont systemFontOfSize:16];
    
    // 设置轮播间隔
    self.scrollText.interval = 3.0;
    
    // 设置背景色
    self.scrollText.contentColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3];
    
    // 设置代理
    self.scrollText.delegate = self;
    
    // 设置点击回调
    [self.scrollText didClick:^(NSInteger index) {
        NSLog(@"Block回调: 点击了第 %ld 项", (long)index);
    }];
}

// MARK: - 测试方法

/// 更改文本数组
- (void)changeTextArray {
    NSArray *newTexts = @[
        @"新的第一条文本",
        @"新的第二条文本，长度不同",
        @"第三条新文本",
        @"这是更新的第四条文本内容",
        @"最后一条文本"
    ];
    
    self.scrollText.textArray = newTexts;
    NSLog(@"文本数组已更改");
}

/// 切换占位文本显示
- (void)togglePlaceholder:(UISwitch *)sender {
    if (sender.isOn) {
        self.scrollText.placeholder = @"这是占位文本";
        // 设置为空数组以触发占位文本
        self.scrollText.textArray = @[];
    } else {
        // 恢复原始文本数组
        self.scrollText.textArray = self.testTexts;
    }
    NSLog(@"占位文本状态: %@", sender.isOn ? @"显示" : @"隐藏");
}

/// 切换文本颜色
- (void)toggleTextColor:(UISwitch *)sender {
    self.scrollText.textColor = sender.isOn ? [UIColor blueColor] : [UIColor blackColor];
    NSLog(@"文本颜色: %@", sender.isOn ? @"蓝色" : @"黑色");
}

/// 切换文本字体
- (void)toggleTextFont:(UISwitch *)sender {
    self.scrollText.textFont = sender.isOn ? [UIFont boldSystemFontOfSize:18] : [UIFont systemFontOfSize:16];
    NSLog(@"文本字体: %@", sender.isOn ? @"粗体18号" : @"常规16号");
}

/// 切换轮播间隔
- (void)toggleInterval:(UISwitch *)sender {
    self.scrollText.interval = sender.isOn ? 5.0 : 3.0;
    NSLog(@"轮播间隔: %@", sender.isOn ? @"5秒" : @"3秒");
}

/// 切换背景颜色
- (void)toggleContentColor:(UISwitch *)sender {
    self.scrollText.contentColor = sender.isOn ?
    [[UIColor yellowColor] colorWithAlphaComponent:0.2] :
    [[UIColor lightGrayColor] colorWithAlphaComponent:0.3];
    NSLog(@"背景颜色已%@", sender.isOn ? @"更改" : @"恢复");
}

// MARK: - WYScrollTextDelegate

- (void)wy_scrollTextItemDidClick:(WYScrollText *)scrollText itemIndex:(NSInteger)itemIndex {
    NSLog(@"代理方法: 点击了第 %ld 项", (long)itemIndex);
}

- (void)dealloc {
    NSLog(@"WYTestScrollTextController release");
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
