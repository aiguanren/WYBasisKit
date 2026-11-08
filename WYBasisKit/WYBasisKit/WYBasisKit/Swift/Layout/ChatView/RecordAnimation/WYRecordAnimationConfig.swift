//
//  WYRecordAnimationConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/2/17.
//

import UIKit
import UIKit

public struct WYRecordAnimationConfig {
    
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
    public var soundWavesViewBottomOffset: CGFloat = (UIDevice.wy_screenHeight - UIDevice.wy_navViewHeight - UIDevice.wy_screenWidth(50, WYBasisKitConfig.defaultScreenPixels)) / 2
    
    /// 录音、取消录音与转文字时气泡控件宽度
    public var soundWavesViewWidth: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(200, WYBasisKitConfig.defaultScreenPixels),
                                    cancel: UIDevice.wy_screenWidth(90, WYBasisKitConfig.defaultScreenPixels),
                                    transfer: UIDevice.wy_screenWidth - 50)
    
    /// 录音、取消录音与转文字时气泡控件高度
    public var soundWavesViewHeight: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(90, WYBasisKitConfig.defaultScreenPixels),
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
                                          transfer: UIColor) = (recording: .wy_hex("#95EC69"),
                                                                cancel: .wy_hex("#FA5151"),
                                            transfer: .wy_hex("#95EC69"))
    
    /// 录音、取消录音与转文字时声波动画气泡边框的颜色
    public var borderColorForMoveUp: (recording: UIColor,
                                          cancel: UIColor,
                                          transfer: UIColor) = (recording: .wy_hex("#95EC69"),
                                                                cancel: .wy_hex("#FA5151"),
                                            transfer: .wy_hex("#95EC69"))
    
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
    
    /// 转文字时声波动画距离气泡右侧与底部偏移量(录音和取消录音固定居中显示)
    public var soundWavesRightOffsetForAirBubble: CGPoint = CGPoint(x: UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels), y: UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels))
    
    /// 取消按钮背景图
    public var cancelRecordViewImage: (onInterior: UIImage, onExternal: UIImage) = (onInterior: .wy_createImage(from: .wy_rgb(236, 236, 236), size: CGSize(width: UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels))).wy_cuttingRound(), onExternal: .wy_createImage(from: .wy_rgb(57, 57, 57), size: CGSize(width: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels))).wy_cuttingRound())
    
    /// 取消按钮内部文本和提示文本
    public var cancelRecordViewText: (onInterior: String, tips: String) = (onInterior: WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable), tips: WYLocalized("松手 取消", table: WYBasisKitConfig.kitLocalizableTable))
    
    /// 转文字按钮内部文本和提示文本
    public var transferViewText: (onInterior: String, tips: String) = (onInterior: WYLocalized("滑到这里\n转文字", table: WYBasisKitConfig.kitLocalizableTable), tips: WYLocalized("编辑文字", table: WYBasisKitConfig.kitLocalizableTable))
    
    /// 录音按钮提示文本
    public var recordViewTips: (onInterior: String, onExternal: String) = (onInterior: WYLocalized("松开 发送", table: WYBasisKitConfig.kitLocalizableTable), onExternal: WYLocalized("语音", table: WYBasisKitConfig.kitLocalizableTable))
    
    /// 转文字按钮背景图
    public var transferViewImage: (onInterior: UIImage, onExternal: UIImage) = (onInterior: .wy_createImage(from: .wy_rgb(236, 236, 236), size: CGSize(width: UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels))).wy_cuttingRound(), onExternal: .wy_createImage(from: .wy_rgb(57, 57, 57), size: CGSize(width: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels))).wy_cuttingRound())
    
    /// 取消按钮及转文字按钮的提示语字号和色值
    public var tipsInfoForMoveUp: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_rgb(163, 163, 163))
    
    /// 录音按钮提示语内部字体及色值
    public var recordViewTipsInfoForInterior: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_rgb(20, 20, 20))
    
    /// 录音按钮提示语外部字体及色值
    public var recordViewTipsInfoForExternal: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_rgb(156, 156, 156))
    
    /// 取消录音按钮内部字体、色值
    public var cancelRecordViewTextInfoForInterior: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_rgb(20, 20, 20))
    
    /// 取消录音按钮外部字体、色值
    public var cancelRecordViewTextInfoForExternal: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_rgb(156, 156, 156))
    
    /// 转文字按钮内部字体、色值
    public var transferViewTextInfoForInterior: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_rgb(20, 20, 20))
    
    /// 转文字按钮外部字体、色值
    public var transferViewTextInfoForExternal: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)), color: .wy_rgb(156, 156, 156))
    
    /// 取消录音按钮和转文字按钮的偏转角度
    public var moveUpViewDeviationAngle: CGFloat = Double.pi * 0.12
    
    /// 录音按钮背景色
    public var recordViewColor:(onInterior: UIColor, onExternal: UIColor) = (onInterior: .wy_rgb(57, 57, 57), onExternal: .white)
    
    /// 录音按钮阴影色值
    public var recordViewShadowColor:(onInterior: UIColor, onExternal: UIColor) = (onInterior: .wy_rgb(57, 57, 57), onExternal: .wy_rgb(57, 57, 57))
    
    /// 声波动画滑动区域圆弧的半径
    public var arcRadian: CGFloat = UIDevice.wy_screenWidth(35, WYBasisKitConfig.defaultScreenPixels)
    
    /// 声波动画可滑动区域的高度
    public var areaHeight: CGFloat = UIDevice.wy_screenWidth(150, WYBasisKitConfig.defaultScreenPixels)
    
    /// 整个声波动画组件向下偏移多少(可兼顾齐刘海)
    public var recordViewBottomOffset: CGFloat = UIDevice.wy_tabbarSafetyZone
    
    /// 录音按钮内部提示文本距离滑动区域顶部的间距
    public var recordTipViewTopOffset: CGFloat = UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels)
    
    /// 取消录音或者语音转文字按钮直径
    public var moveUpButtonDiameter: (onInterior: CGFloat, onExternal: CGFloat) = (onInterior: UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels), onExternal: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels))
    
    /// 取消录音或者语音转文字按钮中心点距离 声波动画控件底部 与 底部圆弧顶点 的间距
    public var moveUpButtonOffset: (top: CGFloat, bottom: CGFloat) = (top: UIDevice.wy_screenWidth(130, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenWidth(65, WYBasisKitConfig.defaultScreenPixels))
    
    /// 取消录音或者语音转文字按钮中心点距离tip控件底部的间距
    public var moveUpButtonCenterOffsetY: (onInterior: CGFloat, onExternal: CGFloat) = (onInterior: UIDevice.wy_screenWidth(55, WYBasisKitConfig.defaultScreenPixels), onExternal: UIDevice.wy_screenWidth(45, WYBasisKitConfig.defaultScreenPixels))
    
    /// 取消录音按钮和转文字按钮中心点X值距离屏幕父控件左侧或者右侧的间距(如果supportSpeechRecognition为false，则此属性无效，内部会强制水平居中)
    public var moveUpButtonCenterOffsetX: CGFloat = UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels)
    
    /// 声波动画操作区切换时是否需要震动反馈
    public var vibrationFeedback: Bool = true
    
    /// 声波动画操作区边缘颜色
    public var strokeColor: UIColor = .clear
    
    /// 声波动画操作区内部填充色(手指在操作区域内部或者外部)
    public var fillColor: (onInterior: UIColor, onExternal: UIColor) = (onInterior: .white.withAlphaComponent(0.5), onExternal: .black.withAlphaComponent(0.5))
    
    /// 声波动画操作区阴影位置，(0, 0)时四周都有阴影
    public var shadowOffset: CGSize = CGSize(width: -UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels), height: -UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels))
    
    /// 声波动画操作区阴影颜色
    public var shadowColor: UIColor = .white
    
    /// 声波动画操作区阴影透明度
    public var shadowOpacity: CGFloat = 0.1
    
    /// 最多可以录制多少秒(最短和最长录音时间)
    public var recordTime: (min: TimeInterval, max: TimeInterval) = (min: 0.1, max: 60)
    
    /// 语音识别来源，默认使用Apple
    public var speechRecognitionSource: WYChatSpeechRecognitionSource = .apple
    /// 外部语音识别实现
    public var speechRecognitionProvider: WYChatSpeechRecognizer? = nil
    /// 外部录音实现，nil时使用WYAudioKit
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
    public var recognitionFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels))
    /// 转写编辑文字颜色
    public var recognitionTextColor: UIColor = .label
    /// 转写编辑背景色
    public var recognitionBackgroundColor: UIColor = .secondarySystemBackground
    /// 转写编辑面板高度
    public var recognitionPanelHeight: CGFloat = UIDevice.wy_screenHeight(240, WYBasisKitConfig.defaultScreenPixels)

    /// 录音文件保存地址
    public var chatAudioUrl: URL = (FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory).appendingPathComponent("WYChatAudio", isDirectory: true)
    public init() {}
}
