//
//  WYTestAudioController.m
//  Verify
//
//  Created by guanren on 2026/1/13.
//

#import "WYTestAudioController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>

#pragma mark - 声波动画视图 (WYVoiceWaveView)

/// 声波动画视图，用于实时显示录音音量
@interface WYVoiceWaveView : UIView

/// 更新音量能量值（归一化 0~1）
- (void)updatePower:(CGFloat)normalizedPower;

/// 开始动画（实际由 DisplayLink 持续驱动）
- (void)startAnimating;

/// 停止动画
- (void)stopAnimating;

@end

@interface WYVoiceWaveView ()

@property (nonatomic, assign) NSInteger barCount;
@property (nonatomic, assign) CGFloat barWidth;
@property (nonatomic, assign) CGFloat barSpacing;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *barHeights;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *targetHeights;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CGFloat smoothing;

@end

@implementation WYVoiceWaveView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _barCount = 20;
        _barWidth = 3.0;
        _barSpacing = 2.0;
        _smoothing = 0.6;
        _barHeights = [NSMutableArray arrayWithCapacity:_barCount];
        _targetHeights = [NSMutableArray arrayWithCapacity:_barCount];
        for (NSInteger i = 0; i < _barCount; i++) {
            [_barHeights addObject:@0];
            [_targetHeights addObject:@0];
        }
        [self startDisplayLink];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _barCount = 20;
        _barWidth = 3.0;
        _barSpacing = 2.0;
        _smoothing = 0.6;
        _barHeights = [NSMutableArray arrayWithCapacity:_barCount];
        _targetHeights = [NSMutableArray arrayWithCapacity:_barCount];
        for (NSInteger i = 0; i < _barCount; i++) {
            [_barHeights addObject:@0];
            [_targetHeights addObject:@0];
        }
        [self startDisplayLink];
    }
    return self;
}

- (void)updatePower:(CGFloat)normalizedPower {
    CGFloat power = MAX(0, MIN(1, normalizedPower));
    CGFloat maxHeight = self.bounds.size.height > 0 ? self.bounds.size.height : 60;
    for (NSInteger i = 0; i < self.barCount; i++) {
        CGFloat factor = sin((CGFloat)i / (CGFloat)self.barCount * M_PI);
        CGFloat target = maxHeight * power * factor;
        self.targetHeights[i] = @(MAX(1, target));
    }
}

- (void)startAnimating {
    // DisplayLink 已持续运行，无需额外操作
}

- (void)stopAnimating {
    // 无需停止 DisplayLink，因为视图可能被复用；但外部可调用，这里留空
}

- (void)startDisplayLink {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateHeights)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)updateHeights {
    BOOL needsRedraw = NO;
    for (NSInteger i = 0; i < self.barCount; i++) {
        CGFloat current = self.barHeights[i].floatValue;
        CGFloat target = self.targetHeights[i].floatValue;
        CGFloat diff = target - current;
        if (diff < -8) {
            self.barHeights[i] = @(target);
            needsRedraw = YES;
        } else if (fabs(diff) > 0.1) {
            current += diff * self.smoothing;
            self.barHeights[i] = @(current);
            needsRedraw = YES;
        } else {
            self.barHeights[i] = @(target);
        }
    }
    if (needsRedraw) {
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return;
    
    CGFloat maxHeight = self.bounds.size.height;
    CGFloat totalWidth = self.barCount * self.barWidth + (self.barCount - 1) * self.barSpacing;
    CGFloat x = (self.bounds.size.width - totalWidth) / 2;
    CGContextSetFillColorWithColor(context, [UIColor systemBlueColor].CGColor);
    
    for (NSInteger i = 0; i < self.barCount; i++) {
        CGFloat height = self.barHeights[i].floatValue;
        CGFloat y = maxHeight - height;
        CGRect barRect = CGRectMake(x, y, self.barWidth, height);
        CGContextFillRect(context, barRect);
        x += self.barWidth + self.barSpacing;
    }
}

- (void)dealloc {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

@end

#pragma mark - 下载任务卡片视图 (DownloadTaskCardView)

/// 单个下载任务的卡片视图，包含 URL 输入、进度条、控制按钮
@interface DownloadTaskCardView : UIView

@property (nonatomic, strong) UITextField *urlTextField;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) UIButton *pauseButton;
@property (nonatomic, strong) UIButton *resumeButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, strong, readonly) NSURL *url;

@end

@implementation DownloadTaskCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (NSURL *)url {
    NSString *text = self.urlTextField.text;
    return text.length ? [NSURL URLWithString:text] : nil;
}

- (void)setupUI {
    self.backgroundColor = [UIColor systemGray6Color];
    self.layer.cornerRadius = 8;
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.urlTextField = [[UITextField alloc] init];
    self.urlTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.urlTextField.placeholder = @"音频URL";
    self.urlTextField.font = [UIFont systemFontOfSize:12];
    
    self.progressLabel = [[UILabel alloc] init];
    self.progressLabel.font = [UIFont systemFontOfSize:12];
    self.progressLabel.text = @"进度: 0%";
    
    self.progressBar = [[UIProgressView alloc] init];
    self.progressBar.progressTintColor = [UIColor systemGreenColor];
    
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.downloadButton setTitle:@"下载" forState:UIControlStateNormal];
    self.downloadButton.titleLabel.font = [UIFont systemFontOfSize:12];
    
    self.pauseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.pauseButton setTitle:@"暂停" forState:UIControlStateNormal];
    self.pauseButton.titleLabel.font = [UIFont systemFontOfSize:12];
    
    self.resumeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.resumeButton setTitle:@"恢复" forState:UIControlStateNormal];
    self.resumeButton.titleLabel.font = [UIFont systemFontOfSize:12];
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:12];
    
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.deleteButton setTitle:@"删除" forState:UIControlStateNormal];
    self.deleteButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.deleteButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    UIStackView *buttonStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.downloadButton, self.pauseButton, self.resumeButton, self.cancelButton, self.deleteButton
    ]];
    buttonStack.axis = UILayoutConstraintAxisHorizontal;
    buttonStack.distribution = UIStackViewDistributionFillEqually;
    buttonStack.spacing = 6;
    
    UIStackView *mainStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.urlTextField, self.progressLabel, self.progressBar, buttonStack
    ]];
    mainStack.axis = UILayoutConstraintAxisVertical;
    mainStack.spacing = 6;
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:mainStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [mainStack.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
        [mainStack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8],
        [mainStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
        [mainStack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8]
    ]];
}

@end

#pragma mark - 主控制器

@interface WYTestAudioController () <WYAudioKitDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

// 音频工具实例
@property (nonatomic, strong) WYAudioKit *audioKit;

// 界面元素
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UITextView *infoTextView;

// 录音控制
@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIButton *pauseRecordButton;
@property (nonatomic, strong) UIButton *stopRecordButton;
@property (nonatomic, strong) UIButton *resumeRecordButton;
@property (nonatomic, strong) WYVoiceWaveView *voiceWaveView;

// 播放控制
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *pausePlayButton;
@property (nonatomic, strong) UIButton *stopPlayButton;
@property (nonatomic, strong) UIButton *resumePlayButton;
@property (nonatomic, strong) UIButton *seekButton;
@property (nonatomic, strong) UISlider *seekSlider;
@property (nonatomic, strong) UISlider *rateSlider;
@property (nonatomic, strong) UILabel *rateLabel;

// 进度显示
@property (nonatomic, strong) UILabel *recordProgressLabel;
@property (nonatomic, strong) UILabel *playProgressLabel;
@property (nonatomic, strong) UILabel *downloadProgressLabel;
@property (nonatomic, strong) UILabel *conversionProgressLabel;

// 设置控件
@property (nonatomic, strong) UISlider *minDurationSlider;
@property (nonatomic, strong) UISlider *maxDurationSlider;
@property (nonatomic, strong) UILabel *minDurationLabel;
@property (nonatomic, strong) UILabel *maxDurationLabel;
@property (nonatomic, strong) UISegmentedControl *qualitySegmentedControl;
@property (nonatomic, strong) UIPickerView *formatPicker;
@property (nonatomic, strong) UISegmentedControl *storageDirSegmentedControl;

// 网络音频 - 单任务
@property (nonatomic, strong) UITextField *remoteURLField;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) UIButton *streamingButton;

// 网络音频 - 多任务下载
@property (nonatomic, strong) UIView *downloadTasksContainer;
@property (nonatomic, strong) UIButton *addTaskButton;
@property (nonatomic, strong) NSMutableArray<DownloadTaskCardView *> *taskCards;
@property (nonatomic, strong) NSLayoutConstraint *containerHeightConstraint;

// 文件管理
@property (nonatomic, strong) UILabel *fileLabel;
@property (nonatomic, strong) UITextView *fileListTextView;
@property (nonatomic, strong) UIButton *refreshFilesButton;
@property (nonatomic, strong) UIButton *saveRecordButton;
@property (nonatomic, strong) UIButton *deleteRecordButton;
@property (nonatomic, strong) UIButton *deleteAllRecordingsButton;
@property (nonatomic, strong) UIButton *deleteAllDownloadsButton;

// 格式转换
@property (nonatomic, strong) UILabel *convertLabel;
@property (nonatomic, strong) UIPickerView *targetFormatPicker;
@property (nonatomic, strong) UIButton *convertButton;

// 其他功能
@property (nonatomic, strong) UIButton *playRecordedButton;
@property (nonatomic, strong) UIButton *customSettingsButton;
@property (nonatomic, strong) UIButton *releaseButton;

// 数据
@property (nonatomic, strong) NSArray<NSNumber *> *supportedFormats;          // 所有格式
@property (nonatomic, strong) NSArray<NSNumber *> *supportedConvertFormats;   // 支持转换的格式
@property (nonatomic, assign) WYAudioFormat selectedFormat;
@property (nonatomic, assign) WYAudioFormat targetFormat;
@property (nonatomic, assign) NSTimeInterval minRecordingDuration;
@property (nonatomic, assign) NSTimeInterval maxRecordingDuration;
@property (nonatomic, assign) NSTimeInterval currentPlayingDuration;  // 当前播放音频总时长，用于 seek

@end

@implementation WYTestAudioController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"音频工具测试";
    
    // 初始化数据
    self.minRecordingDuration = 0;
    self.maxRecordingDuration = 60;
    self.selectedFormat = WYAudioFormatAac;
    self.targetFormat = WYAudioFormatMp3;
    self.currentPlayingDuration = 0;
    self.taskCards = [NSMutableArray array];
    
    [self setupUI];
    [self setupAudioKit];
    [self refreshFileList];
    [self addDefaultDownloadTasks];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollView.contentSize = self.contentView.frame.size;
}

#pragma mark - 初始化

- (void)setupAudioKit {
    self.audioKit = [[WYAudioKit alloc] init];
    self.audioKit.delegate = self;
    self.audioKit.minimumRecordDuration = self.minRecordingDuration;
    self.audioKit.maximumRecordDuration = self.maxRecordingDuration;
    
    // 请求录音权限
    [WYMicrophoneAuthorization authorizeMicrophoneAccessWithShowSettingsAlert:YES completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *status = granted ? @"已授权" : @"未授权";
            [self logInfo:[NSString stringWithFormat:@"录音权限: %@", status]];
        });
    }];
}

- (void)addDefaultDownloadTasks {
    NSArray *urls = @[
        @"http://music.163.com/song/media/outer/url?id=1466027974.mp3",
        @"http://music.163.com/song/media/outer/url?id=2105354877.mp3"
    ];
    for (NSString *urlString in urls) {
        [self addDownloadTaskWithUrlString:urlString];
    }
}

- (void)addDownloadTaskWithUrlString:(NSString *)urlString {
    DownloadTaskCardView *card = [[DownloadTaskCardView alloc] init];
    card.urlTextField.text = urlString;
    [card.downloadButton addTarget:self action:@selector(downloadTaskAction:) forControlEvents:UIControlEventTouchUpInside];
    [card.pauseButton addTarget:self action:@selector(pauseTaskAction:) forControlEvents:UIControlEventTouchUpInside];
    [card.resumeButton addTarget:self action:@selector(resumeTaskAction:) forControlEvents:UIControlEventTouchUpInside];
    [card.cancelButton addTarget:self action:@selector(cancelTaskAction:) forControlEvents:UIControlEventTouchUpInside];
    [card.deleteButton addTarget:self action:@selector(deleteTaskAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.downloadTasksContainer addSubview:card];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    
    DownloadTaskCardView *lastCard = self.taskCards.lastObject;
    NSLayoutConstraint *topConstraint;
    if (lastCard) {
        topConstraint = [card.topAnchor constraintEqualToAnchor:lastCard.bottomAnchor constant:12];
    } else {
        topConstraint = [card.topAnchor constraintEqualToAnchor:self.downloadTasksContainer.topAnchor];
    }
    [NSLayoutConstraint activateConstraints:@[
        topConstraint,
        [card.leadingAnchor constraintEqualToAnchor:self.downloadTasksContainer.leadingAnchor],
        [card.trailingAnchor constraintEqualToAnchor:self.downloadTasksContainer.trailingAnchor]
    ]];
    
    [self.taskCards addObject:card];
    [self updateContainerHeight];
    [self refreshLayoutAfterTaskChange];
}

- (void)updateContainerHeight {
    [self.downloadTasksContainer layoutIfNeeded];
    CGFloat totalHeight = 0;
    for (DownloadTaskCardView *card in self.taskCards) {
        totalHeight += card.frame.size.height + 12;
    }
    if (self.taskCards.count > 0) {
        totalHeight -= 12;
    }
    self.containerHeightConstraint.constant = MAX(totalHeight, 0);
    [self.view layoutIfNeeded];
}

#pragma mark - UI 布局

- (void)setupUI {
    // 滚动视图
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, [UIDevice wy_navViewHeight], [UIDevice wy_screenWidth], [UIDevice wy_screenHeight] - [UIDevice wy_navViewHeight])];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.scrollView.frame.size.height)];
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self.scrollView addSubview:self.contentView];
    
    CGFloat yOffset = 20;
    
    // 信息文本框
    self.infoTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 190)];
    self.infoTextView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.infoTextView.textColor = [UIColor blackColor];
    self.infoTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.infoTextView.layer.borderWidth = 1;
    self.infoTextView.layer.cornerRadius = 8;
    self.infoTextView.font = [UIFont systemFontOfSize:14];
    self.infoTextView.editable = NO;
    self.infoTextView.text = @"操作日志将显示在这里...\n";
    [self.contentView addSubview:self.infoTextView];
    yOffset += 200;
    
    // 格式选择器
    UILabel *formatLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, 200, 30)];
    formatLabel.text = @"选择录音格式:";
    [self.contentView addSubview:formatLabel];
    yOffset += 30;
    self.formatPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 100)];
    self.formatPicker.backgroundColor = [UIColor whiteColor];
    self.formatPicker.dataSource = self;
    self.formatPicker.delegate = self;
    [self.contentView addSubview:self.formatPicker];
    yOffset += 110;
    
    // 存储目录
    UILabel *storageDirLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, 200, 30)];
    storageDirLabel.text = @"存储目录:";
    [self.contentView addSubview:storageDirLabel];
    yOffset += 30;
    self.storageDirSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"临时", @"文档", @"缓存"]];
    self.storageDirSegmentedControl.frame = CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 30);
    self.storageDirSegmentedControl.selectedSegmentIndex = 0;
    [self.storageDirSegmentedControl addTarget:self action:@selector(storageDirChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.storageDirSegmentedControl];
    yOffset += 40;
    
    // 录音控制
    UILabel *recordLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, 200, 30)];
    recordLabel.text = @"录音控制:";
    [self.contentView addSubview:recordLabel];
    yOffset += 30;
    self.recordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.recordButton.frame = CGRectMake(20, yOffset, 80, 40);
    [self.recordButton setTitle:@"开始录音" forState:UIControlStateNormal];
    [self.recordButton addTarget:self action:@selector(startRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.recordButton];
    
    self.pauseRecordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.pauseRecordButton.frame = CGRectMake(110, yOffset, 80, 40);
    [self.pauseRecordButton setTitle:@"暂停录音" forState:UIControlStateNormal];
    [self.pauseRecordButton addTarget:self action:@selector(pauseRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.pauseRecordButton];
    
    self.resumeRecordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.resumeRecordButton.frame = CGRectMake(200, yOffset, 80, 40);
    [self.resumeRecordButton setTitle:@"恢复录音" forState:UIControlStateNormal];
    [self.resumeRecordButton addTarget:self action:@selector(resumeRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.resumeRecordButton];
    
    self.stopRecordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.stopRecordButton.frame = CGRectMake(290, yOffset, 80, 40);
    [self.stopRecordButton setTitle:@"停止录音" forState:UIControlStateNormal];
    [self.stopRecordButton addTarget:self action:@selector(stopRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.stopRecordButton];
    yOffset += 50;
    
    self.recordProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 30)];
    self.recordProgressLabel.textColor = [UIColor blackColor];
    self.recordProgressLabel.text = @"录音进度: 0.0秒/0.0秒";
    [self.contentView addSubview:self.recordProgressLabel];
    yOffset += 40;
    
    self.voiceWaveView = [[WYVoiceWaveView alloc] initWithFrame:CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 60)];
    self.voiceWaveView.backgroundColor = [UIColor systemGray5Color];
    self.voiceWaveView.layer.cornerRadius = 8;
    [self.contentView addSubview:self.voiceWaveView];
    yOffset += 70;
    
    self.playRecordedButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.playRecordedButton.frame = CGRectMake(20, yOffset, 150, 40);
    [self.playRecordedButton setTitle:@"播放录音文件" forState:UIControlStateNormal];
    [self.playRecordedButton addTarget:self action:@selector(playRecordedFile) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.playRecordedButton];
    yOffset += 50;
    
    // 播放控制
    UILabel *playLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, 200, 30)];
    playLabel.text = @"播放控制:";
    [self.contentView addSubview:playLabel];
    yOffset += 30;
    self.playButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.playButton.frame = CGRectMake(20, yOffset, 150, 40);
    [self.playButton setTitle:@"播放本地音频" forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playLocalAudio) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.playButton];
    
    self.pausePlayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.pausePlayButton.frame = CGRectMake(180, yOffset, 80, 40);
    [self.pausePlayButton setTitle:@"暂停播放" forState:UIControlStateNormal];
    [self.pausePlayButton addTarget:self action:@selector(pausePlayback) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.pausePlayButton];
    
    self.stopPlayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.stopPlayButton.frame = CGRectMake(270, yOffset, 80, 40);
    [self.stopPlayButton setTitle:@"停止播放" forState:UIControlStateNormal];
    [self.stopPlayButton addTarget:self action:@selector(stopPlayback) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.stopPlayButton];
    yOffset += 50;
    
    self.resumePlayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.resumePlayButton.frame = CGRectMake(20, yOffset, 80, 40);
    [self.resumePlayButton setTitle:@"恢复播放" forState:UIControlStateNormal];
    [self.resumePlayButton addTarget:self action:@selector(resumePlayback) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.resumePlayButton];
    
    self.seekSlider = [[UISlider alloc] initWithFrame:CGRectMake(110, yOffset, 150, 40)];
    self.seekSlider.minimumValue = 0;
    self.seekSlider.maximumValue = 1;
    [self.contentView addSubview:self.seekSlider];
    
    self.seekButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.seekButton.frame = CGRectMake(270, yOffset, 80, 40);
    [self.seekButton setTitle:@"跳转播放" forState:UIControlStateNormal];
    [self.seekButton addTarget:self action:@selector(seekPlayback) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.seekButton];
    yOffset += 50;
    
    // 倍速控制
    UILabel *rateLabelTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, 100, 30)];
    rateLabelTitle.text = @"播放倍速:";
    [self.contentView addSubview:rateLabelTitle];
    self.rateSlider = [[UISlider alloc] initWithFrame:CGRectMake(120, yOffset, 150, 30)];
    self.rateSlider.minimumValue = 0.5;
    self.rateSlider.maximumValue = 2.0;
    self.rateSlider.value = 1.0;
    [self.rateSlider addTarget:self action:@selector(rateChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.rateSlider];
    self.rateLabel = [[UILabel alloc] initWithFrame:CGRectMake(280, yOffset, 40, 30)];
    self.rateLabel.text = @"1.0x";
    [self.contentView addSubview:self.rateLabel];
    yOffset += 40;
    
    self.playProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 30)];
    self.playProgressLabel.text = @"播放进度: 0.0秒/0.0秒 (0.0%)";
    [self.contentView addSubview:self.playProgressLabel];
    yOffset += 40;
    
    // 时长设置
    UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, 200, 30)];
    durationLabel.text = @"录音时长设置:";
    [self.contentView addSubview:durationLabel];
    yOffset += 30;
    self.minDurationSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 30)];
    self.minDurationSlider.minimumValue = 0;
    self.minDurationSlider.maximumValue = 60;
    self.minDurationSlider.value = 0;
    [self.minDurationSlider addTarget:self action:@selector(minDurationChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.minDurationSlider];
    yOffset += 35;
    self.minDurationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 30)];
    [self.contentView addSubview:self.minDurationLabel];
    yOffset += 40;
    self.maxDurationSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 30)];
    self.maxDurationSlider.minimumValue = 1;
    self.maxDurationSlider.maximumValue = 300;
    self.maxDurationSlider.value = 60;
    [self.maxDurationSlider addTarget:self action:@selector(maxDurationChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.maxDurationSlider];
    yOffset += 35;
    self.maxDurationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 30)];
    [self.contentView addSubview:self.maxDurationLabel];
    yOffset += 50;
    
    UILabel *qualityLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, 200, 30)];
    qualityLabel.text = @"音频质量:";
    [self.contentView addSubview:qualityLabel];
    yOffset += 30;
    self.qualitySegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"低", @"中", @"高"]];
    self.qualitySegmentedControl.frame = CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 30);
    self.qualitySegmentedControl.selectedSegmentIndex = 2;
    [self.qualitySegmentedControl addTarget:self action:@selector(qualityChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.qualitySegmentedControl];
    yOffset += 50;
    
    // 网络音频测试（单个下载 + 流式播放）
    UILabel *remoteLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, 200, 30)];
    remoteLabel.text = @"网络音频测试:";
    [self.contentView addSubview:remoteLabel];
    yOffset += 30;
    self.remoteURLField = [[UITextField alloc] initWithFrame:CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 40)];
    self.remoteURLField.borderStyle = UITextBorderStyleRoundedRect;
    self.remoteURLField.placeholder = @"输入音频URL（单个）";
    self.remoteURLField.text = @"http://music.163.com/song/media/outer/url?id=2105354877.mp3";
    [self.contentView addSubview:self.remoteURLField];
    yOffset += 50;
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.downloadButton.frame = CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 40);
    [self.downloadButton setTitle:@"下载并播放" forState:UIControlStateNormal];
    [self.downloadButton addTarget:self action:@selector(downloadAndPlay) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.downloadButton];
    yOffset += 50;
    self.streamingButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.streamingButton.frame = CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 40);
    [self.streamingButton setTitle:@"流式播放（边下边播）" forState:UIControlStateNormal];
    [self.streamingButton addTarget:self action:@selector(testStreaming) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.streamingButton];
    yOffset += 50;
    self.downloadProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 30)];
    self.downloadProgressLabel.text = @"下载进度: 0.0%";
    [self.contentView addSubview:self.downloadProgressLabel];
    yOffset += 50;
    
    // 多任务下载列表
    UILabel *multiTaskLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, 200, 30)];
    multiTaskLabel.text = @"多任务下载列表:";
    [self.contentView addSubview:multiTaskLabel];
    yOffset += 30;
    
    self.addTaskButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.addTaskButton.frame = CGRectMake(self.view.bounds.size.width - 100, yOffset - 30, 80, 30);
    [self.addTaskButton setTitle:@"添加任务" forState:UIControlStateNormal];
    [self.addTaskButton addTarget:self action:@selector(addTaskButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.addTaskButton];
    
    self.downloadTasksContainer = [[UIView alloc] initWithFrame:CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 0)];
    self.downloadTasksContainer.backgroundColor = [UIColor clearColor];
    self.downloadTasksContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.downloadTasksContainer];
    [NSLayoutConstraint activateConstraints:@[
        [self.downloadTasksContainer.topAnchor constraintEqualToAnchor:multiTaskLabel.bottomAnchor constant:8],
        [self.downloadTasksContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [self.downloadTasksContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20]
    ]];
    self.containerHeightConstraint = [self.downloadTasksContainer.heightAnchor constraintEqualToConstant:0];
    self.containerHeightConstraint.active = YES;
    
    // 以下控件位置动态计算，先创建，稍后统一刷新布局
    self.fileLabel = [[UILabel alloc] init];
    self.fileLabel.text = @"录音文件列表:";
    [self.contentView addSubview:self.fileLabel];
    
    self.refreshFilesButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.refreshFilesButton setTitle:@"刷新列表" forState:UIControlStateNormal];
    [self.refreshFilesButton addTarget:self action:@selector(refreshFileList) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.refreshFilesButton];
    
    self.fileListTextView = [[UITextView alloc] init];
    self.fileListTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.fileListTextView.layer.borderWidth = 1;
    self.fileListTextView.layer.cornerRadius = 8;
    self.fileListTextView.font = [UIFont systemFontOfSize:12];
    self.fileListTextView.editable = NO;
    [self.contentView addSubview:self.fileListTextView];
    
    self.saveRecordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.saveRecordButton setTitle:@"保存录音" forState:UIControlStateNormal];
    [self.saveRecordButton addTarget:self action:@selector(saveRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.saveRecordButton];
    
    self.deleteRecordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.deleteRecordButton setTitle:@"删除录音" forState:UIControlStateNormal];
    [self.deleteRecordButton addTarget:self action:@selector(deleteRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.deleteRecordButton];
    
    self.deleteAllRecordingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.deleteAllRecordingsButton setTitle:@"删除所有录音" forState:UIControlStateNormal];
    [self.deleteAllRecordingsButton addTarget:self action:@selector(deleteAllRecordings) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.deleteAllRecordingsButton];
    
    self.deleteAllDownloadsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.deleteAllDownloadsButton setTitle:@"删除所有下载" forState:UIControlStateNormal];
    [self.deleteAllDownloadsButton addTarget:self action:@selector(deleteAllDownloads) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.deleteAllDownloadsButton];
    
    self.convertLabel = [[UILabel alloc] init];
    self.convertLabel.text = @"格式转换:";
    [self.contentView addSubview:self.convertLabel];
    
    self.targetFormatPicker = [[UIPickerView alloc] init];
    self.targetFormatPicker.dataSource = self;
    self.targetFormatPicker.delegate = self;
    [self.contentView addSubview:self.targetFormatPicker];
    
    self.convertButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.convertButton setTitle:@"转换音频文件格式" forState:UIControlStateNormal];
    [self.convertButton addTarget:self action:@selector(convertAudio) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.convertButton];
    
    self.conversionProgressLabel = [[UILabel alloc] init];
    self.conversionProgressLabel.text = @"转换进度: 0.0%";
    [self.contentView addSubview:self.conversionProgressLabel];
    
    self.customSettingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.customSettingsButton setTitle:@"自定义录音设置" forState:UIControlStateNormal];
    [self.customSettingsButton addTarget:self action:@selector(setCustomSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.customSettingsButton];
    
    self.releaseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.releaseButton setTitle:@"释放资源" forState:UIControlStateNormal];
    [self.releaseButton addTarget:self action:@selector(releaseResources) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.releaseButton];
    
    // 设置一个足够大的初始高度，避免滚动问题
    self.contentView.frame = CGRectMake(0, 0, self.view.bounds.size.width, yOffset + 600);
    [self refreshLayoutAfterTaskChange];
}

- (void)refreshLayoutAfterTaskChange {
    [self.downloadTasksContainer layoutIfNeeded];
    // 动态计算所有控件位置（基于下载任务容器底部）
    CGFloat containerBottom = CGRectGetMaxY(self.downloadTasksContainer.frame);
    CGFloat yOffset = containerBottom + 20;
    
    // 文件管理区域
    self.fileLabel.frame = CGRectMake(20, yOffset, 200, 30);
    self.refreshFilesButton.frame = CGRectMake(self.view.bounds.size.width - 120, yOffset, 100, 30);
    yOffset += 40;
    self.fileListTextView.frame = CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 150);
    yOffset += 160;
    self.saveRecordButton.frame = CGRectMake(20, yOffset, 100, 40);
    self.deleteRecordButton.frame = CGRectMake(130, yOffset, 100, 40);
    self.deleteAllRecordingsButton.frame = CGRectMake(240, yOffset, 120, 40);
    yOffset += 50;
    self.deleteAllDownloadsButton.frame = CGRectMake(20, yOffset, 150, 40);
    yOffset += 50;
    
    // 格式转换区域
    self.convertLabel.frame = CGRectMake(20, yOffset, 200, 30);
    yOffset += 30;
    self.targetFormatPicker.frame = CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 100);
    yOffset += 110;
    self.convertButton.frame = CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 40);
    yOffset += 50;
    self.conversionProgressLabel.frame = CGRectMake(20, yOffset, self.view.bounds.size.width - 40, 30);
    yOffset += 40;
    
    // 其他功能
    self.customSettingsButton.frame = CGRectMake(20, yOffset, 150, 40);
    self.releaseButton.frame = CGRectMake(180, yOffset, 100, 40);
    yOffset += 50;
    
    // 更新 contentView 高度
    self.contentView.frame = CGRectMake(0, 0, self.view.bounds.size.width, yOffset + 100);
    self.scrollView.contentSize = self.contentView.frame.size;
}

#pragma mark - 日志

- (void)logInfo:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterNoStyle;
        formatter.timeStyle = NSDateFormatterMediumStyle;
        NSString *timestamp = [formatter stringFromDate:[NSDate date]];
        NSString *log = [NSString stringWithFormat:@"%@: %@\n", timestamp, message];
        self.infoTextView.text = [self.infoTextView.text stringByAppendingString:log];
        NSRange bottom = NSMakeRange(self.infoTextView.text.length - 1, 1);
        [self.infoTextView scrollRangeToVisible:bottom];
        NSLog(@"log = %@", log);
    });
}

#pragma mark - 录音控制

- (void)startRecording {
    NSError *error;
    [self.audioKit startRecordingWithFileName:nil format:self.selectedFormat error:&error];
    if (error) {
        [self handleError:error];
    }
}

- (void)pauseRecording {
    NSError *error;
    [self.audioKit pauseRecordingWithError:&error];
    if (error) {
        [self handleError:error];
    }
}

- (void)resumeRecording {
    NSError *error;
    [self.audioKit resumeRecordingWithError:&error];
    if (error) {
        [self handleError:error];
    }
}

- (void)stopRecording {
    NSError *error;
    [self.audioKit stopRecordingWithError:&error];
    if (error) {
        [self handleError:error];
    }
}

#pragma mark - 播放控制

- (void)playLocalAudio {
    NSURL *testFileURL = [[NSBundle mainBundle] URLForResource:@"世间美好与你环环相扣" withExtension:@"mp3"];
    if (testFileURL) {
        [self.audioKit playPlaybackWithUrl:testFileURL success:^(NSURL *playURL) {
            [self logInfo:[NSString stringWithFormat:@"本地音频播放成功: %@", playURL.lastPathComponent]];
        } failed:^(NSURL *playURL, NSError *error, NSString *description) {
            [self logInfo:[NSString stringWithFormat:@"本地音频播放失败: %@", error.localizedDescription ?: @"未知错误"]];
        }];
    } else {
        [self logInfo:@"测试音频文件未找到"];
    }
}

- (void)playRecordedFile {
    [self.audioKit playPlaybackWithUrl:nil success:^(NSURL *playURL) {
        [self logInfo:[NSString stringWithFormat:@"录音文件播放成功: %@", playURL.lastPathComponent]];
    } failed:^(NSURL *playURL, NSError *error, NSString *description) {
        [self logInfo:[NSString stringWithFormat:@"录音文件播放失败: %@", error.localizedDescription ?: @"未知错误"]];
    }];
}

- (void)pausePlayback {
    NSError *error;
    [self.audioKit pausePlaybackWithError:&error];
    if (error) {
        [self handleError:error];
    }
}

- (void)stopPlayback {
    [self.audioKit stopPlayback];
}

- (void)resumePlayback {
    NSError *error;
    [self.audioKit resumePlaybackWithError:&error];
    if (error) {
        [self handleError:error];
    }
}

- (void)seekPlayback {
    if (self.currentPlayingDuration <= 0) {
        [self logInfo:@"无法跳转：未获取到音频总时长"];
        return;
    }
    NSTimeInterval seekTime = self.seekSlider.value * self.currentPlayingDuration;
    [self.audioKit seekPlaybackWithTime:seekTime];
    [self logInfo:[NSString stringWithFormat:@"跳转到: %.1f秒", seekTime]];
}

- (void)rateChanged {
    float rate = self.rateSlider.value;
    self.audioKit.playbackRate = rate;
    self.rateLabel.text = [NSString stringWithFormat:@"%.1fx", rate];
    [self logInfo:[NSString stringWithFormat:@"设置播放倍速: %.1f", rate]];
}

#pragma mark - 设置控制

- (void)minDurationChanged {
    self.minRecordingDuration = self.minDurationSlider.value;
    self.audioKit.minimumRecordDuration = self.minRecordingDuration;
    self.minDurationLabel.text = [NSString stringWithFormat:@"最短时长: %.1f秒", self.minRecordingDuration];
    [self logInfo:[NSString stringWithFormat:@"设置最小录音时长: %.1f秒", self.minRecordingDuration]];
}

- (void)maxDurationChanged {
    self.maxRecordingDuration = self.maxDurationSlider.value;
    self.audioKit.maximumRecordDuration = self.maxRecordingDuration;
    self.maxDurationLabel.text = [NSString stringWithFormat:@"最长时长: %.1f秒", self.maxRecordingDuration];
    [self logInfo:[NSString stringWithFormat:@"设置最大录音时长: %.1f秒", self.maxRecordingDuration]];
}

- (void)qualityChanged {
    AVAudioQuality quality;
    switch (self.qualitySegmentedControl.selectedSegmentIndex) {
        case 0: quality = AVAudioQualityLow; break;
        case 1: quality = AVAudioQualityMedium; break;
        default: quality = AVAudioQualityHigh; break;
    }
    self.audioKit.recordQuality = quality;
    NSString *title = [self.qualitySegmentedControl titleForSegmentAtIndex:self.qualitySegmentedControl.selectedSegmentIndex] ?: @"";
    [self logInfo:[NSString stringWithFormat:@"设置音频质量: %@", title]];
}

- (void)storageDirChanged {
    WYAudioStorageDirectory directory;
    switch (self.storageDirSegmentedControl.selectedSegmentIndex) {
        case 0: directory = WYAudioStorageDirectoryTemporary; break;
        case 1: directory = WYAudioStorageDirectoryDocuments; break;
        default: directory = WYAudioStorageDirectoryCaches; break;
    }
    self.audioKit.recordingsDirectory = directory;
    [self logInfo:[NSString stringWithFormat:@"设置录音存储目录: %@", [self directoryDescriptionForDirectory:directory]]];
}

#pragma mark - 网络音频

- (void)downloadAndPlay {
    NSString *urlString = self.remoteURLField.text;
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [self logInfo:@"无效的URL"];
        return;
    }
    [self.audioKit playRemoteAudioWithRemoteUrl:url success:^(WYAudioDownloadInfo *info) {
        [self logInfo:[NSString stringWithFormat:@"网络音频播放成功,存储地址：%@", info.local.lastPathComponent]];
    } failed:^(NSError *error) {
        if (error) [self handleError:error];
    }];
}

- (void)testStreaming {
    NSString *urlString = self.remoteURLField.text;
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [self logInfo:@"无效的URL"];
        return;
    }
    [self.audioKit playStreamingRemoteAudioWithRemoteUrl:url rate:self.audioKit.playbackRate success:^(NSURL *remoteUrl) {
        [self logInfo:[NSString stringWithFormat:@"流式播放成功: %@", remoteUrl]];
    } failed:^(NSError *error) {
        [self logInfo:[NSString stringWithFormat:@"流式播放失败: %@", error.localizedDescription ?: @"未知错误"]];
    }];
}

#pragma mark - 多任务下载卡片事件

- (void)addTaskButtonTapped {
    [self addDownloadTaskWithUrlString:@""];
}

- (void)downloadTaskAction:(UIButton *)sender {
    DownloadTaskCardView *card = [self findCardFromButton:sender];
    if (!card || !card.url) return;
    [self.audioKit downloadRemoteAudioWithRemoteUrls:@[card.url] success:^(NSArray<WYAudioDownloadInfo *> *infos) {
        [self logInfo:[NSString stringWithFormat:@"下载成功: %@", infos.firstObject.local.lastPathComponent]];
    } failed:^(NSError *error) {
        [self logInfo:[NSString stringWithFormat:@"下载失败: %@", error.localizedDescription]];
    }];
}

- (void)pauseTaskAction:(UIButton *)sender {
    DownloadTaskCardView *card = [self findCardFromButton:sender];
    if (!card || !card.url) return;
    [self.audioKit pauseDownloadWithRemoteUrls:@[card.url] success:^(NSURL *url) {
        [self logInfo:[NSString stringWithFormat:@"暂停成功: %@", url]];
    } failed:^(NSURL *url, NSError *error) {
        [self logInfo:[NSString stringWithFormat:@"暂停失败: %@, 错误: %@", url, error.localizedDescription ?: @"未知"]];
    }];
}

- (void)resumeTaskAction:(UIButton *)sender {
    DownloadTaskCardView *card = [self findCardFromButton:sender];
    if (!card || !card.url) return;
    [self.audioKit resumeDownloadWithRemoteUrls:@[card.url]];
    [self logInfo:[NSString stringWithFormat:@"恢复下载: %@", card.url]];
}

- (void)cancelTaskAction:(UIButton *)sender {
    DownloadTaskCardView *card = [self findCardFromButton:sender];
    if (!card || !card.url) return;
    [self.audioKit cancelDownloadWithRemoteUrls:@[card.url]];
    [self logInfo:[NSString stringWithFormat:@"取消下载: %@", card.url]];
    card.progressBar.progress = 0;
    card.progressLabel.text = @"进度: 0%";
}

- (void)deleteTaskAction:(UIButton *)sender {
    DownloadTaskCardView *card = [self findCardFromButton:sender];
    if (!card) return;
    NSInteger index = [self.taskCards indexOfObject:card];
    if (index != NSNotFound) {
        if (card.url) {
            [self.audioKit cancelDownloadWithRemoteUrls:@[card.url]];
        }
        [card removeFromSuperview];
        [self.taskCards removeObjectAtIndex:index];
        // 重新约束剩余卡片
        for (NSInteger i = 0; i < self.taskCards.count; i++) {
            DownloadTaskCardView *c = self.taskCards[i];
            [c removeConstraints:c.constraints];
            c.translatesAutoresizingMaskIntoConstraints = NO;
            NSLayoutConstraint *top;
            if (i == 0) {
                top = [c.topAnchor constraintEqualToAnchor:self.downloadTasksContainer.topAnchor];
            } else {
                top = [c.topAnchor constraintEqualToAnchor:self.taskCards[i-1].bottomAnchor constant:12];
            }
            [NSLayoutConstraint activateConstraints:@[
                top,
                [c.leadingAnchor constraintEqualToAnchor:self.downloadTasksContainer.leadingAnchor],
                [c.trailingAnchor constraintEqualToAnchor:self.downloadTasksContainer.trailingAnchor]
            ]];
        }
        [self updateContainerHeight];
        [self refreshLayoutAfterTaskChange];
    }
}

- (DownloadTaskCardView *)findCardFromButton:(UIButton *)button {
    UIView *view = button.superview;
    while (view && ![view isKindOfClass:[DownloadTaskCardView class]]) {
        view = view.superview;
    }
    return (DownloadTaskCardView *)view;
}

#pragma mark - 文件管理

- (void)refreshFileList {
    NSArray<NSURL *> *recordings = [self.audioKit getAllRecordingsFiles];
    NSArray<WYAudioDownloadInfo *> *downloads = [self.audioKit getAllDownloads];
    
    NSMutableString *fileList = [NSMutableString string];
    [fileList appendFormat:@"录音文件 (%lu个):\n", (unsigned long)recordings.count];
    for (NSURL *url in recordings) {
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil];
        long long size = [attrs[NSFileSize] longLongValue] / 1024;
        [fileList appendFormat:@"%@ (%lld KB)\n", url.lastPathComponent, size];
    }
    [fileList appendFormat:@"\n下载文件 (%lu个):\n", (unsigned long)downloads.count];
    for (WYAudioDownloadInfo *info in downloads) {
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:info.local.path error:nil];
        long long size = [attrs[NSFileSize] longLongValue] / 1024;
        [fileList appendFormat:@"%@ (%lld KB)\n", info.local.lastPathComponent, size];
    }
    self.fileListTextView.text = fileList;
}

- (void)saveRecording {
    NSURL *docDir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSString *fileName = [NSString stringWithFormat:@"saved_audio_%.0f.%@", [[NSDate date] timeIntervalSince1970], [self stringValueForFormat:self.selectedFormat]];
    NSURL *destinationURL = [docDir URLByAppendingPathComponent:fileName];
    NSError *error;
    [self.audioKit saveRecordingWithDestinationUrl:destinationURL error:&error];
    if (error) {
        [self handleError:error];
    } else {
        [self logInfo:[NSString stringWithFormat:@"文件已保存到: %@", destinationURL.lastPathComponent]];
        [self refreshFileList];
    }
}

- (void)deleteRecording {
    NSError *error;
    [self.audioKit deleteRecordingFileWithLocalUrl:self.audioKit.currentRecordFileURL error:&error];
    if (error) {
        [self handleError:error];
    } else {
        [self logInfo:@"录音文件已删除"];
        [self refreshFileList];
    }
}

- (void)deleteAllRecordings {
    NSError *error;
    [self.audioKit deleteRecordingFileWithLocalUrl:nil error:&error];
    if (error) {
        [self handleError:error];
    } else {
        [self logInfo:@"所有录音文件已删除"];
        [self refreshFileList];
    }
}

- (void)deleteAllDownloads {
    NSArray<WYAudioDownloadInfo *> *downloads = [self.audioKit getAllDownloads];
    for (WYAudioDownloadInfo *info in downloads) {
        [self.audioKit deleteDownloadFileWithInfo:info];
    }
    [self logInfo:@"所有下载文件已删除"];
    [self refreshFileList];
    for (DownloadTaskCardView *card in self.taskCards) {
        card.progressBar.progress = 0;
        card.progressLabel.text = @"进度: 0%";
    }
}

#pragma mark - 格式转换

- (void)convertAudio {
    NSURL *sourceURL = self.audioKit.currentRecordFileURL;
    if (!sourceURL) {
        [self logInfo:@"没有可转换的录音文件"];
        return;
    }
    [self logInfo:[NSString stringWithFormat:@"开始转换格式: %@ -> %@", sourceURL.lastPathComponent, [self stringValueForFormat:self.targetFormat]]];
    [self.audioKit convertAudioFormatWithSourceUrls:@[sourceURL] target:self.targetFormat success:^(NSArray<NSURL *> *outputUrls) {
        for (NSURL *url in outputUrls) {
            [self logInfo:[NSString stringWithFormat:@"格式转换成功: %@", url.lastPathComponent]];
            [self refreshFileList];
        }
    } failed:^(NSError *error) {
        if (error) [self handleError:error];
    }];
}

#pragma mark - 其他功能

- (void)setCustomSettings {
    NSDictionary *customSettings = @{
        AVSampleRateKey: @22050.0,
        AVNumberOfChannelsKey: @2,
        AVEncoderBitRateKey: @64000
    };
    self.audioKit.recordSettings = customSettings;
    [self logInfo:@"设置自定义录音参数: 采样率22.05kHz, 比特率64kbps, 双声道"];
}

- (void)releaseResources {
    [self.audioKit releaseAll];
    [self logInfo:@"已释放所有音频资源"];
}

#pragma mark - 错误处理

- (void)handleError:(NSError *)error {
    if ([error.domain isEqualToString:@"WYAudioError"]) {
        WYAudioError audioError = (WYAudioError)error.code;
        [self logInfo:[NSString stringWithFormat:@"操作失败: %@", [self errorDescriptionForError:audioError]]];
    } else {
        [self logInfo:[NSString stringWithFormat:@"操作失败: %@", error.localizedDescription]];
    }
}

- (NSString *)errorDescriptionForError:(WYAudioError)error {
    switch (error) {
        case WYAudioErrorStartRecordingFailed: return @"开始录音失败";
        case WYAudioErrorNoAudioRecordedTasks: return @"没有正在录制的音频任务";
        case WYAudioErrorNoAudioPauseTasks: return @"没有需要暂停的音频任务";
        case WYAudioErrorNoAudioResumeRecordTasks: return @"没有需要恢复录制的音频任务";
        case WYAudioErrorDeleteAudioFileFailed: return @"删除音频(录音)文件失败";
        case WYAudioErrorNotDetermined: return @"未申请录音权限(权限未确定)";
        case WYAudioErrorPermissionDenied: return @"录音权限被拒绝";
        case WYAudioErrorNoAudiofilesToPlay: return @"没有可以播放的音频文件";
        case WYAudioErrorFileNotFound: return @"音频文件未找到";
        case WYAudioErrorFileSaveFailed: return @"录音文件保存失败";
        case WYAudioErrorRecordingInProgress: return @"录音正在进行中";
        case WYAudioErrorMinDurationNotReached: return @"录音时长未达到最小值";
        case WYAudioErrorIsPlayingAudio: return @"正在播放音频文件";
        case WYAudioErrorPlaybackError: return @"播放错误";
        case WYAudioErrorNoAudioToPause: return @"没有可以暂停播放的音频";
        case WYAudioErrorNoAudioResumePlayTasks: return @"没有可以恢复播放的音频任务";
        case WYAudioErrorDownloadFailed: return @"音频下载失败";
        case WYAudioErrorInvalidRemoteURL: return @"无效的远程URL";
        case WYAudioErrorNoFilesRequireConversion: return @"没有需要格式转换的文件";
        case WYAudioErrorConversionFailed: return @"格式转换失败";
        case WYAudioErrorConversionCancelled: return @"格式转换已取消";
        case WYAudioErrorFormatNotSupported: return @"不支持的录制格式";
        case WYAudioErrorSessionConfigurationFailed: return @"音频会话配置失败";
        case WYAudioErrorDirectoryCreationFailed: return @"目录创建失败";
        default: return @"未知错误";
    }
}

- (NSString *)directoryDescriptionForDirectory:(WYAudioStorageDirectory)directory {
    switch (directory) {
        case WYAudioStorageDirectoryTemporary: return @"临时目录";
        case WYAudioStorageDirectoryDocuments: return @"文档目录";
        case WYAudioStorageDirectoryCaches: return @"缓存目录";
        default: return @"未知目录";
    }
}

- (NSString *)stringValueForFormat:(WYAudioFormat)format {
    switch (format) {
        case WYAudioFormatAac: return @"aac";
        case WYAudioFormatWav: return @"wav";
        case WYAudioFormatCaf: return @"caf";
        case WYAudioFormatM4a: return @"m4a";
        case WYAudioFormatAiff: return @"aiff";
        case WYAudioFormatMp3: return @"mp3";
        case WYAudioFormatFlac: return @"flac";
        case WYAudioFormatAu: return @"au";
        case WYAudioFormatAmr: return @"amr";
        case WYAudioFormatAc3: return @"ac3";
        case WYAudioFormatEac3: return @"eac3";
        default: return @"aac";
    }
}

- (NSString *)formatDescriptionForFormat:(WYAudioFormat)format {
    switch (format) {
        case WYAudioFormatAac: return @"高效压缩";
        case WYAudioFormatWav: return @"无损质量";
        case WYAudioFormatCaf: return @"Apple容器";
        case WYAudioFormatM4a: return @"MP4音频";
        case WYAudioFormatAiff: return @"无损格式";
        case WYAudioFormatMp3: return @"通用格式";
        case WYAudioFormatFlac: return @"无损压缩";
        case WYAudioFormatAu: return @"早期格式";
        case WYAudioFormatAmr: return @"人声优化";
        case WYAudioFormatAc3: return @"杜比数字";
        case WYAudioFormatEac3: return @"增强杜比";
        default: return @"未知格式";
    }
}

#pragma mark - 懒加载数据

- (NSArray<NSNumber *> *)supportedFormats {
    if (!_supportedFormats) {
        _supportedFormats = @[
            @(WYAudioFormatAac), @(WYAudioFormatWav), @(WYAudioFormatCaf),
            @(WYAudioFormatM4a), @(WYAudioFormatAiff), @(WYAudioFormatMp3),
            @(WYAudioFormatFlac), @(WYAudioFormatAu), @(WYAudioFormatAmr),
            @(WYAudioFormatAc3), @(WYAudioFormatEac3)
        ];
    }
    return _supportedFormats;
}

- (NSArray<NSNumber *> *)supportedConvertFormats {
    if (!_supportedConvertFormats) {
        _supportedConvertFormats = @[
            @(WYAudioFormatAac), @(WYAudioFormatM4a), @(WYAudioFormatCaf),
            @(WYAudioFormatWav), @(WYAudioFormatAiff)
        ];
    }
    return _supportedConvertFormats;
}

- (void)setMinRecordingDuration:(NSTimeInterval)minRecordingDuration {
    _minRecordingDuration = minRecordingDuration;
    self.minDurationLabel.text = [NSString stringWithFormat:@"最短时长: %.1f秒", minRecordingDuration];
}

- (void)setMaxRecordingDuration:(NSTimeInterval)maxRecordingDuration {
    _maxRecordingDuration = maxRecordingDuration;
    self.maxDurationLabel.text = [NSString stringWithFormat:@"最长时长: %.1f秒", maxRecordingDuration];
}

#pragma mark - UIPickerViewDataSource & UIPickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView == self.formatPicker) {
        return self.supportedFormats.count;
    } else {
        return self.supportedConvertFormats.count;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    WYAudioFormat format;
    if (pickerView == self.formatPicker) {
        format = [self.supportedFormats[row] integerValue];
    } else {
        format = [self.supportedConvertFormats[row] integerValue];
    }
    return [NSString stringWithFormat:@"%@ (%@)", [[self stringValueForFormat:format] uppercaseString], [self formatDescriptionForFormat:format]];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (pickerView == self.formatPicker) {
        WYAudioFormat newFormat = [self.supportedFormats[row] integerValue];
        if (self.selectedFormat != newFormat) {
            self.selectedFormat = newFormat;
        }
    } else {
        WYAudioFormat newFormat = [self.supportedConvertFormats[row] integerValue];
        if (self.targetFormat != newFormat) {
            self.targetFormat = newFormat;
        }
    }
}

#pragma mark - WYAudioKitDelegate

- (void)wy_audioRecorderDidStart:(WYAudioKit *)audioKit isResume:(BOOL)isResume {
    [self logInfo:[NSString stringWithFormat:@"开始录制 %@ 格式音频, %@恢复录音", [self stringValueForFormat:self.selectedFormat], isResume ? @"是" : @"不是"]];
    [self.voiceWaveView startAnimating];
}

- (void)wy_audioRecorderDidStop:(WYAudioKit *)audioKit isPause:(BOOL)isPause isTimeout:(BOOL)isTimeout {
    [self logInfo:[NSString stringWithFormat:@"录音停止, %@暂停录音, %@超时(达到最大录音时长)停止", isPause ? @"是" : @"不是", isTimeout ? @"是" : @"不是"]];
    [self.voiceWaveView stopAnimating];
}

- (void)wy_audioRecorderTimeUpdated:(WYAudioKit *)audioKit currentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration {
    CGFloat progress = MIN(currentTime / duration, 1.0) * 100.0;
    self.recordProgressLabel.text = [NSString stringWithFormat:@"录音进度: %.1f秒/%.1f秒 (%.1f%%)", currentTime, duration, progress];
}

- (void)wy_audioRecorderDidUpdateMeterings:(WYAudioKit *)audioKit peakPowers:(NSArray<NSNumber *> *)peakPowers averagePowers:(NSArray<NSNumber *> *)averagePowers {
    // 使用峰值功率，响应更快
    CGFloat raw = peakPowers.firstObject.floatValue;
    // 放大 80 倍，并限制最大值 1
    CGFloat normalized = MIN(1.0, raw * 80.0);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.voiceWaveView updatePower:normalized];
    });
}

- (void)wy_audioPlayerStateDidChanged:(WYAudioKit *)audioKit state:(enum WYAudioPlayState)state {
    NSString *stateStr;
    switch (state) {
        case WYAudioPlayStateStart: stateStr = @"开始播放"; break;
        case WYAudioPlayStatePause: stateStr = @"暂停播放"; break;
        case WYAudioPlayStateResume: stateStr = @"恢复播放"; break;
        case WYAudioPlayStateStop: stateStr = @"停止播放"; break;
        case WYAudioPlayStateFinish: stateStr = @"完成播放"; break;
        default: stateStr = @"未知状态"; break;
    }
    [self logInfo:[NSString stringWithFormat:@"播放状态: %@", stateStr]];
    if (state == WYAudioPlayStateFinish) {
        self.playProgressLabel.text = @"播放进度: 100%";
    }
}

- (void)wy_audioPlayerTimeUpdated:(WYAudioKit *)audioKit localUrl:(NSURL *)localUrl currentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration progress:(double)progress {
    self.currentPlayingDuration = duration;
    self.playProgressLabel.text = [NSString stringWithFormat:@"播放进度: %.1f秒/%.1f秒 (%.1f%%)", currentTime, duration, progress * 100];
}

- (void)wy_remoteAudioDownloadProgressUpdated:(WYAudioKit *)audioKit remoteUrls:(NSArray<NSURL *> *)remoteUrls progress:(double)progress {
    self.downloadProgressLabel.text = [NSString stringWithFormat:@"下载进度: %.1f%%, remoteUrls：%@", progress * 100, remoteUrls];
    for (DownloadTaskCardView *card in self.taskCards) {
        if (card.url && [remoteUrls containsObject:card.url]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                card.progressBar.progress = progress;
                card.progressLabel.text = [NSString stringWithFormat:@"进度: %.1f%%", progress * 100];
            });
        }
    }
}

- (void)wy_remoteAudioDownloadSuccess:(WYAudioKit *)audioKit fileInfo:(NSArray<WYAudioDownloadInfo *> *)fileInfos {
    for (WYAudioDownloadInfo *info in fileInfos) {
        [self logInfo:[NSString stringWithFormat:@"下载成功: %@", info.local]];
        for (DownloadTaskCardView *card in self.taskCards) {
            if (card.url && [card.url isEqual:info.remote]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    card.progressBar.progress = 1.0;
                    card.progressLabel.text = @"进度: 100%";
                });
            }
        }
    }
    [self refreshFileList];
}

- (void)wy_formatConversionProgressUpdated:(WYAudioKit *)audioKit localUrls:(NSArray<NSURL *> *)localUrls progress:(double)progress {
    self.conversionProgressLabel.text = [NSString stringWithFormat:@"转换进度: %.1f%%, localUrls：%@", progress * 100, localUrls];
}

- (void)wy_formatConversionDidCompleted:(WYAudioKit *)audioKit outputUrls:(NSArray<NSURL *> *)outputUrls {
    for (NSURL *url in outputUrls) {
        [self logInfo:[NSString stringWithFormat:@"转换完成: %@", url.lastPathComponent]];
    }
    [self refreshFileList];
}

- (void)wy_audioTaskDidFailed:(WYAudioKit *)audioKit url:(NSURL *)url error:(enum WYAudioError)error description:(NSString *)description {
    [self logInfo:[NSString stringWithFormat:@"任务失败: %@, 描述: %@, URL: %@", [self errorDescriptionForError:error], description ?: @"无", url ?: @"空"]];
    for (DownloadTaskCardView *card in self.taskCards) {
        if (card.url && [card.url isEqual:url]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                card.progressBar.progress = 0;
                card.progressLabel.text = @"进度: 0%";
            });
        }
    }
}

- (void)dealloc {
    [self.audioKit releaseAll];
    NSLog(@"WYTestAudioController release");
}

@end
