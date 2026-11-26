//
//  WYTestChatController.m
//  ObjCVerify
//
//  Created by guanren on 2026/11/8.
//

#import "WYTestChatController.h"
#import "WYChatTestSuite.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import <QuickLook/QuickLook.h>
#import <SDWebImage/SDWebImage.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestChatController () <WYChatViewDelegate, AVAudioPlayerDelegate, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate, QLPreviewControllerDataSource>
@property (nonatomic, strong) WYChatView *chatView;
@property (nonatomic, strong) AVAudioPlayer *voicePlayer;
@property (nonatomic, copy) NSString *playingVoiceID;
@property (nonatomic, strong) NSURL *attachmentDirectory;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURL *> *importedFiles;
@property (nonatomic, strong) NSURL *previewFileURL;
@property (nonatomic) BOOL importingPhotos;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSUUID *> *exampleTransferTasks;
@property (nonatomic, copy) NSString *exampleConfirmationTitle;
@end

@implementation WYTestChatController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.attachmentDirectory = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:NSUUID.UUID.UUIDString isDirectory:YES];
    self.importedFiles = [NSMutableDictionary dictionary];
    self.exampleTransferTasks = [NSMutableDictionary dictionary];
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
    config.media.albumMoreItemIndex = 0;
    config.media.albumAllowsVideos = YES;
    config.selection.usesForwardActionSheet = YES;
    config.selection.automaticallyDeletesMessages = YES;
    config.selection.automaticallyFavoritesMessages = YES;
    UIEdgeInsets moreInset = config.more.contentInset;
    moreInset.bottom = [UIDevice wy_screenWidth:40];
    config.more.contentInset = moreInset;
    config.imageLoader = ^(WYChatAssetsModel *asset, UIImageView *imageView, NSString *messageID) {
        NSString *name = [asset.name isEqualToString:@"doc"] ? @"WYChatViewFile" : asset.name;
        if (name.length > 0) {
            imageView.image = [UIImage imageNamed:name] ?: [UIImage systemImageNamed:name] ?: [UIImage wy_find:name bundle:resources];
        } else {
            NSURL *url = [NSURL URLWithString:asset.downloadPath];
            if ([@[@"http", @"https"] containsObject:url.scheme.lowercaseString ?: @""]) {
                UIImage *placeholder = imageView.image;
                __weak UIImageView *target = imageView;
                [imageView sd_setImageWithURL:url placeholderImage:placeholder options:SDWebImageAvoidAutoSetImage
                                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    if (image && target.image == placeholder) { target.image = image; }
                }];
            }
        }
    };
    WYChatUserModel *user = [[WYChatUserModel alloc] init];
    user.id = @"current-user";
    user.name = @"自己";
    self.chatView = WYChatView.create(user, config);
    self.chatView.delegate = self;
    __weak typeof(self) weakSelf = self;
    self.chatView.openAlbumHandler = ^{ [weakSelf openExampleAlbum]; };
    self.chatView.preparedForwardHandler = ^(WYChatForwardMode mode, NSArray<WYChatMessageModel *> *messages) {
        [weakSelf deliverExampleForward:messages];
    };
    self.chatView.sendConfirmationHandler = ^(NSArray<WYChatMessageContentModel *> *contents, void (^completion)(BOOL)) {
        typeof(self) self = weakSelf;
        if (!self) { completion(NO); return; }
        [self presentExampleConfirmation:completion];
    };
    self.chatView.messageDetailHandler = ^BOOL(WYChatMessageModel *message) {
        return [weakSelf presentExampleFundsDetail:message];
    };
    self.chatView.mediaTransferActionHandler = ^(WYChatAction action, NSString *messageID, NSString *itemID) {
        typeof(self) self = weakSelf;
        if (!self) { return; }
        if (action == WYChatActionPauseTransfer) {
            [self.exampleTransferTasks removeObjectForKey:[NSString stringWithFormat:@"%@/%@", messageID, itemID]];
            self.chatView.updateMediaTransfer(messageID, itemID, WYChatTransferStatePaused, nil, @"");
        } else {
            [self startExampleMediaTransfer:messageID itemID:itemID];
        }
    };
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
    // WYChatMessageModel *message = [[WYChatMessageModel alloc] init];
    // message.messageID = NSUUID.UUID.UUIDString;
    // message.sender.name = @"示例联系人";
    // message.sender.id = @"contact";
    // message.content.text = @"这条消息展示ObjC接入、气泡配置和消息菜单。";
    // message.sendState = WYChatMessageSendStateSuccess;
    // self.chatView.appendMessages(@[message]);
    // self.chatView.scrollToLastMessage(false);
}

- (void)wy_didClickMoreView:(WYChatMoreView *)moreView itemIndex:(NSInteger)itemIndex {
    NSArray<NSDictionary<NSString *, UIImage *> *> *items = moreView.moreViewConfig.moreSource;
    if (self.importingPhotos || self.presentedViewController || itemIndex < 0 || (NSUInteger)itemIndex >= items.count) { return; }
    // 照片已由 albumMoreItemIndex 转交给 openAlbumHandler。
    if (itemIndex == self.chatView.configuration.media.albumMoreItemIndex) { return; }
    NSString *title = items[itemIndex].allKeys.firstObject;
    self.chatView.inputViewResignFirstResponder();
    if ([title isEqualToString:@"拍摄"]) {
        [self openExampleCamera];
        return;
    }
    if ([title isEqualToString:@"文件"]) {
        [self openExampleFiles];
        return;
    }
    WYChatMessageContentModel *content = [self exampleContentForTitle:title];
    if (!content) { return; }
    [self confirmExampleContent:content title:title];
}

- (void)appendExampleMessage:(WYChatMessageContentModel *)content {
    NSArray<WYChatMessageModel *> *messages = self.chatView.dataSource;
    WYChatMessageModel *message = [[WYChatMessageModel alloc] init];
    message.messageID = NSUUID.UUID.UUIDString;
    message.sender = self.chatView.userInfo;
    message.content = content;
    message.timestamp = @(NSDate.date.timeIntervalSince1970).stringValue;
    message.lastMessageTimestamp = messages.lastObject.timestamp ?: @"";
    message.index = messages.count;
    message.sendState = WYChatMessageSendStateSuccess;
    self.chatView.appendMessages(@[message]);
    self.chatView.scrollToLastMessage(true);
}

- (void)deliverExampleForward:(NSArray<WYChatMessageModel *> *)messages {
    // 模拟目标会话收到消息，示例使用当前会话展示转发结果。
    NSUInteger startIndex = self.chatView.dataSource.count;
    [messages enumerateObjectsUsingBlock:^(WYChatMessageModel *message, NSUInteger index, BOOL *stop) {
        message.index = startIndex + index;
        message.sendState = WYChatMessageSendStateSuccess;
    }];
    self.chatView.appendMessages(messages);
    self.chatView.scrollToLastMessage(true);
}

- (WYChatMessageContentModel *)exampleContentForTitle:(NSString *)title {
    WYChatMessageContentModel *content = [[WYChatMessageContentModel alloc] init];
    if ([title isEqualToString:@"位置"]) {
        content.location = [[WYChatLocationModel alloc] init];
        content.location.title = @"示例位置 · 测试公园";
        content.location.address = @"示例路 100 号";
        content.location.longitude = @"121.4737";
        content.location.latitude = @"31.2304";
    } else if ([title isEqualToString:@"收藏"]) {
        WYChatMessageModel *favorite = self.chatView.favoriteMessages.lastObject;
        if (favorite) { return favorite.content; }
        // ChatView 使用网页卡片展示示例收藏。
        content.webpage = [[WYChatWebpageModel alloc] init];
        content.webpage.title = @"示例收藏 · 聊天接入指南";
        content.webpage.remarks = @"来自我的收藏";
        content.webpage.name = @"收藏";
        content.webpage.path = @"https://example.com";
    } else if ([title isEqualToString:@"个人名片"]) {
        content.businessCard = [[WYChatBusinessCardModel alloc] init];
        content.businessCard.userInfo.id = @"example-card";
        content.businessCard.userInfo.name = @"示例联系人";
        content.businessCard.remarks = @"个人名片";
    } else if ([title isEqualToString:@"音乐"]) {
        content.music = [[WYChatMusicModel alloc] init];
        content.music.name = @"示例音乐";
        content.music.singer = @"示例歌手";
        content.music.duration = 180;
    } else if ([title isEqualToString:@"发红包"]) {
        content.luckyMoney = [[WYChatLuckyMoneyModel alloc] init];
        content.luckyMoney.amounts = @"8.88";
        content.luckyMoney.remarks = @"示例红包 · 祝你开心";
        content.luckyMoney.notes = @"红包";
    } else if ([title isEqualToString:@"转账"]) {
        content.transfer = [[WYChatLuckyMoneyModel alloc] init];
        content.transfer.amounts = @"20.00";
        content.transfer.remarks = @"示例转账";
        content.transfer.notes = @"转账";
    } else {
        return nil;
    }
    return content;
}

- (void)showAttachmentNotice:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"聊天附件" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openExampleAlbum {
    if (self.importingPhotos || self.presentedViewController) { return; }
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] initWithPhotoLibrary:PHPhotoLibrary.sharedPhotoLibrary];
    config.filter = self.chatView.configuration.media.albumAllowsVideos
        ? [PHPickerFilter anyFilterMatchingSubfilters:@[PHPickerFilter.imagesFilter, PHPickerFilter.videosFilter]]
        : PHPickerFilter.imagesFilter;
    config.selection = PHPickerConfigurationSelectionOrdered;
    config.selectionLimit = MAX(0, self.chatView.configuration.media.albumSelectionLimit);
    config.preferredAssetRepresentationMode = PHPickerConfigurationAssetRepresentationModeCurrent;
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)openExampleCamera {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self showAttachmentNotice:@"当前设备无法使用相机，请在支持拍照的 iPhone 上测试。"];
        return;
    }
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        [self showAttachmentNotice:@"相机访问受限，请检查系统设置中的相机权限。"];
        return;
    }
    UIImagePickerController *camera = [[UIImagePickerController alloc] init];
    camera.sourceType = UIImagePickerControllerSourceTypeCamera;
    NSArray<NSString *> *supported = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    camera.mediaTypes = [supported containsObject:UTTypeMovie.identifier] ? @[UTTypeImage.identifier, UTTypeMovie.identifier] : @[UTTypeImage.identifier];
    camera.delegate = self;
    [self presentViewController:camera animated:YES completion:nil];
}

- (void)openExampleFiles {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeItem] asCopy:YES];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (WYChatMediaItem *)examplePhotoAtURL:(NSURL *)url size:(CGSize)size {
    WYChatMediaItem *item = [[WYChatMediaItem alloc] init];
    item.original.localPath = url.path;
    item.thumbnail.localPath = url.path;
    item.size = size;
    return item;
}

- (void)sendExamplePhotos:(NSArray<WYChatMediaItem *> *)items presentation:(WYChatMediaPresentation)presentation {
    self.chatView.sendMediaWithPresentation(items, presentation);
}

- (void)choosePresentationForPhotos:(NSArray<WYChatMediaItem *> *)items selectedCount:(NSUInteger)selectedCount {
    if (items.count == 0) {
        [self showAttachmentNotice:@"无法读取所选照片。"];
        return;
    }
    BOOL includesVideo = [items indexOfObjectPassingTest:^BOOL(WYChatMediaItem *item, NSUInteger index, BOOL *stop) { return item.kind == WYChatMediaKindVideo; }] != NSNotFound;
    NSString *unit = includesVideo ? @"项媒体" : @"张照片";
    NSString *prompt = items.count == selectedCount
        ? [NSString stringWithFormat:@"已选 %lu %@，请选择发送后的展示方式。", (unsigned long)items.count, unit]
        : [NSString stringWithFormat:@"成功读取 %lu / %lu %@，请选择发送后的展示方式。", (unsigned long)items.count, (unsigned long)selectedCount, unit];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:includesVideo ? @"媒体展示方式" : @"照片展示方式" message:prompt preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"折叠展示" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf sendExamplePhotos:items presentation:WYChatMediaPresentationMerged];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"单独展示" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf sendExamplePhotos:items presentation:WYChatMediaPresentationIndividual];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        for (WYChatMediaItem *item in items) { [NSFileManager.defaultManager removeItemAtPath:item.original.localPath error:NULL]; }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    self.importingPhotos = results.count > 0;
    BOOL allowsVideos = self.chatView.configuration.media.albumAllowsVideos;
    [picker dismissViewControllerAnimated:YES completion:^{
        if (results.count == 0) { return; }
        dispatch_group_t imports = dispatch_group_create();
        NSMutableDictionary<NSNumber *, WYChatMediaItem *> *itemsByIndex = [NSMutableDictionary dictionary];
        [results enumerateObjectsUsingBlock:^(PHPickerResult *result, NSUInteger index, BOOL *stop) {
            dispatch_group_enter(imports);
            BOOL video = allowsVideos && [result.itemProvider hasItemConformingToTypeIdentifier:UTTypeMovie.identifier] &&
                         ![result.itemProvider hasItemConformingToTypeIdentifier:UTTypeImage.identifier];
            NSString *identifier = video ? UTTypeMovie.identifier : UTTypeImage.identifier;
            void (^finish)(WYChatMediaItem *) = ^(WYChatMediaItem *item) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (item) { itemsByIndex[@(index)] = item; }
                    dispatch_group_leave(imports);
                });
            };
            [result.itemProvider loadFileRepresentationForTypeIdentifier:identifier completionHandler:^(NSURL *url, NSError *error) {
                WYChatMediaItem *item = nil;
                if (url) {
                    NSFileManager *manager = NSFileManager.defaultManager;
                    NSURL *destination = [self.attachmentDirectory URLByAppendingPathComponent:NSUUID.UUID.UUIDString];
                    if (url.pathExtension.length > 0) { destination = [destination URLByAppendingPathExtension:url.pathExtension]; }
                    // 系统提供的临时 URL 在回调结束时失效。
                    if ([manager createDirectoryAtURL:self.attachmentDirectory withIntermediateDirectories:YES attributes:nil error:NULL] &&
                        [manager copyItemAtURL:url toURL:destination error:NULL]) {
                        if (video) { [self exampleVideoAtURL:destination completion:finish]; return; }
                        UIImage *image = [UIImage imageWithContentsOfFile:destination.path];
                        if (image) { item = [self examplePhotoAtURL:destination size:image.size]; }
                        else { [manager removeItemAtURL:destination error:NULL]; }
                    }
                }
                finish(item);
            }];
        }];
        dispatch_group_notify(imports, dispatch_get_main_queue(), ^{
            self.importingPhotos = NO;
            NSMutableArray<WYChatMediaItem *> *items = [NSMutableArray array];
            for (NSUInteger index = 0; index < results.count; index++) {
                WYChatMediaItem *item = itemsByIndex[@(index)];
                if (item) { [items addObject:item]; }
            }
            if (!self.viewIfLoaded.window || self.presentedViewController) {
                for (WYChatMediaItem *item in items) { [NSFileManager.defaultManager removeItemAtPath:item.original.localPath error:NULL]; }
                return;
            }
            [self choosePresentationForPhotos:items selectedCount:results.count];
        });
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    NSURL *movie = info[UIImagePickerControllerMediaURL];
    if (movie) {
        [self prepareCapturedVideo:movie picker:picker];
        return;
    }
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        NSData *data = image ? UIImageJPEGRepresentation(image, 0.9) : nil;
        if (!data) {
            [self showAttachmentNotice:@"无法读取拍摄结果。"];
            return;
        }
        NSURL *url = [[self.attachmentDirectory URLByAppendingPathComponent:NSUUID.UUID.UUIDString] URLByAppendingPathExtension:@"jpg"];
        if (![NSFileManager.defaultManager createDirectoryAtURL:self.attachmentDirectory withIntermediateDirectories:YES attributes:nil error:NULL] ||
            ![data writeToURL:url options:NSDataWritingAtomic error:NULL]) {
            [self showAttachmentNotice:@"无法保存拍摄结果。"];
            return;
        }
        self.chatView.sendMedia(@[[self examplePhotoAtURL:url size:image.size]]);
    }];
}

- (void)prepareCapturedVideo:(NSURL *)source picker:(UIImagePickerController *)picker {
    NSURL *destination = [[self.attachmentDirectory URLByAppendingPathComponent:NSUUID.UUID.UUIDString] URLByAppendingPathExtension:source.pathExtension];
    NSFileManager *manager = NSFileManager.defaultManager;
    if (![manager createDirectoryAtURL:self.attachmentDirectory withIntermediateDirectories:YES attributes:nil error:NULL] ||
        ![manager copyItemAtURL:source toURL:destination error:NULL]) {
        [picker dismissViewControllerAnimated:YES completion:^{ [self showAttachmentNotice:@"无法保存拍摄的视频。"]; }];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        [weakSelf exampleVideoAtURL:destination completion:^(WYChatMediaItem *item) {
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(self) self = weakSelf;
                if (!self.viewIfLoaded.window) { return; }
                WYChatMessageContentModel *content = WYChatMessageContentModel.new;
                content.mediaGroup = WYChatMediaGroupModel.new;
                content.mediaGroup.items = @[item];
                self.exampleConfirmationTitle = @"视频";
                self.chatView.confirmSending(@[content], ^{
                    typeof(self) self = weakSelf;
                    if (self) { self.chatView.sendMedia(@[item]); }
                });
            });
        }];
    }];
}

- (void)exampleVideoAtURL:(NSURL *)destination completion:(void (^)(WYChatMediaItem *))completion {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:destination options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake(640, 640);
    [asset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
        NSTimeInterval seconds = CMTimeGetSeconds(asset.duration);
        [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:kCMTimeZero]]
                                       completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
            WYChatMediaItem *item = WYChatMediaItem.new;
            item.kind = WYChatMediaKindVideo;
            item.original.localPath = destination.path;
            item.duration = isfinite(seconds) ? seconds : 0;
            if (image) {
                UIImage *cover = [UIImage imageWithCGImage:image];
                NSURL *coverURL = [[destination URLByDeletingPathExtension] URLByAppendingPathExtension:@"jpg"];
                if ([UIImageJPEGRepresentation(cover, 0.8) writeToURL:coverURL options:NSDataWritingAtomic error:NULL]) {
                    item.thumbnail.localPath = coverURL.path;
                    item.size = cover.size;
                }
            }
            completion(item);
        }];
    }];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) { return; }
    NSString *fileID = NSUUID.UUID.UUIDString;
    NSURL *directory = [self.attachmentDirectory URLByAppendingPathComponent:fileID isDirectory:YES];
    NSURL *destination = [directory URLByAppendingPathComponent:url.lastPathComponent];
    NSNumber *size = nil;
    NSFileManager *manager = NSFileManager.defaultManager;
    if (![manager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:NULL] ||
        ![manager copyItemAtURL:url toURL:destination error:NULL] ||
        ![destination getResourceValue:&size forKey:NSURLFileSizeKey error:NULL]) {
        [manager removeItemAtURL:directory error:NULL];
        [self showAttachmentNotice:@"无法读取所选文件。"];
        return;
    }
    self.importedFiles[fileID] = destination;
    WYChatMessageContentModel *content = [[WYChatMessageContentModel alloc] init];
    content.file = [[WYChatFileModel alloc] init];
    content.file.id = fileID;
    content.file.title = url.lastPathComponent;
    content.file.size = [NSByteCountFormatter stringFromByteCount:size.longLongValue countStyle:NSByteCountFormatterCountStyleFile];
    content.file.name = url.pathExtension.uppercaseString;
    __weak typeof(self) weakSelf = self;
    void (^confirm)(void) = ^{ [weakSelf confirmExampleContent:content title:@"文件"]; };
    if (![controller.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) { confirm(); }]) {
        confirm();
    }
}

- (void)previewExampleFile:(NSURL *)url {
    if (![QLPreviewController canPreviewItem:url]) {
        [self showAttachmentNotice:@"系统无法预览此文件格式。"];
        return;
    }
    self.previewFileURL = url;
    QLPreviewController *preview = [[QLPreviewController alloc] init];
    preview.dataSource = self;
    [self presentViewController:preview animated:YES completion:nil];
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.previewFileURL ? 1 : 0;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return self.previewFileURL;
}

- (void)confirmExampleContent:(WYChatMessageContentModel *)content title:(NSString *)title {
    self.exampleConfirmationTitle = title;
    __weak typeof(self) weakSelf = self;
    self.chatView.confirmSending(@[content], ^{
        typeof(self) self = weakSelf;
        if (!self) { return; }
        if (content.text) { [self appendExampleMessage:content]; }
        else { self.chatView.sendContent(content, NSUUID.UUID.UUIDString); }
    });
}

- (void)presentExampleConfirmation:(void (^)(BOOL))completion {
    NSString *title = self.exampleConfirmationTitle ?: @"发送消息";
    self.exampleConfirmationTitle = nil;
    if (self.presentedViewController) { completion(NO); return; }
    NSString *prompt = [title isEqualToString:@"收藏"] && self.chatView.favoriteMessages.count > 0 ? @"发送最近收藏的消息？" : @"确认发送？";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:prompt preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) { completion(NO); }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"发送" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { completion(YES); }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)presentExampleFundsDetail:(WYChatMessageModel *)message {
    WYChatFundsReceiptModel *receipt = message.content.fundsReceipt;
    WYChatMessageModel *original = receipt ? self.chatView.messageModelFrom(receipt.originalMessageID) : message;
    WYChatLuckyMoneyModel *funds = original.content.luckyMoney ?: original.content.transfer;
    if (!funds) { return NO; }
    if (self.presentedViewController) { return YES; }
    NSString *title = original.content.luckyMoney ? @"红包示例" : @"转账示例";
    NSString *amount = [NSString stringWithFormat:@"金额 ¥%@", funds.amounts];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:amount preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];
    if (funds.state == WYChatFundsStateUnreceived) {
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"模拟收款" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            typeof(self) self = weakSelf;
            if (self) { self.chatView.markFundsReceived(original.messageID, @"示例联系人"); }
        }]];
    }
    [self presentViewController:alert animated:YES completion:nil];
    return YES;
}

- (void)startExampleMediaTransfer:(NSString *)messageID itemID:(NSString *)itemID {
    NSString *key = [NSString stringWithFormat:@"%@/%@", messageID, itemID];
    NSUUID *token = NSUUID.UUID;
    self.exampleTransferTasks[key] = token;
    self.chatView.updateMediaTransfer(messageID, itemID, WYChatTransferStateTransferring, nil, @"");
    [self advanceExampleMediaTransfer:messageID itemID:itemID token:token];
}

- (void)advanceExampleMediaTransfer:(NSString *)messageID itemID:(NSString *)itemID token:(NSUUID *)token {
    NSString *key = [NSString stringWithFormat:@"%@/%@", messageID, itemID];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        typeof(self) self = weakSelf;
        if (!self || ![self.exampleTransferTasks[key] isEqual:token]) { return; }
        NSArray<WYChatMediaItem *> *items = self.chatView.messageModelFrom(messageID).content.mediaGroup.items;
        NSUInteger index = [items indexOfObjectPassingTest:^BOOL(WYChatMediaItem *item, NSUInteger position, BOOL *stop) {
            return [item.id isEqualToString:itemID];
        }];
        if (!items || index == NSNotFound) { [self.exampleTransferTasks removeObjectForKey:key]; return; }
        WYChatMediaItem *item = items[index];
        double next = MIN(1, item.transferProgress + (item.kind == WYChatMediaKindVideo ? 0.035 : 0.055) / (1 + index * 0.12));
        WYChatTransferState phase = next == 1 ? WYChatTransferStateCompleted : WYChatTransferStateTransferring;
        self.chatView.updateMediaTransfer(messageID, itemID, phase, @(next), @"");
        if (phase == WYChatTransferStateTransferring) {
            [self advanceExampleMediaTransfer:messageID itemID:itemID token:token];
            return;
        }
        [self.exampleTransferTasks removeObjectForKey:key];
        NSArray<WYChatMessageModel *> *messages = self.chatView.dataSource;
        for (WYChatMessageModel *message in messages) {
            if (![message.messageID isEqualToString:messageID]) { continue; }
            for (WYChatMediaItem *entry in message.content.mediaGroup.items) {
                if (entry.transferState != WYChatTransferStateCompleted) { return; }
            }
            message.sendState = WYChatMessageSendStateSuccess;
            self.chatView.dataSource = messages;
            break;
        }
    });
}

- (void)startExampleTransfer:(NSString *)messageID {
    WYChatMessageModel *message = self.chatView.messageModelFrom(messageID);
    if (!message) { return; }
    NSUUID *token = NSUUID.UUID;
    self.exampleTransferTasks[messageID] = token;
    double progress = message.transferProgress < 1 ? message.transferProgress : 0;
    self.chatView.updateTransfer(messageID, WYChatTransferStateTransferring, @(progress), @"");
    [self advanceExampleTransfer:messageID token:token];
}

- (void)advanceExampleTransfer:(NSString *)messageID token:(NSUUID *)token {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        typeof(self) self = weakSelf;
        if (!self || ![self.exampleTransferTasks[messageID] isEqual:token]) { return; }
        WYChatMessageModel *message = self.chatView.messageModelFrom(messageID);
        if (!message) { [self.exampleTransferTasks removeObjectForKey:messageID]; return; }
        double next = MIN(1, message.transferProgress + 0.12);
        if (next < 1) {
            self.chatView.updateTransfer(messageID, WYChatTransferStateTransferring, @(next), @"");
            [self advanceExampleTransfer:messageID token:token];
            return;
        }
        [self.exampleTransferTasks removeObjectForKey:messageID];
        self.chatView.updateTransfer(messageID, WYChatTransferStateCompleted, nil, @"");
        if (message.sendState == WYChatMessageSendStateSending) {
            NSArray<WYChatMessageModel *> *messages = self.chatView.dataSource;
            for (WYChatMessageModel *item in messages) {
                if ([item.messageID isEqualToString:messageID]) { item.sendState = WYChatMessageSendStateSuccess; break; }
            }
            self.chatView.dataSource = messages;
        }
    });
}

- (void)prepareExampleMessage:(WYChatMessageModel *)message {
    if (!message || message.content.text) { return; }
    if (message.content.mediaGroup) {
        for (WYChatMediaItem *item in message.content.mediaGroup.items) {
            if (item.transferState != WYChatTransferStateCompleted) { [self startExampleMediaTransfer:message.messageID itemID:item.id]; }
        }
        return;
    }
    switch (message.content.style) {
        case WYChatMessageStyleMediaGroup:
        case WYChatMessageStylePhoto:
        case WYChatMessageStyleVideo:
        case WYChatMessageStyleFile:
        case WYChatMessageStyleLocation:
        case WYChatMessageStyleBusinessCard:
        case WYChatMessageStyleMusic:
        case WYChatMessageStyleWebpage:
            [self startExampleTransfer:message.messageID];
            return;
        default:
            break;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        typeof(self) self = weakSelf;
        if (!self) { return; }
        NSMutableArray<WYChatMessageModel *> *messages = self.chatView.dataSource.mutableCopy;
        for (WYChatMessageModel *item in messages) {
            if ([item.messageID isEqualToString:message.messageID]) { item.sendState = WYChatMessageSendStateSuccess; }
        }
        if (message.content.luckyMoney || message.content.transfer) {
            self.chatView.dataSource = messages;
        }
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
    if (action == WYChatActionStartTransfer || action == WYChatActionResumeTransfer) {
        [self startExampleTransfer:messageID];
    } else if (action == WYChatActionPauseTransfer) {
        [self.exampleTransferTasks removeObjectForKey:messageID];
        chatView.updateTransfer(messageID, WYChatTransferStatePaused, nil, @"");
    } else if (action == WYChatActionDelete) {
        [self.exampleTransferTasks removeObjectForKey:messageID];
    }
    if (action == WYChatActionWithdraw) { chatView.markMessageWithdrawn(messageID, NSDate.date, YES); }
    if (action == WYChatActionFavorite && chatView.configuration.selection.automaticallyFavoritesMessages) {
        [WYActivity showInfo:@"已收藏"];
    }
    if (action == WYChatActionTakePat && message) {
        WYChatMessageContentModel *content = [[WYChatMessageContentModel alloc] init];
        content.takePat = [[WYChatTakePatModel alloc] init];
        content.takePat.striking = chatView.userInfo;
        content.takePat.beaten = message.sender;
        content.takePat.notes = @"的肩膀";
        [self appendExampleMessage:content];
        return;
    }
    if (action == WYChatActionContent && message.content.file.id) {
        NSURL *url = self.importedFiles[message.content.file.id];
        if (url) { [self previewExampleFile:url]; }
    }
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
    if (_attachmentDirectory) { [NSFileManager.defaultManager removeItemAtURL:_attachmentDirectory error:NULL]; }
}
@end
