//
//  WYTestTextViewController.m
//  ObjCVerify
//
//  Created by guanren on 2026/5/21.
//

#import "WYTestTextViewController.h"
#import "WYTestTextViewCell.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestTextViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, nullable) UIColor *clickEffectColor;
@property (nonatomic, strong, nullable) UIColor *longPressEffectColor;
@property (nonatomic, assign) BOOL overlaysOriginalBackground;
@property (nonatomic, assign) NSTimeInterval longPressMinimumDuration;
@property (nonatomic, assign) BOOL eventPenetration;
@property (nonatomic, assign) BOOL useCustomFont;
@property (nonatomic, assign) BOOL randomText;
@property (nonatomic, strong, nullable) UITableView *tableView;

@end

@implementation WYTestTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _longPressMinimumDuration = 0.5;
    _overlaysOriginalBackground = YES;
    
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
                                                                 selector:@selector(longPressMinimumDurationSelected)
                                                                superView:contentView
                                                                 leftView:longPressEffectColorView
                                                                  topView:nil
                                                                  isRight:YES
                                                                   isLast:NO];
    
    UIButton *eventPenetrationView = [self createButtonWithTitle:@"(已关闭)非链接\n区域事件穿透"
                                                         selector:@selector(eventPenetration:)
                                                        superView:contentView
                                                         leftView:nil
                                                          topView:longPressMinimumDurationView
                                                          isRight:NO
                                                           isLast:NO];
    [eventPenetrationView setTitle:@"(已开启)非链接\n区域事件穿透" forState:UIControlStateSelected];
    
    UIButton *useCustomFontView = [self createButtonWithTitle:@"未使用自定义字体"
                                                      selector:@selector(useCustomFont:)
                                                     superView:contentView
                                                      leftView:eventPenetrationView
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
                                                    isLast:YES];
    [randomTextView setTitle:@"已使用随机文本" forState:UIControlStateSelected];

    UIButton *overlaysOriginalBackgroundView = [self createButtonWithTitle:@"(覆盖)自带\n背景色高亮"
                                                                  selector:@selector(overlaysOriginalBackground:)
                                                                 superView:contentView
                                                                  leftView:nil
                                                                   topView:eventPenetrationView
                                                                   isRight:NO
                                                                    isLast:YES];
    [overlaysOriginalBackgroundView setTitle:@"(忽略)自带\n背景色高亮" forState:UIControlStateSelected];
    
    self.tableView = [UITableView wy_sharedWithStyle:UITableViewStylePlain separatorStyle:UITableViewCellSeparatorStyleNone delegate:self dataSource:self backgroundColor:[UIColor whiteColor] superView:self.view];
    [self.tableView wy_register:[WYTestTextViewCell class] style:WYTableViewRegisterStyleCell];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView.mas_bottom).offset(20);
        make.left.right.bottom.equalTo(self.view);
    }];

    // 点击空白处或任意文本收起键盘(不拦截不延迟触摸，交互词的点击/长按回调不受影响)
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tapGesture.cancelsTouchesInView = NO;
    tapGesture.delaysTouchesEnded = NO;
    [self.view addGestureRecognizer:tapGesture];

    // 滑动列表时收起键盘
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
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

- (void)longPressMinimumDurationSelected {
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

- (void)eventPenetration:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.eventPenetration = sender.selected;
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

- (void)overlaysOriginalBackground:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.overlaysOriginalBackground = !sender.selected;
    [self.tableView reloadData];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WYTestTextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WYTestTextViewCell" forIndexPath:indexPath];
    [cell reloadWithClickEffectColor:self.clickEffectColor
                 longPressEffectColor:self.longPressEffectColor
               overlaysOriginalBackground:self.overlaysOriginalBackground
            longPressMinimumDuration:self.longPressMinimumDuration
                    eventPenetration:self.eventPenetration
                       useCustomFont:self.useCustomFont
                          randomText:self.randomText];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    wy_print(@"点击了UITableView");
}

- (void)dealloc {
    wy_print(@"WYTestTextViewController release");
}

@end
