// Copyright © 2020 Metabolist. All rights reserved.

import AVKit
import Combine
import Mastodon
import SafariServices
import SwiftUI
import ViewModels

// swiftlint:disable file_length
class TableViewController: UITableViewController {
    var transitionViewTag = -1

    private let viewModel: CollectionViewModel
    private let rootViewModel: RootViewModel
    private let loadingTableFooterView = LoadingTableFooterView()
    private let webfingerIndicatorView = WebfingerIndicatorView()
    @Published private var loading = false
    private var visibleLoadMoreViews = Set<LoadMoreView>()
    private var cancellables = Set<AnyCancellable>()
    private var cellHeightCaches = [CGFloat: [CollectionItem: CGFloat]]()
    private var shouldKeepPlayingVideoAfterDismissal = false
    private let insetBottom: Bool
    private weak var parentNavigationController: UINavigationController?

    private lazy var dataSource: TableViewDataSource = {
        .init(tableView: tableView, viewModelProvider: viewModel.viewModel(indexPath:))
    }()

    init(viewModel: CollectionViewModel,
         rootViewModel: RootViewModel,
         insetBottom: Bool = true,
         parentNavigationController: UINavigationController? = nil) {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel
        self.insetBottom = insetBottom
        self.parentNavigationController = parentNavigationController

        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = dataSource
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.tableFooterView = UIView()
        tableView.contentInset.bottom = bottomInset

        if viewModel.canRefresh {
            refreshControl = UIRefreshControl()
            refreshControl?.addAction(
                UIAction { [weak self] _ in
                    self?.viewModel.request(maxId: nil, minId: nil, search: nil) },
                for: .valueChanged)
        }

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

        viewModel.request(maxId: nil, minId: nil, search: nil)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.isDragging else { return }

        let up = scrollView.panGestureRecognizer.translation(in: scrollView.superview).y > 0

        for loadMoreView in visibleLoadMoreViews {
            loadMoreView.directionChanged(up: up)
        }
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        for loadMoreView in visibleLoadMoreViews {
            loadMoreView.finalizeDirectionChange()
        }
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        var heightCache = cellHeightCaches[tableView.frame.width] ?? [CollectionItem: CGFloat]()

        heightCache[item] = cell.frame.height
        cellHeightCaches[tableView.frame.width] = heightCache

        if !loading,
           indexPath.section == dataSource.numberOfSections(in: tableView) - 1,
           indexPath.row == dataSource.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            viewModel.requestNextPage(fromIndexPath: indexPath)
        }

        if let loadMoreView = cell.contentView as? LoadMoreView {
            visibleLoadMoreViews.insert(loadMoreView)
        }
    }

    override func tableView(_ tableView: UITableView,
                            didEndDisplaying cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        if let loadMoreView = cell.contentView as? LoadMoreView {
            visibleLoadMoreViews.remove(loadMoreView)
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return UITableView.automaticDimension }

        return cellHeightCaches[tableView.frame.width]?[item]
            ?? item.estimatedHeight(width: tableView.readableContentGuide.layoutFrame.width,
                                    identityContext: viewModel.identityContext)
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        viewModel.canSelect(indexPath: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        viewModel.select(indexPath: indexPath)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sizeTableHeaderFooterViews()
    }
}

extension TableViewController {
    func report(reportViewModel: ReportViewModel) {
        let reportViewController = ReportViewController(viewModel: reportViewModel)
        let navigationController = UINavigationController(rootViewController: reportViewController)

        present(navigationController, animated: true)
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

extension TableViewController: AVPlayerViewControllerDelegate {
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        playerViewController.player?.isMuted = true

        coordinator.animate(alongsideTransition: nil) { _ in
            if self.shouldKeepPlayingVideoAfterDismissal {
                playerViewController.player?.play()
            }
        }
    }
}

extension TableViewController: ZoomAnimatorDelegate {
    func transitionWillStartWith(zoomAnimator: ZoomAnimator) {
        view.layoutIfNeeded()

        guard let imageViewController = (presentedViewController as? ImageNavigationController)?.currentViewController
        else { return }

        if imageViewController.playerView.tag != 0 {
            transitionViewTag = imageViewController.playerView.tag
        } else if imageViewController.imageView.tag != 0 {
            transitionViewTag = imageViewController.imageView.tag
        }
    }

    func transitionDidEndWith(zoomAnimator: ZoomAnimator) {

    }

    func referenceView(for zoomAnimator: ZoomAnimator) -> UIView? {
        view.viewWithTag(transitionViewTag)
    }

    func referenceViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
        guard let referenceView = referenceView(for: zoomAnimator) else { return nil }

        return parent?.view.convert(referenceView.frame, from: referenceView.superview)
    }
}

private extension TableViewController {
    static let bottomInset: CGFloat = .newStatusButtonDimension + .defaultSpacing * 4
    static let loadingFooterDebounceInterval: TimeInterval = 0.5

    var bottomInset: CGFloat { insetBottom ? Self.bottomInset : 0 }

    func setupViewModelBindings() {
        viewModel.title.sink { [weak self] in self?.navigationItem.title = $0 }.store(in: &cancellables)

        viewModel.titleLocalizationComponents.sink { [weak self] in
            guard let key = $0.first else { return }

            self?.navigationItem.title = String(
                format: NSLocalizedString(key, comment: ""),
                arguments: Array($0.suffix(from: 1)))
        }
        .store(in: &cancellables)

        viewModel.updates.sink { [weak self] in self?.update($0) }.store(in: &cancellables)

        viewModel.events.receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(event: $0) }
            .store(in: &cancellables)

        viewModel.expandAll.receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.set(expandAllState: $0) }
            .store(in: &cancellables)

        viewModel.loading.receive(on: DispatchQueue.main).assign(to: &$loading)

        $loading.debounce(
            for: .seconds(Self.loadingFooterDebounceInterval),
            scheduler: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }

                let refreshControlVisibile = self.refreshControl?.isRefreshing ?? false

                if !$0, refreshControlVisibile {
                    self.refreshControl?.endRefreshing()
                }

                self.tableView.tableFooterView = $0 && !refreshControlVisibile ? self.loadingTableFooterView : UIView()
                self.sizeTableHeaderFooterViews()
            }
            .store(in: &cancellables)

        viewModel.alertItems
            .compactMap { $0 }
            .sink { [weak self] in self?.present(alertItem: $0) }
            .store(in: &cancellables)

        tableView.publisher(for: \.contentOffset)
            .compactMap { [weak self] _ in self?.tableView.indexPathsForVisibleRows?.first }
            .sink { [weak self] in self?.viewModel.viewedAtTop(indexPath: $0) }
            .store(in: &cancellables)
    }

    func update(_ update: CollectionUpdate) {
        let positionMaintenanceOffset: CGFloat

        if let itemId = update.maintainScrollPositionItemId,
           let indexPath = dataSource.indexPath(itemId: itemId) {
            positionMaintenanceOffset = tableView.rectForRow(at: indexPath).origin.y
                - tableView.safeAreaInsets.top - tableView.contentOffset.y
        } else {
            positionMaintenanceOffset = 0
        }

        self.dataSource.apply(update.sections.snapshot(), animatingDifferences: false) { [weak self] in
            guard let self = self else { return }

            if let itemId = update.maintainScrollPositionItemId,
               let indexPath = self.dataSource.indexPath(itemId: itemId) {
                if update.shouldAdjustContentInset {
                    self.tableView.contentInset.bottom = max(
                        self.tableView.safeAreaLayoutGuide.layoutFrame.height
                            - self.tableView.rectForRow(at: indexPath).height,
                        self.bottomInset)
                }

                self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                self.tableView.contentOffset.y -= positionMaintenanceOffset
            }
        }
    }

    func handle(event: CollectionItemEvent) {
        switch event {
        case .ignorableOutput:
            break
        case let .share(url):
            share(url: url)
        case let .navigation(navigation):
            handle(navigation: navigation)
        case let .attachment(attachmentViewModel, statusViewModel):
            present(attachmentViewModel: attachmentViewModel, statusViewModel: statusViewModel)
        case let .compose(inReplyToViewModel, redraft):
            compose(inReplyToViewModel: inReplyToViewModel, redraft: redraft)
        case let .confirmDelete(statusViewModel, redraft):
            confirmDelete(statusViewModel: statusViewModel, redraft: redraft)
        case let .report(reportViewModel):
            report(reportViewModel: reportViewModel)
        }
    }

    func handle(navigation: Navigation) {
        switch navigation {
        case let .collection(collectionService):
            let vc = TableViewController(
                viewModel: CollectionItemsViewModel(
                    collectionService: collectionService,
                    identityContext: viewModel.identityContext),
                rootViewModel: rootViewModel,
                parentNavigationController: parentNavigationController)

            if let parentNavigationController = parentNavigationController {
                parentNavigationController.pushViewController(vc, animated: true)
            } else {
                show(vc, sender: self)
            }
        case let .profile(profileService):
            let vc = ProfileViewController(
                viewModel: ProfileViewModel(
                    profileService: profileService,
                    identityContext: viewModel.identityContext),
                rootViewModel: rootViewModel,
                identityContext: viewModel.identityContext,
                parentNavigationController: parentNavigationController)

            if let parentNavigationController = parentNavigationController {
                parentNavigationController.pushViewController(vc, animated: true)
            } else {
                show(vc, sender: self)
            }
        case let .url(url):
            present(SFSafariViewController(url: url), animated: true)
        case .searchScope:
            break
        case .webfingerStart:
            webfingerIndicatorView.startAnimating()
        case .webfingerEnd:
            webfingerIndicatorView.stopAnimating()
        }
    }

    func present(attachmentViewModel: AttachmentViewModel, statusViewModel: StatusViewModel) {
        switch attachmentViewModel.attachment.type {
        case .audio, .video:
            let playerViewController = AVPlayerViewController()
            let player: AVPlayer

            if attachmentViewModel.attachment.type == .video {
                player = PlayerCache.shared.player(url: attachmentViewModel.attachment.url)
            } else {
                player = AVPlayer(url: attachmentViewModel.attachment.url)
            }

            playerViewController.delegate = self
            playerViewController.player = player

            shouldKeepPlayingVideoAfterDismissal = attachmentViewModel.shouldAutoplay

            present(playerViewController, animated: true) {
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                player.isMuted = false
                player.play()
            }
        case .image, .gifv:
            let imagePageViewController = ImagePageViewController(
                initiallyVisible: attachmentViewModel,
                statusViewModel: statusViewModel)
            let imageNavigationController = ImageNavigationController(imagePageViewController: imagePageViewController)

            imageNavigationController.transitionController.fromDelegate = self
            transitionViewTag = attachmentViewModel.tag

            present(imageNavigationController, animated: true)
        case .unknown:
            break
        }
    }

    func compose(inReplyToViewModel: StatusViewModel?, redraft: Status?) {
        let newStatusViewModel = rootViewModel.newStatusViewModel(
            identityContext: viewModel.identityContext,
            inReplyTo: inReplyToViewModel,
            redraft: redraft)
        let newStatusViewController =  NewStatusViewController(viewModel: newStatusViewModel)
        let navigationController = UINavigationController(rootViewController: newStatusViewController)

        if UIDevice.current.userInterfaceIdiom == .phone {
            navigationController.modalPresentationStyle = .overFullScreen
        } else {
            navigationController.isModalInPresentation = true
        }

        present(navigationController, animated: true)
    }

    func confirmDelete(statusViewModel: StatusViewModel, redraft: Bool) {
        let alertController = UIAlertController(
            title: nil,
            message: redraft
                ? NSLocalizedString("status.delete-and-redraft.confirm", comment: "")
                : NSLocalizedString("status.delete.confirm", comment: ""),
            preferredStyle: .alert)

        let deleteAction = UIAlertAction(
            title: redraft
                ? NSLocalizedString("status.delete-and-redraft", comment: "")
                : NSLocalizedString("status.delete", comment: ""),
            style: .destructive) { _ in
            redraft ? statusViewModel.deleteAndRedraft() : statusViewModel.delete()
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel) { _ in }

        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }

    func set(expandAllState: ExpandAllState) {
        switch expandAllState {
        case .hidden:
            navigationItem.rightBarButtonItem = nil
        case .expand:
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("status.show-more", comment: ""),
                image: UIImage(systemName: "eye"),
                primaryAction: UIAction { [weak self] _ in self?.viewModel.toggleExpandAll() })
        case .collapse:
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("status.show-less", comment: ""),
                image: UIImage(systemName: "eye.slash"),
                primaryAction: UIAction { [weak self] _ in self?.viewModel.toggleExpandAll() })
        }
    }

    func share(url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let sourceView = tableView.viewWithTag(url.hashValue) else { return }

            activityViewController.popoverPresentationController?.sourceView = sourceView
        }

        present(activityViewController, animated: true, completion: nil)
    }
}
// swiftlint:enable file_length
