// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class AccountStatusesViewModel: StatusListViewModel {
    @Published public private(set) var accountViewModel: AccountViewModel?
    @Published public var collection = AccountStatusCollection.statuses
    private let accountStatusesService: AccountStatusesService
    private var cancellables = Set<AnyCancellable>()

    init(accountStatusesService: AccountStatusesService) {
        self.accountStatusesService = accountStatusesService

        let collectionSubject = CurrentValueSubject<AccountStatusCollection, Never>(.statuses)

        super.init(
            statusListService: accountStatusesService.statusListService(
                collectionPublisher: collectionSubject))

        $collection.sink(receiveValue: collectionSubject.send).store(in: &cancellables)

        accountStatusesService.accountService
            .map(AccountViewModel.init(accountService:))
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$accountViewModel)
    }

    public override var collectionItems: AnyPublisher<[[CollectionItem]], Never> {
        // The pinned key is added to the info of collection items in the first section
        // so a diffable data source can potentially render it in both sections
        super.collectionItems
            .map {
                $0.enumerated().map {
                    $0 == 0 ? $1.map { .init(id: $0.id, kind: $0.kind, info: [.pinned: true]) } : $1
                }
            }
            .eraseToAnyPublisher()
    }

    public override var navigationEvents: AnyPublisher<NavigationEvent, Never> {
        $accountViewModel.compactMap { $0 }
            .flatMap(\.events)
            .flatMap { $0 }
            .map(NavigationEvent.init)
            .compactMap { $0 }
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .merge(with: super.navigationEvents)
            .eraseToAnyPublisher()
    }

    public override func request(maxID: String? = nil, minID: String? = nil) {
        if case .statuses = collection, maxID == nil {
            accountStatusesService.fetchPinnedStatuses()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)
        }

        super.request(maxID: maxID, minID: minID)
    }

    public override var title: AnyPublisher<String?, Never> {
        $accountViewModel.map { $0?.accountName }.eraseToAnyPublisher()
    }
}

public extension AccountStatusesViewModel {
    func fetchAccount() {
        accountStatusesService.fetchAccount()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }
}
