//
//  WYAudioKit+Convert.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/21.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation
import AVFoundation

/// WYAudioKit 格式转换内部实现，AAC走导出会话、wav/aiff/caf走读写器PCM管线，单文件完成收尾、错误处理与批次进度聚合回调
extension WYAudioKit {
    
    /// 单个文件转换成功后的收尾(进度置满、批次摘牌，全部完成时按源文件顺序回调成功)
    func finishConvertFile(batchID: UUID, sourceURL: URL, outputURL: URL) {
        state.convertProgresses[sourceURL] = 1.0
        state.convertTasks.removeValue(forKey: sourceURL)
        
        // 计算并通知整体进度（仅最终 100% 回调）
        if let batch = state.convertGroups[batchID] {
            let total = batch.sourceUrls.count
            let completed = batch.sourceUrls.filter { url in
                url == sourceURL || state.convertProgresses[url] == 1.0
            }.count
            let progress = Double(completed) / Double(total)
            state.lastNotifiedConvertProgress[batchID] = progress
            delegate?.wy_formatConversionProgressUpdated?(audioKit: self,
                                                           localUrls: batch.sourceUrls,
                                                           progress: progress)
        }
        
        // 更新批次信息
        if var batch = state.convertGroups[batchID] {
            batch.pendingUrls.remove(sourceURL)
            batch.outputMap[sourceURL] = outputURL
            state.convertGroups[batchID] = batch
            
            // 如果所有文件都已完成，按源文件顺序回调成功(文件完成的先后顺序是随机的，直接给外部对不上号)
            if batch.pendingUrls.isEmpty {
                batch.success(batch.sourceUrls.compactMap { batch.outputMap[$0] })
                state.convertGroups.removeValue(forKey: batchID)
                state.lastNotifiedConvertProgress.removeValue(forKey: batchID)
            }
        }
        stopDisplayLinkIfNeeded()
    }
    
    /// 处理格式转换错误
    func handleConvertError(batchID: UUID, sourceURL: URL, error: Error) {
        guard var batch = state.convertGroups[batchID] else { return }
        batch.pendingUrls.remove(sourceURL)
        state.convertTasks.removeValue(forKey: sourceURL)
        state.convertProgresses.removeValue(forKey: sourceURL)
        if !batch.hasFailed {
            batch.hasFailed = true
            batch.failed(error)
        }
        state.convertGroups[batchID] = batch
        if batch.pendingUrls.isEmpty {
            state.convertGroups.removeValue(forKey: batchID)
            state.lastNotifiedConvertProgress.removeValue(forKey: batchID)
        }
        stopDisplayLinkIfNeeded()
    }
    
    /// 更新格式转换进度（按批次聚合）
    func updateConversionProgressIfNeeded() {
        guard !state.convertTasks.isEmpty else { return }
        // 更新每个转换任务的进度
        for (url, task) in state.convertTasks {
            state.convertProgresses[url] = task.readProgress()
        }
        // 按批次计算平均进度并回调
        for (batchID, batch) in state.convertGroups {
            let urls = batch.sourceUrls
            guard !urls.isEmpty else { continue }
            var total: Float = 0
            for url in urls {
                total += state.convertProgresses[url] ?? 0
            }
            let avg = Double(total / Float(urls.count))
            // 进度没变化就不回调(刷新器每帧都跑，不拦的话一秒30次内容完全相同的delegate，外部UI白刷)
            guard abs(avg - (state.lastNotifiedConvertProgress[batchID] ?? -1)) > 0.001 else { continue }
            state.lastNotifiedConvertProgress[batchID] = avg
            delegate?.wy_formatConversionProgressUpdated?(audioKit: self,
                                                          localUrls: urls,
                                                          progress: avg)
        }
    }
    
    /// 用导出会话转出AAC编码的m4a(系统现成管线，只有m4a一种输出类型，适合aac/m4a两种目标)
    func startExportSessionConvert(batchID: UUID, sourceURL: URL, outputURL: URL) {
        let asset = AVURLAsset(url: sourceURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            handleConvertError(batchID: batchID, sourceURL: sourceURL, error: WYAudioError.conversionFailed)
            return
        }
        
        // AppleM4A预设只认m4a一种输出类型
        guard exportSession.supportedFileTypes.contains(.m4a) else {
            handleConvertError(batchID: batchID, sourceURL: sourceURL, error: WYAudioError.conversionFailed)
            return
        }
        exportSession.outputFileType = .m4a
        exportSession.outputURL = outputURL
        exportSession.shouldOptimizeForNetworkUse = false
        
        // 句柄强持有会话直到完成摘牌(弱持有的话没有任何人给会话保活，导出中途会话可能被释放掉，任务就永远不会有结果)
        let handle = WYConvertTaskHandle {
            exportSession.cancelExport()
        } readProgress: {
            exportSession.progress
        }
        state.convertTasks[sourceURL] = handle
        state.convertProgresses[sourceURL] = 0.0
        
        exportSession.exportAsynchronously { [weak self, weak exportSession] in
            guard let self = self else { return }
            // 在闭包内部先提取 exportSession 的状态和错误（值类型）
            let status = exportSession?.status ?? .failed
            let error = exportSession?.error
            let finalOutputURL = exportSession?.outputURL ?? outputURL
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch status {
                case .completed:
                    self.finishConvertFile(batchID: batchID, sourceURL: sourceURL, outputURL: finalOutputURL)
                    
                case .failed, .cancelled:
                    self.handleConvertError(batchID: batchID, sourceURL: sourceURL, error: error ?? WYAudioError.conversionFailed)
                    
                default:
                    break
                }
            }
        }
    }
    
    /**
     用读写器把音频解码成线性PCM再封装成wav/aiff/caf
     
     导出会话给不了PCM输出，旧版对这三种目标用直通预设，源文件是压缩编码时基本全部失败，这条路才能真正转成功；管线整体在后台线程跑，主线程只收结果
     */
    func startPCMConvert(batchID: UUID, sourceURL: URL, outputURL: URL, fileType: AVFileType) {
        let box = WYConvertProgressBox()
        let handle = WYConvertTaskHandle(cancel: { box.isCancelled = true }, readProgress: { box.value })
        state.convertTasks[sourceURL] = handle
        state.convertProgresses[sourceURL] = 0.0
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            let asset = AVURLAsset(url: sourceURL)
            
            func fail(_ error: Error) {
                Task { @MainActor [weak self] in
                    self?.handleConvertError(batchID: batchID, sourceURL: sourceURL, error: error)
                }
            }
            
            // 取音频轨(异步load是iOS15起的写法，旧系统退回同步属性)
            let audioTrack: AVAssetTrack?
            if #available(iOS 15.0, *) {
                audioTrack = (try? await asset.loadTracks(withMediaType: .audio))?.first
            } else {
                audioTrack = asset.tracks(withMediaType: .audio).first
            }
            guard let track = audioTrack else {
                fail(WYAudioError.conversionFailed)
                return
            }
            
            // 读出来的统一按容器合规格式解码成线性PCM(AVAssetWriter对PCM写入有三条铁律，违反任何一条都抛ObjC异常、Swift接不住直接闪退:PCM输出键必须给全、AIFF容器强制大端、WAV容器不吃浮点PCM，压缩源默认解码出的Float32进WAV必炸，所以这里统一按Int16整型解码，端序按容器定，采样率/声道跟源)
            guard let reader = try? AVAssetReader(asset: asset) else {
                fail(WYAudioError.conversionFailed)
                return
            }
            let readerSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: fileType == .aiff,
                AVLinearPCMIsNonInterleaved: false,
            ]
            let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: readerSettings)
            reader.add(readerOutput)
            guard reader.startReading() else {
                fail(reader.error ?? WYAudioError.conversionFailed)
                return
            }
            
            // 总时长用来算进度(按已写样本的时长占比算，不依赖具体编码)
            let totalDuration: Double
            if #available(iOS 16.0, *) {
                totalDuration = (try? await track.load(.timeRange).duration.seconds) ?? 0
            } else {
                totalDuration = track.timeRange.duration.seconds
            }
            
            /**
             先拉首个样本拿到实际PCM格式(采样率/声道/位深/交错)再建写入器，写入器端PCM键必须给全(位深/浮点/端序/交错)，缺键时AVAssetWriterInput直接抛ObjC异常闪退；reader侧已按Int16+容器端序解码，这里推导出的设置天然与容器相容
             */
            guard let firstBuffer = readerOutput.copyNextSampleBuffer() else {
                reader.cancelReading()
                fail(WYAudioError.conversionFailed)
                return
            }
            guard let formatDesc = CMSampleBufferGetFormatDescription(firstBuffer),
                  let asbdPtr = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) else {
                fail(WYAudioError.conversionFailed)
                return
            }
            let asbd = asbdPtr.pointee
            let writerSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: asbd.mSampleRate,
                AVNumberOfChannelsKey: Int(asbd.mChannelsPerFrame),
                AVLinearPCMBitDepthKey: Int(asbd.mBitsPerChannel),
                AVLinearPCMIsFloatKey: asbd.mFormatFlags & kAudioFormatFlagIsFloat != 0,
                AVLinearPCMIsBigEndianKey: fileType == .aiff,
                AVLinearPCMIsNonInterleaved: asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved != 0,
            ]
            
            guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: fileType) else {
                fail(WYAudioError.conversionFailed)
                return
            }
            let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: writerSettings)
            writer.add(writerInput)
            guard writer.startWriting() else {
                fail(writer.error ?? WYAudioError.conversionFailed)
                return
            }
            writer.startSession(atSourceTime: .zero)
            
            let workQueue = DispatchQueue(label: "com.wybasiskit.audioconvert.pcm")
            box.appendedSeconds = firstBuffer.duration.seconds
            if totalDuration > 0 {
                box.value = Float(min(1, box.appendedSeconds / totalDuration))
            }

            // 非Sendable系统对象的传递盒(下方@Sendable闭包直接捕获它们会报并发警告，对象实际只在专用串行队列上使用，安全由管线保证)
            let sendableWriter = WYUnsafeSendableBox(writer)
            let sendableWriterInput = WYUnsafeSendableBox(writerInput)
            let sendableReader = WYUnsafeSendableBox(reader)
            let sendableReaderOutput = WYUnsafeSendableBox(readerOutput)

            // 收尾落盘并把结果切回主线程报告(正常读完和写入失败两条路共用)
            func finishWritingAndReport() {
                writerInput.markAsFinished()
                writer.finishWriting {
                    // finishWriting的completion也是@Sendable闭包，writer同样经盒子取
                    let writer = sendableWriter.value
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        if writer.status == .completed {
                            box.value = 1
                            self.finishConvertFile(batchID: batchID, sourceURL: sourceURL, outputURL: outputURL)
                        } else {
                            self.handleConvertError(batchID: batchID, sourceURL: sourceURL, error: writer.error ?? WYAudioError.conversionFailed)
                        }
                    }
                }
            }

            // 首样本写失败(比如磁盘满)直接收尾报错
            if !writerInput.append(firstBuffer) {
                finishWritingAndReport()
                return
            }

            writerInput.requestMediaDataWhenReady(on: workQueue) {
                // 解包出本队列专用对象(整个管线只在workQueue上操作它们)
                let writer = sendableWriter.value
                let writerInput = sendableWriterInput.value
                let reader = sendableReader.value
                let readerOutput = sendableReaderOutput.value

                // 收尾落盘并把结果切回主线程报告(正常读完和写入失败两条路共用)
                func finishWritingAndReport() {
                    writerInput.markAsFinished()
                    writer.finishWriting {
                        // finishWriting的completion也是@Sendable闭包，writer同样经盒子取
                        let writer = sendableWriter.value
                        Task { @MainActor [weak self] in
                            guard let self = self else { return }
                            if writer.status == .completed {
                                box.value = 1
                                self.finishConvertFile(batchID: batchID, sourceURL: sourceURL, outputURL: outputURL)
                            } else {
                                self.handleConvertError(batchID: batchID, sourceURL: sourceURL, error: writer.error ?? WYAudioError.conversionFailed)
                            }
                        }
                    }
                }

                while writerInput.isReadyForMoreMediaData {
                    // 每轮都查一次取消标记，点了停止就立刻收工(批次失败由stopAudioFormatConvert同步报，这里不用再报)
                    if box.isCancelled {
                        reader.cancelReading()
                        writerInput.markAsFinished()
                        writer.cancelWriting()
                        return
                    }
                    if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                        box.appendedSeconds += sampleBuffer.duration.seconds
                        if totalDuration > 0 {
                            box.value = Float(min(1, box.appendedSeconds / totalDuration))
                        }
                        // 写入失败(比如磁盘满)就提前收尾，让finishWriting的状态检查去报错，别把整个源文件空读完
                        if !writerInput.append(sampleBuffer) {
                            finishWritingAndReport()
                            return
                        }
                    } else {
                        // 源文件读完，收尾落盘
                        finishWritingAndReport()
                        return
                    }
                }
            }
        }
    }
}

/// PCM管线的进度盒子(读写器在后台线程跑，进度值和取消标记放盒子里让主线程句柄读写，Float/Bool/Double单值读写本身原子，进度慢半拍无所谓)
final class WYConvertProgressBox: @unchecked Sendable {

    /// 当前进度(0~1)
    var value: Float = 0

    /// 是否已请求取消
    var isCancelled = false

    /// 已写入样本的累计时长(秒)，算进度用
    var appendedSeconds: Double = 0
}

/// 非Sendable对象的跨闭包传递盒(requestMediaDataWhenReady的闭包是@Sendable的，直接捕获AVAssetReader等系统对象会报并发警告；PCM管线把它们装进盒子传递，对象只在专用串行队列上使用，安全由管线自身保证)
final class WYUnsafeSendableBox<T>: @unchecked Sendable {

    /// 被包装传递的对象
    let value: T

    /// 唯一初始化方法
    init(_ value: T) {
        self.value = value
    }
}
