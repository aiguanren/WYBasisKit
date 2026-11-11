//
//  WYChatCellObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

public extension WYChatBasicCell {
    /// 媒体组操作，参数为操作、消息ID和媒体下标
    @objc(mediaActionHandler) var mediaActionHandlerObjC: ((_ action: WYChatMediaAction, _ messageID: String, _ index: Int) -> Void)? { get { mediaActionHandler } set { mediaActionHandler = newValue } }
    /// 媒体组展示视图
    @objc(mediaContentView) var mediaContentViewObjC: UIView { mediaContentView }

    /// 当前消息内容配置
    @objc(messageContentConfiguration) var messageContentConfigurationObjC: WYChatContentConfigObjC { WYChatContentConfigObjC(messageContentConfiguration) }
    /// 当前消息是否已选择
    @objc(isMessageSelected) var isMessageSelectedObjC: Bool { get { isMessageSelected } set { isMessageSelected = newValue } }
    /// 已读标识
    @objc(readMarkView) var readMarkViewObjC: UILabel { readMarkView }
    /// 引用内容
    @objc(referenceView) var referenceViewObjC: WYChatQuoteView { referenceView }
    /// 发送失败按钮
    @objc(loadingView) var loadingViewObjC: UIButton { loadingView }
    /// 发送中动画
    @objc(activityView) var activityViewObjC: UIActivityIndicatorView { activityView }
    /// 更新消息与布局配置，参数为消息、配置和当前用户ID
    @objc(update) var updateObjC: @convention(block) (_ message: WYChatMessageModelObjC, _ configuration: WYChatConfigObjC, _ userID: String) -> WYChatBasicCell {
        { [self] message, configuration, userID in self.update(message: message.toValue(), configuration: configuration.toValue(), userID: userID); return self }
    }
    /// 当前界面配置
    @objc(configuration) var configurationObjC: WYChatConfigObjC {
        get { WYChatConfigObjC(configuration) }
        set { configuration = newValue.toValue() }
    }
    /// 当前用户ID
    @objc(userID) var userIDObjC: String { get { userID } set { userID = newValue } }
    /// 当前消息
    @objc(message) var messageObjC: WYChatMessageModelObjC {
        get { WYChatMessageModelObjC(message) }
        set { message = newValue.toValue() }
    }
    /// 气泡控件
    @objc(bubblesView) var bubblesViewObjC: WYAirBubbleView { bubblesView }
    /// 消息内容容器
    @objc(bodyView) var bodyViewObjC: UIStackView { bodyView }
    /// 头像控件
    @objc(avatarView) var avatarViewObjC: UIImageView { avatarView }
    /// 昵称控件
    @objc(nicknameView) var nicknameViewObjC: UILabel { nicknameView }
    /// 时间控件
    @objc(timeView) var timeViewObjC: UILabel { timeView }
    /// 卡片标题控件
    @objc(titleView) var titleViewObjC: UILabel { titleView }
    /// 卡片摘要控件
    @objc(detailView) var detailViewObjC: UILabel { detailView }
    /// 卡片底部说明控件
    @objc(footerView) var footerViewObjC: UILabel { footerView }
    /// 媒体预览控件
    @objc(previewImageView) var previewImageViewObjC: UIImageView { previewImageView }
    /// 卡片缩略图控件
    @objc(thumbnailImageView) var thumbnailImageViewObjC: UIImageView { thumbnailImageView }
    /// 消息操作，参数为操作及消息ID
    @objc(actionHandler) var actionHandlerObjC: ((_ action: WYChatAction, _ messageID: String) -> Void)? { get { actionHandler } set { actionHandler = newValue } }
}

public extension WYChatTextCell {
    /// 文本控件
    @objc(textView) var textViewObjC: UITextView { textView }
}

#endif
