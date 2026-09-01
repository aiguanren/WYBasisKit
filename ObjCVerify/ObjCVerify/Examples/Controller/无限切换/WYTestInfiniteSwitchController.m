//
//  WYTestInfiniteSwitchController.m
//  ObjCVerify
//
//  Created by 官人 on 2026/9/1.
//

#import "WYTestInfiniteSwitchController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>
#import <IJKPlayerKit/IJKPlayerKit.h>

@interface WYTestInfiniteSwitchController () <WYContentScrollViewDelegate, WYMediaPlayerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

/// 无限滚动View
@property (nonatomic, strong) WYContentScrollView *contentScrollView;

/// 底部操作View
@property (nonatomic, strong) UIScrollView *operatioView;

/// 水平方向内容页视图数量（Int.max表示无限数量）
@property (nonatomic, strong) UISegmentedControl *numberOfHorizontalContent;

/// 垂直方向内容页视图数量（Int.max表示无限数量）
@property (nonatomic, strong) UISegmentedControl *numberOfVerticalContent;

/// 支持的滑动方向
@property (nonatomic, strong) UISegmentedControl *contentSlidingDirection;

/// 当contentSlidingDirection == omnidirectional时，优先支持哪个滑动方向，默认左右滑动
@property (nonatomic, strong) UISegmentedControl *prioritySlidingDirection;

/// 自动轮播时每一页停留时间
@property (nonatomic, strong) UISlider *standingTime;
@property (nonatomic, strong) UILabel *standingTimeValue;

/// 轻扫跨轴直切的速度阈值滑杆
@property (nonatomic, strong) UISlider *flickVelocityThreshold;
@property (nonatomic, strong) UILabel *flickVelocityValue;

/// 跨轴切换呈现样式选择器(瞬时/滑动/渐变/缩放)
@property (nonatomic, strong) UISegmentedControl *crossAxisSwitchStyleSegment;

/// 跨轴切换动画时长滑杆
@property (nonatomic, strong) UISlider *switchDuration;
@property (nonatomic, strong) UILabel *switchDurationValue;

/// 缩放切入比例滑杆
@property (nonatomic, strong) UISlider *zoomScale;
@property (nonatomic, strong) UILabel *zoomScaleValue;

/// 水平方向是否支持滑动
@property (nonatomic, strong) UISwitch *horizontalSliderEnabled;

/// 垂直方向是否支持滑动
@property (nonatomic, strong) UISwitch *verticalSliderEnabled;

/// 水平方向是否无限翻页
@property (nonatomic, strong) UISwitch *horizontalUnlimitedCarousel;

/// 垂直方向是否无限翻页
@property (nonatomic, strong) UISwitch *verticalUnlimitedCarousel;

/// 是否需要自动轮播，默认false(不自动轮播，业务想要自动轮播显式开启)
@property (nonatomic, strong) UISwitch *automaticCarousel;

/// 开启或者关闭定时器
@property (nonatomic, strong) UISwitch *startOrStopTimer;

/// 切换指定方向下一个内容页面
@property (nonatomic, strong) UIButton *nextContent;
@property (nonatomic, strong) UISegmentedControl *nextContentDirection;

/// 切换指定方向上一个内容页面
@property (nonatomic, strong) UIButton *lastContent;
@property (nonatomic, strong) UISegmentedControl *lastContentDirection;

/// 切换到指定方向指定下标处
@property (nonatomic, strong) UIButton *switchContent;
@property (nonatomic, strong) UISegmentedControl *switchContentDirection;
@property (nonatomic, strong) UIPickerView *switchContentPicker;
@property (nonatomic, assign) NSInteger switchContentIndex;

/// 水平方向Contents
@property (nonatomic, strong) NSMutableArray<UIView *> *horizontalViews;

/// 垂直方向Contents
@property (nonatomic, strong) NSMutableArray<UIView *> *verticalViews;

/// 水平方向各下标对应的图片
@property (nonatomic, strong) NSArray<UIImage *> *pageImages;

/// 垂直方向各下标对应的视频地址
@property (nonatomic, strong) NSArray<NSString *> *pageVideoList;

@end

@implementation WYTestInfiniteSwitchController

/// 按下标取水平方向图片：下标对数组长度取模(∞数量+无限轮播时reserveHorizontalIndex可能环绕成极大值，裸下标会越界闪退)
- (UIImage *)imageForHorizontalPageAtIndex:(NSInteger)index {
    return self.pageImages[index % self.pageImages.count];
}

/// 按下标取垂直方向视频地址：下标对数组长度取模(∞数量+无限轮播时reserveVerticalIndex可能环绕成极大值，裸下标会越界闪退)
- (NSString *)videoForVerticalPageAtIndex:(NSInteger)index {
    return self.pageVideoList[index % self.pageVideoList.count];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addSubView];
    [self configSubView];
}

- (void)configSubView {

    for (NSInteger i = 0; i <= 1; i++) {
        UIImageView *horizontal = [[UIImageView alloc] init];
        horizontal.contentMode = UIViewContentModeScaleAspectFill;
        horizontal.clipsToBounds = YES;
        horizontal.tag = 100 + i;
        [self.horizontalViews addObject:horizontal];

        WYMediaPlayer *vertical = [[WYMediaPlayer alloc] init];
        vertical.delegate = self;
        vertical.backgroundColor = UIColor.blackColor;
        vertical.shouldUseFirstFrameAsPoster = YES;
        vertical.tag = 200 + i;
        [self.verticalViews addObject:vertical];
    }

    self.contentScrollView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.contentScrollView.contentDelegate = self;

    self.operatioView.showsHorizontalScrollIndicator = NO;
    self.operatioView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

    self.numberOfHorizontalContent.selectedSegmentIndex = 6;
    [self segmentedControlChange:self.numberOfHorizontalContent];

    self.numberOfVerticalContent.selectedSegmentIndex = 6;
    [self segmentedControlChange:self.numberOfVerticalContent];

    self.contentSlidingDirection.selectedSegmentIndex = 0;
    [self segmentedControlChange:self.contentSlidingDirection];

    self.prioritySlidingDirection.selectedSegmentIndex = 0;
    [self segmentedControlChange:self.prioritySlidingDirection];

    for (UISegmentedControl *segmentedControl in @[self.numberOfHorizontalContent, self.numberOfVerticalContent, self.contentSlidingDirection, self.prioritySlidingDirection, self.nextContentDirection, self.lastContentDirection, self.switchContentDirection]) {
        [segmentedControl addTarget:self action:@selector(segmentedControlChange:) forControlEvents:UIControlEventValueChanged];
    }

    self.nextContentDirection.selectedSegmentIndex = 0;
    self.lastContentDirection.selectedSegmentIndex = 0;
    self.switchContentDirection.selectedSegmentIndex = 0;

    self.standingTime.value = 3;
    self.standingTime.minimumValue = 0;
    self.standingTime.maximumValue = 5;
    [self.standingTime addTarget:self action:@selector(standingTimeChanged:) forControlEvents:UIControlEventValueChanged];

    self.standingTimeValue.textColor = UIColor.blackColor;
    self.standingTimeValue.text = @"3.0";

    self.flickVelocityThreshold.value = 500;
    self.flickVelocityThreshold.minimumValue = 0;
    self.flickVelocityThreshold.maximumValue = 5000;
    [self.flickVelocityThreshold addTarget:self action:@selector(flickVelocityChanged:) forControlEvents:UIControlEventValueChanged];

    self.flickVelocityValue.textColor = UIColor.blackColor;
    self.flickVelocityValue.text = @"500";

    self.crossAxisSwitchStyleSegment.selectedSegmentIndex = 0;
    [self.crossAxisSwitchStyleSegment addTarget:self action:@selector(crossAxisSwitchStyleChanged:) forControlEvents:UIControlEventValueChanged];

    self.switchDuration.value = 0.25;
    self.switchDuration.minimumValue = 0;
    self.switchDuration.maximumValue = 3;
    [self.switchDuration addTarget:self action:@selector(switchDurationChanged:) forControlEvents:UIControlEventValueChanged];

    self.switchDurationValue.textColor = UIColor.blackColor;
    self.switchDurationValue.text = @"0.25";

    self.zoomScale.value = 1.15;
    self.zoomScale.minimumValue = 0.5;
    self.zoomScale.maximumValue = 3;
    [self.zoomScale addTarget:self action:@selector(zoomScaleChanged:) forControlEvents:UIControlEventValueChanged];

    self.zoomScaleValue.textColor = UIColor.blackColor;
    self.zoomScaleValue.text = @"1.15";

    self.horizontalSliderEnabled.on = YES;
    self.verticalSliderEnabled.on = YES;
    self.horizontalUnlimitedCarousel.on = YES;
    self.verticalUnlimitedCarousel.on = YES;
    // 与组件默认值一致(automaticCarousel默认false，不自动轮播；业务想要自动轮播显式开启，开启后组件会在首次展示时自动开表)
    self.automaticCarousel.on = NO;
    // automaticCarousel默认关闭，挂载时不会自动开表，开关显示off与实际计时器状态一致
    self.startOrStopTimer.on = NO;

    for (UISwitch *switchView in @[self.horizontalSliderEnabled, self.verticalSliderEnabled, self.horizontalUnlimitedCarousel, self.verticalUnlimitedCarousel, self.automaticCarousel, self.startOrStopTimer]) {
        [switchView addTarget:self action:@selector(switchSwitched:) forControlEvents:UIControlEventValueChanged];

        if (switchView != self.startOrStopTimer) {
            [self switchSwitched:switchView];
        }
    }

    for (UIButton *button in @[self.nextContent, self.lastContent, self.switchContent]) {
        [button setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    }

    self.switchContentPicker.delegate = self;
    self.switchContentPicker.dataSource = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 离开测试页停止所有播放器，避免视频在后台继续发声、耗流
    for (WYMediaPlayer *player in self.verticalViews) {
        if ([player isKindOfClass:[WYMediaPlayer class]]) {
            [player stopWithKeepLast:NO];
        }
    }
}

- (void)dealloc {
    // 页面销毁时释放播放器全部资源
    for (WYMediaPlayer *player in self.verticalViews) {
        if ([player isKindOfClass:[WYMediaPlayer class]]) {
            [player releaseAll];
        }
    }

    wy_print(@"WYTestInfiniteSwitchController deinit");
}

- (void)segmentedControlChange:(UISegmentedControl *)sender {
    NSArray<NSNumber *> *counts = @[@0, @1, @2, @3, @4, @5, @(INT_MAX)];
    if (sender == self.numberOfHorizontalContent) {
        self.contentScrollView.numberOfHorizontalContent = counts[sender.selectedSegmentIndex].integerValue;
    }else if (sender == self.numberOfVerticalContent) {
        self.contentScrollView.numberOfVerticalContent = counts[sender.selectedSegmentIndex].integerValue;
    }else if (sender == self.contentSlidingDirection) {
        // 切方向前先停两轴所有视频播放(对称通用)：单轴模式另一轴的视图不挂载(组件对应数组为空、did回调该轴参数为nil)，重挂载会把正在播的播放器从层级摘下且无人再能暂停它(画面不可见声音仍响)；切到含该轴的模式无碍，进入该轴页面的did会重新起播
        for (UIView *view in [self.horizontalViews arrayByAddingObjectsFromArray:self.verticalViews]) {
            if ([view isKindOfClass:[WYMediaPlayer class]]) {
                [(WYMediaPlayer *)view pause];
            }
        }
        WYContentSlidingDirection directions[] = {WYContentSlidingDirectionLeftOrRight, WYContentSlidingDirectionTopOrBottom, WYContentSlidingDirectionOmnidirectional};
        self.contentScrollView.contentSlidingDirection = directions[sender.selectedSegmentIndex];
        switch (self.contentScrollView.contentSlidingDirection) {
            case WYContentSlidingDirectionLeftOrRight:
                [self.contentScrollView horizontalOrVerticalDisplayWithCurrentView:self.horizontalViews.firstObject reserveView:self.horizontalViews.lastObject];
                break;
            case WYContentSlidingDirectionTopOrBottom:
                [self.contentScrollView horizontalOrVerticalDisplayWithCurrentView:self.verticalViews.firstObject reserveView:self.verticalViews.lastObject];
                break;
            case WYContentSlidingDirectionOmnidirectional:
                [self.contentScrollView omnidirectionalDisplayWithCurrentHorizontalView:self.horizontalViews.firstObject reserveHorizontalView:self.horizontalViews.lastObject currentVerticalView:self.verticalViews.firstObject reserveVerticalView:self.verticalViews.lastObject];
                break;
        }
    }else if (sender == self.prioritySlidingDirection) {
        WYContentSlidingDirection directions[] = {WYContentSlidingDirectionLeftOrRight, WYContentSlidingDirectionTopOrBottom, WYContentSlidingDirectionOmnidirectional};
        self.contentScrollView.prioritySlidingDirection = directions[sender.selectedSegmentIndex];
    }
}

/// 从方向选择器安全取值：未选中(selectedSegmentIndex为-1)或越界时返回默认的"左右"，避免数组越界闪退
- (WYContentSlidingDirection)selectedDirectionOf:(UISegmentedControl *)segmentedControl {
    if (segmentedControl.selectedSegmentIndex >= 0 && segmentedControl.selectedSegmentIndex <= 2) {
        WYContentSlidingDirection directions[] = {WYContentSlidingDirectionLeftOrRight, WYContentSlidingDirectionTopOrBottom, WYContentSlidingDirectionOmnidirectional};
        return directions[segmentedControl.selectedSegmentIndex];
    }
    return WYContentSlidingDirectionLeftOrRight;
}

- (void)buttonClick:(UIButton *)sender {
    if (sender == self.nextContent) {
        [self.contentScrollView nextContent:[self selectedDirectionOf:self.nextContentDirection]];
    }else if (sender == self.lastContent) {
        [self.contentScrollView lastContent:[self selectedDirectionOf:self.lastContentDirection]];
    }else if (sender == self.switchContent) {
        [self.contentScrollView switchContent:[self selectedDirectionOf:self.switchContentDirection] index:&_switchContentIndex];
    }
}

- (void)standingTimeChanged:(UISlider *)sender {
    self.standingTime.value = floor(sender.value);
    self.standingTimeValue.text = [NSString stringWithFormat:@"%.1f", self.standingTime.value];
    self.contentScrollView.standingTime = self.standingTime.value;
}

- (void)flickVelocityChanged:(UISlider *)sender {
    self.flickVelocityThreshold.value = floor(sender.value);
    self.flickVelocityValue.text = [NSString stringWithFormat:@"%.0f", self.flickVelocityThreshold.value];
    self.contentScrollView.crossAxisFlickVelocityThreshold = self.flickVelocityThreshold.value;
}

- (void)crossAxisSwitchStyleChanged:(UISegmentedControl *)sender {
    self.contentScrollView.crossAxisSwitchStyle = (WYContentSwitchStyle)sender.selectedSegmentIndex;
}

- (void)switchDurationChanged:(UISlider *)sender {
    self.contentScrollView.crossAxisSwitchDuration = sender.value;
    // 标签显示钳制后的实际值：滑到0.1以下/2.0以上可直观看到被组件钳到边界
    self.switchDurationValue.text = [NSString stringWithFormat:@"%.2f", self.contentScrollView.crossAxisSwitchDuration];
}

- (void)zoomScaleChanged:(UISlider *)sender {
    self.contentScrollView.crossAxisSwitchZoomScale = sender.value;
    // 标签显示钳制后的实际值：滑到1.0以下/2.0以上可直观看到被组件钳到边界
    self.zoomScaleValue.text = [NSString stringWithFormat:@"%.2f", self.contentScrollView.crossAxisSwitchZoomScale];
}

- (void)switchSwitched:(UISwitch *)sender {
    if (sender == self.horizontalSliderEnabled) {
        self.contentScrollView.horizontalSliderEnabled = sender.on;
    }else if (sender == self.verticalSliderEnabled) {
        self.contentScrollView.verticalSliderEnabled = sender.on;
    }else if (sender == self.horizontalUnlimitedCarousel) {
        self.contentScrollView.horizontalUnlimitedCarousel = sender.on;
    }else if (sender == self.verticalUnlimitedCarousel) {
        self.contentScrollView.verticalUnlimitedCarousel = sender.on;
    }else if (sender == self.automaticCarousel) {
        self.contentScrollView.automaticCarousel = sender.on;
    }else if (sender == self.startOrStopTimer) {
        if (sender.on) {
            [self.contentScrollView startTimer];
        }else {
            [self.contentScrollView stopTimer];
        }
    }
}

- (void)addSubView {
    [self.view addSubview:self.contentScrollView];
    [self.contentScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(UIDevice.wy_navViewHeight);
    }];

    [self.view addSubview:self.operatioView];
    [self.operatioView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.contentScrollView.mas_bottom);
        make.height.mas_equalTo((UIDevice.wy_screenHeight - UIDevice.wy_navViewHeight - UIDevice.wy_tabbarSafetyZone) / 2);
        make.bottom.equalTo(self.view).offset(UIDevice.wy_tabbarSafetyZone);
    }];

    UIView *numberOfHorizontalContentView = [self createDescContentViewWithDesc:@"水平方向内容页视图数量（∞：表示无限数量(Int.Max)）" controView:self.numberOfHorizontalContent valueView:nil];
    [self.operatioView addSubview:numberOfHorizontalContentView];
    [numberOfHorizontalContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(UIDevice.wy_screenWidth - 20);
        make.top.equalTo(self.operatioView).offset(10);
        make.centerX.equalTo(self.operatioView);
    }];

    UIView *numberOfVerticalContentView = [self createDescContentViewWithDesc:@"垂直方向内容页视图数量（∞：表示无限数量(Int.Max)）" controView:self.numberOfVerticalContent valueView:nil];
    [self.operatioView addSubview:numberOfVerticalContentView];
    [numberOfVerticalContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(numberOfHorizontalContentView.mas_bottom).offset(35);
        make.width.centerX.equalTo(numberOfHorizontalContentView);
    }];

    UIView *contentSlidingDirectionView = [self createDescContentViewWithDesc:@"支持的滑动方向" controView:self.contentSlidingDirection valueView:nil];
    [self.operatioView addSubview:contentSlidingDirectionView];
    [contentSlidingDirectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(numberOfVerticalContentView.mas_bottom).offset(35);
        make.width.centerX.equalTo(numberOfVerticalContentView);
    }];

    UIView *prioritySlidingDirectionView = [self createDescContentViewWithDesc:@"当contentSlidingDirection == omnidirectional时，优先支持哪个滑动方向，默认左右滑动(不支持设置为omnidirectional)" controView:self.prioritySlidingDirection valueView:nil];
    [self.operatioView addSubview:prioritySlidingDirectionView];
    [prioritySlidingDirectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentSlidingDirectionView.mas_bottom).offset(35);
        make.width.centerX.equalTo(contentSlidingDirectionView);
    }];

    UIView *standingTimeView = [self createDescContentViewWithDesc:@"自动轮播时每一页停留时间，默认为3s，最少1s，当设置的值小于1s时，则为默认值，同时修改值后会立即生效" controView:self.standingTime valueView:self.standingTimeValue];
    [self.operatioView addSubview:standingTimeView];
    [standingTimeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prioritySlidingDirectionView.mas_bottom).offset(35);
        make.width.centerX.equalTo(prioritySlidingDirectionView);
    }];

    UIView *horizontalSliderEnabledView = [self createDescContentViewWithDesc:@"水平方向是否支持滑动(仅内容页数量大于1时生效，单页不可滑)，默认true" controView:self.horizontalSliderEnabled valueView:nil];
    [self.operatioView addSubview:horizontalSliderEnabledView];
    [horizontalSliderEnabledView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(standingTimeView.mas_bottom).offset(35);
        make.width.centerX.equalTo(standingTimeView);
    }];

    UIView *verticalSliderEnabledView = [self createDescContentViewWithDesc:@"垂直方向是否支持滑动(仅内容页数量大于1时生效，单页不可滑)，默认true" controView:self.verticalSliderEnabled valueView:nil];
    [self.operatioView addSubview:verticalSliderEnabledView];
    [verticalSliderEnabledView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(horizontalSliderEnabledView.mas_bottom).offset(35);
        make.width.centerX.equalTo(horizontalSliderEnabledView);
    }];

    UIView *horizontalUnlimitedCarouselView = [self createDescContentViewWithDesc:@"水平方向是否无限翻页(末页环绕回首页；轮播前提按展示轴读取本开关)" controView:self.horizontalUnlimitedCarousel valueView:nil];
    [self.operatioView addSubview:horizontalUnlimitedCarouselView];
    [horizontalUnlimitedCarouselView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(verticalSliderEnabledView.mas_bottom).offset(35);
        make.width.centerX.equalTo(verticalSliderEnabledView);
    }];

    UIView *verticalUnlimitedCarouselView = [self createDescContentViewWithDesc:@"垂直方向是否无限翻页(末页环绕回首页；轮播前提按展示轴读取本开关)" controView:self.verticalUnlimitedCarousel valueView:nil];
    [self.operatioView addSubview:verticalUnlimitedCarouselView];
    [verticalUnlimitedCarouselView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(horizontalUnlimitedCarouselView.mas_bottom).offset(35);
        make.width.centerX.equalTo(horizontalUnlimitedCarouselView);
    }];

    UIView *automaticCarouselView = [self createDescContentViewWithDesc:@"是否需要自动轮播，默认false，开启后首次展示自动开表，关闭或stopTimer后需显式startTimer恢复" controView:self.automaticCarousel valueView:nil];
    [self.operatioView addSubview:automaticCarouselView];
    [automaticCarouselView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(verticalUnlimitedCarouselView.mas_bottom).offset(35);
        make.width.centerX.equalTo(verticalUnlimitedCarouselView);
    }];

    UIView *startOrStopTimerView = [self createDescContentViewWithDesc:@"开启或者关闭定时器" controView:self.startOrStopTimer valueView:nil];
    [self.operatioView addSubview:startOrStopTimerView];
    [startOrStopTimerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(automaticCarouselView.mas_bottom).offset(35);
        make.width.centerX.equalTo(automaticCarouselView);
    }];

    UIView *flickVelocityView = [self createDescContentViewWithDesc:@"轻扫跨轴直切速度阈值(pt/s，默500，滑杆0~5000可测钳制：低于50/高于3000会被组件自动钳到边界，仅影响全向模式)" controView:self.flickVelocityThreshold valueView:self.flickVelocityValue];
    [self.operatioView addSubview:flickVelocityView];
    [flickVelocityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(startOrStopTimerView.mas_bottom).offset(35);
        make.width.centerX.equalTo(startOrStopTimerView);
    }];

    UIView *crossAxisSwitchStyleView = [self createDescContentViewWithDesc:@"跨轴切换呈现样式(默认瞬时；滑动=当前页滑出目标页滑入，渐变=目标页淡入覆盖，缩放=目标页缩放归位淡入；同样作用于跨轴轻扫直切，同轴切换不受影响)" controView:self.crossAxisSwitchStyleSegment valueView:nil];
    [self.operatioView addSubview:crossAxisSwitchStyleView];
    [crossAxisSwitchStyleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(flickVelocityView.mas_bottom).offset(35);
        make.width.centerX.equalTo(flickVelocityView);
    }];

    UIView *switchDurationView = [self createDescContentViewWithDesc:@"跨轴切换动画时长(秒，默认0.25，滑杆0~3可测钳制：低于0.1/高于2.0会被组件自动钳到边界，仅滑动/渐变/缩放生效)" controView:self.switchDuration valueView:self.switchDurationValue];
    [self.operatioView addSubview:switchDurationView];
    [switchDurationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(crossAxisSwitchStyleView.mas_bottom).offset(35);
        make.width.centerX.equalTo(crossAxisSwitchStyleView);
    }];

    UIView *zoomScaleView = [self createDescContentViewWithDesc:@"缩放切入的缩放比例(默认1.15，进入页从该值缩放归位、退场页放大至该值淡出，滑杆0.5~3可测钳制：低于1.0/高于2.0会被组件自动钳到边界，1.0时无缩放退化为渐变，仅缩放模式生效)" controView:self.zoomScale valueView:self.zoomScaleValue];
    [self.operatioView addSubview:zoomScaleView];
    [zoomScaleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(switchDurationView.mas_bottom).offset(35);
        make.width.centerX.equalTo(switchDurationView);
    }];

    UIView *nextContentView = [self createDescContentViewsWithDesc:@"切换指定方向下一个内容页面(不支持直接传入direction为omnidirectional)" controViews:@[self.nextContent, self.nextContentDirection]];
    [self.operatioView addSubview:nextContentView];
    [nextContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(zoomScaleView.mas_bottom).offset(35);
        make.width.centerX.equalTo(zoomScaleView);
    }];

    UIView *lastContentView = [self createDescContentViewsWithDesc:@"切换指定方向上一个内容页面(不支持直接传入direction为omnidirectional)" controViews:@[self.lastContent, self.lastContentDirection]];
    [self.operatioView addSubview:lastContentView];
    [lastContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nextContentView.mas_bottom).offset(35);
        make.width.centerX.equalTo(nextContentView);
    }];

    UIView *switchContentView = [self createDescContentViewsWithDesc:@"切换到指定方向指定下标处(不支持直接传入direction为omnidirectional)" controViews:@[self.switchContent, self.switchContentDirection, self.switchContentPicker]];
    [self.operatioView addSubview:switchContentView];
    [switchContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastContentView.mas_bottom).offset(35);
        make.width.centerX.equalTo(lastContentView);
        make.bottom.equalTo(self.operatioView).offset(-100);
    }];

    [switchContentView layoutIfNeeded];
    self.operatioView.contentSize = CGSizeMake(UIDevice.wy_screenWidth, CGRectGetMaxY(switchContentView.frame));
}

- (UIView *)createDescContentViewWithDesc:(NSString *)desc controView:(UIView *)controView valueView:(UIView *)valueView {

    UIView *contentView = [[UIView alloc] init];

    UILabel *descView = [self cerateDescView:desc superView:contentView];

    if (controView) {
        [contentView addSubview:controView];
        [controView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.bottom.equalTo(contentView);
            make.height.mas_equalTo(25);
            if ([controView isKindOfClass:[UISwitch class]]) {
                make.top.equalTo(descView.mas_bottom).offset(5);
                make.width.mas_equalTo(80);
            }else if ([controView isKindOfClass:[UILabel class]]) {
                make.centerY.equalTo(descView);
                make.width.equalTo(contentView).offset(-30);
            }else if (valueView) {
                make.top.equalTo(descView.mas_bottom).offset(5);
                make.width.equalTo(contentView).offset(-55);
            }else {
                make.top.equalTo(descView.mas_bottom).offset(5);
                make.width.equalTo(contentView);
            }
        }];
    }

    if (valueView) {
        [contentView addSubview:valueView];
        if (controView) {
            [valueView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(controView.mas_right).offset(10);
                make.centerY.equalTo(controView);
            }];
        }else {
            [descView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(contentView).offset(-55);
            }];
            [valueView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(descView.mas_right).offset(10);
                make.centerY.equalTo(descView);
            }];
        }
    }

    return contentView;
}

- (UIView *)createDescContentViewsWithDesc:(NSString *)desc controViews:(NSArray<UIView *> *)controViews {

    UIView *contentView = [[UIView alloc] init];

    UILabel *descView = [self cerateDescView:desc superView:contentView];

    UIView *contentlastView = nil;
    for (UIView *controView in controViews) {
        if ([controView isKindOfClass:[UIButton class]]) {
            [(UIButton *)controView setTitle:@"切换" forState:UIControlStateNormal];
        }
        [contentView addSubview:controView];
        [controView mas_makeConstraints:^(MASConstraintMaker *make) {
            if (contentlastView) {
                make.left.equalTo(contentlastView.mas_right).offset(10);
            }else {
                make.left.equalTo(contentView);
            }

            if ([controView isKindOfClass:[UISegmentedControl class]]) {
                make.width.mas_equalTo(UIDevice.wy_screenWidth - 20 - 160);
            }else if ([controView isKindOfClass:[UIPickerView class]]) {
                make.width.mas_equalTo(90);
                make.height.mas_equalTo(100);
                make.bottom.equalTo(contentView);
            }else {
                make.width.mas_equalTo(60);
            }
            if (![controViews containsObject:self.switchContentDirection]) {
                make.height.mas_equalTo(25);
                make.bottom.equalTo(contentView);
            }

            make.top.equalTo(descView.mas_bottom).offset(5);
        }];

        contentlastView = controView;
    }

    return contentView;
}

- (UILabel *)cerateDescView:(NSString *)desc superView:(UIView *)superView {

    UILabel *descView = [[UILabel alloc] init];
    descView.text = desc;
    descView.numberOfLines = 0;
    descView.textColor = UIColor.blackColor;
    descView.textAlignment = NSTextAlignmentLeft;
    [superView addSubview:descView];
    [descView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.width.right.equalTo(superView);
    }];

    return descView;
}

#pragma mark - 懒加载

- (WYContentScrollView *)contentScrollView {
    if (!_contentScrollView) {
        _contentScrollView = [[WYContentScrollView alloc] init];
    }
    return _contentScrollView;
}

- (UIScrollView *)operatioView {
    if (!_operatioView) {
        _operatioView = [[UIScrollView alloc] init];
    }
    return _operatioView;
}

- (UISegmentedControl *)numberOfHorizontalContent {
    if (!_numberOfHorizontalContent) {
        _numberOfHorizontalContent = [[UISegmentedControl alloc] initWithItems:@[@"0", @"1", @"2", @"3", @"4", @"5", @"∞"]];
    }
    return _numberOfHorizontalContent;
}

- (UISegmentedControl *)numberOfVerticalContent {
    if (!_numberOfVerticalContent) {
        _numberOfVerticalContent = [[UISegmentedControl alloc] initWithItems:@[@"0", @"1", @"2", @"3", @"4", @"5", @"∞"]];
    }
    return _numberOfVerticalContent;
}

- (UISegmentedControl *)contentSlidingDirection {
    if (!_contentSlidingDirection) {
        _contentSlidingDirection = [[UISegmentedControl alloc] initWithItems:@[@"左右", @"上下", @"全向"]];
    }
    return _contentSlidingDirection;
}

- (UISegmentedControl *)prioritySlidingDirection {
    if (!_prioritySlidingDirection) {
        _prioritySlidingDirection = [[UISegmentedControl alloc] initWithItems:@[@"左右", @"上下", @"全向"]];
    }
    return _prioritySlidingDirection;
}

- (UISlider *)standingTime {
    if (!_standingTime) {
        _standingTime = [[UISlider alloc] init];
    }
    return _standingTime;
}

- (UILabel *)standingTimeValue {
    if (!_standingTimeValue) {
        _standingTimeValue = [[UILabel alloc] init];
    }
    return _standingTimeValue;
}

- (UISlider *)flickVelocityThreshold {
    if (!_flickVelocityThreshold) {
        _flickVelocityThreshold = [[UISlider alloc] init];
    }
    return _flickVelocityThreshold;
}

- (UILabel *)flickVelocityValue {
    if (!_flickVelocityValue) {
        _flickVelocityValue = [[UILabel alloc] init];
    }
    return _flickVelocityValue;
}

- (UISegmentedControl *)crossAxisSwitchStyleSegment {
    if (!_crossAxisSwitchStyleSegment) {
        _crossAxisSwitchStyleSegment = [[UISegmentedControl alloc] initWithItems:@[@"瞬时", @"滑动", @"渐变", @"缩放"]];
    }
    return _crossAxisSwitchStyleSegment;
}

- (UISlider *)switchDuration {
    if (!_switchDuration) {
        _switchDuration = [[UISlider alloc] init];
    }
    return _switchDuration;
}

- (UILabel *)switchDurationValue {
    if (!_switchDurationValue) {
        _switchDurationValue = [[UILabel alloc] init];
    }
    return _switchDurationValue;
}

- (UISlider *)zoomScale {
    if (!_zoomScale) {
        _zoomScale = [[UISlider alloc] init];
    }
    return _zoomScale;
}

- (UILabel *)zoomScaleValue {
    if (!_zoomScaleValue) {
        _zoomScaleValue = [[UILabel alloc] init];
    }
    return _zoomScaleValue;
}

- (UISwitch *)horizontalSliderEnabled {
    if (!_horizontalSliderEnabled) {
        _horizontalSliderEnabled = [[UISwitch alloc] init];
    }
    return _horizontalSliderEnabled;
}

- (UISwitch *)verticalSliderEnabled {
    if (!_verticalSliderEnabled) {
        _verticalSliderEnabled = [[UISwitch alloc] init];
    }
    return _verticalSliderEnabled;
}

- (UISwitch *)horizontalUnlimitedCarousel {
    if (!_horizontalUnlimitedCarousel) {
        _horizontalUnlimitedCarousel = [[UISwitch alloc] init];
    }
    return _horizontalUnlimitedCarousel;
}

- (UISwitch *)verticalUnlimitedCarousel {
    if (!_verticalUnlimitedCarousel) {
        _verticalUnlimitedCarousel = [[UISwitch alloc] init];
    }
    return _verticalUnlimitedCarousel;
}

- (UISwitch *)automaticCarousel {
    if (!_automaticCarousel) {
        _automaticCarousel = [[UISwitch alloc] init];
    }
    return _automaticCarousel;
}

- (UISwitch *)startOrStopTimer {
    if (!_startOrStopTimer) {
        _startOrStopTimer = [[UISwitch alloc] init];
    }
    return _startOrStopTimer;
}

- (UIButton *)nextContent {
    if (!_nextContent) {
        _nextContent = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _nextContent;
}

- (UISegmentedControl *)nextContentDirection {
    if (!_nextContentDirection) {
        _nextContentDirection = [[UISegmentedControl alloc] initWithItems:@[@"左右", @"上下", @"全向"]];
    }
    return _nextContentDirection;
}

- (UIButton *)lastContent {
    if (!_lastContent) {
        _lastContent = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _lastContent;
}

- (UISegmentedControl *)lastContentDirection {
    if (!_lastContentDirection) {
        _lastContentDirection = [[UISegmentedControl alloc] initWithItems:@[@"左右", @"上下", @"全向"]];
    }
    return _lastContentDirection;
}

- (UIButton *)switchContent {
    if (!_switchContent) {
        _switchContent = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _switchContent;
}

- (UISegmentedControl *)switchContentDirection {
    if (!_switchContentDirection) {
        _switchContentDirection = [[UISegmentedControl alloc] initWithItems:@[@"左右", @"上下", @"全向"]];
    }
    return _switchContentDirection;
}

- (UIPickerView *)switchContentPicker {
    if (!_switchContentPicker) {
        _switchContentPicker = [[UIPickerView alloc] init];
    }
    return _switchContentPicker;
}

- (NSMutableArray<UIView *> *)horizontalViews {
    if (!_horizontalViews) {
        _horizontalViews = [NSMutableArray array];
    }
    return _horizontalViews;
}

- (NSMutableArray<UIView *> *)verticalViews {
    if (!_verticalViews) {
        _verticalViews = [NSMutableArray array];
    }
    return _verticalViews;
}

- (NSArray<UIImage *> *)pageImages {
    if (!_pageImages) {
        NSMutableArray *images = [NSMutableArray array];
        for (NSInteger i = 0; i < 10; i++) {
            [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"banner_%ld", i]]];
        }
        _pageImages = images;
    }
    return _pageImages;
}

- (NSArray<NSString *> *)pageVideoList {
    if (!_pageVideoList) {
        NSURL *localUrl = [NSURL fileURLWithPath:[NSBundle.mainBundle pathForResource:@"mpeg4_local" ofType:@"mp4"]];
        _pageVideoList = @[
            @"https://files.cochat.lenovo.com/download/dbb26a06-4604-3d2b-bb2c-6293989e63a7/55deb281e01b27194daf6da391fdfe83.mp4",
            @"http://www.w3school.com.cn/i/movie.mp4",
            localUrl.absoluteString,
            @"http://vjs.zencdn.net/v/oceans.mp4",
            @"https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
            @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8",
            @"https://live.metshop.top/douyu/9220456",
            @"https://live.metshop.top/huya/11342412",
            @"https://live.metshop.top/huya/11342421",
            @"https://live.metshop.top/douyu/1713615",
            @"https://live.metshop.top/douyu/9171887",
            @"https://live.metshop.top/douyu/9456028",
            @"https://live.metshop.top/huya/11352881",
            @"https://live.metshop.top/huya/11342390",
            @"https://live.metshop.top/huya/11352876",
        ];
    }
    return _pageVideoList;
}

#pragma mark - WYContentScrollViewDelegate

- (void)wy_contentScrollViewDidScroll:(WYContentScrollView *)contentScrollView offset:(CGPoint)offset direction:(WYSlidingDirection)direction currentView:(UIView *)currentView reserveView:(UIView *)reserveView index:(NSInteger)index {

}

- (void)wy_contentScrollViewDidClick:(WYContentScrollView *)contentScrollView direction:(WYSlidingDirection)direction currentView:(UIView *)currentView reserveView:(UIView *)reserveView index:(NSInteger)index {
    if (direction == WYSlidingDirectionUp || direction == WYSlidingDirectionDown) {
        if (![currentView isKindOfClass:[WYMediaPlayer class]]) { return; }
        WYMediaPlayer *mediaPlayer = (WYMediaPlayer *)currentView;
        BOOL isPlaying = mediaPlayer.ijkPlayer.isPlaying;
        if (isPlaying) {
            [mediaPlayer pause];
        }else {
            [mediaPlayer play];
        }
    }

    if (direction == WYSlidingDirectionLeft || direction == WYSlidingDirectionRight) {
    }
}

- (void)wy_contentScrollViewWillSwitch:(WYContentScrollView *)contentScrollView direction:(WYSlidingDirection)direction currentHorizontalView:(UIView *)currentHorizontalView reserveHorizontalView:(UIView *)reserveHorizontalView currentVerticalView:(UIView *)currentVerticalView reserveVerticalView:(UIView *)reserveVerticalView {

    if (direction == WYSlidingDirectionUp || direction == WYSlidingDirectionDown) {
        if (![reserveVerticalView isKindOfClass:[WYMediaPlayer class]]) { return; }
        WYMediaPlayer *reservePlayer = (WYMediaPlayer *)reserveVerticalView;

        // 地址已在预备页上则只按预备页处理(在播的暂停、缓冲中的照常缓冲)，否则换源加载；取值走取模方法防∞模式环绕下标越界
        NSString *playUrl = [self videoForVerticalPageAtIndex:contentScrollView.reserveVerticalIndex];
        if (reservePlayer.mediaUrl && [reservePlayer.mediaUrl isEqualToString:playUrl]) {
            [reservePlayer pause];
        }else {
            [reservePlayer prepareWithUrl:playUrl placeholder:nil];
        }
    }

    if (direction == WYSlidingDirectionLeft || direction == WYSlidingDirectionRight) {
        // 只预载目标轴图片，不在will暂停V轴播放：暂停放到didSwitch里做(完全切到H后才停)，与同轴翻页"滑动全程旧页持续播放、提交才切换"的手感一致；拖动取消回弹时组件会重申原轴didSwitch恢复播放
        if ([reserveHorizontalView isKindOfClass:[UIImageView class]]) {
            ((UIImageView *)reserveHorizontalView).image = [self imageForHorizontalPageAtIndex:contentScrollView.reserveHorizontalIndex];
        }
    }
}

- (void)wy_contentScrollViewDidSwitch:(WYContentScrollView *)contentScrollView direction:(WYSlidingDirection)direction currentHorizontalView:(UIView *)currentHorizontalView reserveHorizontalView:(UIView *)reserveHorizontalView currentVerticalView:(UIView *)currentVerticalView reserveVerticalView:(UIView *)reserveVerticalView {

    // 停垂直轴播放提无条件前置(不放在任何方向分支里)：切到H必须停V；切到V时当前页随分支马上重新play(幂等)，前置暂停无副作用；这一停一起播就是did的"停旧起新"骨架
    if ([currentVerticalView isKindOfClass:[WYMediaPlayer class]]) {
        [(WYMediaPlayer *)currentVerticalView pause];
    }
    if ([reserveVerticalView isKindOfClass:[WYMediaPlayer class]]) {
        [(WYMediaPlayer *)reserveVerticalView pause];
    }

    if (direction == WYSlidingDirectionUp || direction == WYSlidingDirectionDown) {
        if (![currentVerticalView isKindOfClass:[WYMediaPlayer class]]) { return; }
        WYMediaPlayer *currentPlayer = (WYMediaPlayer *)currentVerticalView;

        // 当前页必须按currentVerticalIndex加载(补发didSwitch时reserveVerticalIndex还是残留值，用它会串台)；取值走取模方法防∞模式环绕下标越界
        NSString *playUrl = [self videoForVerticalPageAtIndex:contentScrollView.currentVerticalIndex];
        if (currentPlayer.mediaUrl && [currentPlayer.mediaUrl isEqualToString:playUrl]) {
            [currentPlayer play];
        }else {
            [currentPlayer playWithUrl:playUrl placeholder:nil];
        }
    }

    if (direction == WYSlidingDirectionLeft || direction == WYSlidingDirectionRight) {
        // 取值走取模方法防∞模式环绕下标越界
        if ([currentHorizontalView isKindOfClass:[UIImageView class]]) {
            ((UIImageView *)currentHorizontalView).image = [self imageForHorizontalPageAtIndex:contentScrollView.currentHorizontalIndex];
        }
    }
}

#pragma mark - WYMediaPlayerDelegate

- (void)wy_mediaPlayerStateDidChanged:(WYMediaPlayer *)player state:(WYMediaPlayerState)state {
    if (state == WYMediaPlayerStateReady) {
        wy_print(@"可以播放了");
    }
    switch (state) {
        case WYMediaPlayerStateRendered:
        case WYMediaPlayerStateReady:
        case WYMediaPlayerStatePlaying:
        case WYMediaPlayerStateInterrupted:
        case WYMediaPlayerStatePlayable:
        case WYMediaPlayerStateEnded:
        case WYMediaPlayerStateUserExited:
        case WYMediaPlayerStateError:
        case WYMediaPlayerStatePlayUrlEmpty:
        case WYMediaPlayerStatePaused:
            [WYActivity dismissLoadingIn:player animate:NO];
            break;
        default:
            [WYActivity showLoadingIn:player];
            break;
    }
}

#pragma mark - UIPickerViewDelegate, UIPickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [@[@"0", @"1", @"2", @"3", @"4", @"5"] objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.switchContentIndex = row;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 6;
}

@end
