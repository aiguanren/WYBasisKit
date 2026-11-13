//
//  WYRecordAnimationConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/2/17.
//

import UIKit

/// 录音操作按钮外观
@objc public enum WYRecordingActionStyle: Int {
    /// 圆形按钮
    case circular
    /// 弧形条状按钮
    case curved
}

/// 转写编辑操作控件
@objc public enum WYChatRecordingEditorControl: Int { case close, language, translation, emoji, retry, originalVoice, send }

public struct WYRecordAnimationConfig {
    /// 录音浮层遮罩颜色
    public var overlayBackgroundColor: UIColor = .black.withAlphaComponent(0.7)
    /// 录音及转写气泡的自定义箭头图片，nil时使用气泡箭头
    public var bubbleArrowImage: UIImage? = nil
    /// 录音及转写气泡的自定义箭头图片颜色，nil时保留图片颜色
    public var bubbleArrowImageTintColor: UIColor? = nil
    /// 录音及转写气泡的自定义箭头图片偏移
    public var bubbleArrowImageOffset: CGPoint = .zero
    /// 录音提示距离声波气泡底部的间距
    public var recordingHintSpacing: CGFloat = UIDevice.wy_screenHeight(12, WYBasisKitConfig.defaultScreenPixels)
    /// 直接转写录音时的松手提示
    public var dictationReleaseText: String = WYLocalized("松开 发送", table: WYBasisKitConfig.kitLocalizableTable)

    /// 录音操作按钮外观，默认弧形条状
    public var actionStyle: WYRecordingActionStyle = .curved
    /// 弧形操作按钮尺寸
    public var curvedActionSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(220, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(80, WYBasisKitConfig.defaultScreenPixels))
    /// 弧形操作按钮圆角
    public var curvedActionCornerRadius: CGFloat = UIDevice.wy_screenWidth(36, WYBasisKitConfig.defaultScreenPixels)
    /// 弧形操作按钮中间向上弯曲的高度，0时为直条
    public var curvedActionBendHeight: CGFloat = UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels)
    /// 弧形操作按钮文字向屏幕中间的水平偏移
    public var curvedActionTitleOffsetX: CGFloat = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels)
    /// 弧形操作按钮倾斜角度，单位弧度
    public var curvedActionTiltAngle: CGFloat = .pi / 18
    /// 弧形操作按钮中心相对容器中心的水平距离
    public var curvedActionCenterOffsetX: CGFloat = UIDevice.wy_screenWidth(124, WYBasisKitConfig.defaultScreenPixels)
    /// 弧形操作按钮普通和选中背景色
    public var curvedActionColors: (normal: UIColor, selected: UIColor) = (.wy_hex("#626265"), .wy_hex("#DDE3FF"))

    
    /// 是否启用语音识别，默认false
    public var supportSpeechRecognition: Bool = false
    
    /// 声波线宽度
    public var soundWavesWidth: CGFloat = UIDevice.wy_screenWidth(2, WYBasisKitConfig.defaultScreenPixels)
    
    /// 声波线最大高度
    public var soundWavesMaxHeight: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels),
                                    cancel: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels),
                                    transfer: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels))
    
    /// 声波线最小高度
    public var soundWavesMinHeight: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels),
                                    cancel: UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels),
                                    transfer: UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels))
    
    /// 声波线之间的间距
    public var soundWavesSpace: CGFloat = UIDevice.wy_screenWidth(1, WYBasisKitConfig.defaultScreenPixels)
    
    /// 声波显示条数
    public var severalSoundWaves: (recording: Int,
                                   cancel: Int,
                                   transfer: Int) = (recording: 25,
                                                           cancel: 19,
                                                           transfer: 19)
    
    /// 声波线颜色
    public var colorOfSoundWavesOnRecording: (recording: UIColor,
                                              cancel: UIColor,
                                              transfer: UIColor) = (recording: .wy_hex("282828").withAlphaComponent(0.6),
                                                                    cancel: .wy_hex("282828").withAlphaComponent(0.6),
                                                                    transfer: .wy_hex("282828").withAlphaComponent(0.6))
    
    /// 录音、取消录音与转文字时气泡控件距离屏幕底部间距
    public var soundWavesViewBottomOffset: CGFloat = UIDevice.wy_screenHeight(380, WYBasisKitConfig.defaultScreenPixels)
    
    /// 录音、取消录音与转文字时气泡控件宽度
    public var soundWavesViewWidth: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(160, WYBasisKitConfig.defaultScreenPixels),
                                    cancel: UIDevice.wy_screenWidth(90, WYBasisKitConfig.defaultScreenPixels),
                                    transfer: UIDevice.wy_screenWidth - 50)
    
    /// 录音、取消录音与转文字时气泡控件高度
    public var soundWavesViewHeight: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels),
                                    cancel: UIDevice.wy_screenWidth(90, WYBasisKitConfig.defaultScreenPixels),
                                    transfer: UIDevice.wy_screenWidth(90, WYBasisKitConfig.defaultScreenPixels))
    
    /// 录音、取消录音与转文字时声波动画气泡主体圆角半径
    public var cornerRadiusForMoveUp: (recording: CGFloat,
                                          cancel: CGFloat,
                                       transfer: CGFloat) = (recording: UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels),
                                                                cancel: UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels),
                                            transfer: UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels))
    
    /// 录音、取消录音与转文字时声波动画气泡背景色
    public var backgroundColorForMoveUp: (recording: UIColor,
                                          cancel: UIColor,
                                          transfer: UIColor) = (recording: .wy_hex("#DDE3FF"),
                                                                cancel: .wy_hex("#F27D8A"),
                                            transfer: .wy_hex("#DDE3FF"))
    
    /// 录音、取消录音与转文字时声波动画气泡边框的颜色
    public var borderColorForMoveUp: (recording: UIColor,
                                          cancel: UIColor,
                                          transfer: UIColor) = (recording: .wy_hex("#DDE3FF"),
                                                                cancel: .wy_hex("#F27D8A"),
                                            transfer: .wy_hex("#DDE3FF"))
    
    /// 录音、取消录音与转文字时声波动画气泡边框宽度
    public var borderWidthForMoveUp: (recording: CGFloat,
                                          cancel: CGFloat,
                                       transfer: CGFloat) = (recording: 0,
                                                                cancel: 0,
                                            transfer: 0)
    
    /// 录音、取消录音与转文字时声波动画气泡三角箭头的尺寸（宽度，高度）(宽度是底边长度，高度是尖点到底边的垂直距离)
    public var arrowSizeForMoveUp: (recording: CGSize,
                                          cancel: CGSize,
                                       transfer: CGSize) = (recording: CGSize(width: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)),
                                                                cancel: CGSize(width: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)),
                                            transfer: CGSize(width: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)))
    
    /// 录音、取消录音与转文字时声波动画气泡三角箭头的圆角半径
    public var arrowTipRadiusForMoveUp: (recording: CGFloat,
                                          cancel: CGFloat,
                                         transfer: CGFloat) = (recording: UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels),
                                                               cancel: UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels),
                                                               transfer: UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels))
    
    /// 转文字及显示实时文本时声波距离气泡右侧与底部的间距
    public var soundWavesRightOffsetForAirBubble: CGPoint = CGPoint(x: UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels), y: UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels))
    
    /// 取消按钮背景图
    public var cancelRecordViewImage: (onInterior: UIImage, onExternal: UIImage) = (onInterior: WYChatDefaultResources.recordActionSelectedBackground, onExternal: WYChatDefaultResources.recordActionBackground)
    
    /// 取消按钮内部文本和提示文本
    public var cancelRecordViewText: (onInterior: String, tips: String) = (onInterior: WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable), tips: WYLocalized("松手 取消", table: WYBasisKitConfig.kitLocalizableTable))
    
    /// 转文字按钮内部文本和提示文本
    public var transferViewText: (onInterior: String, tips: String) = (onInterior: WYLocalized("滑到这里\n转文字", table: WYBasisKitConfig.kitLocalizableTable).replacingOccurrences(of: "\n", with: " "), tips: WYLocalized("松手 编辑", table: WYBasisKitConfig.kitLocalizableTable))
    
    /// 录音按钮提示文本
    public var recordViewTips: (onInterior: String, onExternal: String) = (onInterior: WYLocalized("松手 发语音", table: WYBasisKitConfig.kitLocalizableTable), onExternal: WYLocalized("语音", table: WYBasisKitConfig.kitLocalizableTable))
    
    /// 转文字按钮背景图
    public var transferViewImage: (onInterior: UIImage, onExternal: UIImage) = (onInterior: WYChatDefaultResources.recordActionSelectedBackground, onExternal: WYChatDefaultResources.recordActionBackground)
    
    /// 取消按钮及转文字按钮的提示语字号和色值
    public var tipsInfoForMoveUp: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_rgb(163, 163, 163))
    
    /// 录音按钮提示语内部字体及色值
    public var recordViewTipsInfoForInterior: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_rgb(75, 75, 78))
    
    /// 录音按钮提示语外部字体及色值
    public var recordViewTipsInfoForExternal: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_hex("#E3E6F2"))
    
    /// 取消录音按钮内部字体、色值
    public var cancelRecordViewTextInfoForInterior: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_hex("#232B49"))
    
    /// 取消录音按钮外部字体、色值
    public var cancelRecordViewTextInfoForExternal: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_hex("#E3E6F2"))
    
    /// 转文字按钮内部字体、色值
    public var transferViewTextInfoForInterior: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_hex("#232B49"))
    
    /// 转文字按钮外部字体、色值
    public var transferViewTextInfoForExternal: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_hex("#E3E6F2"))
    
    /// 取消录音按钮和转文字按钮的偏转角度
    public var moveUpViewDeviationAngle: CGFloat = 0
    
    
    /// 声波动画滑动区域圆弧的半径
    public var arcRadian: CGFloat = UIDevice.wy_screenWidth(35, WYBasisKitConfig.defaultScreenPixels)
    
    /// 声波动画可滑动区域的高度
    public var areaHeight: CGFloat = UIDevice.wy_screenHeight(120, WYBasisKitConfig.defaultScreenPixels)
    
    /// 整个声波动画组件向下偏移多少(可兼顾齐刘海)
    public var recordViewBottomOffset: CGFloat = 0
    
    /// 圆形样式的录音提示距离底部操作区顶部的间距
    public var recordTipViewTopOffset: CGFloat = UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels)
    
    /// 取消录音或者语音转文字按钮直径
    public var moveUpButtonDiameter: (onInterior: CGFloat, onExternal: CGFloat) = (onInterior: UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels), onExternal: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels))
    
    /// 取消录音或者语音转文字按钮中心点距离 声波动画控件底部 与 底部圆弧顶点 的间距
    public var moveUpButtonOffset: (top: CGFloat, bottom: CGFloat) = (top: UIDevice.wy_screenWidth(130, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenWidth(75, WYBasisKitConfig.defaultScreenPixels))
    
    /// 取消录音或者语音转文字按钮中心点距离tip控件底部的间距
    public var moveUpButtonCenterOffsetY: (onInterior: CGFloat, onExternal: CGFloat) = (onInterior: UIDevice.wy_screenWidth(55, WYBasisKitConfig.defaultScreenPixels), onExternal: UIDevice.wy_screenWidth(45, WYBasisKitConfig.defaultScreenPixels))
    
    /// 取消录音按钮和转文字按钮中心点X值距离屏幕父控件左侧或者右侧的间距(如果supportSpeechRecognition为false，则此属性无效，内部会强制水平居中)
    public var moveUpButtonCenterOffsetX: CGFloat = UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels)
    
    /// 声波动画操作区切换时是否需要震动反馈
    public var vibrationFeedback: Bool = true
    
    /// 声波动画操作区边缘颜色
    public var strokeColor: UIColor = .clear
    
    /// 声波动画操作区内部填充色(手指在操作区域内部或者外部)
    public var fillColor: (onInterior: UIColor, onExternal: UIColor) = (onInterior: .wy_rgb(191, 191, 195), onExternal: .wy_rgb(90, 90, 92))
    
    /// 声波动画操作区阴影位置，(0, 0)时四周都有阴影
    public var shadowOffset: CGSize = CGSize(width: -UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels), height: -UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels))
    
    /// 声波动画操作区阴影颜色
    public var shadowColor: UIColor = .black
    
    /// 声波动画操作区阴影透明度
    public var shadowOpacity: CGFloat = 0.1
    
    /// 最多可以录制多少秒(最短和最长录音时间)
    public var recordTime: (min: TimeInterval, max: TimeInterval) = (min: 0.1, max: 60)
    
    /// 普通语音录音区是否显示实时文本，默认false，滑入转文字后显示
    public var showsLiveTextWhileRecording: Bool = false
    /// 实时转写文本距离气泡边缘的间距
    public var liveTextInsets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels), left: UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels), right: UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels))
    /// 实时转写文本与底部声波的间距
    public var liveTextWaveformSpacing: CGFloat = UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels)
    /// 直接转写在录音区松手后是否发送文本，默认true，false时进入编辑
    public var dictationSendsOnRelease: Bool = true
    /// 直接转写的编辑操作文字
    public var dictationEditText: String = WYLocalized("编辑", table: WYBasisKitConfig.kitLocalizableTable)
    /// 直接转写是否显示声波，默认false
    public var dictationShowsWaveform: Bool = false
    /// 转写编辑时是否显示发送原语音按钮，默认true
    public var showsOriginalVoiceButton: Bool = true
    /// 发送原语音按钮文字
    public var recognitionSendVoiceText: String = WYLocalized("发送原语音", table: WYBasisKitConfig.kitLocalizableTable)

    /// 语音识别来源，默认使用Apple
    public var speechRecognitionSource: WYChatSpeechRecognitionSource = .apple
    /// 语音识别时机，默认边录音边识别
    public var speechRecognitionMode: WYChatSpeechRecognitionMode = .whileRecording
    /// 外部语音识别实现
    public var speechRecognitionProvider: WYChatSpeechRecognizer? = nil
    /// 外部录音实现，nil时使用内置采集
    public var recorder: WYChatRecorder? = nil
    /// 识别语言
    public var speechLocaleIdentifier: String = Locale.preferredLanguages.first ?? Locale.current.identifier
    /// 是否只允许本地识别，默认false
    public var requiresOnDeviceRecognition: Bool = false
    /// 识别超时，单位秒
    public var speechRecognitionTimeout: TimeInterval = 30
    /// 自定义录音设置，空字典时使用AAC单声道设置
    public var recordSettings: [String: Any] = [:]
    /// 录音面板动画时长
    public var animationDuration: TimeInterval = 0.25
    /// 转写失败提示
    public var recognitionFailureText: String = WYLocalized("识别失败，请重试", table: WYBasisKitConfig.kitLocalizableTable)
    /// 转写等待提示
    public var recognizingText: String = WYLocalized("正在识别…", table: WYBasisKitConfig.kitLocalizableTable)
    /// 转写确认按钮文字
    public var recognitionSendText: String = WYLocalized("发送", table: WYBasisKitConfig.kitLocalizableTable)
    /// 转写重试按钮文字
    public var recognitionRetryText: String = WYLocalized("重试", table: WYBasisKitConfig.kitLocalizableTable)
    /// 转写取消按钮文字
    public var recognitionCancelText: String = WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable)
    /// 转写编辑字体
    public var recognitionFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(24, WYBasisKitConfig.defaultScreenPixels))
    /// 转写编辑文字颜色
    public var recognitionTextColor: UIColor = .wy_hex("#111111")
    /// 转写编辑背景色
    public var recognitionBackgroundColor: UIColor = .wy_hex("#DDE3FF")
    /// 转写编辑面板高度
    public var recognitionPanelHeight: CGFloat = UIDevice.wy_screenHeight(480, WYBasisKitConfig.defaultScreenPixels)

    /// 转写编辑最小高度
    public var recognitionMinimumHeight: CGFloat = UIDevice.wy_screenHeight(220, WYBasisKitConfig.defaultScreenPixels)
    /// 转写编辑面板外边距，底部相对键盘顶部
    public var recognitionPanelOuterInsets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels), left: UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenHeight(16, WYBasisKitConfig.defaultScreenPixels), right: UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels))
    /// 转写编辑面板内边距
    public var recognitionPanelInsets: UIEdgeInsets = .zero
    /// 转写编辑面板圆角
    public var recognitionPanelCornerRadius: CGFloat = UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels)
    /// 转写编辑控件行高度
    public var recognitionControlHeight: CGFloat = UIDevice.wy_screenHeight(48, WYBasisKitConfig.defaultScreenPixels)
    /// 转写编辑控件间距
    public var recognitionControlSpacing: CGFloat = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels)
    /// 转写编辑顶部操作行高度
    public var recognitionHeaderHeight: CGFloat = UIDevice.wy_screenHeight(36, WYBasisKitConfig.defaultScreenPixels)
    /// 转写编辑顶部操作行与气泡的间距
    public var recognitionHeaderSpacing: CGFloat = UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels)
    /// 转写编辑气泡与底部操作行的间距
    public var recognitionFooterSpacing: CGFloat = UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels)
    /// 转写编辑发送及原语音按钮宽度，空间不足时自动缩小
    public var recognitionActionWidth: CGFloat = UIDevice.wy_screenWidth(128, WYBasisKitConfig.defaultScreenPixels)
    /// 转写编辑语言及翻译按钮宽度
    public var recognitionHeaderButtonWidth: CGFloat = UIDevice.wy_screenWidth(68, WYBasisKitConfig.defaultScreenPixels)
    /// 转写编辑关闭及表情按钮宽度
    public var recognitionAccessoryWidth: CGFloat = UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels)
    /// 转写编辑关闭及表情图标尺寸
    public var recognitionAccessoryImageSize: CGFloat = UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels)
    /// 转写编辑关闭及表情按钮颜色
    public var recognitionAccessoryColor: UIColor = .white
    /// 转写编辑发送按钮文字颜色
    public var recognitionSendColor: UIColor = .wy_hex("#111111")
    /// 转写编辑发送按钮背景色
    public var recognitionSendBackgroundColor: UIColor = .white
    /// 自定义转写编辑控件，参数为操作和已应用默认外观的按钮
    public var recognitionControlAppearance: ((_ control: WYChatRecordingEditorControl, _ button: UIButton) -> Void)? = nil
    /// 转写编辑按钮字体
    public var recognitionControlFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels))
    /// 转写编辑按钮颜色
    public var recognitionControlColor: UIColor = .white
    /// 转写编辑按钮背景色
    public var recognitionControlBackgroundColor: UIColor = .white.withAlphaComponent(0.12)
    /// 转写编辑按钮圆角
    public var recognitionControlCornerRadius: CGFloat = UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels)
    /// 转写编辑文字内边距
    public var recognitionTextInsets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels), left: UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels), right: UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels))
    /// 转写编辑文本背景色
    public var recognitionTextBackgroundColor: UIColor = .clear
    /// 转写编辑关闭图标，nil时只显示文字
    public var recognitionCloseImage: UIImage? = UIImage(systemName: "xmark")
    /// 转写编辑表情图标
    public var recognitionEmojiImage: UIImage? = UIImage(systemName: "face.smiling")
    /// 转写编辑键盘图标
    public var recognitionKeyboardImage: UIImage? = UIImage(systemName: "keyboard")
    /// 转写编辑是否显示表情按钮，默认true
    public var showsRecognitionEmojiButton: Bool = true
    /// 转写编辑表情配置
    public var recognitionEmoji: WYEmojiViewConfig = WYEmojiViewConfig()
    /// 转写编辑是否显示识别语言按钮，默认false
    public var showsRecognitionLanguageButton: Bool = false
    /// 识别语言列表，空数组时Apple使用系统支持的语言，外部识别仅显示当前语言
    public var speechRecognitionLanguages: [String] = []
    /// 识别语言按钮文字
    public var recognitionLanguageText: String = WYLocalized("语言", table: WYBasisKitConfig.kitLocalizableTable)
    /// 是否启用外部文本翻译，默认false
    public var enablesTranslation: Bool = false
    /// 外部文本翻译服务
    public var translationProvider: WYChatTextTranslator? = nil
    /// 翻译源语言，nil时自动识别
    public var translationSourceLocaleIdentifier: String? = nil
    /// 翻译目标语言
    public var translationTargetLocaleIdentifier: String = Locale.current.identifier
    /// 翻译目标语言列表，空数组时使用translationTargetLocaleIdentifier
    public var translationTargetLanguages: [String] = []
    /// 翻译超时，单位秒
    public var translationTimeout: TimeInterval = 30
    /// 翻译失败提示
    public var translationFailureText: String = WYLocalized("翻译失败，请重试", table: WYBasisKitConfig.kitLocalizableTable)
    /// 翻译等待提示
    public var translationWaitingText: String = WYLocalized("正在翻译…", table: WYBasisKitConfig.kitLocalizableTable)
    /// 翻译按钮文字
    public var translationText: String = WYLocalized("翻译", table: WYBasisKitConfig.kitLocalizableTable)

    /// 录音文件保存地址
    public var chatAudioUrl: URL = (FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory).appendingPathComponent("WYChatAudio", isDirectory: true)
    public init() {}
}
