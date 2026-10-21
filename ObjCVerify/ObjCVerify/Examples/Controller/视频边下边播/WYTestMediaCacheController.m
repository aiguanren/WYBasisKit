//
//  WYTestMediaCacheController.m
//  ObjCVerify
//
//  Created by 官人 on 2026/10/19.
//

#import "WYTestMediaCacheController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>
@import AVFoundation;

/// 缓存区间可视化条(灰色底表示整个文件，绿色块表示已缓存区间，红线表示播放位置)
@interface WYMediaCacheRangesView : UIView

/// 已缓存区间列表
@property (copy, nonatomic) NSArray<WYMediaCacheRange *> *cachedRanges;

/// 媒体文件总大小，单位为字节
@property (assign, nonatomic) long long contentLength;

/// 播放位置占全片比例
@property (assign, nonatomic) CGFloat playbackRatio;

@end

@implementation WYMediaCacheRangesView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        _cachedRanges = @[];
        _contentLength = 0;
        _playbackRatio = 0;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    if (self.contentLength <= 0) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context == NULL) {
        return;
    }
    for (WYMediaCacheRange *range in self.cachedRanges) {
        CGFloat startRatio = range.start / (CGFloat)self.contentLength;
        CGFloat endRatio = range.end / (CGFloat)self.contentLength;
        CGContextSetFillColorWithColor(context, UIColor.systemGreenColor.CGColor);
        CGContextFillRect(context, CGRectMake(rect.origin.x + startRatio * rect.size.width, rect.origin.y, MAX(1, (endRatio - startRatio) * rect.size.width), rect.size.height));
    }
    if (self.playbackRatio > 0) {
        CGContextSetFillColorWithColor(context, UIColor.systemRedColor.CGColor);
        CGContextFillRect(context, CGRectMake(rect.origin.x + self.playbackRatio * rect.size.width, rect.origin.y, 2, rect.size.height));
    }
}

@end

/// 视频边下边播测试页(用 WYMediaCache 播放在线 mp4，演示边下边播、重播秒开、预下载、完整缓存本地播、LRU 容量淘汰与清空缓存)
@interface WYTestMediaCacheController () <UITableViewDataSource, UITableViewDelegate>

/// 播放器
@property (strong, nonatomic) AVPlayer *player;

/// 播放器画面层
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

/// 播放区容器(画面层挂它上面)
@property (strong, nonatomic) UIView *playerContainer;

/// 播放暂停按钮
@property (strong, nonatomic) UIButton *playButton;

/// 播放进度滑块
@property (strong, nonatomic) UISlider *progressSlider;

/// 播放时间标签
@property (strong, nonatomic) UILabel *timeLabel;

/// 素材切换条(三个公共示例视频，后两个体积小适合演示容量淘汰)
@property (strong, nonatomic) UISegmentedControl *mediaSegment;

/// 素材清单(地址为谷歌公共示例视频)
@property (copy, nonatomic) NSArray<NSURL *> *mediaList;

/// 当前素材下标
@property (assign, nonatomic) NSInteger currentIndex;

/// 自定义视频地址(点过播放输入框地址后生效，优先于素材清单)
@property (strong, nonatomic, nullable) NSURL *activeCustomURL;

/// 自定义视频地址输入框
@property (strong, nonatomic) UITextField *urlTextField;

/// 蜂窝流量确认是否开启(测试开关状态随页面)
@property (assign, nonatomic) BOOL cellularConfirmEnabled;

/// 播放进度监听
@property (strong, nonatomic) id timeObserver;

/// 缓存区间可视化条
@property (strong, nonatomic) WYMediaCacheRangesView *rangesView;

/// 缓存状态文字
@property (strong, nonatomic) UILabel *statusLabel;

/// 动作列表
@property (strong, nonatomic) UITableView *tableView;

/// 状态刷新定时器
@property (strong, nonatomic) NSTimer *statusTimer;

@end

@implementation WYTestMediaCacheController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"视频边下边播";
    self.mediaList = @[[NSURL URLWithString:@"https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_5MB.mp4"],
                       [NSURL URLWithString:@"https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4"],
                       [NSURL URLWithString:@"https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4"]];
    [self setupPlayerUI];
    [self setupStatusUI];
    [self setupActionList];
    [self startStatusTimer];
    [self playCurrentMedia];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.playerLayer.frame = CGRectMake(0, 0, self.playerContainer.bounds.size.width, self.playerContainer.bounds.size.height);
}

/// 搭建播放区(画面、素材切换、播放暂停、进度条)
- (void)setupPlayerUI {
    self.playerContainer = [[UIView alloc] init];
    self.playerContainer.backgroundColor = UIColor.blackColor;
    [self.view addSubview:self.playerContainer];

    self.player = [[AVPlayer alloc] init];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.playerContainer.layer addSublayer:self.playerLayer];

    self.mediaSegment = [[UISegmentedControl alloc] initWithItems:@[@"主视频", @"小视频1", @"小视频2"]];
    self.mediaSegment.selectedSegmentIndex = 0;
    [self.mediaSegment addTarget:self action:@selector(mediaSegmentChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.mediaSegment];

    self.playButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.playButton setTitle:@"播放" forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playButton];

    self.progressSlider = [[UISlider alloc] init];
    self.progressSlider.minimumValue = 0;
    self.progressSlider.maximumValue = 1;
    self.progressSlider.value = 0;
    [self.progressSlider addTarget:self action:@selector(progressSliderChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.progressSlider];

    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.text = @"00:00 / 00:00";
    self.timeLabel.font = [UIFont systemFontOfSize:12];
    self.timeLabel.textColor = UIColor.darkGrayColor;
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.timeLabel];

    __weak typeof(self) weakSelf = self;
    [self.playerContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuide).offset(8);
        make.left.and.right.equalTo(self.view);
        make.height.mas_equalTo(self.playerContainer.mas_width).multipliedBy(9.0 / 16.0);
    }];
    [self.mediaSegment mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.playerContainer.mas_bottom).offset(8);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
    }];
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mediaSegment.mas_bottom).offset(8);
        make.left.equalTo(self.view).offset(16);
        make.width.mas_equalTo(64);
    }];
    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.playButton);
        make.left.equalTo(self.playButton.mas_right).offset(12);
        make.right.equalTo(self.view).offset(-16);
    }];
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressSlider.mas_bottom).offset(4);
        make.left.and.right.equalTo(self.progressSlider);
    }];

    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, 600) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf refreshPlaybackTime:time];
    }];
}

/// 搭建缓存状态区(区间可视化条与状态文字)
- (void)setupStatusUI {
    self.rangesView = [[WYMediaCacheRangesView alloc] init];
    self.rangesView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    self.rangesView.layer.cornerRadius = 3;
    self.rangesView.clipsToBounds = YES;
    [self.view addSubview:self.rangesView];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textColor = UIColor.darkGrayColor;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.text = @"等待缓存状态";
    [self.view addSubview:self.statusLabel];

    [self.rangesView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.timeLabel.mas_bottom).offset(12);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(8);
    }];
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.rangesView.mas_bottom).offset(6);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
    }];

    self.urlTextField = [[UITextField alloc] init];
    self.urlTextField.placeholder = @"输入 mp4 视频直链，点下方播放输入框地址";
    self.urlTextField.font = [UIFont systemFontOfSize:13];
    self.urlTextField.textColor = UIColor.darkGrayColor;
    self.urlTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.urlTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:self.urlTextField];
    [self.urlTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statusLabel.mas_bottom).offset(8);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(32);
    }];
}

/// 搭建动作列表
- (void)setupActionList {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];
    // 表头放一份操作指引，照着点就能把缓存能力过一遍
    UILabel *guideLabel = [[UILabel alloc] init];
    guideLabel.text = [self.class guideText];
    guideLabel.font = [UIFont systemFontOfSize:12];
    guideLabel.textColor = UIColor.darkGrayColor;
    guideLabel.numberOfLines = 0;
    CGFloat guideWidth = self.view.bounds.size.width - 32;
    NSAttributedString *guideAttributedString = [[NSAttributedString alloc] initWithString:guideLabel.text attributes:@{NSFontAttributeName: guideLabel.font}];
    CGRect guideRect = [guideAttributedString boundingRectWithSize:CGSizeMake(guideWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, ceil(guideRect.size.height) + 20)];
    guideLabel.frame = CGRectMake(16, 10, guideWidth, ceil(guideRect.size.height));
    [headerView addSubview:guideLabel];
    self.tableView.tableHeaderView = headerView;
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.urlTextField.mas_bottom).offset(8);
        make.left.and.right.and.bottom.equalTo(self.view);
    }];
}

/// 开启缓存状态刷新定时器
- (void)startStatusTimer {
    __weak typeof(self) weakSelf = self;
    self.statusTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *timer) {
        [weakSelf refreshCacheStatus];
    }];
}

/// 动作清单(标题与点击行为)
- (NSArray<NSString *> *)actionTitles {
    return @[@"在线播放(边下边播)",
             @"停止后重播(已缓存部分秒开)",
             @"预下载整个视频",
             @"取消预下载",
             @"播放本地完整缓存文件",
             @"播放输入框地址(边下边播)",
             @"蜂窝流量确认(阈值5MB)开/关",
             @"清除当前素材缓存",
             @"LRU容量淘汰演示(临时上限2MB)",
             @"清空全部缓存"];
}

/// 当前生效的播放地址(输入框地址生效时用它，否则用素材清单当前项)
- (NSURL *)currentMediaURL {
    if (self.activeCustomURL != nil) {
        return self.activeCustomURL;
    }
    return self.mediaList[self.currentIndex];
}

- (void)playCurrentMedia {
    NSURL *mediaURL = self.currentMediaURL;
    AVPlayerItem *item = [WYMediaCache.shared playerItemWithURL:mediaURL];
    [self.player replaceCurrentItemWithPlayerItem:item];
    [self.player play];
    [self.playButton setTitle:@"暂停" forState:UIControlStateNormal];
}

/// 停止后重播当前素材(已缓存部分直接读盘，起播明显变快)
- (void)replayCachedMedia {
    [self.player pause];
    [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self playCurrentMedia];
}

/// 预下载当前素材整个视频
- (void)downloadCurrentMedia {
    NSURL *mediaURL = self.currentMediaURL;
    self.statusLabel.text = @"开始预下载";
    [WYMediaCache.shared downloadWithURL:mediaURL progress:^(long long cachedBytes, long long contentLength) {
        self.statusLabel.text = [NSString stringWithFormat:@"预下载中 %@ / %@", [self.class sizeText:cachedBytes], [self.class sizeText:contentLength]];
    } completion:^(NSError *error) {
        if (error != nil) {
            self.statusLabel.text = [NSString stringWithFormat:@"预下载失败 %@", error.localizedDescription];
        }else {
            self.statusLabel.text = @"预下载完成，可断网重播验证";
        }
    }];
}

/// 取消预下载
- (void)cancelDownload {
    [WYMediaCache.shared cancelDownloadWithURL:self.currentMediaURL];
    self.statusLabel.text = @"已取消预下载";
}

/// 播放本地完整缓存文件(没缓存完整时提示)
- (void)playLocalCachedFile {
    NSString *filePath = [WYMediaCache.shared cachedFilePathForURL:self.currentMediaURL];
    if (filePath == nil) {
        self.statusLabel.text = @"还没有完整缓存，先预下载或完整播一遍";
        return;
    }
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:filePath]];
    [self.player replaceCurrentItemWithPlayerItem:item];
    [self.player play];
    [self.playButton setTitle:@"暂停" forState:UIControlStateNormal];
    self.statusLabel.text = @"正在播放本地缓存文件";
}

/// LRU 容量淘汰演示(临时把上限调到 2MB，依次下载两个小视频，第二个完成后第一个应被淘汰，最后恢复原上限)
- (void)runLRUDemo {
    long long originalLimit = WYMediaCacheConfig.shared.maxCacheSize;
    WYMediaCacheConfig.shared.maxCacheSize = 2 * 1024 * 1024;
    self.statusLabel.text = @"容量上限临时调为 2MB，开始下载小视频1";
    NSURL *firstURL = self.mediaList[1];
    NSURL *secondURL = self.mediaList[2];
    [WYMediaCache.shared downloadWithURL:firstURL progress:nil completion:^(NSError *error) {
        WYMediaCacheStatus *firstStatus = [WYMediaCache.shared cacheStatusForURL:firstURL];
        self.statusLabel.text = [NSString stringWithFormat:@"小视频1完成(完整 %d)，开始下载小视频2", firstStatus.isFullyCached];
        [WYMediaCache.shared downloadWithURL:secondURL progress:nil completion:^(NSError *error) {
            WYMediaCacheStatus *evictedStatus = [WYMediaCache.shared cacheStatusForURL:firstURL];
            WYMediaCacheStatus *keptStatus = [WYMediaCache.shared cacheStatusForURL:secondURL];
            WYMediaCacheConfig.shared.maxCacheSize = originalLimit;
            self.statusLabel.text = [NSString stringWithFormat:@"小视频1被淘汰(%@)，小视频2保留(完整 %d)，容量上限已恢复",
                                     [self.class sizeText:evictedStatus.cachedBytes], keptStatus.isFullyCached];
        }];
    }];
}

/// 切换蜂窝流量确认开关(开为阈值 5MB，关为不限制，真机蜂窝网络下生效)
- (void)toggleCellularConfirm {
    self.cellularConfirmEnabled = !self.cellularConfirmEnabled;
    WYMediaCacheConfig.shared.cellularConfirmSizeLimit = self.cellularConfirmEnabled ? 5 * 1024 * 1024 : 0;
    self.statusLabel.text = self.cellularConfirmEnabled ? @"蜂窝流量确认已开启(阈值 5MB，真机蜂窝网络下生效)" : @"蜂窝流量确认已关闭";
}

/// 播放输入框地址(地址非法时提示)
- (void)playCustomURL {
    NSString *text = self.urlTextField.text;
    if (text.length <= 0 || [text hasPrefix:@"http"] == NO) {
        self.statusLabel.text = @"输入框里先填一个 http/https 的视频直链";
        return;
    }
    NSURL *url = [NSURL URLWithString:text];
    if (url == nil) {
        self.statusLabel.text = @"输入框里先填一个 http/https 的视频直链";
        return;
    }
    self.activeCustomURL = url;
    [self playCurrentMedia];
}

/// 清除当前素材缓存(正在播放的条目闲置后自动清理)
- (void)removeCurrentCache {
    [WYMediaCache.shared removeCacheForURL:self.currentMediaURL];
    self.statusLabel.text = @"已清除当前素材缓存";
    [self refreshCacheStatus];
}

/// 清空全部缓存
- (void)clearAllCache {
    [self.player pause];
    [WYMediaCache.shared clearCache];
    self.statusLabel.text = @"已清空全部缓存";
    [self refreshCacheStatus];
}

/// 刷新缓存状态展示(区间条、进度文字、总容量)
- (void)refreshCacheStatus {
    WYMediaCacheStatus *status = [WYMediaCache.shared cacheStatusForURL:self.currentMediaURL];
    self.rangesView.cachedRanges = status.cachedRanges;
    self.rangesView.contentLength = status.contentLength;
    CMTime duration = self.player.currentItem.duration;
    if (CMTIME_IS_VALID(duration) && CMTimeGetSeconds(duration) > 0) {
        self.rangesView.playbackRatio = CMTimeGetSeconds(self.player.currentTime) / CMTimeGetSeconds(duration);
    }
    [self.rangesView setNeedsDisplay];
    NSString *networkText = WYMediaCache.shared.isNetworkOnline ? (WYMediaCache.shared.isNetworkCellular ? @"蜂窝" : @"WiFi") : @"断网";
    self.statusLabel.text = [NSString stringWithFormat:@"已缓存 %@ / %@，区间数 %lu，缓存目录共 %@，网络 %@",
                             [self.class sizeText:status.cachedBytes],
                             [self.class sizeText:status.contentLength],
                             (unsigned long)status.cachedRanges.count,
                             [self.class sizeText:[WYMediaCache.shared totalCacheSize]],
                             networkText];
}

/// 刷新播放时间展示
- (void)refreshPlaybackTime:(CMTime)time {
    CMTime duration = self.player.currentItem.duration;
    if (CMTIME_IS_VALID(duration) == false || CMTimeGetSeconds(duration) <= 0) {
        return;
    }
    self.progressSlider.value = CMTimeGetSeconds(time) / CMTimeGetSeconds(duration);
    self.timeLabel.text = [NSString stringWithFormat:@"%@ / %@", [self.class timeText:CMTimeGetSeconds(time)], [self.class timeText:CMTimeGetSeconds(duration)]];
}

/// 素材切换
- (void)mediaSegmentChanged {
    self.currentIndex = self.mediaSegment.selectedSegmentIndex;
    self.activeCustomURL = nil;
    [self.player pause];
    [self playCurrentMedia];
}

/// 播放暂停切换
- (void)playButtonClicked {
    if (self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
        [self.player pause];
        [self.playButton setTitle:@"播放" forState:UIControlStateNormal];
    }else {
        [self.player play];
        [self.playButton setTitle:@"暂停" forState:UIControlStateNormal];
    }
}

/// 拖动进度条定位
- (void)progressSliderChanged {
    CMTime duration = self.player.currentItem.duration;
    if (CMTIME_IS_VALID(duration) == false || CMTimeGetSeconds(duration) <= 0) {
        return;
    }
    CMTime target = CMTimeMakeWithSeconds(CMTimeGetSeconds(duration) * self.progressSlider.value, 600);
    [self.player seekToTime:target toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

/// 操作指引文案(每步带预期结果)
+ (NSString *)guideText {
    return @"操作指引\n1 在线播放，绿色缓存条随播放增长，已缓存数字变大\n2 播一段后点停止后重播，起播明显变快(已缓存部分读的本地盘)\n3 预下载整个视频，等进度走完提示完成\n4 断网后点播放本地完整缓存文件，无网也能正常播\n5 LRU容量淘汰演示，上限临时调为 2MB，最久未用的缓存被自动清掉\n6 切换顶部素材再重复，各素材缓存互不影响\n7 在输入框贴自己的视频直链点播放输入框地址，任意网络视频都能测\n8 清除当前素材缓存后重播，重新经历一遍首次缓存\n9 真机蜂窝网络下开启蜂窝流量确认后，播大视频会先弹窗征询\n10 断网再恢复或回前台，播放与预下载自动续起";
}

/// 字节数转显示文字
+ (NSString *)sizeText:(long long)bytes {
    return [NSString stringWithFormat:@"%.1fMB", bytes / 1024.0 / 1024.0];
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
    [self.statusTimer invalidate];
}

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
            [self playCurrentMedia];
            break;
        case 1:
            [self replayCachedMedia];
            break;
        case 2:
            [self downloadCurrentMedia];
            break;
        case 3:
            [self cancelDownload];
            break;
        case 4:
            [self playLocalCachedFile];
            break;
        case 5:
            [self playCustomURL];
            break;
        case 6:
            [self toggleCellularConfirm];
            break;
        case 7:
            [self removeCurrentCache];
            break;
        case 8:
            [self runLRUDemo];
            break;
        default:
            [self clearAllCache];
            break;
    }
}

@end
