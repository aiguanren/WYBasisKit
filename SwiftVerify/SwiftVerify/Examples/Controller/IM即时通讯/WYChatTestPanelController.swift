import UIKit

final class WYChatTestPanelController: UITableViewController, UISearchResultsUpdating {
    private let suite: WYChatTestSuite
    private let search = UISearchController(searchResultsController: nil)
    private var filtered: [WYChatTestCase] = []
    private let summary = UILabel()

    init(suite: WYChatTestSuite) {
        self.suite = suite
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "ChatView测试"
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(close))
        navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "配置", style: .plain, target: self, action: #selector(showConfiguration)), UIBarButtonItem(title: "全部运行", style: .plain, target: self, action: #selector(runAll)), UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(export))]
        tableView.accessibilityIdentifier = "WYChatTests.cases"
        summary.accessibilityIdentifier = "WYChatTests.status"
        summary.numberOfLines = 0
        summary.textAlignment = .center
        summary.font = .preferredFont(forTextStyle: .footnote)
        summary.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 60)
        tableView.tableHeaderView = summary
        suite.progress = { [weak self] in guard let self else { return }; self.updateSearchResults(for: self.search) }
        updateSearchResults(for: search)
    }

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        filtered = suite.cases.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.group.localizedCaseInsensitiveContains(query) }
        let passed = suite.cases.filter { $0.status == .passed }.count
        let failed = suite.cases.filter { $0.status == .failed }.count
        summary.text = (suite.isRunning ? "执行中" : suite.didFinishBatch || passed + failed == suite.cases.count ? "执行完成" : "尚未全部执行") + " · 通过\(passed) · 失败\(failed) · 未执行\(suite.cases.filter { $0.status == .notRun }.count) · 总计\(suite.cases.count)"
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "test") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "test")
        let item = filtered[indexPath.row]
        cell.textLabel?.text = item.name
        let count = item.results.filter(\.passed).count
        let status: String
        switch item.status { case .notRun: status = "未执行"; case .running: status = "执行中"; case .passed: status = "通过"; case .failed: status = "失败" }
        cell.detailTextLabel?.text = item.group + " · " + status + " · \(count)/\(item.results.count)"
        cell.detailTextLabel?.textColor = item.status == .failed ? .systemRed : .secondaryLabel
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = filtered[indexPath.row]
        let detail = item.results.filter { !$0.passed }.map { $0.name + "\n" + $0.detail }.joined(separator: "\n\n")
        let alert = UIAlertController(title: item.name, message: item.explanation + (detail.isEmpty ? "" : "\n\n" + detail), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "运行", style: .default) { [weak self, weak alert] _ in
            Task {
                guard let self else { return }
                while let alert, alert.presentingViewController != nil || alert.isBeingDismissed { try? await Task.sleep(nanoseconds: 20_000_000) }
                await self.suite.run(item)
            }
        })
        alert.addAction(UIAlertAction(title: "关闭", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func showConfiguration() {
        let controller = WYChatTestConfigurationController(chatView: suite.chatView)
        controller.showRelatedTests = { [weak self] query in
            guard let self else { return }
            self.navigationController?.popToViewController(self, animated: true)
            self.search.searchBar.text = query
            self.updateSearchResults(for: self.search)
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func close() { dismiss(animated: true) }
    @objc private func runAll() { Task { await suite.runAll() } }
    @objc private func export() {
        let controller = UIActivityViewController(activityItems: [suite.report], applicationActivities: nil)
        controller.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.last
        present(controller, animated: true)
    }
}
