//
//  WYTestChatDataSource.swift
//  WYBasisKitTest
//
//  Created by 官人 on 2023/6/21.
//

import UIKit

extension WYTestChatController {
    func sampleMessages() -> [WYChatMessageModel] {
        let assets = WYChatAssetsModel(name: "photo.fill")
        let user = WYChatUserModel(id: "sample", name: "示例联系人")
        let mediaItems = (0..<4).map { index -> WYChatMediaItem in
            var item = WYChatMediaItem()
            item.id = "sample-media-\(index)"
            item.original = assets
            item.thumbnail = assets
            item.size = CGSize(width: 800, height: 600)
            return item
        }
        let contents: [WYChatMessageContentModel] = [
            WYChatMessageContentModel(text: "你好，这是一条文本消息。"),
            WYChatMessageContentModel(text: "这是一条较长的消息，用于展示文本换行、表情[彩虹]、电话号码13800138000以及链接https://www.apple.com。"),
            WYChatMessageContentModel(voice: WYChatVoiceModel(duration: 12, voiceToText: "语音识别结果可以在这里展示")),
            WYChatMessageContentModel(photo: WYChatPhotoModel(original: assets, thumbnail: assets)),
            WYChatMessageContentModel(music: WYChatMusicModel(name: "示例音乐", singer: "演唱者", duration: 180, cover: assets, thumbnailCover: assets)),
            WYChatMessageContentModel(video: WYChatVideoModel(cover: assets, thumbnailCover: assets, duration: 25)),
            WYChatMessageContentModel(luckyMoney: WYChatLuckyMoneyModel(amounts: "20.00", remarks: "祝你开心", notes: "红包")),
            WYChatMessageContentModel(transfer: WYChatLuckyMoneyModel(amounts: "100.00", state: .received, remarks: "示例转账")),
            WYChatMessageContentModel(location: WYChatLocationModel(cover: assets, title: "示例位置", address: "示例地址")),
            WYChatMessageContentModel(takePat: WYChatTakePatModel(striking: user, beaten: user, notes: "的肩膀")),
            WYChatMessageContentModel(withdrawn: WYChatWithdrawnModel()),
            WYChatMessageContentModel(call: WYChatCallModel(durationOfCall: 75)),
            WYChatMessageContentModel(webpage: WYChatWebpageModel(cover: assets, title: "示例链接", remarks: "链接摘要", name: "网页", path: "https://www.apple.com")),
            WYChatMessageContentModel(file: WYChatFileModel(title: "示例文档.pdf", icon: WYChatAssetsModel(name: "doc.fill"), size: "128 KB", name: "文档")),
            WYChatMessageContentModel(businessCard: WYChatBusinessCardModel(userInfo: user, remarks: "个人名片")),
            WYChatMessageContentModel(chatRecords: WYChatRecordsModel(title: "聊天记录", messages: [WYChatMessageModel(sender: user, content: WYChatMessageContentModel(text: "一条聊天记录摘要"))], remarks: "聊天记录合集")),
            WYChatMessageContentModel(mediaGroup: WYChatMediaGroupModel(items: mediaItems)),
            WYChatMessageContentModel()
        ]
        return contents.enumerated().flatMap { index, content in
            [false, true].map { sender in
                var message = WYChatMessageModel(messageID: UUID().uuidString, timestamp: String(Date().timeIntervalSince1970 - Double((contents.count - index) * 60)), sender: sender ? chatView.userInfo : user, content: content)
                message.sendState = index == 1 && sender ? .failed : .success
                message.timeFormat = index == 0 ? "聊天消息示例" : ""
                return message
            }
        }
    }
}
