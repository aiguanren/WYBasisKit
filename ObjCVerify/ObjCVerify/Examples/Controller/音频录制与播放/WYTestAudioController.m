//
//  WYTestAudioController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/13.
//

#import "WYTestAudioController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>
#import <AVFoundation/AVFoundation.h>

/// 测试音频控制器，用于演示WYAudioKit的功能
@interface WYTestAudioController () <WYAudioKitDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

/// 音频工具实例
@property (nonatomic, strong) WYAudioKit *audioKit;

/// 界面元素
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UITextView *infoTextView;

// 录音控制
@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIButton *pauseRecordButton;
@property (nonatomic, strong) UIButton *stopRecordButton;
@property (nonatomic, strong) UIButton *resumeRecordButton;

// 播放控制
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *pausePlayButton;
@property (nonatomic, strong) UIButton *stopPlayButton;
@property (nonatomic, strong) UIButton *resumePlayButton;
@property (nonatomic, strong) UIButton *seekButton;
@property (nonatomic, strong) UISlider *seekSlider;

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

// 网络音频
@property (nonatomic, strong) UITextField *remoteURLField;
@property (nonatomic, strong) UIButton *downloadButton;

// 文件管理
@property (nonatomic, strong) UITextView *fileListTextView;
@property (nonatomic, strong) UIButton *refreshFilesButton;
@property (nonatomic, strong) UIButton *deleteAllRecordingsButton;
@property (nonatomic, strong) UIButton *deleteAllDownloadsButton;

// 格式转换
@property (nonatomic, strong) UIButton *convertButton;
@property (nonatomic, strong) UIPickerView *targetFormatPicker;

// 其他功能
@property (nonatomic, strong) UIButton *playRecordedButton;
@property (nonatomic, strong) UIButton *saveRecordButton;
@property (nonatomic, strong) UIButton *deleteRecordButton;
@property (nonatomic, strong) UIButton *customSettingsButton;
@property (nonatomic, strong) UIButton *releaseButton;

/// 支持的音频格式
@property (nonatomic, strong) NSArray<NSNumber *> *supportedFormats;

/// 当前选中的格式
@property (nonatomic, assign) WYAudioFormat selectedFormat;

/// 当前选中的目标格式
@property (nonatomic, assign) WYAudioFormat targetFormat;

/// 最小录音时长
@property (nonatomic, assign) NSTimeInterval minRecordingDuration;

/// 最大录音时长
@property (nonatomic, assign) NSTimeInterval maxRecordingDuration;

@end

@implementation WYTestAudioController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"音频工具测试";
    
    // 初始化属性
    self.minRecordingDuration = 0;
    self.maxRecordingDuration = 60;
    self.selectedFormat = WYAudioFormatAac;
    self.targetFormat = WYAudioFormatMp3;
    
    [self setupUI];
    [self setupAudioKit];
    [self refreshFileList];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollView.contentSize = self.contentView.frame.size;
}

- (void)setupAudioKit {
    self.audioKit = [[WYAudioKit alloc] init];
    self.audioKit.delegate = self;
    [self.audioKit setRecordingDurationsMin:self.minRecordingDuration max:self.maxRecordingDuration];
    
    // 请求录音权限
    [self.audioKit requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *status = granted ? @"已授权" : @"未授权";
            [self logInfo:[NSString stringWithFormat:@"录音权限: %@", status]];
        });
    }];
}

- (void)setupUI {
    // 创建滚动视图
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, [UIDevice wy_navViewHeight], [UIDevice wy_screenWidth], [UIDevice wy_screenHeight] - [UIDevice wy_navViewHeight])];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.scrollView.frame.size.height)];
    [self.scrollView addSubview:self.contentView];
    
    // 信息文本框
    self.infoTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, 20, self.view.bounds.size.width - 40, 190)];
    self.infoTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.infoTextView.layer.borderWidth = 1;
    self.infoTextView.layer.cornerRadius = 8;
    self.infoTextView.font = [UIFont systemFontOfSize:14];
    self.infoTextView.editable = NO;
    self.infoTextView.text = @"操作日志将显示在这里...\n";
    [self.contentView addSubview:self.infoTextView];
    
    // 格式选择器
    UILabel *formatLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 230, 200, 30)];
    formatLabel.text = @"选择录音格式:";
    [self.contentView addSubview:formatLabel];
    
    self.formatPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(20, 260, self.view.bounds.size.width - 40, 100)];
    self.formatPicker.dataSource = self;
    self.formatPicker.delegate = self;
    [self.contentView addSubview:self.formatPicker];
    
    // 存储目录选择
    UILabel *storageDirLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 370, 200, 30)];
    storageDirLabel.text = @"存储目录:";
    [self.contentView addSubview:storageDirLabel];
    
    self.storageDirSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"临时", @"文档", @"缓存"]];
    self.storageDirSegmentedControl.frame = CGRectMake(20, 400, self.view.bounds.size.width - 40, 30);
    self.storageDirSegmentedControl.selectedSegmentIndex = 0;
    [self.storageDirSegmentedControl addTarget:self action:@selector(storageDirChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.storageDirSegmentedControl];
    [self storageDirChanged];
    
    // 录音控制
    UILabel *recordLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 440, 200, 30)];
    recordLabel.text = @"录音控制:";
    [self.contentView addSubview:recordLabel];
    
    self.recordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.recordButton.frame = CGRectMake(20, 480, 80, 40);
    [self.recordButton setTitle:@"开始录音" forState:UIControlStateNormal];
    [self.recordButton addTarget:self action:@selector(startRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.recordButton];
    
    self.pauseRecordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.pauseRecordButton.frame = CGRectMake(110, 480, 80, 40);
    [self.pauseRecordButton setTitle:@"暂停录音" forState:UIControlStateNormal];
    [self.pauseRecordButton addTarget:self action:@selector(pauseRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.pauseRecordButton];
    
    self.resumeRecordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.resumeRecordButton.frame = CGRectMake(200, 480, 80, 40);
    [self.resumeRecordButton setTitle:@"恢复录音" forState:UIControlStateNormal];
    [self.resumeRecordButton addTarget:self action:@selector(resumeRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.resumeRecordButton];
    
    self.stopRecordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.stopRecordButton.frame = CGRectMake(290, 480, 80, 40);
    [self.stopRecordButton setTitle:@"停止录音" forState:UIControlStateNormal];
    [self.stopRecordButton addTarget:self action:@selector(stopRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.stopRecordButton];
    
    // 录音进度
    self.recordProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 530, self.view.bounds.size.width - 40, 30)];
    self.recordProgressLabel.text = @"录音进度: 0.0秒/0.0秒";
    [self.contentView addSubview:self.recordProgressLabel];
    
    // 播放录音文件
    self.playRecordedButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.playRecordedButton.frame = CGRectMake(20, 560, 150, 40);
    [self.playRecordedButton setTitle:@"播放录音文件" forState:UIControlStateNormal];
    [self.playRecordedButton addTarget:self action:@selector(playRecordedFile) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.playRecordedButton];
    
    // 播放控制
    UILabel *playLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 610, 200, 30)];
    playLabel.text = @"播放控制:";
    [self.contentView addSubview:playLabel];
    
    self.playButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.playButton.frame = CGRectMake(20, 650, 150, 40);
    [self.playButton setTitle:@"播放本地音频" forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playLocalAudio) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.playButton];
    
    self.pausePlayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.pausePlayButton.frame = CGRectMake(180, 650, 80, 40);
    [self.pausePlayButton setTitle:@"暂停播放" forState:UIControlStateNormal];
    [self.pausePlayButton addTarget:self action:@selector(pausePlayback) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.pausePlayButton];
    
    self.stopPlayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.stopPlayButton.frame = CGRectMake(270, 650, 80, 40);
    [self.stopPlayButton setTitle:@"停止播放" forState:UIControlStateNormal];
    [self.stopPlayButton addTarget:self action:@selector(stopPlayback) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.stopPlayButton];
    
    self.resumePlayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.resumePlayButton.frame = CGRectMake(20, 700, 80, 40);
    [self.resumePlayButton setTitle:@"恢复播放" forState:UIControlStateNormal];
    [self.resumePlayButton addTarget:self action:@selector(resumePlayback) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.resumePlayButton];
    
    // 跳转播放
    self.seekSlider = [[UISlider alloc] initWithFrame:CGRectMake(110, 700, 150, 40)];
    self.seekSlider.minimumValue = 0;
    self.seekSlider.maximumValue = 1;
    [self.contentView addSubview:self.seekSlider];
    
    self.seekButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.seekButton.frame = CGRectMake(270, 700, 80, 40);
    [self.seekButton setTitle:@"跳转播放" forState:UIControlStateNormal];
    [self.seekButton addTarget:self action:@selector(seekPlayback) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.seekButton];
    
    // 播放进度
    self.playProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 750, self.view.bounds.size.width - 40, 30)];
    self.playProgressLabel.text = @"播放进度: 0.0秒/0.0秒 (0.0%)";
    [self.contentView addSubview:self.playProgressLabel];
    
    // 时长设置
    UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 790, 200, 30)];
    durationLabel.text = @"录音时长设置:";
    [self.contentView addSubview:durationLabel];
    
    self.minDurationSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 830, self.view.bounds.size.width - 40, 30)];
    self.minDurationSlider.minimumValue = 0;
    self.minDurationSlider.maximumValue = 60;
    self.minDurationSlider.value = 0;
    [self.minDurationSlider addTarget:self action:@selector(minDurationChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.minDurationSlider];
    
    self.minDurationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 860, self.view.bounds.size.width - 40, 30)];
    self.minDurationLabel.text = @"最短时长: 0.0秒";
    [self.contentView addSubview:self.minDurationLabel];
    
    self.maxDurationSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 890, self.view.bounds.size.width - 40, 30)];
    self.maxDurationSlider.minimumValue = 1;
    self.maxDurationSlider.maximumValue = 300;
    self.maxDurationSlider.value = 60;
    [self.maxDurationSlider addTarget:self action:@selector(maxDurationChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.maxDurationSlider];
    
    self.maxDurationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 920, self.view.bounds.size.width - 40, 30)];
    self.maxDurationLabel.text = @"最长时长: 60.0秒";
    [self.contentView addSubview:self.maxDurationLabel];
    
    // 质量设置
    UILabel *qualityLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 960, 200, 30)];
    qualityLabel.text = @"音频质量:";
    [self.contentView addSubview:qualityLabel];
    
    self.qualitySegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"低", @"中", @"高"]];
    self.qualitySegmentedControl.frame = CGRectMake(20, 1000, self.view.bounds.size.width - 40, 30);
    self.qualitySegmentedControl.selectedSegmentIndex = 2;
    [self.qualitySegmentedControl addTarget:self action:@selector(qualityChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.qualitySegmentedControl];
    
    // 网络音频
    UILabel *remoteLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 1040, 200, 30)];
    remoteLabel.text = @"网络音频测试:";
    [self.contentView addSubview:remoteLabel];
    
    self.remoteURLField = [[UITextField alloc] initWithFrame:CGRectMake(20, 1080, self.view.bounds.size.width - 40, 40)];
    self.remoteURLField.borderStyle = UITextBorderStyleRoundedRect;
    self.remoteURLField.placeholder = @"输入音频URL";
    self.remoteURLField.text = @"http://music.163.com/song/media/outer/url?id=2105354877.mp3";
    [self.contentView addSubview:self.remoteURLField];
    
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.downloadButton.frame = CGRectMake(20, 1130, self.view.bounds.size.width - 40, 40);
    [self.downloadButton setTitle:@"下载并播放网络音频" forState:UIControlStateNormal];
    [self.downloadButton addTarget:self action:@selector(downloadAndPlay) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.downloadButton];
    
    self.downloadProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 1180, self.view.bounds.size.width - 40, 30)];
    self.downloadProgressLabel.text = @"下载进度: 0.0%";
    [self.contentView addSubview:self.downloadProgressLabel];
    
    // 文件管理
    UILabel *fileLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 1220, 200, 30)];
    fileLabel.text = @"录音文件列表:";
    [self.contentView addSubview:fileLabel];
    
    self.refreshFilesButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.refreshFilesButton.frame = CGRectMake(self.view.bounds.size.width - 120, 1220, 100, 30);
    [self.refreshFilesButton setTitle:@"刷新列表" forState:UIControlStateNormal];
    [self.refreshFilesButton addTarget:self action:@selector(refreshFileList) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.refreshFilesButton];
    
    self.fileListTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, 1260, self.view.bounds.size.width - 40, 150)];
    self.fileListTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.fileListTextView.layer.borderWidth = 1;
    self.fileListTextView.layer.cornerRadius = 8;
    self.fileListTextView.font = [UIFont systemFontOfSize:12];
    self.fileListTextView.editable = NO;
    [self.contentView addSubview:self.fileListTextView];
    
    // 文件操作
    self.saveRecordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.saveRecordButton.frame = CGRectMake(20, 1420, 100, 40);
    [self.saveRecordButton setTitle:@"保存录音" forState:UIControlStateNormal];
    [self.saveRecordButton addTarget:self action:@selector(saveRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.saveRecordButton];
    
    self.deleteRecordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.deleteRecordButton.frame = CGRectMake(130, 1420, 100, 40);
    [self.deleteRecordButton setTitle:@"删除录音" forState:UIControlStateNormal];
    [self.deleteRecordButton addTarget:self action:@selector(deleteRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.deleteRecordButton];
    
    self.deleteAllRecordingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.deleteAllRecordingsButton.frame = CGRectMake(240, 1420, 120, 40);
    [self.deleteAllRecordingsButton setTitle:@"删除所有录音" forState:UIControlStateNormal];
    [self.deleteAllRecordingsButton addTarget:self action:@selector(deleteAllRecordings) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.deleteAllRecordingsButton];
    
    // 格式转换
    UILabel *convertLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 1470, 200, 30)];
    convertLabel.text = @"格式转换:";
    [self.contentView addSubview:convertLabel];
    
    self.targetFormatPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(20, 1510, self.view.bounds.size.width - 40, 100)];
    self.targetFormatPicker.dataSource = self;
    self.targetFormatPicker.delegate = self;
    [self.contentView addSubview:self.targetFormatPicker];
    
    self.convertButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.convertButton.frame = CGRectMake(20, 1620, self.view.bounds.size.width - 40, 40);
    [self.convertButton setTitle:@"转换音频文件格式" forState:UIControlStateNormal];
    [self.convertButton addTarget:self action:@selector(convertAudio) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.convertButton];
    
    self.conversionProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 1670, self.view.bounds.size.width - 40, 30)];
    self.conversionProgressLabel.text = @"转换进度: 0.0%";
    [self.contentView addSubview:self.conversionProgressLabel];
    
    // 其他功能
    self.customSettingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.customSettingsButton.frame = CGRectMake(20, 1710, 150, 40);
    [self.customSettingsButton setTitle:@"自定义录音设置" forState:UIControlStateNormal];
    [self.customSettingsButton addTarget:self action:@selector(setCustomSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.customSettingsButton];
    
    self.releaseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.releaseButton.frame = CGRectMake(180, 1710, 100, 40);
    [self.releaseButton setTitle:@"释放资源" forState:UIControlStateNormal];
    [self.releaseButton addTarget:self action:@selector(releaseResources) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.releaseButton];
    
    self.contentView.wy_height = CGRectGetMaxY(self.releaseButton.frame) + 100;
}

// MARK: - 状态更新
- (void)logInfo:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterNoStyle;
        formatter.timeStyle = NSDateFormatterMediumStyle;
        NSString *timestamp = [formatter stringFromDate:[NSDate date]];
        NSString *log = [NSString stringWithFormat:@"%@: %@\n", timestamp, message];
        self.infoTextView.text = [self.infoTextView.text stringByAppendingString:log];
        
        // 滚动到底部
        NSRange bottom = NSMakeRange(self.infoTextView.text.length - 1, 1);
        [self.infoTextView scrollRangeToVisible:bottom];
    });
}

// MARK: - 录音控制
- (void)startRecording {
    NSError *error;
    [self.audioKit startRecordingWithFormat:self.selectedFormat error:&error];
    
    if (error) {
        [self handleError:error];
    }
}

- (void)pauseRecording {
    [self.audioKit pauseRecording];
}

- (void)resumeRecording {
    [self.audioKit resumeRecording];
}

- (void)stopRecording {
    [self.audioKit stopRecording];
}

// MARK: - 播放控制
- (void)playLocalAudio {
    NSURL *testFileURL = [[NSBundle mainBundle] URLForResource:@"世间美好与你环环相扣" withExtension:@"mp3"];
    if (testFileURL) {
        NSError *error;
        [self.audioKit playAudioWithUrl:testFileURL error:&error];
        
        if (error) {
            [self handleError:error];
        }
    } else {
        [self logInfo:@"测试音频文件未找到"];
    }
}

- (void)playRecordedFile {
    NSError *error;
    [self.audioKit playRecordedFileWithError:&error];
    
    if (error) {
        [self handleError:error];
    }
}

- (void)pausePlayback {
    [self.audioKit pausePlayback];
}

- (void)stopPlayback {
    [self.audioKit stopPlayback];
}

- (void)resumePlayback {
    [self.audioKit resumePlayback];
}

- (void)seekPlayback {
    AVAudioPlayer *player = self.audioKit.audioPlayer;
    if (!player) {
        [self logInfo:@"没有正在播放的音频"];
        return;
    }
    
    NSTimeInterval seekTime = self.seekSlider.value * player.duration;
    [self.audioKit seekPlaybackTo:seekTime];
    [self logInfo:[NSString stringWithFormat:@"跳转到: %.1f秒", seekTime]];
}

// MARK: - 设置控制
- (void)minDurationChanged {
    self.minRecordingDuration = self.minDurationSlider.value;
    [self.audioKit setRecordingDurationsMin:self.minRecordingDuration max:self.maxRecordingDuration];
    [self logInfo:[NSString stringWithFormat:@"设置最小录音时长: %.1f秒", self.minRecordingDuration]];
}

- (void)maxDurationChanged {
    self.maxRecordingDuration = self.maxDurationSlider.value;
    [self.audioKit setRecordingDurationsMin:self.minRecordingDuration max:self.maxRecordingDuration];
    [self logInfo:[NSString stringWithFormat:@"设置最大录音时长: %.1f秒", self.maxRecordingDuration]];
}

- (void)qualityChanged {
    AVAudioQuality quality;
    switch (self.qualitySegmentedControl.selectedSegmentIndex) {
        case 0: quality = AVAudioQualityLow; break;
        case 1: quality = AVAudioQualityMedium; break;
        default: quality = AVAudioQualityHigh; break;
    }
    
    [self.audioKit setAudioQuality:quality];
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

// MARK: - 网络音频
- (void)downloadAndPlay {
    NSString *urlString = self.remoteURLField.text;
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [self logInfo:@"无效的URL"];
        return;
    }
    
    [self.audioKit playRemoteAudioFromRemoteURL:url completion:^(NSURL * _Nullable resultURL, NSError * _Nullable error) {
        if (error) {
            [self handleError:error];
        } else {
            [self logInfo:[NSString stringWithFormat:@"网络音频播放成功,存储地址：%@", resultURL.lastPathComponent]];
        }
    }];
}

// MARK: - 文件管理
- (void)refreshFileList {
    NSURL *tempDir = [NSFileManager defaultManager].temporaryDirectory;
    NSURL *docDir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *cacheDir = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject];
    
    NSMutableString *fileList = [NSMutableString stringWithString:@"临时目录文件:\n"];
    [fileList appendString:[self listFilesInDirectory:tempDir]];
    
    [fileList appendString:@"\n文档目录文件:\n"];
    [fileList appendString:[self listFilesInDirectory:docDir]];
    
    [fileList appendString:@"\n缓存目录文件:\n"];
    [fileList appendString:[self listFilesInDirectory:cacheDir]];
    
    self.fileListTextView.text = fileList;
}

- (NSString *)listFilesInDirectory:(NSURL *)directory {
    NSError *error;
    NSArray<NSURL *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directory includingPropertiesForKeys:nil options:0 error:&error];
    
    if (error) {
        return [NSString stringWithFormat:@"读取文件失败: %@\n", error.localizedDescription];
    }
    
    if (files.count == 0) {
        return @"无文件\n";
    }
    
    NSMutableString *fileInfo = [NSMutableString string];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    for (NSURL *file in files) {
        NSError *attrError;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:file.path error:&attrError];
        
        if (attrError) {
            [fileInfo appendFormat:@"%@\n", file.lastPathComponent];
            [fileInfo appendString:@"  大小: 未知\n"];
            [fileInfo appendString:@"  创建时间: 未知\n"];
            [fileInfo appendString:@"  格式: 未知\n\n"];
            continue;
        }
        
        NSNumber *size = attributes[NSFileSize];
        NSDate *date = attributes[NSFileCreationDate];
        
        double sizeMB = size ? size.doubleValue / (1024 * 1024) : 0;
        NSString *dateStr = date ? [dateFormatter stringFromDate:date] : @"未知";
        
        [fileInfo appendFormat:@"%@\n", file.lastPathComponent];
        [fileInfo appendFormat:@"  大小: %.2f MB\n", sizeMB];
        [fileInfo appendFormat:@"  创建时间: %@\n", dateStr];
        [fileInfo appendFormat:@"  格式: %@\n\n", file.pathExtension.uppercaseString];
    }
    
    return fileInfo;
}

- (void)saveRecording {
    NSURL *docDir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSString *fileName = [NSString stringWithFormat:@"saved_audio_%.0f.%@", [[NSDate date] timeIntervalSince1970], [self stringValueForFormat:self.selectedFormat]];
    NSURL *destinationURL = [docDir URLByAppendingPathComponent:fileName];
    
    NSError *error;
    [self.audioKit saveRecordingToDestinationURL:destinationURL error:&error];
    
    if (error) {
        [self handleError:error];
    } else {
        [self logInfo:[NSString stringWithFormat:@"文件已保存到: %@", destinationURL.lastPathComponent]];
        [self refreshFileList];
    }
}

- (void)deleteRecording {
    NSError *error;
    [self.audioKit deleteRecordingWithError:&error];
    
    if (error) {
        [self handleError:error];
    } else {
        [self logInfo:@"录音文件已删除"];
        [self refreshFileList];
    }
}

- (void)deleteAllRecordings {
    NSError *error;
    [self.audioKit deleteAllRecordingsWithError:&error];
    
    if (error) {
        [self handleError:error];
    } else {
        [self logInfo:@"所有录音文件已删除"];
        [self refreshFileList];
    }
}

// MARK: - 格式转换
- (void)convertAudio {
    NSURL *sourceURL = self.audioKit.currentRecordFileURL;
    if (!sourceURL) {
        [self logInfo:@"没有可转换的录音文件"];
        return;
    }
    
    [self logInfo:[NSString stringWithFormat:@"开始转换格式: %@ -> %@", sourceURL.lastPathComponent, [self stringValueForFormat:self.targetFormat]]];
    
    [self.audioKit convertAudioFileWithSourceURL:sourceURL targetFormat:self.targetFormat completion:^(NSURL * _Nullable newURL, NSError * _Nullable error) {
        if (error) {
            [self handleError:error];
        } else {
            [self logInfo:[NSString stringWithFormat:@"格式转换成功: %@", newURL.lastPathComponent]];
            [self refreshFileList];
        }
    }];
}

// MARK: - 其他功能
- (void)setCustomSettings {
    // 自定义录音参数：采样率22050，比特率64000，双声道
    NSDictionary *customSettings = @{
        AVSampleRateKey: @22050.0,
        AVNumberOfChannelsKey: @2,
        AVEncoderBitRateKey: @64000
    };
    
    [self.audioKit setRecordSettings:customSettings];
    [self logInfo:@"设置自定义录音参数: 采样率22.05kHz, 比特率64kbps, 双声道"];
}

- (void)releaseResources {
    [self.audioKit releaseAll];
    [self logInfo:@"已释放所有音频资源"];
}

// MARK: - 错误处理
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
        case WYAudioErrorPermissionDenied: return @"录音权限被拒绝";
        case WYAudioErrorFileNotFound: return @"音频文件未找到";
        case WYAudioErrorRecordingInProgress: return @"录音正在进行中";
        case WYAudioErrorPlaybackError: return @"播放错误";
        case WYAudioErrorFileSaveFailed: return @"录音文件保存失败";
        case WYAudioErrorMinDurationNotReached: return @"录音时长未达到最小值";
        case WYAudioErrorMaxDurationReached: return @"录音达到最大时长";
        case WYAudioErrorDownloadFailed: return @"音频下载失败";
        case WYAudioErrorInvalidRemoteURL: return @"无效的远程URL";
        case WYAudioErrorConversionFailed: return @"格式转换失败";
        case WYAudioErrorConversionCancelled: return @"格式转换已取消";
        case WYAudioErrorFormatNotSupported: return @"不支持的录制格式";
        case WYAudioErrorOutOfMemory: return @"内存不足";
        case WYAudioErrorSessionConfigurationFailed: return @"音频会话配置失败";
        case WYAudioErrorDirectoryCreationFailed: return @"文件目录创建失败";
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

// MARK: - 懒加载
- (NSArray<NSNumber *> *)supportedFormats {
    if (!_supportedFormats) {
        _supportedFormats = @[
            @(WYAudioFormatAac),
            @(WYAudioFormatWav),
            @(WYAudioFormatCaf),
            @(WYAudioFormatM4a),
            @(WYAudioFormatAiff),
            @(WYAudioFormatMp3),
            @(WYAudioFormatFlac),
            @(WYAudioFormatAu),
            @(WYAudioFormatAmr),
            @(WYAudioFormatAc3),
            @(WYAudioFormatEac3)
        ];
    }
    return _supportedFormats;
}

- (void)setMinRecordingDuration:(NSTimeInterval)minRecordingDuration {
    _minRecordingDuration = minRecordingDuration;
    self.minDurationLabel.text = [NSString stringWithFormat:@"最短时长: %.1f秒", minRecordingDuration];
}

- (void)setMaxRecordingDuration:(NSTimeInterval)maxRecordingDuration {
    _maxRecordingDuration = maxRecordingDuration;
    self.maxDurationLabel.text = [NSString stringWithFormat:@"最长时长: %.1f秒", maxRecordingDuration];
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.supportedFormats.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    WYAudioFormat format = [self.supportedFormats[row] integerValue];
    NSString *formatString = [self stringValueForFormat:format];
    NSString *description = [self formatDescriptionForFormat:format];
    return [NSString stringWithFormat:@"%@ (%@)", formatString.uppercaseString, description];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    WYAudioFormat format = [self.supportedFormats[row] integerValue];
    
    if (pickerView == self.formatPicker) {
        self.selectedFormat = format;
        [self logInfo:[NSString stringWithFormat:@"已选择录音格式: %@", [[self stringValueForFormat:format] uppercaseString]]];
    } else {
        self.targetFormat = format;
        [self logInfo:[NSString stringWithFormat:@"已选择目标格式: %@", [[self stringValueForFormat:format] uppercaseString]]];
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

// MARK: - WYAudioKitDelegate
- (void)audioRecorderDidStart {
    [self logInfo:[NSString stringWithFormat:@"开始录制 %@ 格式音频", [[self stringValueForFormat:self.selectedFormat] uppercaseString]]];
}

- (void)audioRecorderDidPause {
    [self logInfo:@"录音已暂停"];
}

- (void)audioRecorderDidResume {
    [self logInfo:@"录音已恢复"];
}

- (void)audioRecorderDidStop {
    [self logInfo:@"录音停止"];
}

- (void)audioRecorderTimeUpdatedWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration {
    self.recordProgressLabel.text = [NSString stringWithFormat:@"录音进度: %.1f秒/%.1f秒 (%.1f%%)", currentTime, duration, (currentTime/duration)*100];
}

- (void)audioRecorderDidFailWithError:(WYAudioError)error {
    [self logInfo:[NSString stringWithFormat:@"录音错误: %@", [self errorDescriptionForError:error]]];
}

- (void)audioPlayerDidStart {
    [self logInfo:@"播放开始"];
}

- (void)audioPlayerDidPause {
    [self logInfo:@"播放暂停"];
}

- (void)audioPlayerDidResume {
    [self logInfo:@"播放恢复"];
}

- (void)audioPlayerDidStop {
    [self logInfo:@"播放停止"];
}

- (void)audioPlayerTimeUpdatedWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration progress:(double)progress {
    self.playProgressLabel.text = [NSString stringWithFormat:@"播放进度: %.1f秒/%.1f秒 (%.1f%%)", currentTime, duration, progress*100];
}

- (void)audioPlayerDidFinishPlaying {
    [self logInfo:@"播放完成"];
}

- (void)audioPlayerDidFailWithError:(WYAudioError)error {
    [self logInfo:[NSString stringWithFormat:@"播放失败: %@", [self errorDescriptionForError:error]]];
}

- (void)remoteAudioDownloadProgressUpdatedWithProgress:(double)progress {
    self.downloadProgressLabel.text = [NSString stringWithFormat:@"下载进度: %.1f%%", progress*100];
}

- (void)conversionProgressUpdatedWithProgress:(double)progress {
    self.conversionProgressLabel.text = [NSString stringWithFormat:@"转换进度: %.1f%%", progress*100];
}

- (void)conversionDidCompleteWithURL:(NSURL *)url {
    [self logInfo:[NSString stringWithFormat:@"格式转换完成: %@", url.lastPathComponent]];
}

- (void)audioSessionConfigurationFailedWithError:(NSError *)error {
    [self logInfo:[NSString stringWithFormat:@"音频会话配置失败: %@", error.localizedDescription]];
}

- (void)dealloc {
    [self.audioKit releaseAll];
    WYLog(@"WYTestAudioController release");
}

@end
