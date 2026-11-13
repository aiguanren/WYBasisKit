//
//  WYChatTestSuite.m
//  ObjCVerify
//
//  Created by guanren on 2026/11/9.
//

#import "WYChatTestSuite.h"
#import "TestConfiguration/WYChatConfigurationChecks.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYChatTestSpeechProvider : NSObject <WYChatSpeechRecognizer>
@property (nonatomic) NSInteger requests;
@end
@implementation WYChatTestSpeechProvider
- (void)wy_recognizeSpeech:(NSString *)requestID url:(NSURL *)url localeIdentifier:(NSString *)localeIdentifier requiresOnDevice:(BOOL)requiresOnDevice completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    self.requests += 1;
    completion(@"ObjC识别结果", nil);
}
- (void)wy_cancelSpeechRecognition:(NSString *)requestID {}
@end

@interface WYChatTestTranslationProvider : NSObject <WYChatTextTranslator>
@end
@implementation WYChatTestTranslationProvider
- (void)wy_translateText:(NSString *)requestID text:(NSString *)text sourceLocaleIdentifier:(NSString * _Nullable)sourceLocaleIdentifier targetLocaleIdentifier:(NSString *)targetLocaleIdentifier completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    completion(@"ObjC翻译结果", nil);
}
- (void)wy_cancelTranslation:(NSString *)requestID {}
@end

/// 聊天组件测试结果页面
@interface WYChatTestSuite ()
@property (nonatomic, strong) WYChatView *chatView;
@property (nonatomic, copy) NSArray<NSDictionary *> *results;
@property (nonatomic, strong) UILabel *summary;
@property (nonatomic) BOOL running;
@end

@implementation WYChatTestSuite

- (instancetype)initWithChatView:(WYChatView *)chatView {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        self.chatView = WYChatView.create(chatView.userInfo, chatView.configuration);
        self.results = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ChatView测试";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"全部运行" style:UIBarButtonItemStylePlain target:self action:@selector(runChecks)];
    self.summary = [[UILabel alloc] init];
    self.summary.text = @"未执行";
    self.summary.accessibilityIdentifier = @"WYChatTests.status";
    self.summary.textAlignment = NSTextAlignmentCenter;
    self.summary.numberOfLines = 0;
    self.summary.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.summary.frame = CGRectMake(0, 0, self.view.bounds.size.width, [UIDevice wy_screenHeight:60 pixels:WYBasisKitConfig.defaultScreenPixels]);
    self.tableView.tableHeaderView = self.summary;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.results.count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"check"];
    if (!cell) { cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"check"]; }
    NSDictionary *result = self.results[indexPath.row];
    cell.textLabel.text = result[@"name"];
    cell.detailTextLabel.text = [result[@"passed"] boolValue] ? @"通过" : @"失败";
    cell.detailTextLabel.textColor = [result[@"passed"] boolValue] ? UIColor.secondaryLabelColor : UIColor.systemRedColor;
    return cell;
}

- (void)close { [self dismissViewControllerAnimated:true completion:nil]; }

- (void)runChecks {
    if (self.running) { return; }
    self.running = true;
    self.results = @[];
    self.navigationItem.rightBarButtonItem.enabled = false;
    self.chatView.frame = self.view.bounds;
    [self.view addSubview:self.chatView];
    [self.chatView layoutIfNeeded];
    NSMutableArray *checks = NSMutableArray.array;
    void (^check)(NSString *, BOOL) = ^(NSString *name, BOOL passed) {
        [checks addObject:@{@"name": name, @"passed": @(passed)}];
    };
    WYChatCheckConfigurationExports(check);
    WYChatConfig *initial = self.chatView.configuration;
    initial.media.browser.appearance.toastConfig = [[WYMessageInfoConfig alloc] initWithBackgroundColor:UIColor.magentaColor textColor:UIColor.cyanColor textFont:[UIFont systemFontOfSize:22]];
    self.chatView.configuration = initial;
    WYChatCheckConfigurationProperties(initial, self.chatView.configuration, @"", check);
    WYChatConfig *savedConfiguration = self.chatView.configuration;
    WYChatContentConfig *fileContent = WYChatContentConfig.new;
    fileContent.titleFont = [UIFont systemFontOfSize:21];
    initial.setContentConfiguration(WYChatMessageStyleFile, fileContent);
    self.chatView.configuration = initial;
    check(@"content-override-callable-bridge", self.chatView.configuration.contentOverrides[@(WYChatMessageStyleFile)].titleFont.pointSize == 21);
    self.chatView.configuration = savedConfiguration;
    WYChatConfig *config = self.chatView.configuration;
    config.recording.recordTimeMin = 0.5;
    config.recording.recordTimeMax = 42;
    config.senderBubble.arrowSize = CGSizeMake(12, 7);
    config.emoji.previewConfig.previewSize = CGSizeMake(88, 130);
    config.emoji.previewConfig.minimumPressDuration = 0.4;
    config.emoji.previewConfig.allowableMovement = 28;
    config.emoji.previewConfig.textHorizontalInset = 9;
    config.input.textFont = [UIFont systemFontOfSize:22];
    config.input.backgroundImage = nil;
    config.input.backgroundColor = UIColor.magentaColor;
    config.input.iconTintColor = UIColor.orangeColor;
    config.input.rendersIconsAsTemplate = false;
    config.menuActions = @[@(WYChatActionCopy), @(WYChatActionSelect), @(WYChatActionForward), @(WYChatActionFavorite), @(WYChatActionRemind), @(WYChatActionSearch), @(WYChatActionMarkRead), @(WYChatActionMarkUnread)];
    __block NSInteger imageLoads = 0;
    config.imageLoader = ^(WYChatAssetsModel *asset, UIImageView *image, NSString *messageID) {
        imageLoads += 1;
        image.image = [UIImage systemImageNamed:@"photo"];
    };
    self.chatView.configuration = config;
    config.input.textFont = [UIFont systemFontOfSize:10];
    check(@"menu-actions-objc-exposure", [self.chatView.configuration.menuActions isEqualToArray:config.menuActions]);
    check(@"input-appearance-config-bridge", self.chatView.configuration.input.backgroundImage == nil && [self.chatView.configuration.input.backgroundColor isEqual:UIColor.magentaColor] && [self.chatView.configuration.input.iconTintColor isEqual:UIColor.orangeColor] && !self.chatView.configuration.input.rendersIconsAsTemplate);
    check(@"config-value-isolation", self.chatView.configuration.input.textFont.pointSize == 22);
    check(@"tuple-config-roundtrip", self.chatView.configuration.recording.recordTimeMin == 0.5 && self.chatView.configuration.recording.recordTimeMax == 42);
    check(@"emoji-preview-config-bridge", self.chatView.configuration.emoji.previewConfig.minimumPressDuration == 0.4 && self.chatView.configuration.emoji.previewConfig.allowableMovement == 28 && self.chatView.configuration.emoji.previewConfig.textHorizontalInset == 9);
    check(@"nested-config-roundtrip", CGSizeEqualToSize(self.chatView.configuration.emoji.previewConfig.previewSize, CGSizeMake(88, 130)));
    WYChatConfig *snapshot = self.chatView.configuration;
    snapshot.receiver.edgeInset = 16;
    self.chatView.configuration = snapshot;
    check(@"closure-preserved-in-snapshot", self.chatView.configuration.imageLoader != nil);
    NSMutableArray<WYChatMessageContentModel *> *contents = NSMutableArray.array;
    WYChatMessageContentModel *text = [[WYChatMessageContentModel alloc] init]; text.text = @"ObjC文本"; [contents addObject:text];
    WYChatMessageContentModel *voice = [[WYChatMessageContentModel alloc] init]; voice.voice = [[WYChatVoiceModel alloc] init]; voice.voice.duration = 5; [contents addObject:voice];
    WYChatMessageContentModel *photo = [[WYChatMessageContentModel alloc] init]; photo.photo = [[WYChatPhotoModel alloc] init]; [contents addObject:photo];
    WYChatMessageContentModel *music = [[WYChatMessageContentModel alloc] init]; music.music = [[WYChatMusicModel alloc] init]; music.music.name = @"音乐"; [contents addObject:music];
    WYChatMessageContentModel *video = [[WYChatMessageContentModel alloc] init]; video.video = [[WYChatVideoModel alloc] init]; video.video.duration = 12; [contents addObject:video];
    WYChatMessageContentModel *lucky = [[WYChatMessageContentModel alloc] init]; lucky.luckyMoney = [[WYChatLuckyMoneyModel alloc] init]; lucky.luckyMoney.state = WYChatFundsStateReceived; [contents addObject:lucky];
    WYChatMessageContentModel *transfer = [[WYChatMessageContentModel alloc] init]; transfer.transfer = [[WYChatLuckyMoneyModel alloc] init]; transfer.transfer.amounts = @"10"; [contents addObject:transfer];
    WYChatMessageContentModel *location = [[WYChatMessageContentModel alloc] init]; location.location = [[WYChatLocationModel alloc] init]; location.location.title = @"位置"; [contents addObject:location];
    WYChatMessageContentModel *pat = [[WYChatMessageContentModel alloc] init]; pat.takePat = [[WYChatTakePatModel alloc] init]; pat.takePat.striking.name = @"甲"; pat.takePat.beaten.name = @"乙"; [contents addObject:pat];
    WYChatMessageContentModel *withdrawn = [[WYChatMessageContentModel alloc] init]; withdrawn.withdrawn = [[WYChatWithdrawnModel alloc] init]; [contents addObject:withdrawn];
    WYChatMessageContentModel *call = [[WYChatMessageContentModel alloc] init]; call.call = [[WYChatCallModel alloc] init]; call.call.callStyle = WYChatCallStyleMultipleVideos; [contents addObject:call];
    WYChatMessageContentModel *web = [[WYChatMessageContentModel alloc] init]; web.webpage = [[WYChatWebpageModel alloc] init]; web.webpage.title = @"网页"; [contents addObject:web];
    WYChatMessageContentModel *file = [[WYChatMessageContentModel alloc] init]; file.file = [[WYChatFileModel alloc] init]; file.file.name = @"test.pdf"; [contents addObject:file];
    WYChatMessageContentModel *card = [[WYChatMessageContentModel alloc] init]; card.businessCard = [[WYChatBusinessCardModel alloc] init]; card.businessCard.userInfo.name = @"名片"; [contents addObject:card];
    WYChatMessageContentModel *records = [[WYChatMessageContentModel alloc] init]; records.chatRecords = [[WYChatRecordsModel alloc] init]; records.chatRecords.title = @"记录"; [contents addObject:records];
    [contents addObject:[[WYChatMessageContentModel alloc] init]];
    NSMutableArray<WYChatMessageModel *> *messages = NSMutableArray.array;
    for (NSInteger index = 0; index < contents.count; index += 1) {
        for (NSInteger side = 0; side < 2; side += 1) {
            WYChatMessageModel *message = [[WYChatMessageModel alloc] init];
            message.messageID = [NSString stringWithFormat:@"objc-%ld-%ld", (long)index, (long)side];
            message.sender.id = side == 0 ? @"contact" : self.chatView.userInfo.id;
            message.sender.name = side == 0 ? @"联系人" : @"自己";
            message.content = contents[index];
            message.sendState = WYChatMessageSendStateSuccess;
            message.timeFormat = @"";
            [messages addObject:message];
        }
    }
    self.chatView.dataSource = @[];
    self.chatView.appendMessages(messages);
    check(@"all-content-models", self.chatView.dataSource.count == 32);
    check(@"voice-model-roundtrip", self.chatView.dataSource[2].content.voice.duration == 5);
    check(@"funds-enum-roundtrip", self.chatView.dataSource[10].content.luckyMoney.state == WYChatFundsStateReceived);
    check(@"call-enum-roundtrip", self.chatView.dataSource[20].content.call.callStyle == WYChatCallStyleMultipleVideos);
    for (NSInteger index = 0; index < 32; index += 1) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
        [self.chatView.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:false];
        [self.chatView.tableView layoutIfNeeded];
        WYChatBasicCell *cell = (WYChatBasicCell *)[self.chatView.tableView cellForRowAtIndexPath:path];
        CGRect bubble = cell.bubblesView.frame;
        check([NSString stringWithFormat:@"cell-%ld", (long)index], cell != nil && bubble.size.width > 0 && bubble.size.height > 0 && CGRectGetMinX(bubble) >= -1 && CGRectGetMaxX(bubble) <= cell.contentView.bounds.size.width + 1);
    }
    check(@"image-loader-called", imageLoads > 0);
    __block NSInteger prepared = 0;
    self.chatView.messagePreparedHandler = ^(WYChatMessageModel *message) { prepared += 1; };
    WYChatMessageModel *sent = self.chatView.sendMessage(@"ObjC发送", @"objc-send");
    check(@"send-block-and-callback", [sent.content.text isEqualToString:@"ObjC发送"] && prepared == 1 && self.chatView.dataSource.count == 33);
    self.chatView.quoteMessage(@"objc-0-0");
    WYChatMessageModel *quoted = self.chatView.sendMessage(@"ObjC引用", @"objc-quote");
    check(@"quote-block", [quoted.reference.content.text isEqualToString:@"ObjC文本"] && self.chatView.quotedMessageID == nil);
    WYChatConfig *manual = self.chatView.configuration;
    manual.automaticallyInsertsSentMessages = false;
    self.chatView.configuration = manual;
    self.chatView.sendMessage(@"手动插入", @"objc-manual");
    check(@"manual-insertion-mode", self.chatView.dataSource.count == 34 && prepared == 3);
    self.chatView.isSelectingMessages = true;
    NSIndexPath *selectPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.chatView.tableView scrollToRowAtIndexPath:selectPath atScrollPosition:UITableViewScrollPositionTop animated:false];
    [self.chatView.tableView layoutIfNeeded];
    WYChatBasicCell *selectCell = (WYChatBasicCell *)[self.chatView.tableView cellForRowAtIndexPath:selectPath];
    if (selectCell.actionHandler) { selectCell.actionHandler(WYChatActionSelect, @"objc-0-0"); }
    check(@"selection-block", [self.chatView.selectedMessageIDs containsObject:@"objc-0-0"]);
    self.chatView.isSelectingMessages = false;
    check(@"selection-clears", self.chatView.selectedMessageIDs.count == 0);
    WYChatTestSpeechProvider *provider = [[WYChatTestSpeechProvider alloc] init];
    WYChatConfig *speechConfig = self.chatView.configuration;
    speechConfig.recording.supportSpeechRecognition = true;
    speechConfig.recording.speechRecognitionSource = WYChatSpeechRecognitionSourceExternal;
    speechConfig.recording.speechRecognitionProvider = provider;
    speechConfig.recording.actionStyle = WYRecordingActionStyleCurved;
    speechConfig.recording.curvedActionSize = CGSizeMake(210, 58);
    speechConfig.recording.curvedActionCornerRadius = 21;
    __block WYChatRecordingEditorControl styledControl = WYChatRecordingEditorControlClose;
    speechConfig.recording.recognitionControlAppearance = ^(WYChatRecordingEditorControl control, UIButton *button) { styledControl = control; button.tintColor = UIColor.orangeColor; };
    speechConfig.recording.curvedActionBendHeight = 13;
    speechConfig.recording.liveTextInsets = UIEdgeInsetsMake(11, 12, 13, 14);
    speechConfig.recording.liveTextWaveformSpacing = 9;
    speechConfig.recording.curvedActionTiltAngle = 0.12;
    speechConfig.recording.curvedActionCenterOffsetX = 115;
    speechConfig.recording.curvedActionNormalColor = UIColor.darkGrayColor;
    speechConfig.recording.curvedActionSelectedColor = UIColor.cyanColor;
    self.chatView.configuration = speechConfig;
    WYChatTestTranslationProvider *translator = [[WYChatTestTranslationProvider alloc] init];
    speechConfig.recording.dictationSendsOnRelease = false;
    speechConfig.recording.dictationShowsWaveform = true;
    speechConfig.recording.dictationEditText = @"编辑转写";
    speechConfig.recording.showsOriginalVoiceButton = false;
    speechConfig.recording.recognitionSendVoiceText = @"原语音";
    speechConfig.recording.enablesTranslation = true;
    speechConfig.recording.translationProvider = translator;
    speechConfig.recording.translationTargetLanguages = @[@"en-US", @"ja-JP"];
    speechConfig.recording.translationTimeout = 12;
    speechConfig.recording.speechRecognitionLanguages = @[@"zh-CN", @"en-US"];
    speechConfig.recording.recognitionPanelOuterInsets = UIEdgeInsetsMake(3, 7, 5, 9);
    speechConfig.recording.recognitionControlFont = [UIFont systemFontOfSize:19];
    speechConfig.input.enablesVoiceButtonDictation = false;
    speechConfig.input.voiceButtonLongPressDuration = 0.8;
    self.chatView.configuration = speechConfig;
    WYRecordAnimationConfig *recording = self.chatView.configuration.recording;
    check(@"recording-action-style", recording.actionStyle == WYRecordingActionStyleCurved && CGSizeEqualToSize(recording.curvedActionSize, CGSizeMake(210, 58)) && recording.curvedActionCornerRadius == 21 && recording.curvedActionBendHeight == 13 && UIEdgeInsetsEqualToEdgeInsets(recording.liveTextInsets, UIEdgeInsetsMake(11, 12, 13, 14)) && recording.liveTextWaveformSpacing == 9 && recording.curvedActionTiltAngle == 0.12 && recording.curvedActionCenterOffsetX == 115);
    UIButton *styledButton = [UIButton buttonWithType:UIButtonTypeSystem];
    recording.recognitionControlAppearance(WYChatRecordingEditorControlSend, styledButton);
    check(@"recording-control-appearance-block", styledControl == WYChatRecordingEditorControlSend && [styledButton.tintColor isEqual:UIColor.orangeColor]);
    check(@"recording-action-colors", [recording.curvedActionNormalColor isEqual:UIColor.darkGrayColor] && [recording.curvedActionSelectedColor isEqual:UIColor.cyanColor]);
    check(@"dictation-config", !recording.dictationSendsOnRelease && recording.dictationShowsWaveform && [recording.dictationEditText isEqualToString:@"编辑转写"] && !recording.showsOriginalVoiceButton && [recording.recognitionSendVoiceText isEqualToString:@"原语音"]);
    check(@"translation-shared-provider", recording.enablesTranslation && recording.translationProvider == translator && recording.translationTimeout == 12 && recording.translationTargetLanguages.count == 2);
    check(@"editor-config", UIEdgeInsetsEqualToEdgeInsets(recording.recognitionPanelOuterInsets, UIEdgeInsetsMake(3, 7, 5, 9)) && recording.recognitionControlFont.pointSize == 19 && recording.speechRecognitionLanguages.count == 2);
    check(@"dictation-input-config", !self.chatView.configuration.input.enablesVoiceButtonDictation && self.chatView.configuration.input.voiceButtonLongPressDuration == 0.8);
    WYRecordAnimationConfig *disabled = [[WYRecordAnimationConfig alloc] init];
    WYRecordAnimationView *recordView = WYRecordAnimationView.create(disabled);
    __block NSInteger disabledErrors = 0;
    recordView.recognitionResultHandler = ^(NSString *text, NSError *error) { if (error) { disabledErrors += 1; } };
    recordView.startWithMode(WYChatRecordingModeDictation);
    check(@"dictation-disabled-entry", disabledErrors == 1 && recordView.recordingMode == WYChatRecordingModeVoice);
    recordView.cancelTranslation().sendOriginalRecording().endRecordVoice();
    speechConfig.recording.actionStyle = WYRecordingActionStyleCircular;
    self.chatView.configuration = speechConfig;
    check(@"recording-circular-style", self.chatView.configuration.recording.actionStyle == WYRecordingActionStyleCircular);
    check(@"shared-speech-protocol", self.chatView.configuration.recording.speechRecognitionProvider == provider);
    NSString *audioPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"wav"]];
    [NSData.data writeToFile:audioPath atomically:true];
    NSMutableArray<WYChatMessageModel *> *updated = self.chatView.dataSource.mutableCopy;
    updated[2].content.voice.wavPath = audioPath;
    self.chatView.dataSource = updated;
    NSIndexPath *voicePath = [NSIndexPath indexPathForRow:2 inSection:0];
    [self.chatView.tableView scrollToRowAtIndexPath:voicePath atScrollPosition:UITableViewScrollPositionTop animated:false];
    [self.chatView.tableView layoutIfNeeded];
    WYChatBasicCell *voiceCell = (WYChatBasicCell *)[self.chatView.tableView cellForRowAtIndexPath:voicePath];
    if (voiceCell.actionHandler) { voiceCell.actionHandler(WYChatActionTranslate, @"objc-1-0"); }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        check(@"objc-provider-result", provider.requests == 1 && [self.chatView.messageModelFrom(@"objc-1-0").content.voice.voiceToText isEqualToString:@"ObjC识别结果"]);
        [NSFileManager.defaultManager removeItemAtPath:audioPath error:nil];
        WYChatConfig *mediaConfig = self.chatView.configuration;
        mediaConfig.media.presentation = WYChatMediaPresentationMerged;
        mediaConfig.media.automaticallyPresentsBrowser = false;
        mediaConfig.media.videoPresentationStyle = UIModalPresentationOverFullScreen;
        mediaConfig.media.showsVideoPlaybackControls = false;
        mediaConfig.media.browser.stackedCardCount = 4;
        mediaConfig.media.browser.stackedCardOffset = CGSizeMake(7, 9);
        mediaConfig.media.browser.stackedCardRotationAngle = 0.08;
        self.chatView.configuration = mediaConfig;
        WYChatMediaConfig *mediaValue = self.chatView.configuration.media;
        check(@"media-video-controls-roundtrip", mediaValue.videoPresentationStyle == UIModalPresentationOverFullScreen && !mediaValue.showsVideoPlaybackControls);
        check(@"media-browser-stack-roundtrip", mediaValue.browser.stackedCardCount == 4 && CGSizeEqualToSize(mediaValue.browser.stackedCardOffset, CGSizeMake(7, 9)) && mediaValue.browser.stackedCardRotationAngle == 0.08);
        WYChatMediaItem *photo = [[WYChatMediaItem alloc] init];
        photo.id = @"objc-selected-photo";
        photo.thumbnail.name = @"photo.fill";
        WYChatMediaItem *video = [[WYChatMediaItem alloc] init];
        video.id = @"objc-selected-video";
        video.kind = WYChatMediaKindVideo;
        video.thumbnail.name = @"video.fill";
        NSArray<WYChatMessageModel *> *merged = self.chatView.sendMedia(@[photo, video]);
        check(@"media-merged-bridge", merged.count == 1 && merged.firstObject.content.style == WYChatMessageStyleMediaGroup && merged.firstObject.content.mediaGroup.items.count == 2 && merged.firstObject.content.mediaGroup.items[1].kind == WYChatMediaKindVideo);
        self.chatView.appendMessages(merged);
        check(@"media-model-roundtrip", self.chatView.messageModelFrom(merged.firstObject.messageID).content.mediaGroup.items.count == 2);
        mediaConfig.media.presentation = WYChatMediaPresentationIndividual;
        self.chatView.configuration = mediaConfig;
        NSArray<WYChatMessageModel *> *individual = self.chatView.sendMedia(@[photo, video]);
        check(@"media-individual-bridge", individual.count == 2 && individual.firstObject.content.mediaGroup.items.count == 1 && [individual.lastObject.content.mediaGroup.items.firstObject.id isEqualToString:@"objc-selected-video"]);
        __block NSInteger albumRequests = 0;
        self.chatView.openAlbumHandler = ^{ albumRequests += 1; };
        self.chatView.requestAlbum();
        check(@"media-album-event", albumRequests == 1);
        WYPhotoBrowserConfiguration *browserConfig = [[WYPhotoBrowserConfiguration alloc] init];
        browserConfig.layoutStyle = WYPhotoBrowserLayoutStyleStackedCards;
        browserConfig.isEmbedded = true;
        browserConfig.stackedCardCount = 5;
        WYPhotoBrowser *browser = WYPhotoBrowserController.create(browserConfig);
        check(@"browser-native-stack-configuration", browser.configuration.layoutStyle == WYPhotoBrowserLayoutStyleStackedCards && browser.configuration.isEmbedded && browser.configuration.stackedCardCount == 5 && browser.sourceViewAtIndex(0) == nil);
        WYChatConfig *mentionConfig = self.chatView.configuration;
        mentionConfig.basic.avatarTapAction = WYChatAvatarActionProfile;
        mentionConfig.basic.avatarLongPressAction = WYChatAvatarActionMention;
        mentionConfig.basic.avatarDoubleTapAction = WYChatAvatarActionTakePat;
        mentionConfig.basic.avatarLongPressDuration = 0.6;
        mentionConfig.basic.avatarPatAnimationDuration = 0.7;
        mentionConfig.basic.avatarPatAnimationAngles = @[@0, @(-0.1), @0.1, @0];
        mentionConfig.basic.mentionPrefix = @"#";
        mentionConfig.basic.mentionSuffix = @" ";
        self.chatView.configuration = mentionConfig;
        WYBasicChatConfig *mentionBasic = self.chatView.configuration.basic;
        check(@"avatar-config-roundtrip", mentionBasic.avatarTapAction == WYChatAvatarActionProfile && mentionBasic.avatarLongPressAction == WYChatAvatarActionMention && mentionBasic.avatarDoubleTapAction == WYChatAvatarActionTakePat && mentionBasic.avatarLongPressDuration == 0.6 && [mentionBasic.mentionPrefix isEqualToString:@"#"]);
        check(@"avatar-animation-roundtrip", mentionBasic.avatarPatAnimationDuration == 0.7 && mentionBasic.avatarPatAnimationAngles.count == 4);
        self.chatView.chatInput.textView.attributedText = [[NSAttributedString alloc] initWithString:@""];
        self.chatView.chatInput.textView.selectedRange = NSMakeRange(0, 0);
        WYChatUserModel *mentionedUser = [[WYChatUserModel alloc] init];
        mentionedUser.id = @"objc-mention-target";
        mentionedUser.name = @"用户";
        check(@"mention-insert-api", self.chatView.mentionUser(mentionedUser));
        check(@"mention-identity-range", self.chatView.inputMentions.count == 1 && [self.chatView.inputMentions.firstObject.user.id isEqualToString:mentionedUser.id] && NSEqualRanges(self.chatView.inputMentions.firstObject.range, NSMakeRange(0, 3)));
        WYChatMessageModel *mentionMessage = self.chatView.sendMessage(@"#用户 ", @"objc-mention-message");
        check(@"mention-message-metadata", mentionMessage.mentions.count == 1 && [mentionMessage.mentions.firstObject.user.id isEqualToString:mentionedUser.id]);
        self.chatView.appendMessages(@[mentionMessage]);
        check(@"mention-message-model-roundtrip", self.chatView.messageModelFrom(@"objc-mention-message").mentions.count == 1);
        WYChatUserModel *invalidMention = [[WYChatUserModel alloc] init];
        invalidMention.id = @"";
        check(@"mention-empty-id-rejected", !self.chatView.mentionUser(invalidMention));
        WYChatConfig *quoteConfig = self.chatView.configuration;
        quoteConfig.quote.input.titleFont = [UIFont systemFontOfSize:19];
        quoteConfig.quote.message.spacing = 9;
        quoteConfig.quote.inputOuterInsets = UIEdgeInsetsMake(3, 14, 7, 18);
        quoteConfig.notice.reeditTimeLimit = 0;
        quoteConfig.notice.withdrawalTimeLimit = 0;
        self.chatView.configuration = quoteConfig;
        check(@"quote-config-roundtrip", self.chatView.configuration.quote.input.titleFont.pointSize == 19 && self.chatView.configuration.quote.message.spacing == 9 && UIEdgeInsetsEqualToEdgeInsets(self.chatView.configuration.quote.inputOuterInsets, UIEdgeInsetsMake(3, 14, 7, 18)));
        check(@"notice-config-roundtrip", self.chatView.configuration.notice.reeditTimeLimit == 0 && self.chatView.configuration.notice.withdrawalTimeLimit == 0);
        self.chatView.quoteMessage(@"objc-mention-message");
        check(@"quote-composer-snapshot", [self.chatView.quotePreview.quote.messageID isEqualToString:@"objc-mention-message"] && [self.chatView.quotePreview.quote.content.text isEqualToString:@"#用户 "]);
        WYChatMessageModel *quoted = self.chatView.sendMessage(@"ObjC引用回复", @"objc-quoted-reply");
        self.chatView.appendMessages(@[quoted]);
        check(@"quote-message-snapshot", [self.chatView.messageModelFrom(quoted.messageID).reference.messageID isEqualToString:@"objc-mention-message"]);
        WYChatQuoteModel *quoteSnapshot = self.chatView.messageModelFrom(quoted.messageID).reference;
        quoteSnapshot.content.text = @"外部修改";
        check(@"quote-model-value-isolation", [self.chatView.messageModelFrom(quoted.messageID).reference.content.text isEqualToString:@"#用户 "]);
        check(@"withdraw-permission", self.chatView.canWithdrawMessage(quoted.messageID, NSDate.date));
        check(@"withdraw-host-confirmation", self.chatView.markMessageWithdrawn(quoted.messageID, NSDate.date, true));
        WYChatWithdrawnModel *withdrawn = self.chatView.messageModelFrom(quoted.messageID).content.withdrawn;
        check(@"withdraw-retains-editable-quote", [withdrawn.originalText isEqualToString:@"ObjC引用回复"] && [withdrawn.reference.messageID isEqualToString:@"objc-mention-message"]);
        check(@"withdraw-no-duplicate", !self.chatView.markMessageWithdrawn(quoted.messageID, NSDate.date, true));
        check(@"reedit-permission", self.chatView.canReeditMessage(quoted.messageID, NSDate.date));
        check(@"reedit-restores-composer", self.chatView.reeditMessage(quoted.messageID) && [self.chatView.quotedMessageID isEqualToString:@"objc-mention-message"]);
        self.chatView.quoteMessage(nil);
        check(@"quote-cancel-bridge", self.chatView.quotedMessageID == nil && self.chatView.quotePreview.hidden);
        WYChatConfig *selectionConfig = self.chatView.configuration;
        selectionConfig.selection.maximumCount = 3;
        selectionConfig.selection.height = 83;
        selectionConfig.selection.font = [UIFont systemFontOfSize:21];
        selectionConfig.selection.forwardModes = @[@(WYChatForwardModeMerged)];
        self.chatView.configuration = selectionConfig;
        check(@"selection-config-roundtrip", self.chatView.configuration.selection.maximumCount == 3 && self.chatView.configuration.selection.height == 83 && self.chatView.configuration.selection.font.pointSize == 21 && self.chatView.configuration.selection.forwardModes.count == 1);
        check(@"selection-explicit-bridge", self.chatView.selectMessages(@[@"objc-mention-message"]));
        check(@"selection-range-bridge", self.chatView.selectMessageRange(@"objc-mention-message", @"objc-quoted-reply") && self.chatView.selectedMessageIDs.count == 2);
        check(@"selection-invalid-atomic", !self.chatView.selectMessages(@[@"missing"]) && self.chatView.selectedMessageIDs.count == 2);
        NSArray<WYChatMessageModel *> *forwarded = self.chatView.makeForwardMessages(@[@"objc-quoted-reply", @"objc-mention-message"], WYChatForwardModeMerged, @"ObjC合并记录");
        check(@"forward-merged-records-bridge", forwarded.count == 1 && [forwarded.firstObject.content.chatRecords.title isEqualToString:@"ObjC合并记录"] && forwarded.firstObject.content.chatRecords.messages.count == 2 && [forwarded.firstObject.content.chatRecords.messages.firstObject.messageID isEqualToString:@"objc-mention-message"]);
        check(@"forward-individual-bridge", self.chatView.makeForwardMessages(@[@"objc-mention-message", @"objc-quoted-reply"], WYChatForwardModeIndividual, nil).count == 2);
        self.chatView.isSelectingMessages = false;
        WYChatConfig *recordsConfig = self.chatView.configuration;
        recordsConfig.records.showsNicknames = false;
        recordsConfig.records.closeText = @"返回";
        recordsConfig.records.titleFont = [UIFont systemFontOfSize:24];
        self.chatView.configuration = recordsConfig;
        check(@"records-config-roundtrip", !self.chatView.configuration.records.showsNicknames && self.chatView.configuration.records.titleFont.pointSize == 24);
        WYChatRecordsViewController *detail = WYChatRecordsViewController.create(forwarded.firstObject.content.chatRecords, self.chatView.userInfo, recordsConfig);
        [detail loadViewIfNeeded];
        check(@"records-detail-bridge", detail.chatView.dataSource.count == 2 && detail.chatView.chatInput.hidden && !detail.chatView.configuration.showsInputBar && [detail.closeButton.title isEqualToString:@"返回"]);
        __block BOOL recordsPreviewed = false;
        self.chatView.recordsPreviewHandler = ^(WYChatRecordsModel *records) { recordsPreviewed = records.messages.count == 2; };
        self.chatView.appendMessages(forwarded);
        self.chatView.previewRecords(forwarded.firstObject.messageID);
        check(@"records-host-preview-bridge", recordsPreviewed);
        detail.chatView.releaseAll();
        WYChatConfig *playbackConfig = self.chatView.configuration;
        playbackConfig.voicePlayback.rates = @[@1, @1.5, @2];
        playbackConfig.voicePlayback.showsOnlyWhilePlaying = false;
        playbackConfig.voicePlayback.size = CGSizeMake(64, 31);
        self.chatView.configuration = playbackConfig;
        __block float changedRate = 0;
        self.chatView.voicePlaybackRateHandler = ^(NSString *identifier, float rate) { changedRate = rate; };
        check(@"voice-playback-config-bridge", self.chatView.configuration.voicePlayback.rates.count == 3 && CGSizeEqualToSize(self.chatView.configuration.voicePlayback.size, CGSizeMake(64, 31)));
        check(@"voice-playback-rate-bridge", self.chatView.setVoicePlaybackRate(1.5, @"objc-1-0") && changedRate == 1.5 && self.chatView.messageModelFrom(@"objc-1-0").content.voice.playbackRate == 1.5);
        check(@"voice-playback-invalid-bridge", !self.chatView.setVoicePlaybackRate(3, @"objc-1-0"));
        check(@"voice-recording-invalid-file", self.chatView.sendVoiceRecording([NSURL URLWithString:@"https://example.com/voice.caf"], 1, @"objc-invalid-recording") == nil);
        WYChatVoiceModel *recordedVoice = WYChatVoiceModel.new;
        recordedVoice.localPath = @"/recordings/sample.caf";
        WYChatMessageContentModel *recordedContent = WYChatMessageContentModel.new;
        recordedContent.voice = recordedVoice;
        WYChatMessageModel *recordedMessage = WYChatMessageModel.new;
        recordedMessage.messageID = @"objc-recorded-path";
        recordedMessage.content = recordedContent;
        self.chatView.dataSource = @[recordedMessage];
        check(@"voice-local-path-bridge", [self.chatView.dataSource.firstObject.content.voice.localPath isEqualToString:recordedVoice.localPath]);
        self.chatView.inputViewResignFirstResponder();
        NSInteger failed = 0;
        for (NSDictionary *item in checks) { if (![item[@"passed"] boolValue]) { failed += 1; } }
        NSDictionary *result = @{@"checks": checks, @"total": @(checks.count), @"failed": @(failed), @"system": UIDevice.currentDevice.systemVersion};
        NSData *data = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil];
        NSURL *output = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        [data writeToURL:[output URLByAppendingPathComponent:@"ChatView-ObjC-TestResults.json"] atomically:true];
        self.results = checks.copy;
        self.running = false;
        self.navigationItem.rightBarButtonItem.enabled = true;
        [self.chatView removeFromSuperview];
        self.summary.text = [NSString stringWithFormat:@"执行完成 · 通过%lu · 失败%ld", (unsigned long)(checks.count - failed), (long)failed];
        [self.tableView reloadData];
    });
}

- (void)dealloc { self.chatView.releaseAll(); }
@end
