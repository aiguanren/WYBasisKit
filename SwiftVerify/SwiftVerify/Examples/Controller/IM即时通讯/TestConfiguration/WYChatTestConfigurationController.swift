//
//  WYChatTestConfigurationController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/11/11.
//

import UIKit

/// 可搜索和逐项调整的聊天配置测试页
final class WYChatTestConfigurationController: UITableViewController, UISearchResultsUpdating, UIColorPickerViewControllerDelegate {
    private weak var chatView: WYChatView?
    private let initialConfiguration: WYChatConfig
    private let fields: [WYChatTestConfigurationField]
    private let screenTitle: String
    private var previewStyle: WYChatMessageStyle?
    private var previewsToast = false
    private var filtered: [WYChatTestConfigurationField] = []
    private var filterQuery = ""
    private let search = UISearchController(searchResultsController: nil)
    private var pendingColor: WYChatTestConfigurationField?
    private var didChooseColor = false
    var showRelatedTests: ((_ query: String) -> Void)?

    init(chatView: WYChatView, fields: [WYChatTestConfigurationField]? = nil, title: String = "全部配置", previewStyle: WYChatMessageStyle? = nil) {
        self.fields = fields ?? WYChatTestConfigurationFields.all
        screenTitle = title
        self.previewStyle = previewStyle
        self.chatView = chatView
        initialConfiguration = chatView.configuration
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = screenTitle
        definesPresentationContext = true
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.hidesNavigationBarDuringPresentation = false
        search.searchBar.placeholder = "属性路径、说明或类型"
        navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "预览", style: .plain, target: self, action: #selector(preview)), UIBarButtonItem(title: "复原", style: .plain, target: self, action: #selector(restore))]
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textAlignment = .center
        let direct = fields.filter { $0.apply != nil || $0.path == "contentOverrides" || $0.path == "media.browser.appearance.toastConfig" }.count
        label.text = "可直接调整\(direct)项 · 专项检查\(fields.count - direct)项\n修改即时应用，左划可恢复单字段默认值\n复原恢复进入本页前的配置"
        label.accessibilityIdentifier = "WYChatConfiguration.summary"
        label.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: UIDevice.wy_screenHeight(88, WYBasisKitConfig.defaultScreenPixels))
        tableView.tableHeaderView = label
        tableView.accessibilityIdentifier = "WYChatConfiguration.fields"
        updateSearchResults(for: search)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !search.isActive { search.searchBar.text = filterQuery }
    }
    func updateSearchResults(for searchController: UISearchController) {
        if searchController.isActive { filterQuery = searchController.searchBar.text ?? "" }
        let query = filterQuery
        filtered = fields.filter { query.isEmpty || ($0.path + " " + $0.title + " " + $0.type).localizedCaseInsensitiveContains(query) }
        tableView.reloadData()
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "configuration") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "configuration")
        let field = filtered[indexPath.row]
        cell.accessibilityIdentifier = "WYChatConfiguration.field." + field.path
        cell.textLabel?.text = field.path
        cell.textLabel?.font = .preferredFont(forTextStyle: .subheadline)
        cell.textLabel?.numberOfLines = 0
        let config = chatView?.configuration ?? initialConfiguration
        cell.detailTextLabel?.text = field.title + "\n" + field.type + " · " + String(field.read(config).prefix(180)) + (field.path == "contentOverrides" ? "\n按消息类型逐项调整" : field.path == "media.browser.appearance.toastConfig" ? "\n调整提示字体和颜色" : field.kind == .special ? "\n通过专项用例验证" : "")
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryView = nil
        cell.accessoryType = .disclosureIndicator
        if field.kind == .boolean {
            let toggle = UISwitch()
            toggle.accessibilityIdentifier = "WYChatConfiguration.switch." + field.path
            toggle.isOn = field.read(config) == "true"
            toggle.addAction(UIAction { [weak self, weak toggle] _ in guard let self, let toggle else { return }; _ = self.apply(field, text: String(toggle.isOn)) }, for: .valueChanged)
            cell.accessoryView = toggle
            cell.accessoryType = .none
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let field = filtered[indexPath.row]
        if field.kind == .boolean { return }
        withSearchClosed { [weak self] in self?.open(field) }
    }
    private func withSearchClosed(_ action: @escaping @MainActor () -> Void) {
        guard search.isActive else { action(); return }
        filterQuery = search.searchBar.text ?? ""
        if search.presentingViewController != nil {
            search.dismiss(animated: false) { [weak self] in
                guard let self else { return }
                self.search.isActive = false
                self.search.searchBar.text = self.filterQuery
                self.updateSearchResults(for: self.search)
                action()
            }
        } else {
            search.isActive = false
            search.searchBar.text = filterQuery
            updateSearchResults(for: search)
            action()
        }
    }
    private func open(_ field: WYChatTestConfigurationField) {
        guard let chatView else { return }
        switch field.kind {
        case .boolean: _ = apply(field, text: String(field.read(chatView.configuration) != "true"))
        case .color:
            pendingColor = field
            didChooseColor = false
            let picker = UIColorPickerViewController()
            picker.selectedColor = field.color?(chatView.configuration) ?? .clear
            picker.supportsAlpha = true
            picker.delegate = self
            present(picker, animated: true)
        case .text:
            let editor = WYChatTestConfigurationValueController(field: field, value: field.read(chatView.configuration))
            editor.applyValue = { [weak self] value in self?.apply(field, text: value) ?? false }
            navigationController?.pushViewController(editor, animated: true)
        case .special:
            if field.path == "contentOverrides" { showContentOverrides(); return }
            if field.path == "media.browser.appearance.toastConfig" {
                let controller = WYChatTestConfigurationController(chatView: chatView, fields: WYChatTestAdvancedConfigurationChecks.toastFields, title: "保存结果提示")
                controller.previewsToast = true
                navigationController?.pushViewController(controller, animated: true)
                return
            }
            let alert = UIAlertController(title: field.path, message: field.title + "\n" + field.type + "\n使用专项用例检查外部对象、回调或组合配置", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "相关检查", style: .default) { [weak self] _ in self?.showRelatedTests?(field.help) })
            alert.addAction(UIAlertAction(title: "恢复默认", style: .default) { [weak self] _ in self?.reset(field) })
            alert.addAction(UIAlertAction(title: "关闭", style: .cancel))
            present(alert, animated: true)
        }
    }
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let field = filtered[indexPath.row]
        let reset = UIContextualAction(style: .normal, title: "默认") { [weak self] _, _, completion in self?.reset(field); completion(true) }
        reset.backgroundColor = .systemIndigo
        var actions = [reset]
        if let clear = field.clear {
            let action = UIContextualAction(style: .normal, title: field.clearTitle) { [weak self] _, _, completion in
                if let self, var config = self.chatView?.configuration { clear(&config); self.chatView?.configuration = config; self.tableView.reloadData() }
                completion(true)
            }
            action.backgroundColor = .systemOrange
            actions.append(action)
        }
        return UISwipeActionsConfiguration(actions: actions)
    }
    private func showContentOverrides() {
        guard let chatView else { return }
        let controller = WYChatTestConfigurationTypeController()
        controller.selectStyle = { [weak self, weak chatView] style, name, key in
            guard let self, let chatView else { return }
            let fields = WYChatTestConfigurationFields.all.filter { $0.path.hasPrefix("content.") }.map { $0.contentOverride(style, key: key) }
            let editor = WYChatTestConfigurationController(chatView: chatView, fields: fields, title: "覆盖·" + name, previewStyle: style)
            editor.showRelatedTests = self.showRelatedTests
            self.navigationController?.pushViewController(editor, animated: true)
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func apply(_ field: WYChatTestConfigurationField, text: String) -> Bool {
        guard var config = chatView?.configuration, field.apply?(&config, text) == true else { return false }
        chatView?.configuration = config
        tableView.reloadData()
        return true
    }
    private func reset(_ field: WYChatTestConfigurationField) {
        guard var config = chatView?.configuration else { return }
        field.reset(&config)
        chatView?.configuration = config
        tableView.reloadData()
    }
    @objc(colorPickerViewController:didSelectColor:continuously:)
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) { didChooseColor = true }
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        if didChooseColor, let field = pendingColor, var config = chatView?.configuration { field.setColor?(&config, viewController.selectedColor); chatView?.configuration = config; tableView.reloadData() }
        pendingColor = nil
    }
    @objc private func restore() { chatView?.configuration = initialConfiguration; tableView.reloadData() }
    @objc private func preview() {
        withSearchClosed { [weak self] in
            guard let self, let chatView = self.chatView else { return }
            if self.previewsToast {
                WYActivity.showInfo("保存结果提示预览", in: self.view, position: .middle, config: chatView.configuration.media.browser.appearance.toastConfig ?? WYActivityConfig.info)
                return
            }
            self.navigationController?.pushViewController(WYChatTestConfigurationPreviewController(source: chatView, style: self.previewStyle), animated: true)
        }
    }
}

/// 消息类型配置入口
final class WYChatTestConfigurationTypeController: UITableViewController {
    private let names = ["未知", "文本", "语音", "图片", "音乐", "视频", "红包", "转账", "位置", "拍一拍", "撤回", "通话", "网页", "文件", "名片", "聊天记录", "媒体组"]
    private let keys = ["none", "text", "voice", "photo", "music", "video", "luckyMoney", "transfer", "location", "takePat", "withdrawn", "call", "webpage", "file", "businessCard", "chatRecords", "mediaGroup"]
    var selectStyle: ((_ style: WYChatMessageStyle, _ name: String, _ key: String) -> Void)?
    init() { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "按消息类型调整"
        tableView.accessibilityIdentifier = "WYChatConfiguration.messageTypes"
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { WYChatMessageStyle.allCases.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageType") ?? UITableViewCell(style: .default, reuseIdentifier: "messageType")
        let style = WYChatMessageStyle.allCases[indexPath.row]
        cell.textLabel?.text = names[style.rawValue]
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = "WYChatConfiguration.messageType." + keys[style.rawValue]
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let style = WYChatMessageStyle.allCases[indexPath.row]
        selectStyle?(style, names[style.rawValue], keys[style.rawValue])
    }
}

/// 单项配置输入与校验
final class WYChatTestConfigurationValueController: UIViewController {
    private let field: WYChatTestConfigurationField
    private let initialValue: String
    private let textView = UITextView()
    private let errorLabel = UILabel()
    var applyValue: ((_ value: String) -> Bool)?
    init(field: WYChatTestConfigurationField, value: String) { self.field = field; initialValue = value; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = field.path
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "应用", style: .done, target: self, action: #selector(apply))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "WYChatConfiguration.apply"
        let hint = UITextView()
        hint.isEditable = false
        hint.backgroundColor = .clear
        hint.font = .preferredFont(forTextStyle: .footnote)
        hint.text = field.title + "\n" + field.type + "\n" + field.help
        textView.font = .monospacedSystemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels), weight: .regular)
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.accessibilityIdentifier = "WYChatConfiguration.value"
        textView.text = field.type.hasPrefix("UIImage") ? "" : initialValue
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        errorLabel.textColor = .systemRed
        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        errorLabel.numberOfLines = 0
        errorLabel.accessibilityIdentifier = "WYChatConfiguration.error"
        for item in [hint, textView, errorLabel] { item.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(item) }
        let padding = UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels)
        NSLayoutConstraint.activate([
            hint.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), hint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding), hint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding), hint.heightAnchor.constraint(equalToConstant: UIDevice.wy_screenHeight(100, WYBasisKitConfig.defaultScreenPixels)),
            textView.topAnchor.constraint(equalTo: hint.bottomAnchor, constant: padding), textView.leadingAnchor.constraint(equalTo: hint.leadingAnchor), textView.trailingAnchor.constraint(equalTo: hint.trailingAnchor),
            errorLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: padding), errorLabel.leadingAnchor.constraint(equalTo: hint.leadingAnchor), errorLabel.trailingAnchor.constraint(equalTo: hint.trailingAnchor), errorLabel.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -padding), errorLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: UIDevice.wy_screenHeight(28, WYBasisKitConfig.defaultScreenPixels))
        ])
    }
    @objc private func apply() {
        guard applyValue?(textView.text ?? "") == true else { errorLabel.text = "格式或数值无效，配置未更改"; return }
        textView.resignFirstResponder()
        navigationController?.popViewController(animated: true)
    }
}

/// 当前配置的完整聊天预览
final class WYChatTestConfigurationPreviewController: UIViewController {
    let chatView: WYChatView
    init(source: WYChatView, style: WYChatMessageStyle? = nil) { chatView = WYChatView(userInfo: source.userInfo, configuration: source.configuration); chatView.dataSource = style.map { selected in source.dataSource.filter { $0.content.style() == selected } } ?? source.dataSource; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "配置预览"
        chatView.tableView.accessibilityIdentifier = "WYChatConfiguration.previewMessages"
        view.backgroundColor = chatView.configuration.backgroundColor
        chatView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatView)
        NSLayoutConstraint.activate([chatView.leadingAnchor.constraint(equalTo: view.leadingAnchor), chatView.trailingAnchor.constraint(equalTo: view.trailingAnchor), chatView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), chatView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }
    deinit { chatView.releaseAll() }
}

/// 聊天常用设置，保存后统一应用到聊天页面
final class WYChatSettingsController: UITableViewController, UIColorPickerViewControllerDelegate {
    var showRelatedTests: ((String) -> Void)?
    private struct Item {
        let title: String
        let path: String
        var choices: [(String, String)] = []
        var explanation = ""
    }
    private weak var chatView: WYChatView?
    private let draftView: WYChatView
    private var pendingColor: WYChatTestConfigurationField?
    private var groups: [(String, [Item])] = []
    private let fields = WYChatSettingsController.makeFields()

    private static func makeFields() -> [String: WYChatTestConfigurationField] {
        var fields = Dictionary(uniqueKeysWithValues: WYChatTestConfigurationFields.all.map { ($0.path, $0) })
        fields["basic.avatarSize.width"] = .scalar("basic.avatarSize.width", "头像尺寸", "CGFloat", get: { Double($0.basic.avatarSize.width) }, set: { $0.basic.avatarSize.width = CGFloat($1) })
        fields["basic.avatarSize.height"] = .scalar("basic.avatarSize.height", "头像尺寸", "CGFloat", get: { Double($0.basic.avatarSize.height) }, set: { $0.basic.avatarSize.height = CGFloat($1) })
        fields["input.voiceTextButtonSize.width"] = .scalar("input.voiceTextButtonSize.width", "语音切换按钮尺寸", "CGFloat", get: { Double($0.input.voiceTextButtonSize.width) }, set: { $0.input.voiceTextButtonSize.width = CGFloat($1) })
        fields["input.voiceTextButtonSize.height"] = .scalar("input.voiceTextButtonSize.height", "语音切换按钮尺寸", "CGFloat", get: { Double($0.input.voiceTextButtonSize.height) }, set: { $0.input.voiceTextButtonSize.height = CGFloat($1) })
        fields["input.emojiTextButtonSize.width"] = .scalar("input.emojiTextButtonSize.width", "表情切换按钮尺寸", "CGFloat", get: { Double($0.input.emojiTextButtonSize.width) }, set: { $0.input.emojiTextButtonSize.width = CGFloat($1) })
        fields["input.emojiTextButtonSize.height"] = .scalar("input.emojiTextButtonSize.height", "表情切换按钮尺寸", "CGFloat", get: { Double($0.input.emojiTextButtonSize.height) }, set: { $0.input.emojiTextButtonSize.height = CGFloat($1) })
        fields["recording.gradientWaveformSize.width"] = .scalar("recording.gradientWaveformSize.width", "渐变声波尺寸", "CGFloat", get: { Double($0.recording.gradientWaveformSize.width) }, set: { $0.recording.gradientWaveformSize.width = CGFloat($1) })
        fields["recording.gradientWaveformSize.height"] = .scalar("recording.gradientWaveformSize.height", "渐变声波尺寸", "CGFloat", get: { Double($0.recording.gradientWaveformSize.height) }, set: { $0.recording.gradientWaveformSize.height = CGFloat($1) })
        return fields
    }

    init(chatView: WYChatView) {
        self.chatView = chatView
        draftView = WYChatView(userInfo: chatView.userInfo, configuration: chatView.configuration)
        draftView.dataSource = chatView.dataSource
        super.init(style: .insetGrouped)
        groups = [
            ("输入方式", [
                Item(title: "长按消息时整行高亮", path: "highlightsEntireCellOnLongPress"),
                Item(title: "长按菜单与头像的最小间距", path: "menuPreviewAvatarSpacing"),
                Item(title: "点击消息列表收起输入", path: "dismissInputOnTap"),
                Item(title: "输入框操作", path: "inputBehavior", choices: [("切换到语音模式后录音", "0"), ("单击输入，长按发语音", "1"), ("单击输入，长按识别", "2")], explanation: "单击输入框弹出键盘，长按适用于空输入框"),
                Item(title: "占位文字位置", path: "input.textPlaceholderAlignment", choices: [("居左", "0"), ("居中", "1"), ("居右", "2")]),
                Item(title: "占位提示文字", path: "input.textPlaceholder"),
                Item(title: "键盘内显示语音识别按钮", path: "input.enablesKeyboardDictation"),
                Item(title: "手动修改文本时关闭语音识别", path: "input.stopsKeyboardDictationOnTextChange"),
                Item(title: "长按语音图标转文字", path: "input.enablesVoiceButtonDictation")
            ]),
            ("语音录制与识别", [
                Item(title: "启用语音识别", path: "recording.supportSpeechRecognition"),
                Item(title: "录音交互效果", path: "recording.interactionStyle", choices: [("分区操作", "0"), ("底部渐变声波", "1")]),
                Item(title: "分区按钮外观", path: "recording.actionStyle", choices: [("圆形", "0"), ("弧形", "1")]),
                Item(title: "长按识别显示声波", path: "recording.dictationShowsWaveform"),
                Item(title: "转文字后松手直接发送", path: "recording.dictationSendsOnRelease", explanation: "关闭后进入文字编辑界面，确认后发送"),
                Item(title: "识别时机", path: "recording.speechRecognitionMode", choices: [("边录音边识别", "0"), ("录音结束后识别", "1")]),
                Item(title: "识别服务", path: "recording.speechRecognitionSource", choices: [("Apple 系统识别", "0"), ("宿主接入的识别服务", "1")], explanation: "外部服务需要宿主提供识别实现"),
                Item(title: "识别语言", path: "recording.speechLocaleIdentifier", choices: [("跟随系统语言", Locale.preferredLanguages.first ?? Locale.current.identifier), ("简体中文", "zh-CN"), ("繁體中文", "zh-TW"), ("English", "en-US"), ("日本語", "ja-JP"), ("한국어", "ko-KR")]),
                Item(title: "仅使用设备本地识别", path: "recording.requiresOnDeviceRecognition"),
                Item(title: "最长录音秒数", path: "recording.recordTime.max")
            ]),
            ("渐变声波外观", [
                Item(title: "渐变流动动画", path: "recording.gradientMotionEnabled"),
                Item(title: "渐变流动周期（秒）", path: "recording.gradientMotionDuration"),
                Item(title: "手指按压效果", path: "recording.gradientPressEnabled"),
                Item(title: "按压效果颜色", path: "recording.gradientPressColor"),
                Item(title: "按压效果不透明度", path: "recording.gradientPressOpacity"),
                Item(title: "录音渐变颜色", path: "recording.gradientRecordingColor"),
                Item(title: "取消渐变颜色", path: "recording.gradientCancelColor"),
                Item(title: "普通声波颜色", path: "recording.gradientWaveform.wavesColor"),
                Item(title: "取消声波颜色", path: "recording.gradientCancelWaveformColor"),
                Item(title: "普通提示文字颜色", path: "recording.gradientHintColor"),
                Item(title: "取消提示文字颜色", path: "recording.gradientCancelHintColor"),
                Item(title: "渐变高度", path: "recording.gradientHeight"),
                Item(title: "声波宽度", path: "recording.gradientWaveformSize.width"),
                Item(title: "声波高度", path: "recording.gradientWaveformSize.height"),
                Item(title: "声波底部间距", path: "recording.gradientWaveformBottomOffset"),
                Item(title: "提示与声波间距", path: "recording.gradientHintSpacing"),
                Item(title: "提示字体大小", path: "recording.gradientHintFont"),
                Item(title: "上滑取消距离", path: "recording.gradientCancelDistance")
            ]),
            ("头像与昵称", [
                Item(title: "显示自己的头像", path: "sender.showsAvatar"),
                Item(title: "显示对方的头像", path: "receiver.showsAvatar"),
                Item(title: "单聊显示自己的昵称", path: "sender.showsSingleNickname"),
                Item(title: "单聊显示对方的昵称", path: "receiver.showsSingleNickname"),
                Item(title: "群聊显示自己的昵称", path: "sender.showsGroupNickname"),
                Item(title: "群聊显示对方的昵称", path: "receiver.showsGroupNickname"),
                Item(title: "头像宽度", path: "basic.avatarSize.width"),
                Item(title: "头像高度", path: "basic.avatarSize.height"),
                Item(title: "自己头像与消息间距", path: "sender.contentSpacing"),
                Item(title: "对方头像与消息间距", path: "receiver.contentSpacing"),
                Item(title: "昵称字体大小", path: "basic.nicknameFont"),
                Item(title: "显示已读与未读", path: "basic.showReadMark"),
                Item(title: "已读提示文字", path: "basic.readText"),
                Item(title: "未读提示文字", path: "basic.unreadText")
            ]),
            ("消息与输入栏外观", [
                Item(title: "消息间距", path: "messageSpacing"),
                Item(title: "自己发送的气泡颜色", path: "senderBubble.fillColor"),
                Item(title: "对方发送的气泡颜色", path: "receiverBubble.fillColor"),
                Item(title: "消息文字大小", path: "text.textFont"),
                Item(title: "输入文字大小", path: "input.textFont"),
                Item(title: "输入栏背景颜色", path: "input.backgroundColor"),
                Item(title: "语音切换按钮宽度", path: "input.voiceTextButtonSize.width"),
                Item(title: "语音切换按钮高度", path: "input.voiceTextButtonSize.height"),
                Item(title: "表情切换按钮宽度", path: "input.emojiTextButtonSize.width"),
                Item(title: "表情切换按钮高度", path: "input.emojiTextButtonSize.height"),
                Item(title: "媒体消息展示", path: "media.presentation", choices: [("逐条展示", "0"), ("合并展示", "1")])
            ]),
            ("高级与恢复", [Item(title: "全部属性设置", path: "advanced", explanation: "完整属性目录与专项预览"), Item(title: "恢复默认设置", path: "defaults")])
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "聊天设置"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .done, target: self, action: #selector(save))
        tableView.accessibilityIdentifier = "WYChatSettings.groups"
        let hint = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: UIDevice.wy_screenHeight(64, WYBasisKitConfig.defaultScreenPixels)))
        hint.text = "选择需要的效果，点击保存后返回聊天页\n返回而不保存时，聊天页保持原设置"
        hint.textAlignment = .center
        hint.numberOfLines = 0
        hint.font = .preferredFont(forTextStyle: .footnote)
        tableView.tableHeaderView = hint
    }

    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); tableView.reloadData() }
    override func numberOfSections(in tableView: UITableView) -> Int { groups.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { groups[section].0 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { groups[section].1.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = groups[indexPath.section].1[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = item.title
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        let value = fields[item.path]?.read(draftView.configuration) ?? ""
        if item.path == "inputBehavior" {
            cell.detailTextLabel?.text = item.choices.first { $0.1 == String(draftView.configuration.input.placeholderLongPressAction.rawValue) }?.0
        } else if let field = fields[item.path], field.kind == .boolean {
            let toggle = UISwitch()
            toggle.isOn = value == "true"
            toggle.accessibilityIdentifier = "WYChatSettings.switch." + item.path
            toggle.addAction(UIAction { [weak self, weak toggle] _ in
                guard let self, let toggle else { return }
                self.apply(field, text: String(toggle.isOn))
            }, for: .valueChanged)
            cell.accessoryView = toggle
            cell.accessoryType = .none
        } else if fields[item.path]?.kind == .color {
            let swatch = UIView(frame: CGRect(x: 0, y: 0, width: UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels)))
            swatch.backgroundColor = fields[item.path]?.color?(draftView.configuration)
            swatch.layer.cornerRadius = UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels)
            cell.accessoryView = swatch
        } else if fields[item.path]?.type == "UIFont" { cell.detailTextLabel?.text = (value.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? "") + " 号" }
        else { cell.detailTextLabel?.text = item.choices.first(where: { $0.1 == value })?.0 ?? value }
        if !item.explanation.isEmpty { cell.detailTextLabel?.text = [cell.detailTextLabel?.text ?? "", item.explanation].filter { !$0.isEmpty }.joined(separator: "\n") }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = groups[indexPath.section].1[indexPath.row]
        if item.path == "defaults" {
            let alert = UIAlertController(title: "恢复默认设置？", message: "点击保存后应用到聊天页", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "恢复默认", style: .destructive) { [weak self] _ in self?.draftView.configuration = WYChatConfig(); self?.tableView.reloadData() })
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            present(alert, animated: true)
            return
        }
        if item.path == "advanced" {
            let controller = WYChatTestConfigurationController(chatView: draftView)
            controller.showRelatedTests = showRelatedTests
            navigationController?.pushViewController(controller, animated: true)
            return
        }
        if !item.choices.isEmpty {
            let alert = UIAlertController(title: item.title, message: item.explanation.isEmpty ? nil : item.explanation, preferredStyle: .actionSheet)
            for choice in item.choices {
                alert.addAction(UIAlertAction(title: choice.0, style: .default) { [weak self] _ in
                    guard let self else { return }
                    if item.path == "inputBehavior" {
                        var config = self.draftView.configuration
                        config.input.placeholderLongPressAction = WYChatInputLongPressAction(rawValue: Int(choice.1) ?? 0) ?? .disabled
                        if config.input.placeholderLongPressAction == .dictation { config.recording.supportSpeechRecognition = true }
                        self.draftView.configuration = config
                    } else if let field = self.fields[item.path] { self.apply(field, text: choice.1) }
                    self.tableView.reloadData()
                })
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
            alert.popoverPresentationController?.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? .zero
            present(alert, animated: true)
            return
        }
        guard let field = fields[item.path] else { return }
        if field.kind == .boolean { return }
        if field.kind == .color {
            pendingColor = field
            let picker = UIColorPickerViewController()
            picker.selectedColor = field.color?(draftView.configuration) ?? .clear
            picker.supportsAlpha = true
            picker.delegate = self
            present(picker, animated: true)
            return
        }
        let alert = UIAlertController(title: item.title, message: nil, preferredStyle: .alert)
        alert.addTextField { text in
            let value = field.read(self.draftView.configuration)
            text.text = field.type == "UIFont" ? value.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) : value
            text.keyboardType = field.type == "String" ? .default : .decimalPad
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self, weak alert] _ in
            guard let self, let text = alert?.textFields?.first?.text else { return }
            self.apply(field, text: text)
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func apply(_ field: WYChatTestConfigurationField, text: String) {
        var config = draftView.configuration
        guard field.apply?(&config, text) == true else {
            let alert = UIAlertController(title: "这个值不能使用", message: "请检查输入的内容和数值范围", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .cancel))
            present(alert, animated: true)
            return
        }
        draftView.configuration = config
    }

    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        guard let field = pendingColor else { return }
        var config = draftView.configuration
        field.setColor?(&config, viewController.selectedColor)
        draftView.configuration = config
        tableView.reloadData()
    }

    @objc private func save() {
        let config = draftView.configuration
        if config.recording.supportSpeechRecognition && config.recording.speechRecognitionSource == .external && config.recording.speechRecognitionProvider == nil {
            let alert = UIAlertController(title: "外部识别服务尚未接入", message: "请选择 Apple 系统识别，或由宿主先提供识别服务", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .cancel))
            present(alert, animated: true)
            return
        }
        chatView?.configuration = config
        chatView?.layoutIfNeeded()
        dismiss(animated: true)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
