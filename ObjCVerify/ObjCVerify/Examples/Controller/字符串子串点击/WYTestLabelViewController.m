//
//  WYTestLabelViewController.m
//  ObjCVerify
//
//  Created by guanren on 2026/9/21.
//

#import "WYTestLabelViewController.h"
#import "WYTestLabelCell.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestLabelViewController () <UITableViewDelegate, UITableViewDataSource>

/// 点击效果颜色（按下时的背景色）
@property (nonatomic, strong, nullable) UIColor *clickEffectColor;

/// 长按效果颜色（长按时背景色，未设置时回退点击效果色）
@property (nonatomic, strong, nullable) UIColor *longPressEffectColor;

/// 文本自带背景色时按下高亮要不要盖住它，默认 true(为 false 时自带背景色的文本按下不显示高亮)
@property (nonatomic, assign) BOOL overlaysOriginalBackground;

/// 长按手势触发的最小时长（秒），默认 0.5 秒
@property (nonatomic, assign) NSTimeInterval longPressMinimumDuration;

/// 是否模仿 UIButton 的 TouchUpInside(按下并抬起在同一富文本上才触发)，默认 true，为 false 时按下命中立即触发
@property (nonatomic, assign) BOOL touchUpInside;

/// 字符文本的字体
@property (nonatomic, assign) BOOL useCustomFont;

/// 随机文本
@property (nonatomic, assign) BOOL randomText;

@property (nonatomic, strong, nullable) UITableView *tableView;

@end

@implementation WYTestLabelViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _overlaysOriginalBackground = YES;
    _longPressMinimumDuration = 0.5;
    _touchUpInside = YES;

    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:contentView];
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(UIDevice.wy_navViewHeight + 20);
        make.centerX.equalTo(self.view);
    }];

    UIButton *clickEffectColorView = [self createButtonWithTitle:@"点击效果颜色"
                                                         selector:@selector(selectedClickEffectColor)
                                                        superView:contentView
                                                         leftView:nil
                                                          topView:nil
                                                          isRight:NO
                                                           isLast:NO];

    UIButton *longPressEffectColorView = [self createButtonWithTitle:@"长按效果颜色"
                                                             selector:@selector(selectedLongPressEffectColor)
                                                            superView:contentView
                                                             leftView:clickEffectColorView
                                                              topView:nil
                                                              isRight:NO
                                                               isLast:NO];

    UIButton *longPressMinimumDurationView = [self createButtonWithTitle:@"长按手势触发\n的最小时长"
                                                                 selector:@selector(longPressMinimumDurationSectcted)
                                                                superView:contentView
                                                                 leftView:longPressEffectColorView
                                                                  topView:nil
                                                                  isRight:YES
                                                                   isLast:NO];

    UIButton *overlaysOriginalBackgroundView = [self createButtonWithTitle:@"(覆盖)自带\n背景色高亮"
                                                                   selector:@selector(overlaysOriginalBackground:)
                                                                  superView:contentView
                                                                   leftView:nil
                                                                    topView:longPressMinimumDurationView
                                                                    isRight:NO
                                                                     isLast:NO];
    [overlaysOriginalBackgroundView setTitle:@"(忽略)自带\n背景色高亮" forState:UIControlStateSelected];

    UIButton *useCustomFontView = [self createButtonWithTitle:@"未使用自定义字体"
                                                      selector:@selector(useCustomFont:)
                                                     superView:contentView
                                                      leftView:overlaysOriginalBackgroundView
                                                       topView:longPressMinimumDurationView
                                                       isRight:NO
                                                        isLast:NO];
    [useCustomFontView setTitle:@"已使用自定义字体" forState:UIControlStateSelected];

    UIButton *randomTextView = [self createButtonWithTitle:@"未使用随机文本"
                                                   selector:@selector(useRandomText:)
                                                  superView:contentView
                                                   leftView:useCustomFontView
                                                    topView:longPressMinimumDurationView
                                                    isRight:YES
                                                     isLast:NO];
    [randomTextView setTitle:@"已使用随机文本" forState:UIControlStateSelected];

    UIButton *touchUpInsideView = [self createButtonWithTitle:@"(已开启)\n抬起时触发"
                                                      selector:@selector(touchUpInsideToggle:)
                                                     superView:contentView
                                                      leftView:nil
                                                       topView:overlaysOriginalBackgroundView
                                                       isRight:NO
                                                        isLast:YES];
    [touchUpInsideView setTitle:@"(已关闭)\n抬起时触发" forState:UIControlStateSelected];

    self.tableView = [UITableView wy_sharedWithStyle:UITableViewStylePlain separatorStyle:UITableViewCellSeparatorStyleNone delegate:self dataSource:self backgroundColor:[UIColor whiteColor] superView:self.view];
    [self.tableView wy_register:[WYTestLabelCell class] style:WYTableViewRegisterStyleCell];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView.mas_bottom).offset(20);
        make.left.right.bottom.equalTo(self.view);
    }];
}

- (UIButton *)createButtonWithTitle:(NSString *)title
                           selector:(SEL)selector
                          superView:(UIView *)superView
                           leftView:(UIView *)leftView
                            topView:(UIView *)topView
                             isRight:(BOOL)isRight
                              isLast:(BOOL)isLast {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.numberOfLines = 0;
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    [button setTitleColor:[UIColor wy_random] forState:UIControlStateNormal];
    [button wy_addBorder:UIRectEdgeAll color:[UIColor wy_random] thickness:1];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [superView addSubview:button];

    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        if (leftView) {
            make.left.equalTo(leftView.mas_right).offset(15);
        } else {
            make.left.equalTo(superView);
        }
        if (isRight) {
            make.right.equalTo(superView);
        }
        if (topView) {
            make.top.equalTo(topView.mas_bottom).offset(20);
        } else {
            make.top.equalTo(superView);
        }
        if (isLast) {
            make.bottom.equalTo(superView);
        }
        make.size.mas_equalTo(CGSizeMake(([UIScreen mainScreen].bounds.size.width - 60) / 3.0, 50));
    }];
    return button;
}

#pragma mark - Button Actions

- (void)selectedClickEffectColor {
    wy_weakify(self);
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"点击效果颜色" message:@"按下时的背景色" actions:@[@"透明", @"随机", @"跟随文本"] handler:^(NSString * _Nonnull action, NSArray<NSString *> * _Nonnull inputTexts) {
        wy_strongify(self);
        if (!self) { return; }
        if ([action isEqualToString:@"透明"]) {
            self.clickEffectColor = [UIColor clearColor];
        } else if ([action isEqualToString:@"随机"]) {
            self.clickEffectColor = [UIColor wy_random];
        } else {
            self.clickEffectColor = nil;
        }
        [self.tableView reloadData];
    }];
}

- (void)selectedLongPressEffectColor {
    wy_weakify(self);
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"长按效果颜色" message:@"长按时背景色，未设置时先回退点击效果色，再跟随文本色" actions:@[@"透明", @"随机", @"未设置"] handler:^(NSString * _Nonnull action, NSArray<NSString *> * _Nonnull inputTexts) {
        wy_strongify(self);
        if (!self) { return; }
        if ([action isEqualToString:@"透明"]) {
            self.longPressEffectColor = [UIColor clearColor];
        } else if ([action isEqualToString:@"随机"]) {
            self.longPressEffectColor = [UIColor wy_random];
        } else {
            self.longPressEffectColor = nil;
        }
        [self.tableView reloadData];
    }];
}

- (void)longPressMinimumDurationSectcted {
    wy_weakify(self);
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"长按手势触发的最小时长(秒)" message:nil duration:0 actionSheetNeedCancel:NO textFieldPlaceholders:@[[NSString stringWithFormat:@"当前%.2f秒", self.longPressMinimumDuration]] actions:@[@"确定", @"取消"] handler:^(NSString * _Nonnull action, NSArray<NSString *> * _Nonnull inputTexts) {
        wy_strongify(self);
        if (!self) { return; }
        if ([action isEqualToString:@"确定"]) {
            NSString *input = inputTexts.firstObject;
            self.longPressMinimumDuration = MAX(0.5, [input doubleValue]);
            [self.tableView reloadData];
        }
    }];
}

- (void)overlaysOriginalBackground:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.overlaysOriginalBackground = !sender.selected;
    [self.tableView reloadData];
}

- (void)useCustomFont:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.useCustomFont = sender.selected;
    [self.tableView reloadData];
}

- (void)useRandomText:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.randomText = sender.selected;
    [self.tableView reloadData];
}

- (void)touchUpInsideToggle:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.touchUpInside = !sender.selected;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WYTestLabelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WYTestLabelCell" forIndexPath:indexPath];
    [cell reloadWithClickEffectColor:self.clickEffectColor
              longPressEffectColor:self.longPressEffectColor
              overlaysOriginalBackground:self.overlaysOriginalBackground
              longPressMinimumDuration:self.longPressMinimumDuration
                          touchUpInside:self.touchUpInside
                         useCustomFont:self.useCustomFont
                            randomText:self.randomText];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)dealloc {
    wy_print(@"WYTestLabelViewController release");
}

@end
