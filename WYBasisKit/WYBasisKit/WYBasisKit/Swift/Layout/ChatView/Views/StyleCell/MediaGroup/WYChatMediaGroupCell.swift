//
//  WYChatMediaGroupCell.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 合并图片和视频消息
open class WYChatMediaGroupCell: WYChatBasicCell {
    let mediaGroupState = WYChatMediaGroupCellPrivateState()

    override var wy_mediaContentView: UIView { mediaGroupState.mediaView }
    override var wy_defaultContentConfiguration: WYChatContentConfig {
        var content = configuration.content
        content.showsBubble = configuration.media.showsBubble
        content.insets = configuration.media.contentInsets
        return content
    }
    override var wy_transferProgressPresentation: WYChatTransferProgressPresentation { .preview }

    override func wy_setupContent() { wy_mediaGroupSetup() }

    override func wy_resetContent() { wy_mediaGroupReset() }

    override func wy_layoutContent(width: CGFloat) { wy_mediaGroupLayout(width: width) }

    override func wy_measureContent(_ view: UIView, width: CGFloat) -> CGSize? { wy_mediaGroupMeasure(view, width: width) }

    override func wy_updatesItemTransferProgress(visible: Bool) -> Bool { wy_mediaGroupUpdateItemTransferProgress(visible: visible) }

    override func wy_updateAttachmentProgress(_ message: WYChatMessageModel) {
        guard self.message.messageID == message.messageID else { return }
        if let group = message.content.mediaGroup { mediaGroupState.mediaView.updateTransferItems(group.items) }
        super.wy_updateAttachmentProgress(message)
    }

    override func wy_transferPreviewGeometry() -> (frame: CGRect, cornerRadius: CGFloat) {
        guard let group = message.content.mediaGroup else { return super.wy_transferPreviewGeometry() }
        var frame = mediaGroupState.mediaView.convert(mediaGroupState.mediaView.bounds, to: bubblesView)
        if group.isExpanded { frame.size.height = min(frame.height, mediaGroupState.mediaView.firstItemCenterY * 2) }
        return (frame, wy_chatNonnegative(configuration.media.cornerRadius))
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        wy_layoutMediaToggle()
    }

    public override func prepareForReuse() {
        mediaGroupState.mediaView.reset()
        super.prepareForReuse()
    }

    open override func renderContent() { wy_mediaGroupRender() }
}
