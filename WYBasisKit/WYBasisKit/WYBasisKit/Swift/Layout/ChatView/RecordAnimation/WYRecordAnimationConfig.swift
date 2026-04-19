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
    public var soundWavesWidth: CGFloat = UIDevice.wy_screenWidth(2.6)
    
    /// 声波线高度
    public var soundWavesHeight: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(48),
                                    cancel: UIDevice.wy_screenWidth(38),
                                    transfer: UIDevice.wy_screenWidth(48))
    
    /// 声波控件宽度
    public var soundWavesViewWidth: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(220),
                                    cancel: UIDevice.wy_screenWidth(130),
                                    transfer: UIDevice.wy_screenWidth(525))
    
    /// 声波控件高度
    public var soundWavesViewHeight: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: UIDevice.wy_screenWidth(100),
                                    cancel: UIDevice.wy_screenWidth(90),
                                    transfer: UIDevice.wy_screenWidth(170))
    
    /// 声波线之间的间距
    public var soundWavesSpace: CGFloat = UIDevice.wy_screenWidth(2.5)
    
    /// 声波显示条数
    public var severalSoundWaves: (recording: Int,
                                   cancel: Int,
                                   transfer: Int) = (recording: 26,
                                                           cancel: 16,
                                                           transfer: 16)
    
    /// 声波线颜色
    public var colorOfSoundWavesOnRecording: (recording: UIColor,
                                              cancel: UIColor,
                                              transfer: UIColor) = (recording: .wy_hex("282828").withAlphaComponent(0.6),
                                                                    cancel: .wy_hex("282828").withAlphaComponent(0.6),
                                                                    transfer: .wy_hex("282828").withAlphaComponent(0.6))
    
    /// 录音、取消录音与转文字时声波动画背景图
    public var backgroundImageForMoveup: (recording: UIImage,
                                          cancel: UIImage,
                                          transfer: UIImage) = (recording: soundWavesDefaultImage(), cancel: soundWavesDefaultImage(), transfer: soundWavesDefaultImage())
    
    /// 录音、取消录音与转文字时声波动画背景色
    public var backgroundColorForMoveup: (recording: UIColor,
                                          cancel: UIColor,
                                          transfer: UIColor) = (recording: .wy_hex("#94EB68"),
                                            cancel: .wy_hex("#94EB68"),
                                            transfer: .wy_hex("#94EB68"))
    
    /// 取消按钮背景图
    public var cancelRecordViewImage: (onInterior: UIImage, onExternal: UIImage) = (onInterior: .wy_createImage(from: .wy_rgb(236, 236, 236), size: CGSize(width: UIDevice.wy_screenWidth(100), height: UIDevice.wy_screenWidth(100))).wy_cuttingRound(), onExternal: .wy_createImage(from: .wy_rgb(57, 57, 57), size: CGSize(width: UIDevice.wy_screenWidth(80), height: UIDevice.wy_screenWidth(80))).wy_cuttingRound())
    
    /// 取消按钮内部文本和提示文本
    public var cancelRecordViewText: (onInterior: String, tips: String) = (onInterior: "取消", tips: "松手 取消")
    
    /// 转文字按钮内部文本和提示文本
    public var transferViewText: (onInterior: String, tips: String) = (onInterior: "滑到这里\n转文字", tips: "松手 编辑文字")
    
    /// 录音按钮提示文本
    public var recordViewTips: (onInterior: String, onExternal: String) = (onInterior: "松开 发送", onExternal: "语音")
    
    /// 转文字按钮背景图
    public var transferViewImage: (onInterior: UIImage, onExternal: UIImage) = (onInterior: .wy_createImage(from: .wy_rgb(236, 236, 236), size: CGSize(width: UIDevice.wy_screenWidth(100), height: UIDevice.wy_screenWidth(100))).wy_cuttingRound(), onExternal: .wy_createImage(from: .wy_rgb(57, 57, 57), size: CGSize(width: UIDevice.wy_screenWidth(80), height: UIDevice.wy_screenWidth(80))).wy_cuttingRound())
    
    /// 取消按钮及转文字按钮的提示语字号和色值
    public var tipsInfoForMoveup: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15)), color: .wy_rgb(163, 163, 163))
    
    /// 录音按钮提示语字体及色值
    public var recordViewTipsInfo: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: UIFont.wy_fontSize(15)), color: .wy_rgb(163, 163, 163))
    
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
    
    /// 录音按钮图标及Size
    public var recordViewImageInfo: (icon: UIImage, size: CGSize) = (icon: UIImage.wy_find("WYChatViewSoundWavesRecord", inBundle: WYChatSourceBundle).withRenderingMode(.alwaysTemplate), size: CGSize(width: UIDevice.wy_screenWidth(27.2), height: UIDevice.wy_screenWidth(55)))
    
    /// 录音按钮图标色值
    public var recordViewImageColor: (onInterior: UIColor, onExternal: UIColor) = (onInterior: .wy_rgb(57, 57, 57), onExternal: .wy_rgb(156, 156, 156))
    
    /// 声波动画滑动区域圆弧的半径
    public var arcRadian: CGFloat = UIDevice.wy_screenWidth(35)
    
    /// 声波动画可滑动区域的高度
    public var areaHeight: CGFloat = UIDevice.wy_screenWidth(150)
    
    /// 整个声波动画组件向下偏移多少(可兼顾齐刘海)
    public var recordViewBottomOffset: CGFloat = UIDevice.wy_tabbarSafetyZone
    
    /// 取消录音或者语音转文字按钮直径
    public var moveupButtonDiameter: (onInterior: CGFloat, onExternal: CGFloat) = (onInterior: UIDevice.wy_screenWidth(100), onExternal: UIDevice.wy_screenWidth(80))
    
    /// 取消录音或者语音转文字按钮中心点距离 声波动画控件底部 与 底部圆弧顶点 的间距
    public var moveupButtonOffset: (top: CGFloat, bottom: CGFloat) = (top: UIDevice.wy_screenWidth(130), bottom: UIDevice.wy_screenWidth(65))
    
    /// 取消录音或者语音转文字按钮中心点距离tip控件底部的间距
    public var moveupButtonCenterOffsetY: (onInterior: CGFloat, onExternal: CGFloat) = (onInterior: UIDevice.wy_screenWidth(55), onExternal: UIDevice.wy_screenWidth(45))
    
    /// 取消录音按钮和转文字按钮中心点X值距离屏幕父控件左侧或者右侧的间距
    public var moveupButtonCenterOffsetX: CGFloat = UIDevice.wy_screenWidth(UIDevice.wy_screenWidth(100))
    
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

/// 获取录音默认背景图
private func soundWavesDefaultImage(_ capInsets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenWidth(10), left: UIDevice.wy_screenWidth(10), bottom: UIDevice.wy_screenWidth(20), right: UIDevice.wy_screenWidth(10))) -> UIImage {
    
    return UIImage.wy_find("WYChatViewDecibel", inBundle: WYChatSourceBundle).withRenderingMode(.alwaysTemplate).resizableImage(withCapInsets: capInsets, resizingMode: .stretch)
}
