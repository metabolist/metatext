// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import Combine

class StatusListViewController: UITableViewController {
    private let viewModel: StatusesViewModel
    private var cancellables = Set<AnyCancellable>()
    private var cellHeightCaches = [CGFloat: [Status: CGFloat]]()

    private lazy var dataSource: UITableViewDiffableDataSource<Int, Status> = {
        UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, status in
            guard
                let self = self,
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: String(describing: StatusTableViewCell.self),
                    for: indexPath) as? StatusTableViewCell
            else { return nil }

            let statusViewModel = self.viewModel.statusViewModel(status: status)

            cell.viewModel = statusViewModel
            cell.delegate = self

            return cell
        }
    }()

    init(viewModel: StatusesViewModel) {
        self.viewModel = viewModel

        super.init(style: .plain)
    }

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
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.separatorInset = .zero

        viewModel.$statusSections.map { $0.snapshot() }
            .sink { [weak self] in
                guard let self = self else { return }

                var offsetFromNavigationBar: CGFloat?

                if
                    let id = self.viewModel.maintainScrollPositionOfStatusID,
                    let indexPath = self.indexPath(statusID: id),
                    let navigationBar = self.navigationController?.navigationBar {
                    let navigationBarMaxY = self.tableView.convert(navigationBar.bounds, from: navigationBar).maxY
                    offsetFromNavigationBar = self.tableView.rectForRow(at: indexPath).origin.y - navigationBarMaxY
                }

                self.dataSource.apply($0, animatingDifferences: false) {
                    if
                        let id = self.viewModel.maintainScrollPositionOfStatusID,
                        let indexPath = self.indexPath(statusID: id),
                        let offsetFromNavigationBar = offsetFromNavigationBar {
                        self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                        self.tableView.contentOffset.y -= offsetFromNavigationBar
                    }
                }
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

        var heightCache = cellHeightCaches[tableView.frame.width] ?? [Status: CGFloat]()

        heightCache[item] = cell.frame.height
        cellHeightCaches[tableView.frame.width] = heightCache
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return UITableView.automaticDimension }

        return cellHeightCaches[tableView.frame.width]?[item] ?? UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        viewModel.statusSections[indexPath.section][indexPath.row].id != viewModel.contextParentID
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let status = viewModel.statusSections[indexPath.section][indexPath.row]

        navigationController?.pushViewController(
            StatusListViewController(viewModel: viewModel.contextViewModel(status: status)),
            animated: true)
    }
}

extension StatusListViewController: StatusTableViewCellDelegate {
    func statusTableViewCellDidHaveShareButtonTapped(_ cell: StatusTableViewCell) {
        guard let url = cell.viewModel.sharingURL else { return }

        share(url: url)
    }
}

private extension StatusListViewController {
    func indexPath(statusID: String) -> IndexPath? {
        for section in 0..<dataSource.numberOfSections(in: tableView) {
            for row in 0..<dataSource.tableView(tableView, numberOfRowsInSection: section) {
                let indexPath = IndexPath(row: row, section: section)

                if dataSource.itemIdentifier(for: indexPath)?.id == statusID {
                    return indexPath
                }
            }
        }

        return nil
    }

    func share(url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        present(activityViewController, animated: true, completion: nil)
    }
}

private extension Array where Element == [Status] {
    func snapshot() -> NSDiffableDataSourceSnapshot<Int, Status> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Status>()

        let sections = [Int](0..<count)

        snapshot.appendSections(sections)

        for section in sections {
            snapshot.appendItems(self[section], toSection: section)
        }

        return snapshot
    }
}