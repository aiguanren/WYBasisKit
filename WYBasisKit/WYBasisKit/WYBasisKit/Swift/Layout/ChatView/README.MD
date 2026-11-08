# ChatView

ChatView提供聊天消息列表、输入栏、表情与更多面板、录音和语音转写界面。消息传输、下载服务、账号、支付、通话连接和语音识别服务端由宿主App负责。

## 消息类型

支持文本、语音、图片、视频、音乐、文件、网页、名片、位置、聊天记录、红包、转账、通话记录、撤回和拍一拍。未知内容显示可配置占位。红包、转账和通话记录仅提供展示及操作事件。

全部气泡使用WYAirBubbleView，布局采用单一WYChatBasicCell。发送方和接收方可分别设置头像、昵称、边距及气泡外观。撤回与拍一拍默认居中。图片与视频预览、语音播放及文件打开通过消息操作回调交给宿主。

## Swift接入

```swift
var config = WYChatConfig()
config.senderBubble.fillColor = .systemGreen
config.receiverBubble.fillColor = .secondarySystemBackground
config.input.draftStorageKey = "conversation-identifier"
config.recording.supportSpeechRecognition = false

let user = WYChatUserModel(id: "current-user", name: "自己")
let chatView = WYChatView(userInfo: user, configuration: config)
chatView.messagePreparedHandler = { message in
    // 使用message向宿主的消息服务提交发送请求
}
chatView.actionHandler = { chatView, action, messageID in
    // 依据action处理预览、播放、重试、转发、删除等操作
}
chatView.recordingHandler = { url, duration, error in
    // 成功时接收录音文件，失败时处理error
}
```

把chatView添加到宿主布局并约束其四边。控件根据实际容器尺寸和安全区布局，不负责宿主导航栏或会话列表。

## ObjC接入

```objc
WYChatConfig *config = [[WYChatConfig alloc] init];
config.senderBubble.fillColor = UIColor.systemGreenColor;
config.input.draftStorageKey = @"conversation-identifier";

WYChatUserModel *user = [[WYChatUserModel alloc] init];
user.id = @"current-user";
user.name = @"自己";
WYChatView *chatView = WYChatView.create(user, config);
chatView.messagePreparedHandler = ^(WYChatMessageModel *message) {
    // 使用message向宿主的消息服务提交发送请求
};
chatView.appendMessages(messages).scrollToLastMessage(false);
```

Swift与ObjC共用WYChatViewDelegate、WYChatViewEventsHandler、WYChatRecorder和WYChatSpeechRecognizer。ObjC模型与配置为可配置对象，转换后由控件独立持有配置值。

## 配置生效与隔离

每个ChatView独立持有WYChatConfig，修改一个页面不会改变另一个页面。批量修改时先配置局部变量，再一次赋给chatView.configuration，避免连续重建输入面板。

ObjC读取chatView.configuration取得配置快照，需要修改后重新赋给chatView.configuration才会刷新界面。赋值后继续修改先前的配置对象不会影响控件。Swift结构体也可以通过局部副本批量修改后赋值。

| 配置 | 用途 |
| --- | --- |
| basic | 头像、昵称、时间、发送状态与已读显示 |
| sender / receiver | 两侧独立布局 |
| senderBubble / receiverBubble | 圆角、箭头、填充、边框、渐变与阴影 |
| text | 字体、颜色、行距、行数、选择与链接识别 |
| content / contentOverrides | 通用及按类型覆盖的尺寸、边距与卡片外观 |
| input / emoji / more | 输入、表情和更多面板 |
| recording | 录音、转写、实现选择与编辑界面 |
| imageLoader | 替换资源图片加载 |
| messageConfiguration | 按消息修改布局与外观 |
| menuActions / allowsAction / actionTitle | 菜单内容、可用条件与标题 |

气泡箭头默认跟随头像高度，可以通过alignsArrowWithAvatar关闭，再使用arrowOffset指定偏移。尺寸不足时气泡在自身范围内调整圆角与箭头，避免复用和测高过程中出现非法几何尺寸。

## 消息操作

发送文本返回完整消息模型，并触发messagePreparedHandler。automaticallyInsertsSentMessages控制是否自动加入列表，关闭后由宿主更新消息数据源。插入历史消息使用prependMessages，追加消息使用appendMessages。

点击失败状态、预览、头像和昵称会产生相应操作。复制、引用及选择状态由控件处理，转发、删除、撤回、文件打开及实际播放由宿主处理。宿主通过sendState、readers、语音isPlaying、isTransferring、transferProgress与transferError更新界面，不把一次点击当作外部操作已经成功。

用户正在阅读历史时，追加消息显示新消息提示；接近底部时自动跟随。引用消息在输入栏上方显示，点击引用提示可取消。多选使用isSelectingMessages和selectedMessageIDs，内置工具条提供取消、转发与删除，selectionActionHandler一次接收按消息顺序排列的ID。showsSelectionToolbar可以关闭内置工具条，宿主可以提供自己的操作入口。

## 录音与语音识别

默认录音使用WYAudioKit。按住开始，松手结束，滑入取消区后松手丢弃。最长时长、最短时长、保存目录、录音设置和外观可配置。录音文件名自动唯一化，正常结果由recordingHandler交付。宿主负责发送成功后的长期保存或清理。App失去活跃状态时取消正在进行的录音。

| 设置 | 行为 |
| --- | --- |
| supportSpeechRecognition = false | 隐藏转文字入口，不创建识别任务，不申请语音识别权限 |
| supportSpeechRecognition = true，来源apple | 使用Apple Speech文件识别 |
| supportSpeechRecognition = true，来源external | 使用speechRecognitionProvider |
| recorder = nil | 使用内置WYAudioKit采集 |
| recorder提供外部对象 | 使用外部实现采集，与识别来源独立 |

Apple识别使用SFSpeechRecognizer，支持iOS15部署范围。宿主需要提供NSMicrophoneUsageDescription；使用Apple识别还需要NSSpeechRecognitionUsageDescription。仅录音和外部识别不申请Apple识别权限。

requiresOnDeviceRecognition为true时，内置实现先检查本地识别能力，不支持时返回错误，不静默联网。为false时系统可能使用Apple服务器。识别语言通过speechLocaleIdentifier设置，识别等待时限通过speechRecognitionTimeout设置。

组件的配置、权限和能力错误使用WYRecordAnimationView.speechRecognitionErrorDomain及WYChatSpeechRecognitionErrorCode判断，Apple服务和外部实现返回的错误保留其原始错误域与错误码。

识别使用现有音频文件，不开启第二个麦克风采集。滑入转文字区松手后显示等待、编辑、失败重试、取消和确认发送界面，确认后提交编辑文本。转写失败保留录音供重试，取消或释放时清理控件自有的转写临时文件。

外部实现遵循WYChatSpeechRecognizer，按requestID交付最终结果并实现取消；外部录音遵循WYChatRecorder，负责停止、文件结果及取消后的资源清理。外部实现不完整时报告配置错误，不自动切换Apple服务。迟到或重复结果不会覆盖已取消或已切换任务的界面。

## 扩展与资源

可继承WYChatBasicCell或具体Cell并覆写renderContent，内容添加到bodyView。titleView、detailView、footerView、previewImageView和thumbnailImageView提供标准内容视图访问。自定义Cell可通过事件接管代理提供，注册列表由实例配置持有。

组件自带输入栏及表情资源。状态图标使用系统图标和系统活动指示器。自定义图片可由宿主配置或通过加载接口提供，不要求使用固定图片气泡。

UIKit界面和配置刷新在主线程执行。外部录音与识别回调会统一转到主线程处理。离开页面或不再使用时调用releaseAll，停止控件持有的录音和识别任务。
