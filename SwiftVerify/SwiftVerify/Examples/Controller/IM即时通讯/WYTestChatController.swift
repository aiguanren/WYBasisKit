//
//  WYTestChatController.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/3/30.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
import Kingfisher
import AVFoundation
import Photos
import PhotosUI
import QuickLook
import UniformTypeIdentifiers

class WYTestChatController: UIViewController {
    private let detectionSampleID = "text-detection-example"
    
    var chatView: WYChatView!
    private var chatTests: WYChatTestSuite?
    private var scrollProbe: WYChatScrollProbe?
    private var voicePlayer: AVAudioPlayer?
    private var playingVoiceID: String?
    private let attachmentDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    private var importedFiles: [String: URL] = [:]
    private var previewFileURL: URL?
    private var isImportingPhotos = false
    private var exampleTransferTasks: [String: UUID] = [:]
    private var exampleConfirmationTitle: String?

    deinit {
        try? FileManager.default.removeItem(at: attachmentDirectory)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.title = "聊天界面"
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "测试", style: .plain, target: self, action: #selector(showChatTests)),
            UIBarButtonItem(title: "文本识别", style: .plain, target: self, action: #selector(showTextDetection))
        ]
        view.backgroundColor = .wy_hex("#f6f6f6")
        
        var configuration = WYChatConfig()
        configuration.emoji.funcAreaConfig.deleteViewText = ""
        
//        configuration.emoji.totalHeaderText = ""
//        configuration.emoji.recentlyHeaderText = ""
//        configuration.emoji.showRecently = false
        
        configuration.more.moreSource = [
            ["照片": UIImage.wy_find("zhaopian")],
            ["拍摄": UIImage.wy_find("paishe")],
            ["位置": UIImage.wy_find("weizhi")],
            ["文件": UIImage.wy_find("wenjianjia")],
            ["收藏": UIImage.wy_find("shoucang")],
            ["个人名片": UIImage.wy_find("gerenmingpian")],
            ["音乐": UIImage.wy_find("yinle")],
            ["发红包": UIImage(systemName: "gift") ?? UIImage()],
            ["转账": UIImage(systemName: "arrow.left.arrow.right") ?? UIImage()]
        ]
        
//        configuration.more.isPagingEnabled = true
//        configuration.more.scrollDirection = .vertical
        if (configuration.more.scrollDirection == .horizontal) && (configuration.more.showTotalItemInPage() == false) {
            configuration.more.contentInset = UIEdgeInsets(top: UIDevice.wy_screenWidth(10), left: UIDevice.wy_screenWidth(20), bottom: UIDevice.wy_screenWidth(40), right: UIDevice.wy_screenWidth(20))
        }
        
        if (configuration.more.scrollDirection == .vertical) && (configuration.more.showTotalItemInPage() == false) {
            configuration.more.contentInset = UIEdgeInsets(top: UIDevice.wy_screenWidth(10), left: UIDevice.wy_screenWidth(20), bottom: UIDevice.wy_screenWidth(20), right: UIDevice.wy_screenWidth(40))
        }
        
        configuration.emoji.emojiFolders = true
        
        configuration.imageLoader = { asset, imageView, _ in
            let name = asset.name == "doc" ? "WYChatViewFile" : asset.name
            if !name.isEmpty {
                let image = UIImage(named: name) ?? UIImage(systemName: name) ?? UIImage.wy_find(name, inBundle: WYChatSourceBundle)
                if image.size != .zero { imageView.image = image; return }
            }
            if let url = URL(string: asset.downloadPath), ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                imageView.kf.setImage(with: url, placeholder: imageView.image)
            }
        }
        configuration.media.albumMoreItemIndex = 0
        configuration.media.albumAllowsVideos = true
        configuration.selection.usesForwardActionSheet = true
        configuration.selection.automaticallyDeletesMessages = true
        configuration.selection.automaticallyFavoritesMessages = true
        configuration.recording.supportSpeechRecognition = true
        chatView = WYChatView(configuration: configuration)
        chatView.userInfo = sharedUserInfo(id: "99999", name: "官人", avatar: "https://tse3-mm.cn.bing.net/th/id/OIP-C.sLiEXoTdJvx0fe3erN8NeAAAAA?pid=ImgDet&rs=1")
        //chatView.dataSource = sampleMessages()
        chatView.openAlbumHandler = { [weak self] in self?.openExampleAlbum() }
        chatView.preparedForwardHandler = { [weak self] _, messages in self?.deliverExampleForward(messages) }
        chatView.sendConfirmationHandler = { [weak self] _, completion in
            guard let self else { completion(false); return }
            self.presentExampleConfirmation(completion)
        }
        chatView.messageDetailHandler = { [weak self] message in self?.presentExampleFundsDetail(message) ?? false }
        chatView.mediaTransferActionHandler = { [weak self] action, messageID, itemID in
            guard let self else { return }
            if action == .pauseTransfer {
                self.exampleTransferTasks.removeValue(forKey: messageID + "/" + itemID)
                self.chatView.updateMediaTransfer(messageID: messageID, itemID: itemID, state: .paused)
            } else {
                self.startExampleMediaTransfer(messageID, itemID: itemID)
            }
        }
        chatView.messagePreparedHandler = { [weak self] message in self?.prepareExampleMessage(message) }
        chatView.voicePlaybackRateHandler = { [weak self] messageID, rate in
            guard let self, self.playingVoiceID == messageID else { return }
            self.voicePlayer?.rate = rate
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

    private func prepareExampleMessage(_ message: WYChatMessageModel) {
        guard message.content.text == nil else { return }
        if let group = message.content.mediaGroup {
            for item in group.items where item.transferState != .completed { startExampleMediaTransfer(message.messageID, itemID: item.id) }
            return
        }
        switch message.content.style() {
        case .mediaGroup, .photo, .video, .file, .location, .businessCard, .music, .webpage:
            startExampleTransfer(message.messageID)
            return
        default: break
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self, let index = self.chatView.dataSource.firstIndex(where: { $0.messageID == message.messageID }) else { return }
            self.chatView.dataSource[index].sendState = .success
        }
    }

    private func playExampleVoice(_ messageID: String) {
        guard let voice = chatView.messageModelFrom(messageID)?.content.voice else { return }
        do {
            if playingVoiceID != messageID || voicePlayer == nil {
                stopExampleVoice()
                let paths = [voice.localPath, voice.aacPath, voice.wavPath, voice.cafPath, voice.mp3Path, voice.amrPath]
                guard let path = paths.first(where: { !$0.isEmpty && FileManager.default.fileExists(atPath: $0) }) else {
                    throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "没有找到这条语音的本地音频文件"])
                }
                voicePlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                voicePlayer?.delegate = self
                voicePlayer?.enableRate = true
                playingVoiceID = messageID
            }
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            voicePlayer?.rate = voice.playbackRate
            if chatView.configuration.voicePlayback.restartsOnTap { voicePlayer?.currentTime = 0 }
            guard voicePlayer?.play() == true else { throw NSError(domain: NSOSStatusErrorDomain, code: -50) }
            updateExampleVoice(messageID, playing: true)
        } catch { stopExampleVoice(); updateExampleVoice(messageID, playing: false); showVoiceError(error as NSError) }
    }

    private func updateExampleVoice(_ messageID: String, playing: Bool) {
        guard let index = chatView.dataSource.firstIndex(where: { $0.messageID == messageID }),
              var voice = chatView.dataSource[index].content.voice else { return }
        voice.isPlaying = playing
        voice.played = true
        voice.pause = !playing && !chatView.configuration.voicePlayback.restartsOnTap
        voice.currentPlayDuration = voicePlayer?.currentTime ?? 0
        if voice != chatView.dataSource[index].content.voice { chatView.dataSource[index].content.voice = voice }
    }

    private func stopExampleVoice() {
        voicePlayer?.stop()
        voicePlayer?.currentTime = 0
        if let playingVoiceID { updateExampleVoice(playingVoiceID, playing: false) }
        voicePlayer = nil
        playingVoiceID = nil
    }

    private func showVoiceError(_ error: NSError) {
        WYActivity.showInfo("\(error.localizedDescription)\n\(error.domain) (\(error.code))", in: view.window)
    }

    @objc private func showTextDetection(_ sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: "文本识别", message: nil, preferredStyle: .actionSheet)
        let choices: [(String, [WYChatTextDetectionType]?)] = [
            ("关闭识别", []), ("仅识别邮箱", [.email]),
            ("识别电话、邮箱和网址", [.phoneNumber, .email, .link]), ("使用系统识别", nil)
        ]
        for (title, types) in choices {
            sheet.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in self?.applyTextDetection(types) })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = sender
        present(sheet, animated: true)
    }

    private func applyTextDetection(_ types: [WYChatTextDetectionType]?) {
        var config = chatView.configuration
        config.text.detectedTextTypes = types
        config.text.detectedTextStyle = WYChatTextDetectionStyle(color: .systemPurple)
        config.text.detectedTextStyles = [
            .phoneNumber: WYChatTextDetectionStyle(color: .systemOrange, isUnderlined: false),
            .email: WYChatTextDetectionStyle(color: .systemTeal, isUnderlined: false)
        ]
        config.text.detectedTextTapHandler = { [weak self] type, text, message in
            let title: String
            switch type {
            case .phoneNumber: title = "电话"
            case .email: title = "邮箱"
            case .link: title = "网址"
            }
            let alert = UIAlertController(title: title, message: "\(text)\n\(message.messageID)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .cancel))
            self?.present(alert, animated: true)
        }
        chatView.configuration = config
        if chatView.messageModelFrom(detectionSampleID) == nil {
            let sample = WYChatMessageModel(sendState: .success, messageID: detectionSampleID,
                                            timestamp: String(Date().timeIntervalSince1970), sender: chatView.userInfo,
                                            content: WYChatMessageContentModel(text: "+1 (415) 555-0132\nhello@example.com\nhttps://example.org"))
            chatView.appendMessages([sample])
        }
        chatView.scrollToLastMessage()
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

    func wy_messageAction(_ chatView: WYChatView, action: WYChatAction, messageID: String) {
        if action == .startTransfer || action == .resumeTransfer {
            startExampleTransfer(messageID)
        } else if action == .pauseTransfer {
            exampleTransferTasks.removeValue(forKey: messageID)
            chatView.updateTransfer(messageID: messageID, state: .paused)
        } else if action == .delete {
            exampleTransferTasks.removeValue(forKey: messageID)
        }
        if action == .withdraw { chatView.markMessageWithdrawn(messageID) }
        if action == .favorite, chatView.configuration.selection.automaticallyFavoritesMessages {
            WYActivity.showInfo("已收藏", in: view.window)
        }
        if action == .takePat, let target = chatView.messageModelFrom(messageID)?.sender {
            let pat = WYChatTakePatModel(striking: chatView.userInfo, beaten: target, notes: "的肩膀")
            appendExampleMessage(WYChatMessageContentModel(takePat: pat))
        }
        if action == .content, let fileID = chatView.messageModelFrom(messageID)?.content.file?.id,
           let url = importedFiles[fileID] {
            previewExampleFile(url)
        }
        if action == .play { playExampleVoice(messageID) }
        if action == .pause, playingVoiceID == messageID {
            if chatView.configuration.voicePlayback.restartsOnTap { stopExampleVoice() }
            else { voicePlayer?.pause(); updateExampleVoice(messageID, playing: false) }
        }
        if action == .retry, let message = chatView.messageModelFrom(messageID) { prepareExampleMessage(message) }
    }

    func wy_speechRecognitionFinished(_ chatView: WYChatView, messageID: String, text: String?, error: NSError?) {
        if let error { showVoiceError(error) }
    }

    func wy_recordingFinished(_ chatView: WYChatView, url: URL?, duration: TimeInterval, error: NSError?) {
        if let error { showVoiceError(error) }
    }
    
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
        let items = moreView.moreViewConfig.moreSource
        guard !isImportingPhotos, presentedViewController == nil,
              items.indices.contains(itemIndex), let title = items[itemIndex].keys.first else { return }
        // 照片已由 albumMoreItemIndex 转交给 openAlbumHandler。
        if itemIndex == chatView.configuration.media.albumMoreItemIndex { return }
        chatView.inputViewResignFirstResponder()
        switch title {
        case "拍摄": openExampleCamera()
        case "文件": openExampleFiles()
        default:
            if let content = exampleContent(for: title) { confirmExampleContent(content, title: title) }
        }
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
        if longPress.state == .began { stopExampleVoice() }
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

extension WYTestChatController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { stopExampleVoice() }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stopExampleVoice()
        if let error { showVoiceError(error as NSError) }
    }
}


extension WYTestChatController {
    private func appendExampleMessage(_ content: WYChatMessageContentModel) {
        let timestamp = String(Date().timeIntervalSince1970)
        var message = WYChatMessageModel(messageID: UUID().uuidString, timestamp: timestamp, sender: chatView.userInfo, content: content)
        message.index = chatView.dataSource.count
        message.lastMessageTimestamp = message.sharedLastMessageTimestamp(chatView.dataSource, minimumTimeSpan: chatView.configuration.basic.messageMinimumTimeSpan)
        message.sendState = .success
        chatView.appendMessages([message])
        chatView.scrollToLastMessage()
    }

    private func confirmExampleContent(_ content: WYChatMessageContentModel, title: String) {
        exampleConfirmationTitle = title
        chatView.confirmSending([content]) { [weak self] in
            guard let self else { return }
            if content.text != nil { self.appendExampleMessage(content) }
            else { self.chatView.sendContent(content) }
        }
    }

    private func presentExampleConfirmation(_ completion: @escaping (Bool) -> Void) {
        let title = exampleConfirmationTitle ?? "发送消息"
        exampleConfirmationTitle = nil
        guard presentedViewController == nil else { completion(false); return }
        let prompt = title == "收藏" && !chatView.favoriteMessages.isEmpty ? "发送最近收藏的消息？" : "确认发送？"
        let alert = UIAlertController(title: title, message: prompt, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completion(false) })
        alert.addAction(UIAlertAction(title: "发送", style: .default) { _ in completion(true) })
        present(alert, animated: true)
    }

    private func presentExampleFundsDetail(_ tapped: WYChatMessageModel) -> Bool {
        let original = tapped.content.fundsReceipt.flatMap { chatView.messageModelFrom($0.originalMessageID) } ?? tapped
        guard let funds = original.content.luckyMoney ?? original.content.transfer else { return false }
        guard presentedViewController == nil else { return true }
        let alert = UIAlertController(title: original.content.luckyMoney != nil ? "红包示例" : "转账示例", message: "金额 ¥\(funds.amounts)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "关闭", style: .cancel))
        if funds.state == .unreceived {
            alert.addAction(UIAlertAction(title: "模拟收款", style: .default) { [weak self] _ in
                self?.chatView.markFundsReceived(original.messageID, actorName: "示例联系人")
            })
        }
        present(alert, animated: true)
        return true
    }

    private func startExampleMediaTransfer(_ messageID: String, itemID: String) {
        let key = messageID + "/" + itemID
        let token = UUID()
        exampleTransferTasks[key] = token
        chatView.updateMediaTransfer(messageID: messageID, itemID: itemID, state: .transferring)
        advanceExampleMediaTransfer(messageID, itemID: itemID, token: token)
    }

    private func advanceExampleMediaTransfer(_ messageID: String, itemID: String, token: UUID) {
        let key = messageID + "/" + itemID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, self.exampleTransferTasks[key] == token else { return }
            guard let group = self.chatView.messageModelFrom(messageID)?.content.mediaGroup,
                  let offset = group.items.firstIndex(where: { $0.id == itemID }) else {
                self.exampleTransferTasks.removeValue(forKey: key)
                return
            }
            let item = group.items[offset]
            let next = min(1, item.transferProgress + (item.kind == .video ? 0.035 : 0.055) / (1 + Double(offset) * 0.12))
            let phase: WYChatTransferState = next == 1 ? .completed : .transferring
            self.chatView.updateMediaTransfer(messageID: messageID, itemID: itemID, state: phase, progress: next)
            if phase == .transferring {
                self.advanceExampleMediaTransfer(messageID, itemID: itemID, token: token)
            } else {
                self.exampleTransferTasks.removeValue(forKey: key)
                if let row = self.chatView.dataSource.firstIndex(where: { $0.messageID == messageID }),
                   self.chatView.dataSource[row].content.mediaGroup?.items.allSatisfy({ $0.transferState == .completed }) == true {
                    self.chatView.dataSource[row].sendState = .success
                }
            }
        }
    }

    private func startExampleTransfer(_ messageID: String) {
        guard let message = chatView.messageModelFrom(messageID) else { return }
        let token = UUID()
        exampleTransferTasks[messageID] = token
        let progress = message.transferProgress < 1 ? message.transferProgress : 0
        chatView.updateTransfer(messageID: messageID, state: .transferring, progress: progress)
        advanceExampleTransfer(messageID, token: token)
    }

    private func advanceExampleTransfer(_ messageID: String, token: UUID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, self.exampleTransferTasks[messageID] == token else { return }
            guard let message = self.chatView.messageModelFrom(messageID) else {
                self.exampleTransferTasks.removeValue(forKey: messageID)
                return
            }
            let next = min(1, message.transferProgress + 0.12)
            if next >= 1 {
                self.exampleTransferTasks.removeValue(forKey: messageID)
                self.chatView.updateTransfer(messageID: messageID, state: .completed)
                if let index = self.chatView.dataSource.firstIndex(where: { $0.messageID == messageID }),
                   self.chatView.dataSource[index].sendState == .sending {
                    self.chatView.dataSource[index].sendState = .success
                }
            } else {
                self.chatView.updateTransfer(messageID: messageID, state: .transferring, progress: next)
                self.advanceExampleTransfer(messageID, token: token)
            }
        }
    }

    private func deliverExampleForward(_ messages: [WYChatMessageModel]) {
        // 模拟目标会话收到消息，示例使用当前会话展示转发结果。
        let startIndex = chatView.dataSource.count
        let forwarded = messages.enumerated().map { offset, message in
            var result = message
            result.index = startIndex + offset
            result.sendState = .success
            return result
        }
        chatView.appendMessages(forwarded)
        chatView.scrollToLastMessage()
    }

    private func exampleContent(for title: String) -> WYChatMessageContentModel? {
        switch title {
        case "位置":
            return WYChatMessageContentModel(location: WYChatLocationModel(title: "示例位置 · 测试公园", address: "示例路 100 号", longitude: "121.4737", latitude: "31.2304"))
        case "收藏":
            if let favorite = chatView.favoriteMessages.last { return favorite.content }
            // ChatView 使用网页卡片展示示例收藏。
            return WYChatMessageContentModel(webpage: WYChatWebpageModel(title: "示例收藏 · 聊天接入指南", remarks: "来自我的收藏", name: "收藏", path: "https://example.com"))
        case "个人名片":
            let user = WYChatUserModel(id: "example-card", name: "示例联系人")
            return WYChatMessageContentModel(businessCard: WYChatBusinessCardModel(userInfo: user, remarks: "个人名片"))
        case "音乐":
            return WYChatMessageContentModel(music: WYChatMusicModel(name: "示例音乐", singer: "示例歌手", duration: 180))
        case "发红包":
            return WYChatMessageContentModel(luckyMoney: WYChatLuckyMoneyModel(amounts: "8.88", remarks: "示例红包 · 祝你开心", notes: "红包"))
        case "转账":
            return WYChatMessageContentModel(transfer: WYChatLuckyMoneyModel(amounts: "20.00", remarks: "示例转账", notes: "转账"))
        default:
            return nil
        }
    }

    private func showAttachmentNotice(_ message: String) {
        let alert = UIAlertController(title: "聊天附件", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .cancel))
        present(alert, animated: true)
    }

    private func openExampleAlbum() {
        guard !isImportingPhotos, presentedViewController == nil else { return }
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = chatView.configuration.media.albumAllowsVideos ? .any(of: [.images, .videos]) : .images
        configuration.selection = .ordered
        configuration.selectionLimit = max(0, chatView.configuration.media.albumSelectionLimit)
        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func openExampleCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAttachmentNotice("当前设备无法使用相机，请在支持拍照的 iPhone 上测试。")
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status != .denied, status != .restricted else {
            showAttachmentNotice("相机访问受限，请检查系统设置中的相机权限。")
            return
        }
        let camera = UIImagePickerController()
        camera.sourceType = .camera
        let supported = UIImagePickerController.availableMediaTypes(for: .camera) ?? [UTType.image.identifier]
        camera.mediaTypes = [UTType.image.identifier, UTType.movie.identifier].filter { supported.contains($0) }
        camera.delegate = self
        present(camera, animated: true)
    }

    private func openExampleFiles() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func previewExampleFile(_ url: URL) {
        guard QLPreviewController.canPreview(url as NSURL) else {
            showAttachmentNotice("系统无法预览此文件格式。")
            return
        }
        previewFileURL = url
        let preview = QLPreviewController()
        preview.dataSource = self
        present(preview, animated: true)
    }

    private func sendExamplePhotos(_ items: [WYChatMediaItem], selectedCount: Int) {
        guard !items.isEmpty else {
            showAttachmentNotice("无法读取所选照片。")
            return
        }
        guard items.count > max(1, chatView.configuration.media.foldingThreshold) else {
            sendExamplePhotos(items, presentation: .individual)
            return
        }
        let includesVideo = items.contains { $0.kind == .video }
        let unit = includesVideo ? "项媒体" : "张照片"
        let message = items.count == selectedCount
            ? "已选 \(items.count) \(unit)，请选择发送后的展示方式。"
            : "成功读取 \(items.count) / \(selectedCount) \(unit)，请选择发送后的展示方式。"
        let alert = UIAlertController(title: includesVideo ? "媒体展示方式" : "照片展示方式", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "折叠展示", style: .default) { [weak self] _ in
            self?.sendExamplePhotos(items, presentation: .merged)
        })
        alert.addAction(UIAlertAction(title: "单独展示", style: .default) { [weak self] _ in
            self?.sendExamplePhotos(items, presentation: .individual)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            for item in items { try? FileManager.default.removeItem(atPath: item.original.localPath) }
        })
        present(alert, animated: true)
    }

    private func sendExamplePhotos(_ items: [WYChatMediaItem], presentation: WYChatMediaPresentation) {
        chatView.sendMedia(items, presentation: presentation)
    }
}

extension WYTestChatController: PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate, QLPreviewControllerDataSource {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        isImportingPhotos = !results.isEmpty
        let allowsVideos = chatView.configuration.media.albumAllowsVideos
        picker.dismiss(animated: true) { [weak self] in
            guard let self, !results.isEmpty else { return }
            Task {
                var items: [WYChatMediaItem] = []
                for result in results {
                    if let item = await self.importExampleMedia(result.itemProvider, allowsVideos: allowsVideos) { items.append(item) }
                }
                self.isImportingPhotos = false
                guard self.viewIfLoaded?.window != nil, self.presentedViewController == nil else {
                    for item in items { try? FileManager.default.removeItem(atPath: item.original.localPath) }
                    return
                }
                self.sendExamplePhotos(items, selectedCount: results.count)
            }
        }
    }

    private func importExampleMedia(_ provider: NSItemProvider, allowsVideos: Bool) async -> WYChatMediaItem? {
        let directory = attachmentDirectory
        let kind: WYChatMediaKind = allowsVideos && provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
            && !provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) ? .video : .photo
        let type = kind == .video ? UTType.movie : .image
        let destination: URL? = await withCheckedContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, _ in
                guard let url else { continuation.resume(returning: nil); return }
                let destination = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(url.pathExtension)
                do {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                    try FileManager.default.copyItem(at: url, to: destination)
                    continuation.resume(returning: destination)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
        guard let destination else { return nil }
        if kind == .video { return await exampleVideoItem(at: destination) }
        guard let image = UIImage(contentsOfFile: destination.path) else {
            try? FileManager.default.removeItem(at: destination)
            return nil
        }
        return Self.examplePhotoItem(at: destination, size: image.size)
    }

    nonisolated private static func examplePhotoItem(at url: URL, size: CGSize) -> WYChatMediaItem {
        let asset = WYChatAssetsModel(localPath: url.path)
        var item = WYChatMediaItem()
        item.original = asset
        item.thumbnail = asset
        item.size = size
        return item
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let movie = info[.mediaURL] as? URL {
            prepareCapturedVideo(movie, picker: picker)
            return
        }
        let image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            do {
                guard let image, let data = image.jpegData(compressionQuality: 0.9) else {
                    showAttachmentNotice("无法读取拍摄结果。")
                    return
                }
                try FileManager.default.createDirectory(at: attachmentDirectory, withIntermediateDirectories: true)
                let url = attachmentDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
                try data.write(to: url, options: .atomic)
                chatView.sendMedia([Self.examplePhotoItem(at: url, size: image.size)])
            } catch {
                showAttachmentNotice("无法保存拍摄结果。")
            }
        }
    }

    private func prepareCapturedVideo(_ source: URL, picker: UIImagePickerController) {
        let destination = attachmentDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(source.pathExtension)
        do {
            try FileManager.default.createDirectory(at: attachmentDirectory, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            picker.dismiss(animated: true) { [weak self] in self?.showAttachmentNotice("无法保存拍摄的视频。") }
            return
        }
        picker.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            Task {
                let item = await self.exampleVideoItem(at: destination)
                guard self.viewIfLoaded?.window != nil else { return }
                let content = WYChatMessageContentModel(mediaGroup: WYChatMediaGroupModel(items: [item]))
                self.exampleConfirmationTitle = "视频"
                self.confirmVideoSending(content, item: item)
            }
        }
    }

    private func confirmVideoSending(_ content: WYChatMessageContentModel, item: WYChatMediaItem) {
        chatView.confirmSending([content]) { [weak self] in self?.chatView.sendMedia([item]) }
    }

    private func exampleVideoItem(at destination: URL) async -> WYChatMediaItem {
        let asset = AVURLAsset(url: destination)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 640)
        var item = WYChatMediaItem()
        item.kind = .video
        item.original.localPath = destination.path
        let seconds = (try? await asset.load(.duration).seconds) ?? 0
        item.duration = seconds.isFinite ? seconds : 0
        let thumbnail: CGImage? = await withCheckedContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: .zero)]) { _, image, _, _, _ in
                continuation.resume(returning: image)
            }
        }
        if let thumbnail {
            let image = UIImage(cgImage: thumbnail)
            let coverURL = destination.deletingPathExtension().appendingPathExtension("jpg")
            if let data = image.jpegData(compressionQuality: 0.8), (try? data.write(to: coverURL, options: .atomic)) != nil {
                item.thumbnail.localPath = coverURL.path
                item.size = image.size
            }
        }
        return item
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let fileID = UUID().uuidString
        let directory = attachmentDirectory.appendingPathComponent(fileID, isDirectory: true)
        do {
            let localURL = directory.appendingPathComponent(url.lastPathComponent)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: url, to: localURL)
            let byteCount = try localURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            importedFiles[fileID] = localURL
            let size = ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
            let file = WYChatFileModel(id: fileID, title: url.lastPathComponent, size: size, name: url.pathExtension.uppercased())
            let content = WYChatMessageContentModel(file: file)
            let confirm = { [weak self] in self?.confirmExampleContent(content, title: "文件") }
            if controller.transitionCoordinator?.animate(alongsideTransition: nil, completion: { _ in confirm() }) != true {
                confirm()
            }
        } catch {
            try? FileManager.default.removeItem(at: directory)
            showAttachmentNotice("无法读取所选文件。")
        }
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { previewFileURL == nil ? 0 : 1 }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        previewFileURL! as NSURL
    }
}
