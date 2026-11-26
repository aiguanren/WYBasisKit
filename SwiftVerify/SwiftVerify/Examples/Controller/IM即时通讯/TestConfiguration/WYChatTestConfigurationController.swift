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
    private let names = ["未知", "文本", "语音", "图片", "音乐", "视频", "红包", "转账", "位置", "拍一拍", "撤回", "通话", "网页", "文件", "名片", "聊天记录", "媒体组", "收款回执"]
    private let keys = ["none", "text", "voice", "photo", "music", "video", "luckyMoney", "transfer", "location", "takePat", "withdrawn", "call", "webpage", "file", "businessCard", "chatRecords", "mediaGroup", "fundsReceipt"]
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
        let explanation: String
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
            ("长按消息后的菜单", [
                Item(title: "长按时使用系统整行预览", path: "highlightsEntireCellOnLongPress", explanation: "开启时突出整条消息并弹出系统菜单。关闭时气泡留在原位，菜单出现在气泡上方或下方。"),
                Item(title: "气泡旁菜单与头像的最小横向间距", path: "menuPreviewAvatarSpacing", explanation: "调整菜单边缘与这条消息头像之间的横向距离，单位为点。列表可用宽度不足时会缩小间距。"),
                Item(title: "气泡旁菜单背景色", path: "menuBackgroundColor", explanation: "调整长按消息后，气泡旁整块菜单面板的底色。"),
                Item(title: "气泡旁菜单普通按钮颜色", path: "menuTextColor", explanation: "调整「复制」「转发」等普通按钮的文字和图标颜色。"),
                Item(title: "气泡旁菜单「删除」按钮颜色", path: "menuDestructiveTextColor", explanation: "调整长按消息后「删除」按钮的文字和图标颜色。"),
                Item(title: "气泡旁菜单按钮字号", path: "menuItemFont", explanation: "调整长按菜单按钮下方「复制」「引用」等文字的大小。"),
                Item(title: "气泡旁菜单每行最多显示几项", path: "menuMaximumColumns", explanation: "例如设为 3，菜单每行最多排 3 个按钮，其余按钮换行。宽度不足时会自动少排。"),
                Item(title: "长按消息菜单的按钮与顺序", path: "menuActions", explanation: "选择长按消息后可出现的按钮，例如「复制」「引用」「删除」。实际显示项取决于消息类型和当前状态。")
            ]),
            ("底部输入栏与键盘", [
                Item(title: "点击消息列表时收起键盘和面板", path: "dismissInputOnTap", explanation: "轻点消息气泡、头像或列表空白处时，收起底部键盘、表情面板或「＋」面板。"),
                Item(title: "空输入框的长按操作", path: "inputBehavior", choices: [("切换到语音模式后录音", "0"), ("单击输入，长按发语音", "1"), ("单击输入，长按识别", "2")], explanation: "针对聊天页底部没有文字的输入框。轻点打开键盘，长按可录音发语音或转成文字。"),
                Item(title: "长按空输入框的录音界面", path: "input.placeholderRecordingInteractionStyle", choices: [("分区操作", "0"), ("底部渐变声波", "1")], explanation: "在文字输入模式直接长按空输入框时使用，默认显示底部渐变声波。"),
                Item(title: "空输入框提示文字的对齐位置", path: "input.textPlaceholderAlignment", choices: [("居左", "0"), ("居中", "1"), ("居右", "2")], explanation: "调整空输入框里灰色提示文字的位置。选居中时，点进输入框后会靠左。"),
                Item(title: "空输入框的提示文字", path: "input.textPlaceholder", explanation: "输入框为空时显示的灰色文字，输入内容后消失。"),
                Item(title: "显示输入框右侧的语音识别按钮", path: "input.enablesKeyboardDictation", explanation: "展开键盘时，文字输入框右侧可出现麦克风按钮。需要先启用语音转文字。"),
                Item(title: "输入框有文字时仍显示麦克风按钮", path: "input.showsKeyboardDictationWithText", explanation: "控制文字输入框右侧的语音识别按钮在已有内容时是否仍可用于开始识别。"),
                Item(title: "编辑输入文字时结束语音识别", path: "input.stopsKeyboardDictationOnTextChange", explanation: "通过输入框右侧麦克风识别时，手动输入或删除文字会结束正在进行的识别。")
            ]),
            ("录音界面与语音转文字", [
                Item(title: "启用语音转文字", path: "recording.supportSpeechRecognition", explanation: "启用语音转文字后，可使用录音界面的转文字操作、语音消息的「转文字」和输入框右侧的麦克风按钮。"),
                Item(title: "语音模式「按住 说话」的录音界面", path: "recording.interactionStyle", choices: [("分区操作", "0"), ("底部渐变声波", "1")], explanation: "点输入框左侧按钮切到语音模式后，长按「按住 说话」时使用，默认显示分区操作。"),
                Item(title: "分区录音的「取消」与「转文字」按钮形状", path: "recording.actionStyle", choices: [("圆形", "0"), ("弧形", "1")], explanation: "使用「分区操作」样式时，调整录音界面下方两个操作区的形状。"),
                Item(title: "长按空输入框转文字时显示声波", path: "recording.dictationShowsWaveform", explanation: "使用「分区操作」样式直接转写时，控制录音界面内的音量声波是否显示。"),
                Item(title: "长按空输入框转文字，松手后发送", path: "recording.dictationSendsOnRelease", explanation: "长按空输入框转写时，开启后松手会自动发送识别结果。关闭后先进入文字编辑界面，确认后发送。"),
                Item(title: "录音何时开始转文字", path: "recording.speechRecognitionMode", choices: [("边录音边识别", "0"), ("录音结束后识别", "1")], explanation: "决定转写可在录音中返回文字，还是等录音完成后开始识别。"),
                Item(title: "语音转文字使用的识别服务", path: "recording.speechRecognitionSource", choices: [("Apple 系统识别", "0"), ("接入应用提供的识别服务", "1")], explanation: "外部识别服务需要由应用接入后才能使用。"),
                Item(title: "语音转文字识别语言", path: "recording.speechLocaleIdentifier", choices: [("系统首选语言", Locale.preferredLanguages.first ?? Locale.current.identifier), ("简体中文", "zh-CN"), ("繁體中文", "zh-TW"), ("English", "en-US"), ("日本語", "ja-JP"), ("한국어", "ko-KR")], explanation: "选择识别录音时使用的语言。"),
                Item(title: "语音转文字仅使用设备本地识别", path: "recording.requiresOnDeviceRecognition", explanation: "使用 Apple 识别时，设备和所选语言都需支持本地识别。"),
                Item(title: "单次录音最长时间（秒）", path: "recording.recordTime.max", explanation: "限制一次录音可持续的时间，到达上限后结束录音。"),
                Item(title: "长按发语音倒计时", path: "recording.voiceCountdown.leadTime", explanation: "剩余多少秒时显示，设为 0 关闭。"),
                Item(title: "长按转文字倒计时", path: "recording.dictationCountdown.leadTime", explanation: "长按直接识别或滑到转文字区域时使用。"),
                Item(title: "输入框麦克风倒计时", path: "recording.keyboardDictationCountdown.leadTime", explanation: "点击输入框内的麦克风开始识别时使用。")
            ]),
            ("底部渐变声波录音界面", [
                Item(title: "录音背景的渐变流动动画", path: "recording.gradientMotionEnabled", explanation: "录音时让底部渐变背景持续流动。"),
                Item(title: "录音背景的渐变流动周期（秒）", path: "recording.gradientMotionDuration", explanation: "数值越大，底部渐变背景流动越慢。"),
                Item(title: "录音时显示手指按压光晕", path: "recording.gradientPressEnabled", explanation: "在手指按住或滑动的位置显示跟随手指的光晕。"),
                Item(title: "手指按压光晕颜色", path: "recording.gradientPressColor", explanation: "调整跟随手指移动的光晕颜色。"),
                Item(title: "手指按压光晕不透明度", path: "recording.gradientPressOpacity", explanation: "调整光晕的可见程度，0 为透明，1 为不透明。"),
                Item(title: "正常录音时的底部渐变色", path: "recording.gradientRecordingColor", explanation: "调整手指仍在录音区域时的背景主色。"),
                Item(title: "上滑待取消时的底部渐变色", path: "recording.gradientCancelColor", explanation: "手指上滑进入待取消状态后，底部背景会切换到此颜色。"),
                Item(title: "正常录音时的声波颜色", path: "recording.gradientWaveform.wavesColor", explanation: "调整录音界面底部随音量跳动的声波颜色。"),
                Item(title: "上滑待取消时的声波颜色", path: "recording.gradientCancelWaveformColor", explanation: "手指进入待取消状态后，底部声波会切换到此颜色。"),
                Item(title: "正常录音时的提示文字颜色", path: "recording.gradientHintColor", explanation: "调整声波上方「松手发送，上滑取消」等提示的颜色。"),
                Item(title: "上滑待取消时的提示文字颜色", path: "recording.gradientCancelHintColor", explanation: "调整上滑后声波上方取消提示的颜色。"),
                Item(title: "录音底部渐变背景高度", path: "recording.gradientHeight", explanation: "调整渐变背景从聊天页底部向上铺开的高度，单位为点。"),
                Item(title: "录音界面底部的声波宽度", path: "recording.gradientWaveformSize.width", explanation: "调整随音量跳动的声波在水平方向占用的宽度，单位为点。"),
                Item(title: "录音界面底部的声波高度", path: "recording.gradientWaveformSize.height", explanation: "调整随音量跳动的声波在垂直方向占用的高度，单位为点。"),
                Item(title: "声波与屏幕底部安全区的距离", path: "recording.gradientWaveformBottomOffset", explanation: "数值越大，声波位置越靠上，单位为点。"),
                Item(title: "录音提示与声波之间的距离", path: "recording.gradientHintSpacing", explanation: "调整提示文字下沿与声波上沿之间的距离，单位为点。"),
                Item(title: "声波上方的录音提示字号", path: "recording.gradientHintFont", explanation: "调整「松手发送，上滑取消」等录音提示文字的大小。"),
                Item(title: "从按下位置上滑取消的距离", path: "recording.gradientCancelDistance", explanation: "录音时从手指按下的位置向上滑到该距离后，松手即取消。单位为点。")
            ]),
            ("消息列表的头像、昵称与阅读状态", [
                Item(title: "显示自己消息旁的头像", path: "sender.showsAvatar", explanation: "控制聊天列表右侧自己发出的消息旁是否显示头像。"),
                Item(title: "显示收到的消息旁的头像", path: "receiver.showsAvatar", explanation: "控制聊天列表左侧收到的消息旁是否显示发件人头像。"),
                Item(title: "单聊时在自己的气泡上方显示昵称", path: "sender.showsSingleNickname", explanation: "只影响一对一聊天中自己发出的消息。"),
                Item(title: "单聊时在对方的气泡上方显示昵称", path: "receiver.showsSingleNickname", explanation: "只影响一对一聊天中收到的消息。"),
                Item(title: "群聊时在自己的气泡上方显示昵称", path: "sender.showsGroupNickname", explanation: "只影响群聊中自己发出的消息。"),
                Item(title: "群聊时在成员的气泡上方显示昵称", path: "receiver.showsGroupNickname", explanation: "只影响群聊中其他成员发出的消息。"),
                Item(title: "消息气泡旁头像的宽度", path: "basic.avatarSize.width", explanation: "同时调整自己和其他人的头像宽度，单位为点。"),
                Item(title: "消息气泡旁头像的高度", path: "basic.avatarSize.height", explanation: "同时调整自己和其他人的头像高度，单位为点。"),
                Item(title: "自己的头像与消息气泡的距离", path: "sender.contentSpacing", explanation: "调整聊天列表右侧头像与气泡之间的横向间距，单位为点。"),
                Item(title: "其他人的头像与消息气泡的距离", path: "receiver.contentSpacing", explanation: "调整聊天列表左侧头像与气泡之间的横向间距，单位为点。"),
                Item(title: "消息气泡上方的昵称字号", path: "basic.nicknameFont", explanation: "同时调整单聊和群聊中已显示的昵称大小。"),
                Item(title: "显示自己消息旁的已读或未读标识", path: "basic.showReadMark", explanation: "标识出现在自己成功发出的消息气泡旁。"),
                Item(title: "自己发出的消息被阅读后显示的文字", path: "basic.readText", explanation: "开启阅读状态标识后，消息被阅读时在气泡旁显示这段文字。"),
                Item(title: "自己发出的消息尚未被阅读时显示的文字", path: "basic.unreadText", explanation: "开启阅读状态标识后，消息尚未被阅读时在气泡旁显示这段文字。")
            ]),
            ("消息列表外观与多媒体发送", [
                Item(title: "发送进度显示延时（秒）", path: "content.transferProgressDelay", explanation: "适用于文字、文件、图片、视频等消息。默认 0.5 秒，支持小数。设为 0 时立即显示。"),
                Item(title: "消息列表中相邻消息的上下间距", path: "messageSpacing", explanation: "调整上一条与下一条消息之间的垂直留白，单位为点。"),
                Item(title: "自己发出的消息气泡底色", path: "senderBubble.fillColor", explanation: "调整聊天列表右侧自己发出的消息气泡颜色。"),
                Item(title: "收到的消息气泡底色", path: "receiverBubble.fillColor", explanation: "调整聊天列表左侧其他人发出的消息气泡颜色。"),
                Item(title: "文本消息气泡内的字号", path: "text.textFont", explanation: "调整已显示在消息列表里的文本消息文字大小。"),
                Item(title: "文本消息气泡内的动态表情播放方式", path: "text.emojiPlaybackMode", choices: [("首次展示时播放", "0"), ("每次展示时播放", "1"), ("始终静态", "2")], explanation: "控制气泡内的动态表情首次出现、滚动后再次出现时如何播放。"),
                Item(title: "一次选择多张图片或视频后的发送方式", path: "media.presentation", choices: [("每个文件发一条消息", "0"), ("合并成一条叠卡消息", "1")], explanation: "从「＋」面板打开相册并多选后，决定新发出的图片和视频如何排列在聊天列表中。"),
                Item(title: "折叠媒体组的视频自动播放", path: "media.foldedVideoAutoplayMode", choices: [("首项视频自动播放", "1"), ("滑到视频后自动播放", "2"), ("当前项是视频就自动播放", "3")], explanation: "滑动模式只在手势切页并停在视频后开始播放。"),
                Item(title: "折叠媒体组循环滑动", path: "media.browser.allowsLoopScrolling", choices: [("关闭", "false"), ("开启", "true")], explanation: "滑到末端后是否可以继续滑动查看下一张卡片。"),
            ]),
            ("底部输入栏外观", [
                Item(title: "输入框中正在编辑的文字字号", path: "input.textFont", explanation: "调整底部输入框里已输入、尚未发送的文字大小。"),
                Item(title: "整条底部输入栏的背景色", path: "input.backgroundColor", explanation: "调整承载输入框、语音、表情和「＋」按钮的底部栏背景。"),
                Item(title: "输入框左侧语音切换按钮的宽度", path: "input.voiceTextButtonSize.width", explanation: "调整切换文字输入和按住说话的按钮宽度，单位为点。"),
                Item(title: "输入框左侧语音切换按钮的高度", path: "input.voiceTextButtonSize.height", explanation: "调整切换文字输入和按住说话的按钮高度，单位为点。"),
                Item(title: "输入框右侧表情切换按钮的宽度", path: "input.emojiTextButtonSize.width", explanation: "调整切换表情面板和键盘的按钮宽度，单位为点。"),
                Item(title: "输入框右侧表情切换按钮的高度", path: "input.emojiTextButtonSize.height", explanation: "调整切换表情面板和键盘的按钮高度，单位为点。")
            ]),
            ("高级与恢复", [
                Item(title: "全部属性设置", path: "advanced", explanation: "按属性路径查找聊天组件配置，并打开聊天预览检查效果。"),
                Item(title: "恢复默认设置", path: "defaults", explanation: "把本页和全部属性中的配置恢复为默认值，点击「保存」后应用到聊天页。")
            ])
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "聊天设置"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .done, target: self, action: #selector(save))
        tableView.accessibilityIdentifier = "WYChatSettings.groups"
        let hint = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: UIDevice.wy_screenHeight(64, WYBasisKitConfig.defaultScreenPixels)))
        hint.text = "点右上角「保存」，在聊天页查看修改效果"
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
        cell.accessibilityIdentifier = "WYChatSettings.item." + item.path
        cell.textLabel?.text = item.title
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .footnote)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType = .disclosureIndicator
        let value = fields[item.path]?.read(draftView.configuration) ?? ""
        var currentValue = ""
        if item.path == "inputBehavior" {
            currentValue = item.choices.first { $0.1 == String(draftView.configuration.input.placeholderLongPressAction.rawValue) }?.0 ?? ""
        } else if item.path == "menuActions" {
            let config = draftView.configuration
            let actions = config.menuActions
            let names = actions.prefix(3).map { WYChatSettingsMenuActionsController.title(for: $0, configuration: config) }.joined(separator: "、")
            currentValue = actions.isEmpty ? "未选择按钮" : actions.count > 3 ? "\(names)等 \(actions.count) 项" : names
        } else if item.path == "menuMaximumColumns" {
            currentValue = "每行最多 \(max(1, draftView.configuration.menuMaximumColumns)) 项"
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
        } else if fields[item.path]?.type == "UIFont" {
            currentValue = (value.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? "") + " 号"
        } else {
            currentValue = item.choices.first(where: { $0.1 == value })?.0 ?? value
        }
        cell.detailTextLabel?.text = [item.explanation, currentValue].filter { !$0.isEmpty }.joined(separator: "\n")
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
        if item.path == "menuActions" {
            let controller = WYChatSettingsMenuActionsController(configuration: draftView.configuration, title: item.title)
            controller.applyActions = { [weak self] actions in
                guard let self else { return }
                var config = self.draftView.configuration
                config.menuActions = actions
                self.draftView.configuration = config
                self.tableView.reloadData()
            }
            navigationController?.pushViewController(controller, animated: true)
            return
        }
        if !item.choices.isEmpty {
            let alert = UIAlertController(title: item.title, message: item.explanation, preferredStyle: .actionSheet)
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
        let alert = UIAlertController(title: item.title, message: item.explanation, preferredStyle: .alert)
        alert.addTextField { text in
            let value = field.read(self.draftView.configuration)
            text.text = field.type == "UIFont" ? value.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) : value
            if item.path == "menuMaximumColumns" {
                text.keyboardType = .numberPad
            } else {
                text.keyboardType = field.type == "String" ? .default : .decimalPad
            }
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
            let alert = UIAlertController(title: "外部识别服务尚未接入", message: "请选择 Apple 系统识别，或由接入应用先提供识别服务", preferredStyle: .alert)
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

/// 按名称选择长按消息菜单的按钮，并调整显示顺序
private final class WYChatSettingsMenuActionsController: UITableViewController {
    private static let allActions: [WYChatAction] = [
        .copy, .paste, .quote, .forward, .favorite, .delete, .withdraw, .reedit, .select, .translate,
        .reference, .selectRange, .markRead, .markUnread, .remind, .search, .retry, .play, .pause,
        .mention, .takePat, .playbackRate, .content, .avatar, .nickname
    ]
    private let configuration: WYChatConfig
    private var selectedActions: [WYChatAction]
    private var availableActions: [WYChatAction] {
        Self.allActions.filter { !selectedActions.contains($0) }
    }
    var applyActions: (([WYChatAction]) -> Void)?

    init(configuration: WYChatConfig, title: String) {
        self.configuration = configuration
        selectedActions = configuration.menuActions
        super.init(style: .insetGrouped)
        self.title = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "确定", style: .done, target: self, action: #selector(apply))
        tableView.accessibilityIdentifier = "WYChatSettings.menuActions"
        tableView.allowsSelectionDuringEditing = true
        tableView.setEditing(true, animated: false)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "已选按钮" : "可添加按钮"
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == 0 else { return nil }
        return "点按已选按钮可移除，拖动右侧手柄可改变顺序。点按「可添加按钮」里的项目可加入菜单。"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? selectedActions.count : availableActions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuAction") ?? UITableViewCell(style: .default, reuseIdentifier: "menuAction")
        let selected = indexPath.section == 0
        let action = selected ? selectedActions[indexPath.row] : availableActions[indexPath.row]
        cell.textLabel?.text = Self.title(for: action, configuration: configuration)
        cell.textLabel?.numberOfLines = 0
        cell.showsReorderControl = selected
        cell.accessibilityIdentifier = "WYChatSettings.menuAction.\(action.rawValue)"
        cell.accessibilityHint = selected ? "点按以移除" : "点按以添加"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            selectedActions.remove(at: indexPath.row)
        } else {
            selectedActions.append(availableActions[indexPath.row])
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle { .none }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool { false }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { indexPath.section == 0 }

    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        proposedDestinationIndexPath.section == 0 ? proposedDestinationIndexPath : IndexPath(row: selectedActions.count - 1, section: 0)
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let action = selectedActions.remove(at: sourceIndexPath.row)
        selectedActions.insert(action, at: destinationIndexPath.row)
    }

    @objc private func apply() {
        applyActions?(selectedActions)
        navigationController?.popViewController(animated: true)
    }

    static func title(for action: WYChatAction, configuration: WYChatConfig) -> String {
        if let title = configuration.actionTitle?(action) { return title }
        switch action {
        case .copy: return "复制"
        case .paste: return "粘贴"
        case .quote: return "引用"
        case .forward: return "转发"
        case .favorite: return "收藏"
        case .delete: return "删除"
        case .withdraw: return "撤回"
        case .reedit: return configuration.notice.reeditText
        case .select: return "多选"
        case .translate: return "转文字"
        case .reference: return "查看被引用的消息"
        case .selectRange: return configuration.selection.rangeTitle
        case .markRead: return "标记已读"
        case .markUnread: return "标记未读"
        case .remind: return "提醒"
        case .search: return "搜索"
        case .retry: return "重试"
        case .play: return "播放"
        case .pause: return "暂停"
        case .startTransfer: return "开始传输"
        case .pauseTransfer: return "暂停传输"
        case .resumeTransfer: return "继续传输"
        case .mention: return "提及成员"
        case .takePat: return "拍一拍"
        case .playbackRate: return "播放倍速"
        case .content: return "打开消息内容"
        case .avatar: return "打开头像"
        case .nickname: return "打开昵称"
        @unknown default: return "操作 \(action.rawValue)"
        }
    }
}
