//
//  WYTestVideoPlayerController.m
//  ObjCVerify
//
//  Created by guanren on 2026/10/19.
//

#import "WYTestVideoPlayerController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>
@import AVKit;

/// 点播播放器测试页(边下边播叠弹幕字幕，演示手势壳全屏清晰度切换截图画中画与代理回调)
@interface WYTestVideoPlayerController () <WYVideoPlayerDelegate, UITableViewDataSource, UITableViewDelegate>

/// 播放器
@property (strong, nonatomic) WYVideoPlayer *player;

/// 截图预览小图
@property (strong, nonatomic) UIImageView *snapshotImageView;

/// 状态文字(状态/时间/最近一条代理日志)
@property (strong, nonatomic) UILabel *statusLabel;

/// 操作列表
@property (strong, nonatomic) UITableView *tableView;

/// 自动弹幕计数
@property (assign, nonatomic) NSInteger danmakuIndex;

/// 自动弹幕定时器
@property (strong, nonatomic) NSTimer *danmakuTimer;

/// 演示用多档素材(同一支幕后花絮的1080p与360p，切清晰度时画面内容不变)
@property (strong, nonatomic) WYVideoPlayerMediaAsset *multiAsset;

/// 演示用单档素材(约12分钟的长片，验证单档地址的完整播放流程)
@property (strong, nonatomic) WYVideoPlayerMediaAsset *singleAsset;

@end

@implementation WYTestVideoPlayerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"点播播放器";
    WYVideoPlayerMediaQuality *standard = [WYVideoPlayerMediaQuality qualityWithName:@"标清" URL:[NSURL URLWithString:@"https://videoal-platform.cdn.huya.com/leaf/1048585/59a91b252545dcc3e53b1e831b45d090/99634977/73467960_2e4da4f83b6e2e39a68377497b56de2f_264_360_1.mp4?hyvid=1093775374&hyauid=1239535418978&hyroomid=1239535418978&hyratio=350&hyscence=vod&appid=66&domainid=41&srckey=NjZfNDFfMTA5Mzc3NTM3NA%3D%3D&&bitrate=328&client=110&definition=350&pid=1239535418978&scene=vod&vid=1093775374"]];
    WYVideoPlayerMediaQuality *high = [WYVideoPlayerMediaQuality qualityWithName:@"高清" URL:[NSURL URLWithString:@"https://videoal-platform.cdn.huya.com/leaf/1048585/59a91b252545dcc3e53b1e831b45d090/99634977/73467960_d3f67e02fa27857a54ca55b15f2c5878_264_1080_1_max.mp4?hyvid=1093775374&hyauid=1239535418978&hyroomid=1239535418978&hyratio=4000&hyscence=vod&appid=66&domainid=41&srckey=NjZfNDFfMTA5Mzc3NTM3NA%3D%3D&&bitrate=1803&client=110&definition=yuanhua&pid=1239535418978&scene=vod&vid=1093775374"]];
    self.multiAsset = [WYVideoPlayerMediaAsset assetWithQualities:@[standard, high] defaultIndex:0];
    self.singleAsset = [WYVideoPlayerMediaAsset assetWithURL:[NSURL URLWithString:@"https://file.digitaling.com/eImg/uvideos/2026/0202/1770014172754013.mp4"]];
    [self setupPlayerUI];
    [self setupStatusUI];
    [self setupActionList];
    self.player.delegate = self;
    self.player.configuration.shellShowsSnapshotButton = YES;
    [self.player playWithAsset:self.multiAsset];
}

/// 搭建播放器与截图预览
- (void)setupPlayerUI {
    self.player = [[WYVideoPlayer alloc] init];
    [self.view addSubview:self.player];
    __weak typeof(self) weakSelf = self;
    [self.player mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.view.mas_safeAreaLayoutGuide).offset(8);
        make.left.and.right.equalTo(weakSelf.view);
        make.height.mas_equalTo(weakSelf.player.mas_width).multipliedBy(9.0 / 16.0);
    }];
    self.snapshotImageView = [[UIImageView alloc] init];
    self.snapshotImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.snapshotImageView.layer.borderWidth = 1;
    self.snapshotImageView.layer.borderColor = [UIColor.lightGrayColor CGColor];
    [self.view addSubview:self.snapshotImageView];
    [self.snapshotImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.player.mas_bottom).offset(8);
        make.right.equalTo(weakSelf.view).offset(-16);
        make.width.and.height.mas_equalTo(72);
    }];
}

/// 搭建状态区
- (void)setupStatusUI {
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textColor = UIColor.darkGrayColor;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.text = @"等待播放";
    [self.view addSubview:self.statusLabel];
    __weak typeof(self) weakSelf = self;
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.player.mas_bottom).offset(8);
        make.left.equalTo(weakSelf.view).offset(16);
        make.right.equalTo(weakSelf.snapshotImageView.mas_left).offset(-8);
    }];
}

/// 搭建操作列表
- (void)setupActionList {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];
    __weak typeof(self) weakSelf = self;
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.statusLabel.mas_bottom).offset(6);
        make.left.and.right.and.bottom.equalTo(weakSelf.view);
    }];
}

/// 动作清单(标题与点击行为)
- (NSArray<NSString *> *)actionTitles {
    return @[@"播放 / 暂停",
             @"定位到中间",
             @"倍速 1.0 / 1.5 / 2.0 循环",
             @"切清晰度 高清 / 标清",
             @"换单档素材(长片)",
             @"加内联SRT字幕并选中",
             @"关闭字幕",
             @"开弹幕 + 发一条",
             @"自动弹幕 开/关",
             @"截图",
             @"进 / 退全屏",
             @"画中画(真机)",
             @"边下边播 开/关",
             @"边播边缓存状态",
             @"重播"];
}

/// 记一条日志
- (void)log:(NSString *)text {
    self.statusLabel.text = text;
}

/// 装入内联 SRT 字幕并选中
- (void)loadInlineSubtitle {
    NSString *srt = @"1\n00:00:00,500 --> 00:00:02,500\n内联SRT字幕第一条\n\n2\n00:00:03,000 --> 00:00:05,000\n字幕跟播放时间刷新\n\n3\n00:00:06,000 --> 00:00:08,000\n第三条内联字幕\n";
    WYVideoPlayerSubtitleTrack *track = [WYVideoPlayerSubtitleTrack trackWithName:@"内联SRT" srtText:srt];
    [self.player appendSubtitleTrack:track];
    NSUInteger index = [self.player.subtitleTracks indexOfObject:track];
    if (index == NSNotFound) {
        index = 0;
    }
    [self.player selectSubtitleAtIndex:index];
}

/// 自动弹幕开关
- (void)toggleAutoDanmaku {
    if (self.danmakuTimer != nil) {
        [self.danmakuTimer invalidate];
        self.danmakuTimer = nil;
    } else {
        __weak typeof(self) weakSelf = self;
        self.danmakuTimer = [NSTimer scheduledTimerWithTimeInterval:1.2 repeats:YES block:^(NSTimer *timer) {
            __strong typeof(weakSelf) self = weakSelf;
            if (self == nil) {
                return;
            }
            NSArray<NSNumber *> *types = @[@(WYDanmakuTypeScroll), @(WYDanmakuTypeScroll), @(WYDanmakuTypeTop), @(WYDanmakuTypeBottom)];
            [self.player sendDanmaku:[NSString stringWithFormat:@"自动弹幕%ld", (long)self.danmakuIndex] type:types[self.danmakuIndex % types.count].integerValue];
            self.danmakuIndex += 1;
        }];
    }
}

- (void)dealloc {
    [self.danmakuTimer invalidate];
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
            if (self.player.state == WYVideoPlayerStatePlaying) {
                [self.player pauseVideo];
            } else {
                [self.player resumeVideo];
            }
            break;
        case 1:
            [self.player seekToTime:self.player.duration / 2 accurate:YES];
            break;
        case 2: {
            NSArray<NSNumber *> *options = @[@1.0, @1.5, @2.0];
            NSUInteger currentIndex = [options indexOfObjectPassingTest:^BOOL(NSNumber *rate, NSUInteger idx, BOOL *stop) {
                return fabs(rate.doubleValue - self.player.rate) < 0.01;
            }];
            if (currentIndex == NSNotFound) {
                currentIndex = -1;
            }
            self.player.rate = options[(currentIndex + 1) % options.count].floatValue;
            break;
        }
        case 3:
            [self.player selectQualityAtIndex:(self.player.currentAsset.selectedIndex == 0) ? 1 : 0];
            break;
        case 4:
            [self.player playWithAsset:self.singleAsset];
            break;
        case 5:
            [self loadInlineSubtitle];
            break;
        case 6:
            [self.player selectSubtitleAtIndex:-1];
            break;
        case 7:
            if (self.player.danmakuView == nil) {
                self.player.configuration.showsDanmaku = YES;
            }
            [self.player sendDanmaku:[NSString stringWithFormat:@"弹幕跟播放时间走%ld", (long)self.danmakuIndex] type:WYDanmakuTypeScroll];
            self.danmakuIndex += 1;
            break;
        case 8:
            [self toggleAutoDanmaku];
            break;
        case 9:
            [self.player snapshotWithCompletion:nil];
            break;
        case 10:
            if (self.player.isFullscreen) {
                [self.player exitFullscreen];
            } else {
                [self.player enterFullscreen];
            }
            break;
        case 11:
            [self.player startPictureInPicture];
            break;
        case 12:
            self.player.configuration.usesMediaCache = !self.player.configuration.usesMediaCache;
            [self.player playWithAsset:self.multiAsset];
            break;
        case 13: {
            NSURL *url = self.player.currentAsset.currentQuality.url;
            WYMediaCacheStatus *status = [WYMediaCache.shared cacheStatusForURL:url];
            [self log:[NSString stringWithFormat:@"已缓存 %.1fMB / %.1fMB", status.cachedBytes / 1024.0 / 1024.0, status.contentLength / 1024.0 / 1024.0]];
            break;
        }
        default:
            [self.player seekToTime:0 accurate:NO];
            [self.player resumeVideo];
            break;
    }
}

#pragma mark - WYVideoPlayerDelegate

- (void)wy_videoPlayer:(WYVideoPlayer *)player stateDidChange:(WYVideoPlayerState)state {
    [self log:[NSString stringWithFormat:@"状态 %ld", (long)state]];
}

- (void)wy_videoPlayer:(WYVideoPlayer *)player currentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration playableDuration:(NSTimeInterval)playableDuration {
    self.statusLabel.text = [NSString stringWithFormat:@"%lds / %lds，缓冲到 %lds，状态 %@", (long)currentTime, (long)duration, (long)playableDuration, player.state == WYVideoPlayerStatePlaying ? @"播放中" : @"非播放"];
}

- (void)wy_videoPlayer:(WYVideoPlayer *)player didTakeSnapshot:(UIImage *)image {
    self.snapshotImageView.image = image;
    [self log:image == nil ? @"截图失败" : @"截图完成"];
}

- (void)wy_videoPlayer:(WYVideoPlayer *)player qualityDidChangeAtIndex:(NSInteger)qualityIndex {
    [self log:[NSString stringWithFormat:@"清晰度切到 %@", player.currentAsset.qualities[qualityIndex].name]];
}

- (void)wy_videoPlayer:(WYVideoPlayer *)player subtitleDidChangeAtIndex:(NSInteger)trackIndex {
    [self log:[NSString stringWithFormat:@"字幕轨 %ld", (long)trackIndex]];
}

- (void)wy_videoPlayer:(WYVideoPlayer *)player seekPanDidEndWithTargetTime:(NSTimeInterval)targetTime {
    [self log:[NSString stringWithFormat:@"横滑定位到 %lds", (long)targetTime]];
}

@end
