//
//  WYRecordAnimationConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/2/17.
//

import UIKit
import Foundation

public struct WYRecordAnimationConfig {
    
    /// 声波线宽度
    public var soundWavesWidth: CGFloat = UIDevice.wy_screenWidth(2)
    
    /// 声波线最大高度
    public var soundWavesMaxHeight: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(24),
                                    cancel: UIDevice.wy_screenWidth(16),
                                    transfer: UIDevice.wy_screenWidth(16))
    
    /// 声波线最小高度
    public var soundWavesMinHeight: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(8),
                                    cancel: UIDevice.wy_screenWidth(5),
                                    transfer: UIDevice.wy_screenWidth(5))
    
    /// 声波线之间的间距
    public var soundWavesSpace: CGFloat = UIDevice.wy_screenWidth(1)
    
    /// 声波显示条数
    public var severalSoundWaves: (recording: Int,
                                   cancel: Int,
                                   transfer: Int) = (recording: 25,
                                                           cancel: 15,
                                                           transfer: 15)
    
    /// 声波线颜色
    public var colorOfSoundWavesOnRecording: (recording: UIColor,
                                              cancel: UIColor,
                                              transfer: UIColor) = (recording: .wy_hex("282828").withAlphaComponent(0.6),
                                                                    cancel: .wy_hex("282828").withAlphaComponent(0.6),
                                                                    transfer: .wy_hex("282828").withAlphaComponent(0.6))
    
    /// 录音、取消录音与转文字时气泡控件宽度
    public var soundWavesViewWidth: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(200),
                                    cancel: UIDevice.wy_screenWidth(90),
                                    transfer: UIDevice.wy_screenWidth - 50)
    
    /// 录音、取消录音与转文字时气泡控件高度
    public var soundWavesViewHeight: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(100),
                                    cancel: UIDevice.wy_screenWidth(90),
                                    transfer: UIDevice.wy_screenWidth(100))
    
    /// 录音、取消录音与转文字时声波动画气泡主体圆角半径
    public var cornerRadiusForMoveup: (recording: CGFloat,
                                          cancel: CGFloat,
                                       transfer: CGFloat) = (recording: UIDevice.wy_screenWidth(12),
                                                                cancel: UIDevice.wy_screenWidth(12),
                                            transfer: UIDevice.wy_screenWidth(12))
    
    /// 录音、取消录音与转文字时声波动画气泡背景色
    public var backgroundColorForMoveup: (recording: UIColor,
                                          cancel: UIColor,
                                          transfer: UIColor) = (recording: .wy_hex("#95EC69"),
                                                                cancel: .wy_hex("#FA5151"),
                                            transfer: .wy_hex("#95EC69"))
    
    /// 录音、取消录音与转文字时声波动画气泡边框的颜色
    public var borderColorForMoveup: (recording: UIColor,
                                          cancel: UIColor,
                                          transfer: UIColor) = (recording: .wy_hex("#95EC69"),
                                                                cancel: .wy_hex("#FA5151"),
                                            transfer: .wy_hex("#95EC69"))
    
    /// 录音、取消录音与转文字时声波动画气泡边框宽度
    public var borderWidthForMoveup: (recording: CGFloat,
                                          cancel: CGFloat,
                                       transfer: CGFloat) = (recording: 0,
                                                                cancel: 0,
                                            transfer: 0)
    
    /// 录音、取消录音与转文字时声波动画气泡三角箭头的尺寸（宽度，高度）(宽度是底边长度，高度是尖点到底边的垂直距离)
    public var arrowSizeForMoveup: (recording: CGSize,
                                          cancel: CGSize,
                                       transfer: CGSize) = (recording: CGSize(width: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)),
                                                                cancel: CGSize(width: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)),
                                            transfer: CGSize(width: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)))
    
    /// 录音、取消录音与转文字时声波动画气泡三角箭头的圆角半径
    public var arrowTipRadiusForMoveup: (recording: CGFloat,
                                          cancel: CGFloat,
                                         transfer: CGFloat) = (recording: UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels),
                                                               cancel: UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels),
                                                               transfer: UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels))
    
    /// 取消按钮背景图
    public var cancelRecordViewImage: (onInterior: UIImage, onExternal: UIImage) = (onInterior: .wy_createImage(from: .wy_rgb(236, 236, 236), size: CGSize(width: UIDevice.wy_screenWidth(100), height: UIDevice.wy_screenWidth(100))).wy_cuttingRound(), onExternal: .wy_createImage(from: .wy_rgb(57, 57, 57), size: CGSize(width: UIDevice.wy_screenWidth(80), height: UIDevice.wy_screenWidth(80))).wy_cuttingRound())
    
    /// 取消按钮内部文本和提示文本
    public var cancelRecordViewText: (onInterior: String, tips: String) = (onInterior: "取消", tips: "松手 取消")
    
    /// 转文字按钮内部文本和提示文本
    public var transferViewText: (onInterior: String, tips: String) = (onInterior: "滑到这里\n转文字", tips: "编辑文字")
    
    /// 录音按钮提示文本
    public var recordViewTips: (onInterior: String, onExternal: String) = (onInterior: "松开 发送", onExternal: "语音")
    
    /// 转文字按钮背景图
    public var transferViewImage: (onInterior: UIImage, onExternal: UIImage) = (onInterior: .wy_createImage(from: .wy_rgb(236, 236, 236), size: CGSize(width: UIDevice.wy_screenWidth(100), height: UIDevice.wy_screenWidth(100))).wy_cuttingRound(), onExternal: .wy_createImage(from: .wy_rgb(57, 57, 57), size: CGSize(width: UIDevice.wy_screenWidth(80), height: UIDevice.wy_screenWidth(80))).wy_cuttingRound())
    
    /// 取消按钮及转文字按钮的提示语字号和色值
    public var tipsInfoForMoveup: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15)), color: .wy_rgb(163, 163, 163))
    
    /// 录音按钮提示语内部字体及色值
    public var recordViewTipsInfoForInterior: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15)), color: .wy_rgb(20, 20, 20))
    
    /// 录音按钮提示语外部字体及色值
    public var recordViewTipsInfoForExternal: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15)), color: .wy_rgb(156, 156, 156))
    
    /// 取消录音按钮内部字体、色值
    public var cancelRecordViewTextInfoForInterior: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15)), color: .wy_rgb(20, 20, 20))
    
    /// 取消录音按钮外部字体、色值
    public var cancelRecordViewTextInfoForExternal: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15)), color: .wy_rgb(156, 156, 156))
    
    /// 转文字按钮内部字体、色值
    public var transferViewTextInfoForInterior: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15)), color: .wy_rgb(20, 20, 20))
    
    /// 转文字按钮外部字体、色值
    public var transferViewTextInfoForExternal: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15)), color: .wy_rgb(156, 156, 156))
    
    /// 取消录音按钮和转文字按钮的偏转角度
    public var moveupViewDeviationAngle: CGFloat = Double.pi * 0.12
    
    /// 录音按钮背景色
    public var recordViewColor:(onInterior: UIColor, onExternal: UIColor) = (onInterior: .wy_rgb(57, 57, 57), onExternal: .white)
    
    /// 录音按钮阴影色值
    public var recordViewShadowColor:(onInterior: UIColor, onExternal: UIColor) = (onInterior: .wy_rgb(57, 57, 57), onExternal: .wy_rgb(57, 57, 57))
    
    /// 声波动画滑动区域圆弧的半径
    public var arcRadian: CGFloat = UIDevice.wy_screenWidth(35)
    
    /// 声波动画可滑动区域的高度
    public var areaHeight: CGFloat = UIDevice.wy_screenWidth(150)
    
    /// 整个声波动画组件向下偏移多少(可兼顾齐刘海)
    public var recordViewBottomOffset: CGFloat = UIDevice.wy_tabbarSafetyZone
    
    /// 录音按钮内部提示文本距离滑动区域顶部的间距
    public var recordTipViewTopOffset: CGFloat = UIDevice.wy_screenWidth(20)
    
    /// 取消录音或者语音转文字按钮直径
    public var moveupButtonDiameter: (onInterior: CGFloat, onExternal: CGFloat) = (onInterior: UIDevice.wy_screenWidth(100), onExternal: UIDevice.wy_screenWidth(80))
    
    /// 取消录音或者语音转文字按钮中心点距离 声波动画控件底部 与 底部圆弧顶点 的间距
    public var moveupButtonOffset: (top: CGFloat, bottom: CGFloat) = (top: UIDevice.wy_screenWidth(130), bottom: UIDevice.wy_screenWidth(65))
    
    /// 取消录音或者语音转文字按钮中心点距离tip控件底部的间距
    public var moveupButtonCenterOffsetY: (onInterior: CGFloat, onExternal: CGFloat) = (onInterior: UIDevice.wy_screenWidth(55), onExternal: UIDevice.wy_screenWidth(45))
    
    /// 取消录音按钮和转文字按钮中心点X值距离屏幕父控件左侧或者右侧的间距
    public var moveupButtonCenterOffsetX: CGFloat = UIDevice.wy_screenWidth(UIDevice.wy_screenWidth(100))
    
    /// 声波动画操作区切换时是否需要震动反馈
    public var vibrationFeedback: Bool = true
    
    /// 声波动画操作区边缘颜色
    public var strokeColor: UIColor = .clear
    
    /// 声波动画操作区内部填充色(手指在操作区域内部或者外部)
    public var fillColor: (onInterior: UIColor, onExternal: UIColor) = (onInterior: .white.withAlphaComponent(0.5), onExternal: .black.withAlphaComponent(0.5))
    
    /// 声波动画操作区阴影位置，(0, 0)时四周都有阴影
    public var shadowOffset: CGSize = CGSize(width: -UIDevice.wy_screenWidth(5), height: -UIDevice.wy_screenWidth(5))
    
    /// 声波动画操作区阴影颜色
    public var shadowColor: UIColor = .white
    
    /// 声波动画操作区阴影透明度
    public var shadowOpacity: CGFloat = 0.1
    
    /// 最多可以录制多少秒(最短和最长录音时间)
    public var recordTime: (min: TimeInterval, max: TimeInterval) = (min: 0.1, max: 60)
    
    /// 录音文件保存地址
    public var chatAudioUrl: URL = WYStorage.createDirectory(directory: .documentDirectory, subDirectory: "WYChatAudio")
}
