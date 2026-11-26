//
//  WYTestChatController.m
//  ObjCVerify
//
//  Created by guanren on 2026/11/8.
//

#import "WYTestChatController.h"
#import "WYChatTestSuite.h"
#import <AVFoundation/AVFoundation.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestChatController () <WYChatViewDelegate, AVAudioPlayerDelegate>
@property (nonatomic, strong) WYChatView *chatView;
@property (nonatomic, strong) AVAudioPlayer *voicePlayer;
@property (nonatomic, copy) NSString *playingVoiceID;
@end

@implementation WYTestChatController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"聊天界面";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"测试" style:UIBarButtonItemStylePlain target:self action:@selector(showChatTests)];
    WYChatConfig *config = [[WYChatConfig alloc] init];
    config.input.draftStorageKey = @"objc-chat-example";
    config.recording.supportSpeechRecognition = true;
    config.recording.speechRecognitionSource = WYChatSpeechRecognitionSourceApple;
    WYSourceBundle *resources = [[WYSourceBundle alloc] initWithTargetClass:nil bundleName:@"WYChatView" subdirectory:@""];
    config.more.moreSource = @[
        @{@"照片": [UIImage wy_find:@"zhaopian" bundle:nil]},
        @{@"拍摄": [UIImage wy_find:@"paishe" bundle:nil]},
        @{@"位置": [UIImage wy_find:@"weizhi" bundle:nil]},
        @{@"文件": [UIImage wy_find:@"wenjianjia" bundle:nil]},
        @{@"收藏": [UIImage wy_find:@"shoucang" bundle:nil]},
        @{@"个人名片": [UIImage wy_find:@"gerenmingpian" bundle:nil]},
        @{@"音乐": [UIImage wy_find:@"yinle" bundle:nil]},
        @{@"发红包": [UIImage systemImageNamed:@"gift"] ?: [[UIImage alloc] init]},
        @{@"转账": [UIImage systemImageNamed:@"arrow.left.arrow.right"] ?: [[UIImage alloc] init]}
    ];
    UIEdgeInsets moreInset = config.more.contentInset;
    moreInset.bottom = [UIDevice wy_screenWidth:40];
    config.more.contentInset = moreInset;
    config.imageLoader = ^(WYChatAssetsModel *asset, UIImageView *imageView, NSString *messageID) {
        if (asset.name.length == 0) { return; }
        NSString *name = [asset.name isEqualToString:@"doc"] ? @"WYChatViewFile" : asset.name;
        imageView.image = [UIImage imageNamed:name] ?: [UIImage systemImageNamed:name] ?: [UIImage wy_find:name bundle:resources];
    };
    WYChatUserModel *user = [[WYChatUserModel alloc] init];
    user.id = @"current-user";
    user.name = @"自己";
    self.chatView = WYChatView.create(user, config);
    self.chatView.delegate = self;
    __weak typeof(self) weakSelf = self;
    self.chatView.messagePreparedHandler = ^(WYChatMessageModel *message) { [weakSelf prepareExampleMessage:message]; };
    self.chatView.voicePlaybackRateHandler = ^(NSString *messageID, float rate) {
        if ([weakSelf.playingVoiceID isEqualToString:messageID]) { weakSelf.voicePlayer.rate = rate; }
    };
    self.chatView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.chatView];
    [NSLayoutConstraint activateConstraints:@[
        [self.chatView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.chatView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.chatView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.chatView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    WYChatMessageModel *message = [[WYChatMessageModel alloc] init];
    message.messageID = NSUUID.UUID.UUIDString;
    message.sender.name = @"示例联系人";
    message.sender.id = @"contact";
    message.content.text = @"这条消息展示ObjC接入、气泡配置和消息菜单。";
    message.sendState = WYChatMessageSendStateSuccess;
    self.chatView.appendMessages(@[message]);
    self.chatView.scrollToLastMessage(false);
}

- (void)wy_didClickMoreView:(WYChatMoreView *)moreView itemIndex:(NSInteger)itemIndex {
    NSArray<NSDictionary<NSString *, UIImage *> *> *items = moreView.moreViewConfig.moreSource;
    if (itemIndex < 0 || (NSUInteger)itemIndex >= items.count) { return; }
    NSString *title = items[itemIndex].allKeys.firstObject;
    if (!title || ![@[@"发红包", @"转账", @"音乐", @"个人名片"] containsObject:title]) { return; }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:@"已收到更多菜单点击事件，接入方可在此打开对应功能。" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)prepareExampleMessage:(WYChatMessageModel *)message {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        typeof(self) self = weakSelf;
        if (!self) { return; }
        NSMutableArray<WYChatMessageModel *> *messages = self.chatView.dataSource.mutableCopy;
        for (WYChatMessageModel *item in messages) {
            if ([item.messageID isEqualToString:message.messageID]) { item.sendState = WYChatMessageSendStateSuccess; }
        }
        self.chatView.dataSource = messages;
    });
}

- (void)updateExampleVoice:(NSString *)messageID playing:(BOOL)playing {
    NSMutableArray<WYChatMessageModel *> *messages = self.chatView.dataSource.mutableCopy;
    for (WYChatMessageModel *item in messages) {
        if ([item.messageID isEqualToString:messageID]) {
            item.content.voice.isPlaying = playing;
            item.content.voice.played = true;
            item.content.voice.pause = !playing && !self.chatView.configuration.voicePlayback.restartsOnTap;
            item.content.voice.currentPlayDuration = self.voicePlayer.currentTime;
        }
    }
    self.chatView.dataSource = messages;
}

- (void)stopExampleVoice {
    [self.voicePlayer stop];
    self.voicePlayer.currentTime = 0;
    if (self.playingVoiceID) { [self updateExampleVoice:self.playingVoiceID playing:false]; }
    self.voicePlayer = nil;
    self.playingVoiceID = nil;
}

- (void)showVoiceError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"语音处理失败" message:[NSString stringWithFormat:@"%@\n%@ (%ld)", error.localizedDescription, error.domain, (long)error.code] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];
    if (!self.presentedViewController) { [self presentViewController:alert animated:true completion:nil]; }
}

- (void)wy_messageAction:(WYChatView *)chatView action:(WYChatAction)action messageID:(NSString *)messageID {
    WYChatMessageModel *message = chatView.messageModelFrom(messageID);
    if (action == WYChatActionRetry) { [self prepareExampleMessage:message]; return; }
    if (action == WYChatActionPause && [self.playingVoiceID isEqualToString:messageID]) {
        if (chatView.configuration.voicePlayback.restartsOnTap) { [self stopExampleVoice]; }
        else { [self.voicePlayer pause]; [self updateExampleVoice:messageID playing:false]; }
        return;
    }
    if (action != WYChatActionPlay || !message.content.voice) { return; }
    NSError *error = nil;
    WYChatVoiceModel *voice = message.content.voice;
    if (![self.playingVoiceID isEqualToString:messageID] || !self.voicePlayer) {
        [self stopExampleVoice];
        NSString *path = nil;
        for (NSString *candidate in @[voice.localPath, voice.aacPath, voice.wavPath, voice.cafPath, voice.mp3Path, voice.amrPath]) {
            if (candidate.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:candidate]) { path = candidate; break; }
        }
        if (!path) { error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSLocalizedDescriptionKey: @"没有找到这条语音的本地音频文件"}]; }
        else { self.voicePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error]; }
        self.voicePlayer.delegate = self;
        self.voicePlayer.enableRate = true;
        self.playingVoiceID = messageID;
    }
    if (!error) {
        [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
        if (!error) { [AVAudioSession.sharedInstance setActive:true error:&error]; }
        self.voicePlayer.rate = voice.playbackRate;
        if (chatView.configuration.voicePlayback.restartsOnTap) { self.voicePlayer.currentTime = 0; }
        if (!error && ![self.voicePlayer play]) { error = [NSError errorWithDomain:NSOSStatusErrorDomain code:-50 userInfo:nil]; }
    }
    if (error) { [self stopExampleVoice]; [self showVoiceError:error]; }
    else { [self updateExampleVoice:messageID playing:true]; }
}

- (void)wy_speechRecognitionFinished:(WYChatView *)chatView messageID:(NSString *)messageID text:(NSString *)text error:(NSError *)error {
    if (error) { [self showVoiceError:error]; }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag { [self stopExampleVoice]; }
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopExampleVoice];
    if (error) { [self showVoiceError:error]; }
}

- (void)showChatTests {
    WYChatTestSuite *tests = [[WYChatTestSuite alloc] initWithChatView:self.chatView];
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:tests] animated:true completion:nil];
}

- (void)wy_keyboardSendMessage:(NSString *)messageID {
    NSMutableArray<WYChatMessageModel *> *messages = self.chatView.dataSource.mutableCopy;
    for (WYChatMessageModel *message in messages) {
        if ([message.messageID isEqualToString:messageID]) { message.sendState = WYChatMessageSendStateSuccess; }
    }
    self.chatView.dataSource = messages;
}

- (void)dealloc {
    [self.voicePlayer stop];
    self.chatView.releaseAll();
}
@end
