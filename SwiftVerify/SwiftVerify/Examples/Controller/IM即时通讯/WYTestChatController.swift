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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .wy_hex("#f6f6f6")
        
        emojiViewConfig.funcAreaConfig.deleteViewText = ""
        
//        emojiViewConfig.totalHeaderText = ""
//        emojiViewConfig.recentlyHeaderText = ""
//        emojiViewConfig.showRecently = false
        
        moreViewConfig.moreSource = [["照片": "zhaopian"], ["拍摄": "paishe"], ["位置": "weizhi"], ["语音输入": "yuyinshuru"], ["收藏": "shoucang"], ["个人名片": "gerenmingpian"], ["文件": "wenjianjia"], ["音乐": "yinle"]]
        
//        moreViewConfig.isPagingEnabled = true
//        moreViewConfig.scrollDirection = .vertical
        if (moreViewConfig.scrollDirection == .horizontal) && (moreViewConfig.showTotalItemInPage() == false) {
            moreViewConfig.contentInset = UIEdgeInsets(top: UIDevice.wy_screenWidth(10), left: UIDevice.wy_screenWidth(20), bottom: UIDevice.wy_screenWidth(40), right: UIDevice.wy_screenWidth(20))
        }
        
        if (moreViewConfig.scrollDirection == .vertical) && (moreViewConfig.showTotalItemInPage() == false) {
            moreViewConfig.contentInset = UIEdgeInsets(top: UIDevice.wy_screenWidth(10), left: UIDevice.wy_screenWidth(20), bottom: UIDevice.wy_screenWidth(20), right: UIDevice.wy_screenWidth(40))
        }
        
        chatView = WYChatView()
        chatView.userInfo = sharedUaerInfo(id: "99999", name: "官人", avatar: "https://tse3-mm.cn.bing.net/th/id/OIP-C.sLiEXoTdJvx0fe3erN8NeAAAAA?pid=ImgDet&rs=1")
        chatView.dataSource = []
        chatView.eventsHandler = self
        chatView.delegate = self
        view.addSubview(chatView)
        chatView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(UIDevice.wy_navViewHeight)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-UIDevice.wy_tabbarSafetyZone)
        }
        
        recordAnimationConfig.supportSpeechRecognition = true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension WYTestChatController: WYChatViewDelegate {
    
    /// APP变的活跃了
    func applicationDidBecomeActive(_ application: UIApplication) {
        //wy_print("applicationDidBecomeActive")
    }
    
    /// 键盘将要弹出
    func keyboardWillShow(_ notification: Notification) {
        //wy_print("键盘将要弹出")
    }
    
    /// 键盘将要消失
    func keyboardWillDismiss() {
        //wy_print("键盘将要消失")
    }
    
    /// tableView的滚动事件
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //wy_print("tableView的滚动事件")
    }
    
    /// 点击了 文本/语音 切换按钮
    func didClickTextVoiceView(_ isText: Bool) {
        if isText {
            //wy_print("显示键盘")
        }else {
            //wy_print("显示语音")
        }
    }
    
    /// 点击了 表情/文本 切换按钮
    func didClickEmojiTextView(_ isText: Bool) {
        if isText {
            //wy_print("显示键盘")
        }else {
            //wy_print("显示表情")
        }
    }
    
    /// 点击了 更多 按钮
    func didClickMoreView(_ isText: Bool) {
        if isText {
            //wy_print("显示键盘")
        }else {
            //wy_print("显示更多")
        }
    }
    
    /// 输入框文本发生变化
    func textDidChanged(_ text: String) {
        //wy_print("输入的文本：\(text)")
    }
    
    /// 点击了键盘上的 发送 按钮
    func keyboardSendMessage(_ message: WYChatMessageModel) {
        //wy_print("发送文本消息：\(message)，时间戳 = \(message.timestamp)")
        
        Task {
            try? await Task.wy_delay(1, cancelThrows: false) { [weak self] in
                guard let self = self else { return }
                
                message.sendState = .success
                message.readers = "1"
                
                let replyMessage: WYChatMessageModel = WYChatMessageModel()
                replyMessage.timestamp = String.wy_sharedDeviceTimestamp()
                replyMessage.lastMessageTimestamp = replyMessage.sharedLastMessageTimestamp(self.chatView.dataSource)
                replyMessage.clientTimestamp = String.wy_sharedDeviceTimestamp()
                replyMessage.sendor = self.sharedUaerInfo(id: "88888", name: "大官人", avatar: "https://img1.baidu.com/it/u=3709586903,1286591012&fm=253&fmt=auto&app=138&f=JPEG")
                replyMessage.content.text = ["这是自动模拟的回复消息😄😄😄😄😄😄", "回复消息", "这是自动模拟的多行回复消息😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄"][Int.wy_random(minimum: 0, maximum: 2)]
                replyMessage.index = message.index + 1
                replyMessage.sendState = .success
                replyMessage.readers = "1"
                self.chatView.dataSource.append(replyMessage)
            }
        }
    }
    
    /// 点击了emoji控件内某个item
    func didClickEmojiView(_ emojiView: WYChatEmojiView, _ indexPath: IndexPath) {
        //wy_print("emojiView = \(emojiView), emojiName = \(emojiView.dataSource[indexPath.section][indexPath.item])")
    }
    
    /// 点击了emoji控件内功能区删除按钮
    func didClickEmojiDeleteView(_ deleteView: UIButton) {
        //wy_print("点击了emoji控件内功能区删除按钮")
    }
    
    /// 点击了emoji控件内功能区发送按钮
    func didClickEmojiSendView(_ sendView: UIButton) {
        //wy_print("点击了emoji控件内功能区发送按钮")
    }
    
    /// 将要显示表情预览控件(仅限WYEmojiPreviewStyle == other时才会回调)
    func willShowPreviewView(_ imageView: UIImageView, _ imageName: String) {
        //wy_print("imageView = \(imageView), imageName = \(imageName)")
    }
    
    /// 点击了More控件内某个item
    func didClickMoreView(_ moreView: WYChatMoreView, _ itemIndex: Int) {
        //wy_print("点击More控件 \(moreView) 内第 \(itemIndex) 个item")
    }
}

extension WYTestChatController: WYChatViewEventsHandler {
    
    /// 是否需要内部处理 APP变的活跃了 时的事件
    func canManagerApplicationDidBecomeActiveEvents(_ application: UIApplication) -> Bool {
        //wy_print("是否需要内部处理 APP变的活跃了 时的事件， application = \(application)")
        return true
    }
    
    /// 是否需要内部处理 键盘将要弹出 时的事件
    func canManagerKeyboardWillShowEvents(_ notification: Notification) -> Bool {
        //wy_print("是否需要内部处理 键盘将要弹出 时的事件, notification = \(notification)")
        return true
    }

    /// 是否需要内部处理 键盘将要消失 时的事件
    func canManagerKeyboardWillDismissEvents() -> Bool {
        //wy_print("是否需要内部处理 键盘将要消失 时的事件")
        return true
    }

    /// 是否需要内部处理 tableView的滚动事件
    func canManagerScrollViewDidScrollEvents(_ scrollView: UIScrollView) -> Bool {
        //wy_print("是否需要内部处理 tableView的滚动事件, scrollView = \(scrollView)")
        return true
    }
    
    /// 是否需要内部处理chatInput控件内 语音 按钮的长按事件
    func canManagerVoiceRecordEvents(_ longPress: UILongPressGestureRecognizer) -> Bool {
        //wy_print("是否需要内部处理chatInput控件内 语音 按钮的长按事件, longPress = \(longPress)")
        return true
    }

    /// 是否需要内部处理chatInput控件内 文本/语音 按钮的点击事件
    func canManagerTextVoiceViewEvents(_ textVoiceView: UIButton) -> Bool {
        //wy_print("是否需要内部处理chatInput控件内 文本/语音 按钮的点击事件, textVoiceView = \(textVoiceView)")
        return true
    }

    /// 是否需要内部处理chatInput控件内 文本/表情 切换按钮的点击事件
    func canManagerTextEmojiViewEvents(_ textEmojiView: UIButton) -> Bool {
        //wy_print("是否需要内部处理chatInput控件内 文本/表情 切换按钮的点击事件, textEmojiView = \(textEmojiView)")
        return true
    }

    /// 是否需要内部处理chatInput控件内 更多 按钮的点击事件
    func canManagerMoreViewEvents(_ moreView: UIButton) -> Bool {
        //wy_print("是否需要内部处理chatInput控件内 更多 按钮的点击事件, moreView = \(moreView)")
        return true
    }
    
    /// 是否需要内部处理chatInput控件内 键盘发送按钮 的点击事件
    func canManagerKeyboardSendEvents(_ text: String) -> Bool {
        //wy_print("是否需要内部处理chatInput控件内 键盘发送按钮 的点击事件, text = \(text)")
        return true
    }

    /// 是否需要内部处理Emoji控件内 cell 的点击事件
    func canManagerEmojiViewClickEvents(_ emojiView: WYChatEmojiView, _ indexPath: IndexPath) -> Bool {
        //wy_print("是否需要内部处理Emoji控件内 cell 的点击事件, emojiView = \(emojiView), indexPath = \(indexPath)")
        return true
    }

    /// 是否需要内部处理Emoji控件内 表情预览控件(仅限WYEmojiPreviewStyle == other时才会回调) 的长按事件
    func canManagerEmojiLongPressEvents(_ gestureRecognizer: UILongPressGestureRecognizer, emoji: String, imageView: UIImageView) -> Bool {
        //wy_print("是否需要内部处理Emoji控件内 表情预览控件(仅限WYEmojiPreviewStyle == other时才会回调) 的长按事件, imageView = \(imageView), emoji = \(emoji), gestureRecognizer.state = \(gestureRecognizer.state)")
        return true
    }

    /// 是否需要内部处理Emoji控件内 删除按钮 的点击事件
    func canManagerEmojiDeleteViewClickEvents(_ deleteView: UIButton) -> Bool {
        //wy_print("是否需要内部处理Emoji控件内 删除按钮 的点击事件, deleteView = \(deleteView)")
        return true
    }

    /// 是否需要内部处理Emoji控件内 发送按钮 的点击事件
    func canManagerEmojiSendViewClickEvents(_ sendView: UIButton) -> Bool {
        //wy_print("是否需要内部处理Emoji控件内 发送按钮 的点击事件, sendView = \(sendView)")
        return true
    }

    /// 是否需要内部处理More控件内 cell 的点击事件
    func canManagerMoreViewClickEvents(_ moreView: WYChatMoreView, _ itemIndex: Int) -> Bool {
        //wy_print("是否需要内部处理More控件内 cell 的点击事件, moreView = \(moreView), itemIndex = \(itemIndex)")
        return true
    }
    
    /// 是否需要内部处理tableView代理 cellForRowAt 方法
    func canManagerCellForRowEvents(_ chatView: WYChatView, _ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell? {
        return nil
    }
}

extension WYTestChatController {
    
    @discardableResult
    func sharedUaerInfo(id: String, name: String, avatar: String) -> WYChatUaerModel {
        
        let assets: WYChatAssetsModel = WYChatAssetsModel()
        assets.downloadPath = avatar
        
        let userModel: WYChatUaerModel = WYChatUaerModel()
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
