// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class AccountStatusesViewModel: StatusListViewModel {
    @Published public private(set) var account: Account?
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

        accountStatusesService.accountObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$account)
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

    override func isPinned(status: Status) -> Bool {
        collection == .statuses && items.first?.contains(CollectionItem(id: status.id, kind: .status)) ?? false
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
