//
//  WYChatVideoCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/20.
//

import UIKit

/// 消息内容Cell
open class WYChatVideoCell: WYChatBasicCell {
    let videoState = WYChatVideoCellPrivateState()

    override func wy_resetContent() { videoState.videoOverlay?.isHidden = true }

    override var wy_transferProgressPresentation: WYChatTransferProgressPresentation { .preview }

    open override func renderContent() { wy_videoRender() }
}

/// 媒体消息内容
