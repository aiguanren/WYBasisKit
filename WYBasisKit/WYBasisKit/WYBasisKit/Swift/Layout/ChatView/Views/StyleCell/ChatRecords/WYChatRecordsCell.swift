//
//  WYChatRecordsCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/20.
//

import UIKit

/// 消息内容Cell
open class WYChatRecordsCell: WYChatBasicCell {
    override var wy_transferProgressPresentation: WYChatTransferProgressPresentation { .attachment }

    open override func renderContent() { wy_recordsRender() }
}
