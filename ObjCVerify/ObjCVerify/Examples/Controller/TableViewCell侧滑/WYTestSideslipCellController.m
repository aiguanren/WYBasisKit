//
//  WYTestSideslipCellController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/15.
//

#import "WYTestSideslipCellController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestSideslipCellController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<NSString *> *dataSource;

// 控制开关
@property (nonatomic, assign) BOOL enableLongPull;
@property (nonatomic, assign) WYSideslipGesturePriority currentGesturePriority;

@end

@implementation WYTestSideslipCellController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"侧滑功能验证";
    self.view.backgroundColor = UIColor.magentaColor;
    
    [self setupNavigationBar];
    [self setupTableView];
    [self setupData];
    
    // 启用自动关闭侧滑功能（只需要调用一次）
    [UITableView wy_enableAutoCloseSideslip];
}

- (void)setupNavigationBar {
    // 添加长拉功能开关
    UIBarButtonItem *longPullButton = [[UIBarButtonItem alloc] initWithTitle:self.enableLongPull ? @"长拉:开" : @"长拉:关"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(toggleLongPull)];
    
    // 添加手势优先级切换
    UIBarButtonItem *gesturePriorityButton = [[UIBarButtonItem alloc] initWithTitle:[self gesturePriorityTitle]
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(switchGesturePriority)];
    
    self.navigationItem.rightBarButtonItems = @[longPullButton, gesturePriorityButton];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(10, UIDevice.wy_navViewHeight, UIDevice.wy_screenWidth - 20, UIDevice.wy_screenHeight - UIDevice.wy_navViewHeight) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = UIColor.whiteColor;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self.view addSubview:self.tableView];
}

- (void)setupData {
    [self.dataSource removeAllObjects];
    for (NSInteger i = 1; i <= 20; i++) {
        [self.dataSource addObject:[NSString stringWithFormat:@"测试单元格 %ld", (long)i]];
    }
    [self.tableView reloadData];
}

- (NSMutableArray<NSString *> *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (WYSideslipGesturePriority)currentGesturePriority {
    return _currentGesturePriority ?: WYSideslipGesturePriorityAutoSelection;
}

- (void)toggleLongPull {
    self.enableLongPull = !self.enableLongPull;
    
    // 重新创建导航栏按钮数组
    [self setupNavigationBar];
    
    // 使用封装的方法重置所有cell状态
    [self.tableView wy_resetAllVisibleCellsSideslipState];
    [self.tableView reloadData];
    
    wy_print(@"长拉功能: %@", self.enableLongPull ? @"开启" : @"关闭");
}

- (void)switchGesturePriority {
    switch (self.currentGesturePriority) {
        case WYSideslipGesturePriorityAutoSelection:
            self.currentGesturePriority = WYSideslipGesturePrioritySideslipFirst;
            break;
        case WYSideslipGesturePrioritySideslipFirst:
            self.currentGesturePriority = WYSideslipGesturePriorityNavigationBackFirst;
            break;
        case WYSideslipGesturePriorityNavigationBackFirst:
            self.currentGesturePriority = WYSideslipGesturePriorityAutoSelection;
            break;
    }
    
    // 重新创建导航栏按钮数组
    [self setupNavigationBar];
    
    // 使用封装的方法重置所有cell状态
    [self.tableView wy_resetAllVisibleCellsSideslipState];
    [self.tableView reloadData];
    
    wy_print(@"手势优先级: %@", [self gesturePriorityTitle]);
}

- (NSString *)gesturePriorityTitle {
    switch (self.currentGesturePriority) {
        case WYSideslipGesturePriorityAutoSelection:
            return @"手势:自动";
        case WYSideslipGesturePrioritySideslipFirst:
            return @"手势:侧滑优先";
        case WYSideslipGesturePriorityNavigationBackFirst:
            return @"手势:返回优先";
        default:
            return @"手势:自动";
    }
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // 重置cell状态，防止重用问题
    [cell wy_resetSideslipState];
    
    // 配置侧滑功能
    NSString *direction = [self configureSideslipForCell:cell at:indexPath];
    
    // 显示功能状态
    NSString *longPullStatus = self.enableLongPull ? @"+长拉" : @"";
    NSString *gestureStatus = [self gestureStatusText];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@(%@%@%@)", self.dataSource[indexPath.row], direction, longPullStatus, gestureStatus];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor.magentaColor colorWithAlphaComponent:0.25];
    btn.frame = CGRectMake((tableView.wy_width - 100)/2, 0, 100, 50);
    [btn addTarget:self action:@selector(didClickCellButton) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:btn];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    wy_print(@"点击了第%ld个cell", (long)(indexPath.row + 1));
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 滑动tableView时关闭已侧滑的cell
    if ([scrollView isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)scrollView;
        [tableView wy_closeCurrentOpenedSideslipCellIfNeeded];
    }
}

- (NSString *)configureSideslipForCell:(UITableViewCell *)cell at:(NSIndexPath *)indexPath {
    // 启用侧滑功能
    [cell wy_enableSideslip];
    
    // 设置手势优先级
    cell.wy_gesturePriority = self.currentGesturePriority;
    
    NSString *direction = @"";
    
    CGFloat leftSideslipWidth = 0;
    CGFloat rightSideslipWidth = 0;
    
    // 设置侧滑方向（可以根据需要调整）
    if (indexPath.row % 3 == 0) {
        cell.wy_sideslipDirection = WYTableViewSideslipDirectionLeft;
        direction = @"左侧侧滑";
        leftSideslipWidth = 80;
    } else if (indexPath.row % 3 == 1) {
        cell.wy_sideslipDirection = WYTableViewSideslipDirectionRight;
        direction = @"右侧侧滑";
        rightSideslipWidth = 120;
    } else {
        cell.wy_sideslipDirection = WYTableViewSideslipDirectionBoth;
        direction = @"两侧侧滑";
        leftSideslipWidth = 80;
        rightSideslipWidth = 120;
    }
    
    // 设置侧滑区域宽度
    cell.wy_leftSideslipWidth = leftSideslipWidth;
    cell.wy_rightSideslipWidth = rightSideslipWidth;
    
    // 配置长拉功能
    [self configureLongPullForCell:cell at:indexPath];
    
    // 设置自定义侧滑视图
    [self setupCustomSideslipViewForCell:cell at:indexPath];
    
    [cell wy_sideslipEvent:^(enum WYSideslipEventHandler event, enum WYTableViewSideslipDirection direction) {
        wy_print(@"event = %ld, direction = %ld", (long)event, (long)direction);
    }];
    
    return direction;
}

- (void)configureLongPullForCell:(UITableViewCell *)cell at:(NSIndexPath *)indexPath {
    if (self.enableLongPull) {
        cell.wy_enableLongPullAction = YES;
        cell.wy_longPullThreshold = 1.5;
        cell.wy_longPullHapticFeedback = YES;
        
        __weak typeof(self) weakSelf = self;
        __weak typeof(cell) weakCell = cell;
        
        [cell wy_sideslipLongPullHandlerWithProgress:^(CGFloat progress, WYTableViewSideslipDirection direction) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong typeof(weakCell) strongCell = weakCell;
            if (!strongSelf || !strongCell) return;
            
            if (progress > 0) {
                // 通过tableView获取cell的当前indexPath
                NSIndexPath *currentIndexPath = [strongSelf.tableView indexPathForCell:strongCell];
                if (currentIndexPath) {
                    NSString *directionText = direction == WYTableViewSideslipDirectionLeft ? @"左侧" : @"右侧";
                    wy_print(@"第%ld行%@长拉进度: %.2f", (long)(currentIndexPath.row + 1), directionText, progress);
                }
            }
        } completion:^(WYTableViewSideslipDirection direction) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong typeof(weakCell) strongCell = weakCell;
            if (!strongSelf || !strongCell) return;
            
            // 通过tableView获取cell的当前indexPath（最可靠的方式）
            NSIndexPath *currentIndexPath = [strongSelf.tableView indexPathForCell:strongCell];
            if (!currentIndexPath) {
                wy_print(@"❌ 无法获取cell的当前索引");
                return;
            }
            
            NSString *directionText = direction == WYTableViewSideslipDirectionLeft ? @"左侧" : @"右侧";
            wy_print(@"🎉 第%ld行%@长拉完成，执行对应事件！", (long)(currentIndexPath.row + 1), directionText);
            
            // 长拉完成后删除对应cell
            [strongSelf deleteCellAtIndexPath:currentIndexPath direction:direction];
        }];
    } else {
        cell.wy_enableLongPullAction = NO;
    }
}

- (void)setupCustomSideslipViewForCell:(UITableViewCell *)cell at:(NSIndexPath *)indexPath {
    // 左侧滑视图配置
    UIButton *leftButton = [self createSideslipButtonWithTitle:@"(左)删除" color:UIColor.systemRedColor indexPath:indexPath isLeft:YES];
    [cell wy_setSideslipView:leftButton direction:WYTableViewSideslipDirectionLeft];
    
    // 右侧滑视图配置
    UIButton *rightButton = [self createSideslipButtonWithTitle:@"(右)删除" color:UIColor.systemBlueColor indexPath:indexPath isLeft:NO];
    [cell wy_setSideslipView:rightButton direction:WYTableViewSideslipDirectionRight];
}

- (UIButton *)createSideslipButtonWithTitle:(NSString *)title color:(UIColor *)color indexPath:(NSIndexPath *)indexPath isLeft:(BOOL)isLeft {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    button.backgroundColor = color;
    
    // 使用更复杂的tag编码来区分左右按钮和行索引
    NSInteger buttonTag = indexPath.row * 100 + (isLeft ? 1 : 2);
    button.tag = buttonTag;
    
    [button addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (NSString *)gestureStatusText {
    switch (self.currentGesturePriority) {
        case WYSideslipGesturePriorityAutoSelection:
            return @"";
        case WYSideslipGesturePrioritySideslipFirst:
            return @"+侧滑优先";
        case WYSideslipGesturePriorityNavigationBackFirst:
            return @"+返回优先";
        default:
            return @"";
    }
}

- (void)handleButtonTap:(UIButton *)sender {
    NSInteger buttonTag = sender.tag;
    NSInteger originalRowIndex = buttonTag / 100;
    BOOL isLeftButton = (buttonTag % 100) == 1;
    
    NSString *buttonType = isLeftButton ? @"左侧" : @"右侧";
    wy_print(@"点击了原始第 %ld 行的%@滑动区域按钮", (long)(originalRowIndex + 1), buttonType);
    
    // 通过按钮的superview找到对应的cell
    UITableViewCell *cell = [self findCellForButton:sender];
    if (cell) {
        // 通过tableView获取cell的当前indexPath（最可靠的方式）
        NSIndexPath *currentIndexPath = [self.tableView indexPathForCell:cell];
        if (currentIndexPath) {
            WYTableViewSideslipDirection direction = isLeftButton ? WYTableViewSideslipDirectionLeft : WYTableViewSideslipDirectionRight;
            [self deleteCellAtIndexPath:currentIndexPath direction:direction];
        } else {
            wy_print(@"❌ 无法找到按钮对应的cell当前索引");
        }
    }
}

// 通过按钮找到对应的cell
- (UITableViewCell *)findCellForButton:(UIButton *)button {
    UIView *view = button;
    while (view != nil) {
        if ([view isKindOfClass:[UITableViewCell class]]) {
            return (UITableViewCell *)view;
        }
        view = view.superview;
    }
    return nil;
}

- (void)deleteCellAtIndexPath:(NSIndexPath *)indexPath direction:(WYTableViewSideslipDirection)direction {
    if (indexPath.row >= self.dataSource.count) {
        wy_print(@"❌ 索引越界: %ld，数据源数量: %ld", (long)indexPath.row, (long)self.dataSource.count);
        return;
    }
    
    NSString *cellText = self.dataSource[indexPath.row];
    NSString *directionText = direction == WYTableViewSideslipDirectionLeft ? @"左侧" : @"右侧";
    
    wy_print(@"🗑️ 删除第%ld行 (%@): %@", (long)(indexPath.row + 1), directionText, cellText);
    
    // 先关闭侧滑
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [cell wy_closeSideslipWithAnimated:NO];
    }
    
    // 执行删除动画
    [self.tableView performBatchUpdates:^{
        [self.dataSource removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:^(BOOL finished) {
        wy_print(@"✅ 删除完成，剩余%ld个cell", (long)self.dataSource.count);
    }];
}

- (void)didClickCellButton {
    wy_print(@"didClickCellButton");
}

- (void)dealloc {
    wy_print(@"WYTestSideslipCellController release");
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
