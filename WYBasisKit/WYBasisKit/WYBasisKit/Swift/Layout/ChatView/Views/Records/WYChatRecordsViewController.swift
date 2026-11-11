//
//  WYChatRecordsViewController.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 合并聊天记录明细
public class WYChatRecordsViewController: UIViewController {
    /// 消息列表，沿用聊天界面的展示与媒体预览
    public let chatView: WYChatView
    /// 明细中的原始记录
    public var records: WYChatRecordsModel { didSet { if isViewLoaded { wy_renderRecords() } } }
    /// 明细外观与消息配置
    public var configuration: WYChatConfig { didSet { if isViewLoaded { wy_renderRecords() } } }
    /// 关闭明细按钮
    public let closeButton = UIBarButtonItem()

    /**
     创建合并聊天记录明细
     @param records 原始记录
     @param userInfo 当前用户
     @param configuration 界面配置
     */
    public init(records: WYChatRecordsModel, userInfo: WYChatUserModel = WYChatUserModel(), configuration: WYChatConfig = WYChatConfig()) {
        self.records = records
        self.configuration = configuration
        self.chatView = WYChatView(userInfo: userInfo, configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }
    public required init?(coder: NSCoder) { records = WYChatRecordsModel(); configuration = WYChatConfig(); chatView = WYChatView(); super.init(coder: coder) }
    public override func viewDidLoad() { super.viewDidLoad(); wy_setupRecords() }
    deinit { chatView.releaseAll() }
}
