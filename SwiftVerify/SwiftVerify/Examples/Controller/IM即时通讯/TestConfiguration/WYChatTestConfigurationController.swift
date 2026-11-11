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
        if field.kind == .boolean, let chatView { _ = apply(field, text: String(field.read(chatView.configuration) != "true")); return }
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
