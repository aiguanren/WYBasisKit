//
//  WYTestLiveStreamingController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/12.
//

#import "WYTestLiveStreamingController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>
#import <AVKit/AVKit.h>
#import <FSPlayer/FSPlayer.h>

@interface WYTestLiveStreamingController () <WYMediaPlayerDelegate, AVPictureInPictureControllerDelegate>

// MARK: - 播放器
@property (nonatomic, strong) WYMediaPlayer *player;

// MARK: - 控制面板
@property (nonatomic, strong) UIView *controlPanel;
@property (nonatomic, strong) UIScrollView *panelScrollView;
@property (nonatomic, strong) UIButton *closePanelButton;

// MARK: - 播放控制滑块
@property (nonatomic, strong) UISlider *volumeSlider; // 音量
@property (nonatomic, strong) UISlider *rateSlider; // 倍速
@property (nonatomic, strong) UISlider *seekSlider; // 进度

// MARK: - 播放控制按钮
@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UIButton *scalingButton;
@property (nonatomic, strong) UIButton *rotateXButton;
@property (nonatomic, strong) UIButton *rotateYButton;
@property (nonatomic, strong) UIButton *rotateZButton;
@property (nonatomic, strong) UIButton *snapshotButton;
@property (nonatomic, strong) UIButton *mediaButton;
@property (nonatomic, strong) UIButton *subtitleButton;
@property (nonatomic, strong) UIButton *frameButton;
@property (nonatomic, strong) UIButton *audioDelayButton;
@property (nonatomic, strong) UIButton *subtitleDelayButton;
@property (nonatomic, strong) UIButton *colorButton;
@property (nonatomic, strong) UIButton *aspectButton;
@property (nonatomic, strong) UIButton *snapshotTypeButton;

// MARK: - 新增按钮
@property (nonatomic, strong) UIButton *pipButton;          // 画中画按钮
@property (nonatomic, strong) UIButton *fullScreenButton;   // 全屏/半屏按钮
@property (nonatomic, strong) UIButton *orientationButton;  // 横竖屏切换按钮

// MARK: - 信息显示
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UILabel *streamLabel;

// MARK: - 播放数据
@property (nonatomic, strong) NSArray<NSDictionary *> *mediaList;
@property (nonatomic, strong) NSArray<NSURL *> *subtitleList;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSTimer *updateTimer;

// 当前旋转偏好
@property (nonatomic, assign) FSRotatePreference rotatePreference;

// 当前色彩偏好
@property (nonatomic, assign) FSColorConvertPreference colorPreference;

// 当前画面比例
@property (nonatomic, assign) FSDARPreference aspectPreference;

// 当前快照类型
@property (nonatomic, assign) FSSnapshotType currentSnapshotType;

// 控制面板是否显示
@property (nonatomic, assign) BOOL isControlPanelVisible;

// 是否全屏模式
@property (nonatomic, assign) BOOL isFullScreen;

// 画中画控制器
@property (nonatomic, strong) AVPictureInPictureController *pipController;

@end

@implementation WYTestLiveStreamingController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blackColor];
        [self setupMediaList];
        [self setupPlayer];
        [self setupUI];
        [self setupNavigationBar];
        [self playCurrentMedia];
        [self startInfoUpdateTimer];
        [self setupPictureInPicture];
}

// 设置导航栏
- (void)setupNavigationBar {
    // 创建菜单按钮
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"slider.horizontal.3"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleControlPanel)];
    self.navigationItem.rightBarButtonItem = menuButton;
}

// 设置播放器
- (void)setupPlayer {
    self.player = [[WYMediaPlayer alloc] init];
    self.player.delegate = self;
    self.player.looping = 1;
    self.player.backgroundColor = [UIColor blackColor];
    [self.player scalingStyle:FSScalingModeAspectFit];
    self.player.layer.borderWidth = 2;
    self.player.layer.borderColor = [UIColor orangeColor].CGColor;
    [self.view addSubview:self.player];
    
    [self.player mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
}

// 设置画中画功能(待API支持)
- (void)setupPictureInPicture {
//    if (!self.player.ijkPlayer) { return; }
//    self.pipController = [[AVPictureInPictureController alloc] initWithPlayerLayer:self.player.ijkPlayer];
//    self.pipController.delegate = self;
}

// 设置UI控件
- (void)setupUI {
    // 设置控制面板
    self.controlPanel = [[UIView alloc] init];
    self.controlPanel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.controlPanel.layer.cornerRadius = 12;
    self.controlPanel.layer.maskedCorners = kCALayerMaxXMaxYCorner | kCALayerMinXMaxYCorner;
    self.controlPanel.clipsToBounds = YES;
    self.controlPanel.hidden = YES;
    [self.view addSubview:self.controlPanel];
    
    [self.controlPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
        make.height.equalTo(self.view).multipliedBy(0.7);
    }];
    
    // 设置关闭按钮
    self.closePanelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closePanelButton setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    self.closePanelButton.tintColor = [UIColor whiteColor];
    self.closePanelButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.closePanelButton.layer.cornerRadius = 15;
    [self.closePanelButton addTarget:self action:@selector(toggleControlPanel) forControlEvents:UIControlEventTouchUpInside];
    [self.controlPanel addSubview:self.closePanelButton];
    
    [self.closePanelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.controlPanel).offset(16);
        make.right.equalTo(self.controlPanel).offset(-16);
        make.width.height.equalTo(@30);
    }];
    
    // 设置滚动视图
    self.panelScrollView = [[UIScrollView alloc] init];
    self.panelScrollView.showsVerticalScrollIndicator = YES;
    self.panelScrollView.alwaysBounceVertical = YES;
    [self.controlPanel addSubview:self.panelScrollView];
    
    [self.panelScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.closePanelButton.mas_bottom).offset(10);
        make.left.right.bottom.equalTo(self.controlPanel);
    }];
    
    // 创建内容容器
    UIView *contentView = [[UIView alloc] init];
    [self.panelScrollView addSubview:contentView];
    
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.panelScrollView);
        make.width.equalTo(self.panelScrollView);
    }];
    
    // 设置按钮样式
    void (^buttonConfig)(UIButton *, NSString *, UIColor *) = ^(UIButton *button, NSString *title, UIColor *color) {
        [button setTitle:title forState:UIControlStateNormal];
        button.backgroundColor = color;
        button.layer.cornerRadius = 8;
        button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        [contentView addSubview:button];
    };
    
    // 播放/暂停按钮
    self.playPauseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.playPauseButton, @"暂停", [UIColor systemBlueColor]);
    [self.playPauseButton addTarget:self action:@selector(togglePlayPause) forControlEvents:UIControlEventTouchUpInside];
    
    // 停止按钮
    self.stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.stopButton, @"停止", [UIColor systemRedColor]);
    [self.stopButton addTarget:self action:@selector(stopPlaying) forControlEvents:UIControlEventTouchUpInside];
    
    // 缩放模式按钮
    self.scalingButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.scalingButton, @"缩放模式", [UIColor systemPurpleColor]);
    [self.scalingButton addTarget:self action:@selector(changeScaling) forControlEvents:UIControlEventTouchUpInside];
    
    // X轴旋转按钮
    self.rotateXButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.rotateXButton, @"X轴旋转", [UIColor systemOrangeColor]);
    [self.rotateXButton addTarget:self action:@selector(rotateX) forControlEvents:UIControlEventTouchUpInside];
    
    // Y轴旋转按钮
    self.rotateYButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.rotateYButton, @"Y轴旋转", [UIColor systemOrangeColor]);
    [self.rotateYButton addTarget:self action:@selector(rotateY) forControlEvents:UIControlEventTouchUpInside];
    
    // Z轴旋转按钮
    self.rotateZButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.rotateZButton, @"Z轴旋转", [UIColor systemOrangeColor]);
    [self.rotateZButton addTarget:self action:@selector(rotateZ) forControlEvents:UIControlEventTouchUpInside];
    
    // 截图按钮
    self.snapshotButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.snapshotButton, @"截图", [UIColor systemGreenColor]);
    [self.snapshotButton addTarget:self action:@selector(takeSnapshot) forControlEvents:UIControlEventTouchUpInside];
    
    // 媒体选择器按钮
    self.mediaButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.mediaButton, @"选择媒体源", [UIColor systemTealColor]);
    [self.mediaButton addTarget:self action:@selector(showMediaPicker) forControlEvents:UIControlEventTouchUpInside];
    
    // 字幕按钮
    self.subtitleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.subtitleButton, @"字幕", [UIColor systemIndigoColor]);
    [self.subtitleButton addTarget:self action:@selector(handleSubtitle) forControlEvents:UIControlEventTouchUpInside];
    
    // 逐帧按钮
    self.frameButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.frameButton, @"逐帧", [UIColor systemPinkColor]);
    [self.frameButton addTarget:self action:@selector(stepFrame) forControlEvents:UIControlEventTouchUpInside];
    
    // 音频延迟
    self.audioDelayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.audioDelayButton, @"音频延迟", [UIColor systemBrownColor]);
    [self.audioDelayButton addTarget:self action:@selector(adjustAudioDelay) forControlEvents:UIControlEventTouchUpInside];
    
    // 字幕延迟
    if (@available(iOS 15.0, *)) {
        self.subtitleDelayButton = [UIButton buttonWithType:UIButtonTypeSystem];
        buttonConfig(self.subtitleDelayButton, @"字幕延迟", [UIColor systemCyanColor]);
    }
    [self.subtitleDelayButton addTarget:self action:@selector(adjustSubtitleDelay) forControlEvents:UIControlEventTouchUpInside];
    
    // 色彩调整
    self.colorButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.colorButton, @"色彩", [UIColor systemYellowColor]);
    [self.colorButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.colorButton addTarget:self action:@selector(showColorSettings) forControlEvents:UIControlEventTouchUpInside];
    
    // 画面比例
    if (@available(iOS 15.0, *)) {
        self.aspectButton = [UIButton buttonWithType:UIButtonTypeSystem];
        buttonConfig(self.aspectButton, @"画面比例", [UIColor systemMintColor]);
    }
    [self.aspectButton addTarget:self action:@selector(showAspectSettings) forControlEvents:UIControlEventTouchUpInside];
    
    // 快照类型按钮
    self.snapshotTypeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.snapshotTypeButton, @"快照类型", [UIColor systemGrayColor]);
    [self.snapshotTypeButton addTarget:self action:@selector(changeSnapshotType) forControlEvents:UIControlEventTouchUpInside];
    
    // 画中画按钮
    self.pipButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.pipButton, @"画中画", [UIColor systemBlueColor]);
    [self.pipButton addTarget:self action:@selector(togglePictureInPicture) forControlEvents:UIControlEventTouchUpInside];
    
    // 全屏/半屏按钮
    self.fullScreenButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.fullScreenButton, self.isFullScreen ? @"半屏" : @"全屏", [UIColor systemRedColor]);
    [self.fullScreenButton addTarget:self action:@selector(toggleFullScreen) forControlEvents:UIControlEventTouchUpInside];
    
    // 横竖屏切换按钮
    UIInterfaceOrientationMask orientation = UIDevice.wy_currentInterfaceOrientation;
    self.orientationButton = [UIButton buttonWithType:UIButtonTypeSystem];
    buttonConfig(self.orientationButton, (orientation == UIInterfaceOrientationMaskPortrait) ? @"横屏" : @"竖屏", [UIColor systemGreenColor]);
    [self.orientationButton addTarget:self action:@selector(toggleOrientation) forControlEvents:UIControlEventTouchUpInside];
    
    // 音量滑块
    UILabel *volumeSliderTitle = [[UILabel alloc] init];
    volumeSliderTitle.text = @"音量";
    volumeSliderTitle.textColor = [UIColor whiteColor];
    [contentView addSubview:volumeSliderTitle];
    
    self.volumeSlider = [[UISlider alloc] init];
    self.volumeSlider.minimumValue = 0;
    self.volumeSlider.maximumValue = 1;
    self.volumeSlider.value = 0.5;
    self.volumeSlider.tintColor = [UIColor systemBlueColor];
    [self.volumeSlider addTarget:self action:@selector(volumeChanged) forControlEvents:UIControlEventValueChanged];
    [contentView addSubview:self.volumeSlider];
    
    // 倍速滑块
    UILabel *rateSliderTitle = [[UILabel alloc] init];
    rateSliderTitle.text = @"倍速";
    rateSliderTitle.textColor = [UIColor whiteColor];
    [contentView addSubview:rateSliderTitle];
    
    self.rateSlider = [[UISlider alloc] init];
    self.rateSlider.minimumValue = 0.5;
    self.rateSlider.maximumValue = 2.0;
    self.rateSlider.value = 1.0;
    self.rateSlider.tintColor = [UIColor systemOrangeColor];
    [self.rateSlider addTarget:self action:@selector(rateChanged) forControlEvents:UIControlEventValueChanged];
    [contentView addSubview:self.rateSlider];
    
    // 进度滑块
    UILabel *seekSliderTitle = [[UILabel alloc] init];
    seekSliderTitle.text = @"进度";
    seekSliderTitle.textColor = [UIColor whiteColor];
    [contentView addSubview:seekSliderTitle];
    
    self.seekSlider = [[UISlider alloc] init];
    self.seekSlider.minimumValue = 0;
    self.seekSlider.maximumValue = 1;
    self.seekSlider.tintColor = [UIColor systemGreenColor];
    [self.seekSlider addTarget:self action:@selector(seekChanged) forControlEvents:UIControlEventValueChanged];
    [contentView addSubview:self.seekSlider];
    
    // 信息标签
    self.infoLabel = [[UILabel alloc] init];
    self.infoLabel.numberOfLines = 0;
    self.infoLabel.font = [UIFont systemFontOfSize:14];
    self.infoLabel.textColor = [UIColor whiteColor];
    [contentView addSubview:self.infoLabel];
    
    self.stateLabel = [[UILabel alloc] init];
    self.stateLabel.numberOfLines = 0;
    self.stateLabel.font = [UIFont systemFontOfSize:14];
    self.stateLabel.textColor = [UIColor whiteColor];
    [contentView addSubview:self.stateLabel];
    
    self.streamLabel = [[UILabel alloc] init];
    self.streamLabel.numberOfLines = 0;
    self.streamLabel.font = [UIFont systemFontOfSize:14];
    self.streamLabel.textColor = [UIColor whiteColor];
    [contentView addSubview:self.streamLabel];
    
    // 布局所有控件
    CGFloat buttonWidth = (self.view.bounds.size.width - 48) / 3;
    CGFloat buttonHeight = 44;
    
    [self.playPauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView).offset(20);
        make.left.equalTo(contentView).offset(16);
        make.width.equalTo(@(buttonWidth));
        make.height.equalTo(@(buttonHeight));
    }];
    
    [self.stopButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.playPauseButton);
        make.left.equalTo(self.playPauseButton.mas_right).offset(8);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.scalingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.playPauseButton);
        make.left.equalTo(self.stopButton.mas_right).offset(8);
        make.right.equalTo(contentView).offset(-16);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.rotateXButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.playPauseButton.mas_bottom).offset(16);
        make.left.equalTo(self.playPauseButton);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.rotateYButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.rotateXButton);
        make.left.equalTo(self.rotateXButton.mas_right).offset(8);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.rotateZButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.rotateXButton);
        make.left.equalTo(self.rotateYButton.mas_right).offset(8);
        make.right.equalTo(contentView).offset(-16);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.mediaButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.rotateXButton.mas_bottom).offset(16);
        make.left.equalTo(self.playPauseButton);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.subtitleButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mediaButton);
        make.left.equalTo(self.mediaButton.mas_right).offset(8);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.frameButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mediaButton);
        make.left.equalTo(self.subtitleButton.mas_right).offset(8);
        make.right.equalTo(contentView).offset(-16);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.audioDelayButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mediaButton.mas_bottom).offset(16);
        make.left.equalTo(self.playPauseButton);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.subtitleDelayButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.audioDelayButton);
        make.left.equalTo(self.audioDelayButton.mas_right).offset(8);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.colorButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.audioDelayButton);
        make.left.equalTo(self.subtitleDelayButton.mas_right).offset(8);
        make.right.equalTo(contentView).offset(-16);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.aspectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.audioDelayButton.mas_bottom).offset(16);
        make.left.equalTo(self.playPauseButton);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.snapshotButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.aspectButton);
        make.left.equalTo(self.aspectButton.mas_right).offset(8);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.snapshotTypeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.aspectButton);
        make.left.equalTo(self.snapshotButton.mas_right).offset(8);
        make.right.equalTo(contentView).offset(-16);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    // MARK: - 新增按钮布局
    [self.pipButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.snapshotTypeButton.mas_bottom).offset(16);
        make.left.equalTo(self.playPauseButton);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.pipButton);
        make.left.equalTo(self.pipButton.mas_right).offset(8);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [self.orientationButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.pipButton);
        make.left.equalTo(self.fullScreenButton.mas_right).offset(8);
        make.right.equalTo(contentView).offset(-16);
        make.width.height.equalTo(self.playPauseButton);
    }];
    
    [seekSliderTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.pipButton.mas_bottom).offset(20);
        make.left.equalTo(contentView).offset(16);
        make.width.equalTo(@35);
        make.height.equalTo(@30);
    }];
    
    [self.seekSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.pipButton.mas_bottom).offset(20);
        make.left.equalTo(seekSliderTitle.mas_right).offset(16);
        make.right.equalTo(contentView).offset(-16);
        make.height.equalTo(@30);
    }];
    
    [rateSliderTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.seekSlider.mas_bottom).offset(16);
        make.left.width.height.equalTo(seekSliderTitle);
    }];
    
    [self.rateSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.seekSlider.mas_bottom).offset(16);
        make.left.right.equalTo(self.seekSlider);
        make.height.equalTo(@30);
    }];
    
    [volumeSliderTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.rateSlider.mas_bottom).offset(16);
        make.left.width.height.equalTo(seekSliderTitle);
    }];
    
    [self.volumeSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.rateSlider.mas_bottom).offset(16);
        make.left.right.equalTo(self.seekSlider);
        make.height.equalTo(@30);
    }];
    
    [self.infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.volumeSlider.mas_bottom).offset(20);
        make.left.right.equalTo(self.seekSlider);
    }];
    
    [self.stateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.infoLabel.mas_bottom).offset(10);
        make.left.right.equalTo(self.seekSlider);
    }];
    
    [self.streamLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.stateLabel.mas_bottom).offset(10);
        make.left.right.equalTo(self.seekSlider);
        make.bottom.equalTo(contentView).offset(-30);
    }];
}

// 播放当前媒体
- (void)playCurrentMedia {
    if (self.currentIndex >= self.mediaList.count) { return; }
    
    NSDictionary *media = self.mediaList[self.currentIndex];
    self.navigationItem.title = media[@"name"];
    
    [WYActivity showLoadingIn:self.view option:[self sharedLoadingInfoOptions]];
    
    [self.player playWithUrl:media[@"url"]];
}

// 启动信息更新定时器
- (void)startInfoUpdateTimer {
    __weak typeof(self) weakSelf = self;
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakSelf updatePlayerInfo];
    }];
}

// 更新播放器信息
- (void)updatePlayerInfo {
    if (self.player.state != WYMediaPlayerStatePlaying &&
        self.player.state != WYMediaPlayerStateBuffering &&
        self.player.state != WYMediaPlayerStatePaused) { return; }
    
    CGFloat duration = [self.player videoDuration];
    CGFloat currentTime = self.player.ijkPlayer.currentPlaybackTime;
    CGFloat progress = duration > 0 ? currentTime / duration : 0;
    
    [self.seekSlider setValue:progress animated:YES];
    
    CGFloat bufferingProgress = [self.player bufferingProgress];
    CGFloat downloadSpeed = [self.player downloadSpeed];
    CGFloat playableDuration = [self.player playableDuration];
    
    CGFloat speedMB = downloadSpeed / (1024 * 1024);
    
    self.infoLabel.text = [NSString stringWithFormat:@"进度: %.1f/%.1fs\n缓冲: %.0f%%\n可播时长: %.1fs\n下载速度: %.2f MB/s",
                          currentTime, duration, bufferingProgress, playableDuration, speedMB];
    
    self.stateLabel.text = [NSString stringWithFormat:@"状态: %@", [self playerStateDescription:self.player.state]];
    
    if (self.player.ijkPlayer.monitor.mediaMeta) {
        self.streamLabel.text = [NSString stringWithFormat:@"流信息: %@", self.player.ijkPlayer.monitor.mediaMeta];
    }
}

// 播放器状态描述
- (NSString *)playerStateDescription:(WYMediaPlayerState)state {
    switch (state) {
        case WYMediaPlayerStateUnknown: return @"未知";
        case WYMediaPlayerStateRendered: return @"第一帧渲染";
        case WYMediaPlayerStateReady: return @"准备就绪";
        case WYMediaPlayerStatePlaying: return @"播放中";
        case WYMediaPlayerStateBuffering: return @"缓冲中";
        case WYMediaPlayerStatePlayable: return @"可播放";
        case WYMediaPlayerStatePaused: return @"已暂停";
        case WYMediaPlayerStateInterrupted: return @"中断";
        case WYMediaPlayerStateSeekingForward: return @"快进";
        case WYMediaPlayerStateSeekingBackward: return @"快退";
        case WYMediaPlayerStateEnded: return @"结束";
        case WYMediaPlayerStateUserExited: return @"用户退出";
        case WYMediaPlayerStateError: return @"错误";
        case WYMediaPlayerStatePlayUrlEmpty: return @"空URL";
    }
}

// MARK: - 控制功能

- (void)togglePlayPause {
    if (self.player.state == WYMediaPlayerStatePlaying) {
        [self.player pause];
        [self.playPauseButton setTitle:@"播放" forState:UIControlStateNormal];
        self.playPauseButton.backgroundColor = [UIColor systemGreenColor];
    } else {
        [self.player play];
        [self.playPauseButton setTitle:@"暂停" forState:UIControlStateNormal];
        self.playPauseButton.backgroundColor = [UIColor systemBlueColor];
    }
}

- (void)stopPlaying {
    [self.player stopWithKeepLast:NO];
}

- (void)volumeChanged {
    [self.player playbackVolume:self.volumeSlider.value];
}

- (void)rateChanged {
    [self.player playbackRate:self.rateSlider.value];
}

- (void)seekChanged {
    CGFloat duration = [self.player videoDuration];
    CGFloat targetTime = self.seekSlider.value * duration;
    [self.player playbackTime:targetTime];
}

- (void)changeScaling {
    FSScalingMode currentMode = self.player.scalingStyle;
    FSScalingMode nextMode;
    
    switch (currentMode) {
        case FSScalingModeAspectFit:
            nextMode = FSScalingModeAspectFill;
            break;
        case FSScalingModeAspectFill:
            nextMode = FSScalingModeFill;
            break;
        default:
            nextMode = FSScalingModeAspectFit;
            break;
    }
    
    [self.player scalingStyle:nextMode];
    [self showAlertWithTitle:@"缩放模式已更改" message:[NSString stringWithFormat:@"当前模式: %@", [self scalingModeDescription:nextMode]]];
}

- (NSString *)scalingModeDescription:(FSScalingMode)mode {
    switch (mode) {
        case FSScalingModeAspectFit: return @"适应";
        case FSScalingModeAspectFill: return @"填充";
        case FSScalingModeFill: return @"拉伸";
        default: return @"未知";
    }
}

- (void)rotateX {

    FSRotatePreference preference = self.rotatePreference;
    preference.type = FSRotateX;
    preference.degrees += 90;
    
    if (preference.degrees >= 360) {
        preference.degrees = 0;
    }
    
    self.rotatePreference = preference;
    
    [self.player rotatePreference:self.rotatePreference];
    [self showAlertWithTitle:@"X轴旋转" message:[NSString stringWithFormat:@"已旋转至 %d°", (int)self.rotatePreference.degrees]];
}

- (void)rotateY {
    
    FSRotatePreference preference = self.rotatePreference;
    preference.type = FSRotateY;
    preference.degrees += 90;
    
    if (preference.degrees >= 360) {
        preference.degrees = 0;
    }
    
    self.rotatePreference = preference;
    
    [self.player rotatePreference:self.rotatePreference];
    [self showAlertWithTitle:@"Y轴旋转" message:[NSString stringWithFormat:@"已旋转至 %d°", (int)self.rotatePreference.degrees]];
}

- (void)rotateZ {
    
    FSRotatePreference preference = self.rotatePreference;
    preference.type = FSRotateZ;
    preference.degrees += 90;
    
    if (preference.degrees >= 360) {
        preference.degrees = 0;
    }
    
    self.rotatePreference = preference;
    
    [self.player rotatePreference:self.rotatePreference];
    [self showAlertWithTitle:@"Z轴旋转" message:[NSString stringWithFormat:@"已旋转至 %d°", (int)self.rotatePreference.degrees]];
}

- (void)takeSnapshot {
    UIImage *snapshot = [self.player currentSnapshot];
    [self showAlertWithTitle:@"截图成功" message:[NSString stringWithFormat:@"尺寸: %@", NSStringFromCGSize(snapshot.size)]];
}

- (void)showMediaPicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择媒体源" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (NSInteger index = 0; index < self.mediaList.count; index++) {
        NSDictionary *media = self.mediaList[index];
        UIAlertAction *action = [UIAlertAction actionWithTitle:media[@"name"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.currentIndex = index;
            [self playCurrentMedia];
        }];
        [alert addAction:action];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    // 适配iPad
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.mediaButton;
        alert.popoverPresentationController.sourceRect = self.mediaButton.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleSubtitle {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"字幕操作" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *loadAction = [UIAlertAction actionWithTitle:@"加载并激活字幕" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (self.subtitleList.count > 0) {
            NSURL *url = self.subtitleList[arc4random_uniform((uint32_t)self.subtitleList.count)];
            [self.player loadThenActiveSubtitleWithUrl:url];
            [self showAlertWithTitle:@"字幕加载" message:@"已加载并激活字幕"];
        }
    }];
    [alert addAction:loadAction];
    
    UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"关闭字幕流" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self.player closeCurrentStreamWithStyle:@"FS_VAL_TYPE__SUBTITLE"];
        [self showAlertWithTitle:@"字幕流关闭" message:@"已关闭当前字幕流"];
    }];
    [alert addAction:closeAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    // 适配iPad
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.subtitleButton;
        alert.popoverPresentationController.sourceRect = self.subtitleButton.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)stepFrame {
    [self.player stepToNextFrame];
    [self showAlertWithTitle:@"逐帧播放" message:@"已前进一帧"];
}

- (void)adjustAudioDelay {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"音频延迟设置" message:@"输入延迟时间（秒）" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"例如: 0.5 或 -0.3";
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.text = @"0.0";
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        CGFloat delay = [textField.text floatValue];
        [self.player audioExtraDelay:delay];
        [self showAlertWithTitle:@"音频延迟设置" message:[NSString stringWithFormat:@"已设置为 %@秒", textField.text]];
    }];
    [alert addAction:confirmAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)adjustSubtitleDelay {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"字幕延迟设置" message:@"输入延迟时间（秒）" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"例如: 0.5 或 -0.3";
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.text = @"0.0";
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        CGFloat delay = [textField.text floatValue];
        [self.player subtitleExtraDelay:delay];
        [self showAlertWithTitle:@"字幕延迟设置" message:[NSString stringWithFormat:@"已设置为 %@秒", textField.text]];
    }];
    [alert addAction:confirmAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showColorSettings {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"色彩设置" message:@"调整画面色彩" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"默认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        FSColorConvertPreference preference = self.colorPreference;
        preference.brightness = 1.0;
        preference.saturation = 1.0;
        preference.contrast = 1.0;
        self.colorPreference = preference;
        
        [self.player colorPreference:self.colorPreference];
        [self showAlertWithTitle:@"色彩设置" message:@"已恢复默认色彩"];
    }];
    [alert addAction:defaultAction];
    
    UIAlertAction *blackWhiteAction = [UIAlertAction actionWithTitle:@"黑白" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        FSColorConvertPreference preference = self.colorPreference;
        preference.saturation = 0.0;
        self.colorPreference = preference;
        
        [self.player colorPreference:self.colorPreference];
        [self showAlertWithTitle:@"色彩设置" message:@"已设为黑白"];
    }];
    [alert addAction:blackWhiteAction];
    
    UIAlertAction *retroAction = [UIAlertAction actionWithTitle:@"复古" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        FSColorConvertPreference preference = self.colorPreference;
        preference.saturation = 0.8;
        preference.contrast = 1.5;
        self.colorPreference = preference;
        
        [self.player colorPreference:self.colorPreference];
        [self showAlertWithTitle:@"色彩设置" message:@"已设为复古"];
    }];
    [alert addAction:retroAction];
    
    UIAlertAction *brightAction = [UIAlertAction actionWithTitle:@"高亮度" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        FSColorConvertPreference preference = self.colorPreference;
        preference.brightness = 1.5;
        self.colorPreference = preference;
        
        [self.player colorPreference:self.colorPreference];
        [self showAlertWithTitle:@"色彩设置" message:@"已提高亮度"];
    }];
    [alert addAction:brightAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    // 适配iPad
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.colorButton;
        alert.popoverPresentationController.sourceRect = self.colorButton.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAspectSettings {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"画面比例" message:@"选择画面宽高比" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"默认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        FSDARPreference preference = self.aspectPreference;
        preference.ratio = 0;
        self.aspectPreference = preference;
        
        [self.player darPreference:self.aspectPreference];
    }];
    [alert addAction:defaultAction];
    
    UIAlertAction *ratio43Action = [UIAlertAction actionWithTitle:@"4:3" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        FSDARPreference preference = self.aspectPreference;
        preference.ratio = 4.0 / 3.0;
        self.aspectPreference = preference;
        
        [self.player darPreference:self.aspectPreference];
    }];
    [alert addAction:ratio43Action];
    
    UIAlertAction *ratio169Action = [UIAlertAction actionWithTitle:@"16:9" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        FSDARPreference preference = self.aspectPreference;
        preference.ratio = 16.0 / 9.0;
        self.aspectPreference = preference;
        
        [self.player darPreference:self.aspectPreference];
    }];
    [alert addAction:ratio169Action];
    
    UIAlertAction *ratio11Action = [UIAlertAction actionWithTitle:@"1:1" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        FSDARPreference preference = self.aspectPreference;
        preference.ratio = 1.0;
        self.aspectPreference = preference;
        
        [self.player darPreference:self.aspectPreference];
    }];
    [alert addAction:ratio11Action];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    // 适配iPad
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.aspectButton;
        alert.popoverPresentationController.sourceRect = self.aspectButton.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)changeSnapshotType {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"快照类型" message:@"选择截图方式" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *originAction = [UIAlertAction actionWithTitle:@"原始尺寸(无字幕无特效)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSnapshotType = FSSnapshotTypeOrigin;
    }];
    [alert addAction:originAction];
    
    UIAlertAction *screenAction = [UIAlertAction actionWithTitle:@"屏幕截图(当前画面)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSnapshotType = FSSnapshotTypeScreen;
    }];
    [alert addAction:screenAction];
    
    UIAlertAction *effectOriginAction = [UIAlertAction actionWithTitle:@"原始尺寸(有字幕无特效)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSnapshotType = FSSnapshotTypeEffect_Origin;
    }];
    [alert addAction:effectOriginAction];
    
    UIAlertAction *effectSubtitleOriginAction = [UIAlertAction actionWithTitle:@"原始尺寸(有字幕有特效)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.currentSnapshotType = FSSnapshotTypeEffect_Subtitle_Origin;
    }];
    [alert addAction:effectSubtitleOriginAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    // 适配iPad
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.snapshotTypeButton;
        alert.popoverPresentationController.sourceRect = self.snapshotTypeButton.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

// MARK: - 新增按钮功能

// 切换画中画模式
- (void)togglePictureInPicture {
    if (!self.pipController) {
        [self showAlertWithTitle:@"画中画不可用" message:@"无法初始化画中画控制器"];
        return;
    }
    
    if (self.pipController.isPictureInPictureActive) {
        [self.pipController stopPictureInPicture];
        self.pipButton.backgroundColor = [UIColor systemBlueColor];
    } else {
        [self.pipController startPictureInPicture];
        self.pipButton.backgroundColor = [UIColor systemRedColor];
    }
}

// 切换全屏/半屏模式
- (void)toggleFullScreen {
    self.isFullScreen = !self.isFullScreen;
    
    [self.player mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
        
        if (self.isFullScreen) {
            make.bottom.equalTo(self.view);
            [self.fullScreenButton setTitle:@"半屏" forState:UIControlStateNormal];
        } else {
            make.height.equalTo(self.view).multipliedBy(0.5);
            [self.fullScreenButton setTitle:@"全屏" forState:UIControlStateNormal];
        }
    }];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

// 横竖屏切换
- (void)toggleOrientation {
    // 这里只实现按钮状态切换，具体横竖屏实现由您完成
    UIInterfaceOrientationMask orientation = [UIDevice wy_currentInterfaceOrientation];
    if (orientation == UIInterfaceOrientationMaskPortrait) {
        self.orientationButton.backgroundColor = [UIColor systemOrangeColor];
        [self.orientationButton setTitle:@"竖屏" forState:UIControlStateNormal];
        UIDevice.wy_setInterfaceOrientation = UIInterfaceOrientationMaskLandscapeLeft;
    } else {
        self.orientationButton.backgroundColor = [UIColor systemGreenColor];
        [self.orientationButton setTitle:@"横屏" forState:UIControlStateNormal];
        UIDevice.wy_setInterfaceOrientation = UIInterfaceOrientationMaskPortrait;
    }
}

// 显示/隐藏控制面板
- (void)toggleControlPanel {
    self.isControlPanelVisible = !self.isControlPanelVisible;
    
    if (self.isControlPanelVisible) {
        self.controlPanel.hidden = NO;
        self.controlPanel.transform = CGAffineTransformMakeTranslation(0, -self.controlPanel.bounds.size.height);
        [UIView animateWithDuration:0.3 animations:^{
            self.controlPanel.transform = CGAffineTransformIdentity;
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.controlPanel.transform = CGAffineTransformMakeTranslation(0, -self.controlPanel.bounds.size.height);
        } completion:^(BOOL finished) {
            self.controlPanel.hidden = YES;
        }];
    }
}

// 显示提示
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    UIDevice.wy_setInterfaceOrientation = UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc {
    [self.updateTimer invalidate];
    [self.player releaseAll];
    WYLog(@"WYTestLiveStreamingController release");
}

// MARK: - 播放器代理

- (void)mediaPlayerDidChangeState:(WYMediaPlayer *)player state:(enum WYMediaPlayerState)state {
    switch (state) {
        case WYMediaPlayerStateUnknown:
            WYLog(@"未知状态");
            break;
        case WYMediaPlayerStateRendered:
            WYLog(@"第一帧渲染完成");
            [WYActivity dismissLoadingIn:self.view animate:NO];
            break;
        case WYMediaPlayerStateReady:
            WYLog(@"可以播放了");
            break;
        case WYMediaPlayerStatePlaying:
            WYLog(@"正在播放：%@", player.mediaUrl);
            [WYActivity dismissLoadingIn:self.view animate:NO];
            break;
        case WYMediaPlayerStateBuffering:
            WYLog(@"缓冲中");
            [WYActivity showLoadingIn:self.view option:[self sharedLoadingInfoOptions]];
            break;
        case WYMediaPlayerStatePlayable:
            WYLog(@"缓冲结束");
            [WYActivity dismissLoadingIn:self.view animate:NO];
            break;
        case WYMediaPlayerStatePaused:
            WYLog(@"播放暂停");
            [WYActivity dismissLoadingIn:self.view animate:NO];
            break;
        case WYMediaPlayerStateInterrupted:
            WYLog(@"播放被中断");
            [WYActivity dismissLoadingIn:self.view animate:NO];
            break;
        case WYMediaPlayerStateSeekingForward:
            WYLog(@"快进");
            [WYActivity showLoadingIn:self.view option:[self sharedLoadingInfoOptions]];
            break;
            
        case WYMediaPlayerStateSeekingBackward:
            WYLog(@"快退");
            [WYActivity showLoadingIn:self.view option:[self sharedLoadingInfoOptions]];
            break;
        case WYMediaPlayerStateEnded:
            WYLog(@"播放完毕");
            [WYActivity dismissLoadingIn:self.view animate:NO];
            if (self.isControlPanelVisible) {
                [self toggleControlPanel];
            }
            self.currentIndex = ((self.currentIndex + 1) > self.mediaList.count) ? 0 : (self.currentIndex + 1);
            [self playCurrentMedia];
            break;
        case WYMediaPlayerStateUserExited:
            WYLog(@"用户中断播放");
            [WYActivity dismissLoadingIn:self.view animate:NO];
            break;
        case WYMediaPlayerStateError:
            WYLog(@"播放出现异常");
            [WYActivity dismissLoadingIn:self.view animate:NO];
            break;
        case WYMediaPlayerStatePlayUrlEmpty:
            WYLog(@"播放为空");
            [WYActivity dismissLoadingIn:self.view animate:NO];
            break;
    }
}

- (void)mediaPlayerDidChangeSubtitleStream:(WYMediaPlayer *)player mediaMeta:(NSDictionary *)mediaMeta {
    self.streamLabel.text = [NSString stringWithFormat:@"流信息: %@", mediaMeta];
}

- (WYLoadingInfoOptions *)sharedLoadingInfoOptions {
    
    WYLoadingInfoOptions *options = [[WYLoadingInfoOptions alloc] init];
    options.config = WYActivityConfig.concise;
    options.animation = WYActivityAnimationGifOrApng;
    
    return options;
}

// MARK: - 画中画代理

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    self.pipButton.backgroundColor = [UIColor systemRedColor];
    [self.pipButton setTitle:@"退出画中画" forState:UIControlStateNormal];
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    self.pipButton.backgroundColor = [UIColor systemBlueColor];
    [self.pipButton setTitle:@"画中画" forState:UIControlStateNormal];
}

// MARK: - 设置播放列表

- (void)setupMediaList {
    self.mediaList = @[
        @{@"name": @"外国公园", @"url": @"https://files.cochat.lenovo.com/download/dbb26a06-4604-3d2b-bb2c-6293989e63a7/55deb281e01b27194daf6da391fdfe83.mp4"},
        @{@"name": @"棕熊与鸟", @"url": @"http://www.w3school.com.cn/i/movie.mp4"},
        @{@"name": @"勇闯冰川", @"url": @"https://media.w3.org/2010/05/sintel/trailer.mp4"},
        @{@"name": @"哔啵", @"url": @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"},
        @{@"name": @"雍正王朝", @"url": @"https://live.metshop.top/douyu/74374"},
        @{@"name": @"万合出品", @"url": @"https://live.metshop.top/douyu/9220456"},
        @{@"name": @"周星驰", @"url": @"https://live.metshop.top/huya/11342412"},
        @{@"name": @"林正英", @"url": @"https://live.metshop.top/huya/11342421"},
        @{@"name": @"漫威君", @"url": @"https://live.metshop.top/douyu/1713615"},
        @{@"name": @"小黛兮(别扫码，只测试)", @"url": @"https://live.metshop.top/douyu/11553944"},
        @{@"name": @"动物世界", @"url": @"https://playertest.longtailvideo.com/adaptive/oceans_aes/oceans_aes.m3u8"},
        @{@"name": @"动漫世界", @"url": @"https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"},
        @{@"name": @"海底盛宴", @"url": @"http://vjs.zencdn.net/v/oceans.mp4"},
        @{@"name": @"胆子不小的郑吉祥", @"url": @"https://live.metshop.top/douyu/9171887"},
        @{@"name": @"宇宙探索飞船", @"url": @"https://live.metshop.top/douyu/9456028"},
        @{@"name": @"堇姑娘", @"url": @"https://live.metshop.top/douyu/297689"},
        @{@"name": @"十七岁的道姑", @"url": @"https://live.metshop.top/douyu/3186217"},
        @{@"name": @"工藤新医heart", @"url": @"https://live.metshop.top/douyu/8741860"},
        @{@"name": @"粤语电影丶", @"url": @"https://live.metshop.top/douyu/1226741"},
        @{@"name": @"我砸晕了牛顿奥", @"url": @"https://live.metshop.top/douyu/1218414"},
        @{@"name": @"小姐姐不记得", @"url": @"https://live.metshop.top/douyu/3700024"},
        @{@"name": @"魔术师丶西索", @"url": @"https://live.metshop.top/douyu/6610883"},
        @{@"name": @"v刺猬猪v", @"url": @"https://live.metshop.top/douyu/2436390"},
        @{@"name": @"周星驰", @"url": @"https://live.metshop.top/huya/11342412"},
        @{@"name": @"林正英", @"url": @"https://live.metshop.top/huya/11342421"},
        @{@"name": @"萌新司机", @"url": @"https://live.metshop.top/huya/11352881"},
        @{@"name": @"四大裁子之首", @"url": @"https://live.metshop.top/huya/11602058"},
        @{@"name": @"核桃姐姐", @"url": @"https://live.metshop.top/huya/11342390"},
        @{@"name": @"铁血真汉子", @"url": @"https://live.metshop.top/huya/11342395"},
        @{@"name": @"嫣然", @"url": @"https://live.metshop.top/huya/11601977"},
        @{@"name": @"元芳看不到", @"url": @"https://live.metshop.top/huya/11342414"},
        @{@"name": @"yoo", @"url": @"https://live.metshop.top/huya/11352876"},
        @{@"name": @"喜来乐狮子头", @"url": @"https://live.metshop.top/huya/21059580"},
        @{@"name": @"春晚1983", @"url": @"https://alimov2.a.kwimgs.com/upic/2022/01/31/15/BMjAyMjAxMzExNTU5MTRfNDAzMDAxOTlfNjYyNzMxNjcwMjBfMF8z_b_Beb3bda599f76c60c463c433ca7460153.mp4"},
        @{@"name": @"春晚1984", @"url": @"https://alimov2.a.kwimgs.com/upic/2022/01/31/15/BMjAyMjAxMzExNTU5NTRfNDAzMDAxOTlfNjYyNzMyMzg3MTRfMF8z_b_B192356dadbc90d207ba16964d4c2914c.mp4"},
        @{@"name": @"春晚1985", @"url": @"https://alimov2.a.kwimgs.com/upic/2022/01/31/16/BMjAyMjAxMzExNjAwMDFfNDAzMDAxOTlfNjYyNzMyNTAwMzJfMF8z_b_Be73c5abcbc0eeb2ec9fce6842e1362a4.mp4"},
        @{@"name": @"春晚1986", @"url": @"https://alimov2.a.kwimgs.com/upic/2022/01/31/16/BMjAyMjAxMzExNjAwMDRfNDAzMDAxOTlfNjYyNzMyNTU0OTRfMF8z_b_B24f7d19f1132fa5d7f502f8377ad5567.mp4"},
        @{@"name": @"春晚1987", @"url": @"https://alimov2.a.kwimgs.com/upic/2022/01/31/16/BMjAyMjAxMzExNjAwMDhfNDAzMDAxOTlfNjYyNzMyNjMyMDNfMF8z_b_B570493ed8f7200d4013a66b2d21b2de9.mp4"},
        @{@"name": @"春晚1988", @"url": @"https://alimov2.a.kwimgs.com/upic/2022/01/31/16/BMjAyMjAxMzExNjAwMTJfNDAzMDAxOTlfNjYyNzMyNjkxNjBfMF8z_b_B8c835b83a92d25bde81ba22c5cd9521e.mp4"},
        @{@"name": @"春晚1989", @"url": @"https://alimov2.a.kwimgs.com/upic/2022/01/31/16/BMjAyMjAxMzExNjAwMTVfNDAzMDAxOTlfNjYyNzMyNzQ2OTlfMF8z_b_Be477b27b9ce655d2372df56a5a3d96ef.mp4"},
        @{@"name": @"春晚1990", @"url": @"https://cdn8.yzzy-online.com/20220704/597_e0d90c37/1000k/hls/index.m3u8"},
        @{@"name": @"春晚1992", @"url": @"https://txmov2.a.kwimgs.com/bs3/video-hls/5256826755663896297_hlshd15.m3u8"},
        @{@"name": @"春晚1993", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/22/BMjAyMzAxMTMyMjEwMDNfNDAzMDAxOTlfOTM1MTIzMzYwODJfMF8z_b_B647d10e431b4cc5e48e6c77347d69021.mp4"},
        @{@"name": @"春晚1994", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/22/BMjAyMzAxMTMyMjEwMDNfNDAzMDAxOTlfOTM1MTIzMzYxMjNfMF8z_b_B3dde97f36273f04403d4dc5eec611a35.mp4"},
        @{@"name": @"春晚1995", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQwNzVfMF8z_b_B811c0dec6b9a3d3074a18522c185010a.mp4"},
        @{@"name": @"春晚1996", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/22/BMjAyMzAxMTMyMjEwMDNfNDAzMDAxOTlfOTM1MTIzMzYxNTJfMF8z_b_Bd841eae10ab1c9955ef55fbedfae6c45.mp4"},
        @{@"name": @"春晚1997", @"url": @"https://txmov2.a.kwimgs.com/bs3/video-hls/5230649583590411879_hlshd15.m3u8"},
        @{@"name": @"春晚1998", @"url": @"https://txmov2.a.kwimgs.com/bs3/video-hls/5225864507896315430_hlshd15.m3u8"},
        @{@"name": @"春晚1999", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQxNTRfMF8z_b_B0b5e52bc003285ef66ec0cbb2be08556.mp4"},
        @{@"name": @"春晚2000", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/21/BMjAyMzAxMTMyMTE4MzRfNDAzMDAxOTlfOTM1MDY4ODIxMTNfMF8z_b_Bdddf4e7ef0ff6cfd477857bb40e78419.mp4"},
        @{@"name": @"春晚2001", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQyMDFfMF8z_b_B70592cb7c4054e9cabb675e849bbf4bd.mp4"},
        @{@"name": @"春晚2002", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/21/BMjAyMzAxMTMyMTE4MzRfNDAzMDAxOTlfOTM1MDY4ODIxNDdfMF8z_b_Ba6271d10b7e6cfae83759033a091f257.mp4"},
        @{@"name": @"春晚2003", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/14/23/BMjAyMzAxMTQyMzQxNDdfNDAzMDAxOTlfOTM2MTU0MTk1NDFfMF8z_b_B182749d2cd2ea9323639254af385f24b.mp4"},
        @{@"name": @"春晚2004", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/21/BMjAyMzAxMTMyMTE4MzRfNDAzMDAxOTlfOTM1MDY4ODIxOTVfMF8z_b_B86c4430b82ff5a7f4e8132f6ee558536.mp4"},
        @{@"name": @"春晚2005", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQyMzhfMF8z_b_B35ad7cc86aec8fc9e5ddfb31fc7bed63.mp4"},
        @{@"name": @"春晚2006", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQyNzlfMF8z_b_Bbc3703fc331dc994c50859c19aad28ff.mp4"},
        @{@"name": @"春晚2007", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQzMjNfMF8z_b_B00b069c7899976459ceeaa99353dfefe.mp4"},
        @{@"name": @"春晚2008", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQzNTNfMF8z_b_Bd7346962e61bd7b84e11a1fa6e4616f9.mp4"},
        @{@"name": @"春晚2009", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQzOTBfMF8z_b_B29a36a85e0277f6c2a1f033ef7c10708.mp4"},
        @{@"name": @"春晚2010", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQ0MjlfMF8z_b_B8818807a00eed329a69fb494f405bd43.mp4"},
        @{@"name": @"春晚2011", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/16/11/BMjAyMzAxMTYxMTA3MjFfNDAzMDAxOTlfOTM3MjcyMjA3ODhfMF8z_b_B8214200efc869dc6fcf99dad619fa4c1.mp4"},
        @{@"name": @"春晚2012", @"url": @"https://cdn8.yzzy-online.com/20220704/591_82b72f82/1000k/hls/index.m3u8"},
        @{@"name": @"春晚2013", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQ1NjNfMF8z_b_B4fea55408dca4471a68a963ae096be59.mp4"},
        @{@"name": @"春晚2014", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/06/16/BMjAyMzAxMDYxNjMxMTNfNDAzMDAxOTlfOTI4OTY2ODAzNjlfMF8z_b_Bdee65c77f9e7b2120a185c919dad81d2.mp4"},
        @{@"name": @"春晚2015", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQ2MTZfMF8z_b_B4851f43f5a2bc2871a9b0ec87294a6e7.mp4"},
        @{@"name": @"春晚2016", @"url": @"https://cdn8.yzzy-online.com/20220704/577_cda9c8d1/1000k/hls/index.m3u8"},
        @{@"name": @"春晚2017", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQ2NDhfMF8z_b_B6527b0c2ce3dda1d9b3f34edd4fdb9aa.mp4"},
        @{@"name": @"春晚2018", @"url": @"https://alimov2.a.kwimgs.com/upic/2023/01/06/16/BMjAyMzAxMDYxNjMxMTRfNDAzMDAxOTlfOTI4OTY2ODE2MTBfMF8z_b_B11a778e34390a21de42d407e94f45b91.mp4"},
        @{@"name": @"春晚2020", @"url": @"https://alimov2.a.kwimgs.com/upic/2022/01/30/17/BMjAyMjAxMzAxNzA5NDdfNDAzMDAxOTlfNjYxNzQ2MDAyMTFfMF8z_b_B5d51d9564c5670dc66faeba20aa7af3f.mp4"},
        @{@"name": @"春晚2021", @"url": @"https://alimov2.a.kwimgs.com/upic/2022/01/30/17/BMjAyMjAxMzAxNzE4NTJfNDAzMDAxOTlfNjYxNzUzOTg3NjlfMF8z_b_Be41d9503181d7b0608a839ed401e02c2.mp4"},
        @{@"name": @"春晚2022", @"url": @"https://alimov2.a.kwimgs.com/upic/2022/02/01/11/BMjAyMjAyMDExMTEwMjNfNDAzMDAxOTlfNjYzNzA4MTk4NzNfMF8z_b_B898cc7ddd0025bf54ddb18ec1f723c84.mp4"},
        @{@"name": @"春晚2023", @"url": @"https://txmov2.a.kwimgs.com/bs3/video-hls/5251197255879398624_hlshd15.m3u8"},
        @{@"name": @"韩国DJSodaRemix2021电音", @"url": @"https://vd3.bdstatic.com/mda-mev3hw0htz28h5wn/1080p/cae_h264/1622343504467773766/mda-mev3hw0htz28h5wn.mp4"},
        @{@"name": @"韩国歌团001", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240095359203.mp4"},
        @{@"name": @"韩国歌团002", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239978750464.mp4"},
        @{@"name": @"韩国歌团003", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239858729476.mp4"},
        @{@"name": @"韩国歌团004", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239755956819.mp4"},
        @{@"name": @"韩国歌团005", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239987758613.mp4"},
        @{@"name": @"韩国歌团006", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239880949246.mp4"},
        @{@"name": @"韩国歌团007", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239903717006.mp4"},
        @{@"name": @"韩国歌团008", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239903321355.mp4"},
        @{@"name": @"韩国歌团009", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239799872402.mp4"},
        @{@"name": @"韩国歌团010", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239799088974.mp4"},
        @{@"name": @"韩国歌团011", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240024786285.mp4"},
        @{@"name": @"韩国歌团012", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240142715042.mp4"},
        @{@"name": @"韩国歌团013", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240025046562.mp4"},
        @{@"name": @"韩国歌团014", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240145171654.mp4"},
        @{@"name": @"韩国歌团015", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240147051191.mp4"},
        @{@"name": @"韩国歌团016", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239805200933.mp4"},
        @{@"name": @"韩国歌团017", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239910253332.mp4"},
        @{@"name": @"韩国歌团018", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239806164759.mp4"},
        @{@"name": @"韩国歌团019", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239807872136.mp4"},
        @{@"name": @"韩国歌团020", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240032526123.mp4"},
        @{@"name": @"歌团★021", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239808028600.mp4"},
        @{@"name": @"歌团★022", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240031614983.mp4"},
        @{@"name": @"歌团★023", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240150331617.mp4"},
        @{@"name": @"歌团★024", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239809100782.mp4"},
        @{@"name": @"歌团★025", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240151167718.mp4"},
        @{@"name": @"歌团★026", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240033362815.mp4"},
        @{@"name": @"歌团★027", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240151167938.mp4"},
        @{@"name": @"歌团★029", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239811800375.mp4"},
        @{@"name": @"歌团★030", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239916285148.mp4"},
        @{@"name": @"歌团★031", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239927589941.mp4"},
        @{@"name": @"歌团★032", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239931661209.mp4"},
        @{@"name": @"歌团★033", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240171579858.mp4"},
        @{@"name": @"歌团★034", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239831144046.mp4"},
        @{@"name": @"歌团★035", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240056530470.mp4"},
        @{@"name": @"歌团★036", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239832040344.mp4"},
        @{@"name": @"歌团★037", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240173879894.mp4"},
        @{@"name": @"歌团★038", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240057078179.mp4"},
        @{@"name": @"歌团★040", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240059018784.mp4"},
        @{@"name": @"歌团★041", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239834324813.mp4"},
        @{@"name": @"歌团★042", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239834716201.mp4"},
        @{@"name": @"歌团★043", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239837532125.mp4"},
        @{@"name": @"歌团★044", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240179867562.mp4"},
        @{@"name": @"歌团★045", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240063650207.mp4"},
        @{@"name": @"歌团★046", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240181243061.mp4"},
        @{@"name": @"歌团★047", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240181363115.mp4"},
        @{@"name": @"歌团★048", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239944465251.mp4"},
        @{@"name": @"歌团★049", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240065122134.mp4"},
        @{@"name": @"歌团★050", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239840536452.mp4"},
        @{@"name": @"歌团★051", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240065838644.mp4"},
        @{@"name": @"歌团★052", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239945877111.mp4"},
        @{@"name": @"歌团★053", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240184339138.mp4"},
        @{@"name": @"歌团★054", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239842640589.mp4"},
        @{@"name": @"歌团★055", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240186067562.mp4"},
        @{@"name": @"歌团★056", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240187071401.mp4"},
        @{@"name": @"歌团★057", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240069974546.mp4"},
        @{@"name": @"歌团★058", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240070346911.mp4"},
        @{@"name": @"歌团★059", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240070818783.mp4"},
        @{@"name": @"歌团★060", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239846692034.mp4"},
        @{@"name": @"歌团★061", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239951329234.mp4"},
        @{@"name": @"歌团★062", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240191295627.mp4"},
        @{@"name": @"歌团★063", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240026585459.mp4"},
        @{@"name": @"歌团★064", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240192067467.mp4"},
        @{@"name": @"歌团★065", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239911732892.mp4"},
        @{@"name": @"歌团★066", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240196491782.mp4"},
        @{@"name": @"歌团★067", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239960909980.mp4"},
        @{@"name": @"歌团★068", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240017737344.mp4"},
        @{@"name": @"歌团★069", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240202339353.mp4"},
        @{@"name": @"歌团★070", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240203243765.mp4"},
        @{@"name": @"歌团★071", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240205555546.mp4"},
        @{@"name": @"歌团★072", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239983417489.mp4"},
        @{@"name": @"歌团★074", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240221687198.mp4"},
        @{@"name": @"歌团★075", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240222023079.mp4"},
        @{@"name": @"歌团★076", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240107150280.mp4"},
        @{@"name": @"歌团★077", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240224523227.mp4"},
        @{@"name": @"歌团★078", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239987569147.mp4"},
        @{@"name": @"歌团★079", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240225803033.mp4"},
        @{@"name": @"歌团★080", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239989445779.mp4"},
        @{@"name": @"歌团★081", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240229579224.mp4"},
        @{@"name": @"歌团★082", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239993533054.mp4"},
        @{@"name": @"歌团★083", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239994225085.mp4"},
        @{@"name": @"歌团★084", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239994741288.mp4"},
        @{@"name": @"歌团★085", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239995197198.mp4"},
        @{@"name": @"歌团★086", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240232939168.mp4"},
        @{@"name": @"歌团★087", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239890536417.mp4"},
        @{@"name": @"歌团★088", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239890568711.mp4"},
        @{@"name": @"歌团★089", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240233783820.mp4"},
        @{@"name": @"歌团★090", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239894180409.mp4"},
        @{@"name": @"歌团★092", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239895496483.mp4"},
        @{@"name": @"歌团★093", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240119938989.mp4"},
        @{@"name": @"歌团★094", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240002397273.mp4"},
        @{@"name": @"歌团★095", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240241527208.mp4"},
        @{@"name": @"歌团★096", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239899840062.mp4"},
        @{@"name": @"歌团★097", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240243499351.mp4"},
        @{@"name": @"歌团★098", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240127638122.mp4"},
        @{@"name": @"歌团★099", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240030505796.mp4"},
        @{@"name": @"歌团★100", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240245283772.mp4"},
        @{@"name": @"歌团★101", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240247623420.mp4"},
        @{@"name": @"歌团★102", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240043672242.mp4"},
        @{@"name": @"歌团★103", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240339124000.mp4"},
        @{@"name": @"歌团★104", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240221702622.mp4"},
        @{@"name": @"歌团★105", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239993732827.mp4"},
        @{@"name": @"歌团★106", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239994460907.mp4"},
        @{@"name": @"歌团★107", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240340899550.mp4"},
        @{@"name": @"歌团★108", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239995692215.mp4"},
        @{@"name": @"歌团★109", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240341971789.mp4"},
        @{@"name": @"歌团★110", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239996664565.mp4"},
        @{@"name": @"歌团★111", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240342839842.mp4"},
        @{@"name": @"歌团★112", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240225254466.mp4"},
        @{@"name": @"歌团★113", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240225226897.mp4"},
        @{@"name": @"歌团★114", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239998000351.mp4"},
        @{@"name": @"歌团★115", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240105989528.mp4"},
        @{@"name": @"歌团★116", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239998340711.mp4"},
        @{@"name": @"歌团★117", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240106477140.mp4"},
        @{@"name": @"歌团★118", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240107389699.mp4"},
        @{@"name": @"歌团★119", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240345787129.mp4"},
        @{@"name": @"歌团★120", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240227966801.mp4"},
        @{@"name": @"歌团★121", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240228462625.mp4"},
        @{@"name": @"歌团★122", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240108721427.mp4"},
        @{@"name": @"歌团★123", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240001176191.mp4"},
        @{@"name": @"歌团★125", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240001228776.mp4"},
        @{@"name": @"歌团★126", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240109533631.mp4"},
        @{@"name": @"歌团★127", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240347663598.mp4"},
        @{@"name": @"歌团★128", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240001932458.mp4"},
        @{@"name": @"歌团★129", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240002044738.mp4"},
        @{@"name": @"歌团★130", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240111085001.mp4"},
        @{@"name": @"歌团★131", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240350575186.mp4"},
        @{@"name": @"歌团★132", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240350771160.mp4"},
        @{@"name": @"歌团★133", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240113261859.mp4"},
        @{@"name": @"歌团★134", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240352039996.mp4"},
        @{@"name": @"歌团★135", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240236014123.mp4"},
        @{@"name": @"歌团★136", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240008036293.mp4"},
        @{@"name": @"歌团★137", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240354863286.mp4"},
        @{@"name": @"歌团★138", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240008780109.mp4"},
        @{@"name": @"歌团★139", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240009608741.mp4"},
        @{@"name": @"歌团★140", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240379515679.mp4"},
        @{@"name": @"歌团★141", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240262842385.mp4"},
        @{@"name": @"歌团★142", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240264262344.mp4"},
        @{@"name": @"歌团★143", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240384227055.mp4"},
        @{@"name": @"歌团★145", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240267170778.mp4"},
        @{@"name": @"歌团★146", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240386743317.mp4"},
        @{@"name": @"歌团★147", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240268654616.mp4"},
        @{@"name": @"歌团★148", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240387107547.mp4"},
        @{@"name": @"歌团★149", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240150573492.mp4"},
        @{@"name": @"歌团★150", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240388683474.mp4"},
        @{@"name": @"歌团★151", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240270774376.mp4"},
        @{@"name": @"歌团★152", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240151273206.mp4"},
        @{@"name": @"歌团★153", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240389031565.mp4"},
        @{@"name": @"韩国太妍02", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240167997205.mp4"},
        @{@"name": @"韩国太妍03", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240059400880.mp4"},
        @{@"name": @"韩国太妍04", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240407847242.mp4"},
        @{@"name": @"韩国太妍05", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240062596020.mp4"},
        @{@"name": @"韩国太妍06", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240170661907.mp4"},
        @{@"name": @"韩国太妍07", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240411259014.mp4"},
        @{@"name": @"韩国太妍08", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240174309994.mp4"},
        @{@"name": @"韩国太妍09", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240175225325.mp4"},
        @{@"name": @"韩国太妍10", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240066736888.mp4"},
        @{@"name": @"韩国太妍11", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240175161903.mp4"},
        @{@"name": @"韩国太妍12", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240295526170.mp4"},
        @{@"name": @"韩国太妍13", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240295818399.mp4"},
        @{@"name": @"韩国太妍14", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240177321736.mp4"},
        @{@"name": @"韩国太妍15", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240177941288.mp4"},
        @{@"name": @"韩国太妍16", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240070652257.mp4"},
        @{@"name": @"韩国太妍17", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240298266546.mp4"},
        @{@"name": @"韩国太妍18", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240070884570.mp4"},
        @{@"name": @"韩国太妍19", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240298694512.mp4"},
        @{@"name": @"韩国太妍20", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240418087243.mp4"},
        @{@"name": @"韩国太妍21", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240299394846.mp4"},
        @{@"name": @"韩国太妍22", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240181409471.mp4"},
        @{@"name": @"韩国太妍23", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240182993056.mp4"},
        @{@"name": @"韩国太妍24", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240301854532.mp4"},
        @{@"name": @"韩国太妍25", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240075164377.mp4"},
        @{@"name": @"韩国太妍26", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240349762400.mp4"},
        @{@"name": @"韩国太妍27", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240121912724.mp4"},
        @{@"name": @"韩国太妍28", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240126480392.mp4"},
        @{@"name": @"韩国太妍29", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240355262537.mp4"},
        @{@"name": @"韩国太妍30", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240355734488.mp4"},
        @{@"name": @"韩国太妍31", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240237453313.mp4"},
        @{@"name": @"韩国太妍32", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240130092025.mp4"},
        @{@"name": @"韩国太妍33", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240478207039.mp4"},
        @{@"name": @"韩国太妍34", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240361330093.mp4"},
        @{@"name": @"韩国太妍35", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240139316317.mp4"},
        @{@"name": @"韩国太妍36", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240248465975.mp4"},
        @{@"name": @"韩国太妍37", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240139720035.mp4"},
        @{@"name": @"韩国太妍38", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240368550193.mp4"},
        @{@"name": @"韩国太妍40", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240370230905.mp4"},
        @{@"name": @"韩国太妍41", @"url": @"https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240160716008.mp4"},
        @{@"name": @"献血车(本地)", @"url": [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"mpeg4_local" ofType:@"mp4"]].absoluteString},
        @{@"name": @"某办公楼", @"url": [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"1650855755919" ofType:@"mp4"]].absoluteString}
    ];
    
    // 示例字幕（实际使用时替换为真实URL）
    self.subtitleList = @[
        [NSURL URLWithString:@"https://example.com/subtitle1.srt"],
        [NSURL URLWithString:@"https://example.com/subtitle2.srt"],
        [NSURL URLWithString:@"https://example.com/subtitle3.srt"]
    ];
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
