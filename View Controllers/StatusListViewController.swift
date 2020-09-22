// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import SafariServices
import SwiftUI
import ViewModels

class StatusListViewController: UITableViewController {
    private let viewModel: StatusListViewModel
    private let loadingTableFooterView = LoadingTableFooterView()
    private var cancellables = Set<AnyCancellable>()
    private var cellHeightCaches = [CGFloat: [String: CGFloat]]()
    private let dataSourceQueue =
        DispatchQueue(label: "com.metabolist.metatext.status-list.data-source-queue")

    private lazy var dataSource: UITableViewDiffableDataSource<Int, String> = {
        UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, statusID in
            guard
                let self = self,
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: String(describing: StatusListCell.self),
                    for: indexPath) as? StatusListCell
            else { return nil }

            cell.viewModel = self.viewModel.statusViewModel(id: statusID)

            return cell
        }
    }()

    init(viewModel: StatusListViewModel) {
        self.viewModel = viewModel

        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(StatusListCell.self, forCellReuseIdentifier: String(describing: StatusListCell.self))

        tableView.dataSource = dataSource
        tableView.prefetchDataSource = self
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.tableFooterView = UIView()

        navigationItem.title = viewModel.title

        viewModel.$statusIDs
            .sink { [weak self] in self?.update(statusIDs: $0) }
            .store(in: &cancellables)

        viewModel.events.sink { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case let .share(url):
                self.share(url: url)
            case let .statusListNavigation(statusListViewModel):
                self.show(StatusListViewController(viewModel: statusListViewModel), sender: self)
            case let .urlNavigation(url):
                self.present(SFSafariViewController(url: url), animated: true)
            }
        }
        .store(in: &cancellables)

        viewModel.$loading
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self = self else { return }

                self.tableView.tableFooterView = $0 ? self.loadingTableFooterView : UIView()
                self.sizeTableHeaderFooterViews()
            }
            .store(in: &cancellables)

        if let accountsStatusesViewModel = viewModel as? AccountStatusesViewModel {
            // Initial size is to avoid unsatisfiable constraint warning
            let accountHeaderView = AccountHeaderView(
                frame: .init(
                    origin: .zero,
                    size: .init(width: 100, height: 100)))
            accountHeaderView.viewModel = accountsStatusesViewModel
            accountsStatusesViewModel.$account.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] _ in
                accountHeaderView.viewModel = accountsStatusesViewModel
                self?.sizeTableHeaderFooterViews()
            }
            .store(in: &cancellables)
            tableView.tableHeaderView = accountHeaderView
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.request()
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        var heightCache = cellHeightCaches[tableView.frame.width] ?? [String: CGFloat]()

        heightCache[item] = cell.frame.height
        cellHeightCaches[tableView.frame.width] = heightCache
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return UITableView.automaticDimension }

        return cellHeightCaches[tableView.frame.width]?[item] ?? UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return true }

        return id != viewModel.contextParentID
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }

        show(StatusListViewController(viewModel: viewModel.contextViewModel(id: id)), sender: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sizeTableHeaderFooterViews()
    }
}

extension StatusListViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard
            viewModel.paginates,
            let indexPath = indexPaths.last,
            indexPath.section == dataSource.numberOfSections(in: tableView) - 1,
            indexPath.row == dataSource.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1,
            let maxID = dataSource.itemIdentifier(for: indexPath)
        else { return }

        viewModel.request(maxID: maxID)
    }
}

private extension StatusListViewController {
    func update(statusIDs: [[String]]) {
        var offsetFromNavigationBar: CGFloat?

        if
            let id = viewModel.maintainScrollPositionOfStatusID,
            let indexPath = dataSource.indexPath(for: id),
            let navigationBar = navigationController?.navigationBar {
            let navigationBarMaxY = tableView.convert(navigationBar.bounds, from: navigationBar).maxY
            offsetFromNavigationBar = tableView.rectForRow(at: indexPath).origin.y - navigationBarMaxY
        }

        dataSourceQueue.async { [weak self] in
            guard let self = self else { return }

            self.dataSource.apply(statusIDs.snapshot(), animatingDifferences: false) {
                if
                    let id = self.viewModel.maintainScrollPositionOfStatusID,
                    let indexPath = self.dataSource.indexPath(for: id) {
                    self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)

                    if let offsetFromNavigationBar = offsetFromNavigationBar {
                        self.tableView.contentOffset.y -= offsetFromNavigationBar
                    }
                }
            }
        }
    }

    func share(url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        present(activityViewController, animated: true, completion: nil)
    }

    func sizeTableHeaderFooterViews() {
        // https://useyourloaf.com/blog/variable-height-table-view-header/
        if let headerView = tableView.tableHeaderView {
            let size = headerView.systemLayoutSizeFitting(
                CGSize(width: tableView.frame.width, height: .greatestFiniteMagnitude),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel)

            if headerView.frame.size.height != size.height {
                headerView.frame.size.height = size.height
                tableView.tableHeaderView = headerView
                tableView.layoutIfNeeded()
            }
        }

        if let footerView = tableView.tableFooterView {
            let size = footerView.systemLayoutSizeFitting(
                CGSize(width: tableView.frame.width, height: .greatestFiniteMagnitude),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel)

            if footerView.frame.size.height != size.height {
                footerView.frame.size.height = size.height
                tableView.tableFooterView = footerView
                tableView.layoutIfNeeded()
            }
        }
    }
}

private extension Array where Element: Sequence, Element.Element: Hashable {
    func snapshot() -> NSDiffableDataSourceSnapshot<Int, Element.Element> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Element.Element>()

        let sections = [Int](0..<count)

        snapshot.appendSections(sections)

        for section in sections {
            snapshot.appendItems(self[section].map { $0 }, toSection: section)
        }

        return snapshot
    }
}
