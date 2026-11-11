# ChatView

ChatView提供聊天消息列表、输入栏、表情与更多面板、录音和语音转写界面。消息传输、下载服务、账号、支付、通话连接和语音识别服务端由宿主App负责。

## 消息类型

支持文本、语音、图片、视频、音乐、文件、网页、名片、位置、聊天记录、红包、转账、通话记录、撤回和拍一拍。未知内容显示可配置占位。红包、转账和通话记录仅提供展示及操作事件。

全部气泡使用WYAirBubbleView，布局采用单一WYChatBasicCell。发送方和接收方可分别设置头像、昵称、边距及气泡外观。撤回与拍一拍默认居中。图片与视频预览、语音播放及文件打开通过消息操作回调交给宿主。

## Swift接入

聊天视图通过代码创建，不支持从Storyboard或归档加载。

```swift
var config = WYChatConfig()
config.senderBubble.fillColor = .systemIndigo
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
config.senderBubble.fillColor = UIColor.systemIndigoColor;
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

## 图片和视频接入

相册选择器由宿主提供。通过`openAlbumHandler`或`wy_chatViewDidRequestAlbum`接收打开请求，选择完成后调用`sendMedia(_:)`交回`WYChatMediaItem`数组。`media.albumMoreItemIndex`将更多面板的指定项目关联到相册事件，负数时不自动关联。

```swift
config.media.presentation = .merged
chatView.openAlbumHandler = {
    // 打开宿主选择器，完成后调用chatView.sendMedia(selectedItems)
}
```

`media.presentation`支持`.individual`逐条和`.merged`合并。待发送消息的`content.mediaGroup`保存原始媒体顺序和身份，逐条模式中每组只有一个项目。`automaticallyInsertsSentMessages`决定是否自动插入，`messagePreparedHandler`逐条交付待发送消息，上传完成后由宿主更新发送状态。

折叠时复用PhotoBrowser的`.stackedCards`布局与左右滑动，展开/收起按钮及事件由聊天Cell管理。层数、偏移、旋转和圆角通过`media.browser`配置，展开尺寸、间距、按钮文案和样式通过`media`配置。PhotoBrowser自身不提供展开/收起按钮。

```swift
config.media.browser.stackedCardCount = 3
config.media.browser.stackedCardRotationAngle = .pi / 90
chatView.setMediaGroupExpanded(true, messageID: messageID)
chatView.previewMedia(messageID: messageID, index: 2)
```

`mediaPreviewHandler`可接管媒体列表、初始下标及转场来源视图。未接管且`media.automaticallyPresentsBrowser`为true时使用内置浏览器。`mediaActionHandler`报告预览、展开、收起和页码变化。

## 录音与语音识别

按住开始，松手结束，滑入取消区后松手丢弃，滑入转文字区后松手编辑并发送文本。最长时长、最短时长、保存目录、录音设置和外观可配置。录音文件名自动唯一化，正常结果由recordingHandler交付，宿主负责发送成功后的长期保存或清理。App失去活跃状态时取消正在进行的录音。

```swift
config.input.enablesVoiceButtonDictation = true
config.recording.dictationSendsOnRelease = true
config.recording.actionStyle = .curved
config.recording.curvedActionColors = (normal: .darkGray, selected: .systemIndigo)
config.recording.supportSpeechRecognition = true
config.recording.speechRecognitionSource = .apple
config.recording.speechRecognitionMode = .whileRecording
config.recording.speechLocaleIdentifier = "zh-CN"
```

| 设置 | 行为 |
| --- | --- |
| actionStyle = curved | 默认弧形条状操作按钮，尺寸、圆角、弯曲高度、倾斜角度、中心偏移和普通/选中背景色可配置 |
| actionStyle = circular | 圆形操作按钮，直径、背景图、位置及普通/选中状态可配置 |
| supportSpeechRecognition = false | 隐藏转文字入口，不创建识别任务，不申请语音识别权限，清除上次录音的实时文字 |
| speechRecognitionMode = whileRecording | 录音时显示可被后续结果修订的实时文本，松手后等待最终结果 |
| speechRecognitionMode = afterRecording | 松手后识别录音文件 |
| speechRecognitionSource = apple | 使用Apple Speech识别 |
| speechRecognitionSource = external | 使用speechRecognitionProvider，不申请Apple识别权限 |
| recorder = nil | 实时识别使用AVAudioEngine同时保存文件并提供音频，普通录音和录后识别使用WYAudioKit |
| recorder提供外部对象 | 使用外部实现采集，与识别来源独立 |

Apple识别使用SFSpeechRecognizer，支持iOS15部署范围。内置采集需要NSMicrophoneUsageDescription，Apple识别需要NSSpeechRecognitionUsageDescription。切换到语音输入时准备所需权限，拒绝语音识别权限后仍可发送普通语音。外部录音自行处理采集权限。

requiresOnDeviceRecognition为true时，内置实现先检查本地识别能力，不支持时返回错误，不静默联网。为false时系统可能使用Apple服务器。识别语言通过speechLocaleIdentifier设置，识别等待时限通过speechRecognitionTimeout设置。

组件的识别配置、权限和能力错误使用WYRecordAnimationView.speechRecognitionErrorDomain及WYChatSpeechRecognitionErrorCode判断，Apple服务和外部实现返回的错误保留其原始错误域与错误码。

实时识别使用同一路采集音频，不开启第二个麦克风。WYRecordAnimationView.recognitionPartialResultHandler接收录音中的完整文本，recognitionResultHandler接收最终文本及错误，recognizedTextHandler接收确认发送的编辑文本。转写失败保留录音供重试，取消或释放时清理控件自有的转写临时文件。

外部流式识别实现WYChatSpeechRecognizer的wy_startStreamingSpeech、wy_appendSpeechAudio和wy_finishStreamingSpeech，文件识别实现wy_recognizeSpeech，取消使用wy_cancelSpeechRecognition。只提供流式识别时，文件重试通过读取录音文件并逐段提供PCM完成。外部实现不完整时报告配置错误，不自动切换Apple服务，迟到或重复结果不会覆盖已取消或已切换任务的界面。

外部实时录音实现WYChatRecorder的wy_startStreamingRecording并提供PCM，普通录音和录后识别实现wy_startRecording，停止与取消使用wy_stopRecording。录音开始时保存本次配置，停止仍调用本次采集器，修改配置在下一次录音生效，重试识别读取最新识别配置。外部录音实现负责取消后的资源清理，组件不会删除外部交付的文件。

WYRecordAnimationView.delegate使用共用WYRecordEventsHandler，wy_recordingWillStart、wy_recordingTimeUpdated、wy_recordingMeteringUpdated和wy_recordingDidFinish分别报告开始、秒数、dB音量和录音结果，结束结果包含取消、达到最长时长及错误。内置采集与外部采集使用同一组事件，替换录音实现通过recorder配置。

## 示例测试

SwiftVerify与ObjCVerify的聊天页面均提供“测试”入口，可运行检查并查看通过、失败和未执行状态。Swift测试页支持按名称或分组搜索、逐项运行、批量运行和分享JSON报告。标记为需要实际操作的用例单独运行，不计入批量通过；实际手势滚动需要先在聊天列表中拖动，Apple原生实时识别需要系统许可及可用识别服务。

“录音操作双样式”检查样式切换、配置刷新、不同容器宽度、关闭识别和按钮区域命中，渲染图写入Documents/ChatView-VisualResults。

测试结果分别写入示例App的Documents/ChatView-TestResults.json与ChatView-ObjC-TestResults.json。Swift报告保留最近整批结果与每项最近一次结果，重新进入聊天页面不会清除已有报告。固定语音测试使用随示例打包的合成语音文件，不采集麦克风。

## 扩展与资源

可继承WYChatBasicCell或具体Cell并覆写renderContent，内容添加到bodyView。titleView、detailView、footerView、previewImageView和thumbnailImageView提供标准内容视图访问。自定义Cell可通过事件接管代理提供，注册列表由实例配置持有。

组件自带输入栏及表情资源。状态图标使用系统图标和系统活动指示器。自定义图片可由宿主配置或通过加载接口提供，不要求使用固定图片气泡。

UIKit界面和配置刷新在主线程执行。外部录音与识别回调会统一转到主线程处理。离开页面或不再使用时调用releaseAll，停止控件持有的录音和识别任务。

## 头像与用户提及

`basic.avatarTapAction`、`basic.avatarLongPressAction`和`basic.avatarDoubleTapAction`分别配置头像的单击、长按、双击，可选`.none`、`.profile`、`.mention`和`.takePat`。默认依次为打开用户信息、提及用户和请求拍一拍，长按时间由`basic.avatarLongPressDuration`控制，展开媒体旁的头像使用相同配置。`basic.avatarPatAnimationDuration`与`basic.avatarPatAnimationAngles`配置拍一拍反馈动画，时长为0时关闭动画。

头像操作通过`actionHandler`和共享代理报告，拍一拍由宿主处理实际发送和结果。`basic.automaticallyInsertsMentions`控制头像提及时是否自动插入输入框，关闭后由宿主处理`.mention`操作。也可调用`mentionUser(_:)`在当前选区插入，`basic.mentionPrefix`和`basic.mentionSuffix`配置前缀与分隔文本。

`inputMentions`返回仍然有效的提及，发送的文本与输入框一致时，消息的`mentions`保留用户身份及文本中的UTF16范围。同名用户分别保存各自ID，删除或编辑提及文本会移除对应身份，修改前面的文本会同步范围。Objective-C对应`chatView.mentionUser(user)`、`chatView.inputMentions`和`message.mentions`。

内置视频播放器默认全屏，`media.videoPresentationStyle`和`media.showsVideoPlaybackControls`分别配置展示方式与系统播放控件。


## 引用、撤回与重新编辑

`WYChatQuoteModel`保存被引用消息ID、发送者及内容快照，消息的`reference`和输入区的`quotePreview`使用相同模型。输入区外观由`quote.input`配置，气泡外引用由`quote.message`配置，字体、颜色、缩略图、行数、高度、内外边距和关闭按钮可分别调整。`reference`操作回调提供被引用的原消息ID，原消息未加载时宿主仍可接管跳转。

```swift
chatView.quoteMessage(messageID)
chatView.quoteMessage(nil)
config.notice.withdrawalTimeLimit = 120
config.notice.reeditTimeLimit = 300
chatView.actionHandler = { [weak chatView] _, action, identifier in
    if action == .withdraw {
        service.withdraw(identifier) { succeeded in
            DispatchQueue.main.async {
                if succeeded { chatView?.markMessageWithdrawn(identifier) }
            }
        }
    }
}
```

撤回操作向宿主发出请求，宿主确认成功后调用`markMessageWithdrawn`更新列表。`canWithdrawMessage`判断当前用户和时间限制，普通消息与拍一拍分别配置。`canReeditMessage`和`reeditMessage`用于恢复自己的文本、提及身份及发送时的引用，取消过的引用不会在重新编辑时恢复。`notice.reeditTimeLimit`为0时不限时，入口到期后自动隐藏。被引用的原消息撤回后，现有引用同步改为撤回摘要。

## 区间多选与转发

`selectMessages`设置选择，`selectMessages(from:through:)`在当前选择中加入连续区间，支持反向区间。无效ID或超过`selection.maximumCount`时保持原选择，0表示不限。多选时长按另一条消息可选择到该消息，工具条字体、颜色、高度、内边距、间距和按钮显示通过`selection`配置。

```swift
chatView.selectMessages([firstID])
chatView.selectMessages(from: firstID, through: lastID)
chatView.forwardHandler = { mode, originalMessages in
    // 将原消息及转发形式交给宿主选择目标会话
}
let messages = chatView.makeForwardMessages(ids, mode: .merged, title: "聊天记录")
```

设置`forwardHandler`后，内置转发入口提供`selection.forwardModes`中的形式。回调传出按列表顺序排列的原消息快照，取消菜单保留选择。`makeForwardMessages`只组装数据，不插入当前列表或发起发送；逐条模式生成独立消息，合并模式生成`content.chatRecords`卡片，明细保留原发送者和消息顺序。未设置`forwardHandler`时使用`selectionActionHandler`处理批量操作。

多选期间每条消息固定预留指示图标空间，勾选不会改变消息可用宽度。`selection.showsIndicator`控制显示，`indicatorSize`和`indicatorInsets`控制尺寸、间距，`selectedImage`、`unselectedImage`、`selectedColor`、`unselectedColor`和`rendersIndicatorAsTemplate`控制图标与颜色。

合并记录点击可由`recordsPreviewHandler`接管，也可使用内置`WYChatRecordsViewController`展示。明细复用ChatView的消息和媒体展示，隐藏输入栏，昵称和导航栏外观通过`records`配置。`showsInputBar`也可用于宿主自己的只读聊天界面。


## 语音播放倍速

`voicePlayback.rates`控制可选倍速，忽略非正数、非有限值和重复值。按钮默认只在`voice.isPlaying`为true时显示，可通过`showsOnlyWhilePlaying`改为常显，通过`showsRateControl`隐藏。尺寸、字体、颜色、圆角和内边距可配置。

```swift
config.voicePlayback.rates = [1, 1.25, 1.5, 2]
chatView.voicePlaybackRateHandler = { messageID, rate in
    playerForMessage(messageID)?.rate = rate
}
chatView.setVoicePlaybackRate(1.5, messageID: voiceMessageID)
```

选择倍速更新消息的`voice.playbackRate`并通知宿主，不启动或暂停播放器。播放、暂停和播放进度由宿主处理，`isPlaying`也由宿主更新。重复设置同一倍速不重复通知，非法倍速和消息ID保持原状态。


## 输入栏外观与表情预览

输入栏背景图和文本/语音输入框背景图默认为nil，使用对应的动态背景色。自定义背景图覆盖在背景色上，`iconTintColor`设置图标颜色，`rendersIconsAsTemplate`为false时保留图片原色。发送气泡默认根据浅色、深色外观分别取色，收发气泡仍可单独配置。

```swift
config.input.backgroundColor = .secondarySystemBackground
config.input.textViewBackgroundColor = .secondarySystemGroupedBackground
config.input.iconTintColor = .label
config.input.rendersIconsAsTemplate = true
config.emoji.previewConfig.minimumPressDuration = 0.4
config.emoji.previewConfig.allowableMovement = 28
config.emoji.previewConfig.textHorizontalInset = 9
```

表情长按后可跨行滑动更新预览文字和锚定位置，移出有效区域隐藏预览，松手关闭并且不插入表情。

## 宿主消息操作

收藏、提醒、搜索、标记已读和标记未读通过`WYChatAction.favorite/remind/search/markRead/markUnread`报告，由宿主实现服务和数据更新。`menuActions`控制入口，`actionTitle`自定义标题，`allowsAction`控制逐条消息的菜单可见性，`eventsHandler`可接管执行。

```swift
config.menuActions = [.copy, .quote, .forward, .favorite, .remind, .search]
chatView.actionHandler = { _, action, messageID in
    host.handleMessageAction(action, messageID: messageID)
}
```

组件不会将操作请求直接当成服务成功，不自动修改已读状态、建立提醒或保存收藏。


## 配置测试页

SwiftVerify的聊天测试页点击“配置”可搜索并调整配置属性，修改即时应用到当前实例；右上角“预览”打开复制消息的独立页面。“复原”恢复进入配置页之前的设置，字段左划可恢复SDK默认值或清空可选值。

`contentOverrides`按消息类型打开独立配置页。首次编辑复制当前`content`，之后该类型使用完整覆盖配置；左划“取消覆盖”会删除该类型整份覆盖。保存结果提示样式可单独调整字体和颜色并直接预览，左划“使用默认提示”恢复全局默认样式。

外部识别器、翻译服务与资源回调通过专项用例验证。配置目录的读写检查和实际UI操作分别执行，结果可在测试页导出。`emoji.funcAreaConfig.longPressDeleteDuration`和`deleteRepeatInterval`分别设置连续删除开始前的按住时长与删除间隔，单位秒。

实时转写的声波固定在气泡右下角，`recording.soundWavesRightOffsetForAirBubble`控制右侧和底部间距，`liveTextInsets`及`liveTextWaveformSpacing`控制文字留白。弧形操作条由曲线路径绘制，`curvedActionBendHeight`为0时显示直条。

`recording.curvedActionSize`、`curvedActionCornerRadius`、`curvedActionTiltAngle`及`curvedActionTitleOffsetX`分别控制操作条大小、端头圆角、倾斜角度和文字位置。`overlayBackgroundColor`配置整页遮罩，底部录音区域使用独立颜色；气泡下方提示的字体、颜色及间距也可单独设置。

转写编辑的关闭、语言和翻译入口位于气泡上方，表情、原语音和发送位于气泡下方。`recognitionHeaderHeight`、`recognitionHeaderSpacing`、`recognitionFooterSpacing`及按钮宽度分别配置布局，`recognitionControlAppearance`可按操作单独调整按钮的字体、颜色、图标及其他外观。识别语言入口由`showsRecognitionLanguageButton`控制，默认隐藏。

媒体展开/收起按钮默认显示在首个媒体靠页面中间的一侧，`media.buttonPlacement`可切换为下方显示。按钮宽高、圆角、间距、字体和颜色均可配置，`showsItemCountInButton`控制是否显示媒体数量。

输入栏默认无描边，文字输入和语音输入分别使用独立圆角。`input.textViewMaxHeight`默认限制输入框高度为适配后的120，超出部分在输入框内滚动。
