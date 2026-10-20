//
//  WYVideoPlayerSnapshotTaker.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVFoundation
import CoreVideo
import UIKit

/// 播放器截图器(经 AVPlayerItemVideoOutput 取当前帧，只被播放器内部使用)
final class WYVideoPlayerSnapshotTaker: NSObject {

    /// 取画面对象
    private var videoOutput: AVPlayerItemVideoOutput?

    /// 是否已挂到当前条目
    private var isAttached = false

    /// 把取画面对象挂到条目上(装载完成后调)
    func attach(to item: AVPlayerItem) {
        detach()
        let attributes: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
        item.add(output)
        videoOutput = output
        isAttached = true
    }

    /// 与条目解绑
    func detach() {
        videoOutput = nil
        isAttached = false
    }

    /**
     *  截当前画面
     *
     *  @param playerItem  当前播放条目
     *  @param time        截取的时间点(一般传当前播放位置)
     *  @param completion  截图回调(主线程)，取不到画面时回调 nil
     *
     */
    func takeSnapshot(from playerItem: AVPlayerItem, at time: CMTime, completion: @escaping (UIImage?) -> Void) {
        guard isAttached, let output = videoOutput else {
            completion(nil)
            return
        }
        // 直接按时间点同步拷帧，画面层还没渲染出帧时拷不到返回 nil
        let pixelBuffer = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil)
        let image = pixelBuffer.flatMap { image(from: $0) }
        DispatchQueue.main.async {
            completion(image)
        }
    }

    /// 像素缓冲转图片
    private func image(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let coreImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(coreImage, from: coreImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
