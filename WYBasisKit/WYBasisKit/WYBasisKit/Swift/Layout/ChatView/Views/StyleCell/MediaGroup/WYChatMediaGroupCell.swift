//
//  WYChatMediaGroupCell.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 合并图片和视频消息
open class WYChatMediaGroupCell: WYChatBasicCell {
    open override func renderContent() { wy_renderMediaGroup() }
}
