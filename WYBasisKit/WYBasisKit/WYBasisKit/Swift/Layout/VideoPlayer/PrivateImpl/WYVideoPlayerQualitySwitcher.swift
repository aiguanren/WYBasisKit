//
//  WYVideoPlayerQualitySwitcher.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVFoundation
import Foundation

/// 清晰度切换器(判档与重载决策，只被播放器内部使用)
final class WYVideoPlayerQualitySwitcher: NSObject {

    /**
     *  判断切档是否需要按本档地址重载
     *
     *  @param asset    播放素材
     *  @param index    目标档下标
     *
     *  @return true 表示需要重载(下标合法且目标档不是 HLS master)，目标档是 HLS master 时交给系统自适应不重载
     *
     */
    func needsReload(asset: WYVideoPlayerMediaAsset, to index: Int) -> Bool {
        guard asset.qualities.indices.contains(index), index != asset.selectedIndex else { return false }
        return asset.qualities[index].isHLSMaster == false
    }
}
