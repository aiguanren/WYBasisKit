//
//  WYTestPhotoBrowserController.m
//  ObjCVerify
//
//  Created by 官人 on 2026/10/19.
//

#import "WYTestPhotoBrowserController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

/// 测试入口(标题、浏览项构造与配置构造)
@interface WYTestEntryObjC : NSObject

@property (copy, nonatomic) NSString *title;

@property (copy, nonatomic) NSArray<WYPhotoBrowserItem *> *(^items)(void);

@property (copy, nonatomic) WYPhotoBrowserConfiguration *(^config)(void);

+ (instancetype)entryWithTitle:(NSString *)title items:(NSArray<WYPhotoBrowserItem *> *(^)(void))items config:(WYPhotoBrowserConfiguration *(^)(void))config;

@end

@implementation WYTestEntryObjC

+ (instancetype)entryWithTitle:(NSString *)title items:(NSArray<WYPhotoBrowserItem *> *(^)(void))items config:(WYPhotoBrowserConfiguration *(^)(void))config {
    WYTestEntryObjC *entry = [[WYTestEntryObjC alloc] init];
    entry.title = title;
    entry.items = items;
    entry.config = config;
    return entry;
}

@end

@interface WYTestPhotoBrowserController () <UITableViewDataSource, UITableViewDelegate, WYPhotoBrowserDataSource, WYPhotoBrowserDelegate>

/// 分组入口(组名与入口数组)
@property (nonatomic, strong) NSArray<NSDictionary *> *sections;

/// 当前入口的浏览项(浏览器期间数据源按它供数)
@property (nonatomic, copy) NSArray<WYPhotoBrowserItem *> *currentItems;

/// 本地混排数据集(Resource照片、GIF、两级文件、视频封面、LivePhoto对)
@property (nonatomic, copy) NSArray<WYPhotoBrowserItem *> *localItems;

/// 网络混排数据集(网络图、网络视频、网络LivePhoto对、失败地址)
@property (nonatomic, copy) NSArray<WYPhotoBrowserItem *> *remoteItems;

/// 事件日志(浏览器关闭后回看)
@property (nonatomic, strong) UILabel *logLabel;

/// 分组列表
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation WYTestPhotoBrowserController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"图片浏览";

    self.localItems = [self buildLocalItems];
    self.remoteItems = [self buildRemoteItems];

    self.logLabel = [[UILabel alloc] init];
    self.logLabel.textAlignment = NSTextAlignmentCenter;
    self.logLabel.font = [UIFont systemFontOfSize:12];
    self.logLabel.textColor = UIColor.darkGrayColor;
    self.logLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.logLabel.text = @"代理事件日志会显示在这里";
    [self.view addSubview:self.logLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];

    self.sections = [self buildSections];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat top = self.view.safeAreaInsets.top + 4;
    self.logLabel.frame = CGRectMake(0, top, self.view.bounds.size.width, 28);
    self.tableView.frame = CGRectMake(0, top + 28, self.view.bounds.size.width, self.view.bounds.size.height - top - 28);
}

/// 写一条事件日志
- (void)log:(NSString *)text {
    self.logLabel.text = text;
}

/// 取Resource文件全路径
- (NSString *)resourcePath:(NSString *)name ext:(NSString *)ext {
    return [NSBundle.mainBundle pathForResource:name ofType:ext] ?: @"";
}

/// 抽视频首帧做封面
- (UIImage *)videoPosterWithPath:(NSString *)path {
    if (path.length == 0) {
        return nil;
    }
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake(800, 800);
    CGImageRef frame = [generator copyCGImageAtTime:CMTimeMakeWithSeconds(0.5, 600) actualTime:nil error:nil];
    if (frame == nil) {
        return nil;
    }
    UIImage *poster = [UIImage imageWithCGImage:frame];
    CGImageRelease(frame);
    return poster;
}

/// 构造本地混排数据集
- (NSArray<WYPhotoBrowserItem *> *)buildLocalItems {
    NSMutableArray<WYPhotoBrowserItem *> *items = [NSMutableArray array];
    NSArray<NSString *> *photoNames = @[@"樱花", @"夕阳下的花", @"秋天的树", @"蓝色小屋", @"帆船", @"沙滩上的花"];
    [photoNames enumerateObjectsUsingBlock:^(NSString *photoName, NSUInteger index, BOOL *stop) {
        WYPhotoBrowserItem *item = [[WYPhotoBrowserItem alloc] init];
        item.placeholder = [UIImage imageNamed:photoName];
        item.identifier = [NSString stringWithFormat:@"oc_local_%lu", (unsigned long)index];
        [items addObject:item];
    }];

    WYPhotoBrowserItem *twoLevelItem = [[WYPhotoBrowserItem alloc] init];
    twoLevelItem.thumbnailPath = [self resourcePath:@"沙滩上的花" ext:@"png"];
    twoLevelItem.originalPath = [self resourcePath:@"夕阳下的花" ext:@"png"];
    twoLevelItem.identifier = @"oc_two_level_local";
    [items addObject:twoLevelItem];

    WYPhotoBrowserItem *gifItem = [[WYPhotoBrowserItem alloc] init];
    gifItem.originalPath = [self resourcePath:@"关注主播" ext:@"gif"];
    gifItem.identifier = @"oc_local_gif";
    [items addObject:gifItem];

    for (NSString *videoName in @[@"乌篷转桨晃一晃，春风牵衣过平江", @"树屋"]) {
        NSString *videoPath = [self resourcePath:videoName ext:@"mp4"];
        WYPhotoBrowserItem *videoItem = [[WYPhotoBrowserItem alloc] init];
        videoItem.placeholder = [self videoPosterWithPath:videoPath];
        videoItem.mediaType = WYPhotoBrowserMediaTypeVideo;
        videoItem.identifier = [NSString stringWithFormat:@"play:%@", videoPath];
        [items addObject:videoItem];
    }

    NSArray<NSString *> *livePhotoNames = @[@"棕榈步道", @"水中游鸟"];
    for (NSInteger sample = 1; sample <= livePhotoNames.count; sample++) {
        NSString *name = livePhotoNames[sample - 1];
        WYPhotoBrowserItem *liveItem = [[WYPhotoBrowserItem alloc] init];
        liveItem.mediaType = WYPhotoBrowserMediaTypeLivePhoto;
        liveItem.placeholder = [UIImage imageWithContentsOfFile:[self resourcePath:name ext:@"heic"]];
        liveItem.livePhotoStillURL = [NSURL fileURLWithPath:[self resourcePath:name ext:@"heic"]];
        liveItem.livePhotoVideoURL = [NSURL fileURLWithPath:[self resourcePath:name ext:@"mov"]];
        liveItem.identifier = [NSString stringWithFormat:@"oc_live_local_%ld", (long)sample];
        [items addObject:liveItem];
    }
    return items;
}

/// 构造网络混排数据集
- (NSArray<WYPhotoBrowserItem *> *)buildRemoteItems {
    NSMutableArray<WYPhotoBrowserItem *> *items = [NSMutableArray array];
    for (NSInteger index = 0; index < 2; index++) {
        WYPhotoBrowserItem *item = [[WYPhotoBrowserItem alloc] init];
        item.thumbnailURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://picsum.photos/seed/ocbrowser%ld/400/500", (long)index]];
        item.originalURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://picsum.photos/seed/ocbrowser%ld/1200/1500", (long)index]];
        item.originalFileSize = 2411724;
        item.identifier = [NSString stringWithFormat:@"oc_remote_%ld", (long)index];
        [items addObject:item];
    }

    WYPhotoBrowserItem *videoItem = [[WYPhotoBrowserItem alloc] init];
    videoItem.thumbnailURL = [NSURL URLWithString:@"https://picsum.photos/seed/ocvideo/400/500"];
    videoItem.mediaType = WYPhotoBrowserMediaTypeVideo;
    videoItem.identifier = @"play:https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4";
    [items addObject:videoItem];

    WYPhotoBrowserItem *liveItem = [[WYPhotoBrowserItem alloc] init];
    liveItem.mediaType = WYPhotoBrowserMediaTypeLivePhoto;
    liveItem.livePhotoStillURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/NightMean/MotionPhotoSamples/main/Apple%20Live%20Photo/Apple%20iPhone%2015%20-%20photo.HEIC"];
    liveItem.livePhotoVideoURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/NightMean/MotionPhotoSamples/main/Apple%20Live%20Photo/Apple%20iPhone%2015%20-%20video.MOV"];
    liveItem.identifier = @"oc_live_remote";
    [items addObject:liveItem];

    WYPhotoBrowserItem *invalidItem = [[WYPhotoBrowserItem alloc] init];
    invalidItem.thumbnailURL = [NSURL URLWithString:@"https://invalid.wybasiskit.test/none.jpg"];
    invalidItem.identifier = @"oc_invalid_url";
    [items addObject:invalidItem];
    return items;
}

/// 菜单里的关闭动作(覆盖dismissBrowser方法)
- (WYPhotoBrowserAction *)closeAction {
    return [[WYPhotoBrowserAction alloc] initWithTitle:@"关闭浏览器" icon:[UIImage systemImageNamed:@"xmark"] handler:^(WYPhotoBrowser *browser, NSInteger index) {
        [browser dismissBrowserWithAnimated:YES];
    }];
}

/// 构造全部分组入口
- (NSArray<NSDictionary *> *)buildSections {
    NSMutableArray *sections = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;

    void (^appendSection)(NSString *, NSArray<WYTestEntryObjC *> *) = ^(NSString *title, NSArray<WYTestEntryObjC *> *entries) {
        [sections addObject:@{@"title": title, @"entries": entries}];
    };

    appendSection(@"真实混排体验", @[
        [WYTestEntryObjC entryWithTitle:@"本地混排(照片/GIF/两级/视频/Live)" items:^{ return weakSelf.localItems; } config:^{ return [[WYPhotoBrowserConfiguration alloc] init]; }],
        [WYTestEntryObjC entryWithTitle:@"网络混排(图/视频/Live/失败重试)" items:^{ return weakSelf.remoteItems; } config:^{ return [[WYPhotoBrowserConfiguration alloc] init]; }],
        [WYTestEntryObjC entryWithTitle:@"本地加网络全混排" items:^{ return [weakSelf.localItems arrayByAddingObjectsFromArray:weakSelf.remoteItems]; } config:^{ return [[WYPhotoBrowserConfiguration alloc] init]; }],
    ]);

    appendSection(@"配置变体", @[
        [WYTestEntryObjC entryWithTitle:@"纵向翻页(信息流)" items:^{ return weakSelf.localItems; } config:^{
            WYPhotoBrowserConfiguration *configuration = [[WYPhotoBrowserConfiguration alloc] init];
            configuration.scrollDirection = WYPhotoBrowserScrollDirectionVertical;
            return configuration;
        }],
        [WYTestEntryObjC entryWithTitle:@"渐隐转场+圆点页码" items:^{ return weakSelf.localItems; } config:^{
            WYPhotoBrowserConfiguration *configuration = [[WYPhotoBrowserConfiguration alloc] init];
            configuration.transitionStyle = WYPhotoBrowserTransitionStyleFade;
            configuration.pageIndicatorStyle = WYPhotoBrowserPageIndicatorStyleDots;
            return configuration;
        }],
        [WYTestEntryObjC entryWithTitle:@"自动原图+双击3倍+上限5倍" items:^{ return weakSelf.remoteItems; } config:^{
            WYPhotoBrowserConfiguration *configuration = [[WYPhotoBrowserConfiguration alloc] init];
            configuration.originalLoadStyle = WYPhotoBrowserOriginalLoadStyleAutomatic;
            configuration.doubleTapZoomScale = 3;
            configuration.maxZoomScale = 5;
            return configuration;
        }],
        [WYTestEntryObjC entryWithTitle:@"禁单击+禁拖拽(用菜单关)" items:^{ return weakSelf.localItems; } config:^{
            WYPhotoBrowserConfiguration *configuration = [[WYPhotoBrowserConfiguration alloc] init];
            configuration.allowsTapDismiss = NO;
            configuration.allowsDragDismiss = NO;
            configuration.customActions = @[[weakSelf closeAction]];
            return configuration;
        }],
        [WYTestEntryObjC entryWithTitle:@"拖拽阈值60(轻拖即关)+预取关闭" items:^{ return weakSelf.localItems; } config:^{
            WYPhotoBrowserConfiguration *configuration = [[WYPhotoBrowserConfiguration alloc] init];
            configuration.dragDismissThreshold = 60;
            configuration.prefetchCount = 0;
            return configuration;
        }],
        [WYTestEntryObjC entryWithTitle:@"循环翻页+自动轮播2秒" items:^{ return weakSelf.localItems; } config:^{
            WYPhotoBrowserConfiguration *configuration = [[WYPhotoBrowserConfiguration alloc] init];
            configuration.allowsLoopScrolling = YES;
            configuration.autoCarouselInterval = 2;
            return configuration;
        }],
        [WYTestEntryObjC entryWithTitle:@"多页同屏+缩小压暗特效" items:^{ return weakSelf.localItems; } config:^{
            WYPhotoBrowserConfiguration *configuration = [[WYPhotoBrowserConfiguration alloc] init];
            configuration.layoutStyle = WYPhotoBrowserLayoutStyleMultiPage;
            configuration.transformStyle = WYPhotoBrowserTransformStyleDepth;
            return configuration;
        }],
        [WYTestEntryObjC entryWithTitle:@"多页同屏+堆叠特效+循环轮播" items:^{ return weakSelf.localItems; } config:^{
            WYPhotoBrowserConfiguration *configuration = [[WYPhotoBrowserConfiguration alloc] init];
            configuration.layoutStyle = WYPhotoBrowserLayoutStyleMultiPage;
            configuration.transformStyle = WYPhotoBrowserTransformStyleStack;
            configuration.allowsLoopScrolling = YES;
            configuration.autoCarouselInterval = 2;
            return configuration;
        }],
    ]);

    appendSection(@"外观与菜单", @[
        [WYTestEntryObjC entryWithTitle:@"深蓝定制主题(外观字段全赋值)" items:^{ return [weakSelf.localItems arrayByAddingObjectsFromArray:weakSelf.remoteItems]; } config:^{
            WYPhotoBrowserConfiguration *configuration = [[WYPhotoBrowserConfiguration alloc] init];
            WYPhotoBrowserAppearance *appearance = [[WYPhotoBrowserAppearance alloc] init];
            appearance.backgroundColor = [UIColor colorWithRed:0.04 green:0.1 blue:0.24 alpha:1];
            appearance.pageIndicatorTextColor = [UIColor colorWithRed:1 green:0.8 blue:0.2 alpha:1];
            appearance.pageIndicatorFontSize = 16;
            appearance.pageIndicatorDotColor = [UIColor colorWithWhite:1 alpha:0.25];
            appearance.pageIndicatorCurrentDotColor = [UIColor colorWithRed:1 green:0.8 blue:0.2 alpha:1];
            appearance.playButtonIconColor = UIColor.whiteColor;
            appearance.playButtonBackgroundColor = [UIColor colorWithRed:0.1 green:0.35 blue:0.9 alpha:0.75];
            appearance.livePhotoBadgeBackgroundColor = [UIColor colorWithRed:1 green:0.8 blue:0.2 alpha:0.85];
            appearance.livePhotoBadgeTextColor = [UIColor colorWithRed:0.04 green:0.1 blue:0.24 alpha:1];
            appearance.livePhotoBadgeFontSize = 12;
            appearance.progressRingColor = [UIColor colorWithRed:1 green:0.8 blue:0.2 alpha:1];
            appearance.progressRingTrackColor = [UIColor colorWithWhite:1 alpha:0.2];
            appearance.progressLabelColor = UIColor.whiteColor;
            appearance.progressLabelFontSize = 14;
            appearance.retryButtonBackgroundColor = [UIColor colorWithRed:0.75 green:0.15 blue:0.15 alpha:0.9];
            appearance.retryButtonTextColor = UIColor.whiteColor;
            appearance.retryButtonFontSize = 15;
            appearance.originalButtonBackgroundColor = [UIColor colorWithRed:0.1 green:0.35 blue:0.9 alpha:0.85];
            appearance.originalButtonTextColor = UIColor.whiteColor;
            appearance.originalButtonFontSize = 15;
            appearance.menuBackgroundColor = [UIColor colorWithRed:0.06 green:0.16 blue:0.36 alpha:0.95];
            appearance.menuTextColor = [UIColor colorWithRed:1 green:0.8 blue:0.2 alpha:1];
            appearance.menuFontSize = 16;
            appearance.menuHighlightBackgroundColor = [UIColor colorWithWhite:1 alpha:0.18];
            appearance.menuCornerRadius = 20;
            configuration.appearance = appearance;
            return configuration;
        }],
        [WYTestEntryObjC entryWithTitle:@"仅自定义动作(无保存)+程序化跳页" items:^{ return weakSelf.localItems; } config:^{
            WYPhotoBrowserConfiguration *configuration = [[WYPhotoBrowserConfiguration alloc] init];
            configuration.showsSaveAction = NO;
            WYPhotoBrowserAction *forward = [[WYPhotoBrowserAction alloc] initWithTitle:@"转发" icon:[UIImage systemImageNamed:@"arrowshape.turn.up.right"] handler:^(WYPhotoBrowser *browser, NSInteger index) {
                [weakSelf log:[NSString stringWithFormat:@"转发动作 第%ld页", (long)(index + 1)]];
            }];
            WYPhotoBrowserAction *jumpLast = [[WYPhotoBrowserAction alloc] initWithTitle:@"跳到最后一页" icon:[UIImage systemImageNamed:@"forward.end"] handler:^(WYPhotoBrowser *browser, NSInteger index) {
                [weakSelf log:[NSString stringWithFormat:@"scrollToItem 到第%ld页", (long)weakSelf.currentItems.count]];
                [browser scrollToItemAt:weakSelf.currentItems.count - 1 animated:YES];
            }];
            WYPhotoBrowserAction *append = [[WYPhotoBrowserAction alloc] initWithTitle:@"数据+1并刷新" icon:[UIImage systemImageNamed:@"plus.circle"] handler:^(WYPhotoBrowser *browser, NSInteger index) {
                WYPhotoBrowserItem *extra = [[WYPhotoBrowserItem alloc] initWithLocalImage:[UIImage imageNamed:@"樱花"]];
                extra.identifier = [NSString stringWithFormat:@"oc_appended_%ld", (long)weakSelf.currentItems.count];
                weakSelf.currentItems = [weakSelf.currentItems arrayByAddingObject:extra];
                [browser reloadData];
                [weakSelf log:[NSString stringWithFormat:@"数据+1 现在共%ld项", (long)weakSelf.currentItems.count]];
            }];
            configuration.customActions = @[forward, jumpLast, append, [weakSelf closeAction]];
            return configuration;
        }],
    ]);

    return sections;
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section][@"title"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sections[section][@"entries"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    WYTestEntryObjC *entry = self.sections[indexPath.section][@"entries"][indexPath.row];
    cell.textLabel.text = entry.title;
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    WYTestEntryObjC *entry = self.sections[indexPath.section][@"entries"][indexPath.row];
    NSArray<WYPhotoBrowserItem *> *items = entry.items();
    if (items.count == 0) {
        return;
    }
    self.currentItems = items;
    [self log:[NSString stringWithFormat:@"进入[%@]", entry.title]];
    [WYPhotoBrowserController showFromViewController:self index:0 dataSource:self configuration:entry.config() delegate:self];
}

#pragma mark - WYPhotoBrowserDataSource

- (NSInteger)numberOfItemsInPhotoBrowser:(WYPhotoBrowser *)photoBrowser {
    return self.currentItems.count;
}

- (id)photoBrowser:(WYPhotoBrowser *)photoBrowser itemAtIndex:(NSInteger)index {
    return self.currentItems[index];
}

#pragma mark - WYPhotoBrowserDelegate

- (void)wy_photoBrowser:(WYPhotoBrowser *)photoBrowser didShowItemAt:(NSInteger)index {
    [self log:[NSString stringWithFormat:@"翻页落定 第%ld页 共%ld页", (long)(index + 1), (long)self.currentItems.count]];
}

- (void)wy_photoBrowser:(WYPhotoBrowser *)photoBrowser didLongPressItemAt:(NSInteger)index {
    [self log:[NSString stringWithFormat:@"长按 第%ld页(菜单已弹出)", (long)(index + 1)]];
}

- (void)wy_photoBrowser:(WYPhotoBrowser *)photoBrowser didTapPlayVideoItemAt:(NSInteger)index {
    if (index < 0 || index >= self.currentItems.count) {
        return;
    }
    NSString *identifier = self.currentItems[index].identifier ?: @"";
    if ([identifier hasPrefix:@"play:"] == NO) {
        return;
    }
    NSURL *playURL = [NSURL URLWithString:[identifier substringFromIndex:5]];
    if (playURL == nil) {
        return;
    }
    [self log:[NSString stringWithFormat:@"播放回调 第%ld页(%@视频，已接管播放)", (long)(index + 1), [identifier hasPrefix:@"play:http"] ? @"网络" : @"本地"]];
    AVPlayerViewController *playerController = [[AVPlayerViewController alloc] init];
    playerController.player = [AVPlayer playerWithURL:playURL];
    playerController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:playerController animated:YES completion:^{
        [playerController.player play];
    }];
}

- (void)wy_photoBrowser:(WYPhotoBrowser *)photoBrowser didFinishLoadingOriginalItemAt:(NSInteger)index {
    [self log:[NSString stringWithFormat:@"原图加载完成 第%ld页", (long)(index + 1)]];
}

- (void)wy_photoBrowserDidDismiss:(WYPhotoBrowser *)photoBrowser {
    [self log:@"浏览器已关闭"];
}

@end
