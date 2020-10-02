// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import SafariServices
import SwiftUI
import ViewModels

class TableViewController: UITableViewController {
    private let viewModel: CollectionViewModel
    private let loadingTableFooterView = LoadingTableFooterView()
    private let webfingerIndicatorView = WebfingerIndicatorView()
    private var cancellables = Set<AnyCancellable>()
    private var cellHeightCaches = [CGFloat: [CollectionItemIdentifier: CGFloat]]()
    private let dataSourceQueue =
        DispatchQueue(label: "com.metabolist.metatext.collection.data-source-queue")

    private lazy var dataSource: UITableViewDiffableDataSource<Int, CollectionItemIdentifier> = {
        UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            guard let self = self, let cellViewModel = self.viewModel.viewModel(item: item) else { return nil }

            let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: item.kind.cellClass),
                for: indexPath)

            switch (cell, cellViewModel) {
            case (let statusListCell as StatusListCell, let statusViewModel as StatusViewModel):
                statusListCell.viewModel = statusViewModel
            case (let accountListCell as AccountListCell, let accountViewModel as AccountViewModel):
                accountListCell.viewModel = accountViewModel
            case (let loadMoreCell as LoadMoreCell, let loadMoreViewModel as LoadMoreViewModel):
                var contentConfiguration = loadMoreCell.defaultContentConfiguration()

                contentConfiguration.text = NSLocalizedString("load-more", comment: "")

                loadMoreCell.contentConfiguration = contentConfiguration
            default:
                return nil
            }

            return cell
        }
    }()

    init(viewModel: CollectionViewModel) {
        self.viewModel = viewModel

        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        for kind in CollectionItemIdentifier.Kind.allCases {
            tableView.register(kind.cellClass, forCellReuseIdentifier: String(describing: kind.cellClass))
        }

        tableView.dataSource = dataSource
        tableView.prefetchDataSource = self
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.tableFooterView = UIView()

        view.addSubview(webfingerIndicatorView)
        webfingerIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            webfingerIndicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            webfingerIndicatorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])

        setupViewModelBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.request(maxID: nil, minID: nil)
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        var heightCache = cellHeightCaches[tableView.frame.width] ?? [CollectionItemIdentifier: CGFloat]()

        heightCache[item] = cell.frame.height
        cellHeightCaches[tableView.frame.width] = heightCache
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return UITableView.automaticDimension }

        return cellHeightCaches[tableView.frame.width]?[item] ?? UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return true }

        return viewModel.canSelect(item: item)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        viewModel.itemSelected(item)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sizeTableHeaderFooterViews()
    }
}

extension TableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard
            let maxID = viewModel.nextPageMaxID,
            let indexPath = indexPaths.last,
            indexPath.section == dataSource.numberOfSections(in: tableView) - 1,
            indexPath.row == dataSource.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1
        else { return }

        viewModel.request(maxID: maxID, minID: nil)
    }
}

extension TableViewController {
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

            view.insertSubview(webfingerIndicatorView, aboveSubview: headerView)
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

private extension TableViewController {
    func setupViewModelBindings() {
        viewModel.title.sink { [weak self] in self?.navigationItem.title = $0 }.store(in: &cancellables)

        viewModel.collectionItems.sink { [weak self] in self?.update(items: $0) }.store(in: &cancellables)

        viewModel.navigationEvents.receive(on: DispatchQueue.main).sink { [weak self] in
            guard let self = self else { return }

            switch $0 {
            case let .share(url):
                self.share(url: url)
            case let .collectionNavigation(viewModel):
                self.show(TableViewController(viewModel: viewModel), sender: self)
            case let .profileNavigation(viewModel):
                self.show(ProfileViewController(viewModel: viewModel), sender: self)
            case let .urlNavigation(url):
                self.present(SFSafariViewController(url: url), animated: true)
            case .webfingerStart:
                self.webfingerIndicatorView.startAnimating()
            case .webfingerEnd:
                self.webfingerIndicatorView.stopAnimating()
            }
        }
        .store(in: &cancellables)

        viewModel.loading.receive(on: RunLoop.main).sink { [weak self] in
            guard let self = self else { return }

            self.tableView.tableFooterView = $0 ? self.loadingTableFooterView : UIView()
            self.sizeTableHeaderFooterViews()
        }
        .store(in: &cancellables)
    }

    func update(items: [[CollectionItemIdentifier]]) {
        var offsetFromNavigationBar: CGFloat?

        if
            let item = viewModel.maintainScrollPositionOfItem,
            let indexPath = dataSource.indexPath(for: item),
            let navigationBar = navigationController?.navigationBar {
            let navigationBarMaxY = tableView.convert(navigationBar.bounds, from: navigationBar).maxY
            offsetFromNavigationBar = tableView.rectForRow(at: indexPath).origin.y - navigationBarMaxY
        }

        dataSourceQueue.async { [weak self] in
            guard let self = self else { return }

            self.dataSource.apply(items.snapshot(), animatingDifferences: false) {
                if
                    let item = self.viewModel.maintainScrollPositionOfItem,
                    let indexPath = self.dataSource.indexPath(for: item) {
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
}
