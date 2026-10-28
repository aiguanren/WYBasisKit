//
//  WYTestDanmakuController.m
//  ObjCVerify
//
//  Created by guanren on 2026/10/19.
//

#import "WYTestDanmakuController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>
@import AVFoundation;

/// 弹幕测试页(视频边下边播叠弹幕，演示播放时间注入驱动、暂停冻结、定位清屏与外观轨道配置)
@interface WYTestDanmakuController () <UITableViewDataSource, UITableViewDelegate>

/// 播放器
@property (strong, nonatomic) AVPlayer *player;

/// 播放器画面层
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

/// 播放区容器(画面层挂它上面)
@property (strong, nonatomic) UIView *playerContainer;

/// 弹幕视图(叠在视频上)
@property (strong, nonatomic) WYDanmakuView *danmakuView;

/// 自定义弹幕输入框
@property (strong, nonatomic) UITextField *inputTextField;

/// 播放进度滑块(拖动时联动弹幕定位清屏)
@property (strong, nonatomic) UISlider *progressSlider;

/// 播放时间标签
@property (strong, nonatomic) UILabel *timeLabel;

/// 播放暂停按钮
@property (strong, nonatomic) UIButton *playButton;

/// 弹幕操作列表
@property (strong, nonatomic) UITableView *tableView;

/// 播放进度监听
@property (strong, nonatomic) id timeObserver;

/// 自动弹幕定时器
@property (strong, nonatomic) NSTimer *autoDanmakuTimer;

/// 自动弹幕计数
@property (assign, nonatomic) NSInteger autoDanmakuIndex;

/// 拖动滑块时暂停注入的标记
@property (assign, nonatomic) BOOL isDraggingSlider;

@end

@implementation WYTestDanmakuController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"弹幕";
    [self setupPlayerUI];
    [self setupControlUI];
    [self setupActionList];
    [self setupPlayerClock];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.playerLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.playerContainer.bounds.size.height);
}

/// 搭建播放区(视频画面与弹幕叠加)
- (void)setupPlayerUI {
    self.playerContainer = [[UIView alloc] init];
    self.playerContainer.backgroundColor = UIColor.blackColor;
    [self.view addSubview:self.playerContainer];

    self.player = [[AVPlayer alloc] init];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.playerContainer.layer addSublayer:self.playerLayer];

    self.danmakuView = [[WYDanmakuView alloc] init];
    [self.view addSubview:self.danmakuView];

    __weak typeof(self) weakSelf = self;
    [self.playerContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.view.mas_safeAreaLayoutGuide).offset(8);
        make.left.and.right.equalTo(weakSelf.view);
        make.height.mas_equalTo(weakSelf.playerContainer.mas_width).multipliedBy(9.0 / 16.0);
    }];
    [self.danmakuView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf.playerContainer);
    }];
}

/// 搭建播放控制区(播放暂停、进度滑块、时间标签、弹幕输入框)
- (void)setupControlUI {
    self.playButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.playButton setTitle:@"播放" forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playButton];

    self.progressSlider = [[UISlider alloc] init];
    self.progressSlider.minimumValue = 0;
    self.progressSlider.maximumValue = 1;
    [self.progressSlider addTarget:self action:@selector(progressSliderChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.progressSlider];

    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.text = @"00:00 / 00:00";
    self.timeLabel.font = [UIFont systemFontOfSize:12];
    self.timeLabel.textColor = UIColor.darkGrayColor;
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.timeLabel];

    self.inputTextField = [[UITextField alloc] init];
    self.inputTextField.placeholder = @"输入弹幕内容点下方发送";
    self.inputTextField.font = [UIFont systemFontOfSize:13];
    self.inputTextField.textColor = UIColor.darkGrayColor;
    self.inputTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.inputTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:self.inputTextField];

    __weak typeof(self) weakSelf = self;
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.playerContainer.mas_bottom).offset(8);
        make.left.equalTo(weakSelf.view).offset(16);
        make.width.mas_equalTo(64);
    }];
    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(weakSelf.playButton);
        make.left.equalTo(weakSelf.playButton.mas_right).offset(12);
        make.right.equalTo(weakSelf.view).offset(-16);
    }];
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.progressSlider.mas_bottom).offset(4);
        make.left.and.right.equalTo(weakSelf.progressSlider);
    }];
    [self.inputTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.timeLabel.mas_bottom).offset(8);
        make.left.equalTo(weakSelf.view).offset(16);
        make.right.equalTo(weakSelf.view).offset(-16);
        make.height.mas_equalTo(32);
    }];
}

/// 搭建弹幕操作列表
- (void)setupActionList {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];
    __weak typeof(self) weakSelf = self;
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.inputTextField.mas_bottom).offset(8);
        make.left.and.right.and.bottom.equalTo(weakSelf.view);
    }];
}

/// 接播放器时钟(把播放时间注入弹幕，播放暂停冻结弹幕，拖进度定位清屏)
- (void)setupPlayerClock {
    NSURL *mediaURL = [NSURL URLWithString:@"https://file.digitaling.com/eImg/uvideos/2026/0202/1770014172754013.mp4"];
    [self.player replaceCurrentItemWithPlayerItem:[WYMediaCache.shared playerItemWithURL:mediaURL]];
    [self.player play];
    [self.playButton setTitle:@"暂停" forState:UIControlStateNormal];
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1, 600) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        __strong typeof(weakSelf) self = weakSelf;
        if (self == nil || self.isDraggingSlider) {
            return;
        }
        double seconds = CMTimeGetSeconds(time);
        [self.danmakuView playAtTime:seconds];
        double total = CMTimeGetSeconds(self.player.currentItem.duration);
        if (total > 0) {
            self.progressSlider.value = seconds / total;
            self.timeLabel.text = [NSString stringWithFormat:@"%@ / %@", [self.class timeText:seconds], [self.class timeText:total]];
        }
    }];
}

/// 动作清单(标题与点击行为)
- (NSArray<NSString *> *)actionTitles {
    return @[@"发滚动弹幕",
             @"发顶部弹幕",
             @"发底部弹幕",
             @"发彩色富文本弹幕",
             @"发送输入框内容",
             @"自动弹幕 开/关",
             @"轨道条数 0/3/6 切换",
             @"显示区域 1/4~全部循环",
             @"滚动时长 4/8/12秒循环",
             @"满轨策略 排队/丢弃切换",
             @"发带头像弹幕",
             @"弹幕背景 开/关",
             @"文字阴影 开/关",
             @"同轨间距 8/40循环",
             @"轨道间距 0/12循环",
             @"清屏"];
}

/// 发彩色富文本弹幕(演示富文本与描边外观)
- (void)sendColoredDanmaku {
    NSArray<UIColor *> *colors = @[UIColor.systemYellowColor, UIColor.systemRedColor, UIColor.systemTealColor, UIColor.systemPinkColor];
    UIColor *color = colors[arc4random_uniform((uint32_t)colors.count)];
    NSDictionary<NSAttributedStringKey, id> *attributes = @{NSFontAttributeName: self.danmakuView.configuration.font,
                                                            NSForegroundColorAttributeName: color,
                                                            NSStrokeColorAttributeName: self.danmakuView.configuration.textStrokeColor,
                                                            NSStrokeWidthAttributeName: @(self.danmakuView.configuration.textStrokeWidth)};
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:[self.class randomText:-1] attributes:attributes];
    [self.danmakuView sendAttributedText:attributedText type:WYDanmakuTypeScroll];
}

/// 发输入框内容(空内容忽略)
- (void)sendInputText {
    NSString *text = self.inputTextField.text;
    if (text.length <= 0) {
        return;
    }
    [self.danmakuView send:text type:WYDanmakuTypeScroll];
    self.inputTextField.text = nil;
    [self.inputTextField resignFirstResponder];
}

/// 自动弹幕开关切换
- (void)toggleAutoDanmaku {
    if (self.autoDanmakuTimer != nil) {
        [self stopAutoDanmaku];
    } else {
        [self startAutoDanmaku];
    }
}

/// 开自动弹幕(每 0.5 秒随机发一条)
- (void)startAutoDanmaku {
    if (self.autoDanmakuTimer != nil) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    self.autoDanmakuTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *timer) {
        __strong typeof(weakSelf) self = weakSelf;
        if (self == nil) {
            return;
        }
        NSArray<NSNumber *> *types = @[@(WYDanmakuTypeScroll), @(WYDanmakuTypeScroll), @(WYDanmakuTypeScroll), @(WYDanmakuTypeTop), @(WYDanmakuTypeBottom)];
        WYDanmakuType type = types[self.autoDanmakuIndex % types.count].integerValue;
        [self.danmakuView send:[self.class randomText:self.autoDanmakuIndex] type:type];
        self.autoDanmakuIndex += 1;
    }];
}

/// 停自动弹幕
- (void)stopAutoDanmaku {
    [self.autoDanmakuTimer invalidate];
    self.autoDanmakuTimer = nil;
}

/// 轨道条数 0(自适应)/3/6 循环切换
- (void)toggleTrackCount {
    NSInteger next;
    if (self.danmakuView.configuration.trackCount == 0) {
        next = 3;
    } else if (self.danmakuView.configuration.trackCount == 3) {
        next = 6;
    } else {
        next = 0;
    }
    self.danmakuView.configuration.trackCount = next;
}

/// 显示区域比例 1/4、1/2、3/4、全部循环切换
- (void)toggleDisplayArea {
    NSArray<NSNumber *> *ratios = @[@0.25, @0.5, @0.75, @1.0];
    CGFloat current = self.danmakuView.configuration.displayAreaRatio;
    NSUInteger currentIndex = [ratios indexOfObjectPassingTest:^BOOL(NSNumber *ratio, NSUInteger idx, BOOL *stop) {
        return fabs(ratio.doubleValue - current) < 0.01;
    }];
    if (currentIndex == NSNotFound) {
        currentIndex = 2;
    }
    self.danmakuView.configuration.displayAreaRatio = ratios[(currentIndex + 1) % ratios.count].doubleValue;
}

/// 滚动时长 4/8/12 秒循环切换
- (void)toggleScrollDuration {
    NSArray<NSNumber *> *durations = @[@4, @8, @12];
    NSTimeInterval current = self.danmakuView.configuration.scrollDuration;
    NSUInteger currentIndex = [durations indexOfObjectPassingTest:^BOOL(NSNumber *duration, NSUInteger idx, BOOL *stop) {
        return fabs(duration.doubleValue - current) < 0.01;
    }];
    if (currentIndex == NSNotFound) {
        currentIndex = 1;
    }
    self.danmakuView.configuration.scrollDuration = durations[(currentIndex + 1) % durations.count].doubleValue;
}

/// 满轨策略排队/丢弃切换
- (void)toggleOverflowPolicy {
    if (self.danmakuView.configuration.overflowPolicy == WYDanmakuOverflowPolicyQueue) {
        self.danmakuView.configuration.overflowPolicy = WYDanmakuOverflowPolicyDiscard;
    } else {
        self.danmakuView.configuration.overflowPolicy = WYDanmakuOverflowPolicyQueue;
    }
}

/// 发带头像弹幕(头像外观取弹幕配置)
- (void)sendAvatarDanmaku {
    [self.danmakuView send:[self.class randomText:-1] type:WYDanmakuTypeScroll avatar:[self.class avatarImage:arc4random_uniform(100)]];
}

/// 单条弹幕背景开/关(开时套半透明黑底加圆角加左右留白)
- (void)toggleItemBackground {
    if (self.danmakuView.configuration.itemBackgroundColor == nil) {
        self.danmakuView.configuration.itemBackgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
        self.danmakuView.configuration.itemBackgroundCornerRadius = 8;
        self.danmakuView.configuration.itemHorizontalPadding = 8;
        self.danmakuView.configuration.itemVerticalPadding = 4;
    } else {
        self.danmakuView.configuration.itemBackgroundColor = nil;
        self.danmakuView.configuration.itemBackgroundCornerRadius = 0;
        self.danmakuView.configuration.itemHorizontalPadding = 0;
        self.danmakuView.configuration.itemVerticalPadding = 0;
    }
}

/// 文字阴影开/关(开时套黑色柔边阴影增强浅色画面可读性)
- (void)toggleTextShadow {
    if (self.danmakuView.configuration.textShadowColor == nil) {
        self.danmakuView.configuration.textShadowColor = UIColor.blackColor;
        self.danmakuView.configuration.textShadowBlurRadius = 4;
        self.danmakuView.configuration.textShadowOffset = CGSizeMake(0, 1);
    } else {
        self.danmakuView.configuration.textShadowColor = nil;
        self.danmakuView.configuration.textShadowBlurRadius = 0;
        self.danmakuView.configuration.textShadowOffset = CGSizeZero;
    }
}

/// 同轨最小间距 8/40 循环
- (void)toggleItemSpacing {
    NSArray<NSNumber *> *spacings = @[@8, @40];
    CGFloat current = self.danmakuView.configuration.itemSpacing;
    NSUInteger currentIndex = [spacings indexOfObjectPassingTest:^BOOL(NSNumber *spacing, NSUInteger idx, BOOL *stop) {
        return fabs(spacing.doubleValue - current) < 0.01;
    }];
    if (currentIndex == NSNotFound) {
        currentIndex = 0;
    }
    self.danmakuView.configuration.itemSpacing = spacings[(currentIndex + 1) % spacings.count].doubleValue;
}

/// 轨道行间距 0/12 循环
- (void)toggleTrackSpacing {
    NSArray<NSNumber *> *spacings = @[@0, @12];
    CGFloat current = self.danmakuView.configuration.trackSpacing;
    NSUInteger currentIndex = [spacings indexOfObjectPassingTest:^BOOL(NSNumber *spacing, NSUInteger idx, BOOL *stop) {
        return fabs(spacing.doubleValue - current) < 0.01;
    }];
    if (currentIndex == NSNotFound) {
        currentIndex = 0;
    }
    self.danmakuView.configuration.trackSpacing = spacings[(currentIndex + 1) % spacings.count].doubleValue;
}

/// 播放暂停切换(暂停时弹幕随之冻结)
- (void)playButtonClicked {
    if (self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
        [self.player pause];
        [self.danmakuView pauseDanmaku];
        [self.playButton setTitle:@"播放" forState:UIControlStateNormal];
    } else {
        [self.player play];
        [self.playButton setTitle:@"暂停" forState:UIControlStateNormal];
    }
}

/// 拖动进度条定位(弹幕定位清屏，定位完成前不回写滑块位置)
- (void)progressSliderChanged {
    double total = CMTimeGetSeconds(self.player.currentItem.duration);
    if (!(total > 0)) {
        return;
    }
    self.isDraggingSlider = YES;
    double target = self.progressSlider.value * total;
    [self.danmakuView seekToTime:target];
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:CMTimeMakeWithSeconds(target, 600) completionHandler:^(BOOL finished) {
        weakSelf.isDraggingSlider = NO;
    }];
}

/// 随机弹幕文案(序号传 -1 取随机)
+ (NSString *)randomText:(NSInteger)index {
    NSArray<NSString *> *samples = @[@"前方高能", @"这段太好看了", @"弹幕测试走一波", @"官人的弹幕组件", @"轨道分配不重叠", @"暂停冻结定位清屏",
                                     @"滚动顶部底部三类型", @"边下边播叠弹幕", @"富文本带描边", @"排队策略满轨不丢"];
    NSInteger number = (index < 0) ? arc4random_uniform((uint32_t)samples.count) : index;
    return [NSString stringWithFormat:@"%@%ld", samples[number % samples.count], (long)(number % 97)];
}

/// 生成测试头像(色块底加一个字)
+ (UIImage *)avatarImage:(NSInteger)seed {
    NSArray<UIColor *> *colors = @[UIColor.systemRedColor, UIColor.systemBlueColor, UIColor.systemGreenColor, UIColor.systemOrangeColor, UIColor.systemPurpleColor];
    UIColor *color = colors[seed % colors.count];
    CGSize size = CGSizeMake(48, 48);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [color setFill];
        CGContextFillRect(context.CGContext, CGRectMake(0, 0, size.width, size.height));
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:20 weight:UIFontWeightMedium],
                                     NSForegroundColorAttributeName: UIColor.whiteColor};
        [@"弹" drawAtPoint:CGPointMake(12, 12) withAttributes:attributes];
    }];
}

/// 秒数转分秒文字
+ (NSString *)timeText:(double)seconds {
    int total = (int)seconds;
    return [NSString stringWithFormat:@"%02d:%02d", total / 60, total % 60];
}

- (void)dealloc {
    if (self.timeObserver != nil) {
        [self.player removeTimeObserver:self.timeObserver];
    }
    [self stopAutoDanmaku];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.actionTitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = self.actionTitles[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            [self.danmakuView send:[self.class randomText:-1] type:WYDanmakuTypeScroll];
            [self.danmakuView send:[self.class randomText:-1] type:WYDanmakuTypeScroll];
            break;
        case 1:
            [self.danmakuView send:[self.class randomText:-1] type:WYDanmakuTypeTop];
            break;
        case 2:
            [self.danmakuView send:[self.class randomText:-1] type:WYDanmakuTypeBottom];
            break;
        case 3:
            [self sendColoredDanmaku];
            break;
        case 4:
            [self sendInputText];
            break;
        case 5:
            [self toggleAutoDanmaku];
            break;
        case 6:
            [self toggleTrackCount];
            break;
        case 7:
            [self toggleDisplayArea];
            break;
        case 8:
            [self toggleScrollDuration];
            break;
        case 9:
            [self toggleOverflowPolicy];
            break;
        case 10:
            [self sendAvatarDanmaku];
            break;
        case 11:
            [self toggleItemBackground];
            break;
        case 12:
            [self toggleTextShadow];
            break;
        case 13:
            [self toggleItemSpacing];
            break;
        case 14:
            [self toggleTrackSpacing];
            break;
        default:
            [self.danmakuView clearDanmaku];
            break;
    }
}

@end
