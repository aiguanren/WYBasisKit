//
//  WYChatVoiceCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/20.
//

import UIKit

/// 消息内容Cell
open class WYChatVoiceCell: WYChatBasicCell {
    let voiceState = WYChatVoiceCellPrivateState()

    override func wy_setupContent() { wy_setupVoicePlayback() }

    override func wy_resetContent() { wy_voiceReset() }

    override func wy_layoutContent(width: CGFloat) { wy_layoutVoicePlayback(width: width) }

    override func wy_measureContent(_ view: UIView, width: CGFloat) -> CGSize? { wy_voiceMeasure(view, width: width) }

    open override func renderContent() { wy_voiceRender() }
}
