//
//  WYMediaCacheResourceLoader.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVFoundation
import Foundation

/// 播放器数据请求的转发层(挂在 AVURLAsset 的 resourceLoader 上，把自定义协议头地址的数据请求转给对应缓存条目)
final class WYMediaCacheResourceLoader: NSObject, AVAssetResourceLoaderDelegate {

    /// 供数据的缓存管理器
    weak var cache: WYMediaCache?

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let cache = cache, let url = loadingRequest.request.url, let originalURL = cache.originalURL(fromCacheURL: url) else { return false }
        cache.queue.async { [weak cache] in
            cache?.addItem(loadingRequest, for: originalURL)
        }
        return true
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        guard let cache = cache, let url = loadingRequest.request.url, let originalURL = cache.originalURL(fromCacheURL: url) else { return }
        cache.queue.async { [weak cache] in
            cache?.cancelItemRequest(loadingRequest, for: originalURL)
        }
    }
}
