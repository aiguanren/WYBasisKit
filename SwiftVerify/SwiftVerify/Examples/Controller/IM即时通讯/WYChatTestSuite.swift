import UIKit
import AVFoundation
import AVKit
import Speech

/// 聊天交互检查的独立容器
final class WYChatTestHostController: UIViewController {}

enum WYChatTestStatus: String, Codable {
    case notRun, running, passed, failed
}

struct WYChatTestResult: Codable {
    let name: String
    let passed: Bool
    let detail: String
    let milliseconds: Double
}

@MainActor
final class WYChatTestCase {
    let name: String
    let group: String
    let explanation: String
    let operation: () async -> [WYChatTestResult]
    let requiresInteraction: Bool
    var status: WYChatTestStatus = .notRun
    var results: [WYChatTestResult] = []

    init(_ name: String, group: String, explanation: String, requiresInteraction: Bool = false, operation: @escaping () async -> [WYChatTestResult]) {
        self.name = name
        self.group = group
        self.explanation = explanation
        self.operation = operation
        self.requiresInteraction = requiresInteraction
    }
}

@MainActor
final class WYChatTestSuite {
    let chatView: WYChatView
    private(set) var cases: [WYChatTestCase] = []
    private(set) var isRunning = false
    private(set) var didFinishBatch = false
    private weak var scrollProbe: WYChatScrollProbe?
    var progress: (() -> Void)?

    init(chatView: WYChatView, scrollProbe: WYChatScrollProbe? = nil) {
        self.chatView = chatView
        self.scrollProbe = scrollProbe
        registerBehaviorCases()
        registerCoreEventCase()
        registerRepairCases()
        cases.append(WYChatTestCase("消息事件与输入面板：高级配置", group: "配置", explanation: "实际调用按消息配置、资源加载、时间格式、表情资源、分页样式和富文本复制粘贴") { [weak self] in
            guard let self else { return [] }
            return await WYChatTestAdvancedConfigurationChecks.run(source: self.chatView)
        })
        cases.append(WYChatTestCase("配置目录与输入校验", group: "配置", explanation: "核对实际配置字段与编辑目录，逐项检查读写、恢复默认和非法输入隔离，UI行为由布局和真实操作用例另验") { WYChatTestConfigurationChecks.run() })
        registerExternalActionCases()
        registerAvatarMentionCases()
        registerQuoteWithdrawalCases()
        registerSelectionForwardCases()
        registerVoicePlaybackCases()
        registerAppearanceCases()
        registerConfigurationColorPickerCase()
        registerEmojiGestureCase()
        registerReadingPositionCase()
        registerEmojiLimitCase()
        registerRecordingCases()
        registerRecordingActionStyles()
        registerDictationCases()
        registerTranscriptEditorCases()
        registerMediaCases()
        registerMediaPlaybackCase()
        registerMediaGestureCase()
        registerBrowserStackCases()
        registerAppleSpeechCase()
        registerModelCases()
        registerLayoutCases()
    }

    func run(_ item: WYChatTestCase) async {
        guard !isRunning else { return }
        isRunning = true
        await execute(item)
        isRunning = false
        saveReport(isBatch: false)
        progress?()
    }

    func runAll() async {
        guard !isRunning else { return }
        isRunning = true
        for item in cases where !item.requiresInteraction {
            await execute(item)
            try? await Task.sleep(nanoseconds: 16_000_000)
        }
        isRunning = false
        didFinishBatch = true
        saveReport(isBatch: true)
        progress?()
    }

    var report: String {
        let values = cases.map { item -> [String: Any] in
            ["name": item.name, "group": item.group, "status": item.status.rawValue,
             "checks": item.results.map { ["name": $0.name, "passed": $0.passed, "detail": $0.detail, "milliseconds": $0.milliseconds] }]
        }
        let object: [String: Any] = ["system": UIDevice.current.systemVersion, "model": UIDevice.current.model, "cases": values]
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]), let text = String(data: data, encoding: .utf8) else { return "" }
        return text
    }

    private func saveReport(isBatch: Bool) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("ChatView-TestResults.json")
        guard let current = report.data(using: .utf8), var object = (try? JSONSerialization.jsonObject(with: current)) as? [String: Any] else { return }
        let previous = (try? Data(contentsOf: url)).flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
        let recordedAt = ISO8601DateFormatter().string(from: Date())
        object["recordedAt"] = recordedAt
        object["kind"] = isBatch ? "batch" : "single"
        if isBatch { object["lastBatchRun"] = object }
        else if let batch = previous["lastBatchRun"] { object["lastBatchRun"] = batch }
        let names = Set(cases.map(\.name))
        var latest = (previous["lastCaseRuns"] as? [String: [String: Any]] ?? [:]).filter { names.contains($0.key) }
        for item in object["cases"] as? [[String: Any]] ?? [] {
            guard let name = item["name"] as? String, let status = item["status"] as? String, status == "passed" || status == "failed" else { continue }
            var result = item
            result["recordedAt"] = recordedAt
            result["system"] = UIDevice.current.systemVersion
            latest[name] = result
        }
        object["lastCaseRuns"] = latest
        if let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) { try? data.write(to: url, options: .atomic) }
    }

    private func execute(_ item: WYChatTestCase) async {
        item.status = .running
        saveReport(isBatch: false)
        progress?()
        item.results = await item.operation()
        item.status = !item.results.isEmpty && item.results.allSatisfy(\.passed) ? .passed : .failed
        saveReport(isBatch: false)
        progress?()
    }

    private func registerRepairCases() {
        cases.append(WYChatTestCase("回弹、气泡与录音入列", group: "返修", explanation: "检查边界回弹不被强制归位、头像中心与尾部对齐、自定义图片、录音结果入列和命中区域") { [weak self] in
            guard let self else { return [] }
            let recorder: WYChatRecordingFixture
            do { recorder = try WYChatRecordingFixture() } catch { return [WYChatTestResult(name: "repair-fixture", passed: false, detail: error.localizedDescription, milliseconds: 0)] }
            defer { try? FileManager.default.removeItem(at: recorder.url) }
            var config = self.chatView.configuration
            config.recording.recorder = recorder
            config.recording.supportSpeechRecognition = false
            config.recording.recordTime.min = 0
            config.sender.showsSingleNickname = true
            config.receiver.showsSingleNickname = true
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            let host = self.chatView.window ?? self.chatView
            view.frame = host.bounds
            host.addSubview(view)
            defer { view.releaseAll(); view.removeFromSuperview() }
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ passed: Bool, _ detail: String = "") { checks.append(WYChatTestResult(name: name, passed: passed, detail: detail, milliseconds: 0)) }
            view.dataSource = (0..<30).map { WYChatMessageModel(messageID: "bounce-\($0)", content: WYChatMessageContentModel(text: "回弹检查 \($0)")) }
            view.layoutIfNeeded()
            view.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            view.tableView.layoutIfNeeded()
            let pull = -view.tableView.adjustedContentInset.top - 70
            view.tableView.setContentOffset(CGPoint(x: 0, y: pull), animated: false)
            view.tableView.layoutIfNeeded()
            check("overscroll-not-clamped", abs(view.tableView.contentOffset.y - pull) < 1, "offset=\(view.tableView.contentOffset.y), requested=\(pull)")
            view.tableView.setContentOffset(.zero, animated: false)
            for sender in [false, true] {
                for top: CGFloat in [-12, 0, 8] {
                    var sample = config
                    sample.sender.contentTopOffset = top
                    sample.receiver.contentTopOffset = top
                    let cell = WYChatTextCell(style: .default, reuseIdentifier: nil)
                    cell.frame = CGRect(x: 0, y: 0, width: 393, height: 240)
                    host.addSubview(cell)
                    let user = sender ? view.userInfo : WYChatUserModel(id: "repair-other", name: "昵称")
                    cell.update(message: WYChatMessageModel(sender: user, content: WYChatMessageContentModel(text: "气泡中心检查")), configuration: sample, userID: view.userInfo.id)
                    cell.layoutIfNeeded()
                    let bubble = cell.bubblesView
                    let tip = bubble.convert(CGPoint(x: 0, y: bubble.bounds.midY + bubble.arrowOffset), to: cell).y
                    let avatar = cell.avatarView.convert(CGPoint(x: 0, y: cell.avatarView.bounds.midY), to: cell).y
                    check("bubble-avatar-center-\(sender)-\(top)", abs(tip - avatar) < 1, "tip=\(tip), avatar=\(avatar)")
                    sample.senderBubble.arrowImage = UIImage(systemName: "arrowtriangle.right.fill")
                    sample.receiverBubble.arrowImage = UIImage(systemName: "arrowtriangle.left.fill")
                    cell.configuration = sample
                    cell.layoutIfNeeded()
                    let image = bubble.subviews.compactMap { $0 as? UIImageView }.first
                    check("bubble-image-override-\(sender)-\(top)", !bubble.showsArrow && image?.image != nil)
                    cell.removeFromSuperview()
                }
            }
            check("recording-rejects-directory", view.sendVoiceRecording(FileManager.default.temporaryDirectory, duration: 1) == nil)
            let before = view.dataSource.count
            var prepared: [WYChatMessageModel] = []
            view.messagePreparedHandler = { prepared.append($0) }
            view.chatInput.recordView.start()
            try? await Task.sleep(nanoseconds: 100_000_000)
            view.chatInput.recordView.stop()
            try? await Task.sleep(nanoseconds: 200_000_000)
            check("recording-prepares-message", prepared.count == 1 && view.dataSource.count == before + 1)
            check("recording-retains-local-file", prepared.last?.content.voice?.localPath == recorder.url.path && FileManager.default.fileExists(atPath: recorder.url.path))
            recorder.completeAgain()
            try? await Task.sleep(nanoseconds: 50_000_000)
            check("recording-result-once", prepared.count == 1)
            for style in [WYRecordingActionStyle.circular, .curved] {
                var value = config.recording
                value.actionStyle = style
                value.supportSpeechRecognition = true
                let overlay = WYRecordAnimationView(alpha: 0, configuration: value)
                overlay.frame = host.bounds
                host.addSubview(overlay)
                overlay.start()
                overlay.layoutIfNeeded()
                overlay.switchStatus(CGPoint(x: host.bounds.midX, y: host.bounds.midY / 2))
                check("recording-outside-regions-\(style.rawValue)", overlay.soundAnimationStatus == .recording)
                let targets = overlay.subviews.compactMap { $0 as? WYMoveUpTipsView }
                if let cancel = targets.first(where: { $0.moveUpView.currentTitle == value.cancelRecordViewText.onInterior }) {
                    let center = cancel.moveUpView.convert(CGPoint(x: cancel.moveUpView.bounds.midX, y: cancel.moveUpView.bounds.midY), to: overlay)
                    overlay.switchStatus(center)
                    check("recording-cancel-center-\(style.rawValue)", overlay.soundAnimationStatus == .cancel)
                    overlay.switchStatus(cancel.moveUpView.convert(CGPoint(x: 1, y: 1), to: overlay))
                    check("recording-excludes-button-corner-\(style.rawValue)", overlay.soundAnimationStatus == .recording)
                }
                overlay.endRecordVoice()
                overlay.removeFromSuperview()
            }
            return checks
        })
        cases.append(WYChatTestCase("输入框实时识别与占位配置", group: "返修", explanation: "检查居中占位、键盘识别入口、当前选区替换、最终结果、取消迟到回调和关闭识别") { [weak self] in
            guard let self else { return [] }
            let recorder: WYChatRecordingFixture
            do { recorder = try WYChatRecordingFixture() } catch { return [] }
            defer { try? FileManager.default.removeItem(at: recorder.url) }
            let speech = WYChatRecognitionFixture()
            var config = self.chatView.configuration
            config.input.textPlaceholderAlignment = .center
            config.recording.recorder = recorder
            config.recording.speechRecognitionSource = .external
            config.recording.speechRecognitionProvider = speech
            config.recording.supportSpeechRecognition = true
            config.recording.speechRecognitionMode = .whileRecording
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            let host = self.chatView.window ?? self.chatView
            view.frame = host.bounds
            host.addSubview(view)
            defer { view.inputViewResignFirstResponder(); view.releaseAll(); view.removeFromSuperview() }
            view.layoutIfNeeded()
            let input = view.chatInput
            input.layoutIfNeeded()
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ value: Bool) { checks.append(WYChatTestResult(name: name, passed: value, detail: "", milliseconds: 0)) }
            check("placeholder-centered", input.textPlaceholderView.textAlignment == .center)
            input.textView.becomeFirstResponder()
            input.textView.text = "前缀后缀"
            input.textViewDidChange(input.textView, silence: true)
            input.textView.selectedRange = NSRange(location: 2, length: 0)
            view.layoutIfNeeded()
            try? await Task.sleep(nanoseconds: 150_000_000)
            let button = input.subviews.compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "WYChatInput.dictation" }
            check("keyboard-dictation-entry", button != nil && button?.isHidden == false)
            button?.sendActions(for: .touchUpInside)
            try? await Task.sleep(nanoseconds: 200_000_000)
            check("keyboard-dictation-partial", input.textView.text == "前缀" + speech.partialText + "后缀" && input.textView.isFirstResponder && input.isInputDictating)
            button?.sendActions(for: .touchUpInside)
            try? await Task.sleep(nanoseconds: 200_000_000)
            check("keyboard-dictation-final", input.textView.text == "前缀" + speech.finalText + "后缀" && !input.isInputDictating)
            button?.sendActions(for: .touchUpInside)
            try? await Task.sleep(nanoseconds: 100_000_000)
            _ = input.textView(input.textView, shouldChangeTextIn: input.textView.selectedRange, replacementText: "A")
            let saved = input.textView.text
            speech.emitLateResult()
            try? await Task.sleep(nanoseconds: 100_000_000)
            check("keyboard-dictation-late-result", !input.isInputDictating && input.textView.text == saved)
            var disabled = config.recording
            disabled.supportSpeechRecognition = false
            input.recordAnimationConfig = disabled
            input.layoutIfNeeded()
            check("keyboard-dictation-disabled", button?.isHidden == true && !input.isInputDictating)
            for button in [input.textVoiceView, input.emojiView] {
                button.isSelected = true
                button.layoutIfNeeded()
                check("toggle-icon-no-title-\(button.accessibilityIdentifier ?? "")", button.currentTitle == nil && button.currentImage != nil && (button.imageView?.bounds.width ?? 0) > 10)
            }
            return checks
        })
        cases.append(WYChatTestCase("居中占位长按真实手势", group: "返修", explanation: "长按空输入框的居中占位，松手后编辑并发送识别文本", requiresInteraction: true) { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController, let recorder = try? WYChatRecordingFixture() else { return [] }
            defer { try? FileManager.default.removeItem(at: recorder.url) }
            let speech = WYChatRecognitionFixture()
            var presenter = root
            while let shown = presenter.presentedViewController { presenter = shown }
            let host = WYChatTestHostController()
            host.modalPresentationStyle = .fullScreen
            presenter.present(host, animated: false)
            var config = self.chatView.configuration
            config.input.textPlaceholderAlignment = .center
            config.recording.recorder = recorder
            config.recording.speechRecognitionSource = .external
            config.recording.speechRecognitionProvider = speech
            config.recording.supportSpeechRecognition = true
            config.recording.recordTime.min = 0
            config.recording.dictationSendsOnRelease = false
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            host.view.addSubview(view)
            view.frame = host.view.bounds
            view.layoutIfNeeded()
            defer { view.releaseAll(); host.dismiss(animated: false) }
            for _ in 0..<450 {
                if !view.dataSource.isEmpty { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            return [WYChatTestResult(name: "placeholder-long-press-sends-text", passed: speech.starts == 1 && view.dataSource.count == 1 && view.dataSource.first?.content.text == speech.finalText, detail: "starts=\(speech.starts), messages=\(view.dataSource.count)", milliseconds: 0)]
        })
        cases.append(WYChatTestCase("录音发送真实手势", group: "返修", explanation: "按住录音后松手发送，再拖到操作区域外松手发送，最后拖到取消区域松手取消", requiresInteraction: true) { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController, let recorder = try? WYChatRecordingFixture() else { return [] }
            defer { try? FileManager.default.removeItem(at: recorder.url) }
            var presenter = root
            while let shown = presenter.presentedViewController { presenter = shown }
            let host = WYChatTestHostController()
            host.modalPresentationStyle = .fullScreen
            presenter.present(host, animated: false)
            var config = self.chatView.configuration
            config.recording.recorder = recorder
            config.recording.supportSpeechRecognition = false
            config.recording.recordTime.min = 0
            config.recording.actionStyle = .curved
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            host.view.addSubview(view)
            view.frame = host.view.bounds
            view.chatInput.textVoiceView.sendActions(for: .touchUpInside)
            view.layoutIfNeeded()
            defer { view.releaseAll(); host.dismiss(animated: false) }
            for _ in 0..<600 {
                if recorder.stops >= 3 { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            let voices = view.dataSource.compactMap { $0.content.voice }
            return [WYChatTestResult(name: "recording-real-send-cancel", passed: recorder.stops == 3 && voices.count == 2 && voices.allSatisfy { $0.localPath == recorder.url.path }, detail: "stops=\(recorder.stops), voices=\(voices.count)", milliseconds: 0)]
        })
        cases.append(WYChatTestCase("顶部回弹真实手势", group: "返修", explanation: "在列表顶部向下拖动后松手，检查回弹经过多个显示帧并回到顶部", requiresInteraction: true) { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController else { return [] }
            var presenter = root
            while let shown = presenter.presentedViewController { presenter = shown }
            let host = WYChatTestHostController()
            host.modalPresentationStyle = .fullScreen
            presenter.present(host, animated: false)
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: self.chatView.configuration)
            host.view.addSubview(view)
            view.frame = host.view.bounds
            view.tableView.accessibilityIdentifier = "WYChatTests.bounceTable"
            view.dataSource = (0..<50).map { WYChatMessageModel(content: WYChatMessageContentModel(text: "顶部回弹 \($0)")) }
            view.layoutIfNeeded()
            view.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            view.tableView.layoutIfNeeded()
            let probe = WYChatBounceProbe(table: view.tableView)
            defer { probe.stop(); view.releaseAll(); host.dismiss(animated: false) }
            for _ in 0..<120 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if probe.minimum < -20 && !view.tableView.isDragging && !view.tableView.isDecelerating && abs(view.tableView.contentOffset.y + view.tableView.adjustedContentInset.top) < 1 { break }
            }
            return [WYChatTestResult(name: "native-bounce-frames", passed: probe.minimum < -20 && probe.recoveryFrames >= 3 && abs(view.tableView.contentOffset.y + view.tableView.adjustedContentInset.top) < 1, detail: "minimum=\(probe.minimum), recoveryFrames=\(probe.recoveryFrames), final=\(view.tableView.contentOffset.y)", milliseconds: 0)]
        })
    }

    private func registerBehaviorCases() {
        cases.append(WYChatTestCase("实际手势滚动", group: "手势", explanation: "先关闭测试面板，在聊天列表中缓慢上下拖动，再运行本项检查拖动时消息与手指移动是否一致，并记录显示帧间隔", requiresInteraction: true) { [weak self] in
            self?.scrollProbe?.results() ?? [WYChatTestResult(name: "gesture-observer", passed: false, detail: "未建立滚动观察", milliseconds: 0)]
        })
        cases.append(WYChatTestCase("消息增删、更新及引用", group: "功能", explanation: "检查追加、插入历史、替换内容类型、引用、发送和退出多选的实际状态") { [weak self] in
            guard let self else { return [] }
            let view = self.chatView
            let saved = view.dataSource
            let config = view.configuration
            defer { view.configuration = config; view.dataSource = saved; view.isSelectingMessages = false; view.quoteMessage(nil) }
            var results: [WYChatTestResult] = []
            func check(_ name: String, _ passed: Bool, _ detail: String = "") { results.append(WYChatTestResult(name: name, passed: passed, detail: detail, milliseconds: 0)) }
            let first = WYChatMessageModel(messageID: "test-first", sender: WYChatUserModel(id: "other", name: "联系人"), content: WYChatMessageContentModel(text: "第一条消息"))
            view.dataSource = [first]
            view.appendMessages([WYChatMessageModel(messageID: "test-second", content: WYChatMessageContentModel(text: "第二条消息"))])
            check("appendMessages", view.dataSource.count == 2 && view.tableView.numberOfRows(inSection: 0) == 2)
            view.prependMessages([WYChatMessageModel(messageID: "test-history", content: WYChatMessageContentModel(text: "历史"))])
            check("prependMessages", view.dataSource.first?.messageID == "test-history" && view.dataSource.last?.messageID == "test-second")
            check("messageModelFrom", view.messageModelFrom("test-first") == first && view.messageModelFrom("missing") == nil)
            view.quoteMessage(first.messageID)
            let sent = view.sendMessage("引用发送", messageID: "test-sent")
            check("sendMessage", sent.content.text == "引用发送" && sent.sender == view.userInfo && sent.sendState == .sending)
            check("quoteMessage", sent.reference?.content == first.content && sent.reference?.messageID == first.messageID && view.quotedMessageID == nil)
            view.isSelectingMessages = true
            view.isSelectingMessages = false
            check("selection-exit", view.selectedMessageIDs.isEmpty && view.selectionToolbar.isHidden)
            view.dataSource[0].content = WYChatMessageContentModel(file: WYChatFileModel(title: "内容类型变更"))
            view.tableView.layoutIfNeeded()
            let changed = view.tableView(view.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
            check("same-id-content-type-change", changed is WYChatFileCell)
            return results
        })
        cases.append(WYChatTestCase("长列表刷新耗时", group: "性能", explanation: "记录5000条消息追加及修改单条消息所需时间，并检查结果数量与消息内容") { [weak self] in
            guard let self else { return [] }
            let view = self.chatView
            let saved = view.dataSource
            defer { view.dataSource = saved }
            let messages = (0..<5000).map { index in WYChatMessageModel(messageID: "performance-\(index)", content: WYChatMessageContentModel(text: "第\(index)条消息，长列表滚动与更新检查")) }
            view.dataSource = []
            let start = CACurrentMediaTime()
            view.appendMessages(messages)
            let appendTime = (CACurrentMediaTime() - start) * 1000
            let lastVisible = view.tableView.indexPathsForVisibleRows?.contains(IndexPath(row: messages.count - 1, section: 0)) == true
            let updateStart = CACurrentMediaTime()
            view.dataSource[2500].content.text = "单条消息更新成功"
            let updateTime = (CACurrentMediaTime() - updateStart) * 1000
            let changedPath = IndexPath(row: 2500, section: 0)
            view.tableView.scrollToRow(at: changedPath, at: .middle, animated: false)
            view.tableView.layoutIfNeeded()
            let changedCell = view.tableView.cellForRow(at: changedPath) as? WYChatTextCell
            return [WYChatTestResult(name: "5000-message-append", passed: view.dataSource.count == 5000 && lastVisible, detail: "追加5000条消息，末条可见\(lastVisible)，消息体\(MemoryLayout<WYChatMessageContentModel>.stride)字节，消息\(MemoryLayout<WYChatMessageModel>.stride)字节", milliseconds: appendTime), WYChatTestResult(name: "single-message-update", passed: changedCell?.textView.text == "单条消息更新成功", detail: "更新未显示的消息，再滚动到该消息核对实际文字", milliseconds: updateTime)]
        })
    }

    private func registerCoreEventCase() {
        cases.append(WYChatTestCase("消息事件与输入面板", group: "功能", explanation: "检查消息操作接管、发送回调、引用按钮、多选转发/删除/取消、输入面板、录音结果和应用事件") { [weak self] in
            guard let self else { return [] }
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: self.chatView.configuration)
            let host = self.chatView.window ?? self.chatView
            view.frame = host.bounds
            host.addSubview(view)
            defer { view.inputViewResignFirstResponder(); view.releaseAll(); view.removeFromSuperview() }
            let events = WYChatViewEventsFixture()
            view.delegate = events
            view.eventsHandler = events
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ value: Bool) { checks.append(WYChatTestResult(name: name, passed: value, detail: "", milliseconds: 0)) }
            let messages = [WYChatMessageModel(messageID: "events-first", sender: WYChatUserModel(id: "other"), content: WYChatMessageContentModel(text: "消息一")), WYChatMessageModel(messageID: "events-second", content: WYChatMessageContentModel(text: "消息二"))]
            view.dataSource = messages
            view.layoutIfNeeded()
            view.tableView.layoutIfNeeded()
            var actionCount = 0
            var prepared: [WYChatMessageModel] = []
            view.actionHandler = { _, _, _ in actionCount += 1 }
            view.messagePreparedHandler = { prepared.append($0) }
            @MainActor func act(_ action: WYChatAction, _ row: Int) {
                let path = IndexPath(row: row, section: 0)
                view.tableView.scrollToRow(at: path, at: .middle, animated: false)
                view.tableView.layoutIfNeeded()
                let cell = view.tableView.cellForRow(at: path) as? WYChatBasicCell
                cell?.actionHandler?(action, messages[row].messageID)
            }
            events.allowAction = false
            act(.quote, 0)
            check("message-action-veto", view.quotedMessageID == nil && actionCount == 0 && events.actions == 0)
            events.allowAction = true
            act(.quote, 0)
            check("message-action-callbacks", view.quotedMessageID == messages[0].messageID && actionCount == 1 && events.actions == 1 && !view.quoteButton.isHidden)
            view.quoteButton.sendActions(for: .touchUpInside)
            check("quote-button-cancels", view.quotedMessageID == nil && view.quoteButton.isHidden)
            view.tableView(view.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
            check("row-selection-content-callbacks", actionCount == 2 && events.actions == 2)
            events.allowAction = false
            view.tableView(view.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
            check("row-selection-veto", actionCount == 2 && events.actions == 2)
            events.allowAction = true
            view.isSelectingMessages = true
            view.tableView(view.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
            check("row-selection-multiple-messages", view.selectedMessageIDs == [messages[1].messageID])
            view.isSelectingMessages = false
            view.dataSource = [WYChatMessageModel(messageID: "events-media", content: WYChatMessageContentModel(mediaGroup: WYChatMediaGroupModel(items: [WYChatMediaItem()]))) ]
            let beforeMediaRow = actionCount
            view.tableView(view.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
            check("row-selection-media-background", actionCount == beforeMediaRow)
            view.dataSource = messages
            events.allowKeyboardSend = false
            view.didClickKeyboardEvent("被接管的发送", silence: false)
            check("keyboard-send-veto", view.dataSource.count == 2 && prepared.isEmpty && events.keyboardMessages.isEmpty)
            events.allowKeyboardSend = true
            view.didClickKeyboardEvent("键盘发送", silence: false)
            check("keyboard-send-callbacks", prepared.count == 1 && events.keyboardMessages == [prepared.first?.messageID ?? ""] && view.dataSource.last?.content.text == "键盘发送")
            view.didClickKeyboardEvent("  ", silence: true)
            check("empty-keyboard-send", prepared.count == 1)
            view.dataSource = messages
            var selection: (WYChatAction, [String])?
            view.selectionActionHandler = { selection = ($0, $1) }
            act(.select, 1)
            act(.select, 0)
            check("selection-toolbar-state", view.isSelectingMessages && view.selectedMessageIDs == Set(messages.map(\.messageID)) && !view.selectionToolbar.isHidden && view.chatInput.isHidden && view.selectionForwardButton.isEnabled)
            view.selectionForwardButton.sendActions(for: .touchUpInside)
            check("selection-forward-order", selection?.0 == .forward && selection?.1 == messages.map(\.messageID) && !view.isSelectingMessages && !view.chatInput.isHidden)
            act(.select, 0)
            view.selectionDeleteButton.sendActions(for: .touchUpInside)
            check("selection-delete", selection?.0 == .delete && selection?.1 == [messages[0].messageID] && view.dataSource.count == 2)
            act(.select, 0)
            view.selectionCancelButton.sendActions(for: .touchUpInside)
            check("selection-cancel", view.selectedMessageIDs.isEmpty && !view.isSelectingMessages && view.selectionToolbar.isHidden)
            view.chatInput.moreView.sendActions(for: .touchUpInside)
            check("more-panel", view.touchStyle == .more && view.moreView?.isHidden == false && events.moreToggles == 1)
            view.chatInput.emojiView.sendActions(for: .touchUpInside)
            check("emoji-panel", view.touchStyle == .emoji && view.emojiView?.isHidden == false && events.emojiToggles == 1)
            view.inputViewResignFirstResponder()
            check("resign-input-panels", view.touchStyle == .done && view.moreView?.isHidden != false && view.emojiView?.isHidden != false)
            let button = UIButton(type: .system)
            let press = UILongPressGestureRecognizer()
            for allowed in [false, true] {
                events.allowControls = allowed
                check("voice-control-veto-\(allowed)", view.wy_canManagerVoiceRecordEvents(press) == allowed && view.wy_canManagerTextVoiceViewEvents(button) == allowed)
                check("panel-control-veto-\(allowed)", view.wy_canManagerTextEmojiViewEvents(button) == allowed && view.wy_canManagerMoreViewEvents(button) == allowed)
                if let emoji = view.emojiView {
                    check("emoji-control-veto-\(allowed)", view.wy_canManagerEmojiViewClickEvents(emoji, indexPath: IndexPath(item: 0, section: 0)) == allowed && view.wy_canManagerEmojiDeleteViewClickEvents(button) == allowed && view.wy_canManagerEmojiSendViewClickEvents(button) == allowed)
                }
                if let more = view.moreView { check("more-item-veto-\(allowed)", view.wy_canManagerMoreViewClickEvents(more, itemIndex: 0) == allowed) }
            }
            view.wy_didClickTextVoiceView(isText: false)
            view.wy_didClickTextVoiceView(isText: true)
            check("voice-mode-callback", events.voiceModes == [false, true] && view.touchStyle == .done)
            view.chatInput.textView.text = "前缀"
            view.chatInput.textView.selectedRange = NSRange(location: 2, length: 0)
            if let emoji = view.emojiView, let first = emoji.dataSource.first?.first {
                emoji.collectionView(emoji.collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
                check("emoji-insert-callback", view.chatInput.sharedEmojiAttributedText(attributed: view.chatInput.textView.attributedText).string == "前缀" + first && events.emojiSelections == 1)
                view.chatInput.textView.text = "测试A"
                emoji.wy_didClickEmojiDeleteView(button)
                check("emoji-delete-forwarding", view.chatInput.textView.text == "测试" && events.emojiDeletes == 1)
                let sent = prepared.count
                emoji.wy_didClickEmojiSendView(button)
                check("emoji-send-forwarding", prepared.count == sent + 1 && prepared.last?.content.text == "测试" && events.emojiSends == 1)
            } else { check("emoji-fixture-data", false) }
            let keyboardCount = prepared.count
            view.wy_didClickKeyboardEvent(text: "代理发送")
            view.chatInput.textView.text = "按钮发送"
            view.chatInput.didClickSendView(button)
            check("input-send-entry-points", prepared.count == keyboardCount + 2 && prepared.suffix(2).map(\.content.text) == ["代理发送", "按钮发送"])
            if let area = view.emojiView?.funcAreaView {
                @MainActor func buttons(_ root: UIView) -> [UIButton] { root.subviews.flatMap { ($0 as? UIButton).map { [$0] } ?? buttons($0) } }
                let controls = buttons(area)
                let send = controls.first { $0.currentTitle == view.configuration.emoji.funcAreaConfig.sendViewText }
                let delete = controls.first { $0.currentTitle == view.configuration.emoji.funcAreaConfig.deleteViewText }
                area.isUserInteractionEnabled = true
                send?.isUserInteractionEnabled = false
                delete?.isUserInteractionEnabled = true
                area.updateFuncAreaStyle()
                check("emoji-area-independent-state", send?.isSelected == true && delete?.isSelected == false)
                let deletes = events.emojiDeletes
                view.chatInput.textView.text = "区域A"
                area.clickDeleteView()
                check("emoji-area-delete-entry", events.emojiDeletes == deletes + 1 && view.chatInput.textView.text == "区域")
                let sends = prepared.count
                area.clickSendView()
                check("emoji-area-send-entry", prepared.count == sends + 1 && prepared.last?.content.text == "区域")
                area.didLongPress(sender: UILongPressGestureRecognizer())
                area.cancelLongPressTimer()
            }

            let activeBefore = events.activeEvents
            events.allowApplication = false
            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: UIApplication.shared)
            check("application-event-veto", events.activeEvents == activeBefore)
            events.allowApplication = true
            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: UIApplication.shared)
            check("application-event-object", events.activeEvents == activeBefore + 1 && events.application === UIApplication.shared)
            view.chatInput.textView.becomeFirstResponder()
            try? await Task.sleep(nanoseconds: 350_000_000)
            view.chatInput.textView.resignFirstResponder()
            try? await Task.sleep(nanoseconds: 350_000_000)
            check("keyboard-lifecycle-callbacks", events.keyboardShows > 0 && events.keyboardHides > 0)
            let shows = events.keyboardShows
            let hides = events.keyboardHides
            events.allowKeyboardLifecycle = false
            view.chatInput.textView.becomeFirstResponder()
            try? await Task.sleep(nanoseconds: 350_000_000)
            view.chatInput.textView.resignFirstResponder()
            try? await Task.sleep(nanoseconds: 350_000_000)
            check("keyboard-lifecycle-veto", events.keyboardShows == shows && events.keyboardHides == hides)
            let recorder: WYChatRecordingFixture
            do { recorder = try WYChatRecordingFixture() }
            catch { checks.append(WYChatTestResult(name: "recording-fixture", passed: false, detail: error.localizedDescription, milliseconds: 0)); return checks }
            defer { try? FileManager.default.removeItem(at: recorder.url) }
            var config = view.configuration
            config.recording.recorder = recorder
            config.recording.supportSpeechRecognition = false
            view.configuration = config
            var voiceURL: URL?
            view.recordingHandler = { url, _, _ in voiceURL = url }
            view.chatInput.recordView.start()
            try? await Task.sleep(nanoseconds: 50_000_000)
            view.chatInput.recordView.stop()
            try? await Task.sleep(nanoseconds: 350_000_000)
            check("chat-recording-callbacks", voiceURL == recorder.url && events.recordingResults == 1 && events.recordingURL == recorder.url)
            view.chatInput.textView.text = String(repeating: "输入框长文本高度检查\n", count: 30)
            view.chatInput.textViewDidChange(view.chatInput.textView, silence: true)
            view.layoutIfNeeded()
            view.chatInput.layoutIfNeeded()
            check("long-input-height-limit", view.chatInput.textView.bounds.height <= view.configuration.input.textViewMaxHeight + 1 && view.chatInput.textView.isScrollEnabled)
            view.releaseAll()
            check("release-recording-overlay", view.chatInput.recordView.alpha == 0)
            return checks
        })
    }

    private func registerAvatarMentionCases() {
        cases.append(WYChatTestCase("用户提及与头像配置", group: "功能", explanation: "检查头像操作配置、同名用户身份、提及插入、编辑范围、替换和删除、发送元数据与值语义") { [weak self] in
            guard let self else { return [] }
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            let host = self.chatView.window ?? self.chatView
            view.frame = host.bounds
            host.addSubview(view)
            defer { view.inputViewResignFirstResponder(); view.releaseAll(); view.removeFromSuperview() }
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ valid: Bool, _ detail: String = "") { checks.append(WYChatTestResult(name: name, passed: valid, detail: detail, milliseconds: 0)) }
            let first = WYChatUserModel(id: "mention-one", name: "同名")
            let second = WYChatUserModel(id: "mention-two", name: "同名")
            @MainActor func editor() -> UITextView { view.chatInput.textView }
            @MainActor func plain() -> String { view.chatInput.sharedEmojiAttributedText(attributed: editor().attributedText).string }
            @MainActor func setText(_ text: String) {
                editor().attributedText = view.chatInput.sharedEmojiAttributed(string: text)
                editor().selectedRange = NSRange(location: editor().attributedText.length, length: 0)
                view.chatInput.textViewDidChange(editor(), silence: false)
            }
            setText("😀 ")
            check("mention-inserts-at-cursor", view.mentionUser(first) && plain() == "😀 @同名 ")
            check("mention-utf16-range", view.inputMentions.first?.range == NSRange(location: 3, length: 3) && view.inputMentions.first?.user.id == first.id)
            setText("前缀" + plain())
            check("mention-shifts-after-edit", view.inputMentions.first?.range.location == 5 && view.inputMentions.first?.user.id == first.id)
            let range = view.inputMentions.first?.range ?? NSRange(location: 0, length: 0)
            let replaced = (plain() as NSString).replacingCharacters(in: NSRange(location: range.location + 1, length: 1), with: "改")
            setText(replaced)
            check("mention-edit-removes-identity", view.inputMentions.isEmpty && plain().contains("@改名"))
            setText("")
            _ = view.mentionUser(first)
            _ = view.mentionUser(second)
            check("mention-identical-names-keep-ids", view.inputMentions.map { $0.user.id } == [first.id, second.id] && view.inputMentions.map(\.range) == [NSRange(location: 0, length: 3), NSRange(location: 4, length: 3)])
            editor().selectedRange = NSRange(location: 0, length: 0)
            _ = view.mentionUser(second)
            check("mention-identical-prefix-edit-position", view.inputMentions.map { $0.user.id } == [second.id, first.id, second.id] && view.inputMentions.map { $0.range.location } == [0, 4, 8])
            let insertionRange = NSRange(location: 0, length: 0)
            let nativeInsertion = view.chatInput.textView(editor(), shouldChangeTextIn: insertionRange, replacementText: "@同名 ")
            if nativeInsertion { editor().textStorage.replaceCharacters(in: insertionRange, with: "@同名 "); view.chatInput.textViewDidChange(editor(), silence: false) }
            check("mention-native-identical-insertion", nativeInsertion && view.inputMentions.map { $0.range.location } == [4, 8, 12] && view.inputMentions.map { $0.user.id } == [second.id, first.id, second.id])
            let deletionRange = NSRange(location: 0, length: 4)
            let nativeDeletion = view.chatInput.textView(editor(), shouldChangeTextIn: deletionRange, replacementText: "")
            if nativeDeletion { editor().textStorage.replaceCharacters(in: deletionRange, with: ""); view.chatInput.textViewDidChange(editor(), silence: false) }
            check("mention-native-identical-deletion", nativeDeletion && view.inputMentions.map { $0.range.location } == [0, 4, 8] && view.inputMentions.map { $0.user.id } == [second.id, first.id, second.id])
            let draft = view.inputMentions
            let unrelated = view.sendMessage("普通文本", messageID: "mention-unrelated")
            check("mention-programmatic-send-isolated", unrelated.mentions.isEmpty && view.inputMentions == draft)
            let sent = view.sendMessage(plain(), messageID: "mention-message")
            check("mention-send-metadata", sent.mentions == draft && view.dataSource.last?.mentions == draft)
            var copy = sent
            copy.mentions[0].user.name = "另一个名字"
            check("mention-model-value-isolation", sent.mentions[0].user.name == first.name && copy != sent)
            view.didClickKeyboardEvent(plain(), silence: true)
            check("mention-keyboard-send-clears-draft", view.dataSource.last?.mentions == draft && view.inputMentions.isEmpty && plain().isEmpty)
            _ = view.mentionUser(first)
            editor().selectedRange = NSRange(location: 0, length: 3)
            _ = view.mentionUser(second)
            check("mention-selection-replaces-identity", view.inputMentions.count == 1 && view.inputMentions.first?.user.id == second.id)
            setText("")
            check("mention-delete-clears-identity", view.inputMentions.isEmpty)
            config.basic.mentionPrefix = "#"
            config.basic.mentionSuffix = "、"
            view.configuration = config
            let customInserted = view.mentionUser(first)
            check("mention-custom-text", customInserted && plain() == "#同名、" && view.inputMentions.first?.text == "#同名", "inserted=\(customInserted), text=\(plain()), mentions=\(view.inputMentions)")
            setText("保持")
            config.input.inputTextLength = 2
            view.configuration = config
            check("mention-limit-does-not-insert-partial", !view.mentionUser(first) && plain() == "保持" && view.inputMentions.isEmpty)
            check("mention-requires-user-id", !view.mentionUser(WYChatUserModel(name: "空身份")))
            let message = WYChatMessageModel(messageID: "avatar-config", sender: first, content: WYChatMessageContentModel(text: "头像配置"))
            let cell = WYChatTextCell(style: .default, reuseIdentifier: nil)
            config.basic.avatarTapAction = .none
            config.basic.avatarLongPressAction = .none
            config.basic.avatarDoubleTapAction = .none
            cell.update(message: message, configuration: config, userID: self.chatView.userInfo.id)
            check("avatar-gestures-can-disable", cell.avatarView.gestureRecognizers?.count == 3 && cell.avatarView.gestureRecognizers?.allSatisfy { !$0.isEnabled } == true)
            config.basic.avatarTapAction = .profile
            config.basic.avatarLongPressAction = .mention
            config.basic.avatarDoubleTapAction = .takePat
            config.basic.avatarLongPressDuration = 0.6
            cell.update(message: message, configuration: config, userID: self.chatView.userInfo.id)
            check("avatar-gesture-configuration", cell.avatarView.gestureRecognizers?.allSatisfy(\.isEnabled) == true && cell.avatarView.gestureRecognizers?.compactMap { $0 as? UILongPressGestureRecognizer }.first?.minimumPressDuration == 0.6)
            config.basic.avatarLongPressDuration = .nan
            cell.update(message: message, configuration: config, userID: self.chatView.userInfo.id)
            check("avatar-invalid-duration-default", cell.avatarView.gestureRecognizers?.compactMap { $0 as? UILongPressGestureRecognizer }.first?.minimumPressDuration == WYBasicChatConfig().avatarLongPressDuration)
            config.input.inputTextLength = Int.max
            config.basic.automaticallyInsertsMentions = false
            view.configuration = config
            view.dataSource = [message]
            view.layoutIfNeeded()
            view.tableView.layoutIfNeeded()
            let actual = view.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? WYChatBasicCell
            var action: WYChatAction?
            view.actionHandler = { _, value, _ in action = value }
            actual?.actionHandler?(.mention, message.messageID)
            check("avatar-mention-host-handles", action == .mention && plain() == "保持" && view.inputMentions.isEmpty)
            actual?.actionHandler?(.takePat, message.messageID)
            check("avatar-pat-does-not-fake-message", action == .takePat && view.dataSource == [message])
            return checks
        })
        cases.append(WYChatTestCase("头像真实手势", group: "手势", explanation: "依次长按头像、双击头像和单击头像，检查提及、拍一拍请求与打开用户事件互不重复", requiresInteraction: true) { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController else { return [] }
            var presenter = root
            while let shown = presenter.presentedViewController { presenter = shown }
            let host = WYChatTestHostController()
            host.modalPresentationStyle = .fullScreen
            presenter.present(host, animated: false)
            try? await Task.sleep(nanoseconds: 150_000_000)
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            config.basic.avatarTapAction = .profile
            config.basic.avatarLongPressAction = .mention
            config.basic.avatarDoubleTapAction = .takePat
            config.basic.automaticallyInsertsMentions = true
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            view.translatesAutoresizingMaskIntoConstraints = false
            host.view.addSubview(view)
            NSLayoutConstraint.activate([view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor), view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor), view.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor), view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor)])
            host.view.layoutIfNeeded()
            defer { view.inputViewResignFirstResponder(); view.releaseAll(); host.dismiss(animated: false) }
            let user = WYChatUserModel(id: "avatar-gesture-user", name: "联系人")
            view.dataSource = [WYChatMessageModel(messageID: "avatar-gesture", sender: user, content: WYChatMessageContentModel(text: "长按、双击和单击头像"))]
            var actions: [WYChatAction: Int] = [:]
            var animatedPat = false
            view.actionHandler = { [weak view] _, action, _ in
                guard let view else { return }
                actions[action, default: 0] += 1
                if action == .takePat, let cell = view.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? WYChatBasicCell {
                    animatedPat = cell.avatarView.layer.animationKeys()?.compactMap { cell.avatarView.layer.animation(forKey: $0) as? CAKeyframeAnimation }.contains { $0.duration == config.basic.avatarPatAnimationDuration } == true
                }
            }
            view.layoutIfNeeded()
            view.tableView.layoutIfNeeded()
            let actualCell = view.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? WYChatBasicCell
            let avatarFrame = actualCell.map { $0.avatarView.convert($0.avatarView.bounds, to: view.window) } ?? .zero
            let geometry = WYChatTestResult(name: "avatar-safe-area", passed: view.window != nil && avatarFrame.minY >= host.view.safeAreaInsets.top, detail: "host=\(host.view.frame), safe=\(host.view.safeAreaInsets), view=\(view.frame), viewSafe=\(view.safeAreaInsets), table=\(view.tableView.frame), offset=\(view.tableView.contentOffset), avatar=\(avatarFrame), presented=\(String(describing: host.presentingViewController)), window=\(String(describing: view.window))", milliseconds: 0)
            self.cases.first { $0.name == "头像真实手势" }?.results = [geometry]
            self.saveReport(isBatch: false)
            for _ in 0..<300 {
                if (actions[.avatar] ?? 0) > 0 && (actions[.takePat] ?? 0) > 0 && (actions[.mention] ?? 0) > 0 { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            return [geometry,
                WYChatTestResult(name: "avatar-real-mention", passed: actions[.mention] == 1 && view.inputMentions.first?.user.id == user.id, detail: "actions=\(actions)", milliseconds: 0),
                WYChatTestResult(name: "avatar-real-double-tap", passed: actions[.takePat] == 1, detail: "", milliseconds: 0),
                WYChatTestResult(name: "avatar-real-single-tap", passed: actions[.avatar] == 1, detail: "", milliseconds: 0),
                WYChatTestResult(name: "avatar-real-pat-animation", passed: animatedPat, detail: "", milliseconds: 0),
                WYChatTestResult(name: "avatar-real-no-fake-pat", passed: view.dataSource.count == 1 && view.dataSource[0].content.takePat == nil, detail: "", milliseconds: 0)
            ]
        })
    }

    private func registerConfigurationColorPickerCase() {
        cases.append(WYChatTestCase("配置选色器回调", group: "配置", explanation: "检查选色器不修改颜色直接关闭时保留nil，选择颜色后写入对应配置，并保留其他字段") { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController,
                  let field = WYChatTestConfigurationFields.all.first(where: { $0.path == "senderBubble.shadowColor" }) else { return [] }
            var presenter = root
            while let next = presenter.presentedViewController { presenter = next }
            var config = self.chatView.configuration
            config.senderBubble.shadowColor = nil
            config.input.draftStorageKey = ""
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            let editor = WYChatTestConfigurationController(chatView: view, fields: [field])
            let navigation = UINavigationController(rootViewController: editor)
            navigation.modalPresentationStyle = .fullScreen
            await withCheckedContinuation { continuation in
                presenter.present(navigation, animated: false) { continuation.resume() }
            }
            defer { view.releaseAll() }
            var checks: [WYChatTestResult] = []
            for changed in [false, true] {
                editor.tableView(editor.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
                var presented: UIColorPickerViewController?
                for _ in 0..<20 {
                    presented = (editor.presentedViewController ?? navigation.presentedViewController) as? UIColorPickerViewController
                    if let picker = presented, !picker.isBeingPresented, picker.transitionCoordinator == nil, picker.viewIfLoaded?.window != nil { break }
                    try? await Task.sleep(nanoseconds: 50_000_000)
                }
                guard let picker = presented, picker.viewIfLoaded?.window != nil else {
                    await withCheckedContinuation { continuation in
                        presenter.dismiss(animated: false) { continuation.resume() }
                    }
                    return [WYChatTestResult(name: "configuration-color-picker-presented", passed: false, detail: "No presented color picker", milliseconds: 0)]
                }
                if changed {
                    picker.selectedColor = .magenta
                    picker.delegate?.colorPickerViewController?(picker, didSelect: .magenta, continuously: false)
                }
                picker.delegate?.colorPickerViewControllerDidFinish?(picker)
                checks.append(WYChatTestResult(name: changed ? "configuration-color-selection" : "configuration-color-unchanged-nil", passed: changed ? view.configuration.senderBubble.shadowColor?.isEqual(UIColor.magenta) == true : view.configuration.senderBubble.shadowColor == nil, detail: "", milliseconds: 0))
                await withCheckedContinuation { continuation in
                    picker.dismiss(animated: false) { continuation.resume() }
                }
            }
            checks.append(WYChatTestResult(name: "configuration-color-preserves-font", passed: view.configuration.input.textFont == config.input.textFont, detail: "", milliseconds: 0))
            await withCheckedContinuation { continuation in
                presenter.dismiss(animated: false) { continuation.resume() }
            }
            return checks
        })
    }

    private func registerExternalActionCases() {
        cases.append(WYChatTestCase("宿主消息操作入口", group: "功能", explanation: "检查收藏、提醒、搜索和已读标记请求及事件接管，组件不伪造服务结果") { [weak self] in
            guard let self else { return [] }
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            let actions: [WYChatAction] = [.favorite, .remind, .search, .markRead, .markUnread]
            config.menuActions = actions
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            let host = self.chatView.window ?? self.chatView
            view.frame = host.bounds
            host.addSubview(view)
            defer { view.releaseAll(); view.removeFromSuperview() }
            let source = [WYChatMessageModel(messageID: "external-action", sender: view.userInfo, content: WYChatMessageContentModel(text: "原消息内容"))]
            view.dataSource = source
            view.layoutIfNeeded()
            view.tableView.layoutIfNeeded()
            let events = WYChatViewEventsFixture()
            view.delegate = events
            view.eventsHandler = events
            var received: [WYChatAction] = []
            var identifiers: [String] = []
            view.actionHandler = { _, action, identifier in received.append(action); identifiers.append(identifier) }
            let cell = view.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? WYChatBasicCell
            for action in actions { cell?.actionHandler?(action, source[0].messageID) }
            var results = [
                WYChatTestResult(name: "host-actions-complete", passed: received == actions, detail: "", milliseconds: 0),
                WYChatTestResult(name: "host-actions-identities", passed: identifiers == Array(repeating: source[0].messageID, count: actions.count), detail: "", milliseconds: 0),
                WYChatTestResult(name: "host-actions-delegate", passed: events.actions == actions.count, detail: "", milliseconds: 0),
                WYChatTestResult(name: "host-actions-no-fake-result", passed: view.dataSource == source, detail: "", milliseconds: 0)
            ]
            events.allowAction = false
            for action in actions { cell?.actionHandler?(action, source[0].messageID) }
            results.append(WYChatTestResult(name: "host-actions-veto", passed: received == actions && events.actions == actions.count && view.dataSource == source, detail: "", milliseconds: 0))
            return results
        })
        cases.append(WYChatTestCase("宿主消息菜单真实操作", group: "手势", explanation: "逐项长按执行收藏、提醒、搜索和已读标记，检查可配置标题及原消息不变", requiresInteraction: true) { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController else { return [] }
            var presenter = root
            while let next = presenter.presentedViewController { presenter = next }
            let host = WYChatTestHostController()
            host.modalPresentationStyle = .fullScreen
            presenter.present(host, animated: false)
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            let actions: [WYChatAction] = [.favorite, .remind, .search, .markRead, .markUnread]
            config.menuActions = actions
            config.actionTitle = { $0 == .remind ? "安排提醒" : nil }
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            view.translatesAutoresizingMaskIntoConstraints = false
            host.view.addSubview(view)
            NSLayoutConstraint.activate([view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor), view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor), view.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor), view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor)])
            host.view.layoutIfNeeded()
            defer { view.releaseAll(); host.dismiss(animated: false) }
            let source = [WYChatMessageModel(messageID: "external-action-touch", sender: view.userInfo, content: WYChatMessageContentModel(text: "宿主操作测试消息"))]
            view.dataSource = source
            var received: [WYChatAction] = []
            view.actionHandler = { _, action, identifier in if actions.contains(action) && identifier == source[0].messageID { received.append(action) } }
            for _ in 0..<600 {
                if received.count == actions.count { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            return [
                WYChatTestResult(name: "host-real-menu-actions", passed: received == actions, detail: "\(received.map(\.rawValue))", milliseconds: 0),
                WYChatTestResult(name: "host-real-menu-no-fake-result", passed: view.dataSource == source, detail: "", milliseconds: 0)
            ]
        })
    }

    private func registerEmojiGestureCase() {
        cases.append(WYChatTestCase("表情跨行预览真实操作", group: "手势", explanation: "长按首行表情拖到下一行，核对实际预览文字和锚定位置变化，松手后关闭且不插入表情", requiresInteraction: true) { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController else { return [] }
            var presenter = root
            while let next = presenter.presentedViewController { presenter = next }
            let host = WYChatTestHostController()
            host.modalPresentationStyle = .fullScreen
            presenter.present(host, animated: false)
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            config.emoji.showRecently = false
            config.emoji.previewConfig.minimumPressDuration = 0.4
            config.emoji.previewConfig.allowableMovement = 28
            config.emoji.previewConfig.textHorizontalInset = 9
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            view.translatesAutoresizingMaskIntoConstraints = false
            host.view.addSubview(view)
            NSLayoutConstraint.activate([view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor), view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor), view.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor), view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor)])
            host.view.layoutIfNeeded()
            try? await Task.sleep(nanoseconds: 100_000_000)
            defer { view.releaseAll(); host.dismiss(animated: false) }
            view.chatInput.emojiView.sendActions(for: .touchUpInside)
            try? await Task.sleep(nanoseconds: 350_000_000)
            view.layoutIfNeeded()
            guard let emoji = view.emojiView else { return [] }
            emoji.layoutIfNeeded()
            emoji.collectionView.layoutIfNeeded()
            let cells = emoji.collectionView.visibleCells.sorted { abs($0.frame.minY - $1.frame.minY) > 1 ? $0.frame.minY < $1.frame.minY : $0.frame.minX < $1.frame.minX }
            guard let first = cells.first, let second = cells.first(where: { $0.frame.minY > first.frame.minY + 1 }),
                  let firstPath = emoji.collectionView.indexPath(for: first), let secondPath = emoji.collectionView.indexPath(for: second), let window = view.window else {
                return [WYChatTestResult(name: "emoji-real-two-rows", passed: false, detail: "visible=\(cells.map(\.frame))", milliseconds: 0)]
            }
            first.isAccessibilityElement = true
            second.isAccessibilityElement = true
            first.accessibilityIdentifier = "WYChatEmoji.previewStart"
            second.accessibilityIdentifier = "WYChatEmoji.previewEnd"
            @MainActor func title(_ path: IndexPath) -> String {
                let value = emoji.dataSource[path.section][path.item]
                return WYLocalized(value.wy_substring(from: 1, to: value.count - 1), table: WYBasisKitConfig.kitLocalizableTable)
            }
            let expected = [title(firstPath), title(secondPath)]
            let gestures = emoji.collectionView.gestureRecognizers?.compactMap { $0 as? UILongPressGestureRecognizer } ?? []
            let gesture = gestures.first { $0.minimumPressDuration == config.emoji.previewConfig.minimumPressDuration && $0.allowableMovement == config.emoji.previewConfig.allowableMovement }
            var seen: [String: CGRect] = [:]
            var closed = false
            for _ in 0..<900 {
                if let preview = window.subviews.compactMap({ $0 as? WYEmojiPreviewView }).first, !preview.isHidden,
                   let text = preview.subviews.compactMap({ $0 as? UILabel }).first?.text, seen[text] == nil {
                    seen[text] = preview.frame
                    let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("ChatView-VisualResults", isDirectory: true)
                    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                    let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: false) }
                    try? image.pngData()?.write(to: folder.appendingPathComponent("emoji-preview-\(seen.count).png"))
                }
                if expected.allSatisfy({ seen[$0] != nil }) && !window.subviews.contains(where: { $0 is WYEmojiPreviewView }) { closed = true; break }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
            let moved = expected.compactMap { seen[$0]?.minY }
            return [
                WYChatTestResult(name: "emoji-real-preview-gesture-config", passed: gesture?.minimumPressDuration == 0.4 && gesture?.allowableMovement == 28, detail: "\(gestures.map { [ $0.minimumPressDuration, Double($0.allowableMovement) ] })", milliseconds: 0),
                WYChatTestResult(name: "emoji-real-cross-row-content", passed: expected.allSatisfy { seen[$0] != nil }, detail: "expected=\(expected), seen=\(seen)", milliseconds: 0),
                WYChatTestResult(name: "emoji-real-anchor-moves", passed: moved.count == 2 && abs(moved[0] - moved[1]) > 1, detail: "\(moved)", milliseconds: 0),
                WYChatTestResult(name: "emoji-real-release-no-insertion", passed: closed && view.chatInput.textView.attributedText.string.isEmpty, detail: "", milliseconds: 0)
            ]
        })
    }

    private func registerAppearanceCases() {
        cases.append(WYChatTestCase("浅色深色与输入外观", group: "配置", explanation: "切换浅色/深色检查实际气泡颜色、文字对比、输入背景、图标着色、语音按压和自定义图片") { [weak self] in
            guard let self else { return [] }
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            config.sender.showsSingleNickname = true
            config.basic.showReadMark = true
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            let host = self.chatView.window ?? self.chatView
            view.frame = host.bounds
            host.addSubview(view)
            defer { view.releaseAll(); view.removeFromSuperview() }
            var message = WYChatMessageModel(messageID: "appearance-message", sender: view.userInfo, content: WYChatMessageContentModel(text: "主题与文字检查"))
            message.sendState = .success
            view.dataSource = [message]
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ value: Bool, _ detail: String = "") { checks.append(WYChatTestResult(name: name, passed: value, detail: detail, milliseconds: 0)) }
            func rgba(_ color: UIColor, _ traits: UITraitCollection) -> [CGFloat] {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                color.resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
                return [r, g, b, a]
            }
            func same(_ first: UIColor?, _ second: UIColor, _ traits: UITraitCollection) -> Bool {
                guard let first else { return false }
                return zip(rgba(first, traits), rgba(second, traits)).allSatisfy { abs($0 - $1) < 0.001 }
            }
            func layers(_ layer: CALayer) -> [CALayer] { [layer] + (layer.sublayers ?? []).flatMap { layers($0) } }
            for (index, appearance) in [UIUserInterfaceStyle.light, .dark, .light].enumerated() {
                view.overrideUserInterfaceStyle = appearance
                view.setNeedsLayout()
                view.layoutIfNeeded()
                view.tableView.layoutIfNeeded()
                let traits = view.traitCollection
                let input = view.chatInput
                check("appearance-input-background-\(index)", input.image == nil && same(input.backgroundColor, config.input.backgroundColor, traits))
                check("appearance-icon-template-\(index)", input.textVoiceView.image(for: .normal)?.renderingMode == .alwaysTemplate && same(input.textVoiceView.tintColor, config.input.iconTintColor, traits))
                input.textVoiceContentView.isSelected = true
                check("appearance-text-background-\(index)", same(input.textVoiceContentView.backgroundColor, config.input.textViewBackgroundColor, traits))
                input.textVoiceContentView.isSelected = false
                check("appearance-voice-background-\(index)", same(input.textVoiceContentView.backgroundColor, config.input.voiceViewBackgroundColor, traits))
                input.textVoiceContentView.isHighlighted = true
                check("appearance-voice-highlight-\(index)", same(input.textVoiceContentView.backgroundColor, config.input.voiceViewHighlightedBackgroundColor, traits))
                input.textVoiceContentView.isHighlighted = false
                input.textVoiceContentView.isSelected = true
                if let cell = view.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? WYChatBasicCell {
                    let expected = config.senderBubble.fillColor.resolvedColor(with: traits)
                    let actual = layers(cell.bubblesView.layer).compactMap { ($0 as? CAShapeLayer)?.fillColor }.map(UIColor.init(cgColor:))
                    check("appearance-actual-bubble-\(index)", actual.contains { same($0, expected, traits) }, "actual=\(actual), expected=\(expected)")
                    let fill = rgba(expected, traits)
                    let text = rgba(config.text.textColor, traits)
                    func luminance(_ rgb: [CGFloat]) -> CGFloat {
                        let values = rgb.prefix(3).map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
                        return values[0] * 0.2126 + values[1] * 0.7152 + values[2] * 0.0722
                    }
                    let first = luminance(fill), second = luminance(text)
                    let contrast = (max(first, second) + 0.05) / (min(first, second) + 0.05)
                    check("appearance-text-contrast-\(index)", contrast >= 4.5, "contrast=\(contrast)")
                } else { check("appearance-actual-bubble-\(index)", false) }
                let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("ChatView-VisualResults", isDirectory: true)
                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let image = UIGraphicsImageRenderer(bounds: view.bounds).image { _ in view.drawHierarchy(in: view.bounds, afterScreenUpdates: true) }
                try? image.pngData()?.write(to: folder.appendingPathComponent("appearance-\(index)-\(appearance.rawValue).png"))
            }
            let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in UIColor.magenta.setFill(); context.fill(CGRect(x: 0, y: 0, width: 4, height: 4)) }
            var custom = config
            custom.input.backgroundImage = image
            custom.input.textViewBackgroundImage = image
            custom.input.rendersIconsAsTemplate = false
            custom.input.iconTintColor = .orange
            view.configuration = custom
            check("appearance-custom-image-retained", view.chatInput.image === image && view.chatInput.textVoiceContentView.backgroundImage(for: .selected) === image)
            check("appearance-original-icon-colors", view.chatInput.textVoiceView.image(for: .normal)?.renderingMode == .alwaysOriginal)
            return checks
        })
    }

    private func registerVoicePlaybackCases() {
        cases.append(WYChatTestCase("语音倍速与播放接管", group: "功能", explanation: "检查倍速菜单、宿主和代理回调、重复/非法请求、模型快照、显示配置与消息复用") { [weak self] in
            guard let self else { return [] }
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            config.voicePlayback.rates = [1, 1.5, 2, 2, -.infinity, .nan, 0, -1]
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            let host = self.chatView.window ?? self.chatView
            view.frame = host.bounds
            host.addSubview(view)
            defer { view.releaseAll(); view.removeFromSuperview() }
            var voice = WYChatVoiceModel(duration: 10, voiceToText: "识别后的语音文本")
            voice.isPlaying = true
            view.dataSource = [WYChatMessageModel(messageID: "rate-api", sender: view.userInfo, content: WYChatMessageContentModel(voice: voice))]
            view.layoutIfNeeded()
            view.tableView.layoutIfNeeded()
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ value: Bool, _ detail: String = "") { checks.append(WYChatTestResult(name: name, passed: value, detail: detail, milliseconds: 0)) }
            @MainActor func descendants(_ view: UIView) -> [UIView] { [view] + view.subviews.flatMap { descendants($0) } }
            @MainActor func button() -> UIButton? { descendants(view.tableView).compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "WYChatVoice.rate.rate-api" } }
            check("voice-rate-menu-filter", button()?.menu?.children.count == 3 && button()?.isHidden == false)
            if let cell = view.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? WYChatBasicCell {
                let natural = cell.titleView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                check("voice-rate-duration-unclipped", cell.titleView.bounds.width + 1 >= natural.width && cell.titleView.bounds.height + 1 >= natural.height, "title=\(cell.titleView.frame), natural=\(natural), body=\(cell.bodyView.bounds), rate=\(String(describing: button()?.frame))")
            } else { check("voice-rate-duration-unclipped", false) }

            let snapshot = view.dataSource
            var requested: [Float] = []
            view.voicePlaybackRateHandler = { identifier, rate in if identifier == "rate-api" { requested.append(rate) } }
            let delegate = WYChatViewEventsFixture()
            view.delegate = delegate
            check("voice-rate-valid", view.setVoicePlaybackRate(1.5, messageID: "rate-api") && view.dataSource[0].content.voice?.playbackRate == 1.5)
            check("voice-rate-host-callback", requested == [1.5])
            check("voice-rate-delegate-callback", delegate.playbackRates == [1.5] && delegate.actions == 1)
            check("voice-rate-snapshot", snapshot[0].content.voice?.playbackRate == 1)
            check("voice-rate-preserves-playing", view.dataSource[0].content.voice?.isPlaying == true && view.dataSource[0].content.voice?.voiceToText == voice.voiceToText)
            check("voice-rate-duplicate-no-event", view.setVoicePlaybackRate(1.5, messageID: "rate-api") && requested == [1.5])
            check("voice-rate-invalid", !view.setVoicePlaybackRate(.nan, messageID: "rate-api") && !view.setVoicePlaybackRate(.infinity, messageID: "rate-api") && !view.setVoicePlaybackRate(0, messageID: "rate-api") && !view.setVoicePlaybackRate(1.25, messageID: "rate-api") && requested == [1.5])
            check("voice-rate-missing", !view.setVoicePlaybackRate(2, messageID: "missing"))
            view.eventsHandler = delegate
            delegate.allowAction = false
            check("voice-rate-veto", !view.setVoicePlaybackRate(2, messageID: "rate-api") && requested == [1.5])
            view.eventsHandler = nil
            view.dataSource[0].content.voice?.isPlaying = false
            view.tableView.layoutIfNeeded()
            check("voice-rate-stopped-hidden", button()?.isHidden != false)
            var always = view.configuration
            always.voicePlayback.showsOnlyWhilePlaying = false
            always.voicePlayback.size = CGSize(width: 68, height: 36)
            always.voicePlayback.font = .systemFont(ofSize: 19)
            view.configuration = always
            view.layoutIfNeeded()
            view.tableView.layoutIfNeeded()
            check("voice-rate-custom-layout", button()?.isHidden == false && abs((button()?.bounds.width ?? 0) - 68) < 1 && abs((button()?.bounds.height ?? 0) - 36) < 1)
            always.voicePlayback.showsRateControl = false
            view.configuration = always
            view.tableView.layoutIfNeeded()
            check("voice-rate-disabled-hidden", button()?.isHidden != false)
            view.dataSource[0].content = WYChatMessageContentModel(text: "替换为文本")
            check("voice-rate-nonvoice", !view.setVoicePlaybackRate(2, messageID: "rate-api"))
            for width: CGFloat in [320, 393, 768] {
                for factor: CGFloat in [1, 1.5] {
                    var layout = config
                    layout.content.titleFont = config.content.titleFont.withSize(config.content.titleFont.pointSize * factor)
                    layout.content.titleNumberOfLines = 0
                    view.configuration = layout
                    view.frame.size.width = width
                    view.dataSource = [WYChatMessageModel(messageID: "rate-api", sender: view.userInfo, content: WYChatMessageContentModel(voice: voice))]
                    view.layoutIfNeeded()
                    view.tableView.layoutIfNeeded()
                    if let cell = view.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? WYChatBasicCell {
                        let expected = cell.titleView.sizeThatFits(CGSize(width: cell.titleView.bounds.width, height: .greatestFiniteMagnitude))
                        let title = cell.titleView.convert(cell.titleView.bounds, to: cell.bodyView)
                        let rate = button().map { $0.convert($0.bounds, to: cell.bodyView) } ?? .zero
                        check("voice-rate-width-font-\(width)-\(factor)", cell.titleView.bounds.height + 1 >= expected.height && !rate.isEmpty && title.maxX <= rate.minX + 1 && cell.bodyView.bounds.insetBy(dx: -1, dy: -1).contains(rate), "title=\(title), rate=\(rate), expected=\(expected), body=\(cell.bodyView.bounds)")
                    } else { check("voice-rate-width-font-\(width)-\(factor)", false) }
                }
            }
            return checks
        })
        cases.append(WYChatTestCase("语音倍速真实菜单", group: "手势", explanation: "点击播放中的语音倍速按钮，选择2倍速并检查宿主回调及消息状态", requiresInteraction: true) { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController else { return [] }
            var presenter = root
            while let next = presenter.presentedViewController { presenter = next }
            let host = WYChatTestHostController()
            host.modalPresentationStyle = .fullScreen
            presenter.present(host, animated: false)
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            view.translatesAutoresizingMaskIntoConstraints = false
            host.view.addSubview(view)
            NSLayoutConstraint.activate([view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor), view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor), view.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor), view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor)])
            host.view.layoutIfNeeded()
            defer { view.releaseAll(); host.dismiss(animated: false) }
            var voice = WYChatVoiceModel(duration: 12)
            voice.isPlaying = true
            view.dataSource = [WYChatMessageModel(messageID: "rate-touch", sender: view.userInfo, content: WYChatMessageContentModel(voice: voice))]
            var received: Float?
            view.voicePlaybackRateHandler = { identifier, rate in if identifier == "rate-touch" { received = rate } }
            for _ in 0..<450 {
                if received != nil { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            return [WYChatTestResult(name: "voice-rate-real-menu", passed: received == 2 && view.dataSource[0].content.voice?.playbackRate == 2 && view.dataSource[0].content.voice?.isPlaying == true, detail: "", milliseconds: 0)]
        })
    }

    private func registerSelectionForwardCases() {
        cases.append(WYChatTestCase("合并记录明细真实操作", group: "手势", explanation: "点击合并卡片打开明细，核对原发送者、只读列表和关闭后返回", requiresInteraction: true) { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController else { return [] }
            var presenter = root
            while let next = presenter.presentedViewController { presenter = next }
            let host = WYChatTestHostController()
            host.modalPresentationStyle = .fullScreen
            presenter.present(host, animated: false)
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            view.translatesAutoresizingMaskIntoConstraints = false
            host.view.addSubview(view)
            NSLayoutConstraint.activate([view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor), view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor), view.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor), view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor)])
            host.view.layoutIfNeeded()
            defer { view.releaseAll(); host.dismiss(animated: false) }
            let author = WYChatUserModel(id: "records-touch-user", name: "记录发送者")
            let messages = (1...3).map { WYChatMessageModel(messageID: "records-touch-\($0)", sender: author, content: WYChatMessageContentModel(text: "记录中的消息\($0)")) }
            let records = WYChatRecordsModel(title: "测试合并记录", messages: messages, remarks: "三条原始消息")
            view.dataSource = [WYChatMessageModel(messageID: "records-touch-card", sender: view.userInfo, content: WYChatMessageContentModel(chatRecords: records))]
            var opened = false
            var readonly = false
            var closed = false
            for _ in 0..<450 {
                if let navigation = host.presentedViewController as? UINavigationController, let detail = navigation.viewControllers.first as? WYChatRecordsViewController {
                    opened = detail.chatView.dataSource == messages
                    readonly = detail.chatView.chatInput.isHidden && !detail.chatView.configuration.showsInputBar
                } else if opened { closed = true; break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            return [
                WYChatTestResult(name: "records-real-original-messages", passed: opened, detail: "", milliseconds: 0),
                WYChatTestResult(name: "records-real-readonly", passed: readonly, detail: "", milliseconds: 0),
                WYChatTestResult(name: "records-real-close", passed: closed, detail: "", milliseconds: 0)
            ]
        })
        cases.append(WYChatTestCase("区间选择与合并转发真实操作", group: "手势", explanation: "长按进入多选，再长按选择连续区间，通过工具条选择合并转发，检查宿主收到的顺序和原发送者", requiresInteraction: true) { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController else { return [] }
            var presenter = root
            while let next = presenter.presentedViewController { presenter = next }
            let host = WYChatTestHostController()
            host.modalPresentationStyle = .fullScreen
            presenter.present(host, animated: false)
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            view.translatesAutoresizingMaskIntoConstraints = false
            host.view.addSubview(view)
            NSLayoutConstraint.activate([view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor), view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor), view.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor), view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor)])
            host.view.layoutIfNeeded()
            defer { view.releaseAll(); host.dismiss(animated: false) }
            let author = WYChatUserModel(id: "range-touch-user", name: "原发送者")
            view.dataSource = (1...5).map { WYChatMessageModel(messageID: "range-touch-\($0)", sender: author, content: WYChatMessageContentModel(text: "区间消息\($0)")) }
            var mode: WYChatForwardMode?
            var received: [WYChatMessageModel] = []
            view.forwardHandler = { value, messages in mode = value; received = messages }
            for _ in 0..<450 {
                if mode != nil { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            return [
                WYChatTestResult(name: "selection-real-merged-mode", passed: mode == .merged, detail: "", milliseconds: 0),
                WYChatTestResult(name: "selection-real-range-order", passed: received.map(\.messageID) == ["range-touch-1", "range-touch-2", "range-touch-3", "range-touch-4"], detail: received.map(\.messageID).joined(separator: ","), milliseconds: 0),
                WYChatTestResult(name: "selection-real-original-authors", passed: received.allSatisfy { $0.sender == author } && !received.isEmpty, detail: "", milliseconds: 0),
                WYChatTestResult(name: "selection-real-exits-after-forward", passed: !view.isSelectingMessages && view.selectedMessageIDs.isEmpty && !view.chatInput.isHidden, detail: "", milliseconds: 0)
            ]
        })
        cases.append(WYChatTestCase("区间多选与转发快照", group: "功能", explanation: "检查正反向连续选择、选择上限、删除后同步、逐条转发、合并记录、顺序和快照隔离") { [weak self] in
            guard let self else { return [] }
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            config.selection.height = 90
            config.selection.font = .systemFont(ofSize: 23)
            config.selection.spacing = 6
            config.selection.insets = UIEdgeInsets(top: 5, left: 7, bottom: 9, right: 11)
            config.selection.indicatorSize = CGSize(width: 28, height: 22)
            config.selection.indicatorInsets = UIEdgeInsets(top: 2, left: 9, bottom: 4, right: 13)
            config.selection.selectedColor = .systemOrange
            config.selection.unselectedColor = .systemCyan
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            let host = self.chatView.window ?? self.chatView
            view.frame = host.bounds
            host.addSubview(view)
            defer { view.releaseAll(); view.removeFromSuperview() }
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ value: Bool, _ detail: String = "") { checks.append(WYChatTestResult(name: name, passed: value, detail: detail, milliseconds: 0)) }
            let author = WYChatUserModel(id: "forward-author", name: "原发送者")
            let sources = (0..<6).map { WYChatMessageModel(messageID: "forward-\($0)", sender: author, content: WYChatMessageContentModel(text: "消息\($0)")) }
            view.dataSource = sources
            check("selection-explicit", view.selectMessages(["forward-1", "forward-1"]) && view.selectedMessageIDs == ["forward-1"])
            check("selection-forward-range", view.selectMessages(from: "forward-1", through: "forward-3") && view.selectedMessageIDs == ["forward-1", "forward-2", "forward-3"])
            view.layoutIfNeeded()
            check("selection-toolbar-config", abs(view.selectionToolbar.bounds.height - 90) < 1 && view.selectionForwardButton.titleLabel?.font.pointSize == 23 && view.selectionToolbar.layoutMargins == config.selection.insets)
            check("selection-table-above-toolbar", abs(view.tableView.frame.maxY - view.selectionToolbar.frame.minY) < 1)
            view.tableView.layoutIfNeeded()
            let beforeCells = view.tableView.visibleCells.compactMap { $0 as? WYChatBasicCell }
            let beforeWidths = Dictionary(uniqueKeysWithValues: beforeCells.map { ($0.message.messageID, $0.bubblesView.bounds.width) })
            let indicators = beforeCells.compactMap { cell in cell.contentView.subviews.first { $0.accessibilityIdentifier == "WYChatSelection.indicator" } as? UIImageView }
            check("selection-indicator-size", !indicators.isEmpty && indicators.allSatisfy { !$0.isHidden && $0.bounds.size == config.selection.indicatorSize })
            check("selection-indicator-colors", indicators.contains { $0.tintColor == config.selection.selectedColor } && indicators.contains { $0.tintColor == config.selection.unselectedColor })
            check("selection-indicator-template", indicators.allSatisfy { $0.image?.renderingMode == .alwaysTemplate })
            _ = view.selectMessages(["forward-0"])
            view.tableView.layoutIfNeeded()
            check("selection-toggle-preserves-width", view.tableView.visibleCells.compactMap { $0 as? WYChatBasicCell }.allSatisfy { cell in beforeWidths[cell.message.messageID].map { abs($0 - cell.bubblesView.bounds.width) < 1 } ?? false })
            _ = view.selectMessages(["forward-1", "forward-2", "forward-3"])
            let before = view.selectedMessageIDs
            check("selection-invalid-atomic", !view.selectMessages(["forward-0", "missing"]) && view.selectedMessageIDs == before)
            check("selection-range-invalid-atomic", !view.selectMessages(from: "missing", through: "forward-4") && view.selectedMessageIDs == before)
            _ = view.selectMessages([])
            check("selection-reverse-range", view.selectMessages(from: "forward-4", through: "forward-2") && view.selectedMessageIDs == ["forward-2", "forward-3", "forward-4"])
            var limited = view.configuration
            limited.selection.maximumCount = 3
            view.configuration = limited
            check("selection-limit-atomic", !view.selectMessages(from: "forward-0", through: "forward-5") && view.selectedMessageIDs == ["forward-2", "forward-3", "forward-4"])
            limited.selection.allowsRangeSelection = false
            view.configuration = limited
            check("selection-range-disabled", !view.selectMessages(from: "forward-2", through: "forward-3"))
            let individual = view.makeForwardMessages(["forward-4", "forward-2", "forward-4"], mode: .individual)
            check("forward-individual-order", individual.map { $0.content.text ?? "" } == ["消息2", "消息4"])
            check("forward-fresh-identity", individual.allSatisfy { $0.sender.id == view.userInfo.id && $0.sendState == .sending && !sources.map(\.messageID).contains($0.messageID) } && Set(individual.map(\.messageID)).count == 2)
            check("forward-no-insertion-or-send", view.dataSource == sources)
            let merged = view.makeForwardMessages(["forward-4", "forward-2"], mode: .merged, title: "合并记录标题")
            check("forward-merged-authors-order", merged.count == 1 && merged.first?.content.chatRecords?.title == "合并记录标题" && merged.first?.content.chatRecords?.messages.map(\.messageID) == ["forward-2", "forward-4"] && merged.first?.content.chatRecords?.messages.first?.sender == author)
            check("forward-default-records-title", view.makeForwardMessages(["forward-1"], mode: .merged).first?.content.chatRecords?.title == config.selection.recordsTitle)
            if let records = merged.first?.content.chatRecords {
                let detail = WYChatRecordsViewController(records: records, userInfo: view.userInfo, configuration: config)
                detail.loadViewIfNeeded()
                detail.view.frame = host.bounds
                detail.view.layoutIfNeeded()
                detail.chatView.layoutIfNeeded()
                check("records-detail-original-messages", detail.chatView.dataSource == records.messages && detail.title == "合并记录标题")
                check("records-detail-readonly-layout", detail.chatView.chatInput.isHidden && abs(detail.chatView.tableView.frame.maxY - detail.chatView.bounds.height + detail.chatView.safeAreaInsets.bottom) < 1)
                check("records-detail-nicknames", detail.chatView.configuration.sender.showsSingleNickname && detail.chatView.configuration.receiver.showsSingleNickname)
                var hiddenNames = config
                hiddenNames.records.showsNicknames = false
                hiddenNames.records.titleFont = .systemFont(ofSize: 25)
                hiddenNames.records.closeText = "返回列表"
                detail.configuration = hiddenNames
                check("records-detail-configurable", !detail.chatView.configuration.sender.showsSingleNickname && (detail.navigationItem.titleView as? UILabel)?.font.pointSize == 25 && detail.closeButton.title == "返回列表")
                detail.records.messages[0].content.text = "明细修改"
                check("records-detail-snapshot-isolation", records.messages[0].content.text == "消息2")
                detail.chatView.releaseAll()
            }
            if let card = merged.first {
                view.appendMessages([card])
                var received: WYChatRecordsModel?
                view.recordsPreviewHandler = { received = $0 }
                view.previewRecords(card.messageID)
                check("records-host-preview", received == card.content.chatRecords)
                received = nil
                view.previewRecords("missing")
                check("records-invalid-no-callback", received == nil)
                view.dataSource.removeAll { $0.messageID == card.messageID }
            }

            check("forward-missing-rejected", view.makeForwardMessages(["forward-0", "missing"], mode: .merged).isEmpty)
            check("forward-empty-rejected", view.makeForwardMessages([], mode: .individual).isEmpty)
            view.dataSource[2].content.text = "已修改"
            check("forward-records-snapshot-isolation", merged.first?.content.chatRecords?.messages.first?.content.text == "消息2")
            view.dataSource.removeAll { $0.messageID == "forward-3" }
            check("selection-prunes-removed", view.selectedMessageIDs == ["forward-2", "forward-4"])
            view.forwardHandler = { _, _ in }
            check("forward-choice-menu", view.selectionForwardButton.showsMenuAsPrimaryAction && view.selectionForwardButton.menu?.children.count == 2)
            var noForward = view.configuration
            noForward.selection.forwardModes = []
            noForward.selection.showsDeleteButton = false
            view.configuration = noForward
            check("forward-disabled-config", !view.selectionForwardButton.isEnabled && view.selectionDeleteButton.isHidden)
            view.isSelectingMessages = false
            check("selection-exit-restores-input", view.selectedMessageIDs.isEmpty && view.selectionToolbar.isHidden && !view.chatInput.isHidden)
            return checks
        })
    }

    private func registerQuoteWithdrawalCases() {
        cases.append(WYChatTestCase("引用快照与撤回重编辑", group: "功能", explanation: "检查引用身份和快照、气泡外布局、宿主撤回确认、重新编辑时恢复引用/提及、取消引用和到期隐藏") { [weak self] in
            guard let self else { return [] }
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            let host = self.chatView.window ?? self.chatView
            view.frame = host.bounds
            host.addSubview(view)
            defer { view.inputViewResignFirstResponder(); view.releaseAll(); view.removeFromSuperview() }
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ value: Bool, _ detail: String = "") { checks.append(WYChatTestResult(name: name, passed: value, detail: detail, milliseconds: 0)) }
            let other = WYChatUserModel(id: "quote-person", name: "被引用用户")
            let now = Date()
            var source = WYChatMessageModel(messageID: "quote-origin", timestamp: String(now.timeIntervalSince1970 - 10), sender: other, content: WYChatMessageContentModel(text: "保留原始引用内容"))
            view.dataSource = [source]
            view.quoteMessage(source.messageID)
            view.layoutIfNeeded()
            check("quote-composer-snapshot", view.quotePreview.quote?.messageID == source.messageID && view.quotePreview.quote?.sender == other && !view.quotePreview.isHidden)
            let inputFrame = view.chatInput.convert(view.chatInput.bounds, to: view)
            let quoteFrame = view.quotePreview.convert(view.quotePreview.bounds, to: view)
            check("quote-composer-above-input", quoteFrame.height > 0 && quoteFrame.maxY <= inputFrame.minY && view.tableView.frame.maxY <= quoteFrame.minY)
            source.content.text = "源消息后来被更新"
            view.dataSource[0] = source
            check("quote-content-value-snapshot", view.quotePreview.quote?.content.text == "保留原始引用内容")
            let reply = view.sendMessage("带引用的回复", messageID: "quote-reply")
            check("quote-sent-identity", reply.reference?.messageID == source.messageID && reply.reference?.sender.id == other.id && reply.reference?.content.text == "保留原始引用内容" && view.quotedMessageID == nil)
            view.layoutIfNeeded()
            view.tableView.layoutIfNeeded()
            let path = IndexPath(row: 1, section: 0)
            let cell = view.tableView.cellForRow(at: path) as? WYChatBasicCell
            let bubble = cell.map { $0.bubblesView.convert($0.bubblesView.bounds, to: $0.contentView) } ?? .zero
            let reference = cell.map { $0.referenceView.convert($0.referenceView.bounds, to: $0.contentView) } ?? .zero
            check("quote-outside-bubble", cell != nil && reference.minY >= bubble.maxY && reference.height > 0 && reference.maxY <= (cell?.contentView.bounds.height ?? 0) + 1, "bubble=\(bubble), reference=\(reference), cell=\(String(describing: cell?.bounds))")
            var action: (WYChatAction, String)?
            view.actionHandler = { _, value, identifier in action = (value, identifier) }
            cell?.referenceView.tapHandler?()
            check("quote-navigation-target", action?.0 == .reference && action?.1 == source.messageID)
            check("withdraw-requires-valid-local-time", !view.canWithdrawMessage(reply.messageID, at: now.addingTimeInterval(1000)) && view.canWithdrawMessage(reply.messageID, at: now) && !view.canWithdrawMessage(source.messageID, at: now))
            cell?.actionHandler?(.withdraw, reply.messageID)
            check("withdraw-action-is-request", action?.0 == .withdraw && view.messageModelFrom(reply.messageID)?.content.text == reply.content.text)
            check("withdraw-host-confirmation", view.markMessageWithdrawn(reply.messageID, at: now) && view.messageModelFrom(reply.messageID)?.content.withdrawn?.originalText == reply.content.text && view.messageModelFrom(reply.messageID)?.reference == nil)
            check("withdraw-duplicate-ignored", !view.markMessageWithdrawn(reply.messageID) && !view.markMessageWithdrawn("missing"))
            check("reedit-window", view.canReeditMessage(reply.messageID, at: now) && !view.canReeditMessage(reply.messageID, at: now.addingTimeInterval(config.notice.reeditTimeLimit + 1)))
            check("reedit-restores-reference", view.reeditMessage(reply.messageID) && view.quotedMessageID == source.messageID && view.quotePreview.quote == reply.reference && view.chatInput.sharedEmojiAttributedText(attributed: view.chatInput.textView.attributedText).string == reply.content.text)
            view.quoteButton.sendActions(for: .touchUpInside)
            check("quote-close-button", view.quotedMessageID == nil && view.quotePreview.isHidden && view.quoteButton.isHidden)
            let canceled = view.sendMessage("取消引用后发送", messageID: "quote-canceled")
            check("quote-cancel-does-not-send-reference", canceled.reference == nil)
            _ = view.markMessageWithdrawn(canceled.messageID, at: now)
            view.quoteMessage(source.messageID)
            check("reedit-does-not-revive-canceled-quote", view.reeditMessage(canceled.messageID) && view.quotedMessageID == nil && view.quotePreview.isHidden)
            view.chatInput.textView.text = ""
            view.chatInput.textView.selectedRange = NSRange(location: 0, length: 0)
            view.chatInput.textViewDidChange(view.chatInput.textView, silence: false)
            _ = view.mentionUser(other)
            let mentionText = view.chatInput.sharedEmojiAttributedText(attributed: view.chatInput.textView.attributedText).string
            let mentioned = view.sendMessage(mentionText, messageID: "quote-mention")
            _ = view.markMessageWithdrawn(mentioned.messageID, at: now)
            check("reedit-restores-mention-identity", view.reeditMessage(mentioned.messageID) && view.inputMentions == mentioned.mentions && !view.inputMentions.isEmpty)
            check("receiver-withdrawal-does-not-preserve-editable-text", view.markMessageWithdrawn(source.messageID, at: now) && !view.canReeditMessage(source.messageID) && view.messageModelFrom(source.messageID)?.content.withdrawn?.originalText == nil)
            check("withdraw-updates-quoted-snapshots", view.messageModelFrom(reply.messageID)?.content.withdrawn?.reference?.content.withdrawn != nil)
            var pat = WYChatTakePatModel()
            pat.striking = view.userInfo
            pat.beaten = other
            let patMessage = WYChatMessageModel(messageID: "quote-pat", timestamp: String(now.timeIntervalSince1970 - 5), sender: view.userInfo, content: WYChatMessageContentModel(takePat: pat))
            view.appendMessages([patMessage])
            check("pat-withdrawal-permitted", view.canWithdrawMessage(patMessage.messageID, at: now))
            config.notice.allowsPatWithdrawal = false
            view.configuration = config
            check("pat-withdrawal-independent-switch", !view.canWithdrawMessage(patMessage.messageID, at: now))
            config.notice.allowsReedit = false
            view.configuration = config
            check("reedit-disabled", !view.canReeditMessage(reply.messageID) && !view.reeditMessage(reply.messageID))
            config.notice.allowsReedit = true
            config.notice.reeditTimeLimit = 0.8
            view.configuration = config
            let expiring = view.sendMessage("入口自动到期", messageID: "quote-expiring")
            _ = view.markMessageWithdrawn(expiring.messageID)
            view.scrollToLastMessage()
            view.tableView.layoutIfNeeded()
            let expirationPath = IndexPath(row: view.dataSource.count - 1, section: 0)
            let expiringCell = view.tableView.cellForRow(at: expirationPath) as? WYChatBasicCell
            let button = expiringCell?.bodyView.arrangedSubviews.compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "WYChatNotice.reedit" }
            check("reedit-button-visible-before-expiry", button?.isHidden == false)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            check("reedit-button-expires", !view.canReeditMessage(expiring.messageID) && button?.isHidden == true)
            let preview = WYChatQuoteView()
            host.addSubview(preview)
            defer { preview.removeFromSuperview() }
            var style = WYChatQuoteStyle()
            style.showsCloseButton = true
            style.textFont = .systemFont(ofSize: 28)
            style.maximumHeight = 0
            let longQuote = WYChatQuoteModel(messageID: "long-quote", sender: other, content: WYChatMessageContentModel(text: String(repeating: "引用布局检查，", count: 20)))
            for width: CGFloat in [320, 393, 768] {
                preview.update(quote: longQuote, style: style)
                preview.frame = CGRect(origin: .zero, size: preview.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)))
                preview.layoutIfNeeded()
                check("quote-preview-layout-\(Int(width))", preview.bounds.contains(preview.closeButton.frame) && preview.bounds.contains(preview.textView.frame) && !preview.titleView.frame.intersects(preview.textView.frame) && !preview.textView.frame.intersects(preview.closeButton.frame))
            }
            return checks
        })
        cases.append(WYChatTestCase("引用与重编辑真实操作", group: "手势", explanation: "点击消息引用，长按回复请求撤回，重新编辑后取消引用再发送，检查原生键盘与实际发送结果", requiresInteraction: true) { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController else { return [] }
            var presenter = root
            while let shown = presenter.presentedViewController { presenter = shown }
            let host = WYChatTestHostController()
            host.modalPresentationStyle = .fullScreen
            presenter.present(host, animated: false)
            var config = self.chatView.configuration
            config.input.draftStorageKey = ""
            config.input.showSpecialSendButton = true
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            view.translatesAutoresizingMaskIntoConstraints = false
            host.view.addSubview(view)
            NSLayoutConstraint.activate([view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor), view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor), view.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor), view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor)])
            host.view.layoutIfNeeded()
            defer { view.inputViewResignFirstResponder(); view.releaseAll(); host.dismiss(animated: false) }
            let source = WYChatMessageModel(messageID: "quote-touch-source", timestamp: String(Date().timeIntervalSince1970), sender: WYChatUserModel(id: "quote-touch-user", name: "引用联系人"), content: WYChatMessageContentModel(text: "被引用的消息"))
            view.dataSource = [source]
            view.quoteMessage(source.messageID)
            let reply = view.sendMessage("重新编辑的回复", messageID: "quote-touch-reply")
            var jumped = false
            var withdrew = false
            var restored = false
            var canceled = false
            var prepared: WYChatMessageModel?
            view.actionHandler = { [weak view] _, action, identifier in
                guard let view else { return }
                if action == .reference { jumped = identifier == source.messageID }
                if action == .withdraw && identifier == reply.messageID { withdrew = view.markMessageWithdrawn(identifier) }
                if action == .reedit { restored = view.quotedMessageID == source.messageID && view.chatInput.sharedEmojiAttributedText(attributed: view.chatInput.textView.attributedText).string == "重新编辑的回复" }
            }
            view.messagePreparedHandler = { prepared = $0 }
            view.layoutIfNeeded()
            view.tableView.layoutIfNeeded()
            for _ in 0..<450 {
                if restored && view.quotedMessageID == nil { canceled = true }
                if prepared != nil { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            return [
                WYChatTestResult(name: "quote-real-navigation", passed: jumped, detail: "", milliseconds: 0),
                WYChatTestResult(name: "quote-real-withdraw-request", passed: withdrew, detail: "", milliseconds: 0),
                WYChatTestResult(name: "quote-real-reedit-restores-reference", passed: restored, detail: "", milliseconds: 0),
                WYChatTestResult(name: "quote-real-cancel-before-send", passed: canceled && prepared?.reference == nil && prepared?.content.text == "重新编辑的回复", detail: "", milliseconds: 0)
            ]
        })
    }

    private func registerEmojiLimitCase() {
        cases.append(WYChatTestCase("最近表情数量边界", group: "配置", explanation: "检查负数、零、少于历史数量和大于历史数量时的显示，以及不同实例不会互相删减历史") {
            let key = UUID().uuidString
            let previous = UserDefaults.standard.object(forKey: key)
            defer {
                if let previous { UserDefaults.standard.set(previous, forKey: key) }
                else { UserDefaults.standard.removeObject(forKey: key) }
            }
            let history = ["[微笑]", "[憨笑]", "[偷笑]", "[害羞]", "[调皮]", "[流泪]"]
            UserDefaults.standard.set(history, forKey: key)
            var checks: [WYChatTestResult] = []
            for count in [-1, 0, 1, 3, 7, 100] {
                var config = WYEmojiViewConfig()
                config.recentlyCount = count
                config.recentlyStorageKey = key
                let view = WYChatEmojiView(config: config)
                let expected = Array(history.prefix(max(0, count)))
                checks.append(WYChatTestResult(name: "recentlyCount-\(count)", passed: view.recentlyEmoji == expected, detail: "actual=\(view.recentlyEmoji), expected=\(expected)", milliseconds: 0))
                checks.append(WYChatTestResult(name: "recently-storage-\(count)", passed: UserDefaults.standard.array(forKey: key) as? [String] == history, detail: "", milliseconds: 0))
            }
            var hidden = WYEmojiViewConfig()
            hidden.showRecently = false
            hidden.recentlyStorageKey = key
            let view = WYChatEmojiView(config: hidden)
            checks.append(WYChatTestResult(name: "showRecently-disabled", passed: view.recentlyEmoji.isEmpty, detail: "", milliseconds: 0))
            var limited = WYEmojiViewConfig()
            limited.recentlyCount = 3
            limited.recentlyStorageKey = key
            let limitedView = WYChatEmojiView(config: limited)
            let attachment = WYTextAttachment()
            attachment.imageName = history.last!
            limitedView.updateRecentlyEmoji(NSAttributedString(attachment: attachment))
            let updated = [history.last!] + history.dropLast()
            checks.append(WYChatTestResult(name: "recently-update-order", passed: limitedView.recentlyEmoji == Array(updated.prefix(3)) && limitedView.dataSource.first == Array(updated.prefix(3)), detail: "", milliseconds: 0))
            checks.append(WYChatTestResult(name: "recently-update-preserves-history", passed: UserDefaults.standard.array(forKey: key) as? [String] == updated, detail: "", milliseconds: 0))
            let otherKey = UUID().uuidString
            defer { UserDefaults.standard.removeObject(forKey: otherKey) }
            limited.recentlyStorageKey = otherKey
            let independent = WYChatEmojiView(config: limited)
            checks.append(WYChatTestResult(name: "recently-key-isolation", passed: independent.recentlyEmoji.isEmpty, detail: "", milliseconds: 0))
            independent.updateRecentlyEmoji(NSAttributedString(attachment: attachment))
            checks.append(WYChatTestResult(name: "recently-independent-update", passed: independent.recentlyEmoji == [history.last!] && UserDefaults.standard.array(forKey: key) as? [String] == updated, detail: "", milliseconds: 0))
            return checks
        })
    }

    private func registerReadingPositionCase() {
        cases.append(WYChatTestCase("历史消息与阅读位置", group: "功能", explanation: "检查插入历史、离开底部后收到消息、直接设置滚动位置、重复ID和宽度变化时实际可见消息的位置") { [weak self] in
            guard let self else { return [] }
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: self.chatView.configuration)
            let host = self.chatView.window ?? self.chatView
            view.frame = host.bounds
            host.addSubview(view)
            defer { view.releaseAll(); view.removeFromSuperview() }
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ value: Bool, _ detail: String = "") { checks.append(WYChatTestResult(name: name, passed: value, detail: detail, milliseconds: 0)) }
            let messages = (0..<200).map { index in WYChatMessageModel(messageID: "reading-\(index)", content: WYChatMessageContentModel(text: String(repeating: "阅读位置和可变高度检查，", count: index % 5 + 1))) }
            view.dataSource = messages
            view.layoutIfNeeded()
            view.tableView.scrollToRow(at: IndexPath(row: 80, section: 0), at: .middle, animated: false)
            view.tableView.layoutIfNeeded()
            guard let anchor = view.tableView.indexPathsForVisibleRows?.min() else { return [WYChatTestResult(name: "reading-anchor", passed: false, detail: "没有可见消息", milliseconds: 0)] }
            let identifier = view.dataSource[anchor.row].messageID
            let distance = view.tableView.rectForRow(at: anchor).minY - view.tableView.contentOffset.y
            let history = (0..<50).map { index in WYChatMessageModel(messageID: "history-\(index)", content: WYChatMessageContentModel(text: String(repeating: "历史内容，", count: index % 7 + 1))) }
            view.prependMessages(history)
            try? await Task.sleep(nanoseconds: 50_000_000)
            let path = IndexPath(row: anchor.row + history.count, section: 0)
            var actual = view.tableView.rectForRow(at: path).minY - view.tableView.contentOffset.y
            check("prepend-reading-anchor", view.dataSource[path.row].messageID == identifier && view.tableView.indexPathsForVisibleRows?.contains(path) == true && abs(actual - distance) < 1, "before=\(distance), after=\(actual)")
            view.appendMessages([WYChatMessageModel(messageID: "new-reading-message", content: WYChatMessageContentModel(text: "新的消息"))])
            try? await Task.sleep(nanoseconds: 50_000_000)
            actual = view.tableView.rectForRow(at: path).minY - view.tableView.contentOffset.y
            check("append-preserves-reading", abs(actual - distance) < 1 && view.tableView.indexPathsForVisibleRows?.contains(path) == true && !view.newMessagesButton.isHidden, "before=\(distance), after=\(actual)")
            let beforeManual = Set((view.tableView.indexPathsForVisibleRows ?? []).map { view.dataSource[$0.row].messageID })
            let beforeManualOffset = view.tableView.contentOffset
            let beforeManualSize = view.tableView.contentSize
            let offset = CGPoint(x: 0, y: max(0, view.tableView.contentOffset.y - view.tableView.bounds.height / 2))
            view.tableView.setContentOffset(offset, animated: false)
            view.tableView.layoutIfNeeded()
            let settledOffset = view.tableView.contentOffset
            try? await Task.sleep(nanoseconds: 50_000_000)
            check("manual-offset-stays", abs(view.tableView.contentOffset.y - settledOffset.y) < 1)
            let afterManual = Set((view.tableView.indexPathsForVisibleRows ?? []).map { view.dataSource[$0.row].messageID })
            check("manual-scroll-keeps-overlapping-messages", !beforeManual.isDisjoint(with: afterManual), "before=\(beforeManual.sorted()), after=\(afterManual.sorted()), beforeOffset=\(beforeManualOffset), requested=\(offset), settled=\(settledOffset), afterOffset=\(view.tableView.contentOffset), beforeSize=\(beforeManualSize), afterSize=\(view.tableView.contentSize), viewport=\(view.tableView.bounds.size)")
            for width: CGFloat in [320, 393, 768] {
                view.tableView.layoutIfNeeded()
                let before = (view.tableView.visibleCells.first as? WYChatBasicCell)?.message.messageID
                view.frame.size.width = width
                view.setNeedsLayout()
                view.layoutIfNeeded()
                try? await Task.sleep(nanoseconds: 50_000_000)
                check("resize-reading-\(Int(width))", before != nil && view.tableView.visibleCells.contains { ($0 as? WYChatBasicCell)?.message.messageID == before }, "anchor=\(before ?? ""), visible=\(view.tableView.indexPathsForVisibleRows?.map(\.row) ?? [])")
            }
            view.scrollToLastMessage()
            view.tableView.layoutIfNeeded()
            try? await Task.sleep(nanoseconds: 50_000_000)
            let tail = IndexPath(row: view.dataSource.count - 1, section: 0)
            for _ in 0..<20 {
                if view.tableView.indexPathsForVisibleRows?.contains(tail) == true && view.newMessagesButton.isHidden { break }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
            check("resize-then-scroll-to-bottom", view.tableView.indexPathsForVisibleRows?.contains(tail) == true && view.newMessagesButton.isHidden, "offset=\(view.tableView.contentOffset), size=\(view.tableView.contentSize), bounds=\(view.tableView.bounds), rows=\(view.tableView.indexPathsForVisibleRows?.map(\.row) ?? []), indicatorHidden=\(view.newMessagesButton.isHidden)")
            view.tableView.scrollToRow(at: IndexPath(row: 60, section: 0), at: .top, animated: false)
            view.tableView.layoutIfNeeded()
            view.scrollToLastMessage(true)
            for _ in 0..<30 {
                try? await Task.sleep(nanoseconds: 50_000_000)
                if view.tableView.indexPathsForVisibleRows?.contains(tail) == true { break }
            }
            check("animated-scroll-to-bottom", view.tableView.indexPathsForVisibleRows?.contains(tail) == true && view.newMessagesButton.isHidden)
            view.frame.size.width = 393
            view.dataSource = messages
            view.layoutIfNeeded()
            view.tableView.scrollToRow(at: IndexPath(row: 80, section: 0), at: .middle, animated: false)
            view.tableView.layoutIfNeeded()
            for iteration in 0..<8 {
                guard let visible = view.tableView.indexPathsForVisibleRows?.min() else { check("prepend-repeat-visible-\(iteration)", false); break }
                let identifier = view.dataSource[visible.row].messageID
                let distance = view.tableView.rectForRow(at: visible).minY - view.tableView.contentOffset.y
                let additions = (0..<3).map { WYChatMessageModel(messageID: "repeat-history-\(iteration)-\($0)", content: WYChatMessageContentModel(text: String(repeating: "Earlier message ", count: iteration + 1))) }
                view.prependMessages(additions)
                try? await Task.sleep(nanoseconds: 50_000_000)
                let updated = IndexPath(row: visible.row + additions.count, section: 0)
                let actual = view.tableView.rectForRow(at: updated).minY - view.tableView.contentOffset.y
                check("prepend-repeat-anchor-\(iteration)", view.dataSource[updated.row].messageID == identifier && view.tableView.indexPathsForVisibleRows?.contains(updated) == true && abs(actual - distance) < 1, "before=\(distance), after=\(actual), offset=\(view.tableView.contentOffset), row=\(updated.row), rect=\(view.tableView.rectForRow(at: updated)), visible=\(view.tableView.indexPathsForVisibleRows?.map(\.row) ?? [])")
            }
            var duplicate = WYChatMessageModel(messageID: "same", content: WYChatMessageContentModel(text: "重复ID第一条"))
            view.dataSource = [duplicate, duplicate]
            duplicate.content.text = "重复ID第二条已更新"
            view.dataSource[1] = duplicate
            view.scrollToLastMessage()
            view.tableView.layoutIfNeeded()
            let second = view.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? WYChatTextCell
            check("duplicate-id-update", view.tableView.numberOfRows(inSection: 0) == 2 && second?.textView.text == duplicate.content.text)
            return checks
        })
    }

    private func registerRecordingActionStyles() {
        cases.append(WYChatTestCase("录音操作双样式", group: "录音", explanation: "切换圆形与弧形按钮，检查普通/选中状态、尺寸、颜色、文案、配置刷新和不同宽度下的滑入操作") { [weak self] in
            guard let self else { return [] }
            var config = WYRecordAnimationConfig()
            config.supportSpeechRecognition = true
            let view = WYMoveUpTipsView(tipsState: .cancel, configuration: config)
            view.translatesAutoresizingMaskIntoConstraints = false
            self.chatView.addSubview(view)
            NSLayoutConstraint.activate([view.leadingAnchor.constraint(equalTo: self.chatView.leadingAnchor), view.topAnchor.constraint(equalTo: self.chatView.safeAreaLayoutGuide.topAnchor)])
            defer { view.removeFromSuperview() }
            var checks: [WYChatTestResult] = [WYChatTestResult(name: "initial-style", passed: view.moveUpView.currentBackgroundImage == nil && view.moveUpView.backgroundColor == config.curvedActionColors.normal, detail: "", milliseconds: 0)]
            for style in [WYRecordingActionStyle.circular, .curved, .circular] {
                config.actionStyle = style
                config.cancelRecordViewText.onInterior = "停止采集"
                view.recordAnimationConfig = config
                for touched in [false, true] {
                    view.refresh(tipsState: .cancel, isTouched: touched)
                    self.chatView.layoutIfNeeded()
                    view.layoutIfNeeded()
                    let size = style == .curved ? config.curvedActionSize : CGSize(width: touched ? config.moveUpButtonDiameter.onInterior : config.moveUpButtonDiameter.onExternal, height: touched ? config.moveUpButtonDiameter.onInterior : config.moveUpButtonDiameter.onExternal)
                    let actual = view.moveUpView.bounds.size
                    checks.append(WYChatTestResult(name: "size-\(style.rawValue)-\(touched)", passed: abs(actual.width - size.width) < 1 && abs(actual.height - size.height) < 1, detail: "actual=\(actual), expected=\(size)", milliseconds: 0))
                    let background = style == .curved ? view.moveUpView.currentBackgroundImage == nil && view.moveUpView.backgroundColor == (touched ? config.curvedActionColors.selected : config.curvedActionColors.normal) : view.moveUpView.currentBackgroundImage != nil
                    checks.append(WYChatTestResult(name: "appearance-\(style.rawValue)-\(touched)", passed: background && view.moveUpView.currentTitle == "停止采集" && view.moveUpView.isSelected == touched, detail: "", milliseconds: 0))
                }
            }
            config.actionStyle = .curved
            for bend: CGFloat in [0, 18, -1, .infinity] {
                config.curvedActionBendHeight = bend
                view.recordAnimationConfig = config
                view.refresh(tipsState: .cancel, isTouched: false)
                self.chatView.layoutIfNeeded()
                view.layoutIfNeeded()
                let shape = (view.moveUpView.layer.mask as? CAShapeLayer)?.path
                let frame = shape?.boundingBoxOfPath ?? .null
                checks.append(WYChatTestResult(name: "curved-action-path-\(bend)", passed: shape != nil && !frame.isNull && frame.minY >= -1 && frame.maxY <= view.moveUpView.bounds.height + 1, detail: "path=\(frame)", milliseconds: 0))
                if bend == 18, let shape {
                    let width = view.moveUpView.bounds.width
                    checks.append(WYChatTestResult(name: "curved-action-real-bend", passed: shape.contains(CGPoint(x: width / 2, y: 2)) && !shape.contains(CGPoint(x: width / 5, y: 2)), detail: "", milliseconds: 0))
                }
            }
            config.curvedActionBendHeight = WYRecordAnimationConfig().curvedActionBendHeight
            let recorder: WYChatRecordingFixture
            do { recorder = try WYChatRecordingFixture() }
            catch { return checks + [WYChatTestResult(name: "action-audio-fixture", passed: false, detail: error.localizedDescription, milliseconds: 0)] }
            defer { try? FileManager.default.removeItem(at: recorder.url) }
            config.cancelRecordViewText = WYRecordAnimationConfig().cancelRecordViewText
            config.recorder = recorder
            config.speechRecognitionSource = .external
            config.speechRecognitionProvider = WYChatRecognitionFixture()
            let overlay = WYRecordAnimationView(alpha: 0, configuration: config)
            let host = self.chatView.window ?? self.chatView
            overlay.frame = host.bounds
            host.addSubview(overlay)
            defer { overlay.endRecordVoice(); overlay.removeFromSuperview() }
            let imageDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("ChatView-VisualResults", isDirectory: true)
            try? FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
            for style in [WYRecordingActionStyle.circular, .curved] {
                for recognition in [true, false] {
                    overlay.recordAnimationConfig.actionStyle = style
                    overlay.recordAnimationConfig.supportSpeechRecognition = recognition
                    overlay.start()
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    if !recognition {
                        let bubble = overlay.subviews.compactMap { $0 as? WYSoundAnimationView }.first
                        checks.append(WYChatTestResult(name: "disabled-recognition-clears-text-\(style.rawValue)", passed: bubble?.textView.isHidden == true && bubble?.textView.text.isEmpty == true, detail: "", milliseconds: 0))
                    }
                    for width: CGFloat in [320, 393, 768] {
                        overlay.frame.size.width = width
                        overlay.setNeedsLayout()
                        overlay.layoutIfNeeded()
                        let targets: [(WYSoundAnimationStatus, String)] = recognition ? [(.cancel, config.cancelRecordViewText.onInterior), (.transfer, config.transferViewText.onInterior)] : [(.cancel, config.cancelRecordViewText.onInterior)]
                        for (status, title) in targets {
                            let target = overlay.subviews.compactMap { $0 as? WYMoveUpTipsView }.first { $0.moveUpView.currentTitle == title }
                            var visibleCenter = false
                            if let target {
                                let button = target.moveUpView
                                let point = button.convert(CGPoint(x: button.bounds.midX, y: button.bounds.midY), to: overlay)
                                visibleCenter = overlay.bounds.contains(point)
                                overlay.switchStatus(point)
                            }
                            checks.append(WYChatTestResult(name: "gesture-target-\(style.rawValue)-\(recognition)-\(Int(width))-\(status.rawValue)", passed: visibleCenter && overlay.soundAnimationStatus == status, detail: "", milliseconds: 0))
                        }
                        if style == .curved && recognition {
                            overlay.layoutIfNeeded()
                            for target in overlay.subviews.compactMap({ $0 as? WYMoveUpTipsView }) {
                                if let label = target.moveUpView.titleLabel {
                                    let text = label.textRect(forBounds: label.bounds, limitedToNumberOfLines: label.numberOfLines)
                                    let needed = (label.text ?? "").size(withAttributes: [.font: label.font as Any])
                                    checks.append(WYChatTestResult(name: "curved-title-complete-\(Int(width))-\(target.moveUpView.isSelected)", passed: label.bounds.width + 1 >= needed.width && label.bounds.height + 1 >= needed.height, detail: "bounds=\(label.bounds), needed=\(needed), text=\(label.text ?? "")", milliseconds: 0))
                                    let frame = label.convert(text, to: overlay)
                                    checks.append(WYChatTestResult(name: "curved-title-visible-\(Int(width))-\(target.moveUpView.isSelected)", passed: frame.minX >= -1 && frame.maxX <= overlay.bounds.width + 1, detail: "text=\(frame), width=\(overlay.bounds.width)", milliseconds: 0))
                                }
                            }
                        }
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        overlay.layoutIfNeeded()
                        if recognition, let bubble = overlay.subviews.compactMap({ $0 as? WYSoundAnimationView }).first {
                            let wave = bubble.soundWavesView.frame
                            let arrow = bubble.showsArrow && bubble.arrowDirection == .bottom ? bubble.arrowSize.height : 0
                            let x = bubble.bounds.width - config.soundWavesRightOffsetForAirBubble.x
                            let y = bubble.bounds.height - arrow - config.soundWavesRightOffsetForAirBubble.y
                            checks.append(WYChatTestResult(name: "live-wave-bottom-right-\(style.rawValue)-\(Int(width))", passed: abs(wave.maxX - x) < 1 && abs(wave.maxY - y) < 1 && bubble.textView.frame.maxY + config.liveTextWaveformSpacing <= wave.minY + 1, detail: "wave=\(wave), text=\(bubble.textView.frame)", milliseconds: 0))
                        }
                        if style == .curved {
                            let hint = overlay.subviews.compactMap { $0 as? UILabel }.first { $0.accessibilityIdentifier == "WYChatRecording.hint" }
                            let bubble = overlay.subviews.compactMap { $0 as? WYSoundAnimationView }.first
                            let wanted = recognition ? config.transferViewText.tips : config.cancelRecordViewText.tips
                            checks.append(WYChatTestResult(name: "curved-hint-below-bubble-\(recognition)-\(Int(width))", passed: hint?.isHidden == false && hint?.text == wanted && abs((hint?.frame.minY ?? 0) - (bubble?.frame.maxY ?? 0) - config.recordingHintSpacing) < 1 && overlay.backgroundColor == config.overlayBackgroundColor, detail: "hint=\(String(describing: hint?.frame)), bubble=\(String(describing: bubble?.frame))", milliseconds: 0))
                        }
                        let image = UIGraphicsImageRenderer(bounds: overlay.bounds).image { _ in overlay.drawHierarchy(in: overlay.bounds, afterScreenUpdates: true) }
                        let url = imageDirectory.appendingPathComponent("recording-\(style.rawValue)-speech-\(recognition)-width-\(Int(width)).png")
                        try? image.pngData()?.write(to: url)
                    }
                    overlay.endRecordVoice()
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
            }
            overlay.recordAnimationConfig.supportSpeechRecognition = true
            overlay.recordAnimationConfig.speechRecognitionMode = .afterRecording
            overlay.start()
            try? await Task.sleep(nanoseconds: 300_000_000)
            let fileBubble = overlay.subviews.compactMap { $0 as? WYSoundAnimationView }.first
            checks.append(WYChatTestResult(name: "file-recognition-clears-live-text", passed: fileBubble?.textView.isHidden == true && fileBubble?.textView.text.isEmpty == true, detail: "", milliseconds: 0))
            return checks
        })
    }

    private func registerBrowserStackCases() {
        cases.append(WYChatTestCase("PhotoBrowser叠卡模式", group: "媒体", explanation: "直接使用原图片浏览器检查叠卡、当前页、空数据、越界、层数和双向布局，不提供展开收起控件") { [weak self] in
            guard let self else { return [] }
            let source = WYChatBrowserStackFixture()
            var config = WYPhotoBrowserConfiguration()
            config.layoutStyle = .stackedCards
            config.isEmbedded = true
            config.pageIndicatorStyle = .none
            config.appearance.backgroundColor = .clear
            let browser = WYPhotoBrowser(configuration: config)
            browser.dataSource = source
            browser.browserDelegate = source
            browser.view.frame = CGRect(x: 0, y: 0, width: 280, height: 330)
            let host = self.chatView.window ?? self.chatView
            host.addSubview(browser.view)
            defer { browser.view.removeFromSuperview() }
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ value: Bool, _ detail: String = "") { checks.append(WYChatTestResult(name: name, passed: value, detail: detail, milliseconds: 0)) }
            @MainActor func descendants(_ view: UIView) -> [UIView] { view.subviews.flatMap { [$0] + descendants($0) } }
            browser.view.setNeedsLayout()
            browser.view.layoutIfNeeded()
            guard let collection = descendants(browser.view).compactMap({ $0 as? UICollectionView }).first else { return [WYChatTestResult(name: "browser-stack-collection", passed: false, detail: "", milliseconds: 0)] }
            for size in [CGSize(width: 240, height: 280), CGSize(width: 320, height: 390), CGSize(width: 768, height: 600)] {
                browser.view.frame.size = size
                browser.view.setNeedsLayout()
                browser.view.layoutIfNeeded()
                browser.currentIndex = 2
                collection.layoutIfNeeded()
                let attributes = (2...4).compactMap { collection.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: $0, section: 0)) }
                check("browser-stack-layers-\(Int(size.width))", attributes.count == 3 && attributes.allSatisfy { !$0.isHidden && $0.alpha > 0 } && attributes[0].zIndex > attributes[1].zIndex && attributes[1].zIndex > attributes[2].zIndex)
                let rendered = collection.cellForItem(at: IndexPath(item: 3, section: 0))
                check("browser-stack-rendered-rotation-\(Int(size.width))", rendered != nil && rendered?.transform == attributes.dropFirst().first?.transform, "rendered=\(String(describing: rendered?.transform)), expected=\(String(describing: attributes.dropFirst().first?.transform))")
                check("browser-stack-source-\(Int(size.width))", (browser.sourceView(at: 2) as? UIImageView)?.image != nil && browser.currentIndex == 2)
                let origin = collection.contentOffset
                collection.setContentOffset(CGPoint(x: origin.x + size.width * 0.35, y: origin.y), animated: false)
                collection.layoutIfNeeded()
                let front = collection.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: 2, section: 0))
                let next = collection.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: 3, section: 0))
                check("browser-stack-moving-\(Int(size.width))", front != nil && next != nil && (front?.transform.isIdentity == false) && (front?.center.x ?? 0) < (next?.center.x ?? 0))
                browser.currentIndex = 0
                collection.layoutIfNeeded()
            }
            let expand = WYLocalized("展开", table: WYBasisKitConfig.kitLocalizableTable)
            let collapse = WYLocalized("收起", table: WYBasisKitConfig.kitLocalizableTable)
            check("browser-has-no-fold-controls", !descendants(browser.view).compactMap { $0 as? UIButton }.contains { $0.currentTitle == expand || $0.currentTitle == collapse })
            let validIndex = browser.currentIndex
            browser.currentIndex = Int.max
            check("browser-stack-ignores-invalid-index", browser.currentIndex == validIndex)
            source.items = []
            browser.reloadData()
            browser.view.layoutIfNeeded()
            check("browser-stack-empty", collection.numberOfItems(inSection: 0) == 0 && browser.sourceView(at: 0) == nil)
            let styles: [(WYPhotoBrowserLayoutStyle, WYPhotoBrowserTransformStyle)] = [(.fullPage, .none), (.multiPage, .none), (.multiPage, .scale), (.multiPage, .depth), (.multiPage, .accordion), (.multiPage, .stack), (.multiPage, .overlap), (.stackedCards, .none)]
            for (style, effect) in styles {
                for direction: WYPhotoBrowserScrollDirection in [.horizontal, .vertical] {
                    for loops in [false, true] {
                        let fixture = WYChatBrowserStackFixture()
                        var value = config
                        value.layoutStyle = style
                        value.transformStyle = effect
                        value.scrollDirection = direction
                        value.allowsLoopScrolling = loops
                        value.stackedCardCount = loops ? 2 : 1
                        let candidate = WYPhotoBrowser(configuration: value)
                        candidate.dataSource = fixture
                        candidate.browserDelegate = fixture
                        candidate.view.frame = CGRect(x: 0, y: 0, width: 280, height: 330)
                        host.addSubview(candidate.view)
                        candidate.view.layoutIfNeeded()
                        candidate.currentIndex = 3
                        let key = "\(style.rawValue)-\(effect.rawValue)-\(direction.rawValue)-\(loops)"
                        check("browser-mode-source-" + key, candidate.currentIndex == 3 && (candidate.sourceView(at: 3) as? UIImageView)?.image != nil)
                        check("browser-mode-callback-" + key, fixture.shown == [3])
                        if style == .fullPage {
                            candidate.scrollToItem(at: 4, animated: true)
                            try? await Task.sleep(nanoseconds: 800_000_000)
                            check("browser-animated-page-" + key, candidate.currentIndex == 4 && fixture.shown == [3, 4])
                        }
                        candidate.view.removeFromSuperview()
                    }
                }
            }
            return checks
        })
        cases.append(WYChatTestCase("PhotoBrowser叠卡真实滑动", group: "媒体", explanation: "在叠卡上向左、向右各滑动一次，再点击当前图片，检查页码和点击回调", requiresInteraction: true) { [weak self] in
            guard let self else { return [] }
            let source = WYChatBrowserStackFixture()
            var config = WYPhotoBrowserConfiguration()
            config.layoutStyle = .stackedCards
            config.isEmbedded = true
            config.pageIndicatorStyle = .none
            config.appearance.backgroundColor = .systemGroupedBackground
            let browser = WYPhotoBrowser(configuration: config)
            browser.dataSource = source
            browser.browserDelegate = source
            let host = self.chatView.window ?? self.chatView
            browser.view.frame = host.bounds.insetBy(dx: 20, dy: 130)
            browser.view.accessibilityIdentifier = "WYChatTests.browserStackHost"
            host.addSubview(browser.view)
            defer { browser.view.removeFromSuperview() }
            browser.view.layoutIfNeeded()
            for _ in 0..<250 {
                if source.taps > 0 { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            let movedForward = source.shown.contains { $0 > 0 }
            let valid = movedForward && browser.currentIndex == 0 && source.taps > 0
            return [WYChatTestResult(name: "browser-stack-real-swipes", passed: valid, detail: "shown=\(source.shown), index=\(browser.currentIndex), taps=\(source.taps)", milliseconds: 0)]
        })
        cases.append(WYChatTestCase("叠卡连续双向循环", group: "媒体", explanation: "连续向左向右划走顶图，检查循环顺序和叠层完整性", requiresInteraction: true) { [weak self] in
            guard let self else { return [] }
            let source = WYChatBrowserStackFixture()
            var config = WYPhotoBrowserConfiguration()
            config.layoutStyle = .stackedCards
            config.allowsLoopScrolling = true
            config.stackedCardCyclesForward = true
            config.isEmbedded = true
            config.pageIndicatorStyle = .none
            config.appearance.backgroundColor = .systemGroupedBackground
            let browser = WYPhotoBrowser(configuration: config)
            browser.dataSource = source
            browser.browserDelegate = source
            let host = self.chatView.window ?? self.chatView
            browser.view.frame = host.bounds.insetBy(dx: 20, dy: 130)
            browser.view.accessibilityIdentifier = "WYChatTests.browserStackHost"
            host.addSubview(browser.view)
            defer { browser.view.removeFromSuperview() }
            browser.view.layoutIfNeeded()
            @MainActor func descendants(_ view: UIView) -> [UIView] { view.subviews.flatMap { [$0] + descendants($0) } }
            let collection = descendants(browser.view).compactMap { $0 as? UICollectionView }.first
            var correctImages = true
            var fullDepth = true
            var inspected = Set<Int>()
            for _ in 0..<900 {
                if let collection, !collection.isDragging, !collection.isDecelerating {
                    collection.layoutIfNeeded()
                    let index = browser.currentIndex
                    let actual = (browser.sourceView(at: index) as? UIImageView)?.image?.pngData()
                    correctImages = correctImages && actual != nil && actual == source.items[index].placeholder?.pngData()
                    let attributes = collection.collectionViewLayout.layoutAttributesForElements(in: collection.bounds) ?? []
                    fullDepth = fullDepth && attributes.filter { !$0.isHidden && $0.alpha > 0.99 }.count == config.stackedCardCount
                    inspected.insert(index)
                }
                if source.taps > 0 { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            let movedForward = source.shown == Array(1...5) + [0] + Array(1...5) + [0]
            let valid = movedForward && browser.currentIndex == 0 && source.taps > 0 && correctImages && fullDepth && inspected.count == source.items.count
            return [WYChatTestResult(name: "browser-stack-real-swipes", passed: valid, detail: "shown=\(source.shown), index=\(browser.currentIndex), taps=\(source.taps), images=\(correctImages), depth=\(fullDepth), inspected=\(inspected.sorted())", milliseconds: 0)]
        })
    }

    private func registerMediaGestureCase() {
        cases.append(WYChatTestCase("聊天媒体真实预览手势", group: "媒体", explanation: "在消息叠卡上左右滑动并打开预览，切换视频并点击播放，再返回照片双击缩放和下滑关闭", requiresInteraction: true) { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController else { return [] }
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true); try await WYChatVideoFixture.write(to: folder.appendingPathComponent("sample.mp4")) }
            catch { return [WYChatTestResult(name: "media-gesture-fixture", passed: false, detail: error.localizedDescription, milliseconds: 0)] }
            defer { try? FileManager.default.removeItem(at: folder) }
            var items: [WYChatMediaItem] = []
            for index in 0..<3 {
                let image = UIGraphicsImageRenderer(size: CGSize(width: 240, height: 280)).image { context in
                    [UIColor.systemIndigo, .systemOrange, .systemTeal][index].setFill()
                    context.fill(CGRect(x: 0, y: 0, width: 240, height: 280))
                    NSString(string: String(index + 1)).draw(at: CGPoint(x: 90, y: 100), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 50), .foregroundColor: UIColor.white])
                }
                let cover = folder.appendingPathComponent("cover-\(index).png")
                try? image.pngData()?.write(to: cover)
                var item = WYChatMediaItem()
                item.size = image.size
                item.thumbnail.localPath = cover.path
                item.original = item.thumbnail
                if index == 1 { item.kind = .video; item.original.localPath = folder.appendingPathComponent("sample.mp4").path; item.duration = 4 }
                items.append(item)
            }
            var presenter = root
            while let shown = presenter.presentedViewController { presenter = shown }
            let host = WYChatTestHostController()
            host.modalPresentationStyle = .fullScreen
            presenter.present(host, animated: false)
            try? await Task.sleep(nanoseconds: 150_000_000)
            var config = self.chatView.configuration
            config.media.presentation = .merged
            config.media.automaticallyPresentsBrowser = true
            host.view.accessibilityIdentifier = "WYChatTests.mediaGestureHost"
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            host.view.addSubview(view)
            view.frame = host.view.bounds
            defer { view.releaseAll(); host.dismiss(animated: false) }
            let identifier = view.sendMedia(items).first?.messageID ?? ""
            view.layoutIfNeeded()
            view.tableView.layoutIfNeeded()
            @MainActor func descendants(_ view: UIView) -> [UIView] { view.subviews.flatMap { [$0] + descendants($0) } }
            for collection in descendants(view).compactMap({ $0 as? UICollectionView }) {
                collection.isAccessibilityElement = true
            }
            var seenPages = Set<Int>()
            var didPlay = false
            var didZoom = false
            var didDismiss = false
            var hasOpened = false
            var playerClosed = false
            var playbackStartedAt: Date?
            for _ in 0..<450 {
                if let browser = host.presentedViewController as? WYPhotoBrowser {
                    hasOpened = true
                    seenPages.insert(browser.currentIndex)
                    didZoom = didZoom || descendants(browser.view).compactMap { $0 as? UIScrollView }.contains { $0.zoomScale > 1.1 }
                    if let controller = browser.presentedViewController as? AVPlayerViewController {
                        if controller.player?.currentItem?.status == .readyToPlay && (controller.player?.currentTime().seconds ?? 0) > 0 {
                            didPlay = true
                            if playbackStartedAt == nil { playbackStartedAt = Date() }
                        }
                        if !playerClosed, let started = playbackStartedAt, Date().timeIntervalSince(started) > 3 {
                            controller.player?.pause()
                            controller.dismiss(animated: false)
                            playerClosed = true
                        }
                    }
                } else if hasOpened { didDismiss = true; break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            let index = view.messageModelFrom(identifier)?.content.mediaGroup?.visibleIndex
            return [
                WYChatTestResult(name: "media-gesture-preview-pages", passed: seenPages.isSuperset(of: [0, 1, 2]), detail: "pages=\(seenPages.sorted())", milliseconds: 0),
                WYChatTestResult(name: "media-gesture-video-play", passed: didPlay, detail: "", milliseconds: 0),
                WYChatTestResult(name: "media-gesture-photo-zoom", passed: didZoom, detail: "", milliseconds: 0),
                WYChatTestResult(name: "media-gesture-drag-dismiss", passed: didDismiss, detail: "", milliseconds: 0),
                WYChatTestResult(name: "media-gesture-page-model", passed: index == 2, detail: "index=\(index ?? -1)", milliseconds: 0)
            ]
        })
    }

    private func registerMediaPlaybackCase() {
        cases.append(WYChatTestCase("混合媒体全屏与视频播放", group: "媒体", explanation: "生成本地视频，检查照片和视频预览、转场来源、封面播放、真实解码和播放后返回") { [weak self] in
            guard let self, let root = self.chatView.window?.rootViewController else { return [] }
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
            catch { return [WYChatTestResult(name: "media-playback-fixture", passed: false, detail: error.localizedDescription, milliseconds: 0)] }
            defer { try? FileManager.default.removeItem(at: folder) }
            let movie = folder.appendingPathComponent("sample.mp4")
            do { try await WYChatVideoFixture.write(to: movie) }
            catch { return [WYChatTestResult(name: "media-video-encoding", passed: false, detail: error.localizedDescription, milliseconds: 0)] }
            let image = UIGraphicsImageRenderer(size: CGSize(width: 240, height: 180)).image { context in
                UIColor.systemIndigo.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 240, height: 180))
            }
            let cover = folder.appendingPathComponent("cover.png")
            try? image.pngData()?.write(to: cover)
            var photo = WYChatMediaItem()
            photo.original.localPath = cover.path
            photo.thumbnail = photo.original
            photo.size = image.size
            var video = photo
            video.id = UUID().uuidString
            video.kind = .video
            video.original.localPath = movie.path
            video.duration = 4
            var presenter = root
            while let shown = presenter.presentedViewController { presenter = shown }
            let host = WYChatTestHostController()
            host.modalPresentationStyle = .fullScreen
            presenter.present(host, animated: false)
            try? await Task.sleep(nanoseconds: 150_000_000)
            var config = self.chatView.configuration
            config.media.presentation = .merged
            config.media.automaticallyPresentsBrowser = true
            config.media.browser.isEmbedded = true
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            view.frame = host.view.bounds
            host.view.addSubview(view)
            defer { view.releaseAll(); host.dismiss(animated: false) }
            let messages = view.sendMedia([photo, video, photo])
            view.layoutIfNeeded()
            view.tableView.layoutIfNeeded()
            guard let identifier = messages.first?.messageID else { return [] }
            view.previewMedia(messageID: identifier, index: 0)
            try? await Task.sleep(nanoseconds: 500_000_000)
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ value: Bool, _ detail: String = "") { checks.append(WYChatTestResult(name: name, passed: value, detail: detail, milliseconds: 0)) }
            guard let browser = host.presentedViewController as? WYPhotoBrowser else {
                return [WYChatTestResult(name: "media-fullscreen-presentation", passed: false, detail: String(describing: host.presentedViewController), milliseconds: 0)]
            }
            check("media-fullscreen-presentation", !browser.configuration.isEmbedded && browser.currentIndex == 0)
            check("media-photo-loaded", (browser.sourceView(at: 0) as? UIImageView)?.image != nil)
            browser.currentIndex = 1
            browser.view.layoutIfNeeded()
            try? await Task.sleep(nanoseconds: 100_000_000)
            @MainActor func descendants(_ view: UIView) -> [UIView] { view.subviews.flatMap { [$0] + descendants($0) } }
            let play = descendants(browser.view).compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "WYPhotoBrowser.videoPlay" && !$0.isHidden }
            check("media-video-cover-play-control", play != nil && browser.currentIndex == 1, "index=\(browser.currentIndex), source=\(String(describing: browser.dataSource)), play=\(descendants(browser.view).compactMap { $0 as? UIButton }.map { ($0.accessibilityIdentifier ?? "nil") + " hidden=" + String($0.isHidden) })")
            play?.sendActions(for: .touchUpInside)
            try? await Task.sleep(nanoseconds: 500_000_000)
            let player = browser.presentedViewController as? AVPlayerViewController
            for _ in 0..<100 {
                if player?.player?.currentItem?.status != .unknown { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            check("media-real-video-decoded", player?.player?.currentItem?.status == .readyToPlay, player?.player?.currentItem?.error?.localizedDescription ?? "")
            check("media-video-presentation", player?.modalPresentationStyle == config.media.videoPresentationStyle && player?.showsPlaybackControls == config.media.showsVideoPlaybackControls)
            let videoBounds = player?.videoBounds ?? .zero
            check("media-video-aspect", videoBounds.width > 0 && videoBounds.height > 0 && abs(videoBounds.width / videoBounds.height - 4 / 3) < 0.02, "bounds=\(videoBounds)")
            try? await Task.sleep(nanoseconds: 500_000_000)
            check("media-real-video-advances", (player?.player?.currentTime().seconds ?? 0) > 0 && player?.player?.error == nil)
            player?.player?.pause()
            player?.dismiss(animated: false)
            try? await Task.sleep(nanoseconds: 150_000_000)
            browser.currentIndex = 2
            browser.view.layoutIfNeeded()
            for _ in 0..<30 {
                if (browser.sourceView(at: 2) as? UIImageView)?.image != nil { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            check("media-return-to-photo", browser.presentedViewController == nil && browser.currentIndex == 2 && (browser.sourceView(at: 2) as? UIImageView)?.image != nil, "index=\(browser.currentIndex), source=\(String(describing: browser.dataSource)), presented=\(String(describing: browser.presentedViewController))")
            check("media-preview-page-sync", view.messageModelFrom(identifier)?.content.mediaGroup?.visibleIndex == 2)
            browser.dismissBrowser(animated: false)
            try? await Task.sleep(nanoseconds: 150_000_000)
            check("media-preview-dismissed", host.presentedViewController == nil)
            return checks
        })
    }

    private func registerMediaCases() {
        cases.append(WYChatTestCase("相册结果与媒体合并", group: "媒体", explanation: "检查外部相册事件、逐条/合并、混合照片视频、展开收起、翻页状态、预览索引和实际布局") { [weak self] in
            guard let self else { return [] }
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
            catch { return [WYChatTestResult(name: "media-fixture", passed: false, detail: error.localizedDescription, milliseconds: 0)] }
            defer { try? FileManager.default.removeItem(at: folder) }
            let items = (0..<6).map { index -> WYChatMediaItem in
                let image = UIGraphicsImageRenderer(size: CGSize(width: 180, height: index.isMultiple(of: 2) ? 120 : 220)).image { context in
                    UIColor(hue: CGFloat(index) / 6, saturation: 0.55, brightness: 0.85, alpha: 1).setFill()
                    context.fill(CGRect(x: 0, y: 0, width: 180, height: index.isMultiple(of: 2) ? 120 : 220))
                    NSString(string: "\(index + 1)").draw(at: CGPoint(x: 60, y: 40), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 44), .foregroundColor: UIColor.white])
                }
                let path = folder.appendingPathComponent("media-\(index).png")
                try? image.pngData()?.write(to: path)
                var item = WYChatMediaItem()
                item.id = "selected-\(index)"
                item.kind = index == 2 ? .video : .photo
                item.original = WYChatAssetsModel(id: item.id, localPath: path.path)
                item.thumbnail = item.original
                item.size = image.size
                item.duration = index == 2 ? 12 : 0
                return item
            }
            var config = self.chatView.configuration
            config.imageLoader = nil
            config.media.automaticallyPresentsBrowser = false
            config.media.albumMoreItemIndex = 0
            let view = WYChatView(userInfo: self.chatView.userInfo, configuration: config)
            let host = self.chatView.window ?? self.chatView
            view.frame = host.bounds
            host.addSubview(view)
            defer { view.releaseAll(); view.removeFromSuperview() }
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ value: Bool, _ detail: String = "") { checks.append(WYChatTestResult(name: name, passed: value, detail: detail, milliseconds: 0)) }
            var albumRequests = 0
            view.openAlbumHandler = { albumRequests += 1 }
            view.requestAlbum()
            view.wy_didClickMoreViewAtIndex(itemIndex: 0)
            check("album-external-event", albumRequests == 2 && view.dataSource.isEmpty)
            check("empty-selection", view.sendMedia([]).isEmpty && view.dataSource.isEmpty)
            var prepared: [WYChatMessageModel] = []
            view.messagePreparedHandler = { prepared.append($0) }
            config.media.presentation = .individual
            view.configuration = config
            let separate = view.sendMedia(items)
            check("individual-media-messages", separate.count == items.count && view.dataSource.count == items.count && separate.enumerated().allSatisfy { $0.element.content.mediaGroup?.items == [items[$0.offset]] })
            check("individual-unique-message-ids", Set(separate.map(\.messageID)).count == separate.count && prepared.count == items.count)
            config.media.presentation = .merged
            view.configuration = config
            view.dataSource = []
            prepared.removeAll()
            let merged = view.sendMedia(items)
            check("merged-media-message", merged.count == 1 && merged.first?.content.mediaGroup?.items == items && prepared.count == 1 && merged.first?.content.style() == .mediaGroup)
            guard let identifier = merged.first?.messageID else { return checks }
            var previewItems: [WYChatMediaItem] = []
            var previewIndex = -1
            view.mediaPreviewHandler = { values, index, _ in previewItems = values; previewIndex = index }
            view.previewMedia(messageID: identifier, index: 2)
            check("mixed-media-preview-index", previewItems == items && previewIndex == 2 && previewItems[2].kind == .video)
            view.previewMedia(messageID: identifier, index: -1)
            view.previewMedia(messageID: identifier, index: items.count)
            check("invalid-media-index-ignored", previewIndex == 2)
            view.layoutIfNeeded()
            view.tableView.layoutIfNeeded()
            let path = IndexPath(row: 0, section: 0)
            view.tableView.scrollToRow(at: path, at: .top, animated: false)
            view.tableView.layoutIfNeeded()
            let cell = view.tableView.cellForRow(at: path) as? WYChatMediaGroupCell
            check("media-group-cell", cell != nil && cell?.mediaContentView.isHidden == false)
            let sideButton = cell?.contentView.subviews.compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "WYChatMedia.toggle" }
            let mediaFrame = cell.map { $0.mediaContentView.convert($0.mediaContentView.bounds, to: $0.contentView) } ?? .zero
            check("media-toggle-beside-first-item", sideButton != nil && abs((sideButton?.frame.midY ?? 0) - mediaFrame.midY) < 1 && (sideButton?.frame.maxX ?? .infinity) <= mediaFrame.minX + 1 && sideButton?.currentTitle == config.media.expandText)
            @MainActor func collection(in view: UIView) -> UICollectionView? { if let value = view as? UICollectionView { return value }; return view.subviews.compactMap { collection(in: $0) }.first }
            let originalCollection = cell.flatMap { collection(in: $0.mediaContentView) }
            cell?.mediaActionHandler?(.pageChanged, identifier, 3)
            let currentCell = view.tableView.cellForRow(at: path) as? WYChatMediaGroupCell
            check("stack-page-preserves-browser", originalCollection != nil && originalCollection === currentCell.flatMap { collection(in: $0.mediaContentView) } && currentCell?.message.content.mediaGroup?.visibleIndex == 3)
            check("stack-page-state", view.messageModelFrom(identifier)?.content.mediaGroup?.visibleIndex == 3)
            let collapsed = view.tableView.rectForRow(at: path).height
            view.setMediaGroupExpanded(true, messageID: identifier)
            view.tableView.layoutIfNeeded()
            try? await Task.sleep(nanoseconds: 50_000_000)
            let expanded = view.tableView.rectForRow(at: path).height
            check("expanded-media-height", view.messageModelFrom(identifier)?.content.mediaGroup?.isExpanded == true && expanded > collapsed * 3, "collapsed=\(collapsed), expanded=\(expanded)")
            view.setMediaGroupExpanded(false, messageID: identifier)
            view.tableView.layoutIfNeeded()
            check("collapse-retains-page", view.messageModelFrom(identifier)?.content.mediaGroup?.isExpanded == false && view.messageModelFrom(identifier)?.content.mediaGroup?.visibleIndex == 3)
            config.media.buttonPlacement = .below
            config.media.showsItemCountInButton = true
            view.configuration = config
            view.tableView.layoutIfNeeded()
            let belowCell = view.tableView.cellForRow(at: path) as? WYChatMediaGroupCell
            let belowButton = belowCell?.bodyView.arrangedSubviews.compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "WYChatMedia.toggle" }
            check("media-toggle-below-option", belowButton != nil && belowButton?.currentTitle?.contains("\(items.count)") == true)
            config.media.buttonPlacement = .beside
            config.media.showsItemCountInButton = false
            view.configuration = config
            view.tableView.layoutIfNeeded()
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("ChatView-VisualResults", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for width: CGFloat in [320, 393, 768] {
                view.frame.size.width = width
                view.setNeedsLayout()
                view.layoutIfNeeded()
                for expanded in [false, true] {
                    view.setMediaGroupExpanded(expanded, messageID: identifier)
                    view.tableView.layoutIfNeeded()
                    view.tableView.scrollToRow(at: path, at: .top, animated: false)
                    view.tableView.layoutIfNeeded()
                    let cell = view.tableView.cellForRow(at: path) as? WYChatMediaGroupCell
                    let frame = cell?.mediaContentView.convert(cell?.mediaContentView.bounds ?? .zero, to: cell?.contentView) ?? .zero
                    check("media-layout-\(Int(width))-\(expanded)", cell != nil && frame.height > 0 && frame.maxX <= (cell?.contentView.bounds.width ?? 0) + 1 && frame.minX >= -1, "frame=\(frame)")
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    let toggle = cell?.contentView.subviews.compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "WYChatMedia.toggle" }
                    check("media-toggle-\(Int(width))-\(expanded)", toggle?.isHidden == false && toggle?.currentTitle?.isEmpty == false && (cell?.contentView.bounds.insetBy(dx: -1, dy: -1).contains(toggle?.convert(toggle?.bounds ?? .zero, to: cell?.contentView) ?? .zero) ?? false), "toggle=\(String(describing: toggle?.frame)), bounds=\(String(describing: cell?.mediaContentView.bounds)), label=\(String(describing: toggle?.titleLabel?.frame)), title=\(toggle?.currentTitle ?? "")")
                    let image = UIGraphicsImageRenderer(bounds: view.bounds).image { _ in view.drawHierarchy(in: view.bounds, afterScreenUpdates: true) }
                    try? image.pngData()?.write(to: directory.appendingPathComponent("media-group-width-\(Int(width))-expanded-\(expanded).png"))
                }
            }
            var copied = merged[0]
            copied.content.mediaGroup?.items[0].original.localPath = "changed"
            check("media-group-value-isolation", merged[0].content.mediaGroup?.items[0].original.localPath == items[0].original.localPath)
            config.automaticallyInsertsSentMessages = false
            view.configuration = config
            let count = view.dataSource.count
            let callbacks = prepared.count
            let manual = view.sendMedia(items)
            check("media-manual-insertion", manual.count == 1 && view.dataSource.count == count && prepared.count == callbacks + 1)
            return checks
        })
    }

    private func registerTranscriptEditorCases() {
        cases.append(WYChatTestCase("转写编辑与外部翻译", group: "录音", explanation: "检查编辑高度、空文本、表情切换、识别语言以及外部翻译成功、失败、超时、取消和迟到结果") { [weak self] in
            guard let self else { return [] }
            let recorder: WYChatRecordingFixture
            do { recorder = try WYChatRecordingFixture() }
            catch { return [WYChatTestResult(name: "editor-fixture", passed: false, detail: error.localizedDescription, milliseconds: 0)] }
            defer { try? FileManager.default.removeItem(at: recorder.url) }
            let recognizer = WYChatRecognitionFixture()
            let translator = WYChatTranslationFixture()
            var config = WYRecordAnimationConfig()
            config.supportSpeechRecognition = true
            config.dictationSendsOnRelease = false
            config.recorder = recorder
            config.speechRecognitionSource = .external
            config.speechRecognitionProvider = recognizer
            config.translationProvider = translator
            config.showsRecognitionLanguageButton = true
            config.speechRecognitionLanguages = ["en-US", "zh-CN"]
            var styledControls: Set<Int> = []
            config.recognitionControlAppearance = { control, _ in styledControls.insert(control.rawValue) }
            let overlay = WYRecordAnimationView(alpha: 0, configuration: config)
            let host = self.chatView.window ?? self.chatView
            host.endEditing(true)
            overlay.frame = host.bounds
            host.addSubview(overlay)
            defer { overlay.endRecordVoice(); overlay.removeFromSuperview() }
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ value: Bool, _ detail: String = "") { checks.append(WYChatTestResult(name: name, passed: value, detail: detail, milliseconds: 0)) }
            @MainActor func descendants(_ view: UIView) -> [UIView] { view.subviews.flatMap { [$0] + descendants($0) } }
            @MainActor func editor() -> UITextView? { descendants(overlay).compactMap { $0 as? UITextView }.first { $0.accessibilityIdentifier == "WYChatRecording.editor" } }
            func settle() async { try? await Task.sleep(nanoseconds: 250_000_000) }
            @MainActor func show() async {
                overlay.endRecordVoice()
                overlay.recordAnimationConfig = config
                overlay.start(mode: .dictation)
                await settle()
                overlay.stop()
                await settle()
                overlay.layoutIfNeeded()
            }
            var results: [(String?, NSError?)] = []
            overlay.translationResultHandler = { results.append(($0, $1)) }
            await show()
            check("editor-control-appearance", styledControls == Set((0...6)))
            overlay.translateRecognizedText(to: "en-US")
            check("translation-disabled", translator.requests == 0)
            config.enablesTranslation = true
            await show()
            guard let text = editor() else { return checks + [WYChatTestResult(name: "editor-visible", passed: false, detail: "", milliseconds: 0)] }
            check("editor-recognized-text", text.text == recognizer.finalText && text.isEditable)
            let send = descendants(overlay).compactMap { $0 as? UIButton }.first { $0.currentTitle == config.recognitionSendText }
            text.text = ""
            text.delegate?.textViewDidChange?(text)
            check("empty-editor-disables-send", send?.isEnabled == false)
            for width: CGFloat in [320, 393, 768] {
                overlay.frame.size.width = width
                text.text = String(repeating: "编辑高度与文字换行，", count: 100)
                text.delegate?.textViewDidChange?(text)
                overlay.setNeedsLayout()
                overlay.layoutIfNeeded()
                let frame = text.convert(text.bounds, to: overlay)
                let buttonFrame = send?.convert(send?.bounds ?? .zero, to: overlay) ?? .zero
                check("editor-layout-\(Int(width))", frame.height > 0 && frame.maxY <= buttonFrame.minY + 1 && frame.minX >= 0 && frame.maxX <= overlay.bounds.width + 1, "text=\(frame), send=\(buttonFrame)")
                let image = UIGraphicsImageRenderer(bounds: overlay.bounds).image { _ in overlay.drawHierarchy(in: overlay.bounds, afterScreenUpdates: true) }
                let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("ChatView-VisualResults", isDirectory: true)
                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                try? image.pngData()?.write(to: folder.appendingPathComponent("transcript-editor-width-\(Int(width)).png"))
            }
            text.text = recognizer.finalText
            text.delegate?.textViewDidChange?(text)
            overlay.translateRecognizedText(to: "ja-JP")
            await settle()
            check("translation-host-service", translator.requests == 1 && translator.target == "ja-JP" && text.text == translator.output && results.last?.0 == translator.output && Thread.isMainThread)
            let delivered = results.count
            translator.completeAgain()
            await settle()
            check("translation-duplicate-ignored", results.count == delivered)
            text.text = "保留原文"
            translator.output = ""
            overlay.translateRecognizedText(to: "en-US")
            await settle()
            check("translation-empty-keeps-text", text.text == "保留原文" && results.last?.1?.code == 3)
            translator.output = "翻译后的文字"
            translator.completes = false
            overlay.translateRecognizedText(to: "en-US")
            text.text = "翻译期间的新编辑"
            text.delegate?.textViewDidChange?(text)
            let editedCount = results.count
            translator.completeAgain()
            await settle()
            check("translation-edit-cancels-late-result", translator.cancels > 0 && text.text == "翻译期间的新编辑" && results.count == editedCount)
            overlay.translateRecognizedText(to: "en-US")
            overlay.cancelTranslation()
            translator.completeAgain()
            await settle()
            check("translation-explicit-cancel", text.text == "翻译期间的新编辑" && results.count == editedCount)
            var changedLanguage: String?
            overlay.recognitionLanguageChangedHandler = { changedLanguage = $0 }
            let oldRequests = translator.requests
            overlay.changeRecognitionLanguage(to: "en-US")
            await settle()
            check("recognition-language-is-independent", changedLanguage == "en-US" && recognizer.files > 0 && translator.requests == oldRequests && text.text == recognizer.finalText)
            config.translationTimeout = 0.05
            await show()
            overlay.translateRecognizedText(to: "en-US")
            await settle()
            check("translation-timeout", results.last?.1?.code == 2 && results.last?.1?.domain == WYRecordAnimationView.translationErrorDomain)
            config.translationProvider = nil
            await show()
            overlay.translateRecognizedText(to: "en-US")
            check("translation-missing-provider", results.last?.1?.code == 1)
            let emojiButton = descendants(overlay).compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "WYChatRecording.emoji" }
            emojiButton?.sendActions(for: .touchUpInside)
            await settle()
            let activeText = editor()
            check("editor-emoji-input", activeText?.inputView is WYChatEmojiView && activeText?.isFirstResponder == true)
            if let emoji = activeText?.inputView as? WYChatEmojiView, let section = emoji.dataSource.indices.first(where: { !emoji.dataSource[$0].isEmpty }) {
                emoji.delegate?.wy_didClickEmojiView?(emoji, indexPath: IndexPath(item: 0, section: section))
                check("editor-emoji-insertion", !(activeText?.attributedText.string.isEmpty ?? true))
            } else { check("editor-emoji-insertion", false) }
            emojiButton?.sendActions(for: .touchUpInside)
            await settle()
            check("editor-keyboard-return", activeText?.inputView == nil && activeText?.isFirstResponder == true)
            return checks
        })
    }

    private func registerDictationCases() {
        cases.append(WYChatTestCase("直接转写与原语音", group: "录音", explanation: "检查两种识别时机、松手发送或编辑、取消、模式切换、原始文件交付及发送回调重入") { [weak self] in
            guard let self else { return [] }
            let recorder: WYChatRecordingFixture
            do { recorder = try WYChatRecordingFixture() }
            catch { return [WYChatTestResult(name: "dictation-fixture", passed: false, detail: error.localizedDescription, milliseconds: 0)] }
            defer { try? FileManager.default.removeItem(at: recorder.url) }
            let recognizer = WYChatRecognitionFixture()
            var config = WYRecordAnimationConfig()
            config.recorder = recorder
            config.speechRecognitionSource = .external
            config.speechRecognitionProvider = recognizer
            let overlay = WYRecordAnimationView(alpha: 0, configuration: config)
            let host = self.chatView.window ?? self.chatView
            host.endEditing(true)
            overlay.frame = host.bounds
            host.addSubview(overlay)
            defer { overlay.endRecordVoice(); overlay.removeFromSuperview() }
            var checks: [WYChatTestResult] = []
            func check(_ name: String, _ value: Bool) { checks.append(WYChatTestResult(name: name, passed: value, detail: "", milliseconds: 0)) }
            func settle() async { try? await Task.sleep(nanoseconds: 350_000_000) }
            @MainActor func descendants(_ view: UIView) -> [UIView] { view.subviews.flatMap { [$0] + descendants($0) } }
            var sent: [String] = []
            var voiceURLs: [URL] = []
            var errors = 0
            overlay.recognizedTextHandler = { sent.append($0) }
            overlay.resultHandler = { url, _, _ in if let url { voiceURLs.append(url) } }
            overlay.recognitionResultHandler = { _, error in if error != nil { errors += 1 } }
            overlay.start(mode: .dictation)
            check("disabled-dictation-does-not-record", recorder.starts == 0 && recorder.regularStarts == 0 && errors == 1 && overlay.alpha == 0)
            config.supportSpeechRecognition = true
            for timing in [WYChatSpeechRecognitionMode.whileRecording, .afterRecording] {
                for style in [WYRecordingActionStyle.circular, .curved] {
                    config.speechRecognitionMode = timing
                    config.actionStyle = style
                    overlay.recordAnimationConfig = config
                    let before = sent.count
                    overlay.start(mode: .dictation)
                    await settle()
                    check("dictation-mode-\(timing.rawValue)-\(style.rawValue)", overlay.recordingMode == .dictation)
                    let bubble = descendants(overlay).compactMap { $0 as? WYSoundAnimationView }.first
                    check("dictation-waveform-\(timing.rawValue)-\(style.rawValue)", bubble?.soundWavesView.isHidden == true)
                    overlay.stop()
                    overlay.stop()
                    await settle()
                    recognizer.completeAgain()
                    recorder.completeAgain()
                    await settle()
                    check("dictation-send-once-\(timing.rawValue)-\(style.rawValue)", sent.count == before + 1 && sent.last == recognizer.finalText && voiceURLs.isEmpty && overlay.alpha == 0)
                }
            }
            config.speechRecognitionMode = .whileRecording
            config.dictationSendsOnRelease = false
            overlay.recordAnimationConfig = config
            let beforeEdit = sent.count
            overlay.start(mode: .dictation)
            await settle()
            overlay.stop()
            await settle()
            check("dictation-editor-no-auto-send", sent.count == beforeEdit && overlay.alpha == 1)
            let voiceButton = descendants(overlay).compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "WYChatRecording.sendVoice" }
            check("dictation-hides-original-voice", voiceButton?.isHidden == true)
            overlay.sendOriginalRecording()
            check("dictation-cannot-send-voice", voiceURLs.isEmpty)
            let send = descendants(overlay).compactMap { $0 as? UIButton }.first { $0.currentTitle == config.recognitionSendText }
            send?.sendActions(for: .touchUpInside)
            check("dictation-edit-send", sent.count == beforeEdit + 1 && overlay.alpha == 0)
            config.dictationSendsOnRelease = true
            overlay.recordAnimationConfig = config
            let beforeSlide = sent.count
            overlay.start(mode: .dictation)
            await settle()
            overlay.soundAnimationStatus = .transfer
            overlay.stop()
            await settle()
            check("dictation-slide-keeps-editor", sent.count == beforeSlide && overlay.alpha == 1)
            overlay.endRecordVoice()
            overlay.start(mode: .dictation)
            await settle()
            overlay.soundAnimationStatus = .cancel
            overlay.stop()
            await settle()
            recognizer.emitLateResult()
            await settle()
            check("dictation-cancel-late-result", sent.count == beforeSlide && overlay.alpha == 0)
            overlay.start()
            overlay.start(mode: .dictation)
            await settle()
            check("active-mode-cannot-switch", overlay.recordingMode == .voice)
            overlay.soundAnimationStatus = .transfer
            overlay.stop()
            await settle()
            let original = descendants(overlay).compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "WYChatRecording.sendVoice" }
            check("voice-editor-offers-original", original?.isHidden == false && original?.isEnabled == true)
            original?.sendActions(for: .touchUpInside)
            overlay.sendOriginalRecording()
            check("original-voice-once", voiceURLs == [recorder.url] && overlay.alpha == 0 && FileManager.default.fileExists(atPath: recorder.url.path))
            overlay.recognizedTextHandler = { [weak overlay] text in sent.append(text); overlay?.start() }
            overlay.start(mode: .dictation)
            await settle()
            overlay.stop()
            await settle()
            check("send-callback-can-start-next-recording", overlay.recordingMode == .voice && overlay.alpha == 1)
            overlay.endRecordVoice()
            return checks
        })
    }

    private func registerRecordingCases() {
        cases.append(WYChatTestCase("录音与实时转写", group: "录音", explanation: "用固定PCM音频检查实时文本、编辑发送、重复停止、取消、文件识别和超时，不采集麦克风") { [weak self] in
            guard let self else { return [] }
            var results: [WYChatTestResult] = []
            func check(_ name: String, _ passed: Bool) { results.append(WYChatTestResult(name: name, passed: passed, detail: "", milliseconds: 0)) }
            func settle() async { try? await Task.sleep(nanoseconds: 350_000_000) }
            @MainActor func descendants(_ view: UIView) -> [UIView] { view.subviews.flatMap { [$0] + descendants($0) } }
            let recorder: WYChatRecordingFixture
            do { recorder = try WYChatRecordingFixture() }
            catch { return [WYChatTestResult(name: "audio-fixture", passed: false, detail: error.localizedDescription, milliseconds: 0)] }
            defer { try? FileManager.default.removeItem(at: recorder.url) }
            let recognizer = WYChatRecognitionFixture()
            var config = WYRecordAnimationConfig()
            config.supportSpeechRecognition = true
            config.speechRecognitionSource = .external
            config.speechRecognitionProvider = recognizer
            config.recorder = recorder
            config.speechRecognitionTimeout = 0.1
            config.recognitionSendText = "确认文本"
            config.recognitionCancelText = "关闭文本"
            config.recognitionRetryText = "重试文本"
            let events = WYChatRecordingEventsFixture()
            let overlay = WYRecordAnimationView(alpha: 0, delegate: events, configuration: config)
            let host = self.chatView.window ?? self.chatView
            host.endEditing(true)
            overlay.frame = host.bounds
            host.addSubview(overlay)
            defer { overlay.endRecordVoice(); overlay.removeFromSuperview() }
            var partials: [String] = []
            var finalCount = 0
            var finalError: NSError?
            var sent: String?
            var voiceCount = 0
            overlay.recognitionPartialResultHandler = { partials.append($0) }
            overlay.recognitionResultHandler = { _, error in finalCount += 1; finalError = error }
            overlay.recognizedTextHandler = { sent = $0 }
            overlay.resultHandler = { _, _, _ in voiceCount += 1 }
            overlay.start()
            overlay.start()
            await settle()
            let bubble = descendants(overlay).compactMap { $0 as? WYSoundAnimationView }.first
            check("live-single-start", recorder.starts == 1 && recognizer.starts == 1)
            check("partial-before-stop", partials == [recognizer.partialText] && bubble?.textView.text == recognizer.partialText && overlay.alpha == 1)
            for width: CGFloat in [320, 393, 768] {
                overlay.frame.size.width = width
                for status in [WYSoundAnimationStatus.recording, .cancel, .transfer] {
                    overlay.soundAnimationStatus = status
                    if let bubble { overlay.refresh(subview: bubble, status: status) }
                    overlay.setNeedsLayout()
                    overlay.layoutIfNeeded()
                    check("recording-bounds-\(Int(width))-\(status.rawValue)", bubble.map { overlay.bounds.insetBy(dx: -1, dy: -1).contains($0.frame) } ?? false)
                }
            }
            overlay.frame = host.bounds
            overlay.soundAnimationStatus = .transfer
            overlay.recordAnimationConfig.recorder = nil
            overlay.stop()
            overlay.stop()
            overlay.recordAnimationConfig.recorder = recorder
            await settle()
            let editor = descendants(overlay).compactMap { $0 as? UITextView }.first { $0 !== bubble?.textView }
            let buttons = descendants(overlay).compactMap { $0 as? UIButton }
            check("stop-once", recorder.stops == 1 && recognizer.finishes == 1)
            check("editor-survives-stop-animation", overlay.alpha == 1 && editor?.text == recognizer.finalText && editor?.isEditable == true && finalCount == 1)
            recorder.completeAgain()
            recognizer.completeAgain()
            await settle()
            check("duplicate-completion-ignored", finalCount == 1 && voiceCount == 0)
            editor?.text = "  编辑后的文本  "
            buttons.first { $0.title(for: .normal) == config.recognitionSendText }?.sendActions(for: .touchUpInside)
            check("send-edited-text", sent == "编辑后的文本" && overlay.alpha == 0)
            overlay.start()
            await settle()
            overlay.soundAnimationStatus = .cancel
            overlay.stop()
            await settle()
            recognizer.emitLateResult()
            await settle()
            check("cancel-late-result-ignored", finalCount == 1 && voiceCount == 0 && recognizer.cancels == 1 && overlay.alpha == 0)
            overlay.recordAnimationConfig.supportSpeechRecognition = false
            let priorStarts = recognizer.starts
            overlay.start()
            await settle()
            overlay.stop()
            await settle()
            check("disabled-ordinary-voice", recognizer.starts == priorStarts && voiceCount == 1 && recorder.regularStarts == 1)
            overlay.recordAnimationConfig.supportSpeechRecognition = true
            overlay.recordAnimationConfig.speechRecognitionMode = .afterRecording
            overlay.start()
            await settle()
            check("file-mode-no-live-start", recognizer.starts == priorStarts)
            overlay.soundAnimationStatus = .transfer
            overlay.stop()
            await settle()
            check("file-recognition-result", recognizer.files == 1 && editor?.text == recognizer.finalText && finalCount == 2)
            buttons.first { $0.title(for: .normal) == config.recognitionCancelText }?.sendActions(for: .touchUpInside)
            overlay.recordAnimationConfig.speechRecognitionMode = .whileRecording
            recognizer.shouldComplete = false
            overlay.start()
            await settle()
            overlay.soundAnimationStatus = .transfer
            overlay.stop()
            await settle()
            check("stream-timeout-cancels-provider", finalError?.domain == WYChatSpeechRecognitionErrorDomain && finalError?.code == WYChatSpeechRecognitionErrorCode.timedOut.rawValue && recognizer.cancels == 2 && editor?.isEditable == false)
            recognizer.emitLateResult()
            await settle()
            check("timeout-late-result-ignored", finalCount == 3 && editor?.text == config.recognitionFailureText)
            recognizer.shouldComplete = true
            recognizer.supportsFiles = false
            overlay.recordAnimationConfig.speechRecognitionTimeout = 2
            let retryStarts = recognizer.starts
            buttons.first { $0.title(for: .normal) == config.recognitionRetryText }?.sendActions(for: .touchUpInside)
            await settle()
            results.append(WYChatTestResult(name: "stream-only-provider-retry", passed: recognizer.starts == retryStarts + 1 && recognizer.files == 1 && finalCount == 4 && editor?.text == recognizer.finalText && editor?.isEditable == true, detail: "starts=\(recognizer.starts), previous=\(retryStarts), files=\(recognizer.files), finals=\(finalCount), text=\(editor?.text ?? ""), error=\(String(describing: finalError))", milliseconds: 0))
            overlay.endRecordVoice()
            check("release-hides-overlay", overlay.alpha == 0)
            check("recording-events-all-providers", events.starts == 5 && events.finishes == 5 && events.cancelled == 1 && events.times == 5 && events.meters == 5 && events.view === overlay)
            return results
        })
    }

    private func registerAppleSpeechCase() {
        cases.append(WYChatTestCase("Apple原生实时识别", group: "录音", explanation: "用内置固定语音文件检查Apple识别在结束录音前返回文字，并检查最终转写，需要系统语音识别权限及可用识别服务", requiresInteraction: true) { [weak self] in
            guard let self, let url = Bundle.main.url(forResource: "ChatViewSpeechSample", withExtension: "caf") else { return [WYChatTestResult(name: "speech-sample", passed: false, detail: "测试语音文件不存在", milliseconds: 0)] }
            let authorized = await withCheckedContinuation { continuation in wy_authorizeSpeechRecognition(showSettingsAlert: false) { continuation.resume(returning: $0) } }
            guard authorized else { return [WYChatTestResult(name: "apple-speech-permission", passed: false, detail: "未获得系统语音识别权限", milliseconds: 0)] }
            let recorder = WYChatSpokenRecordingFixture(url: url)
            var config = WYRecordAnimationConfig()
            config.recorder = recorder
            config.supportSpeechRecognition = true
            config.speechRecognitionSource = .apple
            config.speechRecognitionMode = .whileRecording
            config.speechLocaleIdentifier = "en-US"
            config.speechRecognitionTimeout = 15
            let overlay = WYRecordAnimationView(alpha: 0, configuration: config)
            let host = self.chatView.window ?? self.chatView
            host.endEditing(true)
            overlay.frame = host.bounds
            host.addSubview(overlay)
            defer { overlay.endRecordVoice(); overlay.removeFromSuperview() }
            var partial = ""
            var final: String?
            var error: NSError?
            overlay.recognitionPartialResultHandler = { partial = $0 }
            overlay.recognitionResultHandler = { final = $0; error = $1 }
            overlay.start()
            let deadline = Date().addingTimeInterval(20)
            while (recorder.hasPendingAudio || (partial.isEmpty && error == nil)) && Date() < deadline { try? await Task.sleep(nanoseconds: 50_000_000) }
            let live = !partial.isEmpty && recorder.isRecording
            let stillRecording = recorder.isRecording
            overlay.soundAnimationStatus = .transfer
            overlay.stop()
            let finalDeadline = Date().addingTimeInterval(20)
            while final == nil && error == nil && Date() < finalDeadline { try? await Task.sleep(nanoseconds: 50_000_000) }
            let expected = final?.lowercased().contains("weather") == true || final?.lowercased().contains("sunny") == true
            var checks = [WYChatTestResult(name: "apple-live-partial", passed: live, detail: partial, milliseconds: 0), WYChatTestResult(name: "apple-final-text", passed: expected && error == nil, detail: "text=\(final ?? ""), error=\(String(describing: error))", milliseconds: 0), WYChatTestResult(name: "recording-continues-until-stop", passed: stillRecording, detail: "", milliseconds: 0), WYChatTestResult(name: "apple-editor-visible", passed: overlay.alpha == 1, detail: "", milliseconds: 0)]
            if let error {
                let baseline = WYChatAppleRecognitionComparison()
                let result = await baseline.recognize(url)
                checks.append(WYChatTestResult(name: "apple-direct-api-comparison", passed: result.error?.domain == error.domain && result.error?.code == error.code, detail: "component=\(error), direct=\(String(describing: result.error))", milliseconds: 0))
            }
            return checks
        })
    }

    private func registerModelCases() {
        cases.append(WYChatTestCase("消息模型复制与嵌套修改", group: "模型", explanation: "检查15种消息内容复制后分别设置、清空、修改数组和嵌套字段时不会影响原值") {
            var results: [WYChatTestResult] = []
            func check(_ name: String, _ passed: Bool) { results.append(WYChatTestResult(name: name, passed: passed, detail: "", milliseconds: 0)) }
            func checkField<Value: Equatable>(_ name: String, _ path: WritableKeyPath<WYChatMessageContentModel, Value?>, _ value: Value, _ style: WYChatMessageStyle) {
                let original = WYChatMessageContentModel()
                var copy = original
                copy[keyPath: path] = value
                check(name + "-set-copy", original.style() == .none && original[keyPath: path] == nil && copy[keyPath: path] == value && copy.style() == style)
                var cleared = copy
                cleared[keyPath: path] = nil
                check(name + "-clear-copy", cleared == original && copy[keyPath: path] == value)
                var array = [copy, copy]
                array[0][keyPath: path] = nil
                check(name + "-array-isolation", array[0] == original && array[1] == copy)
            }
            checkField("text", \.text, "消息内容", .text)
            checkField("voice", \.voice, WYChatVoiceModel(), .voice)
            checkField("photo", \.photo, WYChatPhotoModel(), .photo)
            checkField("music", \.music, WYChatMusicModel(), .music)
            checkField("video", \.video, WYChatVideoModel(), .video)
            checkField("luckyMoney", \.luckyMoney, WYChatLuckyMoneyModel(), .luckyMoney)
            checkField("transfer", \.transfer, WYChatLuckyMoneyModel(), .transfer)
            checkField("location", \.location, WYChatLocationModel(), .location)
            checkField("takePat", \.takePat, WYChatTakePatModel(), .takePat)
            checkField("withdrawn", \.withdrawn, WYChatWithdrawnModel(), .withdrawn)
            checkField("call", \.call, WYChatCallModel(), .call)
            checkField("webpage", \.webpage, WYChatWebpageModel(), .webpage)
            checkField("file", \.file, WYChatFileModel(), .file)
            checkField("businessCard", \.businessCard, WYChatBusinessCardModel(), .businessCard)
            checkField("chatRecords", \.chatRecords, WYChatRecordsModel(), .chatRecords)
            let photo = WYChatMessageContentModel(photo: WYChatPhotoModel())
            var changedPhoto = photo
            changedPhoto.photo?.original.localPath = "changed-photo"
            check("nested-photo-isolation", photo.photo?.original.localPath == "" && changedPhoto.photo?.original.localPath == "changed-photo")
            let records = WYChatMessageContentModel(chatRecords: WYChatRecordsModel(messages: [WYChatMessageModel(content: WYChatMessageContentModel(text: "原消息"))]))
            var changedRecords = records
            changedRecords.chatRecords?.messages[0].content.text = "修改后的消息"
            check("nested-records-isolation", records.chatRecords?.messages[0].content.text == "原消息" && changedRecords.chatRecords?.messages[0].content.text == "修改后的消息")
            var combined = WYChatMessageContentModel(text: "文本", photo: WYChatPhotoModel())
            let combinedCopy = combined
            combined.text = nil
            check("content-priority", combined.style() == .photo && combinedCopy.style() == .text && combinedCopy.photo != nil)
            func checkMessageField<Value: Equatable>(_ name: String, _ path: WritableKeyPath<WYChatMessageModel, Value>, _ value: Value) {
                let original = WYChatMessageModel()
                var copy = original
                copy[keyPath: path] = value
                check(name + "-message-copy", original == WYChatMessageModel() && copy[keyPath: path] == value && copy != original)
                var array = [copy, copy]
                array[0][keyPath: path] = original[keyPath: path]
                check(name + "-message-array", array[0] == original && array[1] == copy)
            }
            checkMessageField("isTransferring", \.isTransferring, true)
            checkMessageField("transferProgress", \.transferProgress, 0.5)
            checkMessageField("transferError", \.transferError, "传输失败")
            checkMessageField("greetingDescription", \.greetingDescription, "打招呼")
            checkMessageField("readers", \.readers, "1")
            checkMessageField("readBackState", \.readBackState, .success)
            checkMessageField("sendState", \.sendState, .sending)
            checkMessageField("messageID", \.messageID, "changed-id")
            checkMessageField("sessionID", \.sessionID, "changed-session")
            checkMessageField("clientTimestamp", \.clientTimestamp, "123")
            checkMessageField("lastMessageTimestamp", \.lastMessageTimestamp, "123")
            checkMessageField("timestamp", \.timestamp, "123")
            checkMessageField("timeFormat", \.timeFormat, "12:00")
            checkMessageField("sender", \.sender, WYChatUserModel(id: "changed-user"))
            checkMessageField("group", \.group, WYChatGroupModel())
            checkMessageField("content", \.content, WYChatMessageContentModel(text: "新内容"))
            checkMessageField("reference", \.reference, WYChatQuoteModel(content: WYChatMessageContentModel(text: "引用")))
            checkMessageField("index", \.index, 1)
            var senderMessage = WYChatMessageModel()
            senderMessage.sender.avatar.localPath = "before"
            var changedSender = senderMessage
            changedSender.sender.avatar.localPath = "after"
            check("nested-sender-isolation", senderMessage.sender.avatar.localPath == "before" && changedSender.sender.avatar.localPath == "after")
            let referenced = WYChatMessageModel(reference: WYChatQuoteModel(content: photo))
            var changedReference = referenced
            changedReference.reference?.content.photo?.original.localPath = "after"
            check("nested-reference-isolation", referenced.reference?.content.photo?.original.localPath == "" && changedReference.reference?.content.photo?.original.localPath == "after")
            return results
        })
    }

    private func registerLayoutCases() {
        let initial = visibleLayoutResults(requireBottom: true)
        cases.append(WYChatTestCase("首次进入的实际列表", group: "布局", explanation: "在任何主动滚动或单独Cell测高之前，检查实际列表内可见卡片的行高和文字裁切") { initial })
        cases.append(WYChatTestCase("当前实际列表", group: "布局", explanation: "检查实际列表当前可见的Cell，与初次进入结果对照") { [weak self] in self?.visibleLayoutResults() ?? [] })
        cases.append(WYChatTestCase("实际列表逐行布局", group: "布局", explanation: "在真实列表内滚动检查每一条消息的图片高度、文字完整性与内容边界") { [weak self] in
            guard let self else { return [] }
            return await self.sweepLayoutResults()
        })
        cases.append(WYChatTestCase("文本边界与换行", group: "布局", explanation: "检查空文本、末尾换行、连续换行、长文本、表情、链接、字号和最大行数") { [weak self] in
            guard let self else { return [] }
            let saved = self.chatView.dataSource
            let config = self.chatView.configuration
            defer { self.chatView.configuration = config; self.chatView.dataSource = saved }
            let samples = ["", "短消息", "末尾换行\n", "\n\n", String(repeating: "长文本换行检查，", count: 60), "你好😀👨‍👩‍👧‍👦[微笑]", "https://example.com/path?q=test", "first line\nsecond line\nthird line"]
            var results: [WYChatTestResult] = []
            for factor: CGFloat in [1, 1.5] {
                for maximum in [0, 1, 3] {
                    var changed = config
                    changed.text.textFont = config.text.textFont.withSize(config.text.textFont.pointSize * factor)
                    changed.text.textMaximumNumberOfLines = maximum
                    self.chatView.configuration = changed
                    self.chatView.dataSource = samples.enumerated().map { index, text in
                        WYChatMessageModel(messageID: "text-boundary-\(index)", sender: WYChatUserModel(id: index.isMultiple(of: 2) ? self.chatView.userInfo.id : "other"), content: WYChatMessageContentModel(text: text))
                    }
                    for result in await self.sweepLayoutResults() {
                        results.append(WYChatTestResult(name: "font-\(factor)-lines-\(maximum)-" + result.name, passed: result.passed, detail: result.detail, milliseconds: result.milliseconds))
                    }
                }
            }
            return results
        })
        cases.append(WYChatTestCase("全部消息测高与复用", group: "布局", explanation: "逐项检查320、393、402及768宽度下的收发消息、文字完整性、内容边界和重复测高稳定性") { [weak self] in
            guard let self else { return [] }
            let source = self.chatView.dataSource
            var results: [WYChatTestResult] = []
            let host = UIView(frame: CGRect(x: 0, y: 0, width: 768, height: 2000))
            self.chatView.addSubview(host)
            defer { host.removeFromSuperview() }
            let factories: [WYChatMessageStyle: () -> WYChatBasicCell] = [
                .none: { WYChatBasicCell(style: .default, reuseIdentifier: nil) }, .text: { WYChatTextCell(style: .default, reuseIdentifier: nil) },
                .voice: { WYChatVoiceCell(style: .default, reuseIdentifier: nil) }, .photo: { WYChatPhotoCell(style: .default, reuseIdentifier: nil) },
                .music: { WYChatMusicCell(style: .default, reuseIdentifier: nil) }, .video: { WYChatVideoCell(style: .default, reuseIdentifier: nil) },
                .luckyMoney: { WYChatLuckyMoneyCell(style: .default, reuseIdentifier: nil) }, .transfer: { WYChatTransferCell(style: .default, reuseIdentifier: nil) },
                .location: { WYChatLocationCell(style: .default, reuseIdentifier: nil) }, .takePat: { WYChatTakePatCell(style: .default, reuseIdentifier: nil) },
                .withdrawn: { WYChatWithdrawnCell(style: .default, reuseIdentifier: nil) }, .call: { WYChatCallCell(style: .default, reuseIdentifier: nil) },
                .webpage: { WYChatWebpageCell(style: .default, reuseIdentifier: nil) }, .file: { WYChatFileCell(style: .default, reuseIdentifier: nil) },
                .businessCard: { WYChatBusinessCardCell(style: .default, reuseIdentifier: nil) }, .chatRecords: { WYChatRecordsCell(style: .default, reuseIdentifier: nil) },
                .mediaGroup: { WYChatMediaGroupCell(style: .default, reuseIdentifier: nil) }
            ]
            for style in WYChatMessageStyle.allCases {
                guard let cell = factories[style]?() else { continue }
                host.addSubview(cell)
                for width: CGFloat in [320, 393, 402, 768] {
                    for message in source.filter({ $0.content.style() == style }) {
                        cell.frame = CGRect(x: 0, y: 0, width: width, height: 2000)
                        cell.update(message: message, configuration: self.chatView.configuration, userID: self.chatView.userInfo.id)
                        let target = CGSize(width: width, height: 0)
                        let measured = cell.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
                        cell.frame.size.height = measured.height
                        cell.setNeedsLayout()
                        cell.layoutIfNeeded()
                        let repeated = cell.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
                        let bubble = cell.bubblesView.convert(cell.bubblesView.bounds, to: cell.contentView)
                        let body = cell.bodyView.convert(cell.bodyView.bounds, to: cell.contentView)
                        let valid = measured.height.isFinite && measured.height > 0 && abs(measured.height - repeated.height) < 1 && cell.contentView.bounds.insetBy(dx: -1, dy: -1).contains(bubble) && bubble.insetBy(dx: -1, dy: -1).contains(body)
                        let id = "\(style.rawValue)-\(Int(width))-\(message.isSender(self.chatView.userInfo.id))"
                        results.append(WYChatTestResult(name: "geometry-" + id, passed: valid, detail: "row=\(measured.height), repeated=\(repeated.height), bubble=\(bubble), body=\(body)", milliseconds: 0))
                        for (name, label) in [("title", cell.titleView), ("detail", cell.detailView), ("footer", cell.footerView)] where !label.isHidden && !(label.text?.isEmpty ?? true) {
                            let expected = label.sizeThatFits(CGSize(width: label.bounds.width, height: .greatestFiniteMagnitude)).height
                            let fits = label.bounds.height + 1 >= expected && cell.bodyView.convert(cell.bodyView.bounds, to: label).insetBy(dx: -1, dy: -1).contains(label.bounds)
                            results.append(WYChatTestResult(name: name + "-" + id, passed: fits, detail: "actual=\(label.bounds.height), expected=\(expected)", milliseconds: 0))
                        }
                    }
                    await Task.yield()
                }
                cell.removeFromSuperview()
            }
            return results
        })
    }

    private func sweepLayoutResults() async -> [WYChatTestResult] {
        let table = self.chatView.tableView
        let offset = table.contentOffset
        defer { table.setContentOffset(offset, animated: false) }
        var results: [String: WYChatTestResult] = [:]
        for row in self.chatView.dataSource.indices {
            table.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle, animated: false)
            table.layoutIfNeeded()
            for result in self.visibleLayoutResults() where results[result.name]?.passed != false {
                results[result.name] = result
            }
            await Task.yield()
        }
        return results.values.sorted { $0.name < $1.name }
    }

    private func visibleLayoutResults(requireBottom: Bool = false) -> [WYChatTestResult] {
        let table = chatView.tableView
        let cells = table.visibleCells.compactMap { $0 as? WYChatBasicCell }
        var checks = [WYChatTestResult(name: "visible-cells", passed: !cells.isEmpty, detail: "可见Cell数量\(cells.count)", milliseconds: 0)]
        if requireBottom, let last = chatView.dataSource.last {
            checks.append(WYChatTestResult(name: "initial-last-message-visible", passed: cells.contains { $0.message.messageID == last.messageID }, detail: "visibleRows=\(table.indexPathsForVisibleRows?.map(\.row) ?? []), total=\(chatView.dataSource.count)", milliseconds: 0))
        }
        for cell in cells {
            guard let path = table.indexPath(for: cell) else { continue }
            let name = "row-\(path.row)-type-\(cell.message.content.style().rawValue)"
            let bubble = cell.bubblesView.convert(cell.bubblesView.bounds, to: cell.contentView)
            let body = cell.bodyView.convert(cell.bodyView.bounds, to: cell.contentView)
            let inside = cell.contentView.bounds.insetBy(dx: -1, dy: -1).contains(bubble) && bubble.insetBy(dx: -1, dy: -1).contains(body)
            checks.append(WYChatTestResult(name: name + "-bounds", passed: inside, detail: "row=\(table.rectForRow(at: path)), content=\(cell.contentView.bounds), bubble=\(bubble), body=\(body)", milliseconds: 0))
            if let textCell = cell as? WYChatTextCell {
                let expected = textCell.textView.sizeThatFits(CGSize(width: textCell.textView.bounds.width, height: .greatestFiniteMagnitude)).height
                checks.append(WYChatTestResult(name: name + "-text-height", passed: textCell.textView.bounds.height + 1 >= expected, detail: "actual=\(textCell.textView.bounds.height), expected=\(expected)", milliseconds: 0))
            }
            if !cell.previewImageView.isHidden {
                let style = cell.message.content.style()
                let factor: CGFloat = [.webpage, .luckyMoney, .transfer].contains(style) ? 0.5 : 1
                let expected = max(1, cell.messageContentConfiguration.mediaSize.height * factor)
                let actual = cell.previewImageView.alignmentRect(forFrame: cell.previewImageView.frame).height
                checks.append(WYChatTestResult(name: name + "-media-height", passed: abs(actual - expected) < 1, detail: "boundsHeight=\(cell.previewImageView.bounds.height), alignmentHeight=\(actual), expected=\(expected)", milliseconds: 0))
            }
            for (field, label) in [("title", cell.titleView), ("detail", cell.detailView), ("footer", cell.footerView)] where !label.isHidden && !(label.text?.isEmpty ?? true) {
                let wanted = label.sizeThatFits(CGSize(width: label.bounds.width, height: .greatestFiniteMagnitude)).height
                checks.append(WYChatTestResult(name: name + "-" + field, passed: label.bounds.height + 1 >= wanted && label.bounds.width > 0, detail: "text=\(label.text ?? ""), actual=\(label.bounds), expectedHeight=\(wanted)", milliseconds: 0))
            }
        }
        return checks
    }
}

/// 固定音频录音实现，用于检查组件的外部采集流程
private final class WYChatRecordingFixture: NSObject, WYChatRecorder {
    let url: URL
    let buffer: AVAudioPCMBuffer
    var starts = 0
    var regularStarts = 0
    var stops = 0
    private var completion: ((URL?, TimeInterval, NSError?) -> Void)?

    init(audioFixture: Void = ()) throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1600)!
        buffer.frameLength = 1600
        if let samples = buffer.floatChannelData?[0] { for index in 0..<1600 { samples[index] = sin(Float(index) * 0.1) * 0.1 } }
        url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
        super.init()
    }

    func wy_startStreamingRecording(_ requestID: String, settings: [String: Any], maximumDuration: TimeInterval, audioBuffer: @escaping (AVAudioPCMBuffer) -> Void, progress: @escaping (TimeInterval, Float, Float) -> Void, completion: @escaping (URL?, TimeInterval, NSError?) -> Void) {
        starts += 1
        self.completion = completion
        audioBuffer(buffer)
        progress(1, -20, -30)
    }

    func wy_startRecording(_ requestID: String, settings: [String: Any], maximumDuration: TimeInterval, progress: @escaping (TimeInterval, Float, Float) -> Void, completion: @escaping (URL?, TimeInterval, NSError?) -> Void) {
        regularStarts += 1
        self.completion = completion
        progress(1, -20, -30)
    }

    func wy_stopRecording(_ requestID: String, cancel: Bool) {
        stops += 1
        completion?(cancel ? nil : url, 1, nil)
    }

    func completeAgain() { completion?(url, 1, nil) }
}

/// 可控制完成与迟到回调的识别实现
private final class WYChatRecognitionFixture: NSObject, WYChatSpeechRecognizer {
    let partialText = "正在录音的实时文本"
    let finalText = "最终识别文本"
    var starts = 0
    var finishes = 0
    var files = 0
    var cancels = 0
    var shouldComplete = true
    var supportsFiles = true
    private var partial: ((String) -> Void)?
    private var completion: ((String?, NSError?) -> Void)?

    override func responds(to aSelector: Selector!) -> Bool {
        if !supportsFiles && aSelector == #selector(WYChatSpeechRecognizer.wy_recognizeSpeech(_:url:localeIdentifier:requiresOnDevice:completion:)) { return false }
        return super.responds(to: aSelector)
    }

    func wy_startStreamingSpeech(_ requestID: String, localeIdentifier: String, requiresOnDevice: Bool, partialResult: @escaping (String) -> Void, completion: @escaping (String?, NSError?) -> Void) {
        starts += 1
        partial = partialResult
        self.completion = completion
    }
    func wy_appendSpeechAudio(_ requestID: String, buffer: AVAudioPCMBuffer) { partial?(partialText) }
    func wy_finishStreamingSpeech(_ requestID: String) { finishes += 1; if shouldComplete { completion?(finalText, nil) } }
    func wy_recognizeSpeech(_ requestID: String, url: URL, localeIdentifier: String, requiresOnDevice: Bool, completion: @escaping (String?, NSError?) -> Void) { files += 1; completion(finalText, nil) }
    func wy_cancelSpeechRecognition(_ requestID: String) { cancels += 1 }
    func completeAgain() { completion?(finalText, nil) }
    func emitLateResult() { partial?("迟到文本"); completion?("迟到文本", nil) }
}

/// 录音事件收集
private final class WYChatRecordingEventsFixture: NSObject, WYRecordEventsHandler {
    var starts = 0
    var times = 0
    var meters = 0
    var finishes = 0
    var cancelled = 0
    weak var view: WYRecordAnimationView?

    func wy_recordingWillStart(_ view: WYRecordAnimationView) { self.view = view; starts += 1 }
    func wy_recordingTimeUpdated(_ view: WYRecordAnimationView, currentTime: TimeInterval, maximumDuration: TimeInterval) { times += 1 }
    func wy_recordingMeteringUpdated(_ view: WYRecordAnimationView, peakPower: Float, averagePower: Float) { meters += 1 }
    func wy_recordingDidFinish(_ view: WYRecordAnimationView, url: URL?, duration: TimeInterval, cancelled: Bool, timedOut: Bool, error: NSError?) { finishes += 1; if cancelled { self.cancelled += 1 } }
}

@MainActor
private final class WYChatBounceProbe: NSObject {
    private weak var table: UITableView?
    private var displayLink: CADisplayLink?
    private(set) var minimum: CGFloat = 0
    private(set) var recoveryFrames = 0

    init(table: UITableView) {
        self.table = table
        super.init()
        let link = CADisplayLink(target: self, selector: #selector(sample))
        displayLink = link
        link.add(to: .main, forMode: .common)
    }

    func stop() { displayLink?.invalidate(); displayLink = nil }

    @objc private func sample() {
        guard let table else { stop(); return }
        let offset = table.contentOffset.y + table.adjustedContentInset.top
        minimum = min(minimum, offset)
        if offset < -1 && !table.isDragging && !table.isTracking { recoveryFrames += 1 }
    }
}

/// 记录实际拖动时的消息位置与显示帧间隔
@MainActor
final class WYChatScrollProbe: NSObject {
    private weak var table: UITableView?
    private var displayLink: CADisplayLink?
    private var previous: (identifier: String, y: CGFloat, translation: CGFloat)?
    private var previousTimestamp: CFTimeInterval?
    private var samples = 0
    private var drags = 0
    private var maximumError: CGFloat = 0
    private var maximumInterval: Double = 0

    init(table: UITableView) {
        self.table = table
        super.init()
        table.panGestureRecognizer.addTarget(self, action: #selector(panChanged(_:)))
    }

    @objc private func panChanged(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            drags += 1
            previous = nil
            previousTimestamp = nil
            displayLink?.invalidate()
            let target = WYChatScrollDisplayLinkTarget()
            target.owner = self
            let link = CADisplayLink(target: target, selector: #selector(WYChatScrollDisplayLinkTarget.sample(_:)))
            displayLink = link
            link.add(to: .main, forMode: .common)
        case .ended, .cancelled, .failed:
            displayLink?.invalidate()
            displayLink = nil
            previous = nil
        default: break
        }
    }

    fileprivate func sample(_ link: CADisplayLink) {
        if let previousTimestamp { maximumInterval = max(maximumInterval, (link.timestamp - previousTimestamp) * 1000) }
        previousTimestamp = link.timestamp
        guard let table, let window = table.window, table.isDragging else { previous = nil; return }
        let minimum = -table.adjustedContentInset.top
        let maximum = max(minimum, table.contentSize.height - table.bounds.height + table.adjustedContentInset.bottom)
        let pixel = 1 / window.screen.scale
        guard table.contentOffset.y > minimum + pixel, table.contentOffset.y < maximum - pixel else { previous = nil; return }
        let translation = table.panGestureRecognizer.translation(in: window).y
        let cells = table.visibleCells.compactMap { $0 as? WYChatBasicCell }
        if let previous, let cell = cells.first(where: { $0.message.messageID == previous.identifier }) {
            let y = cell.convert(cell.bounds, to: window).minY
            let error = abs((y - previous.y) - (translation - previous.translation))
            maximumError = max(maximumError, error)
            samples += 1
        }
        guard let anchor = cells.min(by: { abs($0.frame.midY - table.bounds.midY) < abs($1.frame.midY - table.bounds.midY) }) else { previous = nil; return }
        previous = (anchor.message.messageID, anchor.convert(anchor.bounds, to: window).minY, translation)
    }

    func results() -> [WYChatTestResult] {
        let tolerance = max(UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels), (table?.bounds.height ?? 0) * 0.025)
        return [WYChatTestResult(name: "dragged-message-position", passed: samples > 0 && maximumError <= tolerance, detail: "拖动\(drags)次，有效帧\(samples)，消息与手指移动最大差\(maximumError)pt，允许\(tolerance)pt，最大显示帧间隔\(maximumInterval)ms", milliseconds: maximumInterval)]
    }

    deinit { displayLink?.invalidate() }
}

/// 转发显示刷新事件
@MainActor
private final class WYChatScrollDisplayLinkTarget: NSObject {
    weak var owner: WYChatScrollProbe?
    @objc func sample(_ link: CADisplayLink) { owner?.sample(link) }
}

/// 按实际时长提供固定语音，不采集麦克风
private final class WYChatSpokenRecordingFixture: NSObject, WYChatRecorder {
    let url: URL
    private(set) var isRecording = false
    var hasPendingAudio: Bool { file.map { $0.framePosition < $0.length } ?? false }
    private var timer: Timer?
    private var file: AVAudioFile?
    private var completion: ((URL?, TimeInterval, NSError?) -> Void)?

    init(url: URL) { self.url = url }

    func wy_startStreamingRecording(_ requestID: String, settings: [String: Any], maximumDuration: TimeInterval, audioBuffer: @escaping (AVAudioPCMBuffer) -> Void, progress: @escaping (TimeInterval, Float, Float) -> Void, completion: @escaping (URL?, TimeInterval, NSError?) -> Void) {
        self.completion = completion
        do { file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false) }
        catch { completion(nil, 0, error as NSError); return }
        isRecording = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self, let file = self.file, file.framePosition < file.length else { timer.invalidate(); return }
            let count = AVAudioFrameCount(max(1, file.processingFormat.sampleRate * timer.timeInterval))
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: count) else { return }
            do {
                try file.read(into: buffer)
                audioBuffer(buffer)
                progress(Double(file.framePosition) / file.processingFormat.sampleRate, -20, -30)
            } catch { timer.invalidate(); self.isRecording = false; completion(nil, 0, error as NSError) }
        }
    }

    func wy_stopRecording(_ requestID: String, cancel: Bool) {
        timer?.invalidate()
        timer = nil
        isRecording = false
        let duration = file.map { Double($0.framePosition) / $0.processingFormat.sampleRate } ?? 0
        file = nil
        let completion = completion
        self.completion = nil
        completion?(cancel ? nil : url, duration, nil)
    }

    deinit { timer?.invalidate() }
}

/// 系统识别结果
private struct WYChatAppleRecognitionOutcome {
    let text: String?
    let error: NSError?
}

/// 用同一语音文件直接调用系统识别
@MainActor
private final class WYChatAppleRecognitionComparison {
    private var recognizer: SFSpeechRecognizer?
    private var task: SFSpeechRecognitionTask?
    private var timeout: DispatchWorkItem?
    private var continuation: CheckedContinuation<WYChatAppleRecognitionOutcome, Never>?

    func recognize(_ url: URL) async -> WYChatAppleRecognitionOutcome {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            guard let recognizer else { finish(nil, NSError(domain: "WYChatTests", code: 1)); return }
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = false
            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let result, result.isFinal { self.finish(result.bestTranscription.formattedString, error as NSError?) }
                    else if let error { self.finish(nil, error as NSError) }
                }
            }
            let timeout = DispatchWorkItem { [weak self] in self?.finish(nil, NSError(domain: "WYChatTests", code: 2)) }
            self.timeout = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: timeout)
        }
    }

    private func finish(_ text: String?, _ error: NSError?) {
        guard let continuation else { return }
        self.continuation = nil
        timeout?.cancel()
        timeout = nil
        task?.cancel()
        task = nil
        recognizer = nil
        continuation.resume(returning: WYChatAppleRecognitionOutcome(text: text, error: error))
    }
}

/// 收集聊天事件与接管结果
private final class WYChatViewEventsFixture: NSObject, WYChatViewDelegate, WYChatViewEventsHandler {
    var allowControls = true
    var voiceModes: [Bool] = []
    var emojiSelections = 0
    var emojiDeletes = 0
    var emojiSends = 0
    func wy_canManagerVoiceRecordEvents(_ longPress: UILongPressGestureRecognizer) -> Bool { allowControls }
    func wy_canManagerTextVoiceViewEvents(_ button: UIButton) -> Bool { allowControls }
    func wy_canManagerTextEmojiViewEvents(_ button: UIButton) -> Bool { allowControls }
    func wy_canManagerMoreViewEvents(_ button: UIButton) -> Bool { allowControls }
    func wy_canManagerEmojiViewClickEvents(_ view: WYChatEmojiView, indexPath: IndexPath) -> Bool { allowControls }
    func wy_canManagerEmojiDeleteViewClickEvents(_ button: UIButton) -> Bool { allowControls }
    func wy_canManagerEmojiSendViewClickEvents(_ button: UIButton) -> Bool { allowControls }
    func wy_canManagerMoreViewClickEvents(_ view: WYChatMoreView, itemIndex: Int) -> Bool { allowControls }
    func wy_didClickTextVoiceView(isText: Bool) { voiceModes.append(isText) }
    func wy_didClickEmojiView(_ emojiView: WYChatEmojiView, indexPath: IndexPath) { emojiSelections += 1 }
    func wy_didClickEmojiSendView(_ button: UIButton) { emojiSends += 1 }
    func wy_didClickEmojiDeleteView(_ button: UIButton) { emojiDeletes += 1 }
    var allowAction = true
    var allowKeyboardSend = true
    var allowApplication = true
    var allowKeyboardLifecycle = true
    var actions = 0
    var keyboardMessages: [String] = []
    var moreToggles = 0
    var emojiToggles = 0
    var activeEvents = 0
    var keyboardShows = 0
    var keyboardHides = 0
    var recordingResults = 0
    var recordingURL: URL?
    weak var application: UIApplication?

    func wy_shouldPerformMessageAction(_ chatView: WYChatView, action: WYChatAction, messageID: String) -> Bool { allowAction }
    var playbackRates: [Float] = []
    func wy_voicePlaybackRateChanged(_ chatView: WYChatView, messageID: String, rate: Float) { playbackRates.append(rate) }
    func wy_messageAction(_ chatView: WYChatView, action: WYChatAction, messageID: String) { actions += 1 }
    func wy_canManagerKeyboardSendEvents(_ text: String) -> Bool { allowKeyboardSend }
    func wy_keyboardSendMessage(messageID: String) { keyboardMessages.append(messageID) }
    func wy_didClickMoreView(isText: Bool) { moreToggles += 1 }
    func wy_didClickEmojiTextView(isText: Bool) { emojiToggles += 1 }
    func wy_canManagerApplicationDidBecomeActiveEvents(_ application: UIApplication) -> Bool { allowApplication }
    func wy_applicationDidBecomeActive(_ application: UIApplication) { self.application = application; activeEvents += 1 }
    func wy_canManagerKeyboardWillShowEvents(_ notification: Notification) -> Bool { allowKeyboardLifecycle }
    func wy_canManagerKeyboardWillDismissEvents() -> Bool { allowKeyboardLifecycle }
    func wy_keyboardWillShow(_ notification: Notification) { keyboardShows += 1 }
    func wy_keyboardWillDismiss() { keyboardHides += 1 }
    func wy_recordingFinished(_ chatView: WYChatView, url: URL?, duration: TimeInterval, error: NSError?) { recordingURL = url; recordingResults += 1 }
}

/// 可控制返回时机的外部翻译实现
private final class WYChatTranslationFixture: NSObject, WYChatTextTranslator {
    var requests = 0
    var cancels = 0
    var target = ""
    var output = "外部翻译结果"
    var completes = true
    private var completion: ((String?, NSError?) -> Void)?
    func wy_translateText(_ requestID: String, text: String, sourceLocaleIdentifier: String?, targetLocaleIdentifier: String, completion: @escaping (String?, NSError?) -> Void) {
        requests += 1
        target = targetLocaleIdentifier
        self.completion = completion
        if completes { completion(output, nil) }
    }
    func wy_cancelTranslation(_ requestID: String) { cancels += 1 }
    func completeAgain() { completion?(output, nil) }
}

/// 原图片浏览器的叠卡检查数据源
private final class WYChatBrowserStackFixture: NSObject, WYPhotoBrowserDataSource, WYPhotoBrowserDelegate {
    var items: [WYPhotoBrowserItem] = (0..<6).map { index in
        let image = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 160)).image { context in
            UIColor(hue: CGFloat(index) / 6, saturation: 0.6, brightness: 0.85, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 120, height: 160))
            NSString(string: "\(index + 1)").draw(at: CGPoint(x: 36, y: 48), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 36), .foregroundColor: UIColor.white])
        }
        var item = WYPhotoBrowserItem(localImage: image)
        item.identifier = "browser-stack-\(index)"
        return item
    }
    var shown: [Int] = []
    var taps = 0
    func numberOfItems(in photoBrowser: WYPhotoBrowser) -> Int { items.count }
    func photoBrowser(_ photoBrowser: WYPhotoBrowser, itemAt index: Int) -> Any { items.indices.contains(index) ? items[index] : WYPhotoBrowserItem() }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didShowItemAt index: Int) { shown.append(index) }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didTapItemAt index: Int) { taps += 1 }
}

/// 本地可解码的视频测试素材
@MainActor
private enum WYChatVideoFixture {
    static func write(to url: URL) async throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 160, AVVideoHeightKey: 120])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: 160, kCVPixelBufferHeightKey as String: 120])
        guard writer.canAdd(input) else { throw NSError(domain: "WYChatVideoFixture", code: 1) }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? NSError(domain: "WYChatVideoFixture", code: 2) }
        writer.startSession(atSourceTime: .zero)
        for frame in 0..<96 {
            var attempts = 0
            while !input.isReadyForMoreMediaData && attempts < 200 {
                attempts += 1
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            guard input.isReadyForMoreMediaData, let pool = adaptor.pixelBufferPool else { writer.cancelWriting(); throw writer.error ?? NSError(domain: "WYChatVideoFixture", code: 3) }
            var buffer: CVPixelBuffer?
            guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess, let buffer else { writer.cancelWriting(); throw NSError(domain: "WYChatVideoFixture", code: 4) }
            CVPixelBufferLockBaseAddress(buffer, [])
            if let base = CVPixelBufferGetBaseAddress(buffer), let context = CGContext(data: base, width: 160, height: 120, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) {
                context.setFillColor(UIColor(hue: CGFloat(frame) / 96, saturation: 0.7, brightness: 0.85, alpha: 1).cgColor)
                context.fill(CGRect(x: 0, y: 0, width: 160, height: 120))
            }
            CVPixelBufferUnlockBaseAddress(buffer, [])
            guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(frame), timescale: 24)) else { writer.cancelWriting(); throw writer.error ?? NSError(domain: "WYChatVideoFixture", code: 5) }
        }
        input.markAsFinished()
        await withCheckedContinuation { continuation in writer.finishWriting { continuation.resume() } }
        guard writer.status == .completed else { throw writer.error ?? NSError(domain: "WYChatVideoFixture", code: 6) }
    }
}
