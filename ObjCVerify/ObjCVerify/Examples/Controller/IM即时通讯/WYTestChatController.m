//
//  WYTestChatController.m
//  ObjCVerify
//
//  Created by guanren on 2026/11/8.
//

#import "WYTestChatController.h"
#import "WYChatTestSuite.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestChatController () <WYChatViewDelegate>
@property (nonatomic, strong) WYChatView *chatView;
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
    config.more.moreSource = @[@{@"照片": @"photo"}, @{@"文件": @"doc"}];
    config.more.imageProvider = ^UIImage * _Nullable(NSString *name) { return [UIImage systemImageNamed:name]; };
    config.imageLoader = ^(WYChatAssetsModel *asset, UIImageView *imageView, NSString *messageID) {
        imageView.image = [UIImage systemImageNamed:asset.name.length > 0 ? asset.name : @"person.crop.square"];
    };
    WYChatUserModel *user = [[WYChatUserModel alloc] init];
    user.id = @"current-user";
    user.name = @"自己";
    self.chatView = WYChatView.create(user, config);
    self.chatView.delegate = self;
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
    self.chatView.releaseAll();
}
@end
