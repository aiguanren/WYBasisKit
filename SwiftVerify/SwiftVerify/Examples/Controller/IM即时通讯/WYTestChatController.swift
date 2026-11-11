//
//  WYTestChatController.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/3/30.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit

class WYTestChatController: UIViewController {
    
    var chatView: WYChatView!
    private var chatTests: WYChatTestSuite?
    private var scrollProbe: WYChatScrollProbe?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.title = "聊天界面"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "测试", style: .plain, target: self, action: #selector(showChatTests))
        view.backgroundColor = .wy_hex("#f6f6f6")
        
        var configuration = WYChatConfig()
        configuration.emoji.funcAreaConfig.deleteViewText = ""
        
//        configuration.emoji.totalHeaderText = ""
//        configuration.emoji.recentlyHeaderText = ""
//        configuration.emoji.showRecently = false
        
        configuration.more.moreSource = [["照片": "zhaopian"], ["拍摄": "paishe"], ["位置": "weizhi"], ["语音输入": "yuyinshuru"], ["收藏": "shoucang"], ["个人名片": "gerenmingpian"], ["文件": "wenjianjia"], ["音乐": "yinle"]]
        
//        configuration.more.isPagingEnabled = true
//        configuration.more.scrollDirection = .vertical
        if (configuration.more.scrollDirection == .horizontal) && (configuration.more.showTotalItemInPage() == false) {
            configuration.more.contentInset = UIEdgeInsets(top: UIDevice.wy_screenWidth(10), left: UIDevice.wy_screenWidth(20), bottom: UIDevice.wy_screenWidth(40), right: UIDevice.wy_screenWidth(20))
        }
        
        if (configuration.more.scrollDirection == .vertical) && (configuration.more.showTotalItemInPage() == false) {
            configuration.more.contentInset = UIEdgeInsets(top: UIDevice.wy_screenWidth(10), left: UIDevice.wy_screenWidth(20), bottom: UIDevice.wy_screenWidth(20), right: UIDevice.wy_screenWidth(40))
        }
        
        configuration.emoji.emojiFolders = true
        
        configuration.more.imageProvider = { UIImage(systemName: $0) }
        configuration.more.moreSource = [["照片": "photo"], ["拍摄": "camera"], ["位置": "location"], ["文件": "doc"]]
        configuration.imageLoader = { asset, imageView, _ in imageView.image = UIImage(systemName: asset.name.isEmpty ? "person.crop.square" : asset.name) }
        configuration.media.albumMoreItemIndex = 0
        configuration.recording.supportSpeechRecognition = true
        chatView = WYChatView(configuration: configuration)
        chatView.userInfo = sharedUserInfo(id: "99999", name: "官人", avatar: "https://tse3-mm.cn.bing.net/th/id/OIP-C.sLiEXoTdJvx0fe3erN8NeAAAAA?pid=ImgDet&rs=1")
        chatView.dataSource = sampleMessages()
        chatView.openAlbumHandler = { [weak self] in
            let alert = UIAlertController(title: "相册由宿主接入", message: "使用第三方选择器后，将照片或视频文件通过sendMedia交回。测试页提供逐条和合并展示检查。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "关闭", style: .cancel))
            self?.present(alert, animated: true)
        }
        chatView.eventsHandler = self
        chatView.delegate = self
        view.addSubview(chatView)
        chatView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if scrollProbe == nil { scrollProbe = WYChatScrollProbe(table: chatView.tableView) }
        if chatTests == nil { chatTests = WYChatTestSuite(chatView: chatView, scrollProbe: scrollProbe) }
    }

    @objc private func showChatTests() {
        if chatTests == nil { chatTests = WYChatTestSuite(chatView: chatView, scrollProbe: scrollProbe) }
        guard let chatTests else { return }
        let panel = WYChatTestPanelController(suite: chatTests)
        present(UINavigationController(rootViewController: panel), animated: true)
    }

    /*

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension WYTestChatController: WYChatViewDelegate {
    
    /// APP变的活跃了
    func wy_applicationDidBecomeActive(_ application: UIApplication) {
        //wy_print("applicationDidBecomeActive")
    }
    
    /// 键盘将要弹出
    func wy_keyboardWillShow(_ notification: Notification) {
        //wy_print("键盘将要弹出")
    }
    
    /// 键盘将要消失
    func wy_keyboardWillDismiss() {
        //wy_print("键盘将要消失")
    }
    
    /// tableView的滚动事件
    func wy_scrollViewDidScroll(_ scrollView: UIScrollView) {
        //wy_print("tableView的滚动事件")
    }
    
    /// 点击了 文本/语音 切换按钮
    func wy_didClickTextVoiceView(isText: Bool) {
        if isText {
            //wy_print("显示键盘")
        }else {
            //wy_print("显示语音")
        }
    }
    
    /// 点击了 表情/文本 切换按钮
    func wy_didClickEmojiTextView(isText: Bool) {
        if isText {
            //wy_print("显示键盘")
        }else {
            //wy_print("显示表情")
        }
    }
    
    /// 点击了 更多 按钮
    func wy_didClickMoreView(isText: Bool) {
        if isText {
            //wy_print("显示键盘")
        }else {
            //wy_print("显示更多")
        }
    }
    
    /// 输入框文本发生变化
    func wy_textDidChanged(text: String) {
        //wy_print("输入的文本：\(text)")
    }
    
    /// 点击了键盘上的 发送 按钮
    func wy_keyboardSendMessage(messageID: String) {
        //wy_print("发送文本消息ID：\(messageID)")

        Task { [weak self] in
            try? await Task.wy_delay(1, cancelThrows: false) { [weak self] in
                guard let self = self else { return }

                // 模拟1秒后发送成功，struct是值类型，直接改dataSource里对应下标的消息才会反映到UI
                if let index = self.chatView.dataSource.firstIndex(where: { $0.messageID == messageID }) {
                    self.chatView.dataSource[index].sendState = .success
                    self.chatView.dataSource[index].readers = "1"
                }

                var replyMessage: WYChatMessageModel = WYChatMessageModel()
                replyMessage.messageID = UUID().uuidString
                replyMessage.timestamp = String.wy_sharedDeviceTimestamp()
                replyMessage.lastMessageTimestamp = replyMessage.sharedLastMessageTimestamp(self.chatView.dataSource)
                replyMessage.clientTimestamp = String.wy_sharedDeviceTimestamp()
                replyMessage.sender = self.sharedUserInfo(id: "88888", name: "大官人", avatar: "https://img1.baidu.com/it/u=3709586903,1286591012&fm=253&fmt=auto&app=138&f=JPEG")
                replyMessage.content.text = ["这是自动模拟的回复消息😄😄😄😄😄😄", "回复消息", "这是自动模拟的多行回复消息😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄"][Int.wy_random(minimum: 0, maximum: 2)]
                replyMessage.index = self.chatView.dataSource.count
                replyMessage.sendState = .success
                replyMessage.readers = "1"
                self.chatView.dataSource.append(replyMessage)
            }
        }
    }
    
    /// 点击了emoji控件内某个item
    func wy_didClickEmojiView(_ emojiView: WYChatEmojiView, indexPath: IndexPath) {
        //wy_print("emojiView = \(emojiView), emojiName = \(emojiView.dataSource[indexPath.section][indexPath.item])")
    }
    
    /// 点击了emoji控件内功能区删除按钮
    func wy_didClickEmojiDeleteView(_ deleteView: UIButton) {
        //wy_print("点击了emoji控件内功能区删除按钮")
    }
    
    /// 点击了emoji控件内功能区发送按钮
    func wy_didClickEmojiSendView(_ sendView: UIButton) {
        //wy_print("点击了emoji控件内功能区发送按钮")
    }

    /// 点击了More控件内某个item
    func wy_didClickMoreView(_ moreView: WYChatMoreView, itemIndex: Int) {
        //wy_print("点击More控件 \(moreView) 内第 \(itemIndex) 个item")
    }
}

extension WYTestChatController: WYChatViewEventsHandler {
    
    /// 是否需要内部处理 APP变的活跃了 时的事件
    func wy_canManagerApplicationDidBecomeActiveEvents(_ application: UIApplication) -> Bool {
        //wy_print("是否需要内部处理 APP变的活跃了 时的事件， application = \(application)")
        return true
    }
    
    /// 是否需要内部处理 键盘将要弹出 时的事件
    func wy_canManagerKeyboardWillShowEvents(_ notification: Notification) -> Bool {
        //wy_print("是否需要内部处理 键盘将要弹出 时的事件, notification = \(notification)")
        return true
    }

    /// 是否需要内部处理 键盘将要消失 时的事件
    func wy_canManagerKeyboardWillDismissEvents() -> Bool {
        //wy_print("是否需要内部处理 键盘将要消失 时的事件")
        return true
    }

    /// 是否需要内部处理 tableView的滚动事件
    func wy_canManagerScrollViewDidScrollEvents(_ scrollView: UIScrollView) -> Bool {
        //wy_print("是否需要内部处理 tableView的滚动事件, scrollView = \(scrollView)")
        return true
    }
    
    /// 是否需要内部处理chatInput控件内 语音 按钮的长按事件
    func wy_canManagerVoiceRecordEvents(_ longPress: UILongPressGestureRecognizer) -> Bool {
        //wy_print("是否需要内部处理chatInput控件内 语音 按钮的长按事件, longPress = \(longPress)")
        return true
    }

    /// 是否需要内部处理chatInput控件内 文本/语音 按钮的点击事件
    func wy_canManagerTextVoiceViewEvents(_ textVoiceView: UIButton) -> Bool {
        //wy_print("是否需要内部处理chatInput控件内 文本/语音 按钮的点击事件, textVoiceView = \(textVoiceView)")
        return true
    }

    /// 是否需要内部处理chatInput控件内 文本/表情 切换按钮的点击事件
    func wy_canManagerTextEmojiViewEvents(_ textEmojiView: UIButton) -> Bool {
        //wy_print("是否需要内部处理chatInput控件内 文本/表情 切换按钮的点击事件, textEmojiView = \(textEmojiView)")
        return true
    }

    /// 是否需要内部处理chatInput控件内 更多 按钮的点击事件
    func wy_canManagerMoreViewEvents(_ moreView: UIButton) -> Bool {
        //wy_print("是否需要内部处理chatInput控件内 更多 按钮的点击事件, moreView = \(moreView)")
        return true
    }
    
    /// 是否需要内部处理chatInput控件内 键盘发送按钮 的点击事件
    func wy_canManagerKeyboardSendEvents(_ text: String) -> Bool {
        //wy_print("是否需要内部处理chatInput控件内 键盘发送按钮 的点击事件, text = \(text)")
        return true
    }

    /// 是否需要内部处理Emoji控件内 cell 的点击事件
    func wy_canManagerEmojiViewClickEvents(_ emojiView: WYChatEmojiView, indexPath: IndexPath) -> Bool {
        //wy_print("是否需要内部处理Emoji控件内 cell 的点击事件, emojiView = \(emojiView), indexPath = \(indexPath)")
        return true
    }

    /// 是否需要内部处理Emoji控件内 删除按钮 的点击事件
    func wy_canManagerEmojiDeleteViewClickEvents(_ deleteView: UIButton) -> Bool {
        //wy_print("是否需要内部处理Emoji控件内 删除按钮 的点击事件, deleteView = \(deleteView)")
        return true
    }

    /// 是否需要内部处理Emoji控件内 发送按钮 的点击事件
    func wy_canManagerEmojiSendViewClickEvents(_ sendView: UIButton) -> Bool {
        //wy_print("是否需要内部处理Emoji控件内 发送按钮 的点击事件, sendView = \(sendView)")
        return true
    }

    /// 是否需要内部处理More控件内 cell 的点击事件
    func wy_canManagerMoreViewClickEvents(_ moreView: WYChatMoreView, itemIndex: Int) -> Bool {
        //wy_print("是否需要内部处理More控件内 cell 的点击事件, moreView = \(moreView), itemIndex = \(itemIndex)")
        return true
    }
    
    /// 是否需要内部处理tableView代理 cellForRowAt 方法
    func wy_canManagerCellForRowEvents(_ chatView: WYChatView, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell? {
        return nil
    }
}

extension WYTestChatController {
    
    @discardableResult
    func sharedUserInfo(id: String, name: String, avatar: String) -> WYChatUserModel {
        
        var assets: WYChatAssetsModel = WYChatAssetsModel()
        assets.downloadPath = avatar
        
        var userModel: WYChatUserModel = WYChatUserModel()
        userModel.id = id
        userModel.name = name
        userModel.nickname = name
        userModel.remarks = "这里是测试生成的备注信息"
        userModel.signature = "这里是测试生成的用户签名"
        userModel.area = "中国🇨🇳 香港🇭🇰"
        userModel.qrCode = assets
        userModel.avatar = assets
        userModel.thumbnailAvatar = assets
    
        return userModel
    }
}
