// Copyright © 2020 Metabolist. All rights reserved.

import AVKit
import Combine
import Mastodon
import SDWebImage
import SwiftUI
import ViewModels

// swiftlint:disable file_length
class TableViewController: UITableViewController {
    var transitionViewTag = -1

    private let viewModel: CollectionViewModel
    private let rootViewModel: RootViewModel?
    private let loadingTableFooterView = LoadingTableFooterView()
    private let webfingerIndicatorView = WebfingerIndicatorView()
    private let newItemsView = NewItemsView()
    @Published private var loading = false
    private var visibleLoadMoreViews = Set<LoadMoreView>()
    private var cancellables = Set<AnyCancellable>()
    private var cellHeightCaches = [CGFloat: [CollectionItem: CGFloat]]()
    private var shouldKeepPlayingVideoAfterDismissal = false
    private var newItemsViewHiddenConstraint: NSLayoutConstraint?
    private var newItemsViewVisibleConstraint: NSLayoutConstraint?
    private let insetBottom: Bool
    private weak var parentNavigationController: UINavigationController?

    private lazy var dataSource: TableViewDataSource = {
        .init(tableView: tableView, viewModel: viewModel)
    }()

    init(viewModel: CollectionViewModel,
         rootViewModel: RootViewModel? = nil,
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
        tableView.prefetchDataSource = self
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.tableFooterView = UIView()
        tableView.contentInset.bottom = bottomInset
        tableView.isAccessibilityElement = false
        tableView.shouldGroupAccessibilityChildren = true

        if viewModel.canRefresh {
            refreshControl = UIRefreshControl()
            refreshControl?.addAction(
                UIAction { [weak self] _ in
                    self?.refreshIfAble() },
                for: .valueChanged)
        }

        view.addSubview(webfingerIndicatorView)
        webfingerIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(newItemsView)
        newItemsView.translatesAutoresizingMaskIntoConstraints = false
        newItemsView.alpha = 0

        newItemsViewHiddenConstraint = newItemsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        newItemsViewHiddenConstraint?.isActive = true
        newItemsViewVisibleConstraint = newItemsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                                          constant: .defaultSpacing)

        NSLayoutConstraint.activate([
            webfingerIndicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            webfingerIndicatorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            newItemsView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])

        newItemsView.button.addAction(UIAction { [weak self] _ in
            self?.newItemsTapped()
            self?.hideNewItemsView()
        },
        for: .touchUpInside)
        newItemsView.button.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: NSLocalizedString("dismiss", comment: "")) { [weak self] _ in
                self?.hideNewItemsView()
                return true
        }]

        setupViewModelBindings()

        viewModel.request(maxId: nil, minId: nil, search: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshIfAble()
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
        if case .loadMore = dataSource.itemIdentifier(for: indexPath), UIAccessibility.isVoiceOverRunning {
            return false
        }

        return viewModel.canSelect(indexPath: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        viewModel.select(indexPath: indexPath)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sizeTableHeaderFooterViews()
    }

    func configureRightBarButtonItem(expandAllState: ExpandAllState) {
        switch expandAllState {
        case .hidden:
            navigationItem.rightBarButtonItem = nil
        case .expand:
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("status.show-more-all-button.accessibilty-label", comment: ""),
                image: UIImage(systemName: "eye"),
                primaryAction: UIAction { [weak self] _ in self?.viewModel.toggleExpandAll() })
        case .collapse:
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("status.show-less-all-button.accessibilty-label", comment: ""),
                image: UIImage(systemName: "eye.slash"),
                primaryAction: UIAction { [weak self] _ in self?.viewModel.toggleExpandAll() })
        }
    }
}

extension TableViewController {
    func confirm(message: String, style: UIAlertAction.Style = .default, action: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: style) { _ in
            action()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)

        present(alertController, animated: true)
    }

    func report(reportViewModel: ReportViewModel) {
        let reportViewController = ReportViewController(viewModel: reportViewModel)
        let navigationController = UINavigationController(rootViewController: reportViewController)

        present(navigationController, animated: true)
    }

    func addRemoveFromLists(accountViewModel: AccountViewModel) {
        let addRemoveFromListsView = AddRemoveFromListsView(viewModel: .init(accountViewModel: accountViewModel))
        let addRemoveFromListsController = UIHostingController(rootView: addRemoveFromListsView)

        show(addRemoveFromListsController, sender: self)
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

extension TableViewController: NavigationHandling {
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

            webfingerIndicatorView.stopAnimating()
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

            webfingerIndicatorView.stopAnimating()
        case let .notification(notificationService):
            navigate(toNotification: notificationService.notification)
        case let .url(url):
            open(url: url, identityContext: viewModel.identityContext)
            webfingerIndicatorView.stopAnimating()
        case .searchScope:
            break
        case .webfingerStart:
            webfingerIndicatorView.startAnimating()
        case .webfingerEnd:
            webfingerIndicatorView.stopAnimating()
        }
    }
}

extension TableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap(dataSource.itemIdentifier(for:))
            .reduce(Set<URL>()) { $0.union($1.mediaPrefetchURLs(identityContext: viewModel.identityContext)) }

        SDWebImagePrefetcher.shared.prefetchURLs(Array(urls))
    }
}

extension TableViewController: AVPlayerViewControllerDelegate {
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        playerViewController.player?.isMuted = true
        AVAudioSession.decrementPresentedPlayerViewControllerCount()

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

extension TableViewController: ScrollableToTop {
    func scrollToTop(animated: Bool) {
        guard !dataSource.snapshot().itemIdentifiers.isEmpty else { return }

        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}

private extension TableViewController {
    static let bottomInset: CGFloat = .newStatusButtonDimension + .defaultSpacing * 4
    static let loadingFooterDebounceInterval: TimeInterval = 0.75

    var bottomInset: CGFloat { insetBottom ? Self.bottomInset : 0 }

    // swiftlint:disable:next function_body_length
    func setupViewModelBindings() {
        viewModel.title.sink { [weak self] in self?.navigationItem.title = $0 }.store(in: &cancellables)

        viewModel.titleLocalizationComponents.receive(on: DispatchQueue.main).sink { [weak self] in
            guard let key = $0.first else { return }

            self?.navigationItem.title = String(
                format: NSLocalizedString(key, comment: ""),
                arguments: Array($0.suffix(from: 1)))
        }
        .store(in: &cancellables)

        viewModel.updates.receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.update($0) }
            .store(in: &cancellables)

        viewModel.events.receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(event: $0) }
            .store(in: &cancellables)

        viewModel.expandAll.receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.configureRightBarButtonItem(expandAllState: $0) }
            .store(in: &cancellables)

        viewModel.loading.receive(on: DispatchQueue.main).assign(to: &$loading)

        $loading.combineLatest(
        $loading.debounce(
            for: .seconds(Self.loadingFooterDebounceInterval),
            scheduler: DispatchQueue.main))
            .sink { [weak self] loading, debouncedLoading in
                guard let self = self else { return }

                let refreshControlVisibile = self.refreshControl?.isRefreshing ?? false

                if !loading, refreshControlVisibile {
                    self.refreshControl?.endRefreshing()
                }

                self.tableView.tableFooterView =
                    loading && debouncedLoading && !refreshControlVisibile ? self.loadingTableFooterView : UIView()
                self.sizeTableHeaderFooterViews()
            }
            .store(in: &cancellables)

        viewModel.alertItems
            .compactMap { $0 }
            .sink { [weak self] in
                guard let self = self, self.isVisible, self.presentedViewController == nil else { return }

                self.present(alertItem: $0)
            }
            .store(in: &cancellables)

        tableView.publisher(for: \.contentOffset)
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }

                if (self.newItemsView.layer.animationKeys() ?? []).isEmpty, self.newItemsView.alpha > 0 {
                    self.hideNewItemsView()
                }
            })
            .compactMap { [weak self] _ in self?.tableView.indexPathsForVisibleRows?.first }
            .sink { [weak self] in
                guard let self = self else { return }

                self.viewModel.viewedAtTop(indexPath: $0)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)
            .merge(with: NotificationCenter.default.publisher(for: NewStatusViewController.newStatusPostedNotification))
            .sink { [weak self] _ in
                guard let self = self, self.isVisible else { return }

                self.refreshIfAble()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: LoadMoreView.accessibilityCustomAction)
            .sink { [weak self] notification in
                guard let self = self,
                      let loadMoreView = notification.object as? LoadMoreView,
                      let cell = self.tableView.visibleCells.first(where: { $0.contentView === loadMoreView }),
                      let indexPath = self.tableView.indexPath(for: cell)
                      else { return }

                self.tableView(self.tableView, didSelectRowAt: indexPath)
            }
            .store(in: &cancellables)
    }

    func update(_ update: CollectionUpdate) {
        let positionMaintenanceOffset: CGFloat
        let preUpdateContentOffsetY = tableView.contentOffset.y
        var setPreviousOffset = false
        let firstItemId = dataSource.snapshot().itemIdentifiers.first?.itemId

        if let itemId = update.maintainScrollPositionItemId,
           let indexPath = dataSource.indexPath(itemId: itemId) {
            positionMaintenanceOffset = tableView.rectForRow(at: indexPath).origin.y
                - tableView.safeAreaInsets.top - preUpdateContentOffsetY
        } else {
            positionMaintenanceOffset = 0
        }

        if let headerView = tableView.tableHeaderView,
           let headerViewWindowFrame = view.window?.convert(headerView.frame, from: headerView),
           headerViewWindowFrame.maxY > 0 {
            setPreviousOffset = true
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

                if self.viewModel.announcesNewItems,
                   let firstItemId = firstItemId,
                   let newFirstItem = self.dataSource.snapshot().itemIdentifiers.first,
                   let newFirstItemId = newFirstItem.itemId,
                   newFirstItemId > firstItemId {
                    DispatchQueue.main.async {
                        self.announceNewItems(newestItem: newFirstItem)
                    }
                }
            } else if setPreviousOffset {
                self.tableView.contentOffset.y = preUpdateContentOffsetY
            }

            self.tableView.layoutIfNeeded()
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func handle(event: CollectionItemEvent) {
        switch event {
        case .ignorableOutput:
            break
        case .contextParentDeleted:
            navigationController?.popViewController(animated: true)
        case .refresh:
            refreshIfAble()
        case let .share(url):
            share(url: url)
        case let .navigation(navigation):
            handle(navigation: navigation)
        case let .attachment(attachmentViewModel, statusViewModel):
            present(attachmentViewModel: attachmentViewModel, statusViewModel: statusViewModel)
        case let .compose(identity, inReplyToViewModel, redraft, redraftWasContextParent, directMessageTo):
            compose(identity: identity,
                    inReplyToViewModel: inReplyToViewModel,
                    redraft: redraft,
                    redraftWasContextParent: redraftWasContextParent,
                    directMessageTo: directMessageTo)
        case let .confirmDelete(statusViewModel, redraft):
            confirmDelete(statusViewModel: statusViewModel, redraft: redraft)
        case let .confirmUnfollow(accountViewModel):
            confirmUnfollow(accountViewModel: accountViewModel)
        case let .confirmHideReblogs(accountViewModel):
            confirmHideReblogs(accountViewModel: accountViewModel)
        case let .confirmShowReblogs(accountViewModel):
            confirmShowReblogs(accountViewModel: accountViewModel)
        case let .confirmMute(accountViewModel):
            confirmMute(muteViewModel: accountViewModel.muteViewModel())
        case let .confirmUnmute(accountViewModel):
            confirmUnmute(accountViewModel: accountViewModel)
        case let .confirmBlock(accountViewModel):
            confirmBlock(accountViewModel: accountViewModel)
        case let .confirmUnblock(accountViewModel):
            confirmUnblock(accountViewModel: accountViewModel)
        case let .confirmDomainBlock(accountViewModel):
            confirmDomainBlock(accountViewModel: accountViewModel)
        case let .confirmDomainUnblock(accountViewModel):
            confirmDomainUnblock(accountViewModel: accountViewModel)
        case let .report(reportViewModel):
            report(reportViewModel: reportViewModel)
        case let .accountListEdit(accountViewModel, edit):
            accountListEdit(accountViewModel: accountViewModel, edit: edit)
        }
    }

    func navigate(toNotification: MastodonNotification) {
        guard let item = dataSource.snapshot().itemIdentifiers.first(where: {
            guard case let .notification(notification, _) = $0 else { return false }

            return notification.id == toNotification.id
        }),
        let indexPath = dataSource.indexPath(for: item)
        else { return }

        tableView.scrollToRow(at: indexPath, at: .none, animated: !UIAccessibility.isReduceMotionEnabled)

        viewModel.select(indexPath: indexPath)
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
                AVAudioSession.incrementPresentedPlayerViewControllerCount()
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

    func compose(identity: Identity?,
                 inReplyToViewModel: StatusViewModel?,
                 redraft: Status?,
                 redraftWasContextParent: Bool,
                 directMessageTo: AccountViewModel?) {
        if redraftWasContextParent {
            navigationController?.popViewController(animated: true)
        }

        rootViewModel?.navigationViewModel?.presentedNewStatusViewModel = rootViewModel?.newStatusViewModel(
            identityContext: viewModel.identityContext,
            identity: identity,
            inReplyTo: inReplyToViewModel,
            redraft: redraft,
            directMessageTo: directMessageTo)
    }

    func confirmDelete(statusViewModel: StatusViewModel, redraft: Bool) {
        let deleteAndRedraftConfirmMessage: String
        let deleteConfirmMessage: String

        switch viewModel.identityContext.appPreferences.statusWord {
        case .toot:
            deleteAndRedraftConfirmMessage = NSLocalizedString("status.delete-and-redraft.confirm.toot", comment: "")
            deleteConfirmMessage = NSLocalizedString("status.delete.confirm.toot", comment: "")
        case .post:
            deleteAndRedraftConfirmMessage = NSLocalizedString("status.delete-and-redraft.confirm.post", comment: "")
            deleteConfirmMessage = NSLocalizedString("status.delete.confirm.post", comment: "")
        }

        let alertController = UIAlertController(
            title: nil,
            message: redraft
                ? deleteAndRedraftConfirmMessage
                : deleteConfirmMessage,
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

    func confirmUnfollow(accountViewModel: AccountViewModel) {
        confirm(message: String.localizedStringWithFormat(
                    NSLocalizedString("account.unfollow.confirm-%@", comment: ""),
                    accountViewModel.accountName)) {
            accountViewModel.unfollow()
        }
    }

    func confirmHideReblogs(accountViewModel: AccountViewModel) {
        confirm(message: String.localizedStringWithFormat(
                    NSLocalizedString("account.hide-reblogs.confirm-%@", comment: ""),
                    accountViewModel.accountName)) {
            accountViewModel.hideReblogs()
        }
    }

    func confirmShowReblogs(accountViewModel: AccountViewModel) {
        confirm(message: String.localizedStringWithFormat(
                    NSLocalizedString("account.show-reblogs.confirm-%@", comment: ""),
                    accountViewModel.accountName)) {
            accountViewModel.showReblogs()
        }
    }

    func confirmMute(muteViewModel: MuteViewModel) {
        let muteViewController = MuteViewController(viewModel: muteViewModel)
        let navigationController = UINavigationController(rootViewController: muteViewController)

        present(navigationController, animated: true)
    }

    func confirmUnmute(accountViewModel: AccountViewModel) {
        confirm(message: String.localizedStringWithFormat(
                    NSLocalizedString("account.unmute.confirm-%@", comment: ""),
                    accountViewModel.accountName)) {
            accountViewModel.unmute()
        }
    }

    func confirmBlock(accountViewModel: AccountViewModel) {
        let alertController = UIAlertController(
            title: nil,
            message: String.localizedStringWithFormat(
                NSLocalizedString("account.block.confirm-%@", comment: ""),
                accountViewModel.accountName), preferredStyle: .alert)
        let blockAction = UIAlertAction(title: NSLocalizedString("account.block", comment: ""),
                                        style: .destructive) { _ in
            accountViewModel.block()
        }
        let blockAndReportAction = UIAlertAction(title: NSLocalizedString("account.block-and-report", comment: ""),
                                                 style: .destructive) { [weak self] _ in
            accountViewModel.block()
            self?.report(reportViewModel: accountViewModel.reportViewModel())
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel) { _ in }

        alertController.addAction(blockAction)
        alertController.addAction(blockAndReportAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }

    func confirmUnblock(accountViewModel: AccountViewModel) {
        confirm(message: String.localizedStringWithFormat(
                    NSLocalizedString("account.unblock.confirm-%@", comment: ""),
                    accountViewModel.accountName)) {
            accountViewModel.unblock()
        }
    }

    func confirmDomainBlock(accountViewModel: AccountViewModel) {
        guard let domain = accountViewModel.domain else { return }

        confirm(message: String.localizedStringWithFormat(
                    NSLocalizedString("account.domain-block.confirm-%@", comment: ""),
                    domain),
                style: .destructive) {
            accountViewModel.domainBlock()
        }
    }

    func confirmDomainUnblock(accountViewModel: AccountViewModel) {
        guard let domain = accountViewModel.domain else { return }

        confirm(message: String.localizedStringWithFormat(
                    NSLocalizedString("account.domain-unblock.confirm-%@", comment: ""),
                    domain)) {
            accountViewModel.domainUnblock()
        }
    }

    func accountListEdit(accountViewModel: AccountViewModel, edit: CollectionItemEvent.AccountListEdit) {
        viewModel.applyAccountListEdit(viewModel: accountViewModel, edit: edit)
    }

    func share(url: URL) {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: [OpenInDefaultBrowserActivity()])

        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let sourceView = tableView.viewWithTag(url.hashValue) else { return }

            activityViewController.popoverPresentationController?.sourceView = sourceView
        }

        present(activityViewController, animated: true, completion: nil)
    }

    func refreshIfAble() {
        if viewModel.canRefresh {
            viewModel.request(maxId: nil, minId: nil, search: nil)
        }
    }

    func newItemsTapped() {
        scrollToTop(animated: true)
    }

    func announceNewItems(newestItem: CollectionItem) {
        switch newestItem {
        case .status:
            switch viewModel.identityContext.appPreferences.statusWord {
            case .toot:
                newItemsView.title = NSLocalizedString("status.new-items.toot", comment: "")
            case .post:
                newItemsView.title = NSLocalizedString("status.new-items.post", comment: "")
            }
        case .notification:
            newItemsView.title = NSLocalizedString("notification.new-items", comment: "")
        default:
            return
        }

        newItemsView.layoutIfNeeded()

        UIView.animate(withDuration: .zeroIfReduceMotion(.defaultAnimationDuration),
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 5,
                       options: .curveEaseInOut) {
            self.newItemsView.alpha = 1
            self.newItemsViewHiddenConstraint?.isActive = false
            self.newItemsViewVisibleConstraint?.isActive = true
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.reloadVisibleItems()
        }
    }

    func hideNewItemsView() {
        UIView.animate(withDuration: .zeroIfReduceMotion(.defaultAnimationDuration)) {
            self.newItemsView.alpha = 0
            self.newItemsViewHiddenConstraint?.isActive = true
            self.newItemsViewVisibleConstraint?.isActive = false
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.reloadVisibleItems()
        }
    }

    func reloadVisibleItems() {
        guard let visibleItems = tableView.indexPathsForVisibleRows?.compactMap(dataSource.itemIdentifier(for:))
        else { return }

        var snapshot = dataSource.snapshot()

        snapshot.reloadItems(visibleItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
// swiftlint:enable file_length
