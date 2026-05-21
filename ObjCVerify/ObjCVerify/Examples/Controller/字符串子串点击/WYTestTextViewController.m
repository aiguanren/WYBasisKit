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

@property (nonatomic, strong, nullable) UIColor *wy_clickEffectColor;
@property (nonatomic, strong, nullable) UIColor *wy_longPressEffectColor;
@property (nonatomic, assign) NSTimeInterval wy_longPressMinimumDuration;
@property (nonatomic, assign) BOOL wy_eventPenetration;
@property (nonatomic, assign) BOOL useCustomFont;
@property (nonatomic, strong, nullable) UITableView *tableView;

@end

@implementation WYTestTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _wy_longPressMinimumDuration = 0.5;
    
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
                                                                 selector:@selector(longPressMinimumDuration)
                                                                superView:contentView
                                                                 leftView:longPressEffectColorView
                                                                  topView:nil
                                                                  isRight:YES
                                                                   isLast:NO];
    
    UIButton *eventPenetrationView = [self createButtonWithTitle:@"非链接区域\n(关闭)事件穿透"
                                                         selector:@selector(eventPenetration:)
                                                        superView:contentView
                                                         leftView:nil
                                                          topView:longPressMinimumDurationView
                                                          isRight:NO
                                                           isLast:NO];
    [eventPenetrationView setTitle:@"非链接区域\n(开启)事件穿透" forState:UIControlStateSelected];
    
    UIButton *useCustomFontView = [self createButtonWithTitle:@"不使用自定义字体"
                                                      selector:@selector(useCustomFont:)
                                                     superView:contentView
                                                      leftView:eventPenetrationView
                                                       topView:longPressMinimumDurationView
                                                       isRight:NO
                                                        isLast:YES];
    [useCustomFontView setTitle:@"使用自定义字体" forState:UIControlStateSelected];
    
    self.tableView = [UITableView wy_sharedWithStyle:UITableViewStylePlain separatorStyle:UITableViewCellSeparatorStyleNone delegate:self dataSource:self backgroundColor:[UIColor whiteColor] superView:self.view];
    [self.tableView wy_register:[WYTestTextViewCell class] style:WYTableViewRegisterStyleCell];
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
            self.wy_clickEffectColor = [UIColor clearColor];
        } else if ([action isEqualToString:@"随机"]) {
            self.wy_clickEffectColor = [UIColor wy_random];
        } else {
            self.wy_clickEffectColor = nil;
        }
        [self.tableView reloadData];
    }];
}

- (void)selectedLongPressEffectColor {
    wy_weakify(self);
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert
                                  title:@"长按效果颜色"
                                message:@"长按时背景色"
                                actions:@[@"透明", @"随机", @"跟随文本"]
                      handler:^(NSString *action, NSArray<NSString *> *inputTexts) {
        wy_strongify(self);
        if (!self) { return; }
        if ([action isEqualToString:@"透明"]) {
            self.wy_longPressEffectColor = [UIColor clearColor];
        } else if ([action isEqualToString:@"随机"]) {
            self.wy_longPressEffectColor = [UIColor wy_random];
        } else {
            self.wy_longPressEffectColor = nil;
        }
        [self.tableView reloadData];
    }];
}

- (void)longPressMinimumDuration {
    wy_weakify(self);
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"长按手势触发的最小时长(秒)" message:nil duration:0 actionSheetNeedCancel:NO textFieldPlaceholders:@[[NSString stringWithFormat:@"当前%.2f秒", self.wy_longPressMinimumDuration]] actions:@[@"确定", @"取消"] handler:^(NSString * _Nonnull action, NSArray<NSString *> * _Nonnull inputTexts) {
        wy_strongify(self);
        if (!self) { return; }
        if ([action isEqualToString:@"确定"]) {
            NSString *input = inputTexts.firstObject;
            self.wy_longPressMinimumDuration = [input doubleValue] ?: 0.5;
            [self.tableView reloadData];
        }
    }];
}

- (void)eventPenetration:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.wy_eventPenetration = sender.selected;
    [self.tableView reloadData];
}

- (void)useCustomFont:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.useCustomFont = sender.selected;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WYTestTextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WYTestTextViewCell" forIndexPath:indexPath];
    [cell reloadWithClickEffectColor:self.wy_clickEffectColor
                longPressEffectColor:self.wy_longPressEffectColor
            longPressMinimumDuration:self.wy_longPressMinimumDuration
                    eventPenetration:self.wy_eventPenetration
                       useCustomFont:self.useCustomFont];
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
