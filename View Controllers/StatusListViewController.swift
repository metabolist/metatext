// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import Combine
import ViewModels

class StatusListViewController: UITableViewController {
    private let viewModel: StatusListViewModel
    private let loadingTableFooterView = LoadingTableFooterView()
    private var cancellables = Set<AnyCancellable>()
    private var cellHeightCaches = [CGFloat: [String: CGFloat]]()

    private lazy var dataSource: UITableViewDiffableDataSource<Int, String> = {
        UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, statusID in
            guard
                let self = self,
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: String(describing: StatusTableViewCell.self),
                    for: indexPath) as? StatusTableViewCell
            else { return nil }

            cell.viewModel = self.viewModel.statusViewModel(id: statusID)
            cell.delegate = self

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

        for cellClass in [StatusTableViewCell.self] {
            let classString = String(describing: cellClass)
            tableView.register(
                UINib(nibName: classString, bundle: nil),
                forCellReuseIdentifier: classString)
        }

        tableView.dataSource = dataSource
        tableView.prefetchDataSource = self
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()

        viewModel.$statusIDs
            .sink { [weak self] in
                guard let self = self else { return }

                var offsetFromNavigationBar: CGFloat?

                if
                    let id = self.viewModel.maintainScrollPositionOfStatusID,
                    let indexPath = self.dataSource.indexPath(for: id),
                    let navigationBar = self.navigationController?.navigationBar {
                    let navigationBarMaxY = self.tableView.convert(navigationBar.bounds, from: navigationBar).maxY
                    offsetFromNavigationBar = self.tableView.rectForRow(at: indexPath).origin.y - navigationBarMaxY
                }

                self.dataSource.apply($0.snapshot(), animatingDifferences: false) {
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
            .store(in: &cancellables)

        viewModel.$loading
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self = self else { return }

                self.tableView.tableFooterView = $0 ? self.loadingTableFooterView : UIView()
                self.sizeTableHeaderFooterViews()
            }
            .store(in: &cancellables)
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
        guard
            let id = dataSource.itemIdentifier(for: indexPath),
            let contextViewModel = viewModel.contextViewModel(id: id)
        else { return }

        navigationController?.pushViewController(
            StatusListViewController(viewModel: contextViewModel),
            animated: true)
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

extension StatusListViewController: StatusTableViewCellDelegate {
    func statusTableViewCellDidHaveShareButtonTapped(_ cell: StatusTableViewCell) {
        guard let url = cell.viewModel?.sharingURL else { return }

        share(url: url)
    }
}

private extension StatusListViewController {
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
