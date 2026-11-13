//
//  WYChatComponentsObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

public extension WYChatInputView {
    /// 输入框是否正在采集或等待语音识别结果
    @objc(isInputDictating) var isInputDictatingObjC: Bool { isInputDictating }
    /// 输入框语音识别错误，参数为错误信息，nil时显示默认提示
    @objc(inputDictationErrorHandler) var inputDictationErrorHandlerObjC: ((_ error: NSError) -> Void)? { get { inputDictationErrorHandler } set { inputDictationErrorHandler = newValue } }
    /// 语音或文本输入容器
    @objc(textVoiceContentView) var textVoiceContentViewObjC: UIButton { textVoiceContentView }
    /// 语音切换按钮
    @objc(textVoiceView) var textVoiceViewObjC: UIButton { textVoiceView }
    /// 表情切换按钮
    @objc(emojiView) var emojiViewObjC: UIButton { emojiView }
    /// 更多切换按钮
    @objc(moreView) var moreViewObjC: UIButton { moreView }
    /// 独立发送按钮
    @objc(specialSendButton) var specialSendButtonObjC: UIButton? { specialSendButton }
    /// 录音结果，参数为文件URL、时长和错误
    @objc(recordingResultHandler) var recordingResultHandlerObjC: ((_ url: URL?, _ duration: TimeInterval, _ error: NSError?) -> Void)? { get { recordingResultHandler } set { recordingResultHandler = newValue } }
    /// 发送当前输入文本
    @objc(sendInput) var sendInputObjC: @convention(block) () -> WYChatInputView { { [self] in self.didClickSendView(); return self } }
    /// 转换表情文本，参数为文本
    @objc(sharedEmojiAttributed) var sharedEmojiAttributedObjC: @convention(block) (_ text: String) -> NSAttributedString { { [self] text in self.sharedEmojiAttributed(string: text) } }
    /// 转换表情富文本，参数为富文本
    @objc(sharedEmojiAttributedText) var sharedEmojiAttributedTextObjC: @convention(block) (_ attributedText: NSAttributedString) -> NSAttributedString { { [self] text in self.sharedEmojiAttributedText(attributed: text) } }

    /// 创建输入栏，参数为输入栏配置
    @objc class var create: @convention(block) (_ configuration: WYInputBarConfigObjC) -> WYChatInputView { { config in WYChatInputView(config: config.toValue()) } }
    /// 当前实例配置
    @objc(inputBarConfig) var inputBarConfigObjC: WYInputBarConfigObjC { get { WYInputBarConfigObjC(inputBarConfig) } set { inputBarConfig = newValue.toValue() } }
    /// 表情解析配置
    @objc(emojiViewConfig) var emojiViewConfigObjC: WYEmojiViewConfigObjC { get { WYEmojiViewConfigObjC(emojiViewConfig) } set { emojiViewConfig = newValue.toValue() } }
    /// 录音配置
    @objc(recordAnimationConfig) var recordAnimationConfigObjC: WYRecordAnimationConfigObjC { get { WYRecordAnimationConfigObjC(recordAnimationConfig) } set { recordAnimationConfig = newValue.toValue() } }
    /// 输入文本控件
    @objc(textView) var textViewObjC: WYChatInputTextView { textView }
    /// 录音界面
    @objc(recordView) var recordViewObjC: WYRecordAnimationView { recordView }
    /// 点击事件代理
    @objc(delegate) var delegateObjC: WYChatInputViewDelegate? { get { delegate } set { delegate = newValue } }
    /// 事件接管代理
    @objc(eventsHandler) var eventsHandlerObjC: WYChatInputViewEventsHandler? { get { eventsHandler } set { eventsHandler = newValue } }
}

public extension WYChatEmojiView {
    /// 表情列表
    @objc(collectionView) var collectionViewObjC: UICollectionView { collectionView }
    /// 表情数据源
    @objc(dataSource) var dataSourceObjC: [[String]] { get { dataSource } set { dataSource = newValue; collectionView.reloadData() } }
    /// 最近使用的表情
    @objc(recentlyEmoji) var recentlyEmojiObjC: [String] { recentlyEmoji }
    /// 事件接管代理
    @objc(eventsHandler) var eventsHandlerObjC: WYChatEmojiViewEventsHandler? { get { eventsHandler } set { eventsHandler = newValue } }
    /// 更新最近使用的表情，参数为已发送的富文本
    @objc(updateRecentlyEmoji) var updateRecentlyEmojiObjC: @convention(block) (_ attributedText: NSAttributedString) -> WYChatEmojiView { { [self] text in self.updateRecentlyEmoji(text); return self } }

    /// 创建表情面板，参数为表情配置
    @objc class var create: @convention(block) (_ configuration: WYEmojiViewConfigObjC) -> WYChatEmojiView { { config in WYChatEmojiView(config: config.toValue()) } }
    /// 当前实例配置
    @objc(emojiViewConfig) var emojiViewConfigObjC: WYEmojiViewConfigObjC { get { WYEmojiViewConfigObjC(emojiViewConfig) } set { emojiViewConfig = newValue.toValue() } }
    /// 点击事件代理
    @objc(delegate) var delegateObjC: WYChatEmojiViewDelegate? { get { delegate } set { delegate = newValue } }
}

public extension WYChatMoreView {
    /// 功能列表
    @objc(collectionView) var collectionViewObjC: UICollectionView { collectionView }
    /// 分页控件
    @objc(pageControl) var pageControlObjC: UIPageControl? { pageControl }
    /// 事件接管代理
    @objc(eventsHandler) var eventsHandlerObjC: WYMoreViewEventsHandler? { get { eventsHandler } set { eventsHandler = newValue } }
    /// 设置分页颜色，参数为普通页和当前页的颜色
    @objc(updatePageControlColors) var updatePageControlColorsObjC: @convention(block) (_ defaultColor: UIColor, _ currentColor: UIColor) -> WYChatMoreView { { [self] normal, current in self.updatePageControl(defaultColor: normal, currentColor: current); return self } }
    /// 设置分页图片，参数为普通页和当前页的图片
    @objc(updatePageControlImages) var updatePageControlImagesObjC: @convention(block) (_ defaultImage: UIImage?, _ currentImage: UIImage?) -> WYChatMoreView { { [self] normal, current in self.updatePageControl(defaultImage: normal, currentImage: current); return self } }

    /// 创建更多面板，参数为更多配置
    @objc class var create: @convention(block) (_ configuration: WYMoreViewConfigObjC) -> WYChatMoreView { { config in WYChatMoreView(config: config.toValue()) } }
    /// 当前实例配置
    @objc(moreViewConfig) var moreViewConfigObjC: WYMoreViewConfigObjC { get { WYMoreViewConfigObjC(moreViewConfig) } set { moreViewConfig = newValue.toValue() } }
    /// 点击事件代理
    @objc(delegate) var delegateObjC: WYChatMoreViewDelegate? { get { delegate } set { delegate = newValue } }
}

public extension WYRecordAnimationView {
    /// 切换录音功能区，参数为录音界面内的触摸位置
    @objc(switchStatus) var switchStatusObjC: @convention(block) (_ touchPoint: CGPoint) -> WYRecordAnimationView { { [self] point in self.switchStatus(point); return self } }

    /// 创建录音界面，参数为录音配置
    @objc class var create: @convention(block) (_ configuration: WYRecordAnimationConfigObjC) -> WYRecordAnimationView { { config in WYRecordAnimationView(alpha: 0, configuration: config.toValue()) } }
    /// 当前实例配置
    @objc(recordAnimationConfig) var recordAnimationConfigObjC: WYRecordAnimationConfigObjC { get { WYRecordAnimationConfigObjC(recordAnimationConfig) } set { recordAnimationConfig = newValue.toValue() } }
    /// 代理
    @objc(delegate) var delegateObjC: WYRecordEventsHandler? { get { delegate } set { delegate = newValue } }
    /// 录音文件结果，参数为文件、时长及错误
    @objc(resultHandler) var resultHandlerObjC: ((_ url: URL?, _ duration: TimeInterval, _ error: NSError?) -> Void)? { get { resultHandler } set { resultHandler = newValue } }
    /// 当前录音状态
    @objc(soundAnimationStatus) var soundAnimationStatusObjC: WYSoundAnimationStatus {
        get { soundAnimationStatus }
        set { soundAnimationStatus = newValue }
    }
    /// 转写结果，参数为最终文本及错误
    @objc(recognitionResultHandler) var recognitionResultHandlerObjC: ((_ text: String?, _ error: NSError?) -> Void)? { get { recognitionResultHandler } set { recognitionResultHandler = newValue } }
    /// 录音中的识别文本，参数为可被后续结果修订的完整文本
    @objc(recognitionPartialResultHandler) var recognitionPartialResultHandlerObjC: ((_ text: String) -> Void)? { get { recognitionPartialResultHandler } set { recognitionPartialResultHandler = newValue } }
    /// 转写文本确认发送，参数为编辑后的文本
    @objc(recognizedTextHandler) var recognizedTextHandlerObjC: ((_ text: String) -> Void)? { get { recognizedTextHandler } set { recognizedTextHandler = newValue } }
    /// 开始录音动画
    @objc(start) var startObjC: @convention(block) () -> WYRecordAnimationView { { [self] in self.start(); return self } }
    /// 翻译结果，参数为翻译文本和错误
    @objc(translationResultHandler) var translationResultHandlerObjC: ((_ text: String?, _ error: NSError?) -> Void)? { get { translationResultHandler } set { translationResultHandler = newValue } }
    /// 识别语言切换，参数为语言标识
    @objc(recognitionLanguageChangedHandler) var recognitionLanguageChangedHandlerObjC: ((_ localeIdentifier: String) -> Void)? { get { recognitionLanguageChangedHandler } set { recognitionLanguageChangedHandler = newValue } }
    /// 翻译当前编辑文本，参数为目标语言
    @objc(translateRecognizedText) var translateRecognizedTextObjC: @convention(block) (_ localeIdentifier: String) -> WYRecordAnimationView { { [self] locale in self.translateRecognizedText(to: locale); return self } }
    /// 取消当前翻译并保留编辑文本
    @objc(cancelTranslation) var cancelTranslationObjC: @convention(block) () -> WYRecordAnimationView { { [self] in self.cancelTranslation(); return self } }
    /// 重新识别录音的语言，参数为识别语言
    @objc(changeRecognitionLanguage) var changeRecognitionLanguageObjC: @convention(block) (_ localeIdentifier: String) -> WYRecordAnimationView { { [self] locale in self.changeRecognitionLanguage(to: locale); return self } }
    /// 当前录音用途
    @objc(recordingMode) var recordingModeObjC: WYChatRecordingMode { recordingMode }
    /// 开始指定用途的录音，参数为录音用途，直接转写需要启用语音识别
    @objc(startWithMode) var startWithModeObjC: @convention(block) (_ mode: WYChatRecordingMode) -> WYRecordAnimationView { { [self] mode in self.start(mode: mode); return self } }
    /// 发送转写编辑前的原始录音，文件由调用方保存或清理
    @objc(sendOriginalRecording) var sendOriginalRecordingObjC: @convention(block) () -> WYRecordAnimationView { { [self] in self.sendOriginalRecording(); return self } }
    /// 结束录音动画
    @objc(stop) var stopObjC: @convention(block) () -> WYRecordAnimationView { { [self] in self.stop(); return self } }
    /// 释放录音任务
    @objc(endRecordVoice) var endRecordVoiceObjC: @convention(block) () -> WYRecordAnimationView { { [self] in self.endRecordVoice(); return self } }
}

#endif
